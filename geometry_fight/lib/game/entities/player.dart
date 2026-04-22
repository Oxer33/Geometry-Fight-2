import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/painting.dart' show HSVColor;
import '../../data/constants.dart';
import '../game_world.dart';
import 'enemies/enemy_base.dart';
import 'projectiles.dart';

enum WeaponType {
  basic,
  spread,
  spreadFan,
  laser,
  plasma,
  ricochet,
  homing,
  triple,
  overdrive,
}

// Plasma: colpo lento con danni base * 3.9 (era 3.0, +30% richiesta utente).
const double kPlasmaDamageMultiplier = 3.9;

class Player extends PositionComponent with HasGameReference<GeometryFightGame>, CollisionCallbacks {
  int lives = playerStartLives;
  int bombs = playerStartBombs;
  double speed = playerSpeed;
  WeaponType currentWeapon = WeaponType.basic;
  WeaponType? temporaryWeapon;
  double weaponTimer = 0;

  double _fireTimer = 0;
  double _invincibleTimer = 0;
  bool get isInvincible => _invincibleTimer > 0;

  // Shield
  int shieldHits = 0;
  bool hasShield = false;
  double shieldTimer = 0;

  // Power-up states
  double rapidFireTimer = 0;
  double overdriveTimer = 0;
  double magnetTimer = 0;
  double timeSlowTimer = 0;
  double firePowerTimer = 0;
  bool get hasRapidFire => rapidFireTimer > 0;
  bool get hasOverdrive => overdriveTimer > 0;
  bool get hasMagnet => magnetTimer > 0;
  bool get hasFirePower => firePowerTimer > 0;

  // Visual
  double _thrusterPhase = 0;
  double _rotation = 0;
  double _wingPulse = 0;
  double _energyPhase = 0;
  double _shieldPhase = 0;

  // Cache del colore crystal (HSV ciclante): ricomputato solo quando la hue
  // step avanza (intervalli di 5°) → da 60 HSV/sec per player a ~2/sec.
  int _crystalHueStep = -1;
  Color? _crystalColorCache;

  // Trail di movimento (scia luminosa)
  final List<Vector2> _trail = [];
  static const int _maxTrailLength = 18;
  double _trailTimer = 0;

  Player() : super(size: Vector2(30, 34), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    add(CircleHitbox(radius: playerHurtboxRadius, anchor: Anchor.center)
      ..position = size / 2);
  }

  /// Imposta l'arma equipaggiata a partire dall'id salvato (shop).
  /// Valori validi: 'basic', 'triple', 'spread', 'ricochet', 'homing', 'plasma', 'laser'.
  void setWeaponFromId(String id) {
    switch (id) {
      case 'triple':
        currentWeapon = WeaponType.triple;
      case 'spread':
        currentWeapon = WeaponType.spread;
      case 'ricochet':
        currentWeapon = WeaponType.ricochet;
      case 'homing':
        currentWeapon = WeaponType.homing;
      case 'plasma':
        currentWeapon = WeaponType.plasma;
      case 'laser':
        currentWeapon = WeaponType.laser;
      case 'basic':
      default:
        currentWeapon = WeaponType.basic;
    }
  }

  @override
  void update(double dt) {
    // Il player NON è affetto dal slow-motion: compensa il timeScale
    // Quando timeScale=0.5, dt è già scalato, quindi il player moltiplica per 1/timeScale
    final realDt = game.timeScale > 0.01 ? dt / game.timeScale : dt;
    super.update(realDt);

    // Movement (usa realDt per non essere rallentato dallo slow-mo)
    final moveDir = game.moveInput;
    if (moveDir.length > 0) {
      final actualSpeed = speed * (hasOverdrive ? 1.15 : 1.0) *
          game.saveData.speedMultiplier;
      position += moveDir * actualSpeed * realDt;
    }

    // Clamp to arena
    if (game.isTunnelMode) {
      // Tunnel side-scroller: il player si muove liberamente dentro lo schermo visibile.
      // La camera avanza da sola — il player NON può uscire dalla vista.
      // Guard: game.size potrebbe essere zero durante i primi frame
      final screenHalfW = game.size.x > 0 ? game.size.x / 2 : 400.0;
      final screenHalfH = game.size.y > 0 ? game.size.y / 2 : 300.0;
      final cameraX = game.camera.viewfinder.position.x;
      final cameraY = game.camera.viewfinder.position.y;
      // Clamp X: non può andare dietro al bordo sinistro né oltre il bordo destro
      position.x = position.x.clamp(
        cameraX - screenHalfW + 20,
        cameraX + screenHalfW - 20,
      );
      // Clamp Y: limitato dalla vista della camera (il tunnel renderer fa il clamp fine sui muri)
      position.y = position.y.clamp(
        cameraY - screenHalfH + 20,
        cameraY + screenHalfH - 20,
      );
    } else {
      // Modalità normali: limiti sia X che Y
      position.x = position.x.clamp(15, arenaWidth - 15);
      position.y = position.y.clamp(15, arenaHeight - 15);
    }

    // Aim direction
    final aimDir = game.aimInput;
    if (aimDir.length > 0) {
      _rotation = math.atan2(aimDir.y, aimDir.x) + math.pi / 2;
    }

    // Shooting (usa realDt per non essere rallentato dallo slow-mo)
    _fireTimer -= realDt;
    if ((game.isShooting || aimDir.length > 0.3) && _fireTimer <= 0) {
      _shoot(aimDir.length > 0.3 ? aimDir : Vector2(0, -1));
    }

    // Timers (tutti con realDt — il player non è affetto dal slow-mo)
    if (_invincibleTimer > 0) _invincibleTimer -= realDt;
    if (rapidFireTimer > 0) rapidFireTimer -= realDt;
    if (overdriveTimer > 0) overdriveTimer -= realDt;
    if (magnetTimer > 0) magnetTimer -= realDt;
    if (firePowerTimer > 0) firePowerTimer -= realDt;
    if (timeSlowTimer > 0) {
      timeSlowTimer -= realDt;
      if (timeSlowTimer <= 0) {
        // Non resettare timeScale se c'è un burst slow-mo attivo (bomba/morte)
        if (game.slowMoTimer <= 0) {
          game.timeScale = 1.0;
        }
      }
    }
    if (weaponTimer > 0) {
      weaponTimer -= realDt;
      if (weaponTimer <= 0) {
        temporaryWeapon = null;
      }
    }
    if (hasShield && shieldTimer > 0) {
      shieldTimer -= realDt;
      if (shieldTimer <= 0) {
        hasShield = false;
        shieldHits = 0;
      }
    }

    // Bomb
    if (game.bombPressed) {
      game.bombPressed = false;
      game.useBomb();
    }

    // Magnet - attract geoms
    if (hasMagnet || game.saveData.magnetRange > 0) {
      _attractGeoms();
    }

    // Animazioni visive
    _thrusterPhase += dt * 15;
    _wingPulse += dt * 4;
    _energyPhase += dt * 8;
    _shieldPhase += dt * 3;

    // Trail di movimento: registra posizione ogni 0.02s
    _trailTimer += dt;
    if (_trailTimer >= 0.02 && moveDir.length > 0.1) {
      _trailTimer = 0;
      _trail.insert(0, position.clone());
      if (_trail.length > _maxTrailLength) _trail.removeLast();
    } else if (moveDir.length <= 0.1 && _trail.isNotEmpty) {
      // Dissolvenza trail quando fermi
      if (_trailTimer >= 0.05) {
        _trailTimer = 0;
        if (_trail.isNotEmpty) _trail.removeLast();
      }
    }
  }

  void _shoot(Vector2 direction) {
    final weapon = temporaryWeapon ?? currentWeapon;
    // Overdrive powerup: potenzia SOLO la velocità di movimento della nave
    // (vedi update() line 103). Non incrementa fire rate né danno né pierce
    // — era un effetto cumulativo che rendeva il powerup troppo forte.
    final fireRateMultiplier = game.saveData.fireRateMultiplier *
        (hasRapidFire ? 2.5 : 1.0);

    double fireInterval = 1.0 / (baseFireRate * fireRateMultiplier);
    _fireTimer = fireInterval;

    final dir = direction.normalized();
    double damageMultiplier = game.saveData.damageMultiplier;
    if (hasFirePower) damageMultiplier *= 2.0;
    const pierce = false;
    final basicColor = hasFirePower ? const Color(0xFFFF3300) : NeonColors.bulletYellow;

    switch (weapon) {
      case WeaponType.basic:
        // Due file parallele di proiettili
        final perp = Vector2(-dir.y, dir.x) * 6; // 6px di distanza
        _spawnBullet(dir, damageMultiplier, basicColor, offset: perp, pierce: pierce, weaponType: WeaponType.basic);
        _spawnBullet(dir, damageMultiplier, basicColor, offset: -perp, pierce: pierce, weaponType: WeaponType.basic);
      case WeaponType.spread:
        // 5 proiettili a ventaglio (shop weapon)
        for (final angle in [-0.12, -0.06, 0.0, 0.06, 0.12]) {
          final rotDir = _rotateVector(dir, angle);
          _spawnBullet(rotDir, damageMultiplier * 0.85, NeonColors.spreadOrange,
              speed: bulletSpeed * 1.1, pierce: pierce, weaponType: WeaponType.spread);
        }
      case WeaponType.spreadFan:
        // 9 proiettili con angolo totale 20° (±10°) — powerup drop
        for (final angle in [-0.175, -0.13125, -0.0875, -0.04375, 0.0, 0.04375, 0.0875, 0.13125, 0.175]) {
          final rotDir = _rotateVector(dir, angle);
          _spawnBullet(rotDir, damageMultiplier * 0.7, NeonColors.spreadOrange,
              speed: bulletSpeed * 1.2, pierce: pierce, weaponType: WeaponType.spreadFan);
        }
      case WeaponType.laser:
        _spawnLaser(dir, damageMultiplier);
      case WeaponType.plasma:
        _spawnPlasma(dir, damageMultiplier);
        // +50% fire rate: 0.4 → 0.267s tra i colpi. Anche scalato dagli
        // upgrade shop + rapidFire powerup (entrambi già in fireRateMultiplier).
        // Overdrive powerup NON accelera il fire rate (solo movimento).
        _fireTimer = (0.4 / 1.5) / fireRateMultiplier;
      case WeaponType.ricochet:
        // Ventaglio di 3 colpi che rimbalzano (richiesta utente).
        // Angoli: ~23° totali (-0.20, 0, +0.20 rad) — fan chiaro ma non troppo
        // largo, così i proiettili mantengono utilità vs bersagli singoli.
        // Danno per colpo: 0.55x (3 colpi → DPS totale 1.65x, ragionevole).
        // maxBounces ridotto 5→3 per colpo (totale 9 rimbalzi in scena,
        // era 5 con un singolo proiettile: più spettacolo, meno "muro" di hit).
        for (final angle in [-0.20, 0.0, 0.20]) {
          final rotDir = _rotateVector(dir, angle);
          _spawnBullet(rotDir, damageMultiplier * 0.55, NeonColors.ricochetGreen,
              maxBounces: 3, pierce: pierce, weaponType: WeaponType.ricochet);
        }
      case WeaponType.homing:
        // Base 5 missili. Ventaglio di angoli per coprire più bersagli.
        // Ogni salva ha un volleyId unico: i missili della stessa salva
        // cercano bersagli DISTINTI tra loro (richiesta utente).
        //
        // Spawn: TUTTI dalla parte anteriore della navicella (stesso punto).
        // La divergenza avviene DOPO lo spawn grazie al ventaglio di angoli
        // + target distinti — i missili si allontanano naturalmente.
        //
        // Cap attivi: massimo 20 missili in volo simultanei. Con rapidFire
        // il cap sale a 30 (non 40: rapidFire deve essere meno efficace
        // su quest'arma del 50% — altrimenti troppi missili in scena).
        // Se la salva supera il cap, spawna solo quanti ne entrano.
        const homingCount = 5;
        final maxActive = hasRapidFire ? 30 : 20;
        final available = maxActive - HomingMissile.activeCount;
        final toSpawn = available.clamp(0, homingCount);
        if (toSpawn > 0) {
          final volleyId = HomingMissile.nextVolleyId();
          // Punto di spawn: naso della navicella = posizione player + offset
          // lungo la direzione di tiro. 22px = davanti al corpo del player
          // (player size ~30px, ship forward-tip a ~22 dal centro).
          final nose = position + dir.normalized() * 22;
          for (int i = 0; i < toSpawn; i++) {
            final spread = (i - (homingCount - 1) / 2) * 0.15;
            final rotatedDir = _rotateVector(dir, spread);
            _spawnHomingMissile(
              rotatedDir,
              damageMultiplier,
              volleyId: volleyId,
              spawnAt: nose,
            );
          }
        }
        // Fire rate rapidFire dimezzato in efficacia: normalmente rapidFire
        // dà 2.5x fire rate; qui 1.75x (boost ridotto del 50%: +150% → +75%)
        // → meno missili accumulati nel tempo, cap più facile da rispettare.
        // Overdrive powerup NON accelera il fire rate (solo movimento).
        // Calcolo custom: bypassa `fireRateMultiplier` che ha già 2.5x per
        // rapidFire, e applica 1.75x qui. Senza rapidFire usa il solo shop mult.
        final homingMult = game.saveData.fireRateMultiplier *
            (hasRapidFire ? 1.75 : 1.0);
        _fireTimer = 0.5 / homingMult;
      case WeaponType.triple:
        // Sparo triplo con angolo ristretto (~12° totali)
        for (final angle in [-0.105, 0.0, 0.105]) {
          final rotDir = _rotateVector(dir, angle);
          _spawnBullet(rotDir, damageMultiplier, NeonColors.white, pierce: pierce, weaponType: WeaponType.triple);
        }
        _fireTimer = fireInterval * 0.5;
      case WeaponType.overdrive:
        _spawnOverdriveBeam(dir);
        _fireTimer = 3.0;
    }
  }

  void _spawnBullet(Vector2 dir, double damage, Color color,
      {double speed = bulletSpeed,
      int maxBounces = maxBounces,
      Vector2? offset,
      bool pierce = false,
      WeaponType weaponType = WeaponType.basic}) {
    final bullet = PlayerBullet(
      direction: dir,
      weaponType: weaponType,
      speed: speed,
      damage: damage,
      color: color,
      maxBounces: maxBounces,
      pierce: pierce,
      sizeMultiplier: hasFirePower ? 2.0 : 1.0,
    );
    bullet.position = position + (offset ?? Vector2.zero());
    game.world.add(bullet);
  }

  void _spawnLaser(Vector2 dir, double damage) {
    final laser = LaserBeam(
      direction: dir,
      damage: damage * 0.5,
      sizeMultiplier: hasFirePower ? 2.0 : 1.0,
    );
    laser.position = position.clone();
    game.world.add(laser);
  }

  void _spawnPlasma(Vector2 dir, double damage) {
    final plasma = PlasmaBullet(
      direction: dir,
      damage: damage * kPlasmaDamageMultiplier,
      sizeMultiplier: hasFirePower ? 2.0 : 1.0,
    );
    plasma.position = position.clone();
    game.world.add(plasma);
  }

  void _spawnHomingMissile(
    Vector2 dir,
    double damage, {
    required int volleyId,
    required Vector2 spawnAt,
  }) {
    // Damage base: damageMultiplier * 2.25 (era 1.5 → +50% richiesta utente).
    // 2.25 = 1.5 × 1.5 → i missili fanno il 50% in più rispetto al valore
    // precedente, come richiesto. AoE sempre attiva (logica nel missile).
    final missile = HomingMissile(
      direction: dir,
      damage: damage * 2.25,
      sizeMultiplier: hasFirePower ? 2.0 : 1.0,
      volleyId: volleyId,
    );
    missile.position = spawnAt.clone();
    game.world.add(missile);
  }

  void _spawnOverdriveBeam(Vector2 dir) {
    final beam = OverdriveBeam(direction: dir);
    beam.position = position.clone();
    game.world.add(beam);
  }

  Vector2 _rotateVector(Vector2 v, double angle) {
    final c = math.cos(angle);
    final s = math.sin(angle);
    return Vector2(v.x * c - v.y * s, v.x * s + v.y * c);
  }

  void _attractGeoms() {
    // L'attrazione dei geomi è gestita direttamente in Geom.update()
    // Questo metodo è mantenuto come hook per eventuali effetti visivi futuri
  }

  void takeDamage() {
    if (isInvincible) return;

    if (hasShield) {
      shieldHits--;
      if (shieldHits <= 0) {
        hasShield = false;
      }
      game.spawnExplosion(position, NeonColors.cyan, radius: 30);
      return;
    }

    lives--;
    _invincibleTimer = playerInvincibilityDuration;

    // Scudo post-morte dall'upgrade shop: compare solo dopo aver perso una vita
    final shieldDur = game.saveData.postDeathShieldDuration;
    if (shieldDur > 0 && lives > 0) {
      applyShield(999, duration: shieldDur);
    }

    game.onPlayerHit();

    if (lives <= 0) {
      game.onPlayerDeath();
    }
  }

  void applyShield(int hits, {double duration = 60.0}) {
    hasShield = true;
    shieldHits = hits;
    shieldTimer = duration;
  }

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final paint = Paint();

    // === 1. TRAIL DI MOVIMENTO (scia luminosa dietro la nave) ===
    _renderTrail(canvas, cx, cy);

    // === 2. EFFETTO OVERDRIVE (alone arcobaleno) ===
    if (hasOverdrive) {
      _renderOverdriveAura(canvas, cx, cy);
    }

    // === 3. GLOW ESTERNO DELLA NAVE — senza blur ===
    // Colore base determinato dallo skin equipaggiato (shop). Overdrive
    // prevale con arcobaleno animato. `skinId` letto una volta e condiviso.
    final skinId = game.saveData.activeSkin;
    final skinColor = _getSkinColor();
    final baseColor = hasOverdrive
        ? _getRainbowColor(_energyPhase)
        : skinColor;
    final ghost = skinId == 'ghost';
    final glowAlpha = ghost ? 0.06 : 0.12;
    paint.color = baseColor.withValues(alpha: glowAlpha);
    paint.maskFilter = null;
    _drawShipBody(canvas, paint, 1.7);

    // === 4. THRUSTER (doppio motore con fiamme) ===
    _renderThrusters(canvas, cx, cy);

    // === 5. CORPO NAVE PRINCIPALE ===
    // Skin ghost: alpha ridotta (semi-trasparente). Stealth: fill quasi nero
    // con bordo rosso luminoso. Crystal: base bianca con leggero tint cromatico.
    paint.maskFilter = null;
    Color bodyColor = baseColor;
    if (skinId == 'ghost') {
      bodyColor = baseColor.withValues(alpha: 0.45);
    } else if (skinId == 'stealth') {
      bodyColor = const Color(0xFF0A0A0A);
    } else if (skinId == 'crystal') {
      // Tint cromatico leggero che cicla lento. `Color.lerp` su due non-null
      // è garantito non-null ma evitiamo il bang per robustezza.
      final hue = (_energyPhase * 10) % 360;
      bodyColor = Color.lerp(
            const Color(0xFFE8F8FF),
            HSVColor.fromAHSV(1, hue, 0.4, 1).toColor(),
            0.3,
          ) ??
          const Color(0xFFE8F8FF);
    }
    if (isInvincible) {
      final blink = ((_invincibleTimer * 12).toInt() % 2 == 0);
      paint.color = blink ? bodyColor : bodyColor.withValues(alpha: 0.2);
    } else {
      paint.color = bodyColor;
    }
    _drawShipBody(canvas, paint, 1.0);

    // Bordo rosso luminoso per stealth (si legge sulla fill quasi nera)
    if (skinId == 'stealth' && !isInvincible) {
      final edgePaint = Paint()
        ..color = const Color(0xFFFF2244).withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      _drawShipBody(canvas, edgePaint, 1.0);
    }

    // === 6. DETTAGLI INTERNI (cockpit, linee strutturali) ===
    _renderShipDetails(canvas, cx, cy, baseColor);

    // === 7. WING-TIP LIGHTS (luci sulle punte delle ali) ===
    _renderWingLights(canvas, cx, cy);

    // === 8. SCUDO FORCE FIELD ===
    if (hasShield) {
      _renderShield(canvas, cx, cy);
    }
  }

  static final _trailPaint = Paint();
  static final _detailPaint = Paint();

  /// Scia luminosa dietro la nave durante il movimento.
  /// Colore deriva dal trail equipaggiato nello shop (activeTrail):
  /// normal=cyan, fire=arancio, ice=azzurro, plasma=viola, rainbow=HSV ciclico.
  void _renderTrail(Canvas canvas, double cx, double cy) {
    if (_trail.isEmpty) return;
    for (int i = 0; i < _trail.length; i++) {
      final alpha = (1.0 - i / _maxTrailLength) * 0.4;
      final trailSize = (1.0 - i / _maxTrailLength) * 3;
      final offset = _trail[i] - position;
      final color = hasOverdrive
          ? _getRainbowColor(_energyPhase + i * 0.3)
          : _getTrailColor(i);
      // Soft glow senza blur — cerchio più grande, alpha ridotta
      _trailPaint.color = color.withValues(alpha: alpha * 0.5);
      _trailPaint.maskFilter = null;
      canvas.drawCircle(
        Offset(cx + offset.x, cy + offset.y),
        trailSize * 1.8,
        _trailPaint,
      );
      _trailPaint.color = color.withValues(alpha: alpha);
      canvas.drawCircle(
        Offset(cx + offset.x, cy + offset.y),
        trailSize,
        _trailPaint,
      );
    }
  }

  /// Colore skin equipaggiato (shop). Overdrive prevale (arcobaleno).
  Color _getSkinColor() {
    switch (game.saveData.activeSkin) {
      case 'stealth':
        return const Color(0xFFFF2244);
      case 'crystal':
        // Crystal: ciclo cromatico lento → riflessi arcobaleno.
        // Cache su step di 5° → ricomputo ~72 volte/ciclo invece di 60 fps.
        final step = ((_energyPhase * 20) / 5).floor() % 72;
        if (_crystalHueStep != step || _crystalColorCache == null) {
          _crystalHueStep = step;
          _crystalColorCache =
              HSVColor.fromAHSV(1, step * 5.0, 0.5, 1).toColor();
        }
        return _crystalColorCache!;
      case 'ghost':
        return const Color(0xFF8888CC);
      case 'omega':
        return const Color(0xFFFFD700);
      case 'classic':
      default:
        return NeonColors.cyan;
    }
  }

  /// Colore scia equipaggiata (shop).
  Color _getTrailColor(int index) {
    switch (game.saveData.activeTrail) {
      case 'fire':
        // Gradiente rosso→giallo lungo la scia
        final t = (index / _maxTrailLength).clamp(0.0, 1.0);
        return Color.lerp(const Color(0xFFFFDD00), const Color(0xFFFF2200), t)!;
      case 'ice':
        return const Color(0xFF88DDFF);
      case 'plasma':
        return const Color(0xFFCC00FF);
      case 'rainbow':
        return HSVColor.fromAHSV(
                1, ((_energyPhase * 60) + index * 25) % 360, 1, 1)
            .toColor();
      case 'normal':
      default:
        return NeonColors.cyan;
    }
  }

  static final _auraPaint = Paint();

  /// Alone arcobaleno attorno alla nave durante overdrive — senza blur
  void _renderOverdriveAura(Canvas canvas, double cx, double cy) {
    for (int i = 0; i < 3; i++) {
      final hue = ((_energyPhase * 60 + i * 120) % 360);
      final color = HSVColor.fromAHSV(0.08 - i * 0.02, hue, 1, 1).toColor();
      _auraPaint.color = color;
      _auraPaint.maskFilter = null;
      canvas.drawCircle(Offset(cx, cy), 30 + i * 8.0, _auraPaint);
    }
  }

  /// Doppi thruster con fiamma animata e particelle
  void _renderThrusters(Canvas canvas, double cx, double cy) {
    final moveDir = game.moveInput;
    final isMoving = moveDir.length > 0.1;
    final flameLength = isMoving ? 10 + math.sin(_thrusterPhase) * 4 : 4 + math.sin(_thrusterPhase * 0.5) * 1;
    final flameWidth = isMoving ? 4.0 : 2.0;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(_rotation);

    // Thruster sinistro
    _drawFlame(canvas, -5, 13, flameLength, flameWidth);
    // Thruster destro
    _drawFlame(canvas, 5, 13, flameLength, flameWidth);

    canvas.restore();
  }

  static final _flameCorePaint = Paint();
  static final _flameInnerPaint = Paint();
  static final _flameOuterPaint = Paint();

  /// Disegna una fiamma singola del thruster — senza blur
  void _drawFlame(Canvas canvas, double x, double y, double length, double width) {
    // Fiamma esterna (rosso/viola glow) — cerchio più grande, no blur
    _flameOuterPaint.color = const Color(0xFFFF2200).withValues(alpha: 0.15);
    _flameOuterPaint.maskFilter = null;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, y + length * 0.6), width: width * 2.2, height: length * 1.3),
      _flameOuterPaint,
    );

    // Fiamma interna (arancione brillante)
    _flameInnerPaint.color = const Color(0xFFFF6600).withValues(alpha: 0.7);
    _flameInnerPaint.maskFilter = null;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, y + length * 0.5), width: width, height: length * 0.7),
      _flameInnerPaint,
    );

    // Core bianco (centro fiamma)
    _flameCorePaint.color = const Color(0xFFFFFFFF).withValues(alpha: 0.9);
    _flameCorePaint.maskFilter = null;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, y + length * 0.3), width: width * 0.6, height: length * 0.5),
      _flameCorePaint,
    );
  }

  /// Dettagli interni della nave: cockpit luminoso e linee strutturali
  void _renderShipDetails(Canvas canvas, double cx, double cy, Color baseColor) {
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(_rotation);

    // Cockpit (cerchio luminoso al centro-alto della nave) — senza blur
    final cockpitGlow = 0.6 + math.sin(_energyPhase * 2) * 0.2;
    _detailPaint.color = const Color(0xFFFFFFFF).withValues(alpha: cockpitGlow * 0.5);
    _detailPaint.maskFilter = null;
    _detailPaint.style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(0, -4), 5, _detailPaint);
    _detailPaint.color = const Color(0xFFFFFFFF).withValues(alpha: cockpitGlow);
    canvas.drawCircle(const Offset(0, -4), 3, _detailPaint);
    _detailPaint.color = baseColor.withValues(alpha: 0.9);
    canvas.drawCircle(const Offset(0, -4), 2, _detailPaint);

    // Linee strutturali sulle ali
    _detailPaint.color = baseColor.withValues(alpha: 0.3);
    _detailPaint.strokeWidth = 0.5;
    _detailPaint.style = PaintingStyle.stroke;
    // Linea ala sinistra
    canvas.drawLine(const Offset(-2, 0), const Offset(-10, 10), _detailPaint);
    // Linea ala destra
    canvas.drawLine(const Offset(2, 0), const Offset(10, 10), _detailPaint);
    // Linea centrale
    canvas.drawLine(const Offset(0, -8), const Offset(0, 8), _detailPaint);

    canvas.restore();
  }

  static final _wingPaint = Paint();

  /// Luci sulle punte delle ali che pulsano — senza blur
  void _renderWingLights(Canvas canvas, double cx, double cy) {
    final pulse = 0.5 + math.sin(_wingPulse) * 0.5;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(_rotation);

    // Luce ala sinistra (rossa) — glow + core
    _wingPaint.maskFilter = null;
    _wingPaint.color = Color.fromRGBO(255, 50, 50, pulse * 0.3);
    canvas.drawCircle(const Offset(-12, 10), 4, _wingPaint);
    _wingPaint.color = Color.fromRGBO(255, 50, 50, pulse * 0.8);
    canvas.drawCircle(const Offset(-12, 10), 2, _wingPaint);

    // Luce ala destra (verde) — glow + core
    _wingPaint.color = Color.fromRGBO(50, 255, 100, pulse * 0.3);
    canvas.drawCircle(const Offset(12, 10), 4, _wingPaint);
    _wingPaint.color = Color.fromRGBO(50, 255, 100, pulse * 0.8);
    canvas.drawCircle(const Offset(12, 10), 2, _wingPaint);

    canvas.restore();
  }

  static final _shieldPaint = Paint();

  /// Scudo esagonale force field con animazione — senza blur
  void _renderShield(Canvas canvas, double cx, double cy) {
    final shieldAlpha = 0.2 + math.sin(_shieldPhase * 2) * 0.1;

    // Glow esterno — esagono più grande, alpha ridotta, no blur
    _shieldPaint.color = NeonColors.cyan.withValues(alpha: shieldAlpha * 0.25);
    _shieldPaint.style = PaintingStyle.fill;
    _shieldPaint.strokeWidth = 0;
    _shieldPaint.maskFilter = null;
    _drawHexagonAt(canvas, cx, cy, 28, _shieldPaint);

    // Bordo esagonale principale
    _shieldPaint.color = NeonColors.cyan.withValues(alpha: shieldAlpha + 0.2);
    _shieldPaint.style = PaintingStyle.stroke;
    _shieldPaint.strokeWidth = 1.5;
    _drawHexagonAt(canvas, cx, cy, 22, _shieldPaint);

    // Secondo esagono interno (ruotato)
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(_shieldPhase * 0.3);
    _shieldPaint.color = NeonColors.cyan.withValues(alpha: shieldAlpha * 0.4);
    _shieldPaint.strokeWidth = 0.5;
    _drawHexagonAt(canvas, 0, 0, 18, _shieldPaint);
    canvas.restore();

    // Punti energetici sui vertici — senza blur
    _shieldPaint.style = PaintingStyle.fill;
    for (int i = 0; i < 6; i++) {
      final angle = i * math.pi / 3 - math.pi / 6;
      final px = cx + 22 * math.cos(angle);
      final py = cy + 22 * math.sin(angle);
      final dotAlpha = 0.3 + math.sin(_shieldPhase * 3 + i) * 0.3;
      _shieldPaint.color = NeonColors.cyan.withValues(alpha: dotAlpha * 0.5);
      canvas.drawCircle(Offset(px, py), 3, _shieldPaint);
      _shieldPaint.color = NeonColors.cyan.withValues(alpha: dotAlpha);
      canvas.drawCircle(Offset(px, py), 1.5, _shieldPaint);
    }
  }

  // Path cache: ricostruiti solo se `scale` o skin cambia. Il player viene
  // renderizzato 3 volte per frame (glow + body + stealth-edge) → 3 alloc
  // Path × 60fps = 180 Path/sec evitate.
  double _cachedPathScale = -1;
  bool _cachedPathOmega = false;
  Path? _cachedShipPath;

  /// Disegna il corpo della nave: forma a freccia dettagliata con ali.
  /// Omega skin usa una stella a 4 punte (forma unica descritta nello shop).
  void _drawShipBody(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(_rotation);

    final s = scale;
    final isOmega = game.saveData.activeSkin == 'omega';
    if (_cachedPathScale != s ||
        _cachedPathOmega != isOmega ||
        _cachedShipPath == null) {
      _cachedPathScale = s;
      _cachedPathOmega = isOmega;
      if (isOmega) {
        // Stella a 4 punte — punta lunga in avanti/dietro, punte corte ai lati
        _cachedShipPath = Path()
          ..moveTo(0, -15 * s)
          ..lineTo(4 * s, -3 * s)
          ..lineTo(13 * s, 0)
          ..lineTo(4 * s, 3 * s)
          ..lineTo(0, 15 * s)
          ..lineTo(-4 * s, 3 * s)
          ..lineTo(-13 * s, 0)
          ..lineTo(-4 * s, -3 * s)
          ..close();
      } else {
        // Forma nave standard: punta affilata in alto, ali laterali, coda
        _cachedShipPath = Path()
          ..moveTo(0, -14 * s)
          ..lineTo(4 * s, -6 * s)
          ..lineTo(13 * s, 10 * s)
          ..lineTo(8 * s, 8 * s)
          ..lineTo(5 * s, 14 * s)
          ..lineTo(0, 10 * s)
          ..lineTo(-5 * s, 14 * s)
          ..lineTo(-8 * s, 8 * s)
          ..lineTo(-13 * s, 10 * s)
          ..lineTo(-4 * s, -6 * s)
          ..close();
      }
    }
    canvas.drawPath(_cachedShipPath!, paint);

    canvas.restore();
  }

  /// Esagono a posizione arbitraria
  void _drawHexagonAt(Canvas canvas, double cx, double cy, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = i * math.pi / 3 - math.pi / 6;
      final x = cx + radius * math.cos(angle);
      final y = cy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  /// Colore arcobaleno per overdrive
  Color _getRainbowColor(double phase) {
    final hue = (phase * 60) % 360;
    return HSVColor.fromAHSV(1.0, hue, 1.0, 1.0).toColor();
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is EnemyBase) {
      // GW:RE2: nemici in materializzazione sono incorporei — non danneggiano il player
      if (other.isSpawnInvulnerable) return;
      takeDamage();
    }
    super.onCollisionStart(intersectionPoints, other);
  }
}

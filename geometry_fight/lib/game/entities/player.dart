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
  laser,
  plasma,
  ricochet,
  homing,
  twin,
  overdrive,
}

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

  // Power-up states
  double rapidFireTimer = 0;
  double overdriveTimer = 0;
  double magnetTimer = 0;
  double timeSlowTimer = 0;
  bool get hasRapidFire => rapidFireTimer > 0;
  bool get hasOverdrive => overdriveTimer > 0;
  bool get hasMagnet => magnetTimer > 0;

  // Visual
  double _thrusterPhase = 0;
  double _rotation = 0;
  double _wingPulse = 0;
  double _energyPhase = 0;
  double _shieldPhase = 0;

  // Trail di movimento (scia luminosa)
  final List<Vector2> _trail = [];
  static const int _maxTrailLength = 18;
  double _trailTimer = 0;

  // Tunnel: posizione X massima raggiunta (non si può tornare indietro)
  double _maxTunnelX = 0;

  Player() : super(size: Vector2(30, 34), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    add(CircleHitbox(radius: playerHurtboxRadius, anchor: Anchor.center)
      ..position = size / 2);
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
      final actualSpeed = speed * (hasOverdrive ? 1.5 : 1.0) *
          game.saveData.speedMultiplier;
      position += moveDir * actualSpeed * realDt;
    }

    // Clamp to arena
    if (game.isTunnelMode) {
      // Tunnel: avanzamento automatico lento + non si può tornare indietro
      position.x += 80 * realDt; // Avanzamento automatico
      // Aggiorna la X massima raggiunta
      if (position.x > _maxTunnelX) _maxTunnelX = position.x;
      // Non si può tornare indietro oltre il bordo sinistro dello schermo
      // Il bordo sinistro è la posizione della camera - metà larghezza schermo (~400px)
      final cameraX = game.camera.viewfinder.position.x;
      final screenHalfW = game.size.x / 2;
      position.x = position.x.clamp(cameraX - screenHalfW + 20, double.infinity);
      // Y: limitato dal tunnel renderer (che calcola i muri dinamici)
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
    if (timeSlowTimer > 0) {
      timeSlowTimer -= realDt;
      if (timeSlowTimer <= 0) {
        game.timeScale = 1.0;
      }
    }
    if (weaponTimer > 0) {
      weaponTimer -= realDt;
      if (weaponTimer <= 0) {
        temporaryWeapon = null;
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
    final fireRateMultiplier = game.saveData.fireRateMultiplier *
        (hasRapidFire ? 2.5 : 1.0) *
        (hasOverdrive ? 2.0 : 1.0);

    double fireInterval = 1.0 / (baseFireRate * fireRateMultiplier);
    _fireTimer = fireInterval;

    final dir = direction.normalized();
    final damageMultiplier =
        game.saveData.damageMultiplier * (hasOverdrive ? 3.0 : 1.0);
    final pierce = hasOverdrive;

    switch (weapon) {
      case WeaponType.basic:
        // Due file parallele di proiettili
        final perp = Vector2(-dir.y, dir.x) * 6; // 6px di distanza
        _spawnBullet(dir, damageMultiplier, NeonColors.bulletYellow, offset: perp, pierce: pierce);
        _spawnBullet(dir, damageMultiplier, NeonColors.bulletYellow, offset: -perp, pierce: pierce);
      case WeaponType.spread:
        for (final angle in [-0.52, -0.26, 0.0, 0.26, 0.52]) {
          final rotDir = _rotateVector(dir, angle);
          _spawnBullet(rotDir, damageMultiplier * 0.7, NeonColors.spreadOrange,
              speed: bulletSpeed * 1.2, pierce: pierce);
        }
      case WeaponType.laser:
        _spawnLaser(dir, damageMultiplier);
      case WeaponType.plasma:
        _spawnPlasma(dir, damageMultiplier);
        _fireTimer = 0.4; // Slower fire rate
      case WeaponType.ricochet:
        _spawnBullet(dir, damageMultiplier, NeonColors.ricochetGreen,
            maxBounces: 5, pierce: pierce);
      case WeaponType.homing:
        for (int i = 0; i < 3; i++) {
          final offset = _rotateVector(dir, (i - 1) * 0.2);
          _spawnHomingMissile(offset, damageMultiplier);
        }
        _fireTimer = 0.5;
      case WeaponType.twin:
        final perpendicular = Vector2(-dir.y, dir.x) * 12;
        _spawnBullet(dir, damageMultiplier, NeonColors.white,
            offset: perpendicular, pierce: pierce);
        _spawnBullet(dir, damageMultiplier, NeonColors.white,
            offset: -perpendicular, pierce: pierce);
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
      bool pierce = false}) {
    final bullet = PlayerBullet(
      direction: dir,
      speed: speed,
      damage: damage,
      color: color,
      maxBounces: maxBounces,
      pierce: pierce,
    );
    bullet.position = position + (offset ?? Vector2.zero());
    game.world.add(bullet);
  }

  void _spawnLaser(Vector2 dir, double damage) {
    final laser = LaserBeam(direction: dir, damage: damage * 0.5);
    laser.position = position.clone();
    game.world.add(laser);
  }

  void _spawnPlasma(Vector2 dir, double damage) {
    final plasma = PlasmaBullet(direction: dir, damage: damage * 3);
    plasma.position = position.clone();
    game.world.add(plasma);
  }

  void _spawnHomingMissile(Vector2 dir, double damage) {
    final missile = HomingMissile(direction: dir, damage: damage * 1.5);
    missile.position = position.clone();
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
    game.onPlayerHit();

    if (lives <= 0) {
      game.onPlayerDeath();
    }
  }

  void applyShield(int hits) {
    hasShield = true;
    shieldHits = hits;
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

    // === 3. GLOW ESTERNO DELLA NAVE ===
    final baseColor = hasOverdrive
        ? _getRainbowColor(_energyPhase)
        : NeonColors.cyan;
    paint.color = baseColor.withValues(alpha: 0.25);
    paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    _drawShipBody(canvas, paint, 1.4);

    // === 4. THRUSTER (doppio motore con fiamme) ===
    _renderThrusters(canvas, cx, cy);

    // === 5. CORPO NAVE PRINCIPALE ===
    paint.maskFilter = null;
    if (isInvincible) {
      final blink = ((_invincibleTimer * 12).toInt() % 2 == 0);
      paint.color = blink ? baseColor : baseColor.withValues(alpha: 0.2);
    } else {
      paint.color = baseColor;
    }
    _drawShipBody(canvas, paint, 1.0);

    // === 6. DETTAGLI INTERNI (cockpit, linee strutturali) ===
    _renderShipDetails(canvas, cx, cy, baseColor);

    // === 7. WING-TIP LIGHTS (luci sulle punte delle ali) ===
    _renderWingLights(canvas, cx, cy);

    // === 8. SCUDO FORCE FIELD ===
    if (hasShield) {
      _renderShield(canvas, cx, cy);
    }
  }

  /// Scia luminosa dietro la nave durante il movimento
  void _renderTrail(Canvas canvas, double cx, double cy) {
    if (_trail.isEmpty) return;
    for (int i = 0; i < _trail.length; i++) {
      final alpha = (1.0 - i / _maxTrailLength) * 0.4;
      final trailSize = (1.0 - i / _maxTrailLength) * 3;
      final offset = _trail[i] - position;
      final color = hasOverdrive
          ? _getRainbowColor(_energyPhase + i * 0.3)
          : NeonColors.cyan;
      final p = Paint()
        ..color = color.withValues(alpha: alpha)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, trailSize + 2);
      canvas.drawCircle(
        Offset(cx + offset.x, cy + offset.y),
        trailSize,
        p,
      );
    }
  }

  /// Alone arcobaleno attorno alla nave durante overdrive
  void _renderOverdriveAura(Canvas canvas, double cx, double cy) {
    for (int i = 0; i < 3; i++) {
      final hue = ((_energyPhase * 60 + i * 120) % 360);
      final color = HSVColor.fromAHSV(0.15 - i * 0.03, hue, 1, 1).toColor();
      final p = Paint()
        ..color = color
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 18 + i * 6.0);
      canvas.drawCircle(Offset(cx, cy), 22 + i * 4.0, p);
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

  /// Disegna una fiamma singola del thruster
  void _drawFlame(Canvas canvas, double x, double y, double length, double width) {
    // Core bianco (centro fiamma)
    final corePaint = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.9)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, y + length * 0.3), width: width * 0.6, height: length * 0.5),
      corePaint,
    );

    // Fiamma interna (arancione brillante)
    final innerPaint = Paint()
      ..color = const Color(0xFFFF6600).withValues(alpha: 0.7)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, y + length * 0.5), width: width, height: length * 0.7),
      innerPaint,
    );

    // Fiamma esterna (rosso/viola glow)
    final outerPaint = Paint()
      ..color = const Color(0xFFFF2200).withValues(alpha: 0.3)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, width + 2);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, y + length * 0.6), width: width * 1.8, height: length),
      outerPaint,
    );
  }

  /// Dettagli interni della nave: cockpit luminoso e linee strutturali
  void _renderShipDetails(Canvas canvas, double cx, double cy, Color baseColor) {
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(_rotation);

    // Cockpit (cerchio luminoso al centro-alto della nave)
    final cockpitGlow = 0.6 + math.sin(_energyPhase * 2) * 0.2;
    final cockpitPaint = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: cockpitGlow)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(const Offset(0, -4), 3, cockpitPaint);
    cockpitPaint.maskFilter = null;
    cockpitPaint.color = baseColor.withValues(alpha: 0.9);
    canvas.drawCircle(const Offset(0, -4), 2, cockpitPaint);

    // Linee strutturali sulle ali
    final linePaint = Paint()
      ..color = baseColor.withValues(alpha: 0.3)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;
    // Linea ala sinistra
    canvas.drawLine(const Offset(-2, 0), const Offset(-10, 10), linePaint);
    // Linea ala destra
    canvas.drawLine(const Offset(2, 0), const Offset(10, 10), linePaint);
    // Linea centrale
    canvas.drawLine(const Offset(0, -8), const Offset(0, 8), linePaint);

    canvas.restore();
  }

  /// Luci sulle punte delle ali che pulsano
  void _renderWingLights(Canvas canvas, double cx, double cy) {
    final pulse = 0.5 + math.sin(_wingPulse) * 0.5;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(_rotation);

    // Luce ala sinistra (rossa)
    final leftPaint = Paint()
      ..color = Color.fromRGBO(255, 50, 50, pulse * 0.8)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(const Offset(-12, 10), 2, leftPaint);

    // Luce ala destra (verde)
    final rightPaint = Paint()
      ..color = Color.fromRGBO(50, 255, 100, pulse * 0.8)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(const Offset(12, 10), 2, rightPaint);

    canvas.restore();
  }

  /// Scudo esagonale force field con animazione
  void _renderShield(Canvas canvas, double cx, double cy) {
    final shieldAlpha = 0.2 + math.sin(_shieldPhase * 2) * 0.1;

    // Glow esterno
    final glowPaint = Paint()
      ..color = NeonColors.cyan.withValues(alpha: shieldAlpha * 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    _drawHexagonAt(canvas, cx, cy, 24, glowPaint);

    // Bordo esagonale principale
    final borderPaint = Paint()
      ..color = NeonColors.cyan.withValues(alpha: shieldAlpha + 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    _drawHexagonAt(canvas, cx, cy, 22, borderPaint);

    // Secondo esagono interno (ruotato)
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(_shieldPhase * 0.3);
    final innerPaint = Paint()
      ..color = NeonColors.cyan.withValues(alpha: shieldAlpha * 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    _drawHexagonAt(canvas, 0, 0, 18, innerPaint);
    canvas.restore();

    // Punti energetici sui vertici
    for (int i = 0; i < 6; i++) {
      final angle = i * math.pi / 3 - math.pi / 6;
      final px = cx + 22 * math.cos(angle);
      final py = cy + 22 * math.sin(angle);
      final dotAlpha = 0.3 + math.sin(_shieldPhase * 3 + i) * 0.3;
      final dotPaint = Paint()
        ..color = NeonColors.cyan.withValues(alpha: dotAlpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(Offset(px, py), 1.5, dotPaint);
    }
  }

  /// Disegna il corpo della nave: forma a freccia dettagliata con ali
  void _drawShipBody(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(_rotation);

    final s = scale;
    // Forma nave: punta affilata in alto, ali laterali, coda
    final path = Path()
      ..moveTo(0, -14 * s)           // Punta
      ..lineTo(4 * s, -6 * s)       // Lato destro punta
      ..lineTo(13 * s, 10 * s)      // Ala destra esterna
      ..lineTo(8 * s, 8 * s)        // Rientro ala destra
      ..lineTo(5 * s, 14 * s)       // Coda destra
      ..lineTo(0, 10 * s)           // Centro coda
      ..lineTo(-5 * s, 14 * s)      // Coda sinistra
      ..lineTo(-8 * s, 8 * s)       // Rientro ala sinistra
      ..lineTo(-13 * s, 10 * s)     // Ala sinistra esterna
      ..lineTo(-4 * s, -6 * s)      // Lato sinistro punta
      ..close();
    canvas.drawPath(path, paint);

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
      takeDamage();
    }
    super.onCollisionStart(intersectionPoints, other);
  }
}

import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/painting.dart' show HSVColor;
import '../../data/constants.dart';
import '../effects/gauss_implosion.dart';
import '../game_world.dart';
import 'enemies/enemy_base.dart';
import 'bosses/boss_base.dart';
import 'player.dart';

class PlayerBullet extends PositionComponent
    with HasGameReference<GeometryFightGame>, CollisionCallbacks {
  final Vector2 direction;
  final double speed;
  final double damage;
  final Color color;
  final int maxBounces;
  final bool pierce;
  final double sizeMultiplier;
  final WeaponType weaponType;

  int _bounces = 0;
  double _lifetime = bulletLifetime;
  late Vector2 _velocity;
  double _distanceTravelled = 0;

  /// Flag: già riflesso da MirrorMaster. Evita "rain" di _MirrorBullet
  /// quando un PlayerBullet resta sullo specchio per più frame prima
  /// che Flame processi removeFromParent().
  bool wasReflected = false;

  /// Cooldown per reflect() del Gate: senza questo, la collisione con la
  /// sfera del Gate persiste per più frame → reflect() inverte _velocity
  /// ogni frame → il proiettile resta bloccato dentro il Gate oscillando.
  /// 0.08s = ~5 frame @60fps: abbastanza per uscire dall'hitbox (r=15px,
  /// speed=700 → 56px in 0.08s = ben oltre il raggio).
  double _reflectCooldown = 0;

  // Trail
  final List<Vector2> _trail = [];
  static const int _maxTrailLength = 8;

  PlayerBullet({
    required this.direction,
    required this.weaponType, // explicit: evita default "basic" silente che farebbe schivare Weaver
    this.speed = bulletSpeed,
    this.damage = 1,
    this.color = NeonColors.bulletYellow,
    this.maxBounces = 2,
    this.pierce = false,
    this.sizeMultiplier = 1.0,
  }) : super(size: Vector2(6 * sizeMultiplier, 6 * sizeMultiplier), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    if (direction.length2 < 1e-6) {
      _velocity = Vector2(speed, 0);
    } else {
      _velocity = direction.normalized() * speed;
    }
    // Hitbox circolare per proiettili rotondi
    add(CircleHitbox(radius: 3 * sizeMultiplier, anchor: Anchor.center)
      ..position = size / 2);
  }

  @override
  void update(double dt) {
    // Proiettili player NON affetti dal slow-motion: compensano il timeScale.
    // Clamp divisore 0.3 min: bomb-freeze (timeScale≈0.05) darebbe realDt=20×dt
    // → bullet salta 6m in 1 frame = bucava collision senza hit.
    final realDt = dt / game.timeScale.clamp(0.3, 1.0);
    super.update(realDt);

    if (_reflectCooldown > 0) _reflectCooldown -= realDt;

    // Store trail position
    _trail.insert(0, position.clone());
    if (_trail.length > _maxTrailLength) _trail.removeLast();

    position += _velocity * realDt;
    _distanceTravelled += _velocity.length * realDt;

    // Distruggi / rimbalza quando tocca un muro
    if (game.isTunnelMode) {
      // Tunnel: distruggi se tocca i muri sinusoidali o va dietro la camera
      final cameraLeft = game.camera.viewfinder.position.x - (game.size.x > 0 ? game.size.x / 2 : 400) - 200;
      if (position.x < cameraLeft) {
        removeFromParent();
        return;
      }
      final (topWall, bottomWall) = game.tunnelWallsAtX(position.x);
      if (position.y <= topWall || position.y >= bottomWall) {
        removeFromParent();
        return;
      }
      // Muri rossi tunnel (richiesta utente: impenetrabili).
      if (game.hitsTunnelObstacle(position)) {
        removeFromParent();
        return;
      }
    } else {
      if (maxBounces > 0) {
        // Ricochet weapon: rimbalza sui muri
        bool destroyed = false;
        if (position.x <= 0) {
          position.x = 0;
          if (_bounces < maxBounces) { _velocity.x = _velocity.x.abs(); _bounces++; }
          else { destroyed = true; }
        } else if (position.x >= arenaWidth) {
          position.x = arenaWidth;
          if (_bounces < maxBounces) { _velocity.x = -_velocity.x.abs(); _bounces++; }
          else { destroyed = true; }
        }
        if (!destroyed) {
          if (position.y <= 0) {
            position.y = 0;
            if (_bounces < maxBounces) { _velocity.y = _velocity.y.abs(); _bounces++; }
            else { destroyed = true; }
          } else if (position.y >= arenaHeight) {
            position.y = arenaHeight;
            if (_bounces < maxBounces) { _velocity.y = -_velocity.y.abs(); _bounces++; }
            else { destroyed = true; }
          }
        }
        if (destroyed) { removeFromParent(); return; }
      } else {
        // Arma normale: distruggi quando tocca i bordi dell'arena o dopo 900px percorsi (anche dopo reflect)
        if (position.x < 0 || position.x > arenaWidth ||
            position.y < 0 || position.y > arenaHeight) {
          removeFromParent();
          return;
        }
        if (_distanceTravelled > 900) {
          removeFromParent();
          return;
        }
      }
    }

    _lifetime -= realDt;
    if (_lifetime <= 0) removeFromParent();
  }

  // Paint cache statici per evitare allocazioni ogni frame
  // (con 50+ proiettili × 60fps = migliaia di allocazioni risparmiate)
  static final _trailPaint = Paint();
  static final _glowPaint = Paint();
  static final _bodyPaint = Paint();
  static final _corePaint = Paint()
    ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.7);

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2;
    final cy = size.y / 2;

    // Trail (scia luminosa - solo ultimi 4 punti per performance)
    final trailLen = _trail.length.clamp(0, 4);
    for (int i = 0; i < trailLen; i++) {
      final alpha = 1.0 - (i / 4);
      _trailPaint.color = color.withValues(alpha: alpha * 0.3);
      final offset = _trail[i] - position;
      canvas.drawCircle(
        Offset(cx + offset.x, cy + offset.y), 1.5 * sizeMultiplier, _trailPaint,
      );
    }

    // Glow esterno
    _glowPaint.color = color.withValues(alpha: 0.35);
    canvas.drawCircle(Offset(cx, cy), 4 * sizeMultiplier, _glowPaint);

    // Proiettile principale (cerchio pieno)
    _bodyPaint.color = color;
    canvas.drawCircle(Offset(cx, cy), 3 * sizeMultiplier, _bodyPaint);

    // Centro luminoso bianco
    canvas.drawCircle(Offset(cx, cy), 1.2 * sizeMultiplier, _corePaint);
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is EnemyBase) {
      // GW:RE2: proiettili passano ATTRAVERSO nemici in fase di materializzazione
      if (other.isSpawnInvulnerable) return;

      other.takeDamage(damage);
      // Mini esplosione pixel luminosi al contatto
      game.spawnExplosion(position, color, radius: 8, particleCount: 4);

      // GW:RE2 Fear mechanic: nemici vicini si spaventano quando un proiettile colpisce
      _applyFearToNearby();

      if (!pierce) {
        removeFromParent();
      }
    }
    if (other is BossBase) {
      other.takeDamage(damage);
      game.spawnExplosion(position, color, radius: 10, particleCount: 5);
      if (!pierce) {
        removeFromParent();
      }
    }
    super.onCollisionStart(intersectionPoints, other);
  }

  /// Reflect the bullet's velocity (used by GateEnemy deflection).
  /// Idempotente: cooldown evita flip ripetuti se il bullet resta dentro
  /// la hitbox della sfera del Gate per più frame consecutivi (Flame tiene
  /// attiva la collisione finché i poligoni si sovrappongono).
  void reflect() {
    if (_reflectCooldown > 0) return;
    _velocity = -_velocity;
    _reflectCooldown = 0.08;
  }

  /// GW:RE2 Fear: quando un proiettile colpisce, solo i nemici "fear-dodge"
  /// (attualmente i Weaver verdi) possono fare una micro-schivata.
  /// Max 5 nemici spaventati per impatto per limitare il costo O(n).
  void _applyFearToNearby() {
    const fearRadius = 80.0;
    int fearCount = 0;
    for (final child in game.world.children) {
      if (fearCount >= 5) break; // Limita a 5 per performance
      if (child is EnemyBase && child.canFearDodge) {
        final dist = child.position.distanceTo(position);
        if (dist < fearRadius && dist > 5) {
          child.applyFear(position);
          fearCount++;
        }
      }
    }
  }
}

class EnemyBullet extends PositionComponent
    with HasGameReference<GeometryFightGame>, CollisionCallbacks {
  final Vector2 direction;
  final double speed;
  final Color color;

  late Vector2 _velocity;
  double _lifetime = 4.0;

  EnemyBullet({
    required this.direction,
    this.speed = 300,
    this.color = NeonColors.red,
  }) : super(size: Vector2(18, 18), anchor: Anchor.center); // 3x più grandi

  @override
  Future<void> onLoad() async {
    final dLen2 = direction.length2;
    if (dLen2 < 1e-6) {
      _velocity = Vector2(speed, 0);
    } else {
      _velocity = direction.normalized() * speed;
    }
    add(CircleHitbox(radius: 9, anchor: Anchor.center)
      ..position = size / 2);
  }

  @override
  void update(double dt) {
    super.update(dt);
    position += _velocity * dt;

    _lifetime -= dt;
    if (_lifetime <= 0) { removeFromParent(); return; }

    if (game.isTunnelMode) {
      // Tunnel: distruggi se tocca i muri dinamici o va fuori range
      final (topWall, bottomWall) = game.tunnelWallsAtX(position.x);
      if (position.y <= topWall || position.y >= bottomWall ||
          (position - game.player.position).length > 1200) {
        removeFromParent();
        return;
      }
      // Muri rossi tunnel (richiesta utente impenetrabili).
      if (game.hitsTunnelObstacle(position)) {
        // Piccola esplosione rossa per feedback visivo.
        game.spawnExplosion(position, NeonColors.laserRed,
            radius: 10, particleCount: 3);
        removeFromParent();
        return;
      }
    } else {
      // Arena: distruggi esattamente al bordo (nessuna penetrazione)
      if (position.x < 0 || position.x > arenaWidth ||
          position.y < 0 || position.y > arenaHeight) {
        removeFromParent();
        return;
      }
    }
  }

  // Paint cache statico — evita 50+ allocazioni/frame con molti proiettili nemici
  static final _ebGlowPaint = Paint();
  static final _ebBodyPaint = Paint();
  static final _ebCorePaint = Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.6);

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    // Glow esterno (SENZA blur per performance — con 50 proiettili = 50 blur)
    _ebGlowPaint.color = color.withValues(alpha: 0.3);
    _ebGlowPaint.maskFilter = null;
    canvas.drawCircle(Offset(cx, cy), 8, _ebGlowPaint);
    // Corpo principale
    _ebBodyPaint.color = color;
    canvas.drawCircle(Offset(cx, cy), 6, _ebBodyPaint);
    // Centro luminoso
    canvas.drawCircle(Offset(cx, cy), 3, _ebCorePaint);
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Player) {
      other.takeDamage();
      removeFromParent();
    }
    super.onCollisionStart(intersectionPoints, other);
  }
}

class LaserBeam extends PositionComponent
    with HasGameReference<GeometryFightGame> {
  final Vector2 direction;
  final double damage;
  final double sizeMultiplier;
  double _lifetime = 0.1;
  // Pre-warmed: evita flicker frame 0 con trail comet sotto y=0.
  double _pulsePhase = 0.5;
  double _hitPartCooldown = 0;
  late final Vector2 _dir;
  // Throttle hit-walk a frame alterni (risolve lag richiesta utente).
  int _walkFrame = 0;

  LaserBeam({required this.direction, this.damage = 1, this.sizeMultiplier = 1.0})
      : super(size: Vector2(3, laserBeamLength), anchor: Anchor.topCenter);

  @override
  Future<void> onLoad() async {
    _dir = direction.normalized();
  }

  @override
  void update(double dt) {
    super.update(dt);
    final realDt = dt / game.timeScale.clamp(0.3, 1.0);
    _lifetime -= realDt;
    _pulsePhase += realDt;
    if (_hitPartCooldown > 0) _hitPartCooldown -= realDt;
    if (_lifetime <= 0) {
      removeFromParent();
      return;
    }

    position.setFrom(game.player.position);

    // Throttle hit-walk a frame alterni: halve O(N) cost, 2× damage
    // per tick preserva DPS (richiesta utente: laser generava lag).
    _walkFrame++;
    // Bounded: prevent unbounded growth in extreme long sessions.
    if (_walkFrame > 1 << 20) _walkFrame = 0;
    final doWalk = (_walkFrame & 1) == 0;
    final dir = _dir;
    final enemyHitRadius = 20 * sizeMultiplier;
    final bossHitRadius = 30 * sizeMultiplier;
    bool didHit = false;
    Vector2? hitPoint;
    if (doWalk) {
      final dmgMul = realDt * 60 * 2; // 2× per compensare skip frame
      for (final child in game.world.children) {
        if (child is EnemyBase) {
          final toEnemy = child.position - position;
          final dot = toEnemy.dot(dir);
          if (dot > 0 && dot < laserBeamLength) {
            final perpDist = (toEnemy - dir * dot).length;
            if (perpDist < enemyHitRadius) {
              child.takeDamage(damage * dmgMul, isArea: true);
              didHit = true;
              hitPoint = child.position;
            }
          }
        }
        if (child is BossBase) {
          final toBoss = child.position - position;
          final dot = toBoss.dot(dir);
          if (dot > 0 && dot < laserBeamLength) {
            final perpDist = (toBoss - dir * dot).length;
            if (perpDist < bossHitRadius) {
              child.takeDamage(damage * dmgMul);
              didHit = true;
              hitPoint = child.position;
            }
          }
        }
      }
    }
    // Hit particle rosso (richiesta utente). Throttle 80ms per evitare spam.
    if (didHit && hitPoint != null && _hitPartCooldown <= 0) {
      _hitPartCooldown = 0.08;
      game.spawnExplosion(hitPoint, NeonColors.laserRed,
          radius: 14, particleCount: 4);
    }
  }

  static final _laserGlowPaint = Paint();
  static final _laserCorePaint = Paint();
  static final _laserPulsePaint = Paint();
  static final _laserConePath = Path();

  @override
  void render(Canvas canvas) {
    final angle = math.atan2(direction.y, direction.x) - math.pi / 2;
    canvas.save();
    canvas.translate(size.x / 2, 0);
    canvas.rotate(angle);

    // Cono INVERTITO (richiesta utente): punto stretto al player → si
    // allarga verso il beam → effetto "energia concentrata che esplode
    // nel laser". Colore rosso laser (era bianco-rosso, ora coerente).
    const coneLen = 22.0;
    final coneHalfW = 6 * sizeMultiplier;
    _laserConePath.reset();
    _laserConePath.moveTo(-coneHalfW * 0.15, 0);  // punto stretto al player
    _laserConePath.lineTo(coneHalfW * 0.15, 0);
    _laserConePath.lineTo(coneHalfW, coneLen);     // si allarga al beam
    _laserConePath.lineTo(-coneHalfW, coneLen);
    _laserConePath.close();

    final glowW = 12 * sizeMultiplier;
    final coreW = 3 * sizeMultiplier;

    final pulseLen = laserBeamLength - coneLen;

    // ─── CONO PRIMA DI TUTTO (così comets sono visibili al di sopra) ───
    // Era disegnato in fondo → comets in regione y<22 nascosti dal cono.
    // User feedback "deve partire dalla punta del triangolo": ora cono
    // sotto + comets sopra → pulse visibile dalla punta in poi.
    _laserGlowPaint.color = NeonColors.laserRed.withValues(alpha: 0.6);
    canvas.drawPath(_laserConePath, _laserGlowPaint);
    _laserCorePaint.color = NeonColors.laserRed;
    canvas.drawPath(_laserConePath, _laserCorePaint);

    // ─── BEAM PRINCIPALE 4 STRATI (outer halo → mid → core → nucleus) ───
    _laserGlowPaint.color = const Color(0xFFAA0000).withValues(alpha: 0.25);
    canvas.drawRect(
        Rect.fromLTWH(-glowW * 0.9, coneLen, glowW * 1.8, pulseLen),
        _laserGlowPaint);
    _laserGlowPaint.color = const Color(0xFFFF2244).withValues(alpha: 0.55);
    canvas.drawRect(
        Rect.fromLTWH(-glowW * 0.5, coneLen, glowW, pulseLen),
        _laserGlowPaint);
    _laserCorePaint.color = const Color(0xFFFF6677);
    canvas.drawRect(
        Rect.fromLTWH(-coreW * 0.9, coneLen, coreW * 1.8, pulseLen),
        _laserCorePaint);
    _laserCorePaint.color = const Color(0xFFFFEEDD);
    canvas.drawRect(
        Rect.fromLTWH(-coreW * 0.4, coneLen, coreW * 0.8, pulseLen),
        _laserCorePaint);

    // ─── DUAL-STREAM PLASMA — copertura continua del fascio ───
    // Iter 4 (fix utente "ancora non è per tutta la linea"):
    //   - Iter 3: 8 comets uniformi → spacing 150px → 115px gap visibile.
    //   - Iter 4: 16 primarie (spacing 75px) + 16 secondarie con offset
    //     spaziale costante +0.5*stepLen (~37.5px) → la stream secondaria
    //     viaggia sempre 37.5px avanti rispetto alla primaria a stessa
    //     velocità, dando densità uniforme di 32 nodi/beam in qualsiasi
    //     istante. Trail 5 sfere → percezione continua punta-cono → fondo
    //     senza tratti spenti. NB: stessa velocità è intenzionale —
    //     velocità diverse causerebbero allineamenti periodici (32→16
    //     nodi sovrapposti → gap di 75px temporanei).
    const cometCount = 16;
    const cometSpeed = 850.0;
    final cometR = 5.5 * sizeMultiplier;
    final fullLen = laserBeamLength.toDouble();
    final stepLen = fullLen / cometCount;

    // PRIMARY STREAM — 16 comete grandi (halo + mid + nucleus + trail).
    for (int i = 0; i < cometCount; i++) {
      final raw = _pulsePhase * cometSpeed + i * stepLen;
      final py = raw % fullLen; // parte da 0 (punta cono)

      // Trail: 5 sfere fading dietro (era 3 → estese per coprire gap residui).
      for (int t = 1; t <= 5; t++) {
        final trailY = py - t * cometR;
        if (trailY < 0) continue;
        final trailAlpha = 0.55 * (1.0 - t / 6.0);
        _laserPulsePaint.color =
            const Color(0xFFFF3322).withValues(alpha: trailAlpha);
        canvas.drawCircle(
            Offset(0, trailY), cometR * (1.0 - t * 0.16), _laserPulsePaint);
      }

      // Halo esterno rosso
      _laserPulsePaint.color =
          const Color(0xFFFF1100).withValues(alpha: 0.5);
      canvas.drawCircle(Offset(0, py), cometR * 1.4, _laserPulsePaint);
      // Mid arancione caldo
      _laserPulsePaint.color =
          const Color(0xFFFFAA22).withValues(alpha: 0.85);
      canvas.drawCircle(Offset(0, py), cometR * 0.85, _laserPulsePaint);
      // Nucleus bianco caldo
      _laserPulsePaint.color =
          const Color(0xFFFFFFFF).withValues(alpha: 0.95);
      canvas.drawCircle(Offset(0, py), cometR * 0.45, _laserPulsePaint);
    }

    // SECONDARY STREAM — 16 puntini con offset spaziale +0.5 step (cade
    // nel mezzo del gap tra comete primarie) → riempie ogni "dark zone"
    // del fascio. Più piccoli per non distrarre dalle comete principali.
    // Bumpato 2.8→3.2 (review caveman): nucleus secR*0.6 a sizeMultiplier=1
    // era 1.68px → rischio sub-pixel disappear su low-DPI; ora 1.92px →
    // più affidabile mantenendo gerarchia visiva con primarie.
    final secR = 3.2 * sizeMultiplier;
    for (int i = 0; i < cometCount; i++) {
      final raw = _pulsePhase * cometSpeed + (i + 0.5) * stepLen;
      final py = raw % fullLen;
      _laserPulsePaint.color =
          const Color(0xFFFF6633).withValues(alpha: 0.7);
      canvas.drawCircle(Offset(0, py), secR * 1.4, _laserPulsePaint);
      _laserPulsePaint.color =
          const Color(0xFFFFEEAA).withValues(alpha: 0.95);
      canvas.drawCircle(Offset(0, py), secR * 0.6, _laserPulsePaint);
    }

    // ─── ELECTRIC CRACKLE (5 puntini bianchi sui bordi del beam) ───
    const crackleCount = 5;
    for (int i = 0; i < crackleCount; i++) {
      final crackleSeed = (i * 73 + (_pulsePhase * 12).toInt()) % 100;
      if (crackleSeed > 60) continue;
      final crackleY = coneLen + (crackleSeed / 100.0) * pulseLen;
      final crackleX = (crackleSeed % 2 == 0 ? 1 : -1) *
          (glowW * 0.55 + (crackleSeed % 7) * 0.5);
      _laserPulsePaint.color =
          const Color(0xFFFFFFFF).withValues(alpha: 0.85);
      canvas.drawCircle(
          Offset(crackleX, crackleY), 1.4 * sizeMultiplier, _laserPulsePaint);
    }

    canvas.restore();
  }
}

class PlasmaBullet extends PositionComponent
    with HasGameReference<GeometryFightGame>, CollisionCallbacks {
  final Vector2 direction;
  final double damage;
  final double sizeMultiplier;

  late Vector2 _velocity;
  double _phase = 0;

  /// Guard contro double-explode: stesso motivo di HomingMissile._detonated.
  /// Collisioni multiple nello stesso frame → _explode chiamato N volte
  /// prima di removeFromParent → AoE e particelle N volte.
  bool _exploded = false;

  PlasmaBullet({required this.direction, this.damage = 3, this.sizeMultiplier = 1.0})
      : super(size: Vector2(20 * sizeMultiplier, 20 * sizeMultiplier), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    if (direction.length2 < 1e-6) {
      _velocity = Vector2(350, 0);
    } else {
      _velocity = direction.normalized() * 350;
    }
    // Hitbox circolare scalata con sizeMultiplier: con Firepower (x2) il
    // visual cresce ~2.4x e la hitbox default (size/2) tagliava fuori i
    // nemici vicini al bordo visuale.
    add(CircleHitbox(
      radius: 10 * sizeMultiplier,
      anchor: Anchor.center,
    )..position = size / 2);
  }

  @override
  void update(double dt) {
    super.update(dt);
    final realDt = dt / game.timeScale.clamp(0.3, 1.0);
    position += _velocity * realDt;
    _phase += realDt * 10;

    if (game.isTunnelMode) {
      final cameraLeft = game.camera.viewfinder.position.x - (game.size.x > 0 ? game.size.x / 2 : 400) - 200;
      final (topWall, bottomWall) = game.tunnelWallsAtX(position.x);
      if (position.x < cameraLeft || position.y <= topWall || position.y >= bottomWall ||
          (position - game.player.position).length > 1200) {
        removeFromParent();
        return;
      }
      // Muri rossi tunnel: plasma esplode (simula hit su muro).
      if (game.hitsTunnelObstacle(position)) {
        _explode(null);
        removeFromParent();
        return;
      }
    } else {
      // Arena: distruggi al bordo esatto
      if (position.x < 0 || position.x > arenaWidth ||
          position.y < 0 || position.y > arenaHeight) {
        removeFromParent();
        return;
      }
    }
  }

  static final _plasmaGlowOuter = Paint();
  static final _plasmaGlowMid = Paint();
  static final _plasmaGlowInner = Paint();
  static final _plasmaBodyPaint = Paint();
  static final _plasmaCorePaint = Paint();

  @override
  void render(Canvas canvas) {
    // Palla plasma FLUO + lampeggiante (richiesta utente).
    // _phase avanza rapidamente → sin oscilla tra ~0 e 1 per il flicker.
    final pulse = 0.6 + 0.4 * (0.5 + 0.5 * math.sin(_phase * 2.0));
    final blink = 0.7 + 0.3 * math.sin(_phase * 6.0); // lampeggio veloce
    final baseRadius = (10 + math.sin(_phase) * 2) * sizeMultiplier;
    final center = Offset(size.x / 2, size.y / 2);

    // 3 strati di glow concentrici per effetto neon fluo intenso
    _plasmaGlowOuter.color =
        NeonColors.plasmaViolet.withValues(alpha: 0.25 * pulse);
    canvas.drawCircle(center, baseRadius * 2.4, _plasmaGlowOuter);

    _plasmaGlowMid.color =
        NeonColors.plasmaViolet.withValues(alpha: 0.5 * pulse);
    canvas.drawCircle(center, baseRadius * 1.8, _plasmaGlowMid);

    _plasmaGlowInner.color =
        NeonColors.plasmaViolet.withValues(alpha: 0.8 * pulse);
    canvas.drawCircle(center, baseRadius * 1.3, _plasmaGlowInner);

    // Core viola pieno (blink veloce sopra)
    _plasmaBodyPaint.color = NeonColors.plasmaViolet;
    canvas.drawCircle(center, baseRadius, _plasmaBodyPaint);

    // Nucleo bianco acceso che lampeggia (fluo extra)
    _plasmaCorePaint.color = const Color(0xFFFFFFFF).withValues(alpha: blink);
    canvas.drawCircle(center, baseRadius * 0.45, _plasmaCorePaint);
  }

  void _explode(PositionComponent? directHit) {
    if (_exploded) return;
    _exploded = true;
    // Firepower in-game raddoppia raggio esplosione (80 → 160).
    final explosionRadius = 80 * sizeMultiplier;

    // FIX: applica SEMPRE il danno al bersaglio colpito direttamente.
    // Boss grandi (es. TheGridBoss 200x200) hanno il centro a ~100px dal
    // punto di collisione, fuori dal raggio 80px → l'esplosione AoE
    // falliva e il boss non prendeva danno.
    if (directHit is EnemyBase && !directHit.isSpawnInvulnerable) {
      directHit.takeDamage(damage);
    } else if (directHit is BossBase) {
      directHit.takeDamage(damage);
    }

    // AoE: danneggia tutti gli altri nel raggio (split damage tra bersagli
    // vicini). Non ri-colpisce il directHit grazie al check `identical`.
    // AoE = danno ad AREA → splitter immuni (evita cascata split).
    for (final child in game.world.children) {
      if (identical(child, directHit)) continue;
      if (child is EnemyBase) {
        if (child.isSpawnInvulnerable) continue;
        if (child.position.distanceTo(position) < explosionRadius) {
          child.takeDamage(damage, isArea: true);
        }
      } else if (child is BossBase) {
        if (child.position.distanceTo(position) < explosionRadius) {
          child.takeDamage(damage);
        }
      }
    }
    game.spawnExplosion(position, NeonColors.plasmaViolet,
        radius: explosionRadius);
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    // Passa attraverso nemici in materializzazione
    if (other is EnemyBase && other.isSpawnInvulnerable) return;
    if (other is EnemyBase || other is BossBase) {
      _explode(other);
      removeFromParent();
    }
    super.onCollisionStart(intersectionPoints, other);
  }
}

class HomingMissile extends PositionComponent
    with HasGameReference<GeometryFightGame>, CollisionCallbacks {
  final Vector2 direction;
  final double damage;
  final double sizeMultiplier;

  /// Volee id: permette a una salva di 5 missili di selezionare 5 bersagli
  /// DISTINTI (richiesta utente). Due missili della stessa salva non
  /// sceglieranno mai lo stesso nemico finché esistono abbastanza nemici.
  final int volleyId;

  /// Raggio d'esplosione AoE. Il diametro (2 * raggio) deve essere almeno
  /// 2x la dimensione del missile (richiesta utente): size missile = 16,
  /// diametro minimo 32 → raggio minimo 16. Qui 48 → diametro 96 → 6x la
  /// dimensione missile. Ampio ma consistente con la "gravitas" dei missili.
  static const double baseExplosionRadius = 48.0;

  /// Tracker globale: chi ha preso di mira cosa, per voleeId. Evita che
  /// due missili della stessa salva convergano sullo stesso nemico.
  /// key = volleyId, value = set di bersagli già scelti da quella salva.
  static final Map<int, Set<PositionComponent>> _volleyTargets = {};
  static int _nextVolleyId = 0;
  static int nextVolleyId() => _nextVolleyId++;

  /// Contatore globale dei missili attivi. Usato dal player per cap a 20
  /// (30 con rapidFire). Incrementato in onLoad, decrementato in onRemove.
  static int _activeCount = 0;
  static int get activeCount => _activeCount;

  /// Reset stato statico per nuova partita (chiamato da restartGame).
  /// Azzera contatore attivi, cache bersagli salva e sequenza volleyId.
  /// Necessario perché i missili rimossi a fine run possono lasciare il
  /// counter sporco se qualche onRemove non scatta (es. game reset brusco).
  static void resetStaticState() {
    _activeCount = 0;
    _volleyTargets.clear();
    _nextVolleyId = 0;
  }

  late Vector2 _velocity;
  double _lifetime = 3.0;
  double _flamePhase = 0;
  PositionComponent? _cachedTarget;
  int _searchCooldown = 0;

  /// Guard contro double-detonate: `removeFromParent()` è async in Flame.
  /// Se il missile collide con 2 nemici nello stesso frame, `_detonate`
  /// verrebbe chiamato due volte prima che la rimozione sia processata
  /// → AoE doppio, esplosione visiva doppia, screen shake doppio.
  bool _detonated = false;

  double get explosionRadius => baseExplosionRadius * sizeMultiplier;

  HomingMissile({
    required this.direction,
    required this.volleyId,
    this.damage = 1.5,
    this.sizeMultiplier = 1.0,
  }) : super(
            size: Vector2(8 * sizeMultiplier, 16 * sizeMultiplier),
            anchor: Anchor.center) {
    // Increment sincrono (NON in onLoad async): `player._shoot` legge
    // `activeCount` subito dopo la salva prima che `onLoad` completi →
    // con increment async si spawnavano missili oltre il cap.
    _activeCount++;
  }

  @override
  Future<void> onLoad() async {
    if (direction.length2 < 1e-6) {
      _velocity = Vector2(500, 0);
    } else {
      _velocity = direction.normalized() * 500;
    }
    add(RectangleHitbox());
  }

  /// Seleziona il bersaglio più vicino NON già scelto da altri missili
  /// della stessa salva. Se tutti i nemici esistenti sono già "prenotati",
  /// cade in fallback sul più vicino assoluto (comunque danno utile).
  /// Limita la ricerca entro `homingTrackRadius` (150px, vedi constants.dart).
  PositionComponent? _pickDistinctTarget() {
    final claimed = _volleyTargets.putIfAbsent(volleyId, () => <PositionComponent>{});
    // Pulisci bersagli rimossi dalla memoria della salva
    claimed.removeWhere((c) => c.isRemoved);

    PositionComponent? best;
    double bestDist = homingTrackRadius;
    PositionComponent? fallback;
    double fallbackDist = homingTrackRadius;

    for (final child in game.world.children) {
      PositionComponent? candidate;
      double? dist;
      if (child is EnemyBase) {
        candidate = child;
        dist = child.position.distanceTo(position);
      } else if (child is BossBase) {
        candidate = child;
        dist = child.position.distanceTo(position);
      }
      if (candidate == null || dist == null) continue;
      if (dist > homingTrackRadius) continue; // Fuori raggio inseguimento

      if (dist < fallbackDist) {
        fallbackDist = dist;
        fallback = candidate;
      }
      if (!claimed.contains(candidate) && dist < bestDist) {
        bestDist = dist;
        best = candidate;
      }
    }

    final chosen = best ?? fallback;
    if (chosen != null) claimed.add(chosen);
    return chosen;
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Target search throttled: ogni 5 frame, o se target morto/perso.
    _searchCooldown--;
    final cached = _cachedTarget;
    if (_searchCooldown <= 0 ||
        cached == null ||
        cached.isRemoved) {
      _searchCooldown = 5;
      // Se stiamo switchando bersaglio, libera il vecchio claim così altri
      // missili della salva possono puntarlo. Altrimenti il claimed set
      // cresce sporcando la distinzione per tutta la durata del missile.
      final oldTarget = _cachedTarget;
      _cachedTarget = _pickDistinctTarget();
      if (oldTarget != null && !identical(oldTarget, _cachedTarget)) {
        _volleyTargets[volleyId]?.remove(oldTarget);
      }
    }

    // Steering (NaN guard: se target coincide col missile, skip normalize).
    final target = _cachedTarget;
    if (target != null && !target.isRemoved) {
      final toTarget = target.position - position;
      if (toTarget.length2 > 1e-6) {
        final desired = toTarget.normalized() * 500;
        final steering = (desired - _velocity)..clampLength(0, 800 * dt);
        _velocity += steering;
        if (_velocity.length > 500) {
          _velocity = _velocity.normalized() * 500;
        }
      }
    }

    position += _velocity * dt;
    _flamePhase += dt * 30;
    _lifetime -= dt;
    if (_lifetime <= 0) {
      _releaseVolleyClaim();
      removeFromParent();
      return;
    }

    // Border check: missile contro muri → detonazione (AoE only, no target).
    // Tutte le modalità: arena (4 bordi) + tunnel (muri dinamici + cull sx).
    if (game.isTunnelMode) {
      final cameraLeft = game.camera.viewfinder.position.x -
          (game.size.x > 0 ? game.size.x / 2 : 400) - 200;
      final (topWall, bottomWall) = game.tunnelWallsAtX(position.x);
      if (position.x < cameraLeft ||
          position.y <= topWall ||
          position.y >= bottomWall ||
          game.hitsTunnelObstacle(position)) {
        _detonate(null);
        return;
      }
    } else {
      if (position.x < 0 ||
          position.x > arenaWidth ||
          position.y < 0 ||
          position.y > arenaHeight) {
        _detonate(null);
        return;
      }
    }
  }

  void _releaseVolleyClaim() {
    // Libera il claim sul bersaglio quando il missile sparisce (timeout
    // o esplosione) così il tracker non cresca indefinitamente.
    final set = _volleyTargets[volleyId];
    if (set != null) {
      if (_cachedTarget != null) set.remove(_cachedTarget);
      if (set.isEmpty) _volleyTargets.remove(volleyId);
    }
  }

  @override
  void onRemove() {
    _releaseVolleyClaim();
    // Decrementa il contatore attivi (cap homing) e clamp a 0 per sicurezza
    // in caso di double-remove (Flame può chiamare onRemove più volte in
    // edge cases con restart della partita).
    if (_activeCount > 0) _activeCount--;
    super.onRemove();
  }

  static final _homingBodyPaint = Paint();
  static final _homingFinPaint = Paint();
  static final _homingNosePaint = Paint();
  static final _homingFlameOuter = Paint();
  static final _homingFlameInner = Paint();
  static final _homingFlameCore = Paint();

  // Path cache: fin + nose dipendono solo da bodyW/bodyH (costanti per
  // sizeMultiplier). Cachiamo sul primo render per missile e riutilizziamo.
  // Con 20-30 missili attivi risparmiamo 40-60 Path alloc/frame.
  Path? _finPath;
  Path? _nosePath;
  double _cachedBodyW = -1;

  @override
  void render(Canvas canvas) {
    // Missile renderizzato come silhouette vera: corpo cilindrico, punta
    // conica, pinne posteriori, scia-fiamma animata. Prima era un banale
    // rettangolo ciano.
    final cx = size.x / 2;
    final cy = size.y / 2;
    final angle = math.atan2(_velocity.y, _velocity.x) + math.pi / 2;
    final bodyW = size.x;
    final bodyH = size.y;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(angle);

    // Fiamma posteriore (dietro al corpo) — flicker veloce
    final flicker = 1.0 + math.sin(_flamePhase) * 0.25;
    final flameLen = bodyH * 0.8 * flicker;
    _homingFlameOuter.color = const Color(0xFFFF2200).withValues(alpha: 0.5);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, bodyH * 0.55 + flameLen * 0.3),
          width: bodyW * 1.3, height: flameLen * 1.2),
      _homingFlameOuter,
    );
    _homingFlameInner.color = const Color(0xFFFF8800).withValues(alpha: 0.85);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, bodyH * 0.52 + flameLen * 0.25),
          width: bodyW * 0.85, height: flameLen * 0.85),
      _homingFlameInner,
    );
    _homingFlameCore.color = const Color(0xFFFFFFDD);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, bodyH * 0.5 + flameLen * 0.2),
          width: bodyW * 0.5, height: flameLen * 0.5),
      _homingFlameCore,
    );

    // Pinne + naso: cache lazy per evitare `Path()` alloc ogni frame.
    // Rebuild solo se bodyW cambia (non succede durante lifetime del missile).
    if (_cachedBodyW != bodyW) {
      _cachedBodyW = bodyW;
      _finPath = Path()
        ..moveTo(-bodyW * 0.5, bodyH * 0.25)
        ..lineTo(-bodyW * 1.0, bodyH * 0.55)
        ..lineTo(-bodyW * 0.5, bodyH * 0.55)
        ..close()
        ..moveTo(bodyW * 0.5, bodyH * 0.25)
        ..lineTo(bodyW * 1.0, bodyH * 0.55)
        ..lineTo(bodyW * 0.5, bodyH * 0.55)
        ..close();
      _nosePath = Path()
        ..moveTo(-bodyW * 0.5, -bodyH * 0.35)
        ..lineTo(0, -bodyH * 0.65)
        ..lineTo(bodyW * 0.5, -bodyH * 0.35)
        ..close();
    }

    _homingFinPaint.color = NeonColors.cyan.withValues(alpha: 0.9);
    canvas.drawPath(_finPath!, _homingFinPaint);

    // Corpo cilindrico (rettangolo arrotondato)
    _homingBodyPaint.color = NeonColors.cyan;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(0, bodyH * 0.05),
            width: bodyW, height: bodyH * 0.8),
        Radius.circular(bodyW * 0.25),
      ),
      _homingBodyPaint,
    );

    // Punta conica (naso bianco)
    _homingNosePaint.color = const Color(0xFFE0FFFF);
    canvas.drawPath(_nosePath!, _homingNosePaint);

    canvas.restore();
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is EnemyBase) {
      // Passa attraverso nemici in materializzazione
      if (other.isSpawnInvulnerable) return;
      _detonate(other);
    }
    if (other is BossBase) {
      _detonate(other);
    }
    super.onCollisionStart(intersectionPoints, other);
  }

  /// `target` nullable: quando la detonazione è border-triggered (muri
  /// arena/tunnel) non c'è direct hit — solo AoE.
  void _detonate(PositionComponent? target) {
    if (_detonated) return;
    _detonated = true;
    final radius = explosionRadius;

    // Direct hit al bersaglio (se presente).
    if (target is EnemyBase && !target.isSpawnInvulnerable) {
      target.takeDamage(damage);
    } else if (target is BossBase) {
      target.takeDamage(damage);
    }

    // AoE su tutti gli altri nel raggio. Splitter immuni ad area (tranne
    // direct hit, escluso via `identical(child, target)`).
    for (final child in game.world.children) {
      if (target != null && identical(child, target)) continue;
      if (child is EnemyBase) {
        if (child.isSpawnInvulnerable) continue;
        if (child.position.distanceTo(position) < radius) {
          child.takeDamage(damage, isArea: true);
        }
      } else if (child is BossBase) {
        if (child.position.distanceTo(position) < radius) {
          child.takeDamage(damage);
        }
      }
    }

    game.spawnExplosion(position, NeonColors.cyan,
        radius: radius, particleCount: 14);
    game.spawnExplosion(position, const Color(0xFFFF8800),
        radius: radius * 0.6, particleCount: 8);
    removeFromParent();
  }
}

/// Iter 14 (utente): Gauss Cannon proiettile dedicato. Visual = swirl di
/// piccoli cerchi viola che convergono verso il core. All'impatto con un
/// nemico/boss OR a fine vita (maxDistance/lifetime) spawna un
/// `GaussImplosion` di 2s sul punto di impatto: pull enemies + tick dmg.
///
/// Sostituisce il vecchio `PlayerBullet` con `weaponType == gauss`. Non
/// pierce (un solo trigger), non bounce. Damage diretto = `damage` (forte,
/// stessa scala di Homing per-missile: tipicamente 1.0 × 4.0 × game mults).
class GaussBullet extends PositionComponent
    with HasGameReference<GeometryFightGame>, CollisionCallbacks {
  final Vector2 direction;
  final double speed;
  final double damage;
  final double sizeMultiplier;
  late Vector2 _velocity;
  double _distanceTravelled = 0;
  double _lifetime = bulletLifetime;
  double _phase = 0;

  /// Guard contro double-impact nello stesso frame: stesso pattern di
  /// HomingMissile._detonated. removeFromParent è async → 2 collision
  /// possono triggerare 2 implosioni prima della rimozione.
  bool _imploded = false;

  GaussBullet({
    required this.direction,
    this.speed = bulletSpeed,
    this.damage = 4.0,
    this.sizeMultiplier = 1.0,
  }) : super(
            size: Vector2(24 * sizeMultiplier, 24 * sizeMultiplier),
            anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    if (direction.length2 < 1e-6) {
      _velocity = Vector2(speed, 0);
    } else {
      _velocity = direction.normalized() * speed;
    }
    // Hitbox circolare al centro del core swirl.
    add(CircleHitbox(radius: 6 * sizeMultiplier, anchor: Anchor.center)
      ..position = size / 2);
  }

  @override
  void update(double dt) {
    super.update(dt);
    final realDt = dt / game.timeScale.clamp(0.3, 1.0);
    _phase += realDt;
    position += _velocity * realDt;
    _distanceTravelled += _velocity.length * realDt;
    _lifetime -= realDt;

    // Border / lifetime / maxDistance: trigger implosion anche se non
    // colpisce nessuno (richiesta utente esplicita).
    if (game.isTunnelMode) {
      final cameraLeft = game.camera.viewfinder.position.x -
          (game.size.x > 0 ? game.size.x / 2 : 400) - 200;
      if (position.x < cameraLeft) {
        _explode();
        return;
      }
      final (topWall, bottomWall) = game.tunnelWallsAtX(position.x);
      if (position.y <= topWall || position.y >= bottomWall) {
        _explode();
        return;
      }
      if (game.hitsTunnelObstacle(position)) {
        _explode();
        return;
      }
    } else {
      if (position.x < 0 ||
          position.x > arenaWidth ||
          position.y < 0 ||
          position.y > arenaHeight) {
        _explode();
        return;
      }
    }
    if (_distanceTravelled > 900 || _lifetime <= 0) {
      _explode();
      return;
    }
  }

  void _explode({PositionComponent? directHit}) {
    if (_imploded) return;
    _imploded = true;
    // Direct hit damage (se presente).
    if (directHit is EnemyBase && !directHit.isSpawnInvulnerable) {
      directHit.takeDamage(damage);
    } else if (directHit is BossBase) {
      directHit.takeDamage(damage);
    }
    // Spawn implosion (pull + tick damage gestiti dal component).
    // FirePower → bullet spawnato con sizeMultiplier=2.0 → implosion
    // `scale=2.0` → AOE pull/damage radius raddoppiato. Uso `sizeMultiplier`
    // come fonte di verità invece di leggere `player.hasFirePower` al
    // momento dell'impatto: così il power-up può scadere tra spawn-bullet
    // e impatto senza desync visivo/meccanico.
    game.world.add(GaussImplosion(
      epicenter: position.clone(),
      aoeScale: sizeMultiplier,
    ));
    removeFromParent();
  }

  // Paint cache instance-level (1 bullet vivo alla volta tipicamente —
  // alloc 3 Paint per bullet OK, lifetime ~1s).
  final Paint _swirlPaint = Paint();
  final Paint _glowPaint = Paint();
  final Paint _corePaint = Paint();

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final s = sizeMultiplier;

    // Glow esterno viola.
    _glowPaint.color =
        const Color(0xFFCC66FF).withValues(alpha: 0.35);
    canvas.drawCircle(Offset(cx, cy), 11 * s, _glowPaint);
    _glowPaint.color =
        const Color(0xFFCC66FF).withValues(alpha: 0.55);
    canvas.drawCircle(Offset(cx, cy), 7 * s, _glowPaint);

    // Swirl: 10 piccoli cerchi che orbitano a 2 raggi differenti, ruotando.
    // Distanza dal centro decresce con sin(_phase * speed + i) → effetto
    // "converging into the core". Ogni cerchio piccolo è viola brillante.
    const swirlCount = 10;
    for (int i = 0; i < swirlCount; i++) {
      final ang = _phase * 8 + (i * math.pi * 2 / swirlCount);
      // Modulazione raggio: pulsa verso il centro continuamente.
      final radiusMod =
          0.55 + 0.45 * (math.sin(_phase * 4 + i * 0.7) * 0.5 + 0.5);
      final r = 9 * s * radiusMod;
      final sx = cx + math.cos(ang) * r;
      final sy = cy + math.sin(ang) * r;
      // Alpha più alta quando vicino al centro (illusione "trascinato dentro").
      final convergedness = 1.0 - (r / (9 * s));
      final alpha = (0.5 + convergedness * 0.45).clamp(0.0, 1.0);
      _swirlPaint.color =
          const Color(0xFFCC66FF).withValues(alpha: alpha);
      canvas.drawCircle(Offset(sx, sy), 1.6 * s, _swirlPaint);

      // Trail dot leggermente sfasato per dare senso di rotazione fluida.
      final tang = ang - 0.35;
      final tx = cx + math.cos(tang) * r;
      final ty = cy + math.sin(tang) * r;
      _swirlPaint.color =
          const Color(0xFFAA44EE).withValues(alpha: alpha * 0.55);
      canvas.drawCircle(Offset(tx, ty), 1.1 * s, _swirlPaint);
    }

    // Core centrale: nucleo viola brillante che pulsa.
    final corePulse =
        0.75 + 0.25 * math.sin(_phase * 14);
    _corePaint.color =
        const Color(0xFFCC66FF).withValues(alpha: corePulse);
    canvas.drawCircle(Offset(cx, cy), 3.2 * s, _corePaint);
    _corePaint.color =
        const Color(0xFFFFFFFF).withValues(alpha: corePulse * 0.9);
    canvas.drawCircle(Offset(cx, cy), 1.6 * s, _corePaint);
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    if (_imploded) return;
    if (other is EnemyBase) {
      if (other.isSpawnInvulnerable) return;
      _explode(directHit: other);
    } else if (other is BossBase) {
      _explode(directHit: other);
    }
    super.onCollisionStart(intersectionPoints, other);
  }
}

class OverdriveBeam extends PositionComponent
    with HasGameReference<GeometryFightGame> {
  final Vector2 direction;
  double _lifetime = 3.0;
  double _phase = 0;
  int _walkFrame = 0;

  OverdriveBeam({required this.direction})
      : super(size: Vector2(overdriveBeamWidth, overdriveBeamLength), anchor: Anchor.topCenter);

  @override
  void update(double dt) {
    super.update(dt);
    // Overdrive beam NON affetto dal slow-motion: compensa il timeScale.
    final realDt = dt / game.timeScale.clamp(0.3, 1.0);
    _lifetime -= realDt;
    _phase += realDt * 20;
    if (_lifetime <= 0) {
      removeFromParent();
      return;
    }

    _walkFrame++;
    if (_walkFrame > 1 << 20) _walkFrame = 0;
    if ((_walkFrame & 1) == 0) {
      // Kill everything in path (enemies AND bosses) — raycast = danno ad AREA → splitter immuni
      final dir = direction.normalized();
      final toRemove = <EnemyBullet>[];
      for (final child in game.world.children) {
        if (child is EnemyBase) {
          final toEnemy = child.position - position;
          final dot = toEnemy.dot(dir);
          if (dot > 0 && dot < overdriveBeamLength) {
            final perpDist = (toEnemy - dir * dot).length;
            if (perpDist < 30) {
              child.takeDamage(999, isArea: true);
            }
          }
        } else if (child is BossBase) {
          final toBoss = child.position - position;
          final dot = toBoss.dot(dir);
          if (dot > 0 && dot < overdriveBeamLength) {
            final perpDist = (toBoss - dir * dot).length;
            if (perpDist < 30) {
              child.takeDamage(10); // Danno boss dall'overdrive
            }
          }
        } else if (child is EnemyBullet) {
          final toB = child.position - position;
          final dot = toB.dot(dir);
          if (dot > 0 && dot < overdriveBeamLength) {
            final perpDist = (toB - dir * dot).length;
            if (perpDist < 30) {
              toRemove.add(child);
            }
          }
        }
      }
      for (final b in toRemove) {
        b.removeFromParent();
      }
    }
  }

  static final _odGlowPaint = Paint();
  static final _odCorePaint = Paint();
  static final _odEdgePaint = Paint();

  @override
  void render(Canvas canvas) {
    final angle = math.atan2(direction.y, direction.x) - math.pi / 2;
    canvas.save();
    canvas.translate(size.x / 2, 0);
    canvas.rotate(angle);

    // Rainbow effect
    final hue = (_phase * 30) % 360;
    final rainbowColor =
        HSVColor.fromAHSV(1.0, hue, 1.0, 1.0).toColor();

    // Glow (no blur — overdrive is rare but still saves GPU)
    _odGlowPaint.color = rainbowColor.withValues(alpha: 0.3);
    canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: 60, height: overdriveBeamLength), _odGlowPaint);

    // Core - white
    _odCorePaint.color = const Color(0xFFFFFFFF);
    canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: 20, height: overdriveBeamLength), _odCorePaint);

    // Colored edge
    _odEdgePaint.color = rainbowColor.withValues(alpha: 0.5);
    canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: overdriveBeamWidth, height: overdriveBeamLength), _odEdgePaint);

    canvas.restore();
  }
}

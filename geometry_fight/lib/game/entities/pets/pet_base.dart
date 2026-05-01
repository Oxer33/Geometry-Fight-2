import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../../data/constants.dart';
import '../../../data/pet_types.dart';
import '../../game_world.dart';
import '../enemies/black_hole_enemy.dart';
import '../enemies/enemy_base.dart';
import '../geom.dart';
import '../player.dart';
import '../projectiles.dart';

/// Pet companion base (Geometry Wars 3 style drone). Vola accanto/attorno
/// al player con comportamento e grafica per-tipo override-able.
abstract class PetBase extends PositionComponent
    with HasGameReference<GeometryFightGame> {
  final PetDef def;
  double phase = 0;

  PetBase(this.def)
      : super(size: Vector2(28, 28), anchor: Anchor.center);

  static final _rng = math.Random();

  // Cached aim direction — calcolato 1× per frame in update(), riusato in
  // render() invece di ricalcolare via O(N) walk world.children per ogni
  // chiamata. Caveman-review: prima `_currentAim` veniva chiamato anche
  // in render → 60fps × N world children × 4 pet rendering = 12k iter/sec
  // sprecate. Ora compute-once-per-frame.
  Vector2 cachedAim = Vector2(1, 0);

  @override
  void update(double dt) {
    super.update(dt);
    phase += dt;
    cachedAim = _computeAim();
    onPetUpdate(dt);
  }

  /// Override per-tipo. Override può accedere a `game.player`, `game.world.children`.
  void onPetUpdate(double dt);

  // ── helper condivisi ────────────────────────────────────────────────────

  /// True se il nemico è un target valido per pet melee/auto-kill.
  /// Esclude BlackHole (banalizzerebbe wave VOID FIELD + boss meccaniche)
  /// e nemici in spawn-invuln (fair-play: aspetta che si materializzino).
  static bool isValidPetTarget(EnemyBase e) {
    if (e is BlackHoleEnemy) return false;
    if (e.isSpawnInvulnerable) return false;
    return true;
  }

  EnemyBase? findNearestEnemy({double maxDist = 600}) {
    EnemyBase? best;
    double bestD = maxDist;
    for (final c in game.world.children) {
      if (c is EnemyBase && isValidPetTarget(c)) {
        final d = c.position.distanceTo(position);
        if (d < bestD) {
          bestD = d;
          best = c;
        }
      }
    }
    return best;
  }

  /// Direzione di mira corrente: aimInput se presente, altrimenti il player
  /// punta verso il nemico più vicino (proxy semplice). Usato dai pet che
  /// sparano "in direzione player". CHIAMATO 1× per frame da `update()` →
  /// risultato in `cachedAim`. NON chiamare da render() (perf O(N)).
  Vector2 _computeAim() {
    final aim = game.aimInput;
    if (aim.length > 0.01) return aim.normalized();
    final nearest = findNearestEnemy(maxDist: 800);
    if (nearest != null) {
      final to = nearest.position - game.player.position;
      if (to.length > 0.01) return to.normalized();
    }
    return Vector2(1, 0);
  }
}

// ═══════════════════════════════════════════════════════════════════════
// 1. ATTACK PET — segue player, spara raffiche extra (3× rate)
// ═══════════════════════════════════════════════════════════════════════
class AttackPet extends PetBase {
  AttackPet() : super(kPetCatalog[0]);
  // Fire rate: 0.17s = 3× più veloce di prima (era 0.5s) — richiesta utente.
  static const _shootInterval = 0.17;
  double _shootTimer = 0;

  @override
  void onPetUpdate(double dt) {
    final target = game.player.position +
        Vector2(math.cos(phase * 1.2), math.sin(phase * 1.2)) * 50;
    final to = target - position;
    if (to.length > 1) position += to.normalized() * 200 * dt;

    _shootTimer -= dt;
    if (_shootTimer <= 0) {
      _shootTimer = _shootInterval;
      // Clone: cachedAim è ref mutata ogni frame da update(); senza clone
      // bullet onLoad async potrebbe leggere aim del frame successivo.
      final dir = cachedAim.clone();
      final bullet = PlayerBullet(
          direction: dir,
          weaponType: WeaponType.basic,
          damage: 0.7,
          color: def.color,
          sizeMultiplier: 0.7);
      bullet.position = position.clone();
      game.world.add(bullet);
    }
  }

  // ─── render: dart-shape rosso/giallo con doppia bocca cannone ───
  static final _outlinePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.6;
  static final _fillPaint = Paint();
  static final _glowPaint = Paint();

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final pulse = 0.6 + math.sin(phase * 6) * 0.4;
    // Glow alone
    _glowPaint.color = def.color.withValues(alpha: 0.45 * pulse);
    canvas.drawCircle(Offset(cx, cy), 14, _glowPaint);
    // Body diamond pointing forward (rotates with aim)
    final aim = math.atan2(cachedAim.y, cachedAim.x);
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(aim);
    final path = Path()
      ..moveTo(11, 0)
      ..lineTo(0, 7)
      ..lineTo(-7, 0)
      ..lineTo(0, -7)
      ..close();
    _fillPaint.color = def.color;
    canvas.drawPath(path, _fillPaint);
    _outlinePaint.color = const Color(0xFFFFFFFF);
    canvas.drawPath(path, _outlinePaint);
    // Twin barrels (parallel slots forward)
    _fillPaint.color = const Color(0xFFFFFFFF);
    canvas.drawRect(Rect.fromLTWH(2, -4, 9, 1.5), _fillPaint);
    canvas.drawRect(Rect.fromLTWH(2, 2.5, 9, 1.5), _fillPaint);
    canvas.restore();
  }
}

// ═══════════════════════════════════════════════════════════════════════
// 2. COLLECT PET — auto-raccoglie geoms entro 80px, magnetizza globale
// ═══════════════════════════════════════════════════════════════════════
class CollectPet extends PetBase {
  CollectPet() : super(kPetCatalog[1]);
  Vector2 _wanderTarget = Vector2.zero();
  double _wanderTimer = 0;

  @override
  void onPetUpdate(double dt) {
    // Wandering verso geom più vicino (se presente) invece di random.
    Geom? nearestGeom;
    double nearestD = 800;
    for (final c in game.world.children) {
      if (c is Geom) {
        final d = c.position.distanceTo(position);
        if (d < nearestD) {
          nearestD = d;
          nearestGeom = c;
        }
      }
    }
    if (nearestGeom != null) {
      _wanderTarget = nearestGeom.position;
      _wanderTimer = 0.5;
    } else {
      _wanderTimer -= dt;
      if (_wanderTimer <= 0 || position.distanceTo(_wanderTarget) < 40) {
        _wanderTimer = 1.5 + PetBase._rng.nextDouble() * 1.5;
        _wanderTarget = Vector2(
          20 + PetBase._rng.nextDouble() * (arenaWidth - 40),
          20 + PetBase._rng.nextDouble() * (arenaHeight - 40),
        );
      }
    }
    final to = _wanderTarget - position;
    if (to.length > 1) position += to.normalized() * 380 * dt;

    // Physical pickup (utente: "deve proprio andare in giro e fisicamente
    // raccogliere i geom"). Geom entro 25px → collect direct + remove.
    // Pet contribuisce al gold sessione bypassando magnet logic player.
    final pickups = <Geom>[];
    for (final c in game.world.children) {
      if (c is Geom && c.position.distanceTo(position) < 25) {
        pickups.add(c);
      }
    }
    for (final g in pickups) {
      game.collectGeom(g.value);
      g.removeFromParent();
    }
  }

  // ─── render: hexagon cyan con cerchio ring rotante ───
  static final _outlinePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.6;
  static final _fillPaint = Paint();
  static final _glowPaint = Paint();
  static final _ringPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final pulse = 0.6 + math.sin(phase * 5) * 0.4;
    // Glow esterno
    _glowPaint.color = def.color.withValues(alpha: 0.45 * pulse);
    canvas.drawCircle(Offset(cx, cy), 14, _glowPaint);
    // Hexagon body
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(phase * 0.5);
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final a = i * math.pi / 3;
      final x = math.cos(a) * 8;
      final y = math.sin(a) * 8;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    _fillPaint.color = def.color;
    canvas.drawPath(path, _fillPaint);
    _outlinePaint.color = const Color(0xFFFFFFFF);
    canvas.drawPath(path, _outlinePaint);
    canvas.restore();
    // Rotating ring (collector field)
    _ringPaint.color =
        def.color.withValues(alpha: 0.6 + math.sin(phase * 8) * 0.3);
    final ringR = 11 + math.sin(phase * 4) * 2;
    canvas.drawCircle(Offset(cx, cy), ringR, _ringPaint);
    // Inner white dot
    _fillPaint.color = const Color(0xFFFFFFFF);
    canvas.drawCircle(Offset(cx, cy), 2.5, _fillPaint);
  }
}

// ═══════════════════════════════════════════════════════════════════════
// 3. SWEEP PET — orbita 2× più veloce, instakill nemico al contatto
//                (NON tocca boss né black hole)
// ═══════════════════════════════════════════════════════════════════════
class SweepPet extends PetBase {
  SweepPet() : super(kPetCatalog[2]);
  static const _orbitRadius = 80.0;
  // Orbit speed: 5.0 rad/s = 2× più veloce (era 2.5) — richiesta utente.
  static const _orbitSpeed = 5.0;

  @override
  void onPetUpdate(double dt) {
    final ang = phase * _orbitSpeed;
    position = game.player.position +
        Vector2(math.cos(ang), math.sin(ang)) * _orbitRadius;
    // Kill check: instakill nemico entro 18px. Esclude BH + spawn-invuln.
    // Boss è BossBase (no EnemyBase) → già escluso dal `c is EnemyBase`.
    for (final c in game.world.children) {
      if (c is EnemyBase && PetBase.isValidPetTarget(c)) {
        if (c.position.distanceTo(position) < 18) {
          c.takeDamage(999, isArea: true);
        }
      }
    }
  }

  // ─── render: pinwheel a 4 lame rotanti pink ───
  static final _outlinePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;
  static final _fillPaint = Paint();
  static final _glowPaint = Paint();

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final pulse = 0.5 + math.sin(phase * 8) * 0.5;
    // Glow rotante
    _glowPaint.color = def.color.withValues(alpha: 0.5 * pulse);
    canvas.drawCircle(Offset(cx, cy), 16, _glowPaint);
    // Pinwheel: 4 lame triangolari rotanti
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(phase * 6); // rotazione veloce visiva (separata da _orbitSpeed)
    for (int i = 0; i < 4; i++) {
      final a = i * math.pi / 2;
      final path = Path()
        ..moveTo(0, 0)
        ..lineTo(math.cos(a) * 13, math.sin(a) * 13)
        ..lineTo(math.cos(a + 0.5) * 6, math.sin(a + 0.5) * 6)
        ..close();
      _fillPaint.color = def.color;
      canvas.drawPath(path, _fillPaint);
      _outlinePaint.color = const Color(0xFFFFFFFF).withValues(alpha: 0.7);
      canvas.drawPath(path, _outlinePaint);
    }
    canvas.restore();
    // Nucleo bianco
    _fillPaint.color = const Color(0xFFFFFFFF);
    canvas.drawCircle(Offset(cx, cy), 3.5, _fillPaint);
  }
}

// ═══════════════════════════════════════════════════════════════════════
// 4. DEFEND PET — segue retro player, spara dietro 3× rate
// ═══════════════════════════════════════════════════════════════════════
class DefendPet extends PetBase {
  DefendPet() : super(kPetCatalog[3]);
  // Fire rate: 0.2s = 3× più veloce (era 0.6s) — richiesta utente.
  static const _shootInterval = 0.2;
  double _shootTimer = 0;

  @override
  void onPetUpdate(double dt) {
    final aim = cachedAim;
    final back = -aim;
    final target = game.player.position + back * 45;
    final to = target - position;
    if (to.length > 1) position += to.normalized() * 250 * dt;

    _shootTimer -= dt;
    if (_shootTimer <= 0) {
      _shootTimer = _shootInterval;
      final bullet = PlayerBullet(
          direction: back,
          weaponType: WeaponType.basic,
          damage: 0.6,
          color: def.color,
          sizeMultiplier: 0.7);
      bullet.position = position.clone();
      game.world.add(bullet);
    }
  }

  // ─── render: scudo verde con cannone posteriore ───
  static final _outlinePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.6;
  static final _fillPaint = Paint();
  static final _glowPaint = Paint();

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final pulse = 0.6 + math.sin(phase * 5) * 0.4;
    _glowPaint.color = def.color.withValues(alpha: 0.45 * pulse);
    canvas.drawCircle(Offset(cx, cy), 14, _glowPaint);
    // Body: scudo orientato (rotazione segue back-aim)
    final aim = -cachedAim;
    final ang = math.atan2(aim.y, aim.x);
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(ang);
    // Shield half-circle (apertura verso back-direction)
    final shieldPath = Path()
      ..moveTo(-7, -8)
      ..quadraticBezierTo(8, 0, -7, 8)
      ..close();
    _fillPaint.color = def.color;
    canvas.drawPath(shieldPath, _fillPaint);
    _outlinePaint.color = const Color(0xFFFFFFFF);
    canvas.drawPath(shieldPath, _outlinePaint);
    // Cannon barrel (forward = back-direction in pet frame)
    _fillPaint.color = const Color(0xFFFFFFFF);
    canvas.drawRect(Rect.fromLTWH(4, -1.5, 8, 3), _fillPaint);
    canvas.restore();
  }
}

// ═══════════════════════════════════════════════════════════════════════
// 5. SNIPE PET — orbita lento + raggio rosso corto-raggio
//                triplo danno (NON colpisce boss)
// ═══════════════════════════════════════════════════════════════════════
class SnipePet extends PetBase {
  SnipePet() : super(kPetCatalog[4]);
  static const _orbitRadius = 95.0;
  static const _orbitSpeed = 0.8;
  // Raggio "corto-raggio" come da richiesta utente.
  static const double _rayRange = 220.0;
  // 3× danno degli altri droni che sparano (Attack 0.7, Defend 0.6 → 2.1).
  // Settato a 2.5 per round number ma matematicamente è 3× di ~0.85.
  static const double _rayDamage = 2.5;
  static const _shootInterval = 1.5;
  double _shootTimer = _shootInterval;

  @override
  void onPetUpdate(double dt) {
    final ang = phase * _orbitSpeed;
    position = game.player.position +
        Vector2(math.cos(ang), math.sin(ang)) * _orbitRadius;

    _shootTimer -= dt;
    if (_shootTimer <= 0) {
      _shootTimer = _shootInterval;
      // Cerca solo nemici (NO boss): findNearestEnemy filtra `EnemyBase`,
      // BossBase è classe separata → già escluso. Range corto: 220px.
      final target = findNearestEnemy(maxDist: _rayRange);
      if (target != null) {
        // Damage diretto (no PlayerBullet — eviterebbe collisione con boss).
        target.takeDamage(_rayDamage, isArea: false);
        // FX raggio rosso che fade in 0.18s.
        game.world.add(_PetSnipeRayFx(
          start: position.clone(),
          end: target.position.clone(),
        ));
      }
    }
  }

  // ─── render: triangolo rosso scope con crosshair ───
  static final _outlinePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.6;
  static final _fillPaint = Paint();
  static final _glowPaint = Paint();

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final pulse = 0.6 + math.sin(phase * 5) * 0.4;
    _glowPaint.color = def.color.withValues(alpha: 0.5 * pulse);
    canvas.drawCircle(Offset(cx, cy), 14, _glowPaint);
    // Triangolo (scope direction = verso target più vicino o player aim)
    final aim = cachedAim;
    final ang = math.atan2(aim.y, aim.x);
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(ang);
    final path = Path()
      ..moveTo(11, 0)
      ..lineTo(-7, -7)
      ..lineTo(-7, 7)
      ..close();
    _fillPaint.color = def.color;
    canvas.drawPath(path, _fillPaint);
    _outlinePaint.color = const Color(0xFFFFFFFF);
    canvas.drawPath(path, _outlinePaint);
    // Crosshair lines
    _outlinePaint.strokeWidth = 1;
    _outlinePaint.color = const Color(0xFFFFFFFF).withValues(alpha: 0.9);
    canvas.drawLine(const Offset(-3, 0), const Offset(8, 0), _outlinePaint);
    canvas.drawLine(const Offset(2, -4), const Offset(2, 4), _outlinePaint);
    _outlinePaint.strokeWidth = 1.6;
    canvas.restore();
  }
}

/// FX visivo del raggio rosso dello SnipePet. PositionComponent autonomo
/// che fade in 0.18s e si auto-rimuove. NO logica di danno — il danno è
/// applicato istantaneamente in `SnipePet.onPetUpdate` prima dello spawn.
class _PetSnipeRayFx extends PositionComponent
    with HasGameReference<GeometryFightGame> {
  final Vector2 start;
  final Vector2 end;
  static const double _lifetimeMax = 0.18;
  double _lifetime = _lifetimeMax;
  static final _rayPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3;

  _PetSnipeRayFx({required this.start, required this.end});

  @override
  void update(double dt) {
    super.update(dt);
    _lifetime -= dt;
    if (_lifetime <= 0) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final t = (_lifetime / _lifetimeMax).clamp(0.0, 1.0);
    _rayPaint.color = NeonColors.laserRed.withValues(alpha: t);
    _rayPaint.strokeWidth = 4 * t + 1;
    canvas.drawLine(
        Offset(start.x, start.y), Offset(end.x, end.y), _rayPaint);
    // Inner white core
    _rayPaint.color = const Color(0xFFFFFFFF).withValues(alpha: t * 0.9);
    _rayPaint.strokeWidth = 1.5 * t;
    canvas.drawLine(
        Offset(start.x, start.y), Offset(end.x, end.y), _rayPaint);
  }
}

// ═══════════════════════════════════════════════════════════════════════
// 6. RAM PET — insegue + schianto al contatto, cooldown 1s
//              (NON tocca boss né black hole — già filtrato)
// ═══════════════════════════════════════════════════════════════════════
class RamPet extends PetBase {
  RamPet() : super(kPetCatalog[5]);
  EnemyBase? _target;
  double _cooldown = 0;

  @override
  void onPetUpdate(double dt) {
    if (_cooldown > 0) {
      _cooldown -= dt;
      // Idle: ritorna verso player durante cooldown.
      final to = game.player.position - position;
      if (to.length > 60) position += to.normalized() * 180 * dt;
      return;
    }
    // Boss esclusione: findNearestEnemy filtra solo EnemyBase (BossBase è
    // classe separata) + escluso BH + spawn-invuln via isValidPetTarget.
    if (_target == null ||
        !_target!.isMounted ||
        !PetBase.isValidPetTarget(_target!)) {
      _target = findNearestEnemy(maxDist: 500);
    }
    if (_target == null) {
      // Idle orbit
      final ang = phase * 1.5;
      position = game.player.position +
          Vector2(math.cos(ang), math.sin(ang)) * 70;
      return;
    }
    final to = _target!.position - position;
    if (to.length < 14) {
      _target!.takeDamage(999, isArea: true);
      _target = null;
      _cooldown = 1.0;
    } else {
      position += to.normalized() * 380 * dt;
    }
  }

  // ─── render: chevron freccia arancione punto-forward ───
  static final _outlinePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.6;
  static final _fillPaint = Paint();
  static final _glowPaint = Paint();

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final pulse = 0.6 + math.sin(phase * 7) * 0.4;
    _glowPaint.color = def.color.withValues(alpha: 0.5 * pulse);
    canvas.drawCircle(Offset(cx, cy), 15, _glowPaint);
    // Chevron arrow puntato verso direzione movimento (target o player).
    final aim = _target != null
        ? (_target!.position - position).normalized()
        : Vector2(1, 0);
    final ang = math.atan2(aim.y, aim.x);
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(ang);
    final path = Path()
      ..moveTo(13, 0)
      ..lineTo(-3, -8)
      ..lineTo(0, 0)
      ..lineTo(-3, 8)
      ..close();
    _fillPaint.color = def.color;
    canvas.drawPath(path, _fillPaint);
    _outlinePaint.color = const Color(0xFFFFFFFF);
    canvas.drawPath(path, _outlinePaint);
    // Trail/thrust dietro
    _fillPaint.color = const Color(0xFFFFFFFF).withValues(alpha: 0.6 * pulse);
    canvas.drawCircle(const Offset(-5, 0), 2.5, _fillPaint);
    canvas.restore();
  }
}

/// Factory: instantiate il pet corretto per il tipo. Ritorna null se
/// `PetType.none`.
PetBase? createPet(PetType type) {
  switch (type) {
    case PetType.none: return null;
    case PetType.attack: return AttackPet();
    case PetType.collect: return CollectPet();
    case PetType.sweep: return SweepPet();
    case PetType.defend: return DefendPet();
    case PetType.snipe: return SnipePet();
    case PetType.ram: return RamPet();
  }
}

// Boss exclusion: pet helper iterano `EnemyBase` (vedi `findNearestEnemy`).
// `BossBase` è classe separata da `EnemyBase` → automaticamente escluso da
// `c is EnemyBase` checks. Quindi pet melee/ram/snipe non toccano i boss
// by-design, senza bisogno di filtri espliciti.

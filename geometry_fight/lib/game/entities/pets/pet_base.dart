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
    if (aim.length2 > 1e-4) return aim.normalized();
    final nearest = findNearestEnemy(maxDist: 800);
    if (nearest != null) {
      final to = nearest.position - game.player.position;
      if (to.length2 > 1e-4) return to.normalized();
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
    // Snap istantaneo a target relativo al player (utente: "droni seguano
    // player istantaneo senza delay"). Era lerp 200px/s che laggava ad
    // alta velocità player.
    position = game.player.position +
        Vector2(math.cos(phase * 1.2), math.sin(phase * 1.2)) * 50;

    _shootTimer -= dt;
    if (_shootTimer <= 0) {
      _shootTimer = _shootInterval;
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
    canvas.drawRect(const Rect.fromLTWH(2, -4, 9, 1.5), _fillPaint);
    canvas.drawRect(const Rect.fromLTWH(2, 2.5, 9, 1.5), _fillPaint);
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
  // Reusable buffers — avoids per-frame heap allocation in update() hot path.
  final List<Geom> _pickupBuffer = [];
  final Vector2 _toVec = Vector2.zero();

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
    _toVec.setFrom(_wanderTarget);
    _toVec.sub(position);
    if (_toVec.length2 > 1) position += _toVec.normalized() * 380 * dt;

    // Physical pickup (utente: "deve proprio andare in giro e fisicamente
    // raccogliere i geom"). Geom entro 25px → collect direct + remove.
    // Pet contribuisce al gold sessione bypassando magnet logic player.
    // _pickupBuffer is reused to avoid per-frame List allocation.
    _pickupBuffer.clear();
    for (final c in game.world.children) {
      if (c is Geom && c.position.distanceTo(position) < 25) {
        _pickupBuffer.add(c);
      }
    }
    for (final g in _pickupBuffer) {
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
    // Snap istantaneo dietro al player (utente: "drone defend lento, droni
    // istantanei senza delay"). Era lerp 250px/s che laggava.
    position = game.player.position + back * 45;

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
    canvas.drawRect(const Rect.fromLTWH(4, -1.5, 8, 3), _fillPaint);
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
    var target = _target;
    if (target == null ||
        !target.isMounted ||
        target.isRemoved ||
        !PetBase.isValidPetTarget(target)) {
      target = findNearestEnemy(maxDist: 500);
      _target = target;
    }
    if (target == null) {
      // Idle orbit
      final ang = phase * 1.5;
      position = game.player.position +
          Vector2(math.cos(ang), math.sin(ang)) * 70;
      return;
    }
    final to = target.position - position;
    if (to.length < 14) {
      target.takeDamage(999, isArea: true);
      _target = null;
      _cooldown = 1.0;
    } else if (to.length2 > 1e-6) {
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
    // Chevron arrow puntato verso target se presente, altrimenti usa cachedAim.
    final target = _target;
    final Vector2 aim;
    if (target != null && !target.isRemoved) {
      final toTarget = target.position - position;
      aim = toTarget.length2 > 1e-6 ? toTarget.normalized() : cachedAim;
    } else {
      aim = cachedAim;
    }
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

// ═══════════════════════════════════════════════════════════════════════
// 7. PHOENIX PET — auto-revive una volta per run quando le vite vanno a 0.
//     Stato `charged` resettato al run start (vedi game_world _startRun).
// ═══════════════════════════════════════════════════════════════════════
class PhoenixPet extends PetBase {
  PhoenixPet() : super(kPetCatalog[6]);
  bool charged = true;

  /// Hook chiamato da Player.takeDamage() prima della morte finale.
  /// Ritorna true se il pet aveva ancora la carica → consuma la carica.
  /// Il caller (Player) è responsabile di ripristinare vite + invuln.
  bool tryConsumeRevive() {
    if (!charged) return false;
    charged = false;
    return true;
  }

  @override
  void onPetUpdate(double dt) {
    // Orbita lenta intorno al player.
    final ang = phase * 1.4;
    position = game.player.position +
        Vector2(math.cos(ang), math.sin(ang)) * 46;
  }

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
    // Glow intenso quando carico, fioco quando spento.
    final aIntensity = charged ? 0.6 : 0.2;
    _glowPaint.color = def.color.withValues(alpha: aIntensity * pulse);
    canvas.drawCircle(Offset(cx, cy), 16, _glowPaint);
    // Corpo: ali stilizzate ai lati + corpo centrale a fiamma.
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(phase * 0.8);
    final path = Path()
      ..moveTo(0, -10)
      ..lineTo(8, -2)
      ..lineTo(5, 4)
      ..lineTo(0, 9)
      ..lineTo(-5, 4)
      ..lineTo(-8, -2)
      ..close();
    _fillPaint.color = charged
        ? def.color
        : def.color.withValues(alpha: 0.4);
    canvas.drawPath(path, _fillPaint);
    _outlinePaint.color = const Color(0xFFFFFFFF);
    canvas.drawPath(path, _outlinePaint);
    canvas.restore();
    // Nucleo bianco pulsante (visibile solo se carico).
    if (charged) {
      _fillPaint.color = const Color(0xFFFFFFFF);
      canvas.drawCircle(Offset(cx, cy), 2.5 + math.sin(phase * 8) * 1, _fillPaint);
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════
// 8. BLACK HOLE PET — pozzo gravitazionale micro stazionario.
//     Sta 100px dietro il player; risucchia nemici entro 150px a 80 px/s.
//     Nessun danno, solo pull/lock.
// ═══════════════════════════════════════════════════════════════════════
class BlackHolePet extends PetBase {
  BlackHolePet() : super(kPetCatalog[7]);
  static const double _pullRadius = 150.0;
  static const double _pullSpeed = 80.0;
  // Offset retro player: fisso 100px dietro alla direzione di aim corrente.
  static const double _trailOffset = 100.0;

  @override
  void onPetUpdate(double dt) {
    // Posiziona dietro al player opposto alla direzione di aim corrente.
    // Cached aim è già normalized — fallback gestito da _computeAim.
    final back = -cachedAim;
    position = game.player.position + back * _trailOffset;

    // Risucchia nemici verso il pet. Esclude boss (BossBase, non EnemyBase)
    // automaticamente + spawn-invuln via isValidPetTarget.
    for (final c in game.world.children) {
      if (c is EnemyBase && PetBase.isValidPetTarget(c)) {
        final d = c.position.distanceTo(position);
        if (d < _pullRadius && d > 1e-3) {
          final to = position - c.position;
          c.position += to.normalized() * _pullSpeed * dt;
        }
      }
    }
  }

  static final _fillPaint = Paint();
  static final _glowPaint = Paint();
  static final _arcPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.2;

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final pulse = 0.5 + math.sin(phase * 4) * 0.5;
    // Glow esterno viola.
    _glowPaint.color = def.color.withValues(alpha: 0.5 * pulse);
    canvas.drawCircle(Offset(cx, cy), 16, _glowPaint);
    // Disco nero centrale (event horizon).
    _fillPaint.color = const Color(0xFF000000);
    canvas.drawCircle(Offset(cx, cy), 7, _fillPaint);
    // Bordo viola.
    _arcPaint.color = def.color;
    _arcPaint.strokeWidth = 1.6;
    canvas.drawCircle(Offset(cx, cy), 7, _arcPaint);
    // Quattro archi ruotanti intorno (accretion swirl).
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(phase * 2.6);
    _arcPaint.strokeWidth = 2.2;
    for (int i = 0; i < 4; i++) {
      final start = i * math.pi / 2;
      _arcPaint.color =
          def.color.withValues(alpha: 0.55 + math.sin(phase * 6 + i) * 0.3);
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: 11),
        start,
        math.pi / 3,
        false,
        _arcPaint,
      );
    }
    canvas.restore();
  }
}

// ═══════════════════════════════════════════════════════════════════════
// 9. EMP DRONE PET — pulse stun nemici entro 250px ogni 8s.
//     Stun duration 0.5s tramite EnemyBase.stunTimer (skip updateBehavior).
// ═══════════════════════════════════════════════════════════════════════
class EmpDronePet extends PetBase {
  EmpDronePet() : super(kPetCatalog[8]);
  static const double _pulseRadius = 250.0;
  static const double _pulseInterval = 8.0;
  static const double _stunDuration = 0.5;
  double _pulseTimer = _pulseInterval;

  /// Tempo restante prima del prossimo pulse (per FX/HUD se serve).
  double get pulseCooldown => _pulseTimer;

  @override
  void onPetUpdate(double dt) {
    // Orbita lenta sopra/intorno al player.
    final ang = phase * 1.7;
    position = game.player.position +
        Vector2(math.cos(ang), math.sin(ang)) * 52;

    // Pulse timer in REAL dt: 8s reali tra pulse anche durante slow-mo.
    // I pets ricevono dt scalato dal world; dividiamo per timeScale per
    // tornare a tempo reale. Clamp a 0.1 evita bomb-freeze esplosivo.
    final scaleDiv = game.timeScale.clamp(0.1, 1.0);
    final realDt = dt / scaleDiv;
    _pulseTimer -= realDt;
    if (_pulseTimer <= 0) {
      _pulseTimer = _pulseInterval;
      // Stun nemici entro raggio. Esclude boss + spawn-invuln.
      for (final c in game.world.children) {
        if (c is EnemyBase && PetBase.isValidPetTarget(c)) {
          if (c.position.distanceTo(position) <= _pulseRadius) {
            c.applyStun(_stunDuration);
          }
        }
      }
      // FX visivo: esplosione cyan ad anello (riusa pipeline esistente).
      game.spawnExplosion(position, def.color,
          radius: _pulseRadius, particleCount: 18);
    }
  }

  static final _fillPaint = Paint();
  static final _glowPaint = Paint();
  static final _ringPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  static final _outlinePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.6;

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final pulse = 0.6 + math.sin(phase * 5) * 0.4;
    // Brightness cresce verso il pulse imminente.
    final charge = 1.0 - (_pulseTimer / _pulseInterval).clamp(0.0, 1.0);
    _glowPaint.color = def.color.withValues(alpha: 0.45 * pulse);
    canvas.drawCircle(Offset(cx, cy), 14, _glowPaint);
    // Corpo: hexagon con antenne cardinali (4 piccoli rettangoli).
    canvas.save();
    canvas.translate(cx, cy);
    final body = Path();
    for (int i = 0; i < 6; i++) {
      final a = i * math.pi / 3;
      final x = math.cos(a) * 7;
      final y = math.sin(a) * 7;
      if (i == 0) {
        body.moveTo(x, y);
      } else {
        body.lineTo(x, y);
      }
    }
    body.close();
    _fillPaint.color = def.color;
    canvas.drawPath(body, _fillPaint);
    _outlinePaint.color = const Color(0xFFFFFFFF);
    canvas.drawPath(body, _outlinePaint);
    // Antenne EMP — 4 punte cardinali bianche.
    _fillPaint.color = const Color(0xFFFFFFFF);
    canvas.drawRect(const Rect.fromLTWH(-1, -11, 2, 4), _fillPaint);
    canvas.drawRect(const Rect.fromLTWH(-1, 7, 2, 4), _fillPaint);
    canvas.drawRect(const Rect.fromLTWH(-11, -1, 4, 2), _fillPaint);
    canvas.drawRect(const Rect.fromLTWH(7, -1, 4, 2), _fillPaint);
    canvas.restore();
    // Ring di carica esterno: alpha cresce con charge.
    _ringPaint.color = def.color.withValues(alpha: 0.2 + charge * 0.6);
    canvas.drawCircle(Offset(cx, cy), 13 + math.sin(phase * 4) * 1.5,
        _ringPaint);
  }
}

// ═══════════════════════════════════════════════════════════════════════
// 10. TACTICAL SPOTTER PET — slow-mo 0.5s quando il player è in salute critica.
//     Trigger: lives/startingLives ≤ 25%. Cooldown 6s tra trigger.
//     Snapshot + restore di game.timeScale per giocare bene con altri sistemi
//     che modificano timeScale (TimeSlow powerup, slow-mo bomba).
// ═══════════════════════════════════════════════════════════════════════
class TacticalSpotterPet extends PetBase {
  TacticalSpotterPet() : super(kPetCatalog[9]);
  static const double _hpThreshold = 0.25;
  static const double _slowDuration = 0.5;
  static const double _slowFactor = 0.4;
  static const double _cooldownDuration = 6.0;
  static const double _orbitRadius = 58.0;
  static const double _orbitSpeed = 2.2;

  double _cooldown = 0;
  double _slowTimer = 0;
  double _priorTimeScale = 1.0;
  bool _slowActive = false;

  @override
  void onPetUpdate(double dt) {
    final ang = phase * _orbitSpeed;
    position = game.player.position +
        Vector2(math.cos(ang), math.sin(ang)) * _orbitRadius;

    // Decrementa cooldown/slow timer in REAL dt (compensa game.timeScale):
    // i pets ricevono dt già scalato dal world, quindi se siamo dentro lo
    // slow-mo che noi stessi abbiamo attivato il timer ticchetterebbe a 0.4×
    // → 0.5s di slow-mo durerebbero 1.25s reali. Dividendo per timeScale
    // riportiamo a real-time. Clamp a 0.1 min per evitare bomb-freeze
    // (timeScale≈0.05) che farebbe esplodere realDt → 20× dt.
    final scaleDiv = game.timeScale.clamp(0.1, 1.0);
    final realDt = dt / scaleDiv;
    if (_cooldown > 0) _cooldown -= realDt;

    // Gestione slow-mo attivo: decrementa e ripristina al termine.
    if (_slowActive) {
      _slowTimer -= realDt;
      if (_slowTimer <= 0) {
        _slowActive = false;
        // Ripristina lo scale precedente solo se nessun altro sistema lo ha
        // già toccato (best-effort: confronta con _slowFactor).
        if (game.timeScale == _slowFactor) {
          game.timeScale = _priorTimeScale;
        }
      }
    }

    // Trigger check: salute critica + non attivo + cooldown finito.
    // Usa starting lives come reference (lives correnti / startingLives).
    final startingLives = game.diffConfig.startingLives +
        (game.saveData.startingLives - 3);
    // Guard div-by-zero: startingLives <= 0 disabilita il trigger.
    if (startingLives <= 0) return;
    final hpRatio = game.player.lives / startingLives;
    if (!_slowActive && _cooldown <= 0 && hpRatio <= _hpThreshold) {
      // Snapshot solo se non stiamo per clobberare uno scale "anomalo":
      // se game.timeScale è già != 1.0 (es. bomb-freeze, TimeSlow powerup,
      // altro pet che ha rallentato), preserviamo quello come prior così
      // al ripristino non rompiamo lo stato altrui.
      _priorTimeScale = game.timeScale;
      game.timeScale = _slowFactor;
      _slowTimer = _slowDuration;
      _cooldown = _cooldownDuration;
      _slowActive = true;
    }
  }

  static final _fillPaint = Paint();
  static final _glowPaint = Paint();
  static final _strokePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.6;

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final pulse = 0.6 + math.sin(phase * 7) * 0.4;
    _glowPaint.color = def.color.withValues(alpha: 0.5 * pulse);
    canvas.drawCircle(Offset(cx, cy), 14, _glowPaint);
    // Corpo: scope/binocolo lime con reticolo a croce.
    canvas.save();
    canvas.translate(cx, cy);
    // Cornice scope: cerchio.
    _strokePaint.color = def.color;
    _strokePaint.strokeWidth = 2;
    canvas.drawCircle(Offset.zero, 9, _strokePaint);
    // Reticolo crosshair.
    _strokePaint.color = const Color(0xFFFFFFFF);
    _strokePaint.strokeWidth = 1.2;
    canvas.drawLine(const Offset(-9, 0), const Offset(9, 0), _strokePaint);
    canvas.drawLine(const Offset(0, -9), const Offset(0, 9), _strokePaint);
    // Punto centrale.
    _fillPaint.color = def.color;
    canvas.drawCircle(Offset.zero, 2, _fillPaint);
    canvas.restore();
    // Indicatore cooldown: arco esterno che scompare verso disponibilità.
    if (_cooldown > 0) {
      _strokePaint.color = def.color.withValues(alpha: 0.55);
      _strokePaint.strokeWidth = 2;
      final fraction = (_cooldown / _cooldownDuration).clamp(0.0, 1.0);
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: 13),
        -math.pi / 2,
        math.pi * 2 * fraction,
        false,
        _strokePaint,
      );
    }
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
    case PetType.phoenix: return PhoenixPet();
    case PetType.blackHolePet: return BlackHolePet();
    case PetType.empDrone: return EmpDronePet();
    case PetType.tacticalSpotter: return TacticalSpotterPet();
  }
}

// Boss exclusion: pet helper iterano `EnemyBase` (vedi `findNearestEnemy`).
// `BossBase` è classe separata da `EnemyBase` → automaticamente escluso da
// `c is EnemyBase` checks. Quindi pet melee/ram/snipe non toccano i boss
// by-design, senza bisogno di filtri espliciti.

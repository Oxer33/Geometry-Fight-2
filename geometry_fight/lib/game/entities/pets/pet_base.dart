import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../../data/constants.dart';
import '../../../data/pet_types.dart';
import '../../game_world.dart';
import '../bosses/boss_base.dart';
import '../enemies/black_hole_enemy.dart';
import '../enemies/enemy_base.dart';
import '../geom.dart';
import '../player.dart';
import '../projectiles.dart';

/// Memoizzatore di colore quantizzato per i siti di render animati (glow/aura/
/// ring/onde) dei pet. Il colore base è fisso per istanza (`def.color` o un
/// bianco/accento costante), mentre l'alpha varia con `phase`/`pulse` ogni
/// frame: invece di rialloc un `Color` identico 60×/s, quantizziamo l'alpha a
/// 256 step e ricalcoliamo `withValues` SOLO quando la chiave cambia. Delta
/// alpha ≤ 1/256 → impercettibile, stessa formula e draw order invariati.
class _AlphaColorCache {
  _AlphaColorCache(this._base);

  final Color _base;
  int _lastKey = -1;
  Color _lastColor = const Color(0x00000000);

  /// Ritorna `_base.withValues(alpha: alpha)` quantizzato a 256 step.
  /// `alpha` è clampato a [0,1] prima della quantizzazione.
  Color resolve(double alpha) {
    final key = (alpha.clamp(0.0, 1.0) * 255).round();
    if (key != _lastKey) {
      _lastKey = key;
      _lastColor = _base.withValues(alpha: key / 255);
    }
    return _lastColor;
  }
}

/// Pet companion base (Geometry Wars 3 style drone). Vola accanto/attorno
/// al player con comportamento e grafica per-tipo override-able.
abstract class PetBase extends PositionComponent
    with HasGameReference<GeometryFightGame> {
  final PetDef def;
  double phase = 0;

  PetBase(this.def) : super(size: Vector2(28, 28), anchor: Anchor.center);

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
    for (final c in game.activeEnemies) {
      if (isValidPetTarget(c)) {
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
      if (to.length2 > 1e-4) {
        // normalize() muta `to` in place (evita l'alloc di normalized()); il
        // valore di ritorno (lunghezza) viene scartato, ritorniamo il vettore.
        to.normalize();
        return to;
      }
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
    position =
        game.player.position +
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
        sizeMultiplier: 0.7,
      );
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
  // Geometria statica del corpo (origin-relative) — costruita 1× e riusata,
  // animata via canvas transform invece di rialloc Path ogni frame.
  Path? _bodyPath;
  // Cache colore glow: alpha quantizzato a 256 step (vedi _AlphaColorCache).
  late final _glowCache = _AlphaColorCache(def.color);

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final pulse = 0.6 + math.sin(phase * 6) * 0.4;
    // Glow alone
    _glowPaint.color = _glowCache.resolve(0.45 * pulse);
    canvas.drawCircle(Offset(cx, cy), 14, _glowPaint);
    // Body diamond pointing forward (rotates with aim)
    final aim = math.atan2(cachedAim.y, cachedAim.x);
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(aim);
    final path = _bodyPath ??= Path()
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
    for (final c in game.activeGeoms) {
      final d = c.position.distanceTo(position);
      if (d < nearestD) {
        nearestD = d;
        nearestGeom = c;
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
    for (final c in game.activeGeoms) {
      if (c.position.distanceTo(position) < 25) {
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
  // Geometria statica dell'esagono (origin-relative) — costruita 1× e riusata,
  // ruotata via canvas transform invece di rialloc Path ogni frame.
  Path? _bodyPath;
  // Cache colore glow + ring: alpha quantizzato a 256 step.
  late final _glowCache = _AlphaColorCache(def.color);
  late final _ringCache = _AlphaColorCache(def.color);

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final pulse = 0.6 + math.sin(phase * 5) * 0.4;
    // Glow esterno
    _glowPaint.color = _glowCache.resolve(0.45 * pulse);
    canvas.drawCircle(Offset(cx, cy), 14, _glowPaint);
    // Hexagon body
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(phase * 0.5);
    var path = _bodyPath;
    if (path == null) {
      path = Path();
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
      _bodyPath = path;
    }
    _fillPaint.color = def.color;
    canvas.drawPath(path, _fillPaint);
    _outlinePaint.color = const Color(0xFFFFFFFF);
    canvas.drawPath(path, _outlinePaint);
    canvas.restore();
    // Rotating ring (collector field)
    _ringPaint.color = _ringCache.resolve(0.6 + math.sin(phase * 8) * 0.3);
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
    position =
        game.player.position +
        Vector2(math.cos(ang), math.sin(ang)) * _orbitRadius;
    // Kill check: instakill nemico entro 18px. Esclude BH + spawn-invuln.
    // Boss è BossBase (no EnemyBase) → già escluso dal `c is EnemyBase`.
    for (final c in game.activeEnemies) {
      if (PetBase.isValidPetTarget(c)) {
        if (c.position.distanceTo(position) < 18) {
          c.takeDamage(c.maxHp + 1, isArea: true);
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
  // Outline bianco semitrasparente (alpha costante) — hoistato 1× per evitare
  // l'alloc di un Color identico per ognuna delle 4 lame, ogni frame. Stessa
  // identica espressione di prima: nessuna variazione di colore.
  static final _bladeOutline = const Color(0xFFFFFFFF).withValues(alpha: 0.7);
  // Cache colore glow: alpha quantizzato a 256 step.
  late final _glowCache = _AlphaColorCache(def.color);

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final pulse = 0.5 + math.sin(phase * 8) * 0.5;
    // Glow rotante
    _glowPaint.color = _glowCache.resolve(0.5 * pulse);
    canvas.drawCircle(Offset(cx, cy), 16, _glowPaint);
    // Pinwheel: 4 lame triangolari rotanti
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(
      phase * 6,
    ); // rotazione veloce visiva (separata da _orbitSpeed)
    for (int i = 0; i < 4; i++) {
      final a = i * math.pi / 2;
      final path = Path()
        ..moveTo(0, 0)
        ..lineTo(math.cos(a) * 13, math.sin(a) * 13)
        ..lineTo(math.cos(a + 0.5) * 6, math.sin(a + 0.5) * 6)
        ..close();
      _fillPaint.color = def.color;
      canvas.drawPath(path, _fillPaint);
      _outlinePaint.color = _bladeOutline;
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
        sizeMultiplier: 0.7,
      );
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
  // Geometria statica dello scudo (origin-relative) — costruita 1× e riusata,
  // ruotata via canvas transform invece di rialloc Path ogni frame.
  Path? _shieldPath;
  // Cache colore glow: alpha quantizzato a 256 step.
  late final _glowCache = _AlphaColorCache(def.color);

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final pulse = 0.6 + math.sin(phase * 5) * 0.4;
    _glowPaint.color = _glowCache.resolve(0.45 * pulse);
    canvas.drawCircle(Offset(cx, cy), 14, _glowPaint);
    // Body: scudo orientato (rotazione segue back-aim)
    final aim = -cachedAim;
    final ang = math.atan2(aim.y, aim.x);
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(ang);
    // Shield half-circle (apertura verso back-direction)
    final shieldPath = _shieldPath ??= Path()
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
    position =
        game.player.position +
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
        game.world.add(
          _PetSnipeRayFx(start: position.clone(), end: target.position.clone()),
        );
      }
    }
  }

  // ─── render: triangolo rosso scope con crosshair ───
  static final _outlinePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.6;
  static final _fillPaint = Paint();
  static final _glowPaint = Paint();
  // Geometria statica del triangolo (origin-relative) — costruita 1× e riusata,
  // ruotata via canvas transform invece di rialloc Path ogni frame.
  Path? _bodyPath;
  // Cache colore glow: alpha quantizzato a 256 step.
  late final _glowCache = _AlphaColorCache(def.color);
  // Crosshair bianco (alpha costante 0.9) — hoistato 1×. Stessa espressione.
  static final _crosshairColor = const Color(0xFFFFFFFF).withValues(alpha: 0.9);

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final pulse = 0.6 + math.sin(phase * 5) * 0.4;
    _glowPaint.color = _glowCache.resolve(0.5 * pulse);
    canvas.drawCircle(Offset(cx, cy), 14, _glowPaint);
    // Triangolo (scope direction = verso target più vicino o player aim)
    final aim = cachedAim;
    final ang = math.atan2(aim.y, aim.x);
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(ang);
    final path = _bodyPath ??= Path()
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
    _outlinePaint.color = _crosshairColor;
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
  // Cache colori (alpha quantizzato a 256 step): base costanti, alpha ∝ t.
  // Per-istanza perché più ray FX possono coesistere con `t` diversi nello
  // stesso frame (uno static thrashing tra istanze).
  final _rayColorCache = _AlphaColorCache(NeonColors.laserRed);
  final _coreColorCache = _AlphaColorCache(const Color(0xFFFFFFFF));

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
    _rayPaint.color = _rayColorCache.resolve(t);
    _rayPaint.strokeWidth = 4 * t + 1;
    canvas.drawLine(Offset(start.x, start.y), Offset(end.x, end.y), _rayPaint);
    // Inner white core
    _rayPaint.color = _coreColorCache.resolve(t * 0.9);
    _rayPaint.strokeWidth = 1.5 * t;
    canvas.drawLine(Offset(start.x, start.y), Offset(end.x, end.y), _rayPaint);
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
      position =
          game.player.position + Vector2(math.cos(ang), math.sin(ang)) * 70;
      return;
    }
    final to = target.position - position;
    if (to.length < 14) {
      target.takeDamage(target.maxHp + 1, isArea: true);
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
  // Geometria statica del chevron (origin-relative) — costruita 1× e riusata,
  // ruotata via canvas transform invece di rialloc Path ogni frame.
  Path? _bodyPath;
  // Cache colori (alpha quantizzato a 256 step): glow su def.color, trail su
  // bianco. Entrambi con alpha ∝ pulse.
  late final _glowCache = _AlphaColorCache(def.color);
  final _trailCache = _AlphaColorCache(const Color(0xFFFFFFFF));

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final pulse = 0.6 + math.sin(phase * 7) * 0.4;
    _glowPaint.color = _glowCache.resolve(0.5 * pulse);
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
    final path = _bodyPath ??= Path()
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
    _fillPaint.color = _trailCache.resolve(0.6 * pulse);
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
    position =
        game.player.position + Vector2(math.cos(ang), math.sin(ang)) * 46;
  }

  static final _outlinePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.6;
  static final _fillPaint = Paint();
  static final _glowPaint = Paint();
  // Geometria statica del corpo a fiamma (origin-relative) — costruita 1× e
  // riusata, ruotata via canvas transform invece di rialloc Path ogni frame.
  Path? _bodyPath;
  // Cache colore glow: alpha quantizzato a 256 step.
  late final _glowCache = _AlphaColorCache(def.color);
  // Corpo dimmato (alpha costante 0.4) quando spento — hoistato 1× (stessa
  // espressione). Il ramo "carico" usa def.color diretto (nessun alloc).
  late final _dimBody = def.color.withValues(alpha: 0.4);

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final pulse = 0.6 + math.sin(phase * 6) * 0.4;
    // Glow intenso quando carico, fioco quando spento.
    final aIntensity = charged ? 0.6 : 0.2;
    _glowPaint.color = _glowCache.resolve(aIntensity * pulse);
    canvas.drawCircle(Offset(cx, cy), 16, _glowPaint);
    // Corpo: ali stilizzate ai lati + corpo centrale a fiamma.
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(phase * 0.8);
    final path = _bodyPath ??= Path()
      ..moveTo(0, -10)
      ..lineTo(8, -2)
      ..lineTo(5, 4)
      ..lineTo(0, 9)
      ..lineTo(-5, 4)
      ..lineTo(-8, -2)
      ..close();
    _fillPaint.color = charged ? def.color : _dimBody;
    canvas.drawPath(path, _fillPaint);
    _outlinePaint.color = const Color(0xFFFFFFFF);
    canvas.drawPath(path, _outlinePaint);
    canvas.restore();
    // Nucleo bianco pulsante (visibile solo se carico).
    if (charged) {
      _fillPaint.color = const Color(0xFFFFFFFF);
      canvas.drawCircle(
        Offset(cx, cy),
        2.5 + math.sin(phase * 8) * 1,
        _fillPaint,
      );
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════
// 8. BLACK HOLE PET — pozzo gravitazionale micro stazionario.
//     Sta 100px DAVANTI al player; risucchia nemici entro 150px a 80 px/s.
//     Nessun danno, solo pull/lock.
// ═══════════════════════════════════════════════════════════════════════
class BlackHolePet extends PetBase {
  BlackHolePet() : super(kPetCatalog[7]);
  static const double _pullRadius = 150.0;
  static const double _pullSpeed = 80.0;
  // Offset frontale: fisso 100px DAVANTI al player nella direzione di aim.
  static const double _frontOffset = 100.0;

  @override
  void onPetUpdate(double dt) {
    // Posiziona DAVANTI al player nella direzione di aim corrente.
    // Cached aim è già normalized — fallback gestito da _computeAim.
    position = game.player.position + cachedAim * _frontOffset;

    // Risucchia nemici verso il pet. Esclude boss (BossBase, non EnemyBase)
    // automaticamente + spawn-invuln via isValidPetTarget.
    for (final c in game.activeEnemies) {
      if (PetBase.isValidPetTarget(c)) {
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
  // Cache colore glow + 4 cache indipendenti per gli archi (uno per `i`: alpha
  // sfasato per arco → un'unica cache thrasherebbe nel loop). Alpha a 256 step.
  late final _glowCache = _AlphaColorCache(def.color);
  late final List<_AlphaColorCache> _arcCaches = List.generate(
    4,
    (_) => _AlphaColorCache(def.color),
  );

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final pulse = 0.5 + math.sin(phase * 4) * 0.5;
    // Glow esterno viola.
    _glowPaint.color = _glowCache.resolve(0.5 * pulse);
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
      _arcPaint.color = _arcCaches[i].resolve(
        0.55 + math.sin(phase * 6 + i) * 0.3,
      );
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
    position =
        game.player.position + Vector2(math.cos(ang), math.sin(ang)) * 52;

    // Pulse timer in REAL dt: 8s reali tra pulse anche durante slow-mo.
    // I pets ricevono dt scalato dal world; dividiamo per timeScale per
    // tornare a tempo reale. Clamp a 0.1 evita bomb-freeze esplosivo.
    final scaleDiv = game.timeScale.clamp(0.1, 1.0);
    final realDt = dt / scaleDiv;
    _pulseTimer -= realDt;
    if (_pulseTimer <= 0) {
      _pulseTimer = _pulseInterval;
      // Stun nemici entro raggio. Esclude boss + spawn-invuln.
      for (final c in game.activeEnemies) {
        if (PetBase.isValidPetTarget(c)) {
          if (c.position.distanceTo(position) <= _pulseRadius) {
            c.applyStun(_stunDuration);
          }
        }
      }
      // FX visivo: esplosione cyan ad anello (riusa pipeline esistente).
      game.spawnExplosion(
        position,
        def.color,
        radius: _pulseRadius,
        particleCount: 18,
      );
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
  // Geometria statica dell'esagono (origin-relative) — costruita 1× e riusata
  // invece di rialloc Path ogni frame (nessuna rotazione: posizione fissa).
  Path? _bodyPath;
  // Cache colori (alpha quantizzato a 256 step): glow ∝ pulse, ring ∝ charge.
  late final _glowCache = _AlphaColorCache(def.color);
  late final _ringCache = _AlphaColorCache(def.color);

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final pulse = 0.6 + math.sin(phase * 5) * 0.4;
    // Brightness cresce verso il pulse imminente.
    final charge = 1.0 - (_pulseTimer / _pulseInterval).clamp(0.0, 1.0);
    _glowPaint.color = _glowCache.resolve(0.45 * pulse);
    canvas.drawCircle(Offset(cx, cy), 14, _glowPaint);
    // Corpo: hexagon con antenne cardinali (4 piccoli rettangoli).
    canvas.save();
    canvas.translate(cx, cy);
    var body = _bodyPath;
    if (body == null) {
      body = Path();
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
      _bodyPath = body;
    }
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
    _ringPaint.color = _ringCache.resolve(0.2 + charge * 0.6);
    canvas.drawCircle(
      Offset(cx, cy),
      13 + math.sin(phase * 4) * 1.5,
      _ringPaint,
    );
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
  // True mentre QUESTO pet possiede l'override di timeScale. Sostituisce il
  // vecchio guard fragile `game.timeScale == _slowFactor` (che lasciava lo
  // slow-mo incastrato se un altro sistema toccava timeScale nel frattempo).
  // Garantisce il ripristino anche in onRemove() (game over/restart).
  bool _slowing = false;

  @override
  void onPetUpdate(double dt) {
    final ang = phase * _orbitSpeed;
    position =
        game.player.position +
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
        // Ripristina lo scale precedente se siamo noi a possedere l'override.
        // Flag dedicato invece del confronto fragile su game.timeScale: evita
        // lo slow-mo incastrato quando un altro sistema cambia timeScale.
        if (_slowing) {
          game.timeScale = _priorTimeScale;
          _slowing = false;
        }
      }
    }

    // Trigger check: salute critica + non attivo + cooldown finito.
    // Usa starting lives come reference (lives correnti / startingLives).
    final startingLives =
        game.diffConfig.startingLives + (game.saveData.startingLives - 3);
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
      _slowing = true;
    }
  }

  @override
  void onRemove() {
    // Ripristina il timeScale se il pet sparisce (game over/restart) mentre
    // possiede ancora l'override: senza questo lo slow-mo resterebbe incastrato.
    if (_slowing) {
      game.timeScale = _priorTimeScale;
      _slowing = false;
      _slowActive = false;
    }
    super.onRemove();
  }

  static final _fillPaint = Paint();
  static final _glowPaint = Paint();
  static final _strokePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.6;
  // Cache colore glow (alpha ∝ pulse) + arco cooldown (alpha costante 0.55,
  // hoistato 1× con la stessa espressione). Alpha a 256 step.
  late final _glowCache = _AlphaColorCache(def.color);
  late final _cooldownArcColor = def.color.withValues(alpha: 0.55);

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final pulse = 0.6 + math.sin(phase * 7) * 0.4;
    _glowPaint.color = _glowCache.resolve(0.5 * pulse);
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
      _strokePaint.color = _cooldownArcColor;
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

// ═══════════════════════════════════════════════════════════════════════
// 11. SLOWER PET — campo di rallentamento frontale.
//     Sta `_frontOffset`px DAVANTI al player (direzione di aim). Rallenta i
//     nemici entro `_fieldRadius` al `_slowFactor` della loro velocità,
//     ri-applicando uno slow breve ogni frame finché restano nel campo.
//     Nessun danno: pura utility di controllo.
// ═══════════════════════════════════════════════════════════════════════
class SlowerPet extends PetBase {
  SlowerPet() : super(kPetCatalog[10]);
  static const double _frontOffset = 90.0;
  static const double _fieldRadius = 130.0;
  static const double _slowFactor = 0.45;
  static const double _slowRefresh = 0.2;

  @override
  void onPetUpdate(double dt) {
    // Davanti al player nella direzione di aim corrente.
    position = game.player.position + cachedAim * _frontOffset;

    // Espone il campo al game: anche i proiettili nemici rallentano dentro
    // l'area (richiesta utente: "deve rallentare anche i proiettili").
    game.slowerFieldCenter = position;
    game.slowerFieldRadius = _fieldRadius;
    game.slowerFieldFactor = _slowFactor;

    // Rallenta i nemici dentro al campo. Esclude boss (BossBase, non
    // EnemyBase) automaticamente + spawn-invuln via isValidPetTarget.
    for (final c in game.activeEnemies) {
      if (PetBase.isValidPetTarget(c)) {
        if (c.position.distanceTo(position) <= _fieldRadius) {
          c.applySlow(_slowRefresh, _slowFactor);
        }
      }
    }
  }

  @override
  void onRemove() {
    // Spegne il campo quando il pet sparisce (game over/restart) così i
    // proiettili tornano a velocità piena.
    game.slowerFieldCenter = null;
    super.onRemove();
  }

  static final _fillPaint = Paint();
  static final _glowPaint = Paint();
  static final _ringPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  static final _strokePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.8;
  // Cache colori (alpha quantizzato a 256 step): campo + glow ∝ pulse, e 3
  // cache indipendenti per le onde (alpha sfasato per `i` → un'unica cache
  // thrasherebbe nel loop).
  late final _fieldCache = _AlphaColorCache(def.color);
  late final _glowCache = _AlphaColorCache(def.color);
  late final List<_AlphaColorCache> _rippleCaches = List.generate(
    3,
    (_) => _AlphaColorCache(def.color),
  );

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final pulse = 0.5 + math.sin(phase * 3) * 0.5;
    // Campo di rallentamento: cerchio ampio semitrasparente (area effetto).
    _ringPaint
      ..color = _fieldCache.resolve(0.12 + pulse * 0.06)
      ..strokeWidth = 1.4;
    canvas.drawCircle(Offset(cx, cy), _fieldRadius, _ringPaint);
    // Glow centrale.
    _glowPaint.color = _glowCache.resolve(0.5 * pulse);
    canvas.drawCircle(Offset(cx, cy), 15, _glowPaint);
    // Onde concentriche lente (slow ripple) che si espandono dal nucleo.
    for (int i = 0; i < 3; i++) {
      final t = (phase * 0.4 + i / 3) % 1.0;
      _ringPaint
        ..color = _rippleCaches[i].resolve((1 - t) * 0.5)
        ..strokeWidth = 2;
      canvas.drawCircle(Offset(cx, cy), 6 + t * 12, _ringPaint);
    }
    // Corpo: quadrante orologio + lancette lente (metafora "rallenta il tempo").
    canvas.save();
    canvas.translate(cx, cy);
    _strokePaint
      ..color = def.color
      ..strokeWidth = 1.8;
    canvas.drawCircle(Offset.zero, 8, _strokePaint);
    _strokePaint
      ..color = const Color(0xFFFFFFFF)
      ..strokeWidth = 1.6;
    final hourAng = phase * 0.6 - math.pi / 2;
    canvas.drawLine(
      Offset.zero,
      Offset(math.cos(hourAng) * 5, math.sin(hourAng) * 5),
      _strokePaint,
    );
    final minAng = phase * 0.18;
    canvas.drawLine(
      Offset.zero,
      Offset(math.cos(minAng) * 7, math.sin(minAng) * 7),
      _strokePaint,
    );
    // Perno centrale.
    _fillPaint.color = const Color(0xFFFFFFFF);
    canvas.drawCircle(Offset.zero, 1.8, _fillPaint);
    canvas.restore();
  }
}

// ═══════════════════════════════════════════════════════════════════════
// 12. BOMBER PET — orbita il player e sgancia mine esplosive a intervalli.
//     Le mine si armano (0.4s) poi detonano al contatto coi nemici o a fine
//     vita (6s): danno ad AREA a nemici e boss. Cap mine attive per perf.
// ═══════════════════════════════════════════════════════════════════════
class BomberPet extends PetBase {
  BomberPet() : super(kPetCatalog[11]);
  static const double _orbitR = 46.0;
  static const double _dropInterval = 1.4;
  static const int _maxMines = 5;
  double _dropTimer = 0.6;
  final List<_BomberMine> _mines = [];

  // Predicato hoistato (evita alloc closure per frame in removeWhere).
  static bool _mineIsDead(_BomberMine m) => m.isRemoved || !m.isMounted;

  @override
  void onPetUpdate(double dt) {
    // Orbita lenta attorno al player.
    position =
        game.player.position +
        Vector2(math.cos(phase * 1.6), math.sin(phase * 1.6)) * _orbitR;

    // Prune mine già esplose / rimosse dalla lista di tracking.
    _mines.removeWhere(_mineIsDead);

    _dropTimer -= dt;
    if (_dropTimer <= 0 && _mines.length < _maxMines) {
      _dropTimer = _dropInterval;
      final mine = _BomberMine(def.color)..position = position.clone();
      _mines.add(mine);
      game.world.add(mine);
    }
  }

  static final _glowPaint = Paint();
  static final _bodyPaint = Paint();
  static final _stroke = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.6;
  // Cache colori (alpha quantizzato a 256 step): glow su def.color, miccia su
  // bianco. Entrambi con alpha ∝ pulse.
  late final _glowCache = _AlphaColorCache(def.color);
  final _fuseCache = _AlphaColorCache(const Color(0xFFFFFFFF));

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final pulse = 0.5 + math.sin(phase * 5) * 0.5;
    _glowPaint.color = _glowCache.resolve(0.45 * pulse);
    canvas.drawCircle(Offset(cx, cy), 13, _glowPaint);
    // Corpo drone esagonale ruotante.
    final hex = Path();
    for (int i = 0; i < 6; i++) {
      final a = i * math.pi / 3 + phase;
      final x = cx + math.cos(a) * 7;
      final y = cy + math.sin(a) * 7;
      i == 0 ? hex.moveTo(x, y) : hex.lineTo(x, y);
    }
    hex.close();
    _bodyPaint.color = def.color;
    canvas.drawPath(hex, _bodyPaint);
    // Nucleo bomba nero + anello miccia lampeggiante.
    _bodyPaint.color = const Color(0xFF1A0A00);
    canvas.drawCircle(Offset(cx, cy), 4, _bodyPaint);
    _stroke.color = _fuseCache.resolve(pulse);
    canvas.drawCircle(Offset(cx, cy), 4, _stroke);
  }
}

/// Mina esplosiva sganciata dal BomberPet. Arma 0.4s, poi esplode al contatto
/// coi nemici (raggio trigger) o a fine vita (6s) danneggiando ad area nemici
/// e boss. Render: disco arancione + spuntoni d'allarme rotanti + core rosso
/// che lampeggia sempre più veloce avvicinandosi alla detonazione.
class _BomberMine extends PositionComponent
    with HasGameReference<GeometryFightGame> {
  final Color color;
  double _arm = 0.4;
  double _life = 6.0;
  bool _exploded = false;
  static const double _triggerR = 46.0;
  static const double _blastR = 95.0;
  static const double _damage = 6.0;

  _BomberMine(this.color)
    : super(size: Vector2(20, 20), anchor: Anchor.center, priority: 2);

  @override
  void update(double dt) {
    super.update(dt);
    if (_arm > 0) _arm -= dt;
    _life -= dt;
    if (_life <= 0) {
      _explode();
      return;
    }
    if (_arm <= 0) {
      for (final c in game.activeEnemies) {
        if (PetBase.isValidPetTarget(c) &&
            c.position.distanceTo(position) <= _triggerR) {
          _explode();
          return;
        }
      }
    }
  }

  void _explode() {
    if (_exploded) return;
    _exploded = true;
    // Snapshot: takeDamage→onDeath può mutare world.children nel loop.
    for (final c in game.world.children.toList()) {
      if (c is EnemyBase) {
        if (c.isSpawnInvulnerable) continue;
        if (c.position.distanceTo(position) <= _blastR) {
          c.takeDamage(_damage, isArea: true);
        }
      } else if (c is BossBase) {
        if (c.position.distanceTo(position) <= _blastR) {
          c.takeDamage(_damage);
        }
      }
    }
    game.spawnExplosion(position, color, radius: _blastR, particleCount: 14);
    game.triggerScreenShake(3, 0.12);
    removeFromParent();
  }

  static final _glow = Paint();
  static final _body = Paint();
  static final _ray = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.4;
  static final _core = Paint();
  // Spuntoni bianchi (alpha costante 0.7) — hoistato 1×, stessa espressione.
  static final _rayColor = const Color(0xFFFFFFFF).withValues(alpha: 0.7);
  // Endpoints costanti del core lampeggiante.
  static const _coreDark = Color(0xFF661100);
  static const _coreHot = Color(0xFFFF2200);
  // LUT 256-step del core `Color.lerp(_coreDark, _coreHot, k/255)`: costruita 1×
  // e condivisa tra tutte le mine (read-only → nessun thrash con più mine nello
  // stesso frame). Indicizzata dal parametro lerp quantizzato a 256 step.
  static final List<Color> _coreLut = List.generate(
    256,
    (k) => Color.lerp(_coreDark, _coreHot, k / 255)!,
    growable: false,
  );
  // Glow (alpha ∝ blink) e body (alpha costante 0.9): cache/hoist per-istanza
  // perché più mine possono coesistere con `blink` diversi nello stesso frame.
  late final _glowCache = _AlphaColorCache(color);
  late final _bodyColor = color.withValues(alpha: 0.9);

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final armed = _arm <= 0;
    // Il blink accelera col tempo che resta (tensione pre-boom).
    final blinkSpeed = armed ? (8 + (6 - _life) * 2) : 4.0;
    final blink = 0.5 + math.sin(_life * blinkSpeed) * 0.5;
    _glow.color = _glowCache.resolve(0.35 + 0.3 * blink);
    canvas.drawCircle(Offset(cx, cy), 9, _glow);
    _body.color = _bodyColor;
    canvas.drawCircle(Offset(cx, cy), 5, _body);
    // Spuntoni d'allarme rotanti.
    _ray.color = _rayColor;
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(_life * 2.2);
    for (int i = 0; i < 4; i++) {
      final a = i * math.pi / 2;
      canvas.drawLine(
        Offset(math.cos(a) * 5, math.sin(a) * 5),
        Offset(math.cos(a) * 8, math.sin(a) * 8),
        _ray,
      );
    }
    canvas.restore();
    // Core rosso lampeggiante (rosso vivo quando armata). LUT 256-step invece
    // di un Color.lerp per frame: stessa formula, delta ≤ 1/256.
    final coreT = (armed ? blink : 0.2).clamp(0.0, 1.0);
    _core.color = _coreLut[(coreT * 255).round()];
    canvas.drawCircle(Offset(cx, cy), 2.4, _core);
  }
}

// ═══════════════════════════════════════════════════════════════════════
// 13. REPULSOR PET — campo di forza che RESPINGE i nemici vicini al player
//     (opposto del Black Hole). Nessun danno: puro controllo difensivo.
//     Spinta più forte vicino al centro, in calo verso il bordo del campo.
// ═══════════════════════════════════════════════════════════════════════
class RepulsorPet extends PetBase {
  RepulsorPet() : super(kPetCatalog[12]);
  static const double _radius = 150.0;
  static const double _force = 220.0;

  @override
  void onPetUpdate(double dt) {
    position = game.player.position; // centro del campo
    final ppos = game.player.position;
    for (final c in game.activeEnemies) {
      if (PetBase.isValidPetTarget(c)) {
        final d = c.position.distanceTo(ppos);
        if (d < _radius && d > 1e-3) {
          final falloff = 1.0 - d / _radius; // 1 al centro → 0 al bordo
          final away = c.position - ppos;
          // normalize() muta `away` in place (evita l'alloc di normalized()).
          away.normalize();
          c.position += away * _force * falloff * dt;
        }
      }
    }
  }

  static final _ringPaint = Paint()..style = PaintingStyle.stroke;
  static final _glowPaint = Paint();
  static final _corePaint = Paint();
  // Cache colori (alpha quantizzato a 256 step): glow ∝ pulse + 3 cache
  // indipendenti per le onde (alpha sfasato per `i`). Frecce bianche ad alpha
  // costante 0.5 hoistate 1× (stessa espressione).
  late final _glowCache = _AlphaColorCache(def.color);
  late final List<_AlphaColorCache> _waveCaches = List.generate(
    3,
    (_) => _AlphaColorCache(def.color),
  );
  static final _arrowColor = const Color(0xFFFFFFFF).withValues(alpha: 0.5);

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final pulse = 0.5 + math.sin(phase * 4) * 0.5;
    _glowPaint.color = _glowCache.resolve(0.5 * pulse);
    canvas.drawCircle(Offset(cx, cy), 10, _glowPaint);
    _corePaint.color = def.color;
    canvas.drawCircle(Offset(cx, cy), 4.5, _corePaint);
    _corePaint.color = const Color(0xFFFFFFFF);
    canvas.drawCircle(Offset(cx, cy), 2, _corePaint);
    // 3 onde concentriche espandenti (push field).
    for (int i = 0; i < 3; i++) {
      final t = (phase * 1.2 + i / 3) % 1.0;
      _ringPaint.color = _waveCaches[i].resolve((1 - t) * 0.6);
      _ringPaint.strokeWidth = 2.0 * (1 - t) + 0.5;
      canvas.drawCircle(Offset(cx, cy), 6 + t * 16, _ringPaint);
    }
    // Frecce cardinali uscenti (respingono).
    _ringPaint
      ..color = _arrowColor
      ..strokeWidth = 1.4;
    for (int i = 0; i < 4; i++) {
      final a = i * math.pi / 2 + phase * 0.5;
      canvas.drawLine(
        Offset(cx + math.cos(a) * 9, cy + math.sin(a) * 9),
        Offset(cx + math.cos(a) * 13, cy + math.sin(a) * 13),
        _ringPaint,
      );
    }
  }
}

/// Factory: instantiate il pet corretto per il tipo. Ritorna null se
/// `PetType.none`.
PetBase? createPet(PetType type) {
  switch (type) {
    case PetType.none:
      return null;
    case PetType.attack:
      return AttackPet();
    case PetType.collect:
      return CollectPet();
    case PetType.sweep:
      return SweepPet();
    case PetType.defend:
      return DefendPet();
    case PetType.snipe:
      return SnipePet();
    case PetType.ram:
      return RamPet();
    case PetType.phoenix:
      return PhoenixPet();
    case PetType.blackHolePet:
      return BlackHolePet();
    case PetType.empDrone:
      return EmpDronePet();
    case PetType.tacticalSpotter:
      return TacticalSpotterPet();
    case PetType.slower:
      return SlowerPet();
    case PetType.bomber:
      return BomberPet();
    case PetType.repulsor:
      return RepulsorPet();
  }
}

// Boss exclusion: pet helper iterano `EnemyBase` (vedi `findNearestEnemy`).
// `BossBase` è classe separata da `EnemyBase` → automaticamente escluso da
// `c is EnemyBase` checks. Quindi pet melee/ram/snipe non toccano i boss
// by-design, senza bisogno di filtri espliciti.

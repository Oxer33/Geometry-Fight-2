import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../../data/constants.dart';
import '../../../data/pet_types.dart';
import '../../game_world.dart';
import '../enemies/enemy_base.dart';
import '../player.dart';
import '../projectiles.dart';

/// Pet companion base (Geometry Wars 3 style drone). Vola accanto/attorno
/// al player con comportamento per-tipo override-able.
///
/// Tutti i pet:
/// - Sono PositionComponent leggeri (no hitbox per-default → no collisione
///   col player ne con i nemici, eccetto Sweep/Ram che gestiscono kill manualmente)
/// - Hanno HP infinito (non muoiono mai durante la partita)
/// - Si muovono indipendenti dal `controlsInverted` del player
/// - Renderizzano in stile neon (cerchio + glow + nucleo)
abstract class PetBase extends PositionComponent
    with HasGameReference<GeometryFightGame> {
  final PetDef def;
  double phase = 0;

  PetBase(this.def)
      : super(size: Vector2(20, 20), anchor: Anchor.center);

  static final _glowPaint = Paint();
  static final _bodyPaint = Paint();
  static final _rng = math.Random();

  @override
  void update(double dt) {
    super.update(dt);
    phase += dt;
    onPetUpdate(dt);
  }

  /// Override per-tipo. Override può accedere a `game.player`, `game.world.children`.
  void onPetUpdate(double dt);

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final pulse = 0.6 + math.sin(phase * 4) * 0.4;
    // Halo glow esterno (alpha pulsante).
    _glowPaint.color = def.color.withValues(alpha: 0.35 * pulse);
    canvas.drawCircle(Offset(cx, cy), 11, _glowPaint);
    // Body inner.
    _bodyPaint.color = def.color;
    canvas.drawCircle(Offset(cx, cy), 6.5, _bodyPaint);
    // Nucleo bianco luminoso.
    _bodyPaint.color = const Color(0xFFFFFFFF).withValues(alpha: 0.85);
    canvas.drawCircle(Offset(cx, cy), 2.5, _bodyPaint);
  }

  // ── helper condivisi ────────────────────────────────────────────────────
  EnemyBase? findNearestEnemy({double maxDist = 600}) {
    EnemyBase? best;
    double bestD = maxDist;
    for (final c in game.world.children) {
      if (c is EnemyBase) {
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
  /// sparano "in direzione player".
  Vector2 _currentAim() {
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
// 1. ATTACK PET — segue player, spara bullet aggiuntivi
// ═══════════════════════════════════════════════════════════════════════
class AttackPet extends PetBase {
  AttackPet() : super(kPetCatalog[0]);
  double _shootTimer = 0;

  @override
  void onPetUpdate(double dt) {
    final target = game.player.position +
        Vector2(math.cos(phase * 1.2), math.sin(phase * 1.2)) * 50;
    final to = target - position;
    if (to.length > 1) position += to.normalized() * 200 * dt;

    _shootTimer -= dt;
    if (_shootTimer <= 0) {
      _shootTimer = 0.5;
      final dir = _currentAim();
      final bullet = PlayerBullet(
          direction: dir,
          weaponType: WeaponType.basic,
          damage: 0.7,
          sizeMultiplier: 0.8);
      bullet.position = position.clone();
      game.world.add(bullet);
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════
// 2. COLLECT PET — vola indipendente, magnetizza geoms (gestito in geom.dart)
// ═══════════════════════════════════════════════════════════════════════
class CollectPet extends PetBase {
  CollectPet() : super(kPetCatalog[1]);
  Vector2 _wanderTarget = Vector2.zero();
  double _wanderTimer = 0;

  @override
  void onPetUpdate(double dt) {
    _wanderTimer -= dt;
    if (_wanderTimer <= 0 || position.distanceTo(_wanderTarget) < 40) {
      _wanderTimer = 2.0 + PetBase._rng.nextDouble() * 2;
      _wanderTarget = Vector2(
        20 + PetBase._rng.nextDouble() * (arenaWidth - 40),
        20 + PetBase._rng.nextDouble() * (arenaHeight - 40),
      );
    }
    final to = _wanderTarget - position;
    if (to.length > 1) position += to.normalized() * 320 * dt;
  }
}

// ═══════════════════════════════════════════════════════════════════════
// 3. SWEEP PET — orbita player, instakill nemico al contatto
// ═══════════════════════════════════════════════════════════════════════
class SweepPet extends PetBase {
  SweepPet() : super(kPetCatalog[2]);
  static const _orbitRadius = 80.0;
  static const _orbitSpeed = 2.5; // rad/s

  @override
  void onPetUpdate(double dt) {
    final ang = phase * _orbitSpeed;
    position = game.player.position +
        Vector2(math.cos(ang), math.sin(ang)) * _orbitRadius;
    // Kill check: instakill nemico entro 16px dal pet.
    for (final c in game.world.children) {
      if (c is EnemyBase) {
        if (c.position.distanceTo(position) < 16) {
          c.takeDamage(999, isArea: true);
        }
      }
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════
// 4. DEFEND PET — segue retro player, spara nella direzione opposta
// ═══════════════════════════════════════════════════════════════════════
class DefendPet extends PetBase {
  DefendPet() : super(kPetCatalog[3]);
  double _shootTimer = 0;

  @override
  void onPetUpdate(double dt) {
    final aim = _currentAim();
    final back = -aim;
    final target = game.player.position + back * 45;
    final to = target - position;
    if (to.length > 1) position += to.normalized() * 250 * dt;

    _shootTimer -= dt;
    if (_shootTimer <= 0) {
      _shootTimer = 0.6;
      final bullet = PlayerBullet(
          direction: back,
          weaponType: WeaponType.basic,
          damage: 0.6,
          sizeMultiplier: 0.8);
      bullet.position = position.clone();
      game.world.add(bullet);
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════
// 5. SNIPE PET — orbita lento, laser ray al nemico più vicino ogni 1.5s
// ═══════════════════════════════════════════════════════════════════════
class SnipePet extends PetBase {
  SnipePet() : super(kPetCatalog[4]);
  static const _orbitRadius = 95.0;
  static const _orbitSpeed = 0.8;
  double _shootTimer = 1.5;

  @override
  void onPetUpdate(double dt) {
    final ang = phase * _orbitSpeed;
    position = game.player.position +
        Vector2(math.cos(ang), math.sin(ang)) * _orbitRadius;

    _shootTimer -= dt;
    if (_shootTimer <= 0) {
      _shootTimer = 1.5;
      final target = findNearestEnemy(maxDist: 800);
      if (target != null) {
        final dir = (target.position - position).normalized();
        final bullet = PlayerBullet(
            direction: dir,
            weaponType: WeaponType.basic,
            damage: 2.5,
            sizeMultiplier: 1.2);
        bullet.position = position.clone();
        game.world.add(bullet);
      }
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════
// 6. RAM PET — insegue + schianto al contatto, cooldown 1s
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
    if (_target == null || !_target!.isMounted) {
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

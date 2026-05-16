import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../game_world.dart';
import 'enemy_base.dart';

/// ORBITER - Nemico che orbita attorno al player a distanza fissa,
/// sparando proiettili tangenziali periodicamente.
/// Forma: anello con 3 sfere orbitanti
/// Colore: arancione caldo (#FF9933)
/// Meccanica unica: non puoi scappare perché ti segue in orbita!
class OrbiterEnemy extends EnemyBase {
  double _orbitAngle = 0;
  final double _orbitRadius = 180;
  double _shootTimer = 2.0;
  double _spherePhase = 0;

  // Paint cache: evita alloc per frame × N orbiter.
  static final Paint _ringPaint = Paint()..style = PaintingStyle.stroke;
  // Random statico condiviso (evita alloc per ogni orbiter spawnato).
  static final math.Random _rng = math.Random();

  OrbiterEnemy()
      : super(
          hp: 4,
          speed: 200,
          pointValue: 8,
          geomValue: 3,
          neonColor: const Color(0xFFFF9933),
          size: Vector2(20, 20),
        ) {
    _orbitAngle = _rng.nextDouble() * math.pi * 2;
  }

  @override
  void updateBehavior(double dt) {
    _spherePhase += dt * 5;

    // Orbita attorno al player
    _orbitAngle += dt * 1.5;
    final targetPos = playerPosition + Vector2(
      math.cos(_orbitAngle) * _orbitRadius,
      math.sin(_orbitAngle) * _orbitRadius,
    );

    // Smooth movement verso la posizione orbitale
    final toTarget = targetPos - position;
    if (toTarget.length > 2) {
      position += toTarget.normalized() * speed * dt;
    }

    // Spara periodicamente.
    // Iter: interval 1.8s → 5.4s (3× più lento — richiesta utente:
    // "il mob giallo che spara pallini gialli deve sparare un terzo
    // di adesso"). Orbiter è arancio fluo (#FF9933) percepito come
    // giallo dall'utente.
    _shootTimer -= dt;
    if (_shootTimer <= 0) {
      _shootTimer = 5.4;
      _shootAtPlayer();
    }
  }

  void _shootAtPlayer() {
    // NaN guard: se player coincide col mob, skip shoot.
    final delta = playerPosition - position;
    if (delta.length < 0.001) return;
    final dir = delta.normalized();
    final bullet = _OrbiterBullet(direction: dir, color: neonColor);
    bullet.position = position.clone();
    game.world.add(bullet);
  }

  @override
  void renderShape(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final r = size.x / 2 * scale;

    // Anello centrale
    _ringPaint.color = paint.color;
    _ringPaint.strokeWidth = 2 * scale;
    canvas.drawCircle(Offset(cx, cy), r * 0.6, _ringPaint);

    // 3 sfere orbitanti
    for (int i = 0; i < 3; i++) {
      final angle = _spherePhase + i * math.pi * 2 / 3;
      final sx = cx + r * 0.85 * math.cos(angle);
      final sy = cy + r * 0.85 * math.sin(angle);
      canvas.drawCircle(Offset(sx, sy), 3 * scale, paint);

      if (scale <= 1.01) {
        EnemyBase.detailPaint.color = paint.color.withValues(alpha: 0.2);
        canvas.drawCircle(Offset(sx, sy), 5 * scale, EnemyBase.detailPaint);
      }
    }

    // Nucleo
    if (scale <= 1.01) {
      EnemyBase.detailPaint.color = const Color(0xFFFFFFFF).withValues(alpha: 0.3);
      canvas.drawCircle(Offset(cx, cy), r * 0.3, EnemyBase.detailPaint);
      EnemyBase.detailPaint.color = const Color(0xFFFFFFFF).withValues(alpha: 0.6);
      canvas.drawCircle(Offset(cx, cy), r * 0.2, EnemyBase.detailPaint);
    }
  }
}

/// Proiettile dell'Orbiter
class _OrbiterBullet extends PositionComponent
    with HasGameReference<GeometryFightGame> {
  final Vector2 direction;
  final Color color;
  late Vector2 _velocity;
  double _lifetime = 3.0;

  _OrbiterBullet({required this.direction, required this.color})
      : super(size: Vector2(6, 6), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    _velocity = direction.normalized() * 250;
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Guard contro race: se player è già stato smontato (game over,
    // transizione scena), rimuovi il bullet invece di accedere a player.position.
    if (!game.player.isMounted) {
      removeFromParent();
      return;
    }
    position += _velocity * dt;
    _lifetime -= dt;
    if (_lifetime <= 0) removeFromParent();

    // Check collision con player (distanza² evita sqrt per frame)
    const double kHitRadius = 12.0;
    const double kHitRadiusSq = kHitRadius * kHitRadius;
    if ((position - game.player.position).length2 < kHitRadiusSq) {
      game.player.takeDamage();
      removeFromParent();
    }
  }

  // Paint cache bullet: evita alloc per frame × N bullet.
  static final Paint _bulletPaint = Paint();

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    _bulletPaint.color = color.withValues(alpha: 0.4);
    canvas.drawCircle(Offset(cx, cy), 5, _bulletPaint);
    _bulletPaint.color = color;
    canvas.drawCircle(Offset(cx, cy), 3, _bulletPaint);
    _bulletPaint.color = const Color(0xFFFFFFFF).withValues(alpha: 0.8);
    canvas.drawCircle(Offset(cx, cy), 1.5, _bulletPaint);
  }
}

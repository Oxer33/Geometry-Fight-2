import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../../data/constants.dart';
import '../../game_world.dart';
import 'enemy_base.dart';

/// ORBITER - Nemico che orbita attorno al player a distanza fissa,
/// sparando proiettili tangenziali periodicamente.
/// Forma: anello con 3 sfere orbitanti
/// Colore: arancione caldo (#FF9933)
/// Meccanica unica: non puoi scappare perché ti segue in orbita!
class OrbiterEnemy extends EnemyBase {
  double _orbitAngle = 0;
  double _orbitRadius = 180;
  double _shootTimer = 2.0;
  double _spherePhase = 0;

  OrbiterEnemy()
      : super(
          hp: 4,
          speed: 200,
          pointValue: 250,
          geomValue: 3,
          neonColor: const Color(0xFFFF9933),
          size: Vector2(20, 20),
        ) {
    _orbitAngle = math.Random().nextDouble() * math.pi * 2;
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

    // Spara periodicamente
    _shootTimer -= dt;
    if (_shootTimer <= 0) {
      _shootTimer = 1.8;
      _shootAtPlayer();
    }
  }

  void _shootAtPlayer() {
    final dir = (playerPosition - position).normalized();
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
    final ringPaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * scale;
    canvas.drawCircle(Offset(cx, cy), r * 0.6, ringPaint);

    // 3 sfere orbitanti
    for (int i = 0; i < 3; i++) {
      final angle = _spherePhase + i * math.pi * 2 / 3;
      final sx = cx + r * 0.85 * math.cos(angle);
      final sy = cy + r * 0.85 * math.sin(angle);
      canvas.drawCircle(Offset(sx, sy), 3 * scale, paint);

      if (scale <= 1.01) {
        final glowP = Paint()
          ..color = paint.color.withValues(alpha: 0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
        canvas.drawCircle(Offset(sx, sy), 4 * scale, glowP);
      }
    }

    // Nucleo
    if (scale <= 1.01) {
      final corePaint = Paint()
        ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawCircle(Offset(cx, cy), r * 0.2, corePaint);
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
    position += _velocity * dt;
    _lifetime -= dt;
    if (_lifetime <= 0) removeFromParent();

    // Check collision con player
    final dist = position.distanceTo(game.player.position);
    if (dist < 12) {
      game.player.takeDamage();
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final p = Paint()
      ..color = color
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(Offset(cx, cy), 3, p);
    p.maskFilter = null;
    p.color = const Color(0xFFFFFFFF).withValues(alpha: 0.8);
    canvas.drawCircle(Offset(cx, cy), 1.5, p);
  }
}

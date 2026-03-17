import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../../data/constants.dart';
import '../../../data/wave_configs.dart';
import 'enemy_base.dart';
import '../projectiles.dart';

class BlackHoleEnemy extends EnemyBase {
  double _rotAngle = 0;
  double _spawnTimer = 5.0;

  BlackHoleEnemy()
      : super(
          hp: 20,
          speed: 0,
          pointValue: 1000,
          geomValue: 10,
          neonColor: NeonColors.darkRed,
          size: Vector2(40, 40),
        );

  @override
  void updateBehavior(double dt) {
    _rotAngle += dt * 2;

    // Attract player (weak force)
    final toHole = position - game.player.position;
    if (toHole.length > 0 && toHole.length < 300) {
      final force = toHole.normalized() * 50 * dt;
      game.player.position += force;
    }

    // Attract nearby enemies
    for (final child in game.world.children) {
      if (child is EnemyBase && child != this) {
        final toHole = position - child.position;
        if (toHole.length > 0 && toHole.length < 200) {
          child.position += toHole.normalized() * 30 * dt;
        }
      }
    }

    // Curve player projectiles
    for (final child in game.world.children) {
      if (child is PlayerBullet) {
        final toBH = position - child.position;
        if (toBH.length > 0 && toBH.length < 200) {
          child.position += toBH.normalized() * 80 * dt;
        }
      }
    }

    // Spawn bonus enemies
    _spawnTimer -= dt;
    if (_spawnTimer <= 0) {
      _spawnTimer = 5.0;
      game.spawnEnemy(
          EnemyType.drone,
          position +
              Vector2(
                (math.Random().nextDouble() - 0.5) * 60,
                (math.Random().nextDouble() - 0.5) * 60,
              ));
    }
  }

  @override
  void takeDamage(double amount) {
    // Immune to normal bullets - only plasma, bomb, laser do damage
    // This is handled by checking weapon type in the bullet collision
    // For simplicity, all damage works but normal bullets do reduced
    super.takeDamage(amount * 0.3);
  }

  @override
  void renderShape(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final r = 18 * scale;

    // Dark center
    final darkPaint = Paint()..color = const Color(0xFF000000);
    canvas.drawCircle(Offset(cx, cy), r * 0.7, darkPaint);

    // Rotating red border
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 3;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(_rotAngle);

    for (int i = 0; i < 4; i++) {
      final angle = i * math.pi / 2;
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: r),
        angle,
        math.pi / 3,
        false,
        paint,
      );
    }
    canvas.restore();

    // Red glow
    final glowPaint = Paint()
      ..color = NeonColors.red.withValues(alpha: 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawCircle(Offset(cx, cy), r * 1.5, glowPaint);

    paint.style = PaintingStyle.fill;
  }
}

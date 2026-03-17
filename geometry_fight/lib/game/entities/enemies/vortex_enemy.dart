import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../../data/constants.dart';
import 'enemy_base.dart';
import '../projectiles.dart';

/// NEW ENEMY: Vortex - creates spinning bullet patterns
class VortexEnemy extends EnemyBase {
  double _spinAngle = 0;
  double _shootTimer = 0;

  VortexEnemy()
      : super(
          hp: 8,
          speed: 50,
          pointValue: 500,
          geomValue: 6,
          neonColor: NeonColors.lime,
          size: Vector2(28, 28),
        );

  @override
  void updateBehavior(double dt) {
    _spinAngle += dt * 3;
    _shootTimer -= dt;

    // Slowly drift around
    final toPlayer = playerPosition - position;
    if (toPlayer.length > 400) {
      position += toPlayer.normalized() * speed * dt;
    }

    // Spiral bullet pattern
    if (_shootTimer <= 0) {
      _shootTimer = 0.15;

      final angle = _spinAngle;
      final dir = Vector2(math.cos(angle), math.sin(angle));
      final bullet = EnemyBullet(
        direction: dir,
        speed: 180,
        color: NeonColors.lime,
      );
      bullet.position = position.clone();
      game.world.add(bullet);
    }
  }

  @override
  void renderShape(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final r = 13 * scale;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(_spinAngle);

    // Spiral arms
    for (int arm = 0; arm < 3; arm++) {
      final armAngle = arm * math.pi * 2 / 3;
      final path = Path();
      for (int i = 0; i < 20; i++) {
        final t = i / 20.0;
        final spiralR = r * t;
        final spiralAngle = armAngle + t * math.pi;
        final x = spiralR * math.cos(spiralAngle);
        final y = spiralR * math.sin(spiralAngle);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 2 * scale;
      canvas.drawPath(path, paint);
    }

    // Center
    paint.style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, 4 * scale, paint);

    canvas.restore();
  }
}

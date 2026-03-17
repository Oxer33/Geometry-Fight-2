import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../../data/constants.dart';
import 'enemy_base.dart';

class DroneEnemy extends EnemyBase {
  DroneEnemy()
      : super(
          hp: 1,
          speed: 180,
          pointValue: 50,
          geomValue: 1,
          neonColor: NeonColors.pink,
          size: Vector2(18, 18),
        );

  @override
  void updateBehavior(double dt) {
    final velocity = seekPlayer(speed);
    position += velocity * dt;
  }

  @override
  void renderShape(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final s = size.x / 2 * scale;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(idlePhase * 3);

    final path = Path()
      ..moveTo(0, -s)
      ..lineTo(s, 0)
      ..lineTo(0, s)
      ..lineTo(-s, 0)
      ..close();
    canvas.drawPath(path, paint);
    canvas.restore();
  }
}

import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../../data/constants.dart';
import 'enemy_base.dart';

class WeaverEnemy extends EnemyBase {
  double _waveOffset = 0;

  WeaverEnemy()
      : super(
          hp: 2,
          speed: 220,
          pointValue: 150,
          geomValue: 2,
          neonColor: NeonColors.lightBlue,
          size: Vector2(16, 24),
        ) {
    _waveOffset = math.Random().nextDouble() * math.pi * 2;
  }

  @override
  void updateBehavior(double dt) {
    final toPlayer = playerPosition - position;
    if (toPlayer.length > 0) {
      final forward = toPlayer.normalized();
      final side = Vector2(-forward.y, forward.x);

      // Sinusoidal side movement
      final sideOffset = math.sin(idlePhase * 4 + _waveOffset) * 200;
      final targetVelocity = forward * speed + side * sideOffset * dt * 3;

      position += targetVelocity * dt;
    }
  }

  @override
  void renderShape(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final w = 6 * scale;
    final h = 12 * scale;

    // Elongated diamond
    final path = Path()
      ..moveTo(cx, cy - h)
      ..lineTo(cx + w, cy)
      ..lineTo(cx, cy + h)
      ..lineTo(cx - w, cy)
      ..close();
    canvas.drawPath(path, paint);
  }
}

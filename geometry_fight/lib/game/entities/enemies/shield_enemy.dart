import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../../data/constants.dart';
import 'enemy_base.dart';

class ShieldEnemy extends EnemyBase {
  double shieldHp = 5;
  double _shieldRegenTimer = 0;
  final double _shieldRegenDelay = 4.0;

  ShieldEnemy()
      : super(
          hp: 3,
          speed: 100,
          pointValue: 350,
          geomValue: 4,
          neonColor: NeonColors.purple,
          size: Vector2(24, 24),
        );

  @override
  void updateBehavior(double dt) {
    // Move towards player, facing them
    final velocity = seekPlayer(speed);
    position += velocity * dt;

    // Shield regen
    if (shieldHp <= 0) {
      _shieldRegenTimer += dt;
      if (_shieldRegenTimer >= _shieldRegenDelay) {
        shieldHp = 5;
        _shieldRegenTimer = 0;
      }
    }
  }

  @override
  void takeDamage(double amount) {
    // Check if bullet is hitting from front (facing player)
    final toPlayer = (playerPosition - position).normalized();
    // For simplicity, shield always faces player
    if (shieldHp > 0) {
      shieldHp -= amount;
      if (shieldHp < 0) shieldHp = 0;
      return;
    }

    super.takeDamage(amount);
  }

  @override
  void renderShape(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;

    // Body - circle
    canvas.drawCircle(Offset(cx, cy), 10 * scale, paint);

    // Shield hexagon (front-facing)
    if (shieldHp > 0) {
      final shieldPaint = Paint()
        ..color = NeonColors.purple.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      final toPlayer = (playerPosition - position);
      final angle = math.atan2(toPlayer.y, toPlayer.x);

      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(angle);

      // Arc shield
      final shieldPath = Path();
      for (int i = -3; i <= 3; i++) {
        final a = i * math.pi / 8;
        final x = 14 * scale * math.cos(a);
        final y = 14 * scale * math.sin(a);
        if (i == -3) {
          shieldPath.moveTo(x, y);
        } else {
          shieldPath.lineTo(x, y);
        }
      }
      canvas.drawPath(shieldPath, shieldPaint);
      canvas.restore();
    }
  }
}

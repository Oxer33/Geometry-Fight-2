import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../../data/constants.dart';
import 'enemy_base.dart';
import '../projectiles.dart';

/// NEW ENEMY: Mirror - reflects player bullets back at them
class MirrorEnemy extends EnemyBase {
  double _reflectCooldown = 0;
  double _shieldFlash = 0;

  MirrorEnemy()
      : super(
          hp: 5,
          speed: 90,
          pointValue: 300,
          geomValue: 4,
          neonColor: NeonColors.magenta,
          size: Vector2(26, 26),
        );

  @override
  void updateBehavior(double dt) {
    // Slowly approach player
    final velocity = seekPlayer(speed);
    position += velocity * dt;

    if (_reflectCooldown > 0) _reflectCooldown -= dt;
    if (_shieldFlash > 0) _shieldFlash -= dt;

    // Check for nearby player bullets and reflect them
    if (_reflectCooldown <= 0) {
      for (final child in game.world.children.toList()) {
        if (child is PlayerBullet) {
          final dist = child.position.distanceTo(position);
          if (dist < 30) {
            // Reflect: remove player bullet, spawn enemy bullet going back
            final reflectDir = (child.position - position).normalized();
            final reflected = EnemyBullet(
              direction: reflectDir,
              speed: 400,
              color: NeonColors.magenta,
            );
            reflected.position = child.position.clone();
            game.world.add(reflected);
            child.removeFromParent();
            _reflectCooldown = 0.3;
            _shieldFlash = 0.2;
            break;
          }
        }
      }
    }
  }

  @override
  void renderShape(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final r = 12 * scale;

    // Octagon shape
    final path = Path();
    for (int i = 0; i < 8; i++) {
      final angle = i * math.pi / 4 + idlePhase * 0.5;
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);

    // Shield flash when reflecting
    if (_shieldFlash > 0) {
      final flashPaint = Paint()
        ..color = NeonColors.white.withValues(alpha: _shieldFlash * 3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(Offset(cx, cy), r * 1.3, flashPaint);
    }
  }
}

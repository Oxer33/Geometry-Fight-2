import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../../data/constants.dart';
import 'enemy_base.dart';

class MineEnemy extends EnemyBase {
  double _detonateTimer = -1;
  bool _detonating = false;

  MineEnemy()
      : super(
          hp: 2,
          speed: 0,
          pointValue: 75,
          geomValue: 2,
          neonColor: NeonColors.gray,
          size: Vector2(20, 20),
        );

  @override
  void updateBehavior(double dt) {
    // Check proximity to player
    if (!_detonating && distanceToPlayer < 80) {
      _detonating = true;
      _detonateTimer = 0.5;
    }

    if (_detonating) {
      _detonateTimer -= dt;
      if (_detonateTimer <= 0) {
        _explode();
      }
    }
  }

  @override
  void takeDamage(double amount) {
    if (!_detonating) {
      _detonating = true;
      _detonateTimer = 0.5;
    }
    super.takeDamage(amount);
  }

  void _explode() {
    // Damage player if in range
    if (distanceToPlayer < 100) {
      game.player.takeDamage();
    }
    game.spawnExplosion(position, NeonColors.gray, radius: 100, particleCount: 25);
    game.grid.applyForce(position, 150, 800);
    removeFromParent();
    game.onEnemyKilled(this);
  }

  @override
  void renderShape(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final r = 8 * scale;

    // Star shape (8 points)
    final path = Path();
    for (int i = 0; i < 16; i++) {
      final angle = i * math.pi / 8 + idlePhase * 0.5;
      final radius = i % 2 == 0 ? r : r * 0.5;
      final x = cx + radius * math.cos(angle);
      final y = cy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    // Flash when detonating
    if (_detonating) {
      final flash = ((_detonateTimer * 20).toInt() % 2 == 0);
      if (flash) {
        paint.color = const Color(0xFFFF0000);
      }
    }

    canvas.drawPath(path, paint);
  }
}

import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../../data/constants.dart';
import '../../../data/wave_configs.dart';
import 'enemy_base.dart';

class SpawnerEnemy extends EnemyBase {
  double _spawnTimer = 3.0;

  SpawnerEnemy()
      : super(
          hp: 15,
          speed: 60,
          pointValue: 500,
          geomValue: 5,
          neonColor: NeonColors.orange,
          size: Vector2(30, 30),
        );

  @override
  void updateBehavior(double dt) {
    // Move slowly away from player (towards edges)
    final awayDir = (position - playerPosition);
    if (awayDir.length > 0) {
      awayDir.normalize();
      position += awayDir * speed * dt;
    }

    // Spawn drones periodically
    _spawnTimer -= dt;
    if (_spawnTimer <= 0) {
      _spawnTimer = 3.0;
      for (int i = 0; i < 2; i++) {
        final offset = Vector2(
          (math.Random().nextDouble() - 0.5) * 40,
          (math.Random().nextDouble() - 0.5) * 40,
        );
        game.spawnEnemy(EnemyType.drone, position + offset);
      }
    }
  }

  @override
  void renderShape(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final r = 14 * scale;

    // Hexagon
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = i * math.pi / 3 - math.pi / 6;
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

    // Pulsing core
    final corePulse = 4 + math.sin(idlePhase * 4) * 2;
    final corePaint = Paint()
      ..color = NeonColors.orange.withValues(alpha: 0.8);
    canvas.drawCircle(Offset(cx, cy), corePulse, corePaint);
  }
}

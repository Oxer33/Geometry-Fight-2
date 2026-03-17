import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../../data/constants.dart';
import 'enemy_base.dart';
import '../projectiles.dart';

/// NEW ENEMY: Pulsar - emits periodic energy rings that damage the player
class PulsarEnemy extends EnemyBase {
  double _pulseTimer = 2.5;
  double _pulseRadius = 0;
  bool _pulsing = false;

  PulsarEnemy()
      : super(
          hp: 4,
          speed: 80,
          pointValue: 250,
          geomValue: 3,
          neonColor: NeonColors.teal,
          size: Vector2(22, 22),
        );

  @override
  void updateBehavior(double dt) {
    // Orbit around the player at a distance
    final toPlayer = playerPosition - position;
    final dist = toPlayer.length;

    if (dist > 250) {
      position += toPlayer.normalized() * speed * dt;
    } else if (dist < 180) {
      position -= toPlayer.normalized() * speed * dt;
    } else {
      // Orbit
      final perpendicular = Vector2(-toPlayer.y, toPlayer.x).normalized();
      position += perpendicular * speed * dt;
    }

    // Pulse attack
    _pulseTimer -= dt;
    if (_pulseTimer <= 0) {
      _pulseTimer = 2.5;
      _pulsing = true;
      _pulseRadius = 0;

      // Spawn ring bullets
      for (int i = 0; i < 12; i++) {
        final angle = i * math.pi * 2 / 12;
        final dir = Vector2(math.cos(angle), math.sin(angle));
        final bullet = EnemyBullet(
          direction: dir,
          speed: 200,
          color: NeonColors.teal,
        );
        bullet.position = position.clone();
        game.world.add(bullet);
      }
    }

    if (_pulsing) {
      _pulseRadius += dt * 300;
      if (_pulseRadius > 150) _pulsing = false;
    }
  }

  @override
  void renderShape(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final r = 10 * scale;

    // Pentagon shape
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final angle = i * math.pi * 2 / 5 - math.pi / 2 + idlePhase;
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

    // Pulse ring
    if (_pulsing) {
      final alpha = 1.0 - (_pulseRadius / 150);
      final ringPaint = Paint()
        ..color = NeonColors.teal.withValues(alpha: alpha * 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(Offset(cx, cy), _pulseRadius, ringPaint);
    }
  }
}

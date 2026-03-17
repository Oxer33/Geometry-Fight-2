import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../../data/constants.dart';
import 'enemy_base.dart';

class SnakeEnemy extends EnemyBase {
  final int segmentCount;
  final List<Vector2> _segments = [];
  final List<Vector2> _segmentVelocities = [];
  final bool isFragment;

  SnakeEnemy({this.segmentCount = 8, this.isFragment = false})
      : super(
          hp: 1,
          speed: 120,
          pointValue: 100,
          geomValue: 2,
          neonColor: NeonColors.green,
          size: Vector2(12, 12),
        ) {
    hp = segmentCount.toDouble();
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _segments.clear();
    for (int i = 0; i < segmentCount; i++) {
      _segments.add(position - Vector2(0, i * 14.0));
      _segmentVelocities.add(Vector2.zero());
    }
  }

  @override
  void updateBehavior(double dt) {
    // Head follows player
    final dir = seekPlayer(speed);
    position += dir * dt;

    // Update segment positions (follow the leader)
    if (_segments.isNotEmpty) {
      _segments[0] = position.clone();
      for (int i = 1; i < _segments.length; i++) {
        final target = _segments[i - 1];
        final current = _segments[i];
        final toTarget = target - current;
        if (toTarget.length > 14) {
          _segments[i] = current + toTarget.normalized() * (toTarget.length - 14);
        }
      }
    }
  }

  @override
  void takeDamage(double amount) {
    hp -= amount;
    if (hp <= 0) {
      onDeath();
    } else if (_segments.length > 2 && hp <= _segments.length / 2) {
      // Split into two snakes
      _split();
    }
  }

  void _split() {
    if (_segments.length < 4) return;

    final midPoint = _segments.length ~/ 2;

    // Create a new snake from the tail half
    final tailSnake = SnakeEnemy(
        segmentCount: _segments.length - midPoint, isFragment: true);
    tailSnake.position = _segments[midPoint].clone();
    tailSnake.hp = (_segments.length - midPoint).toDouble();
    game.world.add(tailSnake);

    // Trim current snake
    while (_segments.length > midPoint) {
      _segments.removeLast();
    }
    hp = _segments.length.toDouble();
  }

  @override
  void renderShape(Canvas canvas, Paint paint, double scale) {
    // Draw segments
    for (int i = 0; i < _segments.length; i++) {
      final seg = _segments[i] - position;
      final radius = (6 - i * 0.3).clamp(3.0, 6.0) * scale;
      canvas.drawCircle(
        Offset(size.x / 2 + seg.x, size.y / 2 + seg.y),
        radius,
        paint,
      );
    }

    // If segments not initialized yet, draw at center
    if (_segments.isEmpty) {
      canvas.drawCircle(Offset(size.x / 2, size.y / 2), 6 * scale, paint);
    }
  }
}

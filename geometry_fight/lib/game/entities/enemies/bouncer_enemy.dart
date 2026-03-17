import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../../data/constants.dart';
import 'enemy_base.dart';

class BouncerEnemy extends EnemyBase {
  late Vector2 _velocity;
  double _maxSpeed = 500;

  BouncerEnemy()
      : super(
          hp: 3,
          speed: 200,
          pointValue: 200,
          geomValue: 3,
          neonColor: NeonColors.yellow,
          size: Vector2(16, 16),
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final angle = math.Random().nextDouble() * math.pi * 2;
    _velocity = Vector2(math.cos(angle), math.sin(angle)) * speed;
  }

  @override
  void updateBehavior(double dt) {
    position += _velocity * dt;

    // Bounce off walls
    if (position.x <= 8 || position.x >= arenaWidth - 8) {
      _velocity.x = -_velocity.x;
      position.x = position.x.clamp(8, arenaWidth - 8);
      _accelerate();
    }
    if (position.y <= 8 || position.y >= arenaHeight - 8) {
      _velocity.y = -_velocity.y;
      position.y = position.y.clamp(8, arenaHeight - 8);
      _accelerate();
    }
  }

  void _accelerate() {
    final currentSpeed = _velocity.length;
    if (currentSpeed < _maxSpeed) {
      _velocity = _velocity.normalized() * (currentSpeed * 1.1);
    }
  }

  @override
  void renderShape(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    canvas.drawCircle(Offset(cx, cy), 8 * scale, paint);
  }
}

import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../../data/constants.dart';
import 'enemy_base.dart';

enum KamikazeState { idle, charging, rushing, recovering }

class KamikazeEnemy extends EnemyBase {
  KamikazeState _state = KamikazeState.idle;
  double _stateTimer = 1.5;
  Vector2? _rushDirection;
  double _flashRate = 2;

  KamikazeEnemy()
      : super(
          hp: 1,
          speed: 800,
          pointValue: 100,
          geomValue: 2,
          neonColor: NeonColors.red,
          size: Vector2(16, 22),
        );

  @override
  void updateBehavior(double dt) {
    _stateTimer -= dt;

    switch (_state) {
      case KamikazeState.idle:
        if (_stateTimer <= 0) {
          _state = KamikazeState.charging;
          _stateTimer = 1.5;
          _flashRate = 2;
        }
      case KamikazeState.charging:
        // Accelerating flash to telegraph
        _flashRate += dt * 15;
        if (_stateTimer <= 0) {
          _state = KamikazeState.rushing;
          _rushDirection = (playerPosition - position).normalized();
          _stateTimer = 1.0;
        }
      case KamikazeState.rushing:
        position += _rushDirection! * speed * dt;
        if (_stateTimer <= 0) {
          _state = KamikazeState.recovering;
          _stateTimer = 0.5;
        }
      case KamikazeState.recovering:
        if (_stateTimer <= 0) {
          _state = KamikazeState.charging;
          _stateTimer = 1.5;
          _flashRate = 2;
        }
    }
  }

  @override
  void renderShape(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final w = 7 * scale;
    final h = 11 * scale;

    // Flash during charging
    if (_state == KamikazeState.charging) {
      if ((idlePhase * _flashRate).toInt() % 2 == 0) {
        paint.color = const Color(0xFFFFFFFF);
      }
    }

    // Arrow/pointed triangle
    final angle = _rushDirection != null
        ? math.atan2(_rushDirection!.y, _rushDirection!.x) + math.pi / 2
        : math.atan2(playerPosition.y - position.y,
                playerPosition.x - position.x) +
            math.pi / 2;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(angle);

    final path = Path()
      ..moveTo(0, -h)
      ..lineTo(w, h * 0.5)
      ..lineTo(w * 0.3, h * 0.2)
      ..lineTo(-w * 0.3, h * 0.2)
      ..lineTo(-w, h * 0.5)
      ..close();
    canvas.drawPath(path, paint);
    canvas.restore();
  }
}

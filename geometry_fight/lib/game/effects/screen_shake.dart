import 'dart:math' as math;
import 'package:flame/components.dart';

class ScreenShakeEffect extends Component {
  double _intensity = 0;
  double _duration = 0;
  double _timer = 0;
  final _random = math.Random();

  Vector2 offset = Vector2.zero();

  void shake(double intensity, double duration) {
    _intensity = intensity;
    _duration = duration;
    _timer = duration;
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_timer > 0) {
      _timer -= dt;
      final progress = _timer / _duration;
      final currentIntensity = _intensity * progress;

      offset = Vector2(
        (_random.nextDouble() - 0.5) * 2 * currentIntensity,
        (_random.nextDouble() - 0.5) * 2 * currentIntensity,
      );

      if (parent is PositionComponent) {
        (parent as PositionComponent).position = offset;
      }
    } else if (offset.length > 0) {
      offset = Vector2.zero();
      if (parent is PositionComponent) {
        (parent as PositionComponent).position = Vector2.zero();
      }
    }
  }
}

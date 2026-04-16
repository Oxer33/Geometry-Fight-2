import 'dart:math' as math;
import 'package:flame/components.dart';

class ScreenShakeEffect extends Component {
  double _intensity = 0;
  double _duration = 0;
  double _timer = 0;
  final _random = math.Random();

  Vector2 _previousOffset = Vector2.zero();

  void shake(double intensity, double duration) {
    if (duration <= 0) return;
    _intensity = math.max(_intensity, intensity);
    _duration = math.max(_duration, duration);
    _timer = math.max(_timer, duration); // FIX: non azzerare uno shake già in corso
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (parent is! PositionComponent) return;
    final p = parent as PositionComponent;

    if (_timer > 0) {
      _timer -= dt;
      final progress = (_timer / _duration).clamp(0.0, 1.0);
      final currentIntensity = _intensity * progress;

      final newOffset = Vector2(
        (_random.nextDouble() - 0.5) * 2 * currentIntensity,
        (_random.nextDouble() - 0.5) * 2 * currentIntensity,
      );

      // Apply delta: undo previous offset, apply new one
      p.position -= _previousOffset;
      p.position += newOffset;
      _previousOffset = newOffset;

      if (_timer <= 0) {
        _intensity = 0;
      }
    } else if (_previousOffset.length > 0) {
      // Undo last offset to restore original position
      p.position -= _previousOffset;
      _previousOffset = Vector2.zero();
    }
  }

  @override
  void onRemove() {
    // Safety: undo any remaining offset when removed
    if (parent is PositionComponent && _previousOffset.length > 0) {
      (parent as PositionComponent).position -= _previousOffset;
      _previousOffset = Vector2.zero();
    }
    super.onRemove();
  }
}

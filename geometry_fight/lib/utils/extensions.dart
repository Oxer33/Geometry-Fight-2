import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';

extension Vector2Ext on Vector2 {
  Vector2 rotatedBy(double angle) {
    final c = math.cos(angle);
    final s = math.sin(angle);
    return Vector2(x * c - y * s, x * s + y * c);
  }

  double get heading => math.atan2(y, x);

  Vector2 clampLength(double maxLength) {
    if (length2 > maxLength * maxLength) {
      return normalized() * maxLength;
    }
    return clone();
  }

  double distanceToSquared(Vector2 other) {
    final dx = x - other.x;
    final dy = y - other.y;
    return dx * dx + dy * dy;
  }

  static final _random = math.Random();

  static Vector2 randomInCircle(double radius) {
    final angle = _random.nextDouble() * 2 * math.pi;
    final r = math.sqrt(_random.nextDouble()) * radius;
    return Vector2(math.cos(angle) * r, math.sin(angle) * r);
  }

  static Vector2 randomDirection() {
    final angle = _random.nextDouble() * 2 * math.pi;
    return Vector2(math.cos(angle), math.sin(angle));
  }

  static Vector2 randomInRect(double width, double height) {
    return Vector2(
      _random.nextDouble() * width,
      _random.nextDouble() * height,
    );
  }
}

extension ColorExt on Color {
  Color withGlowAlpha([double factor = 0.5]) {
    return withValues(alpha: factor);
  }

  Color flash(double t) {
    return Color.lerp(this, const Color(0xFFFFFFFF), t)!;
  }
}

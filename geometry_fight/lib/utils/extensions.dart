import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';

/// Helper extensions su Vector2 / Color.
/// NOTE: al momento il file non è importato da nessun modulo (grep in `lib/`
/// restituisce 0 risultati); `Vector2.distanceToSquared` usato altrove arriva
/// dalla built-in di Flame. Teniamo i membri ancora utili come utility
/// generali, ma RIMOSSO `clampLength(double)` che shadowava la built-in
/// `Vector2.clampLength(double min, double max)` e introduceva ambiguità.
extension Vector2Ext on Vector2 {
  Vector2 rotatedBy(double angle) {
    final c = math.cos(angle);
    final s = math.sin(angle);
    return Vector2(x * c - y * s, x * s + y * c);
  }

  double get heading => math.atan2(y, x);

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
    return Vector2(_random.nextDouble() * width, _random.nextDouble() * height);
  }
}

extension ColorExt on Color {
  /// Returns a copy of this color with alpha set to [factor] (0.0 – 1.0).
  /// Clamps defensively to avoid out-of-range alpha.
  Color withGlowAlpha([double factor = 0.5]) {
    final clamped = factor.clamp(0.0, 1.0);
    return withValues(alpha: clamped);
  }

  /// Lerps this color toward pure white by [t] (0.0 – 1.0). Used for hit-flash
  /// animations. [t] is clamped defensively to keep `Color.lerp` non-null.
  Color flash(double t) {
    final clamped = t.clamp(0.0, 1.0);
    return Color.lerp(this, const Color(0xFFFFFFFF), clamped)!;
  }
}

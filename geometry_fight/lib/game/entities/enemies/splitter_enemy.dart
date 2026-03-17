import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../../data/constants.dart';
import 'enemy_base.dart';

enum SplitterSize { large, medium, small }

class SplitterEnemy extends EnemyBase {
  final SplitterSize splitterSize;

  SplitterEnemy({this.splitterSize = SplitterSize.large})
      : super(
          hp: 1,
          speed: _speedForSize(splitterSize),
          pointValue: _pointsForSize(splitterSize),
          geomValue: _geomsForSize(splitterSize),
          neonColor: NeonColors.white,
          size: _sizeForSize(splitterSize),
        );

  static double _speedForSize(SplitterSize s) {
    switch (s) {
      case SplitterSize.large:
        return 100;
      case SplitterSize.medium:
        return 180;
      case SplitterSize.small:
        return 300;
    }
  }

  static int _pointsForSize(SplitterSize s) {
    switch (s) {
      case SplitterSize.large:
        return 300;
      case SplitterSize.medium:
        return 100;
      case SplitterSize.small:
        return 50;
    }
  }

  static int _geomsForSize(SplitterSize s) {
    switch (s) {
      case SplitterSize.large:
        return 3;
      case SplitterSize.medium:
        return 2;
      case SplitterSize.small:
        return 1;
    }
  }

  static Vector2 _sizeForSize(SplitterSize s) {
    switch (s) {
      case SplitterSize.large:
        return Vector2(28, 28);
      case SplitterSize.medium:
        return Vector2(18, 18);
      case SplitterSize.small:
        return Vector2(10, 10);
    }
  }

  @override
  void updateBehavior(double dt) {
    final velocity = seekPlayer(speed);
    position += velocity * dt;
  }

  @override
  void onDeath() {
    // Split into smaller pieces
    SplitterSize? nextSize;
    switch (splitterSize) {
      case SplitterSize.large:
        nextSize = SplitterSize.medium;
      case SplitterSize.medium:
        nextSize = SplitterSize.small;
      case SplitterSize.small:
        nextSize = null;
    }

    if (nextSize != null) {
      for (int i = 0; i < 3; i++) {
        final child = SplitterEnemy(splitterSize: nextSize);
        final angle = i * math.pi * 2 / 3;
        child.position =
            position + Vector2(math.cos(angle), math.sin(angle)) * 20;
        game.world.add(child);
      }
    }

    super.onDeath();
  }

  @override
  void renderShape(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final r = size.x / 2 * scale;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(idlePhase * 2);

    final path = Path()
      ..moveTo(0, -r)
      ..lineTo(r * 0.87, r * 0.5)
      ..lineTo(-r * 0.87, r * 0.5)
      ..close();
    canvas.drawPath(path, paint);
    canvas.restore();
  }
}

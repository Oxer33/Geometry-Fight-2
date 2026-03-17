import 'dart:ui';
import 'package:flame/components.dart';
import '../../data/constants.dart';

class _GridNode {
  Vector2 position;
  Vector2 restPosition;
  Vector2 velocity;

  _GridNode(this.restPosition)
      : position = restPosition.clone(),
        velocity = Vector2.zero();
}

class GridDistortion extends PositionComponent {
  final List<List<_GridNode>> _nodes = [];
  final double _spacing = arenaWidth / gridCols;

  GridDistortion() : super(priority: -10);

  @override
  Future<void> onLoad() async {
    // Create grid nodes
    for (int y = 0; y <= gridRows; y++) {
      final row = <_GridNode>[];
      for (int x = 0; x <= gridCols; x++) {
        row.add(_GridNode(Vector2(x * _spacing, y * _spacing)));
      }
      _nodes.add(row);
    }
  }

  void applyForce(Vector2 center, double radius, double force) {
    for (final row in _nodes) {
      for (final node in row) {
        final dist = node.position.distanceTo(center);
        if (dist < radius && dist > 0) {
          final strength = force * (1.0 - dist / radius);
          final dir = (node.position - center).normalized();
          node.velocity += dir * strength;
        }
      }
    }
  }

  void applyAttraction(Vector2 center, double radius, double force) {
    for (final row in _nodes) {
      for (final node in row) {
        final dist = node.position.distanceTo(center);
        if (dist < radius && dist > 0) {
          final strength = force * (1.0 - dist / radius);
          final dir = (center - node.position).normalized();
          node.velocity += dir * strength;
        }
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    for (final row in _nodes) {
      for (final node in row) {
        // Spring back to rest
        final displacement = node.restPosition - node.position;
        node.velocity += displacement * gridSpringStiffness * dt;

        // Damping
        node.velocity *= gridDamping;

        // Update position
        node.position += node.velocity * dt;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = const Color(0x26AADDFF) // ~0.15 alpha
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // Draw horizontal lines
    for (int y = 0; y <= gridRows; y++) {
      final path = Path();
      for (int x = 0; x <= gridCols; x++) {
        final pos = _nodes[y][x].position;
        if (x == 0) {
          path.moveTo(pos.x, pos.y);
        } else {
          path.lineTo(pos.x, pos.y);
        }
      }
      canvas.drawPath(path, paint);
    }

    // Draw vertical lines
    for (int x = 0; x <= gridCols; x++) {
      final path = Path();
      for (int y = 0; y <= gridRows; y++) {
        final pos = _nodes[y][x].position;
        if (y == 0) {
          path.moveTo(pos.x, pos.y);
        } else {
          path.lineTo(pos.x, pos.y);
        }
      }
      canvas.drawPath(path, paint);
    }
  }
}

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

  // Path cache — evita 102 allocazioni Path ogni frame
  final List<Path> _hPaths = [];
  final List<Path> _vPaths = [];
  bool _pathsCreated = false;

  // Paint cache — 1 allocazione anziché ogni frame
  static final _gridPaint = Paint()
    ..color = const Color(0x26AADDFF) // ~0.15 alpha
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.5;

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

    // Pre-alloca i Path (riutilizzati ogni frame con reset())
    for (int y = 0; y <= gridRows; y++) {
      _hPaths.add(Path());
    }
    for (int x = 0; x <= gridCols; x++) {
      _vPaths.add(Path());
    }
    _pathsCreated = true;
  }

  void applyForce(Vector2 center, double radius, double force) {
    final radiusSq = radius * radius;
    for (final row in _nodes) {
      for (final node in row) {
        final dx = node.position.x - center.x;
        final dy = node.position.y - center.y;
        final distSq = dx * dx + dy * dy;
        if (distSq < radiusSq && distSq > 0) {
          final dist = node.position.distanceTo(center);
          final strength = force * (1.0 - dist / radius);
          final dir = (node.position - center)..normalize();
          node.velocity += dir * strength;
        }
      }
    }
  }

  void applyAttraction(Vector2 center, double radius, double force) {
    final radiusSq = radius * radius;
    for (final row in _nodes) {
      for (final node in row) {
        final dx = node.position.x - center.x;
        final dy = node.position.y - center.y;
        final distSq = dx * dx + dy * dy;
        if (distSq < radiusSq && distSq > 0) {
          final dist = node.position.distanceTo(center);
          final strength = force * (1.0 - dist / radius);
          final dir = (center - node.position)..normalize();
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
    if (!_pathsCreated) return;

    // Riutilizza Path esistenti con reset() — 0 allocazioni per frame
    for (int y = 0; y <= gridRows; y++) {
      _hPaths[y].reset();
      for (int x = 0; x <= gridCols; x++) {
        final pos = _nodes[y][x].position;
        if (x == 0) {
          _hPaths[y].moveTo(pos.x, pos.y);
        } else {
          _hPaths[y].lineTo(pos.x, pos.y);
        }
      }
      canvas.drawPath(_hPaths[y], _gridPaint);
    }

    for (int x = 0; x <= gridCols; x++) {
      _vPaths[x].reset();
      for (int y = 0; y <= gridRows; y++) {
        final pos = _nodes[y][x].position;
        if (y == 0) {
          _vPaths[x].moveTo(pos.x, pos.y);
        } else {
          _vPaths[x].lineTo(pos.x, pos.y);
        }
      }
      canvas.drawPath(_vPaths[x], _gridPaint);
    }
  }
}

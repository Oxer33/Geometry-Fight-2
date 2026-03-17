import 'package:flame/components.dart';

class SpatialHash<T> {
  final double cellSize;
  final Map<int, List<SpatialEntry<T>>> _cells = {};

  SpatialHash({this.cellSize = 64});

  int _hashKey(int cx, int cy) => cx * 73856093 ^ cy * 19349663;

  void clear() {
    _cells.clear();
  }

  void insert(T item, Vector2 position, double radius) {
    final minCx = ((position.x - radius) / cellSize).floor();
    final maxCx = ((position.x + radius) / cellSize).floor();
    final minCy = ((position.y - radius) / cellSize).floor();
    final maxCy = ((position.y + radius) / cellSize).floor();

    final entry = SpatialEntry(item, position, radius);

    for (int cx = minCx; cx <= maxCx; cx++) {
      for (int cy = minCy; cy <= maxCy; cy++) {
        final key = _hashKey(cx, cy);
        _cells.putIfAbsent(key, () => []).add(entry);
      }
    }
  }

  List<T> query(Vector2 position, double radius) {
    final results = <T>{};
    final minCx = ((position.x - radius) / cellSize).floor();
    final maxCx = ((position.x + radius) / cellSize).floor();
    final minCy = ((position.y - radius) / cellSize).floor();
    final maxCy = ((position.y + radius) / cellSize).floor();

    for (int cx = minCx; cx <= maxCx; cx++) {
      for (int cy = minCy; cy <= maxCy; cy++) {
        final key = _hashKey(cx, cy);
        final cell = _cells[key];
        if (cell != null) {
          for (final entry in cell) {
            final dist = position.distanceTo(entry.position);
            if (dist <= radius + entry.radius) {
              results.add(entry.item);
            }
          }
        }
      }
    }
    return results.toList();
  }
}

class SpatialEntry<T> {
  final T item;
  final Vector2 position;
  final double radius;

  SpatialEntry(this.item, this.position, this.radius);
}

import 'dart:math' as math;
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
  // Spacing separato per X e Y — copre l'arena 16:9 senza deformazioni
  final double _spacingX = arenaWidth / gridCols;
  final double _spacingY = arenaHeight / gridRows;

  // Path cache — evita 102 allocazioni Path ogni frame
  final List<Path> _hPaths = [];
  final List<Path> _vPaths = [];
  bool _pathsCreated = false;

  // Paint cache — 1 allocazione anziché ogni frame
  static final _gridPaint = Paint()
    ..color = const Color(0x26AADDFF) // ~0.15 alpha
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.5;

  // At-rest early exit: salta l'update quando la griglia è ferma (caso comune)
  // → 0 lavoro tra un'esplosione e l'altra, indipendente dal refresh rate
  bool _hasActiveNodes = false;

  // Skip-frame physics: fisica a ~60Hz anche a 120fps
  // Accumula dt e aggiorna solo quando supera la soglia minima
  double _physicsAccumulator = 0.0;
  static const _physicsStep = 1.0 / 60.0; // 60Hz fisica

  // Render dirty flag: evita rebuild dei Path quando la griglia è a riposo
  bool _pathsDirty = false;

  GridDistortion() : super(priority: -10);

  @override
  Future<void> onLoad() async {
    // Create grid nodes
    for (int y = 0; y <= gridRows; y++) {
      final row = <_GridNode>[];
      for (int x = 0; x <= gridCols; x++) {
        row.add(_GridNode(Vector2(x * _spacingX, y * _spacingY)));
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

  // Velocity cap: prevents unbounded accumulation when multiple explosions
  // land in the same frame (boss ring + player bomb overlap). Without the
  // cap, velocity can reach 10K+ px/s → spring overshoots rest by orders of
  // magnitude → visible grid warp and wasted update cycles.
  static const double _maxNodeSpeed = 2000.0;
  static const double _maxNodeSpeedSq = _maxNodeSpeed * _maxNodeSpeed;

  static void _capVelocity(_GridNode node) {
    final lenSq = node.velocity.length2;
    if (lenSq > _maxNodeSpeedSq) {
      node.velocity.scale(_maxNodeSpeed / math.sqrt(lenSq));
    }
  }

  void applyForce(Vector2 center, double radius, double force) {
    final radiusSq = radius * radius;
    // NaN guard: distSq > 1e-6 (non solo > 0) evita NaN da normalize
    // quando dx/dy sono ~1e-10 per precision loss.
    const minDistSq = 1e-6;
    for (final row in _nodes) {
      for (final node in row) {
        final dx = node.position.x - center.x;
        final dy = node.position.y - center.y;
        final distSq = dx * dx + dy * dy;
        if (distSq < radiusSq && distSq > minDistSq) {
          final dist = math.sqrt(distSq);
          final strength = force * (1.0 - dist / radius);
          final dir = (node.position - center)..normalize();
          node.velocity += dir * strength;
          _capVelocity(node);
        }
      }
    }
    _hasActiveNodes = true;
  }

  void applyAttraction(Vector2 center, double radius, double force) {
    final radiusSq = radius * radius;
    const minDistSq = 1e-6;
    for (final row in _nodes) {
      for (final node in row) {
        final dx = node.position.x - center.x;
        final dy = node.position.y - center.y;
        final distSq = dx * dx + dy * dy;
        if (distSq < radiusSq && distSq > minDistSq) {
          final dist = math.sqrt(distSq);
          final strength = force * (1.0 - dist / radius);
          final dir = (center - node.position)..normalize();
          node.velocity += dir * strength;
          _capVelocity(node);
        }
      }
    }
    _hasActiveNodes = true;
  }

  @override
  void update(double dt) {
    super.update(dt);

    // At-rest early exit: nessuna distorsione attiva → 0 lavoro
    if (!_hasActiveNodes) return;

    // Accumula dt e aggiorna fisica a step fissi (~60Hz)
    // A 120fps: aggiorna ogni 2 frame con dt doppio → metà CPU, fisica identica
    _physicsAccumulator += dt;
    if (_physicsAccumulator < _physicsStep) return;

    // Damping frame-rate independent: esponente normalizza per frequenza
    // Identico visivamente a 30, 60 o 120fps
    final frameDamping = math.pow(gridDamping, _physicsStep * 60).toDouble();

    bool stillActive = false;
    // Substeps loop: consuma l'accumulatore in step fissi, max 4 iterazioni
    // (~66ms) — previene esplosione spring dopo app resume / long frame.
    int iterations = 0;
    while (_physicsAccumulator >= _physicsStep && iterations < 4) {
      for (final row in _nodes) {
        for (final node in row) {
          // Spring back to rest
          final displacement = node.restPosition - node.position;
          node.velocity += displacement * gridSpringStiffness * _physicsStep;

          // Damping normalizzato per dt
          node.velocity *= frameDamping;

          // Update position
          node.position += node.velocity * _physicsStep;

          // Check if any node still has meaningful velocity
          if (node.velocity.length2 > 0.1) stillActive = true;
        }
      }
      _physicsAccumulator -= _physicsStep;
      iterations++;
    }
    // Scarta eventuale residuo se abbiamo raggiunto il cap di iterazioni
    if (iterations >= 4) {
      _physicsAccumulator = 0.0;
    }
    // Quando tutti i nodi si sono fermati, disabilita updates finché
    // non arriva una nuova esplosione (applyForce/applyAttraction)
    _hasActiveNodes = stillActive;
    _pathsDirty = true;
  }

  @override
  void render(Canvas canvas) {
    if (!_pathsCreated) return;

    if (_pathsDirty) {
      // Ricostruisce i Path solo quando la fisica ha aggiornato le posizioni
      // Riutilizza Path esistenti con reset() — 0 allocazioni per frame
      _pathsDirty = false;

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
      }
    }

    // Disegna i Path (cached o appena ricostruiti) — sempre necessario ogni frame
    for (int y = 0; y <= gridRows; y++) {
      canvas.drawPath(_hPaths[y], _gridPaint);
    }
    for (int x = 0; x <= gridCols; x++) {
      canvas.drawPath(_vPaths[x], _gridPaint);
    }
  }
}

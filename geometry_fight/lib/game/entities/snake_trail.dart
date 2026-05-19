import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import '../game_world.dart';
import 'enemies/enemy_base.dart';

/// Snake mode trail segment: emitted behind the player roughly every ~0.03s.
/// Each segment is a [PositionComponent] with a [CircleHitbox] that collides
/// with [EnemyBase]; on contact applies a massive damage value (999999) so the
/// enemy is one-shotted through the standard kill path and spawns a small
/// green pop on the impact location.
///
/// Lifetime: 4s. Color: cyan→green gradient pulse with outer glow + bright
/// white nucleus. Visual radius: ~6px (with halo ~13px). Collision radius: 8px.
///
/// Player owns the active segment list and enforces a cap of ~150 active
/// segments by removing the oldest entry when exceeded (see `player.dart`).
class SnakeTrailSegment extends PositionComponent
    with HasGameReference<GeometryFightGame>, CollisionCallbacks {
  /// Lifetime in seconds before the segment auto-removes.
  static const double _maxLife = 4.0;
  /// Fade window in the last [_fadeWindow] seconds — alpha 1 → 0 linearly.
  static const double _fadeWindow = 0.5;
  /// Visual core radius in px.
  static const double _radius = 6.0;
  /// Collision radius (slightly larger than visual for forgiving hits).
  static const double _hitboxRadius = 8.0;

  double _life = _maxLife;
  // Hue phase per segment so the trail visually pulses along its length.
  final double _phase;

  // Reused paints — avoid per-frame allocations.
  static final Paint _glowPaint = Paint();
  static final Paint _corePaint = Paint();
  static final Paint _innerPaint = Paint();

  SnakeTrailSegment({required Vector2 spawnAt, double phase = 0})
      : _phase = phase,
        super(
          position: spawnAt.clone(),
          size: Vector2(_radius * 2, _radius * 2),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    add(CircleHitbox(
      radius: _hitboxRadius,
      anchor: Anchor.center,
    )..position = size / 2);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _life -= dt;
    if (_life <= 0) {
      removeFromParent();
    }
  }

  /// Linear alpha fade in the last [_fadeWindow] seconds of life.
  double get _alpha {
    if (_life >= _fadeWindow) return 1.0;
    return (_life / _fadeWindow).clamp(0.0, 1.0);
  }

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final a = _alpha;
    if (a <= 0) return;

    // Pulse cyan↔green based on phase for trail-along visual rhythm.
    final pulse = (math.sin(_phase) * 0.5 + 0.5);
    final color = Color.lerp(
      const Color(0xFF00FFFF), // cyan
      const Color(0xFF00FF44), // neon green
      pulse,
    )!;

    // Outer glow halo.
    _glowPaint
      ..color = color.withValues(alpha: a * 0.35)
      ..maskFilter = null;
    canvas.drawCircle(Offset(cx, cy), _radius * 2.2, _glowPaint);

    // Mid ring (saturated color).
    _corePaint
      ..color = color.withValues(alpha: a * 0.8)
      ..maskFilter = null;
    canvas.drawCircle(Offset(cx, cy), _radius * 1.1, _corePaint);

    // Inner white nucleus for "lethal" pop.
    _innerPaint
      ..color = const Color(0xFFFFFFFF).withValues(alpha: a * 0.9)
      ..maskFilter = null;
    canvas.drawCircle(Offset(cx, cy), _radius * 0.45, _innerPaint);
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is EnemyBase) {
      // Spawn-invuln enemies must not be insta-killed during materialization
      // (preserves the GW2:RE materializzazione window — fair design).
      if (other.isSpawnInvulnerable) {
        super.onCollisionStart(intersectionPoints, other);
        return;
      }
      // Instant kill via massive damage so achievements / kill-count fire
      // through the standard `onDeath` path (vs. `killSilently`).
      other.takeDamage(999999);
      // Small green pop on the kill spot for visual feedback.
      game.spawnExplosion(
        other.position,
        const Color(0xFF00FF44),
        radius: 24,
        particleCount: 6,
      );
    }
    super.onCollisionStart(intersectionPoints, other);
  }
}

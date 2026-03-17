import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import '../../data/constants.dart';
import '../game_world.dart';
import 'player.dart';

class Geom extends PositionComponent
    with HasGameReference<GeometryFightGame>, CollisionCallbacks {
  final int value;
  double _lifetime = geomLifetime;
  double _phase = 0;
  bool _attracted = false;

  static final _random = math.Random();
  late Color _color;
  late double _rotationSpeed;

  Geom({this.value = 1})
      : super(size: Vector2(10, 10), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    _color = _getColorForValue(value);
    _rotationSpeed = (_random.nextDouble() - 0.5) * 5;
    add(CircleHitbox(radius: geomCollectRadius, anchor: Anchor.center, isSolid: true)
      ..position = size / 2);
  }

  Color _getColorForValue(int v) {
    if (v >= 10) return NeonColors.gold;
    if (v >= 5) return NeonColors.purple;
    if (v >= 3) return NeonColors.green;
    return NeonColors.cyan;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _phase += dt * _rotationSpeed;
    _lifetime -= dt;

    // Fade out when almost expired
    if (_lifetime <= 0) {
      removeFromParent();
      return;
    }

    // Attrazione geomi: sempre attiva con raggio base 80px
    // Power-up Magnet aumenta il raggio a 400px
    // Upgrade magnetRange aggiunge raggio extra
    final player = game.player;
    final dist = position.distanceTo(player.position);
    
    // Raggio base passivo (80px) + upgrade + power-up
    const double baseAttractionRange = 80.0;
    final upgradeRange = game.saveData.magnetRange;
    final magnetRange = player.hasMagnet ? magnetRadius : baseAttractionRange + upgradeRange;

    if (dist < magnetRange) {
      _attracted = true;
    }

    if (_attracted) {
      final dir = (player.position - position);
      if (dir.length > 0) {
        dir.normalize();
        // Velocità attrazione: più vicino = più veloce
        final attractSpeed = player.hasMagnet ? 800.0 : 400.0 + (1.0 - dist / magnetRange).clamp(0.0, 1.0) * 300;
        position += dir * attractSpeed * dt;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final alpha = _lifetime < 2 ? _lifetime / 2 : 1.0;
    final gemSize = 4.0 + value * 1.5;

    // Glow
    final glowPaint = Paint()
      ..color = _color.withValues(alpha: alpha * 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), gemSize * 1.5, glowPaint);

    // Diamond shape
    final paint = Paint()..color = _color.withValues(alpha: alpha);
    final cx = size.x / 2;
    final cy = size.y / 2;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(_phase);

    final path = Path()
      ..moveTo(0, -gemSize)
      ..lineTo(gemSize * 0.6, 0)
      ..lineTo(0, gemSize)
      ..lineTo(-gemSize * 0.6, 0)
      ..close();
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Player) {
      game.collectGeom(value);
      removeFromParent();
    }
    super.onCollisionStart(intersectionPoints, other);
  }
}

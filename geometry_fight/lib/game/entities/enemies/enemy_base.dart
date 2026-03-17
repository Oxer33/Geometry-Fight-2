import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import '../../../data/constants.dart';
import '../../game_world.dart';
import '../player.dart';

abstract class EnemyBase extends PositionComponent
    with HasGameReference<GeometryFightGame>, CollisionCallbacks {
  double hp;
  double maxHp;
  double speed;
  int pointValue;
  int geomValue;
  Color neonColor;

  double _flashTimer = 0;
  double _spawnPulse = 0.4; // Pulse ring on spawn
  double _idlePhase = 0;

  EnemyBase({
    required this.hp,
    required this.speed,
    required this.pointValue,
    required this.geomValue,
    required this.neonColor,
    Vector2? size,
  })  : maxHp = hp,
        super(size: size ?? Vector2(20, 20), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    add(CircleHitbox(radius: size.x / 2, anchor: Anchor.center)
      ..position = this.size / 2);
  }

  @override
  void update(double dt) {
    super.update(dt);

    _idlePhase += dt;
    if (_flashTimer > 0) _flashTimer -= dt;
    if (_spawnPulse > 0) _spawnPulse -= dt;

    // Clamp to arena
    position.x = position.x.clamp(5, arenaWidth - 5);
    position.y = position.y.clamp(5, arenaHeight - 5);

    updateBehavior(dt);
  }

  void updateBehavior(double dt);

  void takeDamage(double amount) {
    hp -= amount;
    _flashTimer = 0.1;

    if (hp <= 0) {
      onDeath();
    }
  }

  void onDeath() {
    game.onEnemyKilled(this);
    game.spawnExplosion(position, neonColor, radius: size.x, particleCount: 12);
    removeFromParent();
  }

  Vector2 get playerPosition => game.player.position;

  Vector2 seekPlayer(double maxSpeed) {
    final dir = (playerPosition - position);
    if (dir.length > 0) {
      dir.normalize();
      return dir * maxSpeed;
    }
    return Vector2.zero();
  }

  double get distanceToPlayer => position.distanceTo(playerPosition);

  double get idlePhase => _idlePhase;

  @override
  void render(Canvas canvas) {
    // Spawn pulse
    if (_spawnPulse > 0) {
      final radius = (1 - _spawnPulse / 0.4) * 40;
      final alpha = _spawnPulse / 0.4;
      final paint = Paint()
        ..color = neonColor.withValues(alpha: alpha * 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(Offset(size.x / 2, size.y / 2), radius, paint);
    }

    // Draw glow
    final glowPaint = Paint()
      ..color = neonColor.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    renderShape(canvas, glowPaint, 1.3);

    // Draw main shape
    final mainColor = _flashTimer > 0 ? const Color(0xFFFFFFFF) : neonColor;
    final mainPaint = Paint()..color = mainColor;
    renderShape(canvas, mainPaint, 1.0);
  }

  void renderShape(Canvas canvas, Paint paint, double scale);
}

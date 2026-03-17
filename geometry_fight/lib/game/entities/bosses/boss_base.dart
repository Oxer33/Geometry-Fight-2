import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import '../../../data/constants.dart';
import '../../game_world.dart';
import '../player.dart';

abstract class BossBase extends PositionComponent
    with HasGameReference<GeometryFightGame>, CollisionCallbacks {
  double hp;
  double maxHp;
  String bossName;
  int pointValue;
  Color neonColor;

  int currentPhase = 0;
  double _flashTimer = 0;

  BossBase({
    required this.hp,
    required this.bossName,
    required this.pointValue,
    required this.neonColor,
    Vector2? size,
  })  : maxHp = hp,
        super(size: size ?? Vector2(100, 100), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    add(CircleHitbox(radius: size.x / 2 * 0.8, anchor: Anchor.center)
      ..position = this.size / 2);
  }

  double get healthPercent => hp / maxHp;
  Vector2 get playerPosition => game.player.position;
  double get distanceToPlayer => position.distanceTo(playerPosition);

  @override
  void update(double dt) {
    super.update(dt);
    if (_flashTimer > 0) _flashTimer -= dt;

    // Determine phase
    final newPhase = getPhase();
    if (newPhase != currentPhase) {
      currentPhase = newPhase;
      onPhaseChange(currentPhase);
    }

    updateBoss(dt);

    // Clamp to arena
    position.x = position.x.clamp(50, arenaWidth - 50);
    position.y = position.y.clamp(50, arenaHeight - 50);
  }

  int getPhase();
  void onPhaseChange(int phase) {}
  void updateBoss(double dt);

  void takeDamage(double amount) {
    hp -= amount;
    _flashTimer = 0.08;
    if (hp <= 0) {
      hp = 0;
      onDeath();
    }
  }

  void onDeath() {
    game.onBossKilled(this);
    game.spawnExplosion(position, neonColor, radius: 200, particleCount: 60);
    game.triggerScreenShake(8, 0.5);
    removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    // Glow
    final glowPaint = Paint()
      ..color = neonColor.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    renderBoss(canvas, glowPaint, 1.2);

    // Main
    final color = _flashTimer > 0 ? const Color(0xFFFFFFFF) : neonColor;
    final paint = Paint()..color = color;
    renderBoss(canvas, paint, 1.0);

    // HP bar above boss
    _renderHpBar(canvas);
  }

  void _renderHpBar(Canvas canvas) {
    final barWidth = size.x * 1.2;
    final barHeight = 4.0;
    final barX = (size.x - barWidth) / 2;
    final barY = -15.0;

    // Background
    canvas.drawRect(
      Rect.fromLTWH(barX, barY, barWidth, barHeight),
      Paint()..color = const Color(0x44FFFFFF),
    );

    // HP
    final hpColor = healthPercent > 0.5
        ? NeonColors.green
        : healthPercent > 0.25
            ? NeonColors.yellow
            : NeonColors.red;
    canvas.drawRect(
      Rect.fromLTWH(barX, barY, barWidth * healthPercent, barHeight),
      Paint()..color = hpColor,
    );
  }

  void renderBoss(Canvas canvas, Paint paint, double scale);

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Player) {
      other.takeDamage();
    }
    super.onCollisionStart(intersectionPoints, other);
  }
}

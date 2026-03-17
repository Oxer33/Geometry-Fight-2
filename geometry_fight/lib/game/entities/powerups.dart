import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import '../../data/constants.dart';
import '../game_world.dart';
import 'player.dart';

enum PowerUpType {
  rapidFire,
  spreadShot,
  shield,
  magnet,
  timeSlow,
  overdrive,
  smartBomb,
  scoreMultiplier,
}

class PowerUp extends PositionComponent
    with HasGameReference<GeometryFightGame>, CollisionCallbacks {
  final PowerUpType type;
  double _lifetime = 10.0;
  double _phase = 0;
  double _pulsePhase = 0;

  PowerUp({required this.type})
      : super(size: Vector2(24, 24), anchor: Anchor.center);

  Color get color {
    switch (type) {
      case PowerUpType.rapidFire:
        return const Color(0xFFFF4400);
      case PowerUpType.spreadShot:
        return NeonColors.spreadOrange;
      case PowerUpType.shield:
        return NeonColors.cyan;
      case PowerUpType.magnet:
        return const Color(0xFFFFEE00);
      case PowerUpType.timeSlow:
        return const Color(0xFFAA00FF);
      case PowerUpType.overdrive:
        return NeonColors.white;
      case PowerUpType.smartBomb:
        return NeonColors.green;
      case PowerUpType.scoreMultiplier:
        return NeonColors.gold;
    }
  }

  @override
  Future<void> onLoad() async {
    add(CircleHitbox(radius: 15, anchor: Anchor.center)
      ..position = size / 2);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _phase += dt * 3;
    _pulsePhase += dt * 6;
    _lifetime -= dt;
    if (_lifetime <= 0) removeFromParent();
  }

  void applyTo(Player player) {
    switch (type) {
      case PowerUpType.rapidFire:
        player.rapidFireTimer = powerUpDuration;
      case PowerUpType.spreadShot:
        player.temporaryWeapon = WeaponType.spread;
        player.weaponTimer = powerUpDuration;
      case PowerUpType.shield:
        player.applyShield(player.game.saveData.shieldCapacity);
      case PowerUpType.magnet:
        player.magnetTimer = powerUpDuration;
      case PowerUpType.timeSlow:
        player.timeSlowTimer = powerUpDuration;
        player.game.timeScale = 0.4;
      case PowerUpType.overdrive:
        player.overdriveTimer = powerUpDuration;
      case PowerUpType.smartBomb:
        if (player.bombs < player.game.saveData.bombCapacity) {
          player.bombs++;
        }
      case PowerUpType.scoreMultiplier:
        player.game.scoreSystem.activateDoubleMultiplier(20);
    }
  }

  @override
  void render(Canvas canvas) {
    final alpha = _lifetime < 2 ? _lifetime / 2 : 1.0;
    final pulse = 1.0 + math.sin(_pulsePhase) * 0.15;
    final cx = size.x / 2;
    final cy = size.y / 2;

    // Glow
    final glowPaint = Paint()
      ..color = color.withValues(alpha: alpha * 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(Offset(cx, cy), 16 * pulse, glowPaint);

    // Shape (rotating)
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(_phase);

    final paint = Paint()..color = color.withValues(alpha: alpha);
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = i * math.pi / 3;
      final r = 10 * pulse;
      final x = r * math.cos(angle);
      final y = r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);

    // Inner icon hint
    paint.color = const Color(0xFFFFFFFF).withValues(alpha: alpha * 0.8);
    canvas.drawCircle(Offset.zero, 3, paint);

    canvas.restore();
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Player) {
      applyTo(other);
      removeFromParent();
    }
    super.onCollisionStart(intersectionPoints, other);
  }
}

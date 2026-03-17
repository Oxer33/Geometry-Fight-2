import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../../data/constants.dart';
import '../../../data/wave_configs.dart';
import 'boss_base.dart';
import '../projectiles.dart';

class _HydraHead {
  Vector2 position;
  double hp;
  final double maxHp;
  double attackTimer;
  bool alive;
  double deathTime;
  int attackType;

  _HydraHead({required this.position, this.hp = 150})
      : maxHp = hp,
        attackTimer = 2.0 + math.Random().nextDouble() * 2,
        alive = true,
        deathTime = 0,
        attackType = math.Random().nextInt(4);
}

class HydraBoss extends BossBase {
  final List<_HydraHead> _heads = [];
  double _ragePhase = 0;
  bool _rageMode = false;
  double _rageShootTimer = 0;

  HydraBoss()
      : super(
          hp: 800,
          bossName: 'HYDRA',
          pointValue: 8000,
          neonColor: NeonColors.green,
          size: Vector2(120, 120),
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Create 4 heads
    for (int i = 0; i < 4; i++) {
      final angle = i * math.pi / 2;
      _heads.add(_HydraHead(
        position: Vector2(math.cos(angle) * 80, math.sin(angle) * 80),
      ));
    }
  }

  @override
  int getPhase() {
    final aliveHeads = _heads.where((h) => h.alive).length;
    if (aliveHeads == 0) return 2; // Rage mode
    if (healthPercent < 0.4) return 1;
    return 0;
  }

  @override
  void onPhaseChange(int phase) {
    if (phase == 2) {
      _rageMode = true;
    }
  }

  @override
  void updateBoss(double dt) {
    _ragePhase += dt;

    // Move slowly
    final dir = (playerPosition - position);
    if (dir.length > 200) {
      position += dir.normalized() * 40 * dt;
    }

    // Update heads
    for (int i = 0; i < _heads.length; i++) {
      final head = _heads[i];
      if (!head.alive) {
        // Regen timer
        head.deathTime += dt;
        if (head.deathTime > 5) {
          head.alive = true;
          head.hp = head.maxHp;
          head.deathTime = 0;
        }
        continue;
      }

      // Animate head position (tentacle movement)
      final baseAngle = i * math.pi / 2 + _ragePhase * 0.5;
      final wobble = math.sin(_ragePhase * 2 + i * 1.5) * 15;
      head.position = Vector2(
        math.cos(baseAngle) * (80 + wobble),
        math.sin(baseAngle) * (80 + wobble),
      );

      // Attack
      head.attackTimer -= dt;
      if (head.attackTimer <= 0) {
        head.attackTimer = 2.0 + math.Random().nextDouble() * 1.5;
        _headAttack(head, i);
      }
    }

    // Check if all heads died within 3s of each other
    // (simplified: just check if all are dead)
    final deadHeads = _heads.where((h) => !h.alive).toList();
    if (deadHeads.length == 4) {
      // All dead - prevent regen, go to rage mode
      _rageMode = true;
    }

    // Rage mode
    if (_rageMode) {
      _rageShootTimer -= dt;
      if (_rageShootTimer <= 0) {
        _rageShootTimer = 0.1;
        final angle = _ragePhase * 5;
        final dir = Vector2(math.cos(angle), math.sin(angle));
        final bullet = EnemyBullet(direction: dir, speed: 300, color: NeonColors.green);
        bullet.position = position.clone();
        game.world.add(bullet);
      }
    }
  }

  void _headAttack(_HydraHead head, int index) {
    final headWorldPos = position + head.position;

    switch (head.attackType) {
      case 0: // Radial burst
        for (int i = 0; i < 8; i++) {
          final angle = i * math.pi / 4;
          final dir = Vector2(math.cos(angle), math.sin(angle));
          final bullet = EnemyBullet(direction: dir, speed: 200, color: NeonColors.green);
          bullet.position = headWorldPos.clone();
          game.world.add(bullet);
        }
      case 1: // Tracking laser-like burst
        final toPlayer = (playerPosition - headWorldPos).normalized();
        for (int i = 0; i < 5; i++) {
          final bullet = EnemyBullet(
            direction: toPlayer,
            speed: 250 + i * 30.0,
            color: NeonColors.green,
          );
          bullet.position = headWorldPos.clone();
          game.world.add(bullet);
        }
      case 2: // Spawn snakes
        for (int i = 0; i < 2; i++) {
          game.spawnEnemy(EnemyType.snake, headWorldPos + Vector2(
            (math.Random().nextDouble() - 0.5) * 40,
            (math.Random().nextDouble() - 0.5) * 40,
          ));
        }
      case 3: // Homing shot
        final toPlayer = (playerPosition - headWorldPos).normalized();
        final bullet = EnemyBullet(direction: toPlayer, speed: 350, color: NeonColors.cyan);
        bullet.position = headWorldPos.clone();
        game.world.add(bullet);
    }
  }

  @override
  void takeDamage(double amount) {
    // Check if damage hits a head
    for (final head in _heads) {
      if (!head.alive) continue;
      final headWorldPos = position + head.position;
      // Simple proximity check - any damage near a head damages it
      head.hp -= amount * 0.5;
      if (head.hp <= 0) {
        head.alive = false;
        head.deathTime = 0;
        game.spawnExplosion(headWorldPos, NeonColors.green, radius: 30);
      }
    }

    super.takeDamage(amount);
  }

  @override
  void renderBoss(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;

    // Draw tentacles and heads
    for (int i = 0; i < _heads.length; i++) {
      final head = _heads[i];
      if (!head.alive) continue;

      // Tentacle (bezier curve)
      final tentaclePaint = Paint()
        ..color = neonColor.withValues(alpha: paint.color.a)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 * scale;

      final startPoint = Offset(cx, cy);
      final endPoint = Offset(cx + head.position.x, cy + head.position.y);
      final controlPoint = Offset(
        (startPoint.dx + endPoint.dx) / 2 +
            math.sin(_ragePhase * 3 + i) * 20,
        (startPoint.dy + endPoint.dy) / 2 +
            math.cos(_ragePhase * 3 + i) * 20,
      );

      final path = Path()
        ..moveTo(startPoint.dx, startPoint.dy)
        ..quadraticBezierTo(
            controlPoint.dx, controlPoint.dy, endPoint.dx, endPoint.dy);
      canvas.drawPath(path, tentaclePaint);

      // Head
      canvas.drawCircle(endPoint, 12 * scale, paint);
    }

    // Core
    canvas.drawCircle(Offset(cx, cy), 25 * scale, paint);

    // Rage indicator
    if (_rageMode) {
      final ragePaint = Paint()
        ..color = NeonColors.red.withValues(alpha: 0.3 + math.sin(_ragePhase * 8) * 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
      canvas.drawCircle(Offset(cx, cy), 35 * scale, ragePaint);
    }
  }
}

import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../../data/constants.dart';
import '../../../data/wave_configs.dart';
import 'boss_base.dart';
import '../projectiles.dart';

/// NEW BOSS: The Architect - builds geometric structures that attack
class TheArchitectBoss extends BossBase {
  double _buildTimer = 3;
  double _phase = 0;
  final List<_Structure> _structures = [];
  double _wallAttackTimer = 6;

  TheArchitectBoss()
      : super(
          hp: 1500,
          bossName: 'THE ARCHITECT',
          pointValue: 15000,
          neonColor: NeonColors.electricBlue,
          size: Vector2(160, 160),
        );

  @override
  int getPhase() {
    if (healthPercent > 0.6) return 0;
    if (healthPercent > 0.3) return 1;
    return 2;
  }

  @override
  void updateBoss(double dt) {
    _phase += dt;

    // Orbital movement around arena center
    final centerX = arenaWidth / 2;
    final centerY = arenaHeight / 2;
    final orbitRadius = 300.0 - currentPhase * 50;
    position = Vector2(
      centerX + math.cos(_phase * 0.5) * orbitRadius,
      centerY + math.sin(_phase * 0.5) * orbitRadius,
    );

    // Build structures
    _buildTimer -= dt;
    if (_buildTimer <= 0) {
      _buildTimer = 3.0 - currentPhase * 0.8;
      _buildStructure();
    }

    // Update structures
    for (final structure in _structures.toList()) {
      structure.lifetime -= dt;
      structure.attackTimer -= dt;

      if (structure.lifetime <= 0) {
        _structures.remove(structure);
        continue;
      }

      // Structures shoot at player
      if (structure.attackTimer <= 0) {
        structure.attackTimer = 1.5;
        final dir = (playerPosition - structure.position).normalized();
        final bullet = EnemyBullet(
            direction: dir, speed: 220, color: NeonColors.electricBlue);
        bullet.position = structure.position.clone();
        game.world.add(bullet);
      }
    }

    // Wall attack (phase 1+)
    if (currentPhase >= 1) {
      _wallAttackTimer -= dt;
      if (_wallAttackTimer <= 0) {
        _wallAttackTimer = 6.0;
        _wallAttack();
      }
    }

    // Phase 2: Structures shoot faster and boss shoots too
    if (currentPhase >= 2) {
      if ((_phase * 5).floor() % 3 == 0 && (_phase * 5) % 1 < dt * 6) {
        final dir = (playerPosition - position).normalized();
        final bullet = EnemyBullet(
            direction: dir, speed: 280, color: NeonColors.white);
        bullet.position = position.clone();
        game.world.add(bullet);
      }
    }
  }

  void _buildStructure() {
    final angle = math.Random().nextDouble() * math.pi * 2;
    final dist = 150 + math.Random().nextDouble() * 200;
    final pos = position + Vector2(math.cos(angle) * dist, math.sin(angle) * dist);

    _structures.add(_Structure(
      position: pos,
      lifetime: 10.0 + currentPhase * 5,
      attackTimer: 1.5,
    ));

    // Spawn a mine near the structure
    if (currentPhase >= 1) {
      game.spawnEnemy(EnemyType.mine, pos + Vector2(30, 0));
    }
  }

  void _wallAttack() {
    // Create a wall of bullets
    final horizontal = math.Random().nextBool();
    for (int i = 0; i < 15; i++) {
      Vector2 bulletPos;
      Vector2 bulletDir;
      if (horizontal) {
        bulletPos = Vector2(
          playerPosition.x - 400 + i * 53,
          playerPosition.y - 500,
        );
        bulletDir = Vector2(0, 1);
      } else {
        bulletPos = Vector2(
          playerPosition.x - 500,
          playerPosition.y - 400 + i * 53,
        );
        bulletDir = Vector2(1, 0);
      }

      // Leave gaps
      if (i == 5 || i == 9) continue;

      final bullet = EnemyBullet(
          direction: bulletDir, speed: 200, color: NeonColors.electricBlue);
      bullet.position = bulletPos;
      game.world.add(bullet);
    }
  }

  @override
  void renderBoss(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;

    // Main body - geometric construction
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(_phase * 0.3);

    // Outer square
    final r = 65 * scale;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 3;
    canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: r * 2, height: r * 2),
        paint);

    // Inner rotated square
    canvas.rotate(math.pi / 4);
    canvas.drawRect(
        Rect.fromCenter(
            center: Offset.zero, width: r * 1.4, height: r * 1.4),
        paint);

    // Central circle
    paint.style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, 20 * scale, paint);

    canvas.restore();

    // Draw structures
    for (final structure in _structures) {
      final sPos = structure.position - position;
      final sPaint = Paint()
        ..color = NeonColors.electricBlue
            .withValues(alpha: structure.lifetime / 15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      // Small hexagon
      final path = Path();
      for (int i = 0; i < 6; i++) {
        final angle = i * math.pi / 3;
        final x = cx + sPos.x + 10 * math.cos(angle);
        final y = cy + sPos.y + 10 * math.sin(angle);
        if (i == 0) path.moveTo(x, y);
        else path.lineTo(x, y);
      }
      path.close();
      canvas.drawPath(path, sPaint);
    }
  }
}

class _Structure {
  final Vector2 position;
  double lifetime;
  double attackTimer;

  _Structure({
    required this.position,
    required this.lifetime,
    required this.attackTimer,
  });
}

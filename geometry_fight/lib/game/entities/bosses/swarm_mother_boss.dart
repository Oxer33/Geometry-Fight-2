import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../../data/constants.dart';
import '../../../data/wave_configs.dart';
import 'boss_base.dart';
import '../projectiles.dart';

class SwarmMotherBoss extends BossBase {
  double _spawnTimer = 3;
  double _laserAngle = 0;
  bool _laserActive = false;
  double _laserTimer = 0;
  double _phase = 0;
  bool _split = false;
  Vector2? _halfOffset;

  SwarmMotherBoss()
      : super(
          hp: 2000,
          bossName: 'THE SWARM MOTHER',
          pointValue: 20000,
          neonColor: NeonColors.orange,
          size: Vector2(180, 180),
        );

  @override
  int getPhase() {
    if (healthPercent > 0.7) return 0;
    if (healthPercent > 0.4) return 1;
    if (healthPercent > 0.2) return 2;
    return 3;
  }

  @override
  void onPhaseChange(int phase) {
    if (phase == 1) _split = true;
    if (phase == 2) _split = false;
    if (phase == 3) {
      // Berserk - spawn black hole
      game.spawnEnemy(EnemyType.blackHole, Vector2(arenaWidth / 2, arenaHeight / 2));
    }
  }

  @override
  void updateBoss(double dt) {
    _phase += dt;

    final speed = currentPhase == 3 ? 180.0 : 60.0;
    final dir = (playerPosition - position);
    if (dir.length > 150) {
      position += dir.normalized() * speed * dt;
    }

    // Split movement
    if (_split) {
      _halfOffset = Vector2(math.sin(_phase * 2) * 100, math.cos(_phase * 2) * 100);
    } else {
      _halfOffset = null;
    }

    // Spawn enemies
    _spawnTimer -= dt;
    if (_spawnTimer <= 0) {
      switch (currentPhase) {
        case 0:
          _spawnTimer = 3;
          for (int i = 0; i < 20; i++) {
            game.spawnEnemy(EnemyType.drone, position + Vector2(
              (math.Random().nextDouble() - 0.5) * 200,
              (math.Random().nextDouble() - 0.5) * 200,
            ));
          }
        case 1:
          _spawnTimer = 2.5;
          for (int i = 0; i < 10; i++) {
            game.spawnEnemy(EnemyType.drone, position + Vector2(
              (math.Random().nextDouble() - 0.5) * 150,
              (math.Random().nextDouble() - 0.5) * 150,
            ));
          }
        case 2:
          _spawnTimer = 2;
          game.spawnEnemy(EnemyType.splitter, position + Vector2(50, 0));
          game.spawnEnemy(EnemyType.kamikaze, position + Vector2(-50, 0));
          game.spawnEnemy(EnemyType.kamikaze, position + Vector2(0, 50));
        case 3:
          _spawnTimer = 1.5;
          for (int i = 0; i < 5; i++) {
            game.spawnEnemy(EnemyType.kamikaze, position + Vector2(
              (math.Random().nextDouble() - 0.5) * 100,
              (math.Random().nextDouble() - 0.5) * 100,
            ));
          }
      }
    }

    // Laser sweep (phase 2+)
    if (currentPhase >= 2) {
      if (!_laserActive && (_phase % 8) < dt * 2) {
        _laserActive = true;
        _laserTimer = 3.0;
        _laserAngle = math.atan2(
            playerPosition.y - position.y, playerPosition.x - position.x);
      }

      if (_laserActive) {
        _laserAngle += dt * math.pi * 2 / 3;
        _laserTimer -= dt;
        if (_laserTimer <= 0) _laserActive = false;

        // Damage player
        final laserDir = Vector2(math.cos(_laserAngle), math.sin(_laserAngle));
        final toPlayer = playerPosition - position;
        final dot = toPlayer.dot(laserDir);
        if (dot > 0) {
          final perpDist = (toPlayer - laserDir * dot).length;
          if (perpDist < 20) {
            game.player.takeDamage();
          }
        }
      }
    }
  }

  @override
  void renderBoss(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;

    if (_split && _halfOffset != null) {
      // Draw two halves
      _drawHalf(canvas, paint, scale, Offset(cx + _halfOffset!.x / 2, cy + _halfOffset!.y / 2));
      _drawHalf(canvas, paint, scale, Offset(cx - _halfOffset!.x / 2, cy - _halfOffset!.y / 2));
    } else {
      _drawHexagon(canvas, paint, scale, Offset(cx, cy));
    }

    // Berserk glow
    if (currentPhase == 3) {
      final berserkPaint = Paint()
        ..color = NeonColors.red.withValues(alpha: 0.3 + math.sin(_phase * 10) * 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25);
      canvas.drawCircle(Offset(cx, cy), 100 * scale, berserkPaint);
    }

    // Laser
    if (_laserActive) {
      final laserPaint = Paint()
        ..color = NeonColors.laserRed.withValues(alpha: 0.7)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(_laserAngle);
      canvas.drawRect(Rect.fromLTWH(0, -3, 1500, 6), laserPaint);
      canvas.restore();
    }
  }

  void _drawHalf(Canvas canvas, Paint paint, double scale, Offset center) {
    final r = 60 * scale;
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = i * math.pi / 3 + _phase * 0.3;
      final irregularity = 1.0 + math.sin(i * 1.5 + _phase) * 0.15;
      final x = center.dx + r * irregularity * math.cos(angle);
      final y = center.dy + r * irregularity * math.sin(angle);
      if (i == 0) path.moveTo(x, y);
      else path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawHexagon(Canvas canvas, Paint paint, double scale, Offset center) {
    final r = 80 * scale;
    final path = Path();

    // Membrane pulsation
    for (int i = 0; i < 8; i++) {
      final angle = i * math.pi / 4 + _phase * 0.2;
      final irregularity = 1.0 + math.sin(i * 2.0 + _phase * 2) * 0.1;
      final x = center.dx + r * irregularity * math.cos(angle);
      final y = center.dy + r * irregularity * math.sin(angle);
      if (i == 0) path.moveTo(x, y);
      else path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paint);
  }
}

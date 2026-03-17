import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../../data/constants.dart';
import '../../../data/wave_configs.dart';
import 'boss_base.dart';
import '../projectiles.dart';

class SingularityBoss extends BossBase {
  double _pulseTimer = 3;
  double _pullTimer = 5;
  double _cloneTimer = 8;
  double _vortexTimer = 12;
  bool _pulling = false;
  double _pullDuration = 0;
  double _phase = 0;
  final List<Vector2> _vortexPositions = [];
  double _vortexAngle = 0;

  SingularityBoss()
      : super(
          hp: 1200,
          bossName: 'SINGULARITY',
          pointValue: 12000,
          neonColor: NeonColors.green,
          size: Vector2(140, 140),
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

    // Slow movement
    final dir = (playerPosition - position);
    if (dir.length > 300) {
      position += dir.normalized() * 50 * dt;
    }

    // Pulse attack
    _pulseTimer -= dt;
    if (_pulseTimer <= 0) {
      _pulseTimer = 3.0 - currentPhase * 0.5;
      _doPulse();
    }

    // Pull attack
    _pullTimer -= dt;
    if (_pullTimer <= 0 && !_pulling) {
      _pulling = true;
      _pullDuration = 2.0;
      _pullTimer = 5.0;
    }

    if (_pulling) {
      // Pull player towards boss
      final pullDir = (position - playerPosition);
      if (pullDir.length > 0) {
        game.player.position += pullDir.normalized() * 150 * dt;
      }
      _pullDuration -= dt;
      if (_pullDuration <= 0) _pulling = false;
    }

    // Clone attack (phase 1+)
    if (currentPhase >= 1) {
      _cloneTimer -= dt;
      if (_cloneTimer <= 0) {
        _cloneTimer = 8.0;
        _spawnClones();
      }
    }

    // Vortex (phase 2)
    if (currentPhase >= 2) {
      _vortexTimer -= dt;
      if (_vortexTimer <= 0) {
        _vortexTimer = 12.0;
        _createVortex();
      }

      // Rotate vortex positions
      _vortexAngle += dt * 0.5;
    }

    // Black rain (phase 2, periodic)
    if (currentPhase >= 2 && (_phase % 4).floor() == 0 && _phase % 4 < dt * 2) {
      _blackRain();
    }
  }

  void _doPulse() {
    // Push wave
    for (int i = 0; i < 16; i++) {
      final angle = i * math.pi * 2 / 16;
      final dir = Vector2(math.cos(angle), math.sin(angle));
      final bullet = EnemyBullet(direction: dir, speed: 200, color: NeonColors.green);
      bullet.position = position.clone();
      game.world.add(bullet);
    }
  }

  void _spawnClones() {
    for (int i = 0; i < 2; i++) {
      final offset = Vector2(
        (math.Random().nextDouble() - 0.5) * 400,
        (math.Random().nextDouble() - 0.5) * 400,
      );
      // Spawn a weak drone that looks like the boss (simplified as special drone)
      game.spawnEnemy(EnemyType.drone, position + offset);
    }
  }

  void _createVortex() {
    _vortexPositions.clear();
    for (int i = 0; i < 4; i++) {
      final angle = i * math.pi / 2;
      _vortexPositions.add(Vector2(math.cos(angle) * 200, math.sin(angle) * 200));
    }
    // Spawn black holes
    for (final vPos in _vortexPositions) {
      game.spawnEnemy(EnemyType.blackHole, position + vPos);
    }
  }

  void _blackRain() {
    for (int i = 0; i < 5; i++) {
      final x = playerPosition.x + (math.Random().nextDouble() - 0.5) * 400;
      final bullet = EnemyBullet(
        direction: Vector2(0, 1),
        speed: 300,
        color: NeonColors.darkRed,
      );
      bullet.position = Vector2(x, playerPosition.y - 500);
      game.world.add(bullet);
    }
  }

  @override
  void renderBoss(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final r = 55 * scale;

    // Dark sphere
    final darkPaint = Paint()..color = const Color(0xFF111111);
    canvas.drawCircle(Offset(cx, cy), r, darkPaint);

    // Green radioactive glow
    final glowIntensity = 0.3 + math.sin(_phase * 2) * 0.1;
    final greenGlow = Paint()
      ..color = NeonColors.green.withValues(alpha: glowIntensity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawCircle(Offset(cx, cy), r * 1.3, greenGlow);

    // Edge ring
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 3 * scale;
    canvas.drawCircle(Offset(cx, cy), r, paint);

    // Pull indicator
    if (_pulling) {
      final pullPaint = Paint()
        ..color = NeonColors.purple.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      for (int ring = 0; ring < 3; ring++) {
        final ringR = r + 20 + ring * 30 + (_pullDuration * 50);
        pullPaint.color = NeonColors.purple.withValues(alpha: 0.3 - ring * 0.1);
        canvas.drawCircle(Offset(cx, cy), ringR, pullPaint);
      }
    }

    paint.style = PaintingStyle.fill;
  }
}

import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../../data/constants.dart';
import 'boss_base.dart';
import '../projectiles.dart';

/// NEW BOSS: Chrono Wraith - manipulates time, teleports, creates afterimages
class ChronoWraithBoss extends BossBase {
  double _phase = 0;
  double _teleportTimer = 4;
  double _afterimageTimer = 0.3;
  double _timeWarpTimer = 8;
  double _shootTimer = 0.5;
  final List<_Afterimage> _afterimages = [];
  bool _timeWarping = false;
  double _timeWarpDuration = 0;

  ChronoWraithBoss()
      : super(
          hp: 1800,
          bossName: 'CHRONO WRAITH',
          pointValue: 18000,
          neonColor: NeonColors.deepPurple,
          size: Vector2(130, 130),
        );

  @override
  int getPhase() {
    if (healthPercent > 0.65) return 0;
    if (healthPercent > 0.35) return 1;
    return 2;
  }

  @override
  void updateBoss(double dt) {
    _phase += dt;

    // Movement - drift and teleport
    final dir = (playerPosition - position);
    if (dir.length > 200) {
      position += dir.normalized() * 100 * dt;
    }

    // Teleport
    _teleportTimer -= dt;
    if (_teleportTimer <= 0) {
      _teleportTimer = 4.0 - currentPhase;
      _teleport();
    }

    // Afterimages
    _afterimageTimer -= dt;
    if (_afterimageTimer <= 0) {
      _afterimageTimer = 0.15;
      _afterimages.add(_Afterimage(
        position: position.clone(),
        lifetime: 1.0,
        opacity: 0.6,
      ));
    }

    // Update afterimages
    for (final ai in _afterimages.toList()) {
      ai.lifetime -= dt;
      ai.opacity = ai.lifetime;
      if (ai.lifetime <= 0) _afterimages.remove(ai);
    }

    // Shoot
    _shootTimer -= dt;
    if (_shootTimer <= 0) {
      _shootTimer = 0.5 - currentPhase * 0.1;
      _shoot();
    }

    // Time warp attack
    _timeWarpTimer -= dt;
    if (_timeWarpTimer <= 0 && !_timeWarping) {
      _timeWarping = true;
      _timeWarpDuration = 3.0;
      _timeWarpTimer = 8.0;
      // Slow everything except boss
      game.timeScale = 0.3;
    }

    if (_timeWarping) {
      _timeWarpDuration -= dt;
      if (_timeWarpDuration <= 0) {
        _timeWarping = false;
        game.timeScale = 1.0;
      }

      // During time warp, spawn extra bullets
      if ((_phase * 8).floor() % 2 == 0) {
        for (int i = 0; i < 6; i++) {
          final angle = i * math.pi / 3 + _phase * 2;
          final bulletDir = Vector2(math.cos(angle), math.sin(angle));
          final bullet = EnemyBullet(
              direction: bulletDir, speed: 350, color: NeonColors.deepPurple);
          bullet.position = position.clone();
          game.world.add(bullet);
        }
      }
    }

    // Phase 2: Afterimages also shoot
    if (currentPhase >= 2) {
      for (final ai in _afterimages) {
        if (ai.lifetime > 0.8) {
          final toPlayer = (playerPosition - ai.position).normalized();
          final bullet = EnemyBullet(
              direction: toPlayer,
              speed: 200,
              color: NeonColors.deepPurple.withValues(alpha: 0.5));
          bullet.position = ai.position.clone();
          game.world.add(bullet);
          ai.lifetime = 0.5; // Prevent shooting again
        }
      }
    }
  }

  void _teleport() {
    // Teleport behind the player
    final behind = playerPosition +
        (playerPosition - position).normalized() * -200;
    position = Vector2(
      behind.x.clamp(100, arenaWidth - 100),
      behind.y.clamp(100, arenaHeight - 100),
    );

    game.spawnExplosion(position, NeonColors.deepPurple, radius: 40, particleCount: 15);
  }

  void _shoot() {
    final toPlayer = (playerPosition - position).normalized();

    // Predictive shooting - aim where player will be
    final playerVel = game.moveInput * playerSpeed;
    final timeToReach = position.distanceTo(playerPosition) / 300;
    final predictedPos = playerPosition + playerVel * timeToReach;
    final predictedDir = (predictedPos - position).normalized();

    final bullet = EnemyBullet(
        direction: predictedDir, speed: 300, color: NeonColors.deepPurple);
    bullet.position = position.clone();
    game.world.add(bullet);

    // Spread shots in phase 1+
    if (currentPhase >= 1) {
      for (final offset in [-0.3, 0.3]) {
        final angle = math.atan2(predictedDir.y, predictedDir.x) + offset;
        final spreadDir = Vector2(math.cos(angle), math.sin(angle));
        final spreadBullet = EnemyBullet(
            direction: spreadDir, speed: 280, color: NeonColors.purple);
        spreadBullet.position = position.clone();
        game.world.add(spreadBullet);
      }
    }
  }

  @override
  void renderBoss(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;

    // Draw afterimages
    for (final ai in _afterimages) {
      final offset = ai.position - position;
      final aiPaint = Paint()
        ..color = neonColor.withValues(alpha: ai.opacity * 0.3);
      _drawWraithShape(
          canvas, aiPaint, scale * 0.9, Offset(cx + offset.x, cy + offset.y));
    }

    // Main body
    _drawWraithShape(canvas, paint, scale, Offset(cx, cy));

    // Time warp visual
    if (_timeWarping) {
      final warpPaint = Paint()
        ..color = NeonColors.deepPurple.withValues(alpha: 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);
      canvas.drawCircle(Offset(cx, cy), 100 * scale, warpPaint);

      // Clock-like rotating arcs
      final arcPaint = Paint()
        ..color = NeonColors.white.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(_phase * 3);
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: 80 * scale),
        0,
        math.pi / 3,
        false,
        arcPaint,
      );
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: 80 * scale),
        math.pi,
        math.pi / 3,
        false,
        arcPaint,
      );
      canvas.restore();
    }
  }

  void _drawWraithShape(
      Canvas canvas, Paint paint, double scale, Offset center) {
    final r = 50 * scale;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(_phase * 0.8);

    // Ghostly shape with flowing edges
    final path = Path();
    for (int i = 0; i < 12; i++) {
      final angle = i * math.pi * 2 / 12;
      final wobble = math.sin(_phase * 4 + i * 1.2) * 8;
      final x = (r + wobble) * math.cos(angle);
      final y = (r + wobble) * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);

    // Inner eye-like structure
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2 * scale;
    canvas.drawCircle(Offset.zero, r * 0.4, paint);

    // Dot in center
    paint.style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, 5 * scale, paint);

    canvas.restore();
  }
}

class _Afterimage {
  final Vector2 position;
  double lifetime;
  double opacity;

  _Afterimage({
    required this.position,
    required this.lifetime,
    required this.opacity,
  });
}

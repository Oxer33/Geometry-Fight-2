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
  double _warpShotTimer = 0;

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
      _shootTimer = (0.5 - currentPhase * 0.1).clamp(0.1, 0.5); // FIX C9c: evita timer negativo/zero
      _shoot();
    }

    // Time warp attack
    _timeWarpTimer -= dt;
    if (_timeWarpTimer <= 0 && !_timeWarping) {
      _timeWarping = true;
      _timeWarpDuration = 3.0;
      _timeWarpTimer = 8.0;
      _warpShotTimer = 0;
      // Slow everything except boss
      game.timeScale = 0.3;
    }

    if (_timeWarping) {
      _timeWarpDuration -= dt;
      if (_timeWarpDuration <= 0) {
        _timeWarping = false;
        if (game.slowMoTimer <= 0) {
          game.timeScale = game.player.timeSlowTimer > 0 ? 0.4 : 1.0;
        }
      }

      // During time warp, spawn extra bullets at fixed cadence (no frame-rate spam).
      _warpShotTimer -= dt;
      if (_warpShotTimer <= 0) {
        _warpShotTimer = (0.22 - currentPhase * 0.03).clamp(0.12, 0.22);
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

  @override
  void onDeath() {
    // Ripristina timeScale se il boss muore durante time warp
    if (_timeWarping) {
      if (game.slowMoTimer <= 0) {
        game.timeScale = game.player.timeSlowTimer > 0 ? 0.4 : 1.0;
      }
    }
    super.onDeath();
  }

  @override
  void onRemove() {
    // FIX C9b: Ripristina timeScale se il boss viene rimosso per qualsiasi ragione
    if (game.timeScale < 1.0 && game.slowMoTimer <= 0) {
      game.timeScale = 1.0;
    }
    super.onRemove();
  }

  void _teleport() {
    // Teleport behind the player
    final behind = playerPosition +
        (playerPosition - position).normalized() * -200;
    if (game.isTunnelMode) {
      final cam = game.camera.viewfinder.position;
      final halfW = game.size.x > 0 ? game.size.x / 2 : 400.0;
      final halfH = game.size.y > 0 ? game.size.y / 2 : 300.0;
      position = Vector2(
        behind.x.clamp(cam.x - halfW + 50, cam.x + halfW - 50),
        behind.y.clamp(cam.y - halfH + 50, cam.y + halfH - 50),
      );
    } else {
      position = Vector2(
        behind.x.clamp(100, arenaWidth - 100),
        behind.y.clamp(100, arenaHeight - 100),
      );
    }

    game.spawnExplosion(position, NeonColors.deepPurple, radius: 40, particleCount: 15);
  }

  void _shoot() {
    // Predictive shooting - aim where player will be
    final playerVel = game.moveInput * playerSpeed;
    final timeToReach = position.distanceTo(playerPosition) / 300;
    final predictedPos = playerPosition + playerVel * timeToReach;
    final aimDir = predictedPos - position;
    if (aimDir.length < 1) return; // FIX C9a: evita NaN se player == boss position
    final predictedDir = aimDir.normalized();

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

  static final _aiPaint = Paint();
  static final _warpPaint = Paint();
  static final _arcPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  // Signature FX paints
  static final _clockTickPaint = Paint()..style = PaintingStyle.stroke;
  static final _clockHandPaint = Paint()..style = PaintingStyle.stroke;
  static final _irisPaint = Paint();
  static final _pupilPaint = Paint();
  static final _warpSpiralPaint = Paint()..style = PaintingStyle.stroke;
  static final _teleportRingPaint = Paint()..style = PaintingStyle.stroke;

  @override
  void renderBoss(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;

    // ─── PRE-TELEPORT RING (appare 0.5s prima del teleport) ───
    if (scale <= 1.01 && _teleportTimer < 0.5 && _teleportTimer > 0) {
      final warnT = 1.0 - _teleportTimer.clamp(0.0, 0.5) / 0.5;
      _teleportRingPaint.color =
          NeonColors.deepPurple.withValues(alpha: warnT * 0.7);
      _teleportRingPaint.strokeWidth = 2 + warnT * 3;
      canvas.drawCircle(Offset(cx, cy), 70 * scale * (1.0 - warnT * 0.3),
          _teleportRingPaint);
    }

    // Afterimages
    for (final ai in _afterimages) {
      final offset = ai.position - position;
      _aiPaint.color = neonColor.withValues(alpha: ai.opacity * 0.3);
      _drawWraithShape(
          canvas, _aiPaint, scale * 0.9, Offset(cx + offset.x, cy + offset.y),
          drawClockface: false);
    }

    // Corpo principale con clockface
    _drawWraithShape(canvas, paint, scale, Offset(cx, cy),
        drawClockface: scale <= 1.01);

    // ─── TIME WARP: vortex viola + spirale rotante ───
    if (_timeWarping) {
      _warpPaint.color = NeonColors.deepPurple.withValues(alpha: 0.1);
      canvas.drawCircle(Offset(cx, cy), 130 * scale, _warpPaint);
      _warpPaint.color = NeonColors.deepPurple.withValues(alpha: 0.15);
      canvas.drawCircle(Offset(cx, cy), 100 * scale, _warpPaint);

      // Spirale 2-arm che risucchia
      _warpSpiralPaint.color = const Color(0xFFFFFFFF).withValues(alpha: 0.45);
      _warpSpiralPaint.strokeWidth = 1.3;
      canvas.save();
      canvas.translate(cx, cy);
      for (int arm = 0; arm < 2; arm++) {
        final spiralPath = Path();
        const segs = 18;
        for (int s = 0; s <= segs; s++) {
          final t = s / segs;
          final sR = 20 + t * 100 * scale;
          final sA = arm * math.pi + t * math.pi * 2.5 + _phase * 3;
          final sx = math.cos(sA) * sR;
          final sy = math.sin(sA) * sR;
          if (s == 0) {
            spiralPath.moveTo(sx, sy);
          } else {
            spiralPath.lineTo(sx, sy);
          }
        }
        canvas.drawPath(spiralPath, _warpSpiralPaint);
      }
      canvas.restore();

      // Clock-hand rotanti veloci
      _arcPaint.color = NeonColors.white.withValues(alpha: 0.4);
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(_phase * 3);
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: 80 * scale),
        0, math.pi / 3, false, _arcPaint,
      );
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: 80 * scale),
        math.pi, math.pi / 3, false, _arcPaint,
      );
      canvas.restore();
    }
  }

  void _drawWraithShape(
      Canvas canvas, Paint paint, double scale, Offset center,
      {bool drawClockface = false}) {
    final r = 50 * scale;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(_phase * 0.8);

    // Corpo spettrale con bordi fluttuanti
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

    // Inner stroke ring
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2 * scale;
    canvas.drawCircle(Offset.zero, r * 0.4, paint);

    // ─── CLOCKFACE (12 tick) + lancette — signature FX ───
    if (drawClockface) {
      _clockTickPaint.color = NeonColors.white.withValues(alpha: 0.55);
      _clockTickPaint.strokeWidth = 1.5 * scale;
      for (int t = 0; t < 12; t++) {
        final tAng = t * math.pi / 6;
        final inner = r * 0.7;
        final outer = r * (t % 3 == 0 ? 0.88 : 0.82);
        canvas.drawLine(
          Offset(math.cos(tAng) * inner, math.sin(tAng) * inner),
          Offset(math.cos(tAng) * outer, math.sin(tAng) * outer),
          _clockTickPaint,
        );
      }
      // Lancetta minuti (rotazione veloce)
      _clockHandPaint.color = NeonColors.white.withValues(alpha: 0.85);
      _clockHandPaint.strokeWidth = 2 * scale;
      final minAng = _phase * 1.3;
      canvas.drawLine(
        Offset.zero,
        Offset(math.cos(minAng) * r * 0.55, math.sin(minAng) * r * 0.55),
        _clockHandPaint,
      );
      // Lancetta ore (lenta)
      _clockHandPaint.color = NeonColors.deepPurple.withValues(alpha: 0.85);
      _clockHandPaint.strokeWidth = 2.5 * scale;
      final hourAng = _phase * 0.3;
      canvas.drawLine(
        Offset.zero,
        Offset(math.cos(hourAng) * r * 0.35, math.sin(hourAng) * r * 0.35),
        _clockHandPaint,
      );
    }

    // ─── IRIS + pupilla bianca pulsante ───
    paint.style = PaintingStyle.fill;
    if (drawClockface) {
      final irisPulse = 0.6 + math.sin(_phase * 5) * 0.4;
      _irisPaint.color =
          const Color(0xFF6611AA).withValues(alpha: irisPulse);
      canvas.drawCircle(Offset.zero, 8 * scale * irisPulse, _irisPaint);
      _pupilPaint.color =
          const Color(0xFFFFFFFF).withValues(alpha: irisPulse);
      canvas.drawCircle(Offset.zero, 3.5 * scale, _pupilPaint);
    } else {
      canvas.drawCircle(Offset.zero, 5 * scale, paint);
    }

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

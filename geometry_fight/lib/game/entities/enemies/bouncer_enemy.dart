import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../../data/constants.dart';
import 'enemy_base.dart';

/// BOUNCER → WANDERER (Pinwheel) - come Geometry Wars originale.
/// Random walk, rimbalza sui muri, NON insegue il player.
/// Pericoloso solo perché imprevedibile e numeroso.
class BouncerEnemy extends EnemyBase {
  double _dirChangeTimer = 0;
  late double _moveAngle;

  BouncerEnemy()
      : super(
          hp: 1,
          speed: 45, // GW Wanderer: 35-50 px/s
          pointValue: 1,
          geomValue: 1,
          neonColor: NeonColors.purple, // Viola come GW Wanderer
          size: Vector2(16, 16),
        ) {
    _moveAngle = math.Random().nextDouble() * math.pi * 2;
    _dirChangeTimer = 1.5 + math.Random().nextDouble() * 1.5;
  }

  @override
  void updateBehavior(double dt) {
    _dirChangeTimer -= dt;

    if (_dirChangeTimer <= 0) {
      // Cambio direzione con pesi GW: 0°:35%, ±45°:30%, ±90°:5%
      _dirChangeTimer = 1.5 + math.Random().nextDouble() * 1.5;
      final r = math.Random().nextDouble();
      double angleChange;
      if (r < 0.05) {
        angleChange = -math.pi / 2;
      } else if (r < 0.35) {
        angleChange = -math.pi / 4;
      } else if (r < 0.70) {
        angleChange = 0;
      } else if (r < 0.95) {
        angleChange = math.pi / 4;
      } else {
        angleChange = math.pi / 2;
      }
      _moveAngle += angleChange;
    }

    // Movimento nella direzione corrente
    position.x += math.cos(_moveAngle) * speed * dt;
    position.y += math.sin(_moveAngle) * speed * dt;

    // Rimbalzo sui muri (reflection)
    if (game.isTunnelMode) {
      // Tunnel mode: solo rimbalzo Y (basato su tunnelHeight), niente X
      final camY = game.camera.viewfinder.position.y;
      final halfH = game.tunnelHeight / 2;
      final minY = camY - halfH + 10;
      final maxY = camY + halfH - 10;
      if (position.y <= minY) {
        _moveAngle = -_moveAngle;
        position.y = minY;
      } else if (position.y >= maxY) {
        _moveAngle = -_moveAngle;
        position.y = maxY;
      }
    } else {
      if (position.x <= 10) {
        _moveAngle = math.pi - _moveAngle;
        position.x = 10;
      } else if (position.x >= arenaWidth - 10) {
        _moveAngle = math.pi - _moveAngle;
        position.x = arenaWidth - 10;
      }
      if (position.y <= 10) {
        _moveAngle = -_moveAngle;
        position.y = 10;
      } else if (position.y >= arenaHeight - 10) {
        _moveAngle = -_moveAngle;
        position.y = arenaHeight - 10;
      }
    }
  }

  @override
  void renderShape(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final r = 8 * scale;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(idlePhase * 3.14);

    // Stella a 4 punte esterna (pinwheel)
    final path = Path();
    for (int i = 0; i < 4; i++) {
      final angle = i * math.pi / 2;
      final outerX = r * math.cos(angle);
      final outerY = r * math.sin(angle);
      final innerAngle = angle + math.pi / 4;
      final innerX = r * 0.35 * math.cos(innerAngle);
      final innerY = r * 0.35 * math.sin(innerAngle);

      if (i == 0) {
        path.moveTo(outerX, outerY);
      } else {
        path.lineTo(outerX, outerY);
      }
      path.lineTo(innerX, innerY);
    }
    path.close();
    canvas.drawPath(path, paint);

    if (scale <= 1.01) {
      // Seconda stella interna contro-rotante (ruota il doppio in senso opposto)
      final innerStarPath = Path();
      for (int i = 0; i < 4; i++) {
        final angle = i * math.pi / 2 + math.pi / 4; // Sfasata 45°
        final outerX = r * 0.5 * math.cos(angle);
        final outerY = r * 0.5 * math.sin(angle);
        final innerAngle = angle + math.pi / 4;
        final innerX = r * 0.2 * math.cos(innerAngle);
        final innerY = r * 0.2 * math.sin(innerAngle);
        if (i == 0) {
          innerStarPath.moveTo(outerX, outerY);
        } else {
          innerStarPath.lineTo(outerX, outerY);
        }
        innerStarPath.lineTo(innerX, innerY);
      }
      innerStarPath.close();
      final innerStarPaint = Paint()
        ..color = paint.color.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7;
      canvas.drawPath(innerStarPath, innerStarPaint);

      // Raggi energetici dalle punte verso il centro
      final spokePaint = Paint()
        ..color = paint.color.withValues(alpha: 0.2)
        ..strokeWidth = 0.5;
      for (int i = 0; i < 4; i++) {
        final angle = i * math.pi / 2;
        final tipX = r * 0.8 * math.cos(angle);
        final tipY = r * 0.8 * math.sin(angle);
        canvas.drawLine(Offset.zero, Offset(tipX, tipY), spokePaint);
      }

      // 4 micro-nodi energetici tra le punte
      for (int i = 0; i < 4; i++) {
        final angle = i * math.pi / 2 + math.pi / 4;
        final nx = r * 0.55 * math.cos(angle);
        final ny = r * 0.55 * math.sin(angle);
        final nodePulse = 0.3 + math.sin(idlePhase * 6 + i * 1.2) * 0.3;
        final nodePaint = Paint()
          ..color = paint.color.withValues(alpha: nodePulse);
        canvas.drawCircle(Offset(nx, ny), 0.8, nodePaint);
      }

      // Nucleo centrale pulsante
      final pulse = 0.4 + math.sin(idlePhase * 4) * 0.3;
      final corePaint = Paint()
        ..color = const Color(0xFFFFFFFF).withValues(alpha: pulse);
      canvas.drawCircle(Offset.zero, r * 0.15, corePaint);
    }
    canvas.restore();
  }
}

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

  @override
  void renderShape(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final r = 8 * scale;

    // Stella a 4 punte rotante (pinwheel come GW Wanderer)
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(idlePhase * 3.14); // Rotazione costante veloce (180 deg/s)

    final path = Path();
    for (int i = 0; i < 4; i++) {
      final angle = i * math.pi / 2;
      // Punta esterna
      final outerX = r * math.cos(angle);
      final outerY = r * math.sin(angle);
      // Rientro tra le punte
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
      // Nucleo centrale pulsante (senza blur per performance)
      final pulse = 0.4 + math.sin(idlePhase * 4) * 0.3;
      final corePaint = Paint()
        ..color = const Color(0xFFFFFFFF).withValues(alpha: pulse);
      canvas.drawCircle(Offset.zero, r * 0.2, corePaint);
    }
    canvas.restore();
  }
}

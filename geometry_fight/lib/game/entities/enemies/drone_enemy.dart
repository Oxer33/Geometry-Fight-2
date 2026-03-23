import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../../data/constants.dart';
import 'enemy_base.dart';

/// DRONE (Grunt) - Rombo blu che insegue il player.
/// Come in GW: parte lento e ACCELERA nel tempo (+2px/s per secondo di vita).
/// Dopo 60s raggiunge la velocità del player, dopo 120s la supera.
class DroneEnemy extends EnemyBase {
  double _aliveTime = 0;

  DroneEnemy()
      : super(
          hp: 1,
          speed: 80, // Parte lento come GW (80 px/s)
          pointValue: 50,
          geomValue: 1,
          neonColor: const Color(0xFF4488FF), // Blu brillante come GW
          size: Vector2(18, 18),
        );

  @override
  void updateBehavior(double dt) {
    _aliveTime += dt;
    // Accelera nel tempo: +2px/s per secondo di vita (come GW Grunt)
    final currentSpeed = speed + _aliveTime * 2.0;
    final velocity = seekPlayer(currentSpeed.clamp(80, 500));
    position += velocity * dt;
  }

  @override
  void renderShape(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final s = size.x / 2 * scale;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(idlePhase * 3);

    // Rombo esterno (corpo principale)
    final path = Path()
      ..moveTo(0, -s)
      ..lineTo(s, 0)
      ..lineTo(0, s)
      ..lineTo(-s, 0)
      ..close();
    canvas.drawPath(path, paint);

    // Solo per il layer principale (non glow)
    if (scale <= 1.01) {
      // Croce interna luminosa
      final crossPaint = Paint()
        ..color = paint.color.withValues(alpha: 0.4)
        ..strokeWidth = 0.8
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(0, -s * 0.5), Offset(0, s * 0.5), crossPaint);
      canvas.drawLine(Offset(-s * 0.5, 0), Offset(s * 0.5, 0), crossPaint);

      // Nucleo pulsante al centro
      final pulse = 0.5 + math.sin(idlePhase * 6) * 0.3;
      final corePaint = Paint()
        ..color = const Color(0xFFFFFFFF).withValues(alpha: pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawCircle(Offset.zero, s * 0.2, corePaint);

      // Punti energetici sui 4 vertici del rombo
      final dotAlpha = 0.4 + math.sin(idlePhase * 4) * 0.3;
      final dotPaint = Paint()
        ..color = paint.color.withValues(alpha: dotAlpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawCircle(Offset(0, -s * 0.8), 1.2, dotPaint);
      canvas.drawCircle(Offset(s * 0.8, 0), 1.2, dotPaint);
      canvas.drawCircle(Offset(0, s * 0.8), 1.2, dotPaint);
      canvas.drawCircle(Offset(-s * 0.8, 0), 1.2, dotPaint);
    }

    canvas.restore();
  }
}

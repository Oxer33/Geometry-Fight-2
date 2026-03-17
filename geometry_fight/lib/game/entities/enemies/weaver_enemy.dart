import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../../data/constants.dart';
import 'enemy_base.dart';

class WeaverEnemy extends EnemyBase {
  double _waveOffset = 0;

  WeaverEnemy()
      : super(
          hp: 2,
          speed: 220,
          pointValue: 150,
          geomValue: 2,
          neonColor: NeonColors.lightBlue,
          size: Vector2(16, 24),
        ) {
    _waveOffset = math.Random().nextDouble() * math.pi * 2;
  }

  @override
  void updateBehavior(double dt) {
    final toPlayer = playerPosition - position;
    if (toPlayer.length > 0) {
      final forward = toPlayer.normalized();
      final side = Vector2(-forward.y, forward.x);

      // Sinusoidal side movement
      final sideOffset = math.sin(idlePhase * 4 + _waveOffset) * 200;
      final targetVelocity = forward * speed + side * sideOffset * dt * 3;

      position += targetVelocity * dt;
    }
  }

  @override
  void renderShape(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final w = 6 * scale;
    final h = 12 * scale;

    // Rombo allungato (corpo principale)
    final path = Path()
      ..moveTo(cx, cy - h)
      ..lineTo(cx + w, cy)
      ..lineTo(cx, cy + h)
      ..lineTo(cx - w, cy)
      ..close();
    canvas.drawPath(path, paint);

    // Dettagli interni solo sul layer principale
    if (scale <= 1.01) {
      // Linea centrale verticale
      final linePaint = Paint()
        ..color = paint.color.withValues(alpha: 0.3)
        ..strokeWidth = 0.5;
      canvas.drawLine(Offset(cx, cy - h * 0.6), Offset(cx, cy + h * 0.6), linePaint);

      // Linee diagonali (struttura ala)
      linePaint.color = paint.color.withValues(alpha: 0.2);
      canvas.drawLine(Offset(cx, cy - h * 0.3), Offset(cx + w * 0.7, cy), linePaint);
      canvas.drawLine(Offset(cx, cy - h * 0.3), Offset(cx - w * 0.7, cy), linePaint);

      // Nucleo pulsante al centro
      final pulse = 0.4 + math.sin(idlePhase * 5 + _waveOffset) * 0.3;
      final corePaint = Paint()
        ..color = const Color(0xFFFFFFFF).withValues(alpha: pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawCircle(Offset(cx, cy), w * 0.25, corePaint);

      // Punti energetici sulle punte superiore e inferiore
      final dotAlpha = 0.3 + math.sin(idlePhase * 4) * 0.3;
      final dotPaint = Paint()
        ..color = paint.color.withValues(alpha: dotAlpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
      canvas.drawCircle(Offset(cx, cy - h * 0.7), 1.0, dotPaint);
      canvas.drawCircle(Offset(cx, cy + h * 0.7), 1.0, dotPaint);
    }
  }
}

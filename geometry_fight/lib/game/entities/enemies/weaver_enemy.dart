import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../../data/constants.dart';
import 'enemy_base.dart';

/// WEAVER (Green Scare) - Quadrato verde che insegue il player.
/// Come in GW: homing + SCHIVA i proiettili che si avvicinano.
/// Leggermente più veloce del player. 85% probabilità di schivare.
class WeaverEnemy extends EnemyBase {
  double _dodgeCooldown = 0;
  final double _waveOffset = math.Random().nextDouble() * math.pi * 2;

  WeaverEnemy()
      : super(
          hp: 1,
          speed: 220, // Leggermente più veloce del player (200)
          pointValue: 4,
          geomValue: 2,
          neonColor: NeonColors.green, // Verde come GW
          size: Vector2(16, 16),
        );

  @override
  void updateBehavior(double dt) {
    if (_dodgeCooldown > 0) _dodgeCooldown -= dt;

    // Homing verso il player
    final toPlayer = seekPlayer(speed);

    // SCHIVA proiettili vicini (85% probabilità, come GW)
    if (_dodgeCooldown <= 0) {
      for (final child in game.world.children) {
        if (child is PositionComponent &&
            child.runtimeType.toString().contains('PlayerBullet')) {
          final dist = child.position.distanceTo(position);
          if (dist < 80) {
            // 85% probabilità di schivare
            if (math.Random().nextDouble() < 0.85) {
              final bulletDir = (child.position - position).normalized();
              final dodgeDir = Vector2(-bulletDir.y, bulletDir.x);
              position += dodgeDir * 150 * dt;
              _dodgeCooldown = 0.3;
            }
            break;
          }
        }
      }
    }

    position += toPlayer * dt;
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

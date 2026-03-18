import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../../data/constants.dart';
import 'enemy_base.dart';

/// GRAVITY WELL - Crea un campo gravitazionale che inverte i controlli del player.
/// Forma: doppio cerchio con spirale interna e particelle orbitanti
/// Colore: indaco profondo (#4400CC)
/// Meccanica: quando il player è nel raggio (180px), i suoi controlli sono invertiti.
/// Si muove lentamente e pulsa ritmicamente. Priorità alta: va eliminato subito!
class GravityWellEnemy extends EnemyBase {
  double _spiralPhase = 0;
  double _pulsePhase = 0;
  static const double _invertRadius = 180.0;

  GravityWellEnemy()
      : super(
          hp: 8,
          speed: 40,
          pointValue: 450,
          geomValue: 5,
          neonColor: const Color(0xFF4400CC),
          size: Vector2(28, 28),
        );

  @override
  void updateBehavior(double dt) {
    _spiralPhase += dt * 4;
    _pulsePhase += dt * 2;

    // Movimento molto lento verso il player
    final velocity = seekPlayer(speed);
    position += velocity * dt;

    // Distorci la griglia costantemente
    game.grid.applyAttraction(position, _invertRadius, 50 * dt);
  }

  @override
  void renderShape(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final r = size.x / 2 * scale;
    final pulse = 1.0 + math.sin(_pulsePhase) * 0.15;

    // Campo gravitazionale visibile (solo layer principale)
    if (scale <= 1.01) {
      // Cerchio campo con gradiente
      for (int ring = 3; ring >= 0; ring--) {
        final ringR = _invertRadius * 0.3 * (ring + 1) * 0.25;
        final ringAlpha = 0.04 + ring * 0.02;
        final ringPaint = Paint()
          ..color = neonColor.withValues(alpha: ringAlpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5;
        canvas.drawCircle(Offset(cx, cy), ringR, ringPaint);
      }
    }

    // Cerchio esterno pulsante
    canvas.drawCircle(Offset(cx, cy), r * pulse, paint);

    // Dettagli interni
    if (scale <= 1.01) {
      // Spirale interna
      final spiralPaint = Paint()
        ..color = paint.color.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      final spiralPath = Path();
      for (int i = 0; i < 60; i++) {
        final angle = _spiralPhase + i * 0.15;
        final dist = r * 0.1 + r * 0.7 * (i / 60);
        final sx = cx + dist * math.cos(angle);
        final sy = cy + dist * math.sin(angle);
        if (i == 0) spiralPath.moveTo(sx, sy); else spiralPath.lineTo(sx, sy);
      }
      canvas.drawPath(spiralPath, spiralPaint);

      // Particelle orbitanti (6 particelle)
      for (int i = 0; i < 6; i++) {
        final pAngle = _spiralPhase * 1.5 + i * math.pi / 3;
        final pDist = r * 0.6 * pulse;
        final px = cx + pDist * math.cos(pAngle);
        final py = cy + pDist * math.sin(pAngle);
        final pAlpha = 0.4 + math.sin(_spiralPhase * 2 + i) * 0.3;
        canvas.drawCircle(
          Offset(px, py), 1.5,
          Paint()..color = const Color(0xFF8844FF).withValues(alpha: pAlpha)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
        );
      }

      // Nucleo luminoso
      final corePaint = Paint()
        ..color = const Color(0xFFAA66FF).withValues(alpha: 0.6 + math.sin(_pulsePhase * 3) * 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
      canvas.drawCircle(Offset(cx, cy), r * 0.25, corePaint);
    }
  }
}

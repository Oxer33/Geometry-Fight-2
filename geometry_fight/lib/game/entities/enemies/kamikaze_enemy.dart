import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../../data/constants.dart';
import 'enemy_base.dart';

enum KamikazeState { idle, charging, rushing, recovering }

class KamikazeEnemy extends EnemyBase {
  KamikazeState _state = KamikazeState.idle;
  double _stateTimer = 1.5;
  Vector2? _rushDirection;
  double _flashRate = 2;

  KamikazeEnemy()
      : super(
          hp: 1,
          speed: 800,
          pointValue: 100,
          geomValue: 2,
          neonColor: NeonColors.red,
          size: Vector2(16, 22),
        );

  @override
  void updateBehavior(double dt) {
    _stateTimer -= dt;

    switch (_state) {
      case KamikazeState.idle:
        if (_stateTimer <= 0) {
          _state = KamikazeState.charging;
          _stateTimer = 1.5;
          _flashRate = 2;
        }
      case KamikazeState.charging:
        // Accelerating flash to telegraph
        _flashRate += dt * 15;
        if (_stateTimer <= 0) {
          _state = KamikazeState.rushing;
          _rushDirection = (playerPosition - position).normalized();
          _stateTimer = 1.0;
        }
      case KamikazeState.rushing:
        position += _rushDirection! * speed * dt;
        if (_stateTimer <= 0) {
          _state = KamikazeState.recovering;
          _stateTimer = 0.5;
        }
      case KamikazeState.recovering:
        if (_stateTimer <= 0) {
          _state = KamikazeState.charging;
          _stateTimer = 1.5;
          _flashRate = 2;
        }
    }
  }

  @override
  void renderShape(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final w = 7 * scale;
    final h = 11 * scale;

    // Direzione di puntamento
    final angle = _rushDirection != null
        ? math.atan2(_rushDirection!.y, _rushDirection!.x) + math.pi / 2
        : math.atan2(playerPosition.y - position.y,
                playerPosition.x - position.x) +
            math.pi / 2;

    // === EFFETTI SPECIALI PER STATO (solo layer principale) ===
    if (scale <= 1.01) {
      // Anelli di carica durante charging
      if (_state == KamikazeState.charging) {
        final chargeProgress = 1.0 - (_stateTimer / 1.5).clamp(0.0, 1.0);
        for (int i = 0; i < 2; i++) {
          final ringR = 20 - chargeProgress * 12 + i * 8;
          final ringAlpha = chargeProgress * 0.4 - i * 0.1;
          if (ringAlpha > 0) {
            final ringPaint = Paint()
              ..color = const Color(0xFFFF4400).withValues(alpha: ringAlpha)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5;
            canvas.drawCircle(Offset(cx, cy), ringR, ringPaint);
          }
        }
      }

      // Scia di fuoco durante il rush
      if (_state == KamikazeState.rushing && _rushDirection != null) {
        final trailDir = -_rushDirection!;
        for (int i = 1; i <= 5; i++) {
          final trailAlpha = 0.4 - i * 0.07;
          final trailSize = 3.0 - i * 0.4;
          if (trailAlpha > 0 && trailSize > 0) {
            final trailPaint = Paint()
              ..color = const Color(0xFFFF4400).withValues(alpha: trailAlpha)
              ..maskFilter = MaskFilter.blur(BlurStyle.normal, trailSize + 1);
            canvas.drawCircle(
              Offset(cx + trailDir.x * i * 5, cy + trailDir.y * i * 5),
              trailSize, trailPaint,
            );
          }
        }
      }
    }

    // Flash bianco durante charging (accelera)
    if (_state == KamikazeState.charging) {
      if ((idlePhase * _flashRate).toInt() % 2 == 0) {
        paint.color = const Color(0xFFFFFFFF);
      }
    }
    // Rosso brillante durante il rush
    if (_state == KamikazeState.rushing && scale <= 1.01) {
      paint.color = const Color(0xFFFF2200);
    }

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(angle);

    // Freccia appuntita (corpo principale)
    final path = Path()
      ..moveTo(0, -h)
      ..lineTo(w, h * 0.5)
      ..lineTo(w * 0.3, h * 0.2)
      ..lineTo(-w * 0.3, h * 0.2)
      ..lineTo(-w, h * 0.5)
      ..close();
    canvas.drawPath(path, paint);

    // Dettagli interni (solo layer principale)
    if (scale <= 1.01) {
      // Linea centrale
      final linePaint = Paint()
        ..color = paint.color.withValues(alpha: 0.3)
        ..strokeWidth = 0.5;
      canvas.drawLine(Offset(0, -h * 0.6), Offset(0, h * 0.3), linePaint);

      // Nucleo incandescente durante charging/rushing
      if (_state == KamikazeState.charging || _state == KamikazeState.rushing) {
        final glowAlpha = _state == KamikazeState.rushing ? 0.8 : 0.4;
        final corePaint = Paint()
          ..color = const Color(0xFFFF6600).withValues(alpha: glowAlpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawCircle(Offset(0, -h * 0.2), 3, corePaint);
      }
    }

    canvas.restore();
  }
}

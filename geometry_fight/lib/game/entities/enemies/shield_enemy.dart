import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../../data/constants.dart';
import 'enemy_base.dart';

class ShieldEnemy extends EnemyBase {
  double shieldHp = 5;
  double _shieldRegenTimer = 0;
  final double _shieldRegenDelay = 4.0;

  ShieldEnemy()
      : super(
          hp: 3,
          speed: 100,
          pointValue: 350,
          geomValue: 4,
          neonColor: NeonColors.purple,
          size: Vector2(24, 24),
        );

  @override
  void updateBehavior(double dt) {
    // Move towards player, facing them
    final velocity = seekPlayer(speed);
    position += velocity * dt;

    // Shield regen
    if (shieldHp <= 0) {
      _shieldRegenTimer += dt;
      if (_shieldRegenTimer >= _shieldRegenDelay) {
        shieldHp = 5;
        _shieldRegenTimer = 0;
      }
    }
  }

  @override
  void takeDamage(double amount) {
    // Lo scudo frontale assorbe sempre i danni indipendentemente dalla direzione
    if (shieldHp > 0) {
      shieldHp -= amount;
      if (shieldHp < 0) shieldHp = 0;
      return;
    }

    super.takeDamage(amount);
  }

  @override
  void renderShape(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final r = 10 * scale;

    // Corpo - cerchio con anello interno
    canvas.drawCircle(Offset(cx, cy), r, paint);

    if (scale <= 1.01) {
      // Anello interno strutturale
      final ringPaint = Paint()
        ..color = paint.color.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8;
      canvas.drawCircle(Offset(cx, cy), r * 0.6, ringPaint);

      // Nucleo pulsante
      final pulse = 0.4 + math.sin(idlePhase * 4) * 0.3;
      final corePaint = Paint()
        ..color = const Color(0xFFFFFFFF).withValues(alpha: pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawCircle(Offset(cx, cy), r * 0.25, corePaint);
    }

    // Scudo frontale force field
    if (shieldHp > 0) {
      final toPlayer = (playerPosition - position);
      final angle = math.atan2(toPlayer.y, toPlayer.x);
      final shieldAlpha = (shieldHp / 5.0).clamp(0.0, 1.0);

      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(angle);

      // Glow dello scudo
      final glowPaint = Paint()
        ..color = NeonColors.purple.withValues(alpha: shieldAlpha * 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: 15 * scale),
        -math.pi / 3, math.pi * 2 / 3, false, glowPaint..strokeWidth = 5..style = PaintingStyle.stroke,
      );

      // Scudo principale
      final shieldPaint = Paint()
        ..color = NeonColors.purple.withValues(alpha: shieldAlpha * 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5 * scale;
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: 14 * scale),
        -math.pi / 3, math.pi * 2 / 3, false, shieldPaint,
      );

      // Segmenti HP scudo (puntini lungo l'arco)
      if (scale <= 1.01) {
        for (int i = 0; i < 5; i++) {
          final segAngle = -math.pi / 3 + i * (math.pi * 2 / 3) / 4;
          final segX = 14 * scale * math.cos(segAngle);
          final segY = 14 * scale * math.sin(segAngle);
          final segActive = i < shieldHp;
          final segPaint = Paint()
            ..color = segActive
                ? NeonColors.purple.withValues(alpha: 0.8)
                : NeonColors.purple.withValues(alpha: 0.15);
          canvas.drawCircle(Offset(segX, segY), 1.5, segPaint);
        }
      }

      canvas.restore();
    } else if (scale <= 1.01) {
      // Indicatore rigenerazione (cerchio tratteggiato debole)
      final regenProgress = (_shieldRegenTimer / _shieldRegenDelay).clamp(0.0, 1.0);
      if (regenProgress > 0) {
        final regenPaint = Paint()
          ..color = NeonColors.purple.withValues(alpha: regenProgress * 0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5;
        canvas.drawCircle(Offset(cx, cy), 14 * scale, regenPaint);
      }
    }
  }
}

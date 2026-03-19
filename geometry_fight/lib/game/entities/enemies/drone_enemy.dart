import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../../data/constants.dart';
import 'enemy_base.dart';

/// DRONE (Wanderer) - Nemico base più comune. Rombo rosa.
/// Come in Geometry Wars: rimbalza sui muri con direzione casuale.
/// NON insegue il player. Si muove in linea retta rimbalzando.
class DroneEnemy extends EnemyBase {
  late Vector2 _velocity;
  static final _rng = math.Random();

  DroneEnemy()
      : super(
          hp: 1,
          speed: 160,
          pointValue: 50,
          geomValue: 1,
          neonColor: NeonColors.pink,
          size: Vector2(18, 18),
        ) {
    // Direzione iniziale casuale
    final angle = _rng.nextDouble() * math.pi * 2;
    _velocity = Vector2(math.cos(angle), math.sin(angle)) * speed;
  }

  @override
  void updateBehavior(double dt) {
    // Movimento rettilineo con rimbalzo sui muri (come Geometry Wars)
    position += _velocity * dt;

    // Rimbalzo sui bordi dell'arena
    if (game.isTunnelMode) {
      final centerY = arenaHeight / 2;
      final halfH = game.tunnelHeight / 2;
      if (position.y <= centerY - halfH + 10 || position.y >= centerY + halfH - 10) {
        _velocity.y = -_velocity.y;
      }
    } else {
      if (position.x <= 10 || position.x >= arenaWidth - 10) {
        _velocity.x = -_velocity.x;
      }
      if (position.y <= 10 || position.y >= arenaHeight - 10) {
        _velocity.y = -_velocity.y;
      }
    }
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

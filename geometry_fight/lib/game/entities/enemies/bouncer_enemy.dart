import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../../data/constants.dart';
import 'enemy_base.dart';

class BouncerEnemy extends EnemyBase {
  late Vector2 _velocity;
  double _maxSpeed = 500;

  BouncerEnemy()
      : super(
          hp: 3,
          speed: 200,
          pointValue: 200,
          geomValue: 3,
          neonColor: NeonColors.yellow,
          size: Vector2(16, 16),
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final angle = math.Random().nextDouble() * math.pi * 2;
    _velocity = Vector2(math.cos(angle), math.sin(angle)) * speed;
  }

  @override
  void updateBehavior(double dt) {
    position += _velocity * dt;

    // Bounce off walls
    if (position.x <= 8 || position.x >= arenaWidth - 8) {
      _velocity.x = -_velocity.x;
      position.x = position.x.clamp(8, arenaWidth - 8);
      _accelerate();
    }
    if (position.y <= 8 || position.y >= arenaHeight - 8) {
      _velocity.y = -_velocity.y;
      position.y = position.y.clamp(8, arenaHeight - 8);
      _accelerate();
    }
  }

  void _accelerate() {
    final currentSpeed = _velocity.length;
    if (currentSpeed < _maxSpeed) {
      _velocity = _velocity.normalized() * (currentSpeed * 1.1);
    }
  }

  @override
  void renderShape(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final r = 8 * scale;

    // Cerchio principale
    canvas.drawCircle(Offset(cx, cy), r, paint);

    // Dettagli solo sul layer principale (non glow)
    if (scale <= 1.01) {
      // Velocità attuale come indicatore di luminosità
      final speedFactor = (_velocity.length / _maxSpeed).clamp(0.0, 1.0);

      // Anello esterno rotante
      final ringPaint = Paint()
        ..color = paint.color.withValues(alpha: 0.3 + speedFactor * 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(idlePhase * 2);
      // Arco parziale che indica la velocità
      final sweepAngle = math.pi * (0.5 + speedFactor * 1.5);
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: r * 1.15),
        0, sweepAngle, false, ringPaint,
      );
      canvas.restore();

      // Secondo arco (rotazione opposta)
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(-idlePhase * 1.5);
      ringPaint.color = paint.color.withValues(alpha: 0.2);
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: r * 1.3),
        0, sweepAngle * 0.6, false, ringPaint,
      );
      canvas.restore();

      // Nucleo luminoso (più luminoso = più veloce)
      final corePaint = Paint()
        ..color = Color.fromRGBO(255, 255, 255, 0.3 + speedFactor * 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(Offset(cx, cy), r * 0.35, corePaint);

      // Croce interna
      final crossPaint = Paint()
        ..color = paint.color.withValues(alpha: 0.2)
        ..strokeWidth = 0.5;
      canvas.drawLine(Offset(cx - r * 0.5, cy), Offset(cx + r * 0.5, cy), crossPaint);
      canvas.drawLine(Offset(cx, cy - r * 0.5), Offset(cx, cy + r * 0.5), crossPaint);
    }
  }
}

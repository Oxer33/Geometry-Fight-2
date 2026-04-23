import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import 'enemy_base.dart';

/// DRONE (Grunt) - Rombo blu che insegue il player.
/// Come in GW: parte lento e ACCELERA nel tempo (+2px/s per secondo di vita).
/// Dopo 60s raggiunge la velocità del player, dopo 120s la supera.
class DroneEnemy extends EnemyBase {
  double _aliveTime = 0;

  // Paint caches: con 60+ droni a schermo × 60fps = 14400 alloc/sec evitati.
  static final Paint _innerPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.8;
  static final Paint _circuitPaint = Paint()..strokeWidth = 0.5;
  static final Paint _nodePaint = Paint();
  static final Paint _corePaint = Paint();

  DroneEnemy()
      : super(
          hp: 1,
          speed: 80, // Parte lento come GW (80 px/s)
          pointValue: 2,
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

    if (scale <= 1.01) {
      // Rombo interno contro-rotante (effetto tech)
      final innerS = s * 0.5;
      final innerPath = Path()
        ..moveTo(0, -innerS)
        ..lineTo(innerS, 0)
        ..lineTo(0, innerS)
        ..lineTo(-innerS, 0)
        ..close();
      _innerPaint.color = paint.color.withValues(alpha: 0.35);
      canvas.drawPath(innerPath, _innerPaint);

      // Circuiti: linee dai vertici interni a quelli esterni
      _circuitPaint.color = paint.color.withValues(alpha: 0.25);
      canvas.drawLine(Offset(0, -innerS), Offset(innerS * 0.7, -innerS * 0.7), _circuitPaint);
      canvas.drawLine(Offset(innerS, 0), Offset(innerS * 0.7, innerS * 0.7), _circuitPaint);
      canvas.drawLine(Offset(0, innerS), Offset(-innerS * 0.7, innerS * 0.7), _circuitPaint);
      canvas.drawLine(Offset(-innerS, 0), Offset(-innerS * 0.7, -innerS * 0.7), _circuitPaint);

      // 4 nodi energetici sui vertici (pulsanti sfasati)
      for (int i = 0; i < 4; i++) {
        final angle = i * math.pi / 2;
        final nx = s * 0.75 * math.cos(angle - math.pi / 4);
        final ny = s * 0.75 * math.sin(angle - math.pi / 4);
        final nodePulse = 0.3 + math.sin(idlePhase * 5 + i * 1.5) * 0.3;
        _nodePaint.color = paint.color.withValues(alpha: nodePulse);
        canvas.drawCircle(Offset(nx, ny), 1.2, _nodePaint);
      }

      // Nucleo pulsante al centro
      final pulse = 0.5 + math.sin(idlePhase * 6) * 0.3;
      _corePaint.color = const Color(0xFFFFFFFF).withValues(alpha: pulse);
      canvas.drawCircle(Offset.zero, s * 0.15, _corePaint);
    }

    canvas.restore();
  }
}

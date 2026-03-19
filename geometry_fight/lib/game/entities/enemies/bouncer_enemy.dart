import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../../data/constants.dart';
import 'enemy_base.dart';

/// BOUNCER (Green Square) - Insegue il player con homing lento
/// MA schiva i proiettili che si avvicinano (come Geometry Wars).
/// Forma: quadrato verde con rotazione.
class BouncerEnemy extends EnemyBase {
  double _dodgeCooldown = 0;
  bool _isDodging = false;
  double _dodgeTimer = 0;

  BouncerEnemy()
      : super(
          hp: 2,
          speed: 140,
          pointValue: 200,
          geomValue: 3,
          neonColor: NeonColors.green,
          size: Vector2(16, 16),
        );

  @override
  void updateBehavior(double dt) {
    if (_dodgeCooldown > 0) _dodgeCooldown -= dt;
    if (_dodgeTimer > 0) _dodgeTimer -= dt;
    if (_dodgeTimer <= 0) _isDodging = false;

    // Insegue il player lentamente (homing)
    final toPlayer = seekPlayer(speed);

    // Schiva proiettili vicini (meccanica Green Square di Geometry Wars)
    if (_dodgeCooldown <= 0) {
      for (final child in game.world.children) {
        if (child is PositionComponent && child.runtimeType.toString().contains('PlayerBullet')) {
          final dist = child.position.distanceTo(position);
          if (dist < 80) {
            // Proiettile vicino! Schiva lateralmente
            final bulletDir = (child.position - position).normalized();
            final dodgeDir = Vector2(-bulletDir.y, bulletDir.x); // Perpendicolare
            position += dodgeDir * 120 * dt;
            _isDodging = true;
            _dodgeTimer = 0.2;
            _dodgeCooldown = 0.5;
            break;
          }
        }
      }
    }

    // Movimento base: insegue il player
    if (!_isDodging) {
      position += toPlayer * dt;
    }
  }

  @override
  void renderShape(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final r = 8 * scale;

    // Quadrato ruotato (come Green Square di Geometry Wars)
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(idlePhase * 1.5);
    canvas.drawRect(
      Rect.fromCenter(center: Offset.zero, width: r * 1.8, height: r * 1.8),
      paint,
    );

    if (scale <= 1.01) {
      // Effetto schivata (flash quando dodge attivo)
      if (_isDodging) {
        final dodgePaint = Paint()
          ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: r * 2.2, height: r * 2.2),
          dodgePaint,
        );
      }

      // Diagonali interne
      final diagPaint = Paint()
        ..color = paint.color.withValues(alpha: 0.3)
        ..strokeWidth = 0.6;
      canvas.drawLine(Offset(-r * 0.6, -r * 0.6), Offset(r * 0.6, r * 0.6), diagPaint);
      canvas.drawLine(Offset(r * 0.6, -r * 0.6), Offset(-r * 0.6, r * 0.6), diagPaint);

      // Nucleo pulsante
      final pulse = 0.4 + math.sin(idlePhase * 5) * 0.3;
      final corePaint = Paint()
        ..color = const Color(0xFFFFFFFF).withValues(alpha: pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawCircle(Offset.zero, r * 0.25, corePaint);

      // Punti agli angoli del quadrato
      final dotPaint = Paint()
        ..color = paint.color.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
      final hr = r * 0.8;
      canvas.drawCircle(Offset(-hr, -hr), 1.2, dotPaint);
      canvas.drawCircle(Offset(hr, -hr), 1.2, dotPaint);
      canvas.drawCircle(Offset(hr, hr), 1.2, dotPaint);
      canvas.drawCircle(Offset(-hr, hr), 1.2, dotPaint);
    }
    canvas.restore();
  }
}

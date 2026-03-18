import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../../data/constants.dart';
import 'enemy_base.dart';
import '../projectiles.dart';

/// NEW ENEMY: Pulsar - emits periodic energy rings that damage the player
class PulsarEnemy extends EnemyBase {
  double _pulseTimer = 2.5;
  double _pulseRadius = 0;
  bool _pulsing = false;

  PulsarEnemy()
      : super(
          hp: 4,
          speed: 80,
          pointValue: 250,
          geomValue: 3,
          neonColor: NeonColors.teal,
          size: Vector2(22, 22),
        );

  @override
  void updateBehavior(double dt) {
    // Orbit around the player at a distance
    final toPlayer = playerPosition - position;
    final dist = toPlayer.length;

    if (dist > 250) {
      position += toPlayer.normalized() * speed * dt;
    } else if (dist < 180) {
      position -= toPlayer.normalized() * speed * dt;
    } else {
      // Orbit
      final perpendicular = Vector2(-toPlayer.y, toPlayer.x).normalized();
      position += perpendicular * speed * dt;
    }

    // Pulse attack
    _pulseTimer -= dt;
    if (_pulseTimer <= 0) {
      _pulseTimer = 2.5;
      _pulsing = true;
      _pulseRadius = 0;

      // Spawn ring bullets
      for (int i = 0; i < 12; i++) {
        final angle = i * math.pi * 2 / 12;
        final dir = Vector2(math.cos(angle), math.sin(angle));
        final bullet = EnemyBullet(
          direction: dir,
          speed: 200,
          color: NeonColors.teal,
        );
        bullet.position = position.clone();
        game.world.add(bullet);
      }
    }

    if (_pulsing) {
      _pulseRadius += dt * 300;
      if (_pulseRadius > 150) _pulsing = false;
    }
  }

  @override
  void renderShape(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final r = 10 * scale;

    // Pentagono con rotazione lenta
    final path = Path();
    final vertices = <Offset>[];
    for (int i = 0; i < 5; i++) {
      final angle = i * math.pi * 2 / 5 - math.pi / 2 + idlePhase * 0.5;
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      vertices.add(Offset(x, y));
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paint);

    // Dettagli interni solo sul layer principale
    if (scale <= 1.01) {
      // Indicatore di carica (cerchio che si riempie prima del pulse)
      final chargeProgress = 1.0 - (_pulseTimer / 2.5).clamp(0.0, 1.0);
      if (chargeProgress > 0.1) {
        final chargePaint = Paint()
          ..color = NeonColors.teal.withValues(alpha: chargeProgress * 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        canvas.drawArc(
          Rect.fromCircle(center: Offset(cx, cy), radius: r * 1.3),
          -math.pi / 2, math.pi * 2 * chargeProgress, false, chargePaint,
        );
      }

      // Nucleo pulsante teal (brilla di più prima del pulse)
      final coreIntensity = 0.4 + chargeProgress * 0.4;
      final corePaint = Paint()
        ..color = const Color(0xFFFFFFFF).withValues(alpha: coreIntensity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3 + chargeProgress * 3);
      canvas.drawCircle(Offset(cx, cy), r * 0.3, corePaint);

      // Particelle luminose sui vertici
      for (int i = 0; i < 5; i++) {
        final dotAlpha = 0.3 + math.sin(idlePhase * 3 + i * 1.2) * 0.3;
        final dotPaint = Paint()
          ..color = paint.color.withValues(alpha: dotAlpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
        canvas.drawCircle(vertices[i], 1.5, dotPaint);
      }

      // Linee interne dal centro ai vertici
      final linePaint = Paint()
        ..color = paint.color.withValues(alpha: 0.15)
        ..strokeWidth = 0.5;
      for (final v in vertices) {
        canvas.drawLine(Offset(cx, cy), v, linePaint);
      }
    }

    // Doppia onda pulse
    if (_pulsing) {
      final alpha = 1.0 - (_pulseRadius / 150);
      // Onda interna brillante
      final innerRing = Paint()
        ..color = NeonColors.teal.withValues(alpha: alpha * 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(Offset(cx, cy), _pulseRadius, innerRing);
      // Onda esterna sottile
      final outerRing = Paint()
        ..color = NeonColors.teal.withValues(alpha: alpha * 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawCircle(Offset(cx, cy), _pulseRadius * 1.2, outerRing);
    }
  }
}

import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../../data/constants.dart';
import 'enemy_base.dart';
import '../projectiles.dart';

// Random statico condiviso: evita alloc a ogni pulse (~2.5s per pulsar).
final math.Random _pulsarRng = math.Random();

/// NEW ENEMY: Pulsar - emits periodic energy rings that damage the player
class PulsarEnemy extends EnemyBase {
  double _pulseTimer = 2.5;
  double _pulseRadius = 0;
  bool _pulsing = false;

  // Paint caches: evita alloc per frame × N pulsar (chargePaint, inner/outer
  // ring, linePaint).
  static final Paint _chargePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;
  static final Paint _innerRing = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.5;
  static final Paint _outerRing = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  static final Paint _linePaint = Paint()..strokeWidth = 0.5;

  PulsarEnemy()
      : super(
          hp: 4,
          speed: 80,
          pointValue: 8,
          geomValue: 3,
          neonColor: NeonColors.teal,
          size: Vector2(22, 22),
        );

  @override
  void updateBehavior(double dt) {
    // Orbit around the player at a distance
    final toPlayer = playerPosition - position;
    final dist = toPlayer.length;

    // NaN guard: se player coincide col mob, skip movement.
    if (dist > 0.001) {
      if (dist > 250) {
        position += toPlayer.normalized() * speed * dt;
      } else if (dist < 180) {
        position -= toPlayer.normalized() * speed * dt;
      } else {
        // Orbit
        final perpendicular = Vector2(-toPlayer.y, toPlayer.x).normalized();
        position += perpendicular * speed * dt;
      }
    }

    // Pulse attack
    _pulseTimer -= dt;
    if (_pulseTimer <= 0) {
      _pulseTimer = 2.5;
      _pulsing = true;
      _pulseRadius = 0;

      // 4 bullets in + (0/90/180/270°) or X (45° offsets) — random ogni pulse.
      // Meno intenso dell'originale ring a 12: schivabile, ma comunque
      // costringe il player a non restare fermo.
      final useX = _pulsarRng.nextBool();
      final baseOffset = useX ? math.pi / 4 : 0.0;
      for (int i = 0; i < 4; i++) {
        final angle = baseOffset + i * math.pi / 2;
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
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);

    // Dettagli interni solo sul layer principale
    if (scale <= 1.01) {
      // Indicatore di carica (cerchio che si riempie prima del pulse)
      final chargeProgress = 1.0 - (_pulseTimer / 2.5).clamp(0.0, 1.0);
      if (chargeProgress > 0.1) {
        _chargePaint.color = NeonColors.teal.withValues(alpha: chargeProgress * 0.4);
        canvas.drawArc(
          Rect.fromCircle(center: Offset(cx, cy), radius: r * 1.3),
          -math.pi / 2, math.pi * 2 * chargeProgress, false, _chargePaint,
        );
      }

      // Nucleo pulsante teal (brilla di più prima del pulse)
      final coreIntensity = 0.4 + chargeProgress * 0.4;
      // Core — senza blur, glow simulato
      EnemyBase.detailPaint.color = const Color(0xFFFFFFFF).withValues(alpha: coreIntensity * 0.4);
      canvas.drawCircle(Offset(cx, cy), r * 0.5, EnemyBase.detailPaint);
      EnemyBase.detailPaint.color = const Color(0xFFFFFFFF).withValues(alpha: coreIntensity);
      canvas.drawCircle(Offset(cx, cy), r * 0.3, EnemyBase.detailPaint);

      // Particelle luminose sui vertici — senza blur
      for (int i = 0; i < 5; i++) {
        final dotAlpha = 0.3 + math.sin(idlePhase * 3 + i * 1.2) * 0.3;
        EnemyBase.detailPaint.color = paint.color.withValues(alpha: dotAlpha);
        canvas.drawCircle(vertices[i], 1.5, EnemyBase.detailPaint);
      }

      // Linee interne dal centro ai vertici
      _linePaint.color = paint.color.withValues(alpha: 0.15);
      for (final v in vertices) {
        canvas.drawLine(Offset(cx, cy), v, _linePaint);
      }
    }

    // Doppia onda pulse
    if (_pulsing) {
      final alpha = 1.0 - (_pulseRadius / 150);
      // Onda interna brillante
      _innerRing.color = NeonColors.teal.withValues(alpha: alpha * 0.5);
      canvas.drawCircle(Offset(cx, cy), _pulseRadius, _innerRing);
      // Onda esterna sottile
      _outerRing.color = NeonColors.teal.withValues(alpha: alpha * 0.2);
      canvas.drawCircle(Offset(cx, cy), _pulseRadius * 1.2, _outerRing);
    }
  }
}

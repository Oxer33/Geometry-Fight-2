import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../../data/constants.dart';
import 'enemy_base.dart';

/// LASER TURRET - Nemico stazionario che spara raggi laser rotanti.
/// Forma: quadrato con cannone rotante al centro
/// Colore: rosso intenso (#FF1144)
/// Meccanica: non si muove, ma ruota un raggio laser continuo a 360°.
/// Il raggio danneggia il player al contatto. Va distrutto da lontano.
class LaserTurretEnemy extends EnemyBase {
  double _laserAngle = 0;
  double _laserSpeed = 1.2; // radianti/secondo
  double _warmupTimer = 1.5; // Tempo prima che il laser si attivi
  bool _laserActive = false;
  static const double _laserLength = 250.0;

  LaserTurretEnemy()
      : super(
          hp: 6,
          speed: 0, // Stazionario
          pointValue: 400,
          geomValue: 5,
          neonColor: const Color(0xFFFF1144),
          size: Vector2(22, 22),
        );

  @override
  void updateBehavior(double dt) {
    if (_warmupTimer > 0) {
      _warmupTimer -= dt;
      if (_warmupTimer <= 0) _laserActive = true;
      return;
    }

    // Ruota il laser
    _laserAngle += _laserSpeed * dt;

    // Check danno al player
    if (_laserActive) {
      final laserEnd = position + Vector2(
        math.cos(_laserAngle) * _laserLength,
        math.sin(_laserAngle) * _laserLength,
      );
      // Distanza punto-segmento player-laser
      final playerDist = _distToSegment(playerPosition, position, laserEnd);
      if (playerDist < 12) {
        game.player.takeDamage();
      }
    }
  }

  double _distToSegment(Vector2 p, Vector2 a, Vector2 b) {
    final ab = b - a;
    final len = ab.length;
    if (len == 0) return p.distanceTo(a);
    final t = ((p - a).dot(ab) / (len * len)).clamp(0.0, 1.0);
    return p.distanceTo(a + ab * t);
  }

  @override
  void renderShape(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final r = size.x / 2 * scale;

    // Quadrato base
    canvas.save();
    canvas.translate(cx, cy);
    canvas.drawRect(
      Rect.fromCenter(center: Offset.zero, width: r * 1.6, height: r * 1.6),
      paint,
    );

    // Dettagli interni
    if (scale <= 1.01) {
      // Cerchio cannone al centro
      final cannonPaint = Paint()
        ..color = paint.color.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(Offset.zero, r * 0.5, cannonPaint);

      // Linea del laser (se attivo)
      if (_laserActive) {
        // Glow del laser
        final laserGlow = Paint()
          ..color = neonColor.withValues(alpha: 0.2)
          ..strokeWidth = 6
          ..style = PaintingStyle.stroke
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
        canvas.drawLine(
          Offset.zero,
          Offset(math.cos(_laserAngle) * _laserLength, math.sin(_laserAngle) * _laserLength),
          laserGlow,
        );
        // Core del laser
        final laserCore = Paint()
          ..color = neonColor
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;
        canvas.drawLine(
          Offset.zero,
          Offset(math.cos(_laserAngle) * _laserLength, math.sin(_laserAngle) * _laserLength),
          laserCore,
        );
        // Punto luminoso alla fine del laser
        canvas.drawCircle(
          Offset(math.cos(_laserAngle) * _laserLength, math.sin(_laserAngle) * _laserLength),
          3,
          Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.5)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );
      } else {
        // Warmup: indicatore di carica (cerchio che si riempie)
        final chargeProgress = 1.0 - (_warmupTimer / 1.5).clamp(0.0, 1.0);
        final chargePaint = Paint()
          ..color = neonColor.withValues(alpha: chargeProgress * 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawArc(
          Rect.fromCircle(center: Offset.zero, radius: r * 0.8),
          -math.pi / 2, math.pi * 2 * chargeProgress, false, chargePaint,
        );
      }

      // Nucleo
      final coreAlpha = _laserActive ? 0.8 : 0.3;
      canvas.drawCircle(
        Offset.zero, r * 0.2,
        Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: coreAlpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }
    canvas.restore();
  }
}

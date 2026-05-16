import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import 'enemy_base.dart';

/// LASER TURRET - Nemico stazionario che spara raggi laser rotanti.
/// Forma: quadrato con cannone rotante al centro
/// Colore: rosso intenso (#FF1144)
/// Meccanica: non si muove, ma ruota un raggio laser continuo a 360°.
/// Il raggio danneggia il player al contatto. Va distrutto da lontano.
class LaserTurretEnemy extends EnemyBase {
  double _laserAngle = 0;
  final double _laserSpeed = 1.2; // radianti/secondo
  double _warmupTimer = 1.5; // Tempo prima che il laser si attivi
  bool _laserActive = false;
  static const double _laserLength = 250.0;
  // Cooldown sul danno al player: il raggio era un check per-frame → 60 danni/sec.
  // Con 0.5s di cooldown il player può comunque uscire dal cono di rotazione.
  double _hitCd = 0;

  // Paint caches: evita 2× alloc/frame × N turret a schermo.
  static final Paint _cannonPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;
  static final Paint _chargePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;

  LaserTurretEnemy()
      : super(
          hp: 6,
          speed: 0, // Stazionario
          pointValue: 15,
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
    if (_hitCd > 0) _hitCd -= dt;

    // Check danno al player (con cooldown 0.5s tra hit per evitare 60 dmg/sec).
    if (_laserActive) {
      final laserEnd = position + Vector2(
        math.cos(_laserAngle) * _laserLength,
        math.sin(_laserAngle) * _laserLength,
      );
      // Distanza punto-segmento player-laser
      final playerDist = _distToSegment(playerPosition, position, laserEnd);
      if (playerDist < 12 && _hitCd <= 0) {
        game.player.takeDamage();
        _hitCd = 0.5;
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
      _cannonPaint.color = paint.color.withValues(alpha: 0.5);
      canvas.drawCircle(Offset.zero, r * 0.5, _cannonPaint);

      // Linea del laser (se attivo)
      if (_laserActive) {
        final laserEnd = Offset(math.cos(_laserAngle) * _laserLength, math.sin(_laserAngle) * _laserLength);
        // Glow del laser — senza blur, linea più spessa
        EnemyBase.detailPaint.color = neonColor.withValues(alpha: 0.1);
        EnemyBase.detailPaint.strokeWidth = 8;
        EnemyBase.detailPaint.style = PaintingStyle.stroke;
        canvas.drawLine(Offset.zero, laserEnd, EnemyBase.detailPaint);
        // Core del laser
        EnemyBase.detailPaint.color = neonColor;
        EnemyBase.detailPaint.strokeWidth = 2;
        canvas.drawLine(Offset.zero, laserEnd, EnemyBase.detailPaint);
        // Punto luminoso alla fine — senza blur
        EnemyBase.detailPaint.style = PaintingStyle.fill;
        EnemyBase.detailPaint.color = const Color(0xFFFFFFFF).withValues(alpha: 0.5);
        canvas.drawCircle(laserEnd, 3, EnemyBase.detailPaint);
      } else {
        // Warmup: indicatore di carica (cerchio che si riempie)
        final chargeProgress = 1.0 - (_warmupTimer / 1.5).clamp(0.0, 1.0);
        _chargePaint.color = neonColor.withValues(alpha: chargeProgress * 0.5);
        canvas.drawArc(
          Rect.fromCircle(center: Offset.zero, radius: r * 0.8),
          -math.pi / 2, math.pi * 2 * chargeProgress, false, _chargePaint,
        );
      }

      // Nucleo — senza blur
      final coreAlpha = _laserActive ? 0.8 : 0.3;
      EnemyBase.detailPaint.color = const Color(0xFFFFFFFF).withValues(alpha: coreAlpha * 0.5);
      EnemyBase.detailPaint.style = PaintingStyle.fill;
      canvas.drawCircle(Offset.zero, r * 0.3, EnemyBase.detailPaint);
      EnemyBase.detailPaint.color = const Color(0xFFFFFFFF).withValues(alpha: coreAlpha);
      canvas.drawCircle(Offset.zero, r * 0.2, EnemyBase.detailPaint);
    }
    canvas.restore();
  }
}

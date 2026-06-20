import 'dart:math' as math;
import 'dart:ui';

import '../../../data/talents/talent_effect.dart';

/// Draws a tiny per-effect glyph centered at [center], sized to radius [r].
/// Pure canvas primitives (1–4 ops) so it stays cheap across ~600 nodes — the
/// static [WebPainter] caches to a raster, so this only runs on allocation.
void drawEffectGlyph(
  Canvas canvas,
  Offset center,
  double r,
  TalentEffect effect,
  Color color,
) {
  final p = Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = (r * 0.18).clamp(1.2, 4.0)
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  final fill = Paint()
    ..color = color
    ..style = PaintingStyle.fill;
  final cx = center.dx, cy = center.dy;
  final g = r * 0.62; // glyph half-extent

  switch (effect) {
    case TalentEffect.atkPct:
      // Up chevron.
      canvas.drawPath(
        Path()
          ..moveTo(cx - g, cy + g * 0.5)
          ..lineTo(cx, cy - g * 0.6)
          ..lineTo(cx + g, cy + g * 0.5),
        p,
      );
    case TalentEffect.shieldDuration:
      // Shield outline.
      canvas.drawPath(
        Path()
          ..moveTo(cx, cy - g)
          ..lineTo(cx + g * 0.8, cy - g * 0.45)
          ..lineTo(cx + g * 0.8, cy + g * 0.3)
          ..lineTo(cx, cy + g)
          ..lineTo(cx - g * 0.8, cy + g * 0.3)
          ..lineTo(cx - g * 0.8, cy - g * 0.45)
          ..close(),
        p,
      );
    case TalentEffect.critChance:
      // 4-point spark.
      canvas.drawLine(Offset(cx, cy - g), Offset(cx, cy + g), p);
      canvas.drawLine(Offset(cx - g, cy), Offset(cx + g, cy), p);
    case TalentEffect.critDmg:
      // 6-point asterisk.
      for (var i = 0; i < 3; i++) {
        final a = i * math.pi / 3;
        canvas.drawLine(
          Offset(cx - math.cos(a) * g, cy - math.sin(a) * g),
          Offset(cx + math.cos(a) * g, cy + math.sin(a) * g),
          p,
        );
      }
    case TalentEffect.fireRate:
      // Lightning bolt.
      canvas.drawPath(
        Path()
          ..moveTo(cx + g * 0.4, cy - g)
          ..lineTo(cx - g * 0.5, cy + g * 0.1)
          ..lineTo(cx + g * 0.1, cy + g * 0.1)
          ..lineTo(cx - g * 0.4, cy + g),
        p,
      );
    case TalentEffect.moveSpeed:
      // Right arrow.
      canvas.drawLine(Offset(cx - g, cy), Offset(cx + g, cy), p);
      canvas.drawPath(
        Path()
          ..moveTo(cx + g * 0.3, cy - g * 0.5)
          ..lineTo(cx + g, cy)
          ..lineTo(cx + g * 0.3, cy + g * 0.5),
        p,
      );
    case TalentEffect.cooldown:
      // Clock.
      canvas.drawCircle(Offset(cx, cy), g, p);
      canvas.drawLine(Offset(cx, cy), Offset(cx, cy - g * 0.6), p);
      canvas.drawLine(Offset(cx, cy), Offset(cx + g * 0.45, cy), p);
    case TalentEffect.goldFind:
      // Diamond.
      canvas.drawPath(
        Path()
          ..moveTo(cx, cy - g)
          ..lineTo(cx + g, cy)
          ..lineTo(cx, cy + g)
          ..lineTo(cx - g, cy)
          ..close(),
        p,
      );
    case TalentEffect.essenceFind:
      // Ring.
      canvas.drawCircle(Offset(cx, cy), g * 0.8, p);
    case TalentEffect.magnet:
      // Horseshoe magnet (arc + two legs).
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy - g * 0.2), radius: g),
        math.pi,
        math.pi,
        false,
        p,
      );
      canvas.drawLine(
        Offset(cx - g, cy - g * 0.2),
        Offset(cx - g, cy + g * 0.7),
        p,
      );
      canvas.drawLine(
        Offset(cx + g, cy - g * 0.2),
        Offset(cx + g, cy + g * 0.7),
        p,
      );
    case TalentEffect.bombRadius:
      // Blast: ring + center dot.
      canvas.drawCircle(Offset(cx, cy), g, p);
      canvas.drawCircle(Offset(cx, cy), g * 0.22, fill);
    case TalentEffect.skillPower:
      // Empower: bold bolt inside a ring.
      canvas.drawCircle(Offset(cx, cy), g, p);
      canvas.drawPath(
        Path()
          ..moveTo(cx + g * 0.3, cy - g * 0.6)
          ..lineTo(cx - g * 0.35, cy + g * 0.05)
          ..lineTo(cx + g * 0.05, cy + g * 0.05)
          ..lineTo(cx - g * 0.25, cy + g * 0.6),
        p,
      );
  }
}

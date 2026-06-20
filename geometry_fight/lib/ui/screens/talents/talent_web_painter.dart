import 'dart:math' as math;

import 'package:flutter/rendering.dart';

import '../../../data/talents/talent_def.dart';
import '../../../data/talents/talent_generator.dart';
import 'talent_icons.dart';

// Node diameters by tier (reference spec).
double talentNodeSize(TalentTier t) => switch (t) {
  TalentTier.keystone => 60,
  TalentTier.fork => 40,
  TalentTier.notable => 36,
  TalentTier.root => 30,
  TalentTier.minor => 28,
};

/// Generous tap radius per tier (draw radius + 8).
double talentHitRadius(TalentTier t) => talentNodeSize(t) / 2 + 8;

const Color _dormant = Color(0xFF8C8C9A);
const Color _bg = Color(0xFF0A0A14);
const Color _white = Color(0xFFFFFFFF);

/// STATIC web layer: all edges + all nodes (shape + icon + halo). Wrapped by the
/// screen in a [RepaintBoundary] so it caches to a single raster; it only
/// repaints when [revision] changes (an allocation), never per animation frame.
class TalentWebPainter extends CustomPainter {
  TalentWebPainter({
    required this.tree,
    required this.owned,
    required this.revision,
  }) : _ownedSlots = _computeOwnedSlots(tree, owned);

  final TalentTree tree;
  final Set<String> owned;
  final int revision;

  /// Slot ids treated as owned for connectivity: each owned id plus its fork
  /// twins (both options share a slot — slot-aware).
  final Set<String> _ownedSlots;

  static Set<String> _computeOwnedSlots(TalentTree tree, Set<String> owned) {
    final s = <String>{};
    for (final id in owned) {
      s.add(id);
      final node = tree.byId[id];
      if (node != null) s.addAll(node.excludes);
    }
    return s;
  }

  bool _slot(String id) => _ownedSlots.contains(id);

  @override
  void paint(Canvas canvas, Size size) {
    final hub = tree.hubCenter;
    Offset pos(TalentDef n) => Offset(hub + n.x, hub + n.y);

    // ── Edges in three passes (dormant → reachable → owned) so owned draw on
    // top. State per spec: both-owned thick, prereq-owned thin, else filament.
    final dormantPaint = Paint()
      ..color = _dormant.withValues(alpha: 0.14)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    final reachablePaint = Paint()
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;
    final ownedPaint = Paint()
      ..strokeWidth = 3.4
      ..style = PaintingStyle.stroke;

    final reachable = <List<Offset>>[];
    final reachableColors = <Color>[];
    final ownedEdges = <List<Offset>>[];
    final ownedColors = <Color>[];
    // Dormant edges (the vast majority) all share one paint → batch into a
    // single Path and one drawPath, instead of ~1500 separate drawLine ops.
    final dormantPath = Path();

    for (final n in tree.nodes) {
      final np = pos(n);
      final nOwnedSlot = _slot(n.id);
      for (final pid in n.prereq) {
        final pNode = tree.byId[pid];
        if (pNode == null) continue;
        final pp = pos(pNode);
        final pOwned = _slot(pid);
        if (nOwnedSlot && pOwned) {
          ownedEdges.add([pp, np]);
          ownedColors.add(Color(n.colorArgb));
        } else if (pOwned) {
          // prereq owned → n is takeable: light n's branch colour.
          reachable.add([pp, np]);
          reachableColors.add(Color(n.colorArgb));
        } else if (nOwnedSlot) {
          // n owned → its neighbour p is takeable (undirected): light p's.
          reachable.add([pp, np]);
          reachableColors.add(Color(pNode.colorArgb));
        } else {
          dormantPath
            ..moveTo(pp.dx, pp.dy)
            ..lineTo(np.dx, np.dy);
        }
      }
    }
    canvas.drawPath(dormantPath, dormantPaint);
    // Reachable (takeable) edges glow in the BRANCH colour of the node they
    // make available — the node itself stays obscured; the lit edge is the cue.
    reachablePaint.strokeWidth = 2.4;
    for (var i = 0; i < reachable.length; i++) {
      reachablePaint.color = reachableColors[i].withValues(alpha: 0.85);
      canvas.drawLine(reachable[i][0], reachable[i][1], reachablePaint);
    }
    for (var i = 0; i < ownedEdges.length; i++) {
      ownedPaint.color = ownedColors[i].withValues(alpha: 0.8);
      canvas.drawLine(ownedEdges[i][0], ownedEdges[i][1], ownedPaint);
    }

    // ── Nodes.
    for (final n in tree.nodes) {
      _drawNode(canvas, n, pos(n));
    }
  }

  void _drawNode(Canvas canvas, TalentDef n, Offset c) {
    final color = Color(n.colorArgb);
    final isOwned = owned.contains(n.id);
    final isSlotOwned = _slot(n.id); // owned, or twin owned
    // A takeable (reachable-but-unowned) node deliberately stays OBSCURED —
    // only the red connecting edge signals that it can be allocated.
    final size = talentNodeSize(n.tier);
    final r = size / 2 - 2;
    final special = n.tier != TalentTier.minor && n.tier != TalentTier.root;

    // Halo behind special nodes.
    if (special) {
      final haloExtra = switch (n.tier) {
        TalentTier.keystone => 12.0,
        TalentTier.fork => 6.0,
        _ => 4.0,
      };
      final blur = n.tier == TalentTier.keystone ? 12.0 : 7.0;
      canvas.drawCircle(
        c,
        r + haloExtra,
        Paint()
          ..color = color.withValues(alpha: isSlotOwned ? 0.2 : 0.08)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur),
      );
    }

    // Body fill (dark base, tinted by state). Unowned nodes — including
    // takeable ones — share the dim dormant fill.
    final fillAlpha = isOwned
        ? 0.85
        : isSlotOwned
        ? 0.5
        : 0.16;
    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = Color.lerp(_bg, color, fillAlpha)!;
    final path = _shapeFor(n.tier, c, r);
    canvas.drawPath(path, fill);

    // Outline: only OWNED nodes get a bold coloured outline; everything else
    // (takeable or dormant) keeps a faint outline so it reads as obscured.
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = isOwned ? (special ? 2.8 : 1.6) : (special ? 1.6 : 1.0)
      ..color = color.withValues(alpha: isOwned ? 1.0 : 0.35);
    canvas.drawPath(path, outline);

    // Effect glyph.
    drawEffectGlyph(
      canvas,
      c,
      r,
      n.effect,
      (isOwned ? _white : color).withValues(alpha: isOwned ? 0.95 : 0.6),
    );
  }

  Path _shapeFor(TalentTier tier, Offset c, double r) => switch (tier) {
    TalentTier.keystone => _polygon(c, r, 4, -math.pi / 2), // diamond
    TalentTier.fork => _star(c, r, r * 0.46, 8, -math.pi / 2),
    TalentTier.notable => _polygon(c, r, 6, -math.pi / 2),
    _ => (Path()..addOval(Rect.fromCircle(center: c, radius: r))),
  };

  Path _polygon(Offset c, double r, int sides, double start) {
    final path = Path();
    for (var i = 0; i < sides; i++) {
      final a = start + i * (math.pi * 2 / sides);
      final pt = Offset(c.dx + math.cos(a) * r, c.dy + math.sin(a) * r);
      i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    return path..close();
  }

  Path _star(Offset c, double rOuter, double rInner, int points, double start) {
    final path = Path();
    for (var i = 0; i < points * 2; i++) {
      final rr = i.isEven ? rOuter : rInner;
      final a = start + i * (math.pi / points);
      final pt = Offset(c.dx + math.cos(a) * rr, c.dy + math.sin(a) * rr);
      i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    return path..close();
  }

  @override
  bool shouldRepaint(covariant TalentWebPainter old) =>
      old.revision != revision;
}

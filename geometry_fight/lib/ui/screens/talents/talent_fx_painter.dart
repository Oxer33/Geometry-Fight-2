import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../data/talents/talent_def.dart';
import '../../../data/talents/talent_generator.dart';
import 'talent_web_painter.dart';

const Color _essence = Color(0xFFFFD27A); // warm gold
const Color _cyan = Color(0xFF00FFFF);
const Color _violet = Color(0xFF9B5CFF);

/// Owned-derived geometry for the FX overlay (owned nodes, allocated edges,
/// outermost radius). Built ONCE per allocation in the screen — never per
/// animation frame — so the hot paint path does no O(N) rescanning.
class TalentFxData {
  TalentFxData(this.tree, Set<String> owned) {
    final slots = <String>{};
    for (final id in owned) {
      slots.add(id);
      final node = tree.byId[id];
      if (node != null) slots.addAll(node.excludes);
    }
    for (final n in tree.nodes) {
      if (owned.contains(n.id)) {
        ownedNodes.add(n);
        if (n.dist > maxOwnedR) maxOwnedR = n.dist;
      }
    }
    // Allocated edges (owned↔owned, slot-aware) — the wave lights these.
    for (final n in ownedNodes) {
      for (final pid in n.prereq) {
        if (!slots.contains(pid)) continue;
        final p = tree.byId[pid];
        if (p != null) _ownedEdges.add(_Edge(p, n));
      }
    }
  }

  final TalentTree tree;
  final List<TalentDef> ownedNodes = [];
  final List<_Edge> _ownedEdges = [];
  double maxOwnedR = 0;
}

/// ANIMATED overlay: hub orb, owned-node glow (special → rotating sweep shader,
/// minor/root → pulse ring), and the energy wave over owned nodes + allocated
/// edges. Repaints from the three animation clocks but only touches owned
/// geometry (precomputed in [data]), so it stays cheap.
class TalentFxPainter extends CustomPainter {
  TalentFxPainter({
    required this.data,
    required this.pulse,
    required this.spin,
    required this.wave,
    required this.revision,
  });

  final TalentFxData data;
  final double pulse; // 0..1
  final double spin; // 0..1
  final double wave; // 0..1

  /// Allocation revision — owned geometry only changes when this changes.
  final int revision;

  // Reused paints — avoid per-node/per-edge/per-frame heap allocation.
  static final Paint _glowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final Paint _wavePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  static final Paint _bloomPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
  static final Paint _hubGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
  static final Paint _hubRingPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
  static final Paint _hubCorePaint = Paint();
  static final Paint _hubThinPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;

  @override
  void paint(Canvas canvas, Size size) {
    final hub = data.tree.hubCenter;
    Offset pos(TalentDef n) => Offset(hub + n.x, hub + n.y);
    final ang = spin * math.pi * 2;

    // ── Owned-node glow. Special nodes (few) get the rotating sweep shader;
    // the bulk minors get a cheap pulsing ring (no per-frame shader alloc).
    for (final n in data.ownedNodes) {
      final special = n.tier != TalentTier.minor && n.tier != TalentTier.root;
      final r = talentNodeSize(n.tier) / 2 - 2;
      final c = pos(n);
      final col = Color(n.colorArgb);
      if (special) {
        _glowPaint
          ..strokeWidth = 2.6 + 1.8
          ..shader = SweepGradient(
            transform: GradientRotation(ang),
            colors: [
              col.withValues(alpha: 0),
              col.withValues(alpha: 0.95),
              col.withValues(alpha: 0),
            ],
            stops: const [0.16, 0.5, 0.84],
          ).createShader(Rect.fromCircle(center: c, radius: r));
      } else {
        _glowPaint
          ..shader = null
          ..strokeWidth = 1.7 + 1.8
          ..color = col.withValues(alpha: 0.35 + 0.35 * pulse);
      }
      canvas.drawCircle(c, r, _glowPaint);
    }

    // ── Energy WAVE: a radial front travels outward, lighting owned nodes AND
    // the allocated connection lines it crosses (white-hot bead).
    if (data.ownedNodes.isNotEmpty) {
      final frontR = wave * (data.maxOwnedR + 90);
      const sigma = 60.0;

      for (final e in data._ownedEdges) {
        final lo = e.a.dist < e.b.dist ? e.a.dist : e.b.dist;
        final hi = e.a.dist < e.b.dist ? e.b.dist : e.a.dist;
        final dd = frontR < lo
            ? lo - frontR
            : (frontR > hi ? frontR - hi : 0.0);
        final g = math.exp(-(dd * dd) / (sigma * sigma));
        if (g < 0.06) continue;
        _wavePaint
          ..strokeWidth = 3.0 + 3.0 * g
          ..color = Color.lerp(
            Color(e.b.colorArgb),
            Colors.white,
            0.6,
          )!.withValues(alpha: 0.95 * g);
        canvas.drawLine(pos(e.a), pos(e.b), _wavePaint);
      }

      for (final n in data.ownedNodes) {
        final dd = (n.dist - frontR).abs();
        if (dd > 120) continue;
        final g = math.exp(-(dd * dd) / (sigma * sigma));
        if (g < 0.06) continue;
        _bloomPaint.color = Color(n.colorArgb).withValues(alpha: 0.65 * g);
        canvas.drawCircle(
          pos(n),
          talentNodeSize(n.tier) / 2 * (0.95 + 0.6 * g),
          _bloomPaint,
        );
      }
    }

    // ── Hub orb (base 48) ────────────────────────────────────────────────────
    _drawHub(canvas, Offset(hub, hub), pulse, ang);
  }

  void _drawHub(Canvas canvas, Offset c, double t, double ang) {
    const base = 48.0;
    // Outer glow.
    _hubGlowPaint.color = _essence.withValues(alpha: 0.16 + 0.12 * t);
    canvas.drawCircle(c, base * (0.55 + 0.18 * t), _hubGlowPaint);
    // Mid ring with rotating sweep.
    _hubRingPaint.shader = SweepGradient(
      transform: GradientRotation(ang),
      colors: [
        _essence.withValues(alpha: 0.0),
        _cyan.withValues(alpha: 0.7),
        _essence.withValues(alpha: 0.0),
        _violet.withValues(alpha: 0.7),
        _essence.withValues(alpha: 0.0),
      ],
      stops: const [0, 0.25, 0.5, 0.75, 1],
    ).createShader(Rect.fromCircle(center: c, radius: base * 0.5));
    canvas.drawCircle(c, base * 0.5, _hubRingPaint);
    // White-hot core.
    _hubCorePaint.color = Colors.white.withValues(alpha: 0.95);
    canvas.drawCircle(c, base * (0.16 + 0.03 * t), _hubCorePaint);
    // Thin ring.
    _hubThinPaint.color = _essence.withValues(alpha: 0.8);
    canvas.drawCircle(c, base * 0.26, _hubThinPaint);
  }

  @override
  bool shouldRepaint(covariant TalentFxPainter old) =>
      old.pulse != pulse ||
      old.spin != spin ||
      old.wave != wave ||
      old.revision != revision;
}

/// An allocated (owned↔owned) edge: prereq [a] → node [b].
class _Edge {
  const _Edge(this.a, this.b);
  final TalentDef a;
  final TalentDef b;
}

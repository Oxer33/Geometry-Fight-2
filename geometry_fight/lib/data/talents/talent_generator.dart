import 'dart:math' as math;

import 'talent_arm.dart';
import 'talent_def.dart';
import 'talent_effect.dart';

// ─── Lattice constants (reference spec, tuned to ~600 nodes for mobile) ──────
// Roots jut INWARD (radius < innerR) so they read as the only valid starts.
const double kRootRadius = 74;
const double kInnerRadius = 116; // clear ring around the hub
const double kRingSpacing = 52;
const double kTargetArc = 44; // px arc per slot ⇒ slots = round(2πR / arc)
const int kRingCount = 10; // 10 data rings ⇒ ~586 minor/notable slots

/// Rings whose nodes are "notable" (bigger). Deliberately OFF the fork tiers.
const Set<int> kNotableRings = {4, 8};

/// Ring numbers that host forks (5 tiers × 6 arms = 30 forks). Off notable
/// rings. The list order is the tier index used for per-tier scaling.
const List<int> kForkTiers = [3, 5, 6, 7, 9];

/// Design space is square and centered on the hub.
const double kDesignSize = 2200;
const double kHubCenter = kDesignSize / 2;

// Per fork-tier scaling (index 0..4 across [kForkTiers]).
const List<double> kForkPowerByTier = [0.07, 0.10, 0.13, 0.16, 0.20];
const List<double> kForkCdrByTier = [0.05, 0.07, 0.09, 0.11, 0.14];

const double _tau = math.pi * 2;
const double _sector = math.pi / 3; // 60° per arm

/// The fully-built talent web: nodes + id index + hub geometry.
class TalentTree {
  TalentTree({required this.nodes})
    : byId = {for (final n in nodes) n.id: n},
      neighbors = _buildNeighbors(nodes),
      hubCenter = kHubCenter,
      designSize = kDesignSize;

  final List<TalentDef> nodes;
  final Map<String, TalentDef> byId;

  /// UNDIRECTED adjacency from prereq edges: connectivity is bidirectional
  /// (PoE-style) — owning a node makes ALL its connected neighbours takeable,
  /// not only the ones further from the hub.
  final Map<String, Set<String>> neighbors;
  final double hubCenter;
  final double designSize;

  static Map<String, Set<String>> _buildNeighbors(List<TalentDef> nodes) {
    final m = <String, Set<String>>{};
    for (final n in nodes) {
      for (final p in n.prereq) {
        (m[n.id] ??= <String>{}).add(p);
        (m[p] ??= <String>{}).add(n.id);
      }
    }
    return m;
  }

  TalentDef? operator [](String id) => byId[id];

  /// Roots (the 6 valid start points).
  Iterable<TalentDef> get roots => nodes.where((n) => n.isRoot);

  /// All fork nodes.
  Iterable<TalentDef> get forks => nodes.where((n) => n.isFork);
}

TalentTree? _cached;

/// Build (and cache) the procedural talent web. Deterministic — no randomness,
/// so ids/positions are stable across launches and reproducible in tests.
TalentTree buildTalentTree() => _cached ??= _generate();

TalentTree _generate() {
  final nodes = <TalentDef>[];

  // Slot counts per ring (ring 0 = the 6 roots).
  final ringCounts = <int>[kArmCount];
  for (var r = 1; r <= kRingCount; r++) {
    final radius = kInnerRadius + r * kRingSpacing;
    final count = math.max(kArmCount, (_tau * radius / kTargetArc).round());
    ringCounts.add(count);
  }

  // ── Roots: mid-sector, jutting inward ────────────────────────────────────
  for (var a = 0; a < kArmCount; a++) {
    final arm = kTalentArms[a];
    final angle = (a + 0.5) * _sector;
    nodes.add(
      TalentDef(
        id: 'root$a',
        x: math.cos(angle) * kRootRadius,
        y: math.sin(angle) * kRootRadius,
        arm: a,
        colorArgb: arm.colorArgb,
        tier: TalentTier.root,
        effect: arm.primary,
        magnitude: baseMagnitudeFor(arm.primary),
        name: '${arm.name} Root',
        description: _describeStat(arm.primary, baseMagnitudeFor(arm.primary)),
      ),
    );
  }

  // ── Reserve fork slots: one per (forkTier, arm), nearest arm mid-sector ───
  // reserved['n{r}_{k}'] = (armIndex, tierIndex).
  final reserved = <String, List<int>>{};
  for (var ti = 0; ti < kForkTiers.length; ti++) {
    final r = kForkTiers[ti];
    final count = ringCounts[r];
    for (var a = 0; a < kArmCount; a++) {
      final mid = (a + 0.5) * _sector;
      final k = (mid / (_tau / count)).round() % count;
      reserved['n${r}_$k'] = [a, ti];
    }
  }

  // ── Ring slots (minors + notables), skipping reserved fork slots ──────────
  for (var r = 1; r <= kRingCount; r++) {
    final count = ringCounts[r];
    final radius = kInnerRadius + r * kRingSpacing;
    final isNotableRing = kNotableRings.contains(r);
    for (var s = 0; s < count; s++) {
      final id = 'n${r}_$s';
      if (reserved.containsKey(id)) continue; // fork fills this slot

      final angle = s * (_tau / count);
      final a = (angle / _sector).floor() % kArmCount;
      final arm = kTalentArms[a];
      final pool = arm.pool;
      // Scatter pick (NOT slot%len) so an arm sector isn't a monotone line.
      final pick = (r * 7 + s * 13 + a * 5) % pool.length;
      final effect = pool[pick];
      final mag =
          baseMagnitudeFor(effect) * (isNotableRing ? kNotableMagnitudeMul : 1);

      // Variety: notables always — and ~1/3 of minors — carry a small secondary
      // stat (≠ primary), so consecutive nodes feel different.
      final extras = <TalentStat>[];
      if (isNotableRing || (r * 3 + s) % 3 == 0) {
        // Scan all offsets until a DISTINCT effect is found (a 2-try limit
        // could silently emit nothing when the primary fills consecutive pool
        // slots, e.g. massacre's three atkPct entries).
        for (var off = 1; off < pool.length; off++) {
          final sec = pool[(pick + off + r) % pool.length];
          if (sec != effect) {
            extras.add(
              TalentStat(sec, baseMagnitudeFor(sec) * (isNotableRing ? 2 : 1)),
            );
            break;
          }
        }
      }

      final desc = [
        _describeStat(effect, mag),
        for (final e in extras) _describeStat(e.effect, e.magnitude),
      ].join(' · ');

      nodes.add(
        TalentDef(
          id: id,
          x: math.cos(angle) * radius,
          y: math.sin(angle) * radius,
          arm: a,
          colorArgb: arm.colorArgb,
          tier: isNotableRing ? TalentTier.notable : TalentTier.minor,
          effect: effect,
          magnitude: mag,
          extraStats: extras,
          prereq: _prereqFor(r, s, a, count, ringCounts),
          name: isNotableRing
              ? '${talentEffectName(effect)} (Notable)'
              : talentEffectName(effect),
          description: desc,
        ),
      );
    }
  }

  // ── Forks: two TalentDefs at the reserved slot, mutually exclusive ────────
  final fxList = AbilityFx.values;
  reserved.forEach((slotId, meta) {
    final a = meta[0];
    final ti = meta[1];
    final r = kForkTiers[ti];
    final count = ringCounts[r];
    final s = int.parse(slotId.split('_')[1]);
    final angle = s * (_tau / count);
    final radius = kInnerRadius + r * kRingSpacing;
    final arm = kTalentArms[a];
    final prereq = _prereqFor(r, s, a, count, ringCounts);

    final sGlobal = ti * kArmCount + a; // 0..29
    final fxA = fxList[sGlobal % fxList.length];
    var fxB = fxList[(sGlobal + 1 + sGlobal ~/ fxList.length) % fxList.length];
    if (fxB == fxA) fxB = fxList[(fxList.indexOf(fxA) + 1) % fxList.length];

    final sp = kForkPowerByTier[ti];
    final cdr = kForkCdrByTier[ti];
    final idA = slotId; // option A reuses the slot id
    final idB = '${slotId}_x'; // option B hidden twin, same position

    nodes.add(
      TalentDef(
        id: idA,
        x: math.cos(angle) * radius,
        y: math.sin(angle) * radius,
        arm: a,
        colorArgb: arm.colorArgb,
        tier: TalentTier.fork,
        effect: TalentEffect.skillPower,
        magnitude: sp,
        prereq: prereq,
        excludes: [idB],
        empowers: fxA,
        empowerCdr: cdr,
        name: 'Empower: ${abilityFxName(fxA)}',
        description: _describeFork(fxA, sp, cdr),
      ),
    );
    nodes.add(
      TalentDef(
        id: idB,
        x: math.cos(angle) * radius,
        y: math.sin(angle) * radius,
        arm: a,
        colorArgb: arm.colorArgb,
        tier: TalentTier.fork,
        effect: TalentEffect.skillPower,
        magnitude: sp,
        prereq: prereq,
        excludes: [idA],
        empowers: fxB,
        empowerCdr: cdr,
        name: 'Empower: ${abilityFxName(fxB)}',
        description: _describeFork(fxB, sp, cdr),
      ),
    );
  });

  // ── Keystones: one per arm, beyond the great circle (arm end) ─────────────
  final outerCount = ringCounts[kRingCount];
  for (var a = 0; a < kArmCount; a++) {
    final arm = kTalentArms[a];
    final angle = (a + 0.5) * _sector;
    final radius = kInnerRadius + (kRingCount + 1) * kRingSpacing;
    final extras = _keystoneExtras(arm);
    final primaryMag = baseMagnitudeFor(arm.primary) * kKeystoneMagnitudeMul;
    // Prereq: the two outer-ring slots nearest the arm's mid angle. Base ids
    // `n{r}_{k}` are slot-aware (a reserved fork slot's option A shares the id).
    final nearest = (angle / (_tau / outerCount)).round() % outerCount;
    final prereq = <String>[
      'n${kRingCount}_$nearest',
      'n${kRingCount}_${(nearest + 1) % outerCount}',
    ];
    final stats = [
      _describeStat(arm.primary, primaryMag),
      for (final e in extras) _describeStat(e.effect, e.magnitude),
    ].join(' · ');
    nodes.add(
      TalentDef(
        id: 'keystone$a',
        x: math.cos(angle) * radius,
        y: math.sin(angle) * radius,
        arm: a,
        colorArgb: arm.colorArgb,
        tier: TalentTier.keystone,
        effect: arm.primary,
        magnitude: primaryMag,
        prereq: prereq,
        extraStats: extras,
        name: '${arm.name} Keystone',
        description: stats,
      ),
    );
  }

  return TalentTree(nodes: nodes);
}

/// Prerequisites for slot (r,s): inward spoke + ring-loop + (even s) diagonal.
/// Ids reference the base slot id `n{r}_{k}` — which for a fork slot is option
/// A's id; `TalentService.ownsSlot` makes either option satisfy it.
List<String> _prereqFor(int r, int s, int arm, int count, List<int> counts) {
  final out = <String>{};
  final angle = s * (_tau / count);

  if (r == 1) {
    out.add('root$arm'); // inward spoke → own arm's root
    if (s.isEven) {
      out.add('root${(arm + 1) % kArmCount}'); // diagonal → neighbor root
    }
  } else {
    final lower = counts[r - 1];
    final near = (angle / (_tau / lower)).round() % lower;
    out.add('n${r - 1}_$near'); // inward spoke
    if (s.isEven) {
      out.add('n${r - 1}_${(near + 1) % lower}'); // diagonal
    }
  }
  // Ring-loop → previous slot on same ring.
  out.add('n${r}_${(s - 1 + count) % count}');
  return out.toList();
}

/// Two distinct extra stats for a keystone (≠ primary), to bundle ≥3 stats.
List<TalentStat> _keystoneExtras(TalentArm arm) {
  const fallback = [
    TalentEffect.shieldDuration,
    TalentEffect.critChance,
    TalentEffect.fireRate,
    TalentEffect.moveSpeed,
    TalentEffect.atkPct,
  ];
  final picks = <TalentEffect>[];
  for (final e in [...arm.pool, ...fallback]) {
    if (e == arm.primary || picks.contains(e)) continue;
    picks.add(e);
    if (picks.length == 2) break;
  }
  return [for (final e in picks) TalentStat(e, baseMagnitudeFor(e) * 8)];
}

String _describeStat(TalentEffect e, double mag) {
  if (e == TalentEffect.shieldDuration) {
    return '+${mag.toStringAsFixed(1)}s ${talentEffectName(e)}';
  }
  if (isPercentEffect(e)) {
    return '+${(mag * 100).round()}% ${talentEffectName(e)}';
  }
  return '+${mag.round()} ${talentEffectName(e)}';
}

String _describeFork(AbilityFx fx, double sp, double cdr) =>
    'Empower ${abilityFxName(fx)}: +${(sp * 100).round()}% power, '
    '−${(cdr * 100).round()}% cooldown';

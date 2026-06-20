import 'dart:math' as math;

import 'talent_effect.dart';

/// Visual/gameplay tier of a node. Drives shape, size and magnitude.
enum TalentTier { root, minor, notable, keystone, fork }

/// A single (effect, magnitude) grant. Keystones bundle several.
class TalentStat {
  const TalentStat(this.effect, this.magnitude);
  final TalentEffect effect;
  final double magnitude;
}

/// Immutable definition of one talent node in the web.
///
/// [x]/[y] are offsets from the hub center (design space is centered on the
/// hub). Edges are implied by [prereq]: an edge is drawn between this node and
/// each id it lists. [excludes] holds the mutually-exclusive fork sibling(s).
class TalentDef {
  TalentDef({
    required this.id,
    required this.x,
    required this.y,
    required this.arm,
    required this.colorArgb,
    required this.tier,
    required this.effect,
    required this.magnitude,
    this.prereq = const [],
    this.excludes = const [],
    this.empowers,
    this.empowerCdr = 0.0,
    this.extraStats = const [],
    required this.name,
    required this.description,
  }) : dist = math.sqrt(x * x + y * y);

  final String id;

  /// Offset from hub center.
  final double x;
  final double y;

  /// Owning arm 0..5.
  final int arm;

  /// Accent color 0xAARRGGBB (arm color; forks may tint).
  final int colorArgb;

  final TalentTier tier;

  /// Primary effect granted.
  final TalentEffect effect;

  /// Magnitude of [effect] (fraction for %, px for magnet; for forks this is
  /// the skill-power fraction applied to [empowers]).
  final double magnitude;

  /// Prerequisite node ids. Unlock flows outward from the hub: this node is
  /// unlockable once ANY prereq's slot is owned (slot-aware — see
  /// `TalentService.ownsSlot`).
  final List<String> prereq;

  /// Mutually-exclusive sibling ids (forks). Symmetric.
  final List<String> excludes;

  /// Fork only: the ability this node empowers.
  final AbilityFx? empowers;

  /// Fork only: cooldown reduction fraction for [empowers].
  final double empowerCdr;

  /// Keystone only: extra (effect, magnitude) grants beyond [effect].
  final List<TalentStat> extraStats;

  /// English-fallback display name.
  final String name;

  /// English-fallback effect description.
  final String description;

  /// Distance from hub center (cached, for the energy-wave front).
  final double dist;

  bool get isRoot => tier == TalentTier.root;
  bool get isFork => tier == TalentTier.fork;
  bool get isKeystone => tier == TalentTier.keystone;
  bool get isNotable => tier == TalentTier.notable;

  /// All (effect, magnitude) grants this node folds into stats: the primary
  /// plus any keystone [extraStats]. Forks contribute via skill-power maps, not
  /// here, so they return empty.
  List<TalentStat> get stats {
    if (isFork) return const [];
    return [TalentStat(effect, magnitude), ...extraStats];
  }
}

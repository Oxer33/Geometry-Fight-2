import 'talent_effect.dart';

/// One of the 6 radiating "arms" of the talent web. Each arm owns an accent
/// color, a theme, a primary effect (used by its keystone) and a pool of
/// effects its minor/notable nodes draw from.
///
/// Palette/themes follow the reference spec, but the two originally defensive
/// arms (Immortal=maxHp, Aegis=def) are re-themed to offense/utility because
/// this game has NO hp/defense talents (one-shot design):
///   - magenta `Onslaught` → attack speed (was Immortal/maxHp)
///   - violet  `Arsenal`   → cooldown + empower (was Aegis/def)
class TalentArm {
  const TalentArm({
    required this.index,
    required this.id,
    required this.name,
    required this.colorArgb,
    required this.theme,
    required this.primary,
    required this.pool,
  });

  /// 0..5, matches the angular sector the arm occupies.
  final int index;
  final String id;

  /// English-fallback display name.
  final String name;

  /// Accent color as 0xAARRGGBB.
  final int colorArgb;

  /// Short English-fallback theme label.
  final String theme;

  /// Effect a keystone of this arm leads with.
  final TalentEffect primary;

  /// Effects the arm's minor/notable nodes cycle through.
  final List<TalentEffect> pool;
}

/// The 6 arms, in angular order (arm `i` centers on angle `i·60°`).
const List<TalentArm> kTalentArms = [
  // Pools are WEIGHTED by repetition: the arm's identity effect appears most,
  // with cross-stats sprinkled so a whole sector isn't a monotone line. The
  // generator picks per-node via a scatter hash (not slot%len), and ~1/3 of
  // minors carry a small secondary stat for texture.
  TalentArm(
    index: 0,
    id: 'annihilation',
    name: 'Annihilation',
    colorArgb: 0xFFFFB23A, // amber
    theme: 'Offense',
    primary: TalentEffect.bombRadius,
    pool: [
      TalentEffect.bombRadius,
      TalentEffect.shieldDuration,
      TalentEffect.shieldDuration,
      TalentEffect.atkPct,
      TalentEffect.critDmg,
    ],
  ),
  TalentArm(
    index: 1,
    id: 'deadeye',
    name: 'Deadeye',
    colorArgb: 0xFF4FA8FF, // blue
    theme: 'Crit',
    primary: TalentEffect.critDmg,
    pool: [
      TalentEffect.critChance,
      TalentEffect.critChance,
      TalentEffect.critDmg,
      TalentEffect.critDmg,
      TalentEffect.atkPct,
    ],
  ),
  TalentArm(
    index: 2,
    id: 'massacre',
    name: 'Massacre',
    colorArgb: 0xFFFF4D6D, // red
    theme: 'Raw Damage',
    primary: TalentEffect.atkPct,
    pool: [
      TalentEffect.atkPct,
      TalentEffect.atkPct,
      TalentEffect.atkPct,
      TalentEffect.shieldDuration,
      TalentEffect.fireRate,
      TalentEffect.critChance,
    ],
  ),
  TalentArm(
    index: 3,
    id: 'onslaught',
    name: 'Onslaught',
    colorArgb: 0xFFE45BD0, // magenta
    theme: 'Attack Speed',
    primary: TalentEffect.fireRate,
    pool: [
      TalentEffect.fireRate,
      TalentEffect.fireRate,
      TalentEffect.atkPct,
      TalentEffect.moveSpeed,
      TalentEffect.critChance,
    ],
  ),
  TalentArm(
    index: 4,
    id: 'arsenal',
    name: 'Arsenal',
    colorArgb: 0xFF8B5CF6, // violet
    theme: 'Cooldown',
    primary: TalentEffect.cooldown,
    pool: [
      TalentEffect.cooldown,
      TalentEffect.cooldown,
      TalentEffect.fireRate,
      TalentEffect.bombRadius,
      TalentEffect.critDmg,
    ],
  ),
  TalentArm(
    index: 5,
    id: 'ascendant',
    name: 'Ascendant',
    colorArgb: 0xFF49E5A6, // green
    theme: 'Utility',
    primary: TalentEffect.moveSpeed,
    pool: [
      TalentEffect.moveSpeed,
      TalentEffect.moveSpeed,
      TalentEffect.goldFind,
      TalentEffect.essenceFind,
      TalentEffect.magnet,
      TalentEffect.cooldown,
    ],
  ),
];

const int kArmCount = 6;

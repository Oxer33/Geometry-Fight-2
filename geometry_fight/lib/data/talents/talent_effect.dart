/// Talent effect taxonomy and the empowerable ability list.
///
/// PURE DATA — no Flutter/UI imports. The talent web is generated and folded
/// into gameplay stats through these enums.
///
/// Design constraint (utente): il gioco è "one-shot" — se il player viene
/// toccato muore. Quindi NON esistono nodi HP / vite / difesa / damage-taken
/// reduction. Tutti gli effetti sono offesa, crit, velocità, cooldown o
/// "find" (gold/xp/magnete). Ogni nodo minore dà comunque un piccolo upgrade
/// (es. +1% crit chance).
library;

/// The distinct stat a talent node grants. Magnitudes are interpreted by
/// [TalentService] when folding owned talents into the character's stats:
/// percentage effects use a fraction (0.01 == +1%), pixel effects use raw px.
enum TalentEffect {
  /// % weapon damage — Massacre arm. Displayed as "Damage".
  atkPct,

  /// +seconds of post-death shield: after losing a life (lives remaining > 0)
  /// the player gets a temporary invulnerability shield. Replaces the old,
  /// redundant global-damage stat.
  shieldDuration,

  /// +crit chance (fraction) — Deadeye arm.
  critChance,

  /// +crit damage multiplier (fraction added on top of the base ×2.2) —
  /// Deadeye arm.
  critDmg,

  /// % attack speed / fire-rate — Onslaught arm.
  fireRate,

  /// % move speed — Ascendant arm.
  moveSpeed,

  /// Global cooldown reduction (fraction) — Arsenal arm. Applies to dash and
  /// other timed abilities.
  cooldown,

  /// % more gold/geom earned at run end — Ascendant arm.
  goldFind,

  /// % more XP earned (faster levelling → more talent points) — Ascendant arm.
  essenceFind,

  /// +magnet pickup range in px — Ascendant arm.
  magnet,

  /// % bomb blast radius — Annihilation arm.
  bombRadius,

  /// Empower a single ability (fork nodes only). Carries [TalentDef.empowers]
  /// and [TalentDef.empowerCdr]. Visually/semantically distinct from the plain
  /// stat minors around it.
  skillPower,
}

/// Abilities that a fork node can empower (power and/or cooldown). Excludes
/// power-up-only weapons (spreadFan, overdrive) and any heal/mend fx (none
/// here). Mapped from `WeaponType` via `fxForWeapon`.
enum AbilityFx {
  weaponBasic,
  weaponSpread,
  weaponTriple,
  weaponRicochet,
  weaponLaser,
  weaponPlasma,
  weaponHoming,
  weaponGauss,
  weaponChain,
  weaponShotgun,
  weaponRailgun,
  dash,
  bomb,
}

/// English-fallback display name for an [AbilityFx]. UI may override via i18n.
String abilityFxName(AbilityFx fx) => switch (fx) {
  AbilityFx.weaponBasic => 'Basic Cannon',
  AbilityFx.weaponSpread => 'Spread',
  AbilityFx.weaponTriple => 'Triple',
  AbilityFx.weaponRicochet => 'Ricochet',
  AbilityFx.weaponLaser => 'Laser',
  AbilityFx.weaponPlasma => 'Plasma',
  AbilityFx.weaponHoming => 'Homing',
  AbilityFx.weaponGauss => 'Gauss',
  AbilityFx.weaponChain => 'Chain Lightning',
  AbilityFx.weaponShotgun => 'Shotgun',
  AbilityFx.weaponRailgun => 'Railgun',
  AbilityFx.dash => 'Dash',
  AbilityFx.bomb => 'Bomb',
};

/// Stable string key for an [AbilityFx] (persistence / map keys).
String abilityFxKey(AbilityFx fx) => fx.name;

/// English-fallback display name for a [TalentEffect].
String talentEffectName(TalentEffect e) => switch (e) {
  TalentEffect.atkPct => 'Damage',
  TalentEffect.shieldDuration => 'Shield Duration',
  TalentEffect.critChance => 'Crit Chance',
  TalentEffect.critDmg => 'Crit Damage',
  TalentEffect.fireRate => 'Fire Rate',
  TalentEffect.moveSpeed => 'Move Speed',
  TalentEffect.cooldown => 'Cooldown',
  TalentEffect.goldFind => 'Gold Find',
  TalentEffect.essenceFind => 'XP Find',
  TalentEffect.magnet => 'Magnet',
  TalentEffect.bombRadius => 'Bomb Radius',
  TalentEffect.skillPower => 'Empower',
};

/// Base (minor-node) magnitude per effect. Notable nodes multiply this by
/// [kNotableMagnitudeMul]; keystones by [kKeystoneMagnitudeMul].
double baseMagnitudeFor(TalentEffect e) => switch (e) {
  TalentEffect.atkPct => 0.01, // +1%
  TalentEffect.shieldDuration => 0.1, // +0.1s post-death shield
  TalentEffect.critChance => 0.01,
  TalentEffect.critDmg => 0.02, // +2% crit dmg
  TalentEffect.fireRate => 0.01,
  TalentEffect.moveSpeed => 0.01,
  TalentEffect.cooldown => 0.01,
  TalentEffect.goldFind => 0.02,
  TalentEffect.essenceFind => 0.02,
  TalentEffect.magnet => 6.0, // +6px
  TalentEffect.bombRadius => 0.01,
  TalentEffect.skillPower => 0.0, // forks carry their own magnitude
};

/// Notable nodes are ~4× a minor.
const double kNotableMagnitudeMul = 4.0;

/// Keystones are ~22× a minor and bundle two extra stats.
const double kKeystoneMagnitudeMul = 22.0;

/// Whether an effect's magnitude is a percentage fraction (for UI `%`
/// formatting) vs a raw value (magnet px, shield seconds).
bool isPercentEffect(TalentEffect e) =>
    e != TalentEffect.magnet && e != TalentEffect.shieldDuration;

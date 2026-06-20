import 'talent_effect.dart';
import 'talent_generator.dart';

/// Aggregated, gameplay-ready stat bonuses folded from a set of owned talents.
/// Percentage fields are fractions (0.05 == +5%); [magnet] is raw px. The two
/// maps hold per-ability empower bonuses contributed by fork nodes.
class TalentStats {
  const TalentStats({
    this.atkPct = 0,
    this.shieldDuration = 0,
    this.critChance = 0,
    this.critDmg = 0,
    this.fireRate = 0,
    this.moveSpeed = 0,
    this.cooldown = 0,
    this.goldFind = 0,
    this.essenceFind = 0,
    this.magnet = 0,
    this.bombRadius = 0,
    this.skillPowerByFx = const {},
    this.skillCdrByFx = const {},
  });

  final double atkPct;
  final double shieldDuration;
  final double critChance;
  final double critDmg;
  final double fireRate;
  final double moveSpeed;
  final double cooldown;
  final double goldFind;
  final double essenceFind;
  final double magnet;
  final double bombRadius;
  final Map<AbilityFx, double> skillPowerByFx;
  final Map<AbilityFx, double> skillCdrByFx;

  static const empty = TalentStats();

  double skillPower(AbilityFx fx) => skillPowerByFx[fx] ?? 0;
  double skillCdr(AbilityFx fx) => skillCdrByFx[fx] ?? 0;

  /// Convenience accessors so the data layer can fold dash/bomb empower without
  /// importing [AbilityFx] at the call site.
  double get dashCdr => skillCdr(AbilityFx.dash);
  double get bombPower => skillPower(AbilityFx.bomb);
}

/// Fold a set of owned talent node ids into a single [TalentStats]. Unknown
/// ids are ignored (defensive against stale saves after a re-generation).
TalentStats foldTalents(List<String> ownedIds) {
  if (ownedIds.isEmpty) return TalentStats.empty;
  final tree = buildTalentTree();

  var atkPct = 0.0,
      shieldDuration = 0.0,
      critChance = 0.0,
      critDmg = 0.0,
      fireRate = 0.0,
      moveSpeed = 0.0,
      cooldown = 0.0,
      goldFind = 0.0,
      essenceFind = 0.0,
      magnet = 0.0,
      bombRadius = 0.0;
  final powerByFx = <AbilityFx, double>{};
  final cdrByFx = <AbilityFx, double>{};

  for (final id in ownedIds) {
    final node = tree.byId[id];
    if (node == null) continue;

    if (node.isFork) {
      final fx = node.empowers!;
      powerByFx[fx] = (powerByFx[fx] ?? 0) + node.magnitude;
      cdrByFx[fx] = (cdrByFx[fx] ?? 0) + node.empowerCdr;
      continue;
    }

    for (final s in node.stats) {
      switch (s.effect) {
        case TalentEffect.atkPct:
          atkPct += s.magnitude;
        case TalentEffect.shieldDuration:
          shieldDuration += s.magnitude;
        case TalentEffect.critChance:
          critChance += s.magnitude;
        case TalentEffect.critDmg:
          critDmg += s.magnitude;
        case TalentEffect.fireRate:
          fireRate += s.magnitude;
        case TalentEffect.moveSpeed:
          moveSpeed += s.magnitude;
        case TalentEffect.cooldown:
          cooldown += s.magnitude;
        case TalentEffect.goldFind:
          goldFind += s.magnitude;
        case TalentEffect.essenceFind:
          essenceFind += s.magnitude;
        case TalentEffect.magnet:
          magnet += s.magnitude;
        case TalentEffect.bombRadius:
          bombRadius += s.magnitude;
        case TalentEffect.skillPower:
          break; // only forks carry skillPower, handled above
      }
    }
  }

  return TalentStats(
    atkPct: atkPct,
    shieldDuration: shieldDuration,
    critChance: critChance,
    critDmg: critDmg,
    fireRate: fireRate,
    moveSpeed: moveSpeed,
    cooldown: cooldown,
    goldFind: goldFind,
    essenceFind: essenceFind,
    magnet: magnet,
    bombRadius: bombRadius,
    skillPowerByFx: powerByFx,
    skillCdrByFx: cdrByFx,
  );
}

/// Cosmetic: a node id that is a fork twin (option B) ends with `_x`.
bool isForkTwinId(String id) => id.endsWith('_x');

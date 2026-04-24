enum EnemyType {
  drone,
  snake,
  mine,
  spawner,
  weaver,
  splitter,
  shieldEnemy,
  blackHole,
  kamikaze,
  // New enemy types
  pulsar,
  mirror,
  phantom,
  vortex,
  leech,
  titan,
  glitch,
  healer,
  orbiter,
  siren,
  necro,
  tesla,
  gravityWell,
  swarmDrone,
  laserTurret,
  timeBomb,
  decoy,
  // GW:RE2 mechanics
  gate,     // Gate: due sfere + linea, player ci passa attraverso → esplosione
  proton,   // Proton: mini nemico veloce da esplosione buco nero
  mutator,  // Mutator: potenzia altri nemici al contatto
}

enum BossType {
  theGrid,
  hydra,
  singularity,
  swarmMother,
  // New bosses
  theArchitect,
  chronoWraith,
  nexusPrime,
  voidReaper,
  teslaLord,
  phantomKing,
  omegaCore,
  // Batch 3 bosses
  mirrorMaster,
  swarmQueen,
  graviton,
  inferno,
  eternityEngine,
  // Batch 4 — 4 nuovi boss (richiesta utente: "aggiungere 4 nuovi boss con
  // meccaniche uniche, FX spettacolari") per coprire i 20 slot boss della
  // modalità classica (ogni wave multipla di 5).
  crimsonCrown,    // wave 5   — orbi fuoco + lava mines
  prismHunter,     // wave 15  — laser sweeping + rainbow bullet hell
  voidKraken,      // wave 25  — gravity pull + ink cloud + proton spawn
  astralSentinel,  // wave 35  — poligono laser + star constellation gate
}

class WaveSpawn {
  final EnemyType type;
  final int count;
  final double delay; // seconds before this group spawns

  const WaveSpawn(this.type, this.count, {this.delay = 0});
}

class WaveConfig {
  final int waveNumber;
  final List<WaveSpawn> spawns;
  final BossType? boss;

  const WaveConfig({
    required this.waveNumber,
    required this.spawns,
    this.boss,
  });
}

// ═══════════════════════════════════════════════════════════════════════
// BOSS PLACEMENT — richiesta utente: un boss ad ogni wave multipla di 5.
// 100 waves / 5 = 20 slot boss. 16 boss esistenti + 4 nuovi = 20 esatti.
// Ordine scelto per escalation di difficoltà (boss più dinamici prima,
// boss "bullet hell" e finali nelle wave alte).
// ═══════════════════════════════════════════════════════════════════════
const Map<int, BossType> _classicBossSchedule = {
  5: BossType.crimsonCrown,    // NEW — primo boss "tutorial" meccanico
  10: BossType.theGrid,
  15: BossType.prismHunter,     // NEW — sweeping laser
  20: BossType.hydra,
  25: BossType.voidKraken,      // NEW — gravity pull
  30: BossType.singularity,
  35: BossType.astralSentinel,  // NEW — constellation gate
  40: BossType.swarmMother,
  45: BossType.theArchitect,
  50: BossType.chronoWraith,
  55: BossType.nexusPrime,
  60: BossType.voidReaper,
  65: BossType.teslaLord,
  70: BossType.phantomKing,
  75: BossType.omegaCore,
  80: BossType.mirrorMaster,
  85: BossType.swarmQueen,
  90: BossType.graviton,
  95: BossType.inferno,
  100: BossType.eternityEngine,
};

// Spawn "entourage" pre-boss. Wave bassi (5-50) = piccoli entourage leggeri
// per non lasciare l'arena sterile durante il boss fight. Wave alti (55+) =
// entourage pesanti già presenti.
const Map<int, List<WaveSpawn>> _bossEntourageSpawns = {
  // Early bosses entourage (leggero, per varietà).
  5: [WaveSpawn(EnemyType.drone, 8, delay: 3)],
  15: [WaveSpawn(EnemyType.kamikaze, 6, delay: 3)],
  25: [WaveSpawn(EnemyType.weaver, 6, delay: 3)],
  35: [WaveSpawn(EnemyType.swarmDrone, 20, delay: 3)],
  45: [WaveSpawn(EnemyType.shieldEnemy, 4, delay: 3)],
  50: [WaveSpawn(EnemyType.splitter, 4), WaveSpawn(EnemyType.snake, 4, delay: 3)],
  // Mid/late bosses entourage (preservati).
  55: [WaveSpawn(EnemyType.tesla, 6), WaveSpawn(EnemyType.orbiter, 8, delay: 2)],
  60: [WaveSpawn(EnemyType.healer, 4), WaveSpawn(EnemyType.siren, 6, delay: 2)],
  65: [WaveSpawn(EnemyType.tesla, 10), WaveSpawn(EnemyType.necro, 4, delay: 3)],
  70: [WaveSpawn(EnemyType.phantom, 8), WaveSpawn(EnemyType.glitch, 6, delay: 2)],
  75: [WaveSpawn(EnemyType.titan, 6), WaveSpawn(EnemyType.healer, 4, delay: 3)],
  80: [WaveSpawn(EnemyType.mirror, 8), WaveSpawn(EnemyType.decoy, 10, delay: 2)],
  85: [WaveSpawn(EnemyType.swarmDrone, 40), WaveSpawn(EnemyType.healer, 4, delay: 3)],
  90: [WaveSpawn(EnemyType.gravityWell, 4), WaveSpawn(EnemyType.blackHole, 2, delay: 4)],
  95: [WaveSpawn(EnemyType.kamikaze, 20), WaveSpawn(EnemyType.timeBomb, 6, delay: 3)],
  100: [
    WaveSpawn(EnemyType.titan, 8),
    WaveSpawn(EnemyType.tesla, 10, delay: 2),
    WaveSpawn(EnemyType.healer, 6, delay: 4)
  ],
};

List<WaveConfig> generateWaveConfigs() {
  final configs = <WaveConfig>[];
  // Ring buffer ultimi 3 archetipi scelti → no ripetizione consecutiva.
  final history = <int>[];

  for (int wave = 1; wave <= 100; wave++) {
    // Boss wave: ogni wave multipla di 5.
    final bossType = _classicBossSchedule[wave];
    if (bossType != null) {
      configs.add(WaveConfig(
        waveNumber: wave,
        spawns: _bossEntourageSpawns[wave] ?? const [],
        boss: bossType,
      ));
      continue;
    }

    // ═══════════════════════════════════════════════════════════════
    // ARCHETYPE SYSTEM (ispirato GW2:RE Sequence): 31 archetipi con 4
    // tier di difficoltà, random weighted per wave. Varietà massima
    // + escalation graduale + climax pre-boss (MEGASWARM tier 3+).
    // ═══════════════════════════════════════════════════════════════
    final archetype = _pickArchetype(wave, history);
    final spawns = archetype.generator(wave);

    // Gate hazard raro: 1 ogni 10 wave non-boss (11, 21, 31, ...).
    if (wave >= 11 && wave % 10 == 1) {
      spawns.add(WaveSpawn(EnemyType.gate, 1, delay: 10));
    }

    configs.add(WaveConfig(waveNumber: wave, spawns: spawns));
  }

  return configs;
}

/// Archetype: blueprint per generare gli spawn di una wave non-boss.
class _Archetype {
  final String name;
  final int tier; // 1=facile, 4=nightmare
  final List<WaveSpawn> Function(int wave) generator;
  const _Archetype(this.name, this.tier, this.generator);
}

/// Picker weighted per tier. Regole:
/// - Wave 1 = CARDINAL QUARTET fisso (onboarding).
/// - Wave %5 == 4 (pre-boss) = forced MEGASWARM/STORM/HELL (climax).
/// - Tier range scala col wave: 1-10 → t1-2; 11-25 → t1-2;
///   26-45 → t2-3; 46+ → t2-4.
/// - No ripetizione ultimi 3 archetipi (history ring buffer).
_Archetype _pickArchetype(int wave, List<int> history) {
  if (wave == 1) {
    final idx = _archetypes.indexWhere((a) => a.name == 'CARDINAL QUARTET');
    _pushHistory(history, idx);
    return _archetypes[idx];
  }

  final maxTier = wave <= 10
      ? 2
      : wave <= 25
          ? 2
          : wave <= 45
              ? 3
              : 4;
  // Pre-boss climax (MEGASWARM forzato) solo se maxTier ≥ 3 (wave > 25).
  // BUG CRITICO: prima wave 4 (pre-boss boss 5) forzava minTier=3 ma
  // maxTier=2 → pool vuoto → pool[% 0] IntegerDivisionByZeroException
  // durante generateWaveConfigs() → game crash → schermo bianco.
  final isPreBoss = wave % 5 == 4 && maxTier >= 3;
  final minTier = isPreBoss ? 3 : (wave <= 25 ? 1 : 2);

  final pool = <int>[];
  for (int i = 0; i < _archetypes.length; i++) {
    final a = _archetypes[i];
    if (a.tier < minTier || a.tier > maxTier) continue;
    if (history.contains(i)) continue;
    if (isPreBoss &&
        !(a.name.contains('MEGASWARM') ||
            a.name.contains('STORM') ||
            a.name.contains('HELL'))) {
      continue;
    }
    pool.add(i);
  }
  if (pool.isEmpty) {
    history.clear();
    for (int i = 0; i < _archetypes.length; i++) {
      final a = _archetypes[i];
      if (a.tier >= minTier && a.tier <= maxTier) pool.add(i);
    }
  }
  // Emergency fallback: se ancora vuoto (configurazione degenere),
  // usa CARDINAL QUARTET invece di crashare con % 0.
  if (pool.isEmpty) {
    final idx = _archetypes.indexWhere((a) => a.name == 'CARDINAL QUARTET');
    _pushHistory(history, idx);
    return _archetypes[idx];
  }

  // Pseudo-random deterministico sul wave number: riproducibile,
  // varia per-wave, history previene ripetizioni.
  final pickIdx = pool[(wave * 2654435761) % pool.length];
  _pushHistory(history, pickIdx);
  return _archetypes[pickIdx];
}

void _pushHistory(List<int> h, int idx) {
  h.add(idx);
  if (h.length > 3) h.removeAt(0);
}

// ═══════════════════════════════════════════════════════════════════════
// ARCHETYPE LIBRARY — 31 archetipi (tier 1-4) ispirati GW2:RE Sequence.
// Tier 1: onboarding/easy (wave 1-15).
// Tier 2: mix mid, posizionamento richiesto (wave 10-35).
// Tier 3: MEGASWARM/climax, 1 tipo in massa + contorno (wave 25-55).
// Tier 4: nightmare, meccaniche ostili combinate (wave 45+).
// ═══════════════════════════════════════════════════════════════════════
final List<_Archetype> _archetypes = [
  // ─── TIER 1 ─────────────────────────────────────────────────────────
  _Archetype('CARDINAL QUARTET', 1, (w) => [
        WaveSpawn(EnemyType.drone, 4, delay: 0),
        WaveSpawn(EnemyType.drone, (12 + w).clamp(12, 30), delay: 3.0),
      ]),
  _Archetype('INCOMING RUSH', 1, (w) => [
        WaveSpawn(EnemyType.drone, (20 + w * 2).clamp(20, 50), delay: 0.3),
        WaveSpawn(EnemyType.kamikaze, (6 + w).clamp(6, 20), delay: 2.0),
      ]),
  _Archetype('GENTLE SWEEP', 1, (w) => [
        WaveSpawn(EnemyType.weaver, (10 + w).clamp(10, 25), delay: 0.2),
        WaveSpawn(EnemyType.drone, (15 + w * 2).clamp(15, 40), delay: 1.5),
      ]),
  _Archetype('BORDER RAIN', 1, (w) => [
        WaveSpawn(EnemyType.swarmDrone,
            (40 + w * 4).clamp(40, 120), delay: 0.2),
        WaveSpawn(EnemyType.drone, (15 + w).clamp(15, 35), delay: 2.0),
      ]),
  _Archetype('PAIR ESCALATION', 1, (w) => [
        WaveSpawn(EnemyType.shieldEnemy, 2, delay: 0),
        WaveSpawn(EnemyType.weaver, 2, delay: 0.5),
        WaveSpawn(EnemyType.drone, (25 + w * 2).clamp(25, 60), delay: 3.0),
      ]),

  // ─── TIER 2 ─────────────────────────────────────────────────────────
  _Archetype('SPAWNER SIEGE', 2, (w) => [
        WaveSpawn(EnemyType.spawner, (2 + w ~/ 15).clamp(2, 4), delay: 0.5),
        WaveSpawn(EnemyType.drone, (20 + w).clamp(20, 40), delay: 2.5),
      ]),
  _Archetype('SNAKE PARADE', 2, (w) => [
        WaveSpawn(EnemyType.snake, (4 + w ~/ 3).clamp(4, 12), delay: 0.3),
        WaveSpawn(EnemyType.drone, (20 + w * 2).clamp(20, 50), delay: 2.5),
      ]),
  _Archetype('MIRROR WALL', 2, (w) => [
        WaveSpawn(EnemyType.mirror, (5 + w ~/ 5).clamp(5, 10), delay: 0.3),
        WaveSpawn(EnemyType.kamikaze, (20 + w).clamp(20, 45), delay: 2.0),
      ]),
  _Archetype('DIAGONAL STORM', 2, (w) => [
        WaveSpawn(EnemyType.weaver, (30 + w * 3).clamp(30, 70), delay: 0.3),
        WaveSpawn(EnemyType.drone, (10 + w).clamp(10, 30), delay: 2.5),
      ]),
  _Archetype('PULSAR RING', 2, (w) => [
        WaveSpawn(EnemyType.pulsar, (6 + w ~/ 5).clamp(6, 12), delay: 0.3),
        WaveSpawn(EnemyType.drone, (15 + w * 2).clamp(15, 40), delay: 2.0),
      ]),
  _Archetype('TESLA NETWORK', 2, (w) => [
        WaveSpawn(EnemyType.tesla, (4 + w ~/ 6).clamp(4, 8), delay: 0.3),
        WaveSpawn(EnemyType.shieldEnemy,
            (5 + w ~/ 4).clamp(5, 12), delay: 2.0),
        WaveSpawn(EnemyType.drone, (15 + w).clamp(15, 35), delay: 3.5),
      ]),
  _Archetype('PHANTOM HUNT', 2, (w) => [
        WaveSpawn(EnemyType.phantom, (6 + w ~/ 4).clamp(6, 12), delay: 0.3),
        WaveSpawn(EnemyType.weaver, (20 + w * 2).clamp(20, 45), delay: 2.0),
      ]),
  _Archetype('HAZARD MAZE', 2, (w) => [
        WaveSpawn(EnemyType.mine, (8 + w ~/ 3).clamp(8, 16), delay: 0.3),
        WaveSpawn(EnemyType.laserTurret,
            (3 + w ~/ 8).clamp(3, 6), delay: 1.5),
        WaveSpawn(EnemyType.snake, (8 + w ~/ 2).clamp(8, 20), delay: 3.0),
      ]),
  _Archetype('ORBITER CAGE', 2, (w) => [
        WaveSpawn(EnemyType.orbiter, (5 + w ~/ 5).clamp(5, 10), delay: 0.3),
        WaveSpawn(EnemyType.drone, (20 + w * 2).clamp(20, 50), delay: 2.5),
      ]),
  _Archetype('LEECH SWARM', 2, (w) => [
        WaveSpawn(EnemyType.leech, (10 + w).clamp(10, 25), delay: 0.3),
        WaveSpawn(EnemyType.drone, (25 + w * 2).clamp(25, 55), delay: 2.0),
      ]),

  // ─── TIER 3 — MEGASWARM (climax pre-boss) ───────────────────────────
  _Archetype('MEGASWARM DRONES', 3, (w) => [
        WaveSpawn(EnemyType.drone, (70 + w * 3).clamp(70, 160), delay: 0.3),
        WaveSpawn(EnemyType.weaver, (5 + w ~/ 8).clamp(5, 12), delay: 2.0),
      ]),
  _Archetype('MEGASWARM KAMIKAZE', 3, (w) => [
        WaveSpawn(EnemyType.kamikaze, (40 + w * 2).clamp(40, 90), delay: 0.3),
        WaveSpawn(EnemyType.shieldEnemy,
            (6 + w ~/ 6).clamp(6, 14), delay: 2.5),
      ]),
  _Archetype('MEGASWARM SNAKES', 3, (w) => [
        WaveSpawn(EnemyType.snake, (8 + w ~/ 2).clamp(8, 24), delay: 0.3),
        WaveSpawn(EnemyType.weaver, (25 + w * 2).clamp(25, 55), delay: 2.5),
      ]),
  _Archetype('MEGASWARM LEECHES', 3, (w) => [
        WaveSpawn(EnemyType.leech, (20 + w).clamp(20, 40), delay: 0.3),
        WaveSpawn(EnemyType.drone, (20 + w * 2).clamp(20, 50), delay: 2.0),
      ]),
  _Archetype('MEGASWARM SWARM', 3, (w) => [
        WaveSpawn(EnemyType.swarmDrone,
            (100 + w * 5).clamp(100, 220), delay: 0.2),
        WaveSpawn(EnemyType.kamikaze, (15 + w).clamp(15, 40), delay: 2.5),
      ]),
  _Archetype('CONCENTRIC STORM', 3, (w) => [
        // Ondate ring successive che circondano player.
        WaveSpawn(EnemyType.drone, (15 + w).clamp(15, 35), delay: 0.3),
        WaveSpawn(EnemyType.drone, (15 + w).clamp(15, 35), delay: 2.5),
        WaveSpawn(EnemyType.drone, (15 + w).clamp(15, 35), delay: 4.5),
        WaveSpawn(EnemyType.weaver, (5 + w ~/ 6).clamp(5, 12), delay: 5.5),
      ]),
  _Archetype('QUADRANT STORM', 3, (w) => [
        WaveSpawn(EnemyType.weaver, (12 + w ~/ 2).clamp(12, 25), delay: 0.3),
        WaveSpawn(EnemyType.pulsar, (6 + w ~/ 5).clamp(6, 12), delay: 1.2),
        WaveSpawn(EnemyType.shieldEnemy,
            (8 + w ~/ 4).clamp(8, 16), delay: 2.2),
        WaveSpawn(EnemyType.drone, (20 + w).clamp(20, 45), delay: 3.5),
      ]),
  _Archetype('MEGASWARM GATES', 3, (w) => [
        WaveSpawn(EnemyType.gate, (2 + w ~/ 30).clamp(2, 3), delay: 0.5),
        WaveSpawn(EnemyType.drone, (40 + w * 2).clamp(40, 90), delay: 2.5),
      ]),
  _Archetype('MUTATOR STORM', 3, (w) => [
        WaveSpawn(EnemyType.mutator, (2 + w ~/ 20).clamp(2, 4), delay: 0.3),
        WaveSpawn(EnemyType.drone, (30 + w * 2).clamp(30, 70), delay: 2.0),
      ]),
  _Archetype('MEGASWARM TITANS', 3, (w) => [
        WaveSpawn(EnemyType.titan, (4 + w ~/ 10).clamp(4, 8), delay: 0.3),
        WaveSpawn(EnemyType.drone, (25 + w * 2).clamp(25, 55), delay: 2.5),
      ]),

  // ─── TIER 4 — NIGHTMARE (wave 45+) ──────────────────────────────────
  _Archetype('VOID STORM', 4, (w) => [
        WaveSpawn(EnemyType.blackHole, 2, delay: 0.5),
        WaveSpawn(EnemyType.drone, (35 + w).clamp(35, 70), delay: 2.5),
        WaveSpawn(EnemyType.proton, (8 + w ~/ 5).clamp(8, 20), delay: 4.0),
      ]),
  _Archetype('NECRO STORM', 4, (w) => [
        WaveSpawn(EnemyType.necro, (3 + w ~/ 15).clamp(3, 6), delay: 0.3),
        WaveSpawn(EnemyType.drone, (30 + w).clamp(30, 65), delay: 2.0),
        WaveSpawn(EnemyType.weaver, (6 + w ~/ 8).clamp(6, 14), delay: 3.5),
      ]),
  _Archetype('MEGASWARM TIMEBOMBS', 4, (w) => [
        WaveSpawn(EnemyType.timeBomb,
            (12 + w ~/ 3).clamp(12, 25), delay: 0.3),
        WaveSpawn(EnemyType.drone, (20 + w).clamp(20, 45), delay: 2.5),
      ]),
  _Archetype('GLITCH STORM', 4, (w) => [
        WaveSpawn(EnemyType.glitch, (8 + w ~/ 4).clamp(8, 16), delay: 0.3),
        WaveSpawn(EnemyType.kamikaze, (30 + w * 2).clamp(30, 70), delay: 2.0),
      ]),
  _Archetype('SIREN STORM', 4, (w) => [
        WaveSpawn(EnemyType.siren, (6 + w ~/ 6).clamp(6, 12), delay: 0.3),
        WaveSpawn(EnemyType.drone, (40 + w * 2).clamp(40, 80), delay: 2.0),
        WaveSpawn(EnemyType.weaver, (8 + w ~/ 5).clamp(8, 20), delay: 3.5),
      ]),
  _Archetype('HELL SPAWN', 4, (w) => [
        WaveSpawn(EnemyType.spawner, (3 + w ~/ 20).clamp(3, 5), delay: 0.5),
        WaveSpawn(EnemyType.necro, (2 + w ~/ 25).clamp(2, 4), delay: 2.0),
        WaveSpawn(EnemyType.kamikaze, (15 + w).clamp(15, 35), delay: 3.5),
      ]),
];

// Obsolete themed-wave helpers rimossi — sostituiti da archetype system.

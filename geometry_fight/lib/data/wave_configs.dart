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
    // STILE GEOMETRY WARS (richiesta utente): 3-4 tipi di mob per wave
    // in quantità massiccia → arena si riempie. Ogni wave ha un TEMA
    // riconoscibile invece di un mix disordinato di ogni mob esistente.
    //
    // Base rotation (wave % 5):
    //   1 → SWARM ASSAULT  (swarmDrone + drone + kamikaze opz.)
    //   2 → RUSH           (kamikaze + weaver + swarmDrone)
    //   3 → MINE FIELD     (mine + shield + drone)
    //   4 → GEOMETRIC      (splitter + snake + pulsar + phantom)
    //
    // Late-game (wave >= 50): 4 temi speciali sostituiscono la rotazione
    // base su wave specifiche per varietà (ELECTRIC/TEMPORAL/GRAVITY/BIOHAZARD).
    // ═══════════════════════════════════════════════════════════════
    final spawns = _generateThemedWave(wave);

    // Gate raro: 1 ogni 10 wave (indipendente dal tema).
    if (wave >= 10 && wave % 10 == 0) {
      spawns.add(WaveSpawn(EnemyType.gate, 1, delay: 10));
    }

    configs.add(WaveConfig(waveNumber: wave, spawns: spawns));
  }

  return configs;
}

// ═══════════════════════════════════════════════════════════════════════
// TEMI WAVE — richiesta utente: ondate "uniche e particolari" con 3-4
// tipi di mob che riempiono l'arena (GW:RE style).
// ═══════════════════════════════════════════════════════════════════════

/// Genera spawn list per una wave non-boss applicando il tema rotante.
/// Count scalati per "riempire l'arena" (counts alti, pochi tipi).
List<WaveSpawn> _generateThemedWave(int wave) {
  // Late-game variety (wave >= 50): temi speciali su wave selezionate.
  if (wave >= 50) {
    final lateTheme = _lateGameThemeOverride(wave);
    if (lateTheme != null) return lateTheme;
  }

  switch (wave % 5) {
    case 1:
      return _themeSwarmAssault(wave);
    case 2:
      return _themeRush(wave);
    case 3:
      return _themeMineField(wave);
    case 4:
      return _themeGeometricHorror(wave);
    default:
      // case 0 gestita sopra come boss. Safety fallback.
      return _themeSwarmAssault(wave);
  }
}

/// TEMA A — SWARM ASSAULT: massa swarmDrone + drone medium.
/// Ondate cardinali che riempiono l'arena con bersagli facili.
List<WaveSpawn> _themeSwarmAssault(int wave) {
  return [
    WaveSpawn(EnemyType.swarmDrone,
        (80 + wave * 6).clamp(80, 200), delay: 0.2),
    WaveSpawn(EnemyType.drone,
        (40 + wave * 3).clamp(40, 100), delay: 1.2),
    if (wave >= 8)
      WaveSpawn(EnemyType.kamikaze,
          (10 + wave).clamp(10, 40), delay: 2.5),
  ];
}

/// TEMA B — RUSH: kamikaze veloci + weaver evasivi + swarmDrone come tappeto.
/// Forza movimento costante del player, non si può stare fermi.
List<WaveSpawn> _themeRush(int wave) {
  return [
    WaveSpawn(EnemyType.kamikaze,
        (24 + wave * 3).clamp(24, 80), delay: 0.3),
    WaveSpawn(EnemyType.weaver,
        (12 + wave * 2).clamp(12, 50), delay: 1.5),
    WaveSpawn(EnemyType.swarmDrone,
        (40 + wave * 4).clamp(40, 140), delay: 2.8),
  ];
}

/// TEMA C — MINE FIELD: statici (mine) + tank (shield) + drone filler.
/// Challenge di posizionamento, non si attraversa liberamente.
List<WaveSpawn> _themeMineField(int wave) {
  return [
    WaveSpawn(EnemyType.mine,
        (16 + wave * 2).clamp(16, 50), delay: 0.2),
    WaveSpawn(EnemyType.drone,
        (40 + wave * 3).clamp(40, 120), delay: 1.5),
    if (wave >= 4)
      WaveSpawn(EnemyType.shieldEnemy,
          (6 + wave).clamp(6, 30), delay: 2.8),
  ];
}

/// TEMA D — GEOMETRIC HORROR: splitter + snake + pulsar + phantom (late).
/// Comportamenti complessi che richiedono lettura del pattern.
List<WaveSpawn> _themeGeometricHorror(int wave) {
  return [
    if (wave >= 3)
      WaveSpawn(EnemyType.splitter,
          (5 + wave ~/ 2).clamp(5, 16), delay: 0.3),
    WaveSpawn(EnemyType.snake,
        (6 + wave).clamp(6, 30), delay: 1.2),
    if (wave >= 5)
      WaveSpawn(EnemyType.pulsar,
          (8 + wave).clamp(8, 30), delay: 2.2),
    if (wave >= 9)
      WaveSpawn(EnemyType.phantom,
          (4 + wave ~/ 2).clamp(4, 20), delay: 3.5),
  ];
}

/// Late-game override (wave >= 50): 4 temi speciali che sostituiscono la
/// rotazione base su wave specifiche per varietà avanzata.
List<WaveSpawn>? _lateGameThemeOverride(int wave) {
  // wave % 20 pattern — boss su 0/5/10/15 (già gestiti), temi su 1/3/7/9/11/13/17/19 a scelta.
  final mod = wave % 20;
  switch (mod) {
    case 1: // 51, 71, 91 → ELECTRIC
      return [
        WaveSpawn(EnemyType.tesla, (20 + wave).clamp(20, 60)),
        WaveSpawn(EnemyType.laserTurret,
            (8 + wave ~/ 3).clamp(8, 24), delay: 2),
        WaveSpawn(EnemyType.drone, (30 + wave).clamp(30, 80), delay: 3),
      ];
    case 3: // 53, 73, 93 → TEMPORAL
      return [
        WaveSpawn(EnemyType.glitch, (12 + wave ~/ 2).clamp(12, 40)),
        WaveSpawn(EnemyType.phantom,
            (10 + wave ~/ 2).clamp(10, 30), delay: 1.5),
        WaveSpawn(EnemyType.mirror,
            (10 + wave ~/ 2).clamp(10, 30), delay: 2.8),
        WaveSpawn(EnemyType.decoy,
            (12 + wave ~/ 2).clamp(12, 40), delay: 3.5),
      ];
    case 7: // 57, 77, 97 → GRAVITY
      return [
        WaveSpawn(EnemyType.gravityWell,
            (1 + wave ~/ 30).clamp(1, 3), delay: 0.5),
        if (wave >= 60)
          WaveSpawn(EnemyType.blackHole,
              (wave ~/ 25).clamp(1, 3), delay: 1.5),
        WaveSpawn(EnemyType.orbiter,
            (16 + wave ~/ 2).clamp(16, 40), delay: 3),
        WaveSpawn(EnemyType.swarmDrone,
            (40 + wave).clamp(40, 120), delay: 4),
      ];
    case 9: // 69, 89 → BIOHAZARD
      return [
        WaveSpawn(EnemyType.healer, (3 + wave ~/ 15).clamp(3, 8)),
        WaveSpawn(EnemyType.siren,
            (6 + wave ~/ 5).clamp(6, 20), delay: 1.5),
        WaveSpawn(EnemyType.mutator,
            (4 + wave ~/ 10).clamp(4, 12), delay: 2.5),
        WaveSpawn(EnemyType.leech,
            (16 + wave).clamp(16, 50), delay: 3.5),
        if (wave >= 60)
          WaveSpawn(EnemyType.necro,
              (wave ~/ 15).clamp(1, 4), delay: 5),
      ];
    default:
      return null;
  }
}

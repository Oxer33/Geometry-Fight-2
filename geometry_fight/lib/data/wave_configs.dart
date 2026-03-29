enum EnemyType {
  drone,
  snake,
  mine,
  spawner,
  weaver,
  bouncer,
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

List<WaveConfig> generateWaveConfigs() {
  final configs = <WaveConfig>[];

  for (int wave = 1; wave <= 100; wave++) {
    // Boss waves
    if (wave == 10) {
      configs.add(WaveConfig(
        waveNumber: wave,
        spawns: [],
        boss: BossType.theGrid,
      ));
      continue;
    }
    if (wave == 20) {
      configs.add(WaveConfig(
        waveNumber: wave,
        spawns: [],
        boss: BossType.hydra,
      ));
      continue;
    }
    if (wave == 30) {
      configs.add(WaveConfig(
        waveNumber: wave,
        spawns: [],
        boss: BossType.singularity,
      ));
      continue;
    }
    if (wave == 40) {
      configs.add(WaveConfig(
        waveNumber: wave,
        spawns: [],
        boss: BossType.swarmMother,
      ));
      continue;
    }
    if (wave == 45) {
      configs.add(WaveConfig(
        waveNumber: wave,
        spawns: [],
        boss: BossType.theArchitect,
      ));
      continue;
    }
    if (wave == 50) {
      configs.add(WaveConfig(
        waveNumber: wave,
        spawns: [],
        boss: BossType.chronoWraith,
      ));
      continue;
    }
    if (wave == 55) {
      configs.add(WaveConfig(
        waveNumber: wave,
        spawns: [WaveSpawn(EnemyType.tesla, 6), WaveSpawn(EnemyType.orbiter, 8, delay: 2)],
        boss: BossType.nexusPrime,
      ));
      continue;
    }
    if (wave == 60) {
      configs.add(WaveConfig(
        waveNumber: wave,
        spawns: [WaveSpawn(EnemyType.healer, 4), WaveSpawn(EnemyType.siren, 6, delay: 2)],
        boss: BossType.voidReaper,
      ));
      continue;
    }
    if (wave == 65) {
      configs.add(WaveConfig(
        waveNumber: wave,
        spawns: [WaveSpawn(EnemyType.tesla, 10), WaveSpawn(EnemyType.necro, 4, delay: 3)],
        boss: BossType.teslaLord,
      ));
      continue;
    }
    if (wave == 70) {
      configs.add(WaveConfig(
        waveNumber: wave,
        spawns: [WaveSpawn(EnemyType.phantom, 8), WaveSpawn(EnemyType.glitch, 6, delay: 2)],
        boss: BossType.phantomKing,
      ));
      continue;
    }
    if (wave == 75) {
      configs.add(WaveConfig(
        waveNumber: wave,
        spawns: [WaveSpawn(EnemyType.titan, 6), WaveSpawn(EnemyType.healer, 4, delay: 3)],
        boss: BossType.omegaCore,
      ));
      continue;
    }
    // Wave 80-100: nuovi boss batch 3
    if (wave == 80) {
      configs.add(WaveConfig(
        waveNumber: wave,
        spawns: [WaveSpawn(EnemyType.mirror, 8), WaveSpawn(EnemyType.decoy, 10, delay: 2)],
        boss: BossType.mirrorMaster,
      ));
      continue;
    }
    if (wave == 85) {
      configs.add(WaveConfig(
        waveNumber: wave,
        spawns: [WaveSpawn(EnemyType.swarmDrone, 40), WaveSpawn(EnemyType.healer, 4, delay: 3)],
        boss: BossType.swarmQueen,
      ));
      continue;
    }
    if (wave == 90) {
      configs.add(WaveConfig(
        waveNumber: wave,
        spawns: [WaveSpawn(EnemyType.gravityWell, 4), WaveSpawn(EnemyType.blackHole, 2, delay: 4)],
        boss: BossType.graviton,
      ));
      continue;
    }
    if (wave == 95) {
      configs.add(WaveConfig(
        waveNumber: wave,
        spawns: [WaveSpawn(EnemyType.kamikaze, 20), WaveSpawn(EnemyType.timeBomb, 6, delay: 3)],
        boss: BossType.inferno,
      ));
      continue;
    }
    if (wave == 100) {
      configs.add(WaveConfig(
        waveNumber: wave,
        spawns: [WaveSpawn(EnemyType.titan, 8), WaveSpawn(EnemyType.tesla, 10, delay: 2), WaveSpawn(EnemyType.healer, 6, delay: 4)],
        boss: BossType.eternityEngine,
      ));
      continue;
    }

    // ═══════════════════════════════════════════════════════════════
    // STILE GEOMETRY WARS: ~70% mob stupidi (wanderer/swarm) + 30% pericolosi
    // I mob stupidi riempiono l'arena e creano caos visivo,
    // i pericolosi sono pochi ma richiedono attenzione.
    // ═══════════════════════════════════════════════════════════════
    final spawns = <WaveSpawn>[];

    // ── MOB STUPIDI (massa) ── spawnano subito, riempiono l'arena ──

    // Bouncer (Wanderer): random walk, non insegue — SEMPRE presenti, tanti
    spawns.add(WaveSpawn(EnemyType.bouncer, (30 + wave * 4).clamp(30, 120)));

    // SwarmDrone: seguono vagamente ma sono debolissimi — ondate enormi
    if (wave >= 2) {
      spawns.add(WaveSpawn(EnemyType.swarmDrone, (20 + wave * 4).clamp(20, 100), delay: 0.3));
    }

    // Drone (Grunt): lento homing, diventa pericoloso solo col tempo
    spawns.add(WaveSpawn(EnemyType.drone, (16 + wave * 2).clamp(16, 60), delay: 0.5));

    // Mine: statiche, pericolose ma non inseguono
    if (wave >= 3) {
      spawns.add(WaveSpawn(EnemyType.mine, (4 + wave).clamp(4, 24), delay: 1));
    }

    // ── MOB PERICOLOSI (minoranza) ── spawnano con delay, pochi ma letali ──

    // Kamikaze: veloci e diretti
    if (wave >= 4) {
      spawns.add(WaveSpawn(EnemyType.kamikaze, (4 + wave * 2 ~/ 3).clamp(4, 20), delay: 2));
    }

    // Weaver: schiva proiettili
    if (wave >= 5) {
      spawns.add(WaveSpawn(EnemyType.weaver, (2 + wave ~/ 2).clamp(2, 16), delay: 2.5));
    }

    // Snake: sine wave, corpo invulnerabile
    if (wave >= 5) {
      spawns.add(WaveSpawn(EnemyType.snake, (2 + wave * 2 ~/ 5).clamp(2, 10), delay: 3));
    }

    // Splitter: si divide alla morte
    if (wave >= 6) {
      spawns.add(WaveSpawn(EnemyType.splitter, (2 + wave * 2 ~/ 5).clamp(2, 12), delay: 3));
    }

    // Shield: carica e ha scudo
    if (wave >= 7) {
      spawns.add(WaveSpawn(EnemyType.shieldEnemy, (2 + wave ~/ 3).clamp(2, 10), delay: 4));
    }

    // Spawner: genera mini nemici
    if (wave >= 8) {
      spawns.add(WaveSpawn(EnemyType.spawner, (wave ~/ 4).clamp(2, 6), delay: 4));
    }

    // Black Hole: raro ma devastante
    if (wave >= 9 && wave % 4 == 0) {
      spawns.add(WaveSpawn(EnemyType.blackHole, 2, delay: 5));
    }

    // Pulsar: onde d'urto
    if (wave >= 10) {
      spawns.add(WaveSpawn(EnemyType.pulsar, (wave ~/ 4).clamp(2, 8), delay: 3.5));
    }

    // Leech: parassiti veloci
    if (wave >= 12) {
      spawns.add(WaveSpawn(EnemyType.leech, (wave * 2 ~/ 7).clamp(2, 10), delay: 3));
    }

    // Mirror: strafing orbitale
    if (wave >= 14) {
      spawns.add(WaveSpawn(EnemyType.mirror, (wave ~/ 5).clamp(2, 8), delay: 4));
    }

    // Glitch: teletrasporto
    if (wave >= 16) {
      spawns.add(WaveSpawn(EnemyType.glitch, (wave ~/ 6).clamp(2, 6), delay: 4));
    }

    // Phantom: flanking invisibile
    if (wave >= 18) {
      spawns.add(WaveSpawn(EnemyType.phantom, (wave ~/ 6).clamp(2, 6), delay: 5));
    }

    // Titan: tank
    if (wave >= 15 && wave % 3 == 0) {
      spawns.add(WaveSpawn(EnemyType.titan, (wave * 2 ~/ 15).clamp(2, 4), delay: 5));
    }

    // Vortex
    if (wave >= 20) {
      spawns.add(WaveSpawn(EnemyType.vortex, (wave * 2 ~/ 15).clamp(2, 6), delay: 5));
    }

    // Healer: cura nemici (priorità target!)
    if (wave >= 20 && wave % 3 == 0) {
      spawns.add(WaveSpawn(EnemyType.healer, (wave ~/ 10).clamp(2, 4), delay: 5));
    }

    // Tesla: archi elettrici in pack
    if (wave >= 22) {
      spawns.add(WaveSpawn(EnemyType.tesla, (wave * 2 ~/ 15).clamp(2, 6), delay: 5));
    }

    // Orbiter
    if (wave >= 25) {
      spawns.add(WaveSpawn(EnemyType.orbiter, (wave * 2 ~/ 15).clamp(2, 6), delay: 4));
    }

    // Siren: rallenta proiettili
    if (wave >= 28) {
      spawns.add(WaveSpawn(EnemyType.siren, (wave ~/ 10).clamp(2, 4), delay: 6));
    }

    // Necro: resuscita nemici
    if (wave >= 30 && wave % 4 == 0) {
      spawns.add(WaveSpawn(EnemyType.necro, 2, delay: 7));
    }

    // Laser Turret
    if (wave >= 28) {
      spawns.add(WaveSpawn(EnemyType.laserTurret, (wave ~/ 12).clamp(2, 4), delay: 6));
    }

    // Time Bomb
    if (wave >= 24 && wave % 3 == 0) {
      spawns.add(WaveSpawn(EnemyType.timeBomb, (wave ~/ 10).clamp(2, 4), delay: 5));
    }

    // Gravity Well: raro
    if (wave >= 35 && wave % 5 == 0) {
      spawns.add(WaveSpawn(EnemyType.gravityWell, 2, delay: 7));
    }

    // Decoy: trappole
    if (wave >= 18 && wave % 3 == 0) {
      spawns.add(WaveSpawn(EnemyType.decoy, (wave ~/ 5).clamp(2, 8), delay: 4));
    }

    // Gate (GW:RE2): attraversali per uccidere nemici vicini — risk/reward
    if (wave >= 3) {
      spawns.add(WaveSpawn(EnemyType.gate, (2 + wave ~/ 4).clamp(2, 10), delay: 1));
    }

    // Mutator (GW:RE2): potenzia nemici al contatto — priorità alta!
    if (wave >= 12 && wave % 2 == 0) {
      spawns.add(WaveSpawn(EnemyType.mutator, (wave ~/ 8).clamp(1, 4), delay: 5));
    }

    configs.add(WaveConfig(waveNumber: wave, spawns: spawns));
  }

  return configs;
}

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
    // STILE GEOMETRY WARS: ~70% mob stupidi + 30% pericolosi.
    // Opening ROTATA per wave (`wave % 5`) → niente più monotona doppia
    // schiera di swarmDrone rossi ad ogni wave. 5 pattern differenti.
    // ═══════════════════════════════════════════════════════════════
    final spawns = <WaveSpawn>[];

    // Gate raro: 1 ogni 10 wave a partire da 10.
    if (wave >= 10 && wave % 10 == 0) {
      spawns.add(WaveSpawn(EnemyType.gate, 1, delay: 8));
    }

    // ── OPENING PATTERN (ruota su wave % 5) ──
    switch (wave % 5) {
      case 0:
        // "Swarm assault": sciame rosa classico
        spawns.add(WaveSpawn(EnemyType.swarmDrone,
            (50 + wave * 6).clamp(50, 180), delay: 0.1));
        spawns.add(WaveSpawn(EnemyType.drone,
            (20 + wave * 2).clamp(20, 80), delay: 0.6));
      case 1:
        // "Kamikaze rush": ondate veloci che puntano
        spawns.add(WaveSpawn(EnemyType.kamikaze,
            (16 + wave * 3).clamp(16, 70), delay: 0.2));
        spawns.add(WaveSpawn(EnemyType.drone,
            (24 + wave * 2).clamp(24, 90), delay: 0.8));
        if (wave >= 2) {
          spawns.add(WaveSpawn(EnemyType.swarmDrone,
              (20 + wave * 3).clamp(20, 80), delay: 1.4));
        }
      case 2:
        // "Mine field": statiche + drone lenti → posizionamento
        spawns.add(WaveSpawn(EnemyType.mine,
            (10 + wave * 2).clamp(10, 40), delay: 0.1));
        spawns.add(WaveSpawn(EnemyType.drone,
            (32 + wave * 3).clamp(32, 100), delay: 0.8));
        if (wave >= 4) {
          spawns.add(WaveSpawn(EnemyType.shieldEnemy,
              (4 + wave).clamp(4, 24), delay: 2));
        }
      case 3:
        // "Geometric horror": splitter + snake + weaver
        if (wave >= 3) {
          spawns.add(WaveSpawn(EnemyType.splitter,
              (3 + wave ~/ 2).clamp(3, 10), delay: 0.3));
        }
        spawns.add(WaveSpawn(EnemyType.drone,
            (24 + wave * 3).clamp(24, 100), delay: 0.6));
        if (wave >= 2) {
          spawns.add(WaveSpawn(EnemyType.weaver,
              (8 + wave * 2).clamp(8, 50), delay: 1.5));
        }
        if (wave >= 3) {
          spawns.add(WaveSpawn(EnemyType.snake,
              (3 + wave).clamp(3, 20), delay: 2));
        }
      case 4:
        // "Mixed chaos": swarm light + kamikaze + pulsar/leech
        spawns.add(WaveSpawn(EnemyType.swarmDrone,
            (30 + wave * 4).clamp(30, 120), delay: 0.1));
        spawns.add(WaveSpawn(EnemyType.kamikaze,
            (10 + wave * 2).clamp(10, 40), delay: 1));
        if (wave >= 5) {
          spawns.add(WaveSpawn(EnemyType.pulsar,
              (4 + wave).clamp(4, 30), delay: 2));
        }
        if (wave >= 6) {
          spawns.add(WaveSpawn(EnemyType.leech,
              (4 + wave).clamp(4, 25), delay: 2.5));
        }
    }

    // Mine filler se non è il pattern case 2 (già in primo piano).
    if (wave >= 2 && wave % 5 != 2) {
      spawns.add(WaveSpawn(EnemyType.mine,
          (6 + wave).clamp(6, 30), delay: 1.5));
    }

    // ── MOB PERICOLOSI (minoranza) ── spawnano con delay, pochi ma letali ──
    // Tutti i tier mid/strong anticipati e con count scalato per dare varietà
    // alle early wave (erano troppo monotone) senza sovraccaricare il giocatore.

    // Kamikaze: veloci e diretti — già da wave 2 in piccoli gruppi
    if (wave >= 2) {
      spawns.add(WaveSpawn(EnemyType.kamikaze, (6 + wave * 3).clamp(6, 50), delay: 2));
    }

    // Weaver: schiva proiettili — da wave 2 in piccoli gruppi
    if (wave >= 2) {
      spawns.add(WaveSpawn(EnemyType.weaver, (6 + wave * 3).clamp(6, 50), delay: 2.5));
    }

    // Snake: sine wave, corpo invulnerabile — da wave 3
    if (wave >= 3) {
      spawns.add(WaveSpawn(EnemyType.snake, (4 + wave * 2).clamp(4, 50), delay: 3));
    }

    // Splitter: si divide alla morte — da wave 3, piccoli gruppi
    if (wave >= 3) {
      spawns.add(WaveSpawn(EnemyType.splitter, (3 + wave).clamp(3, 12), delay: 3));
    }

    // Shield: carica e ha scudo — da wave 4
    if (wave >= 4) {
      spawns.add(WaveSpawn(EnemyType.shieldEnemy, (5 + wave * 2).clamp(5, 50), delay: 4));
    }

    // Spawner: genera mini nemici — limitato, ogni spawner crea già molti figli
    if (wave >= 8) {
      spawns.add(WaveSpawn(EnemyType.spawner, (wave ~/ 6).clamp(2, 8), delay: 4));
    }

    // Black Hole: raro ma devastante — primo spawn GARANTITO a wave 9, poi ogni 4
    if (wave >= 9 && (wave == 9 || wave % 4 == 0)) {
      spawns.add(WaveSpawn(EnemyType.blackHole, (wave ~/ 15).clamp(1, 4), delay: 5));
    }

    // Pulsar: onde d'urto — da wave 5
    if (wave >= 5) {
      spawns.add(WaveSpawn(EnemyType.pulsar, (5 + wave * 2).clamp(5, 50), delay: 3.5));
    }

    // Leech: parassiti veloci — da wave 6
    if (wave >= 6) {
      spawns.add(WaveSpawn(EnemyType.leech, (5 + wave * 2).clamp(5, 50), delay: 3));
    }

    // Mirror: strafing orbitale — da wave 7
    if (wave >= 7) {
      spawns.add(WaveSpawn(EnemyType.mirror, (4 + wave * 2).clamp(4, 50), delay: 4));
    }

    // Glitch: teletrasporto — da wave 8
    if (wave >= 8) {
      spawns.add(WaveSpawn(EnemyType.glitch, (4 + wave).clamp(4, 50), delay: 4));
    }

    // Phantom: flanking invisibile — da wave 9
    if (wave >= 9) {
      spawns.add(WaveSpawn(EnemyType.phantom, (4 + wave).clamp(4, 50), delay: 5));
    }

    // Titan: tank — pochi ma resistenti
    if (wave >= 15 && wave % 3 == 0) {
      spawns.add(WaveSpawn(EnemyType.titan, (wave ~/ 8).clamp(2, 8), delay: 5));
    }

    // Vortex
    if (wave >= 20) {
      spawns.add(WaveSpawn(EnemyType.vortex, 50, delay: 5));
    }

    // Healer: cura nemici (priorità target!) — supporto, mai troppi
    if (wave >= 20 && wave % 3 == 0) {
      spawns.add(WaveSpawn(EnemyType.healer, (wave ~/ 10).clamp(2, 6), delay: 5));
    }

    // Tesla: archi elettrici in pack
    if (wave >= 22) {
      spawns.add(WaveSpawn(EnemyType.tesla, 50, delay: 5));
    }

    // Orbiter
    if (wave >= 25) {
      spawns.add(WaveSpawn(EnemyType.orbiter, 50, delay: 4));
    }

    // Siren: rallenta proiettili
    if (wave >= 28) {
      spawns.add(WaveSpawn(EnemyType.siren, 50, delay: 6));
    }

    // Necro: resuscita nemici — pochissimi, ogni necro è già moltiplicatore
    if (wave >= 30 && wave % 4 == 0) {
      spawns.add(WaveSpawn(EnemyType.necro, (wave ~/ 15).clamp(1, 4), delay: 7));
    }

    // Laser Turret
    if (wave >= 28) {
      spawns.add(WaveSpawn(EnemyType.laserTurret, 50, delay: 6));
    }

    // Time Bomb
    if (wave >= 24 && wave % 3 == 0) {
      spawns.add(WaveSpawn(EnemyType.timeBomb, 50, delay: 5));
    }

    // Gravity Well: raro — mai più di 3
    if (wave >= 35 && wave % 5 == 0) {
      spawns.add(WaveSpawn(EnemyType.gravityWell, (wave ~/ 20).clamp(1, 3), delay: 7));
    }

    // Decoy: trappole
    if (wave >= 18 && wave % 3 == 0) {
      spawns.add(WaveSpawn(EnemyType.decoy, 50, delay: 4));
    }

    // Mutator (GW:RE2): potenzia nemici al contatto — priorità alta!
    if (wave >= 12 && wave % 2 == 0) {
      spawns.add(WaveSpawn(EnemyType.mutator, 50, delay: 5));
    }

    configs.add(WaveConfig(waveNumber: wave, spawns: spawns));
  }

  return configs;
}

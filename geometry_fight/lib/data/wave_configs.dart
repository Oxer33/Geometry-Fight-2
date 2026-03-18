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

  for (int wave = 1; wave <= 75; wave++) {
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
        spawns: [WaveSpawn(EnemyType.tesla, 3), WaveSpawn(EnemyType.orbiter, 4, delay: 2)],
        boss: BossType.nexusPrime,
      ));
      continue;
    }
    if (wave == 60) {
      configs.add(WaveConfig(
        waveNumber: wave,
        spawns: [WaveSpawn(EnemyType.healer, 2), WaveSpawn(EnemyType.siren, 3, delay: 2)],
        boss: BossType.voidReaper,
      ));
      continue;
    }
    if (wave == 65) {
      configs.add(WaveConfig(
        waveNumber: wave,
        spawns: [WaveSpawn(EnemyType.tesla, 5), WaveSpawn(EnemyType.necro, 2, delay: 3)],
        boss: BossType.teslaLord,
      ));
      continue;
    }
    if (wave == 70) {
      configs.add(WaveConfig(
        waveNumber: wave,
        spawns: [WaveSpawn(EnemyType.phantom, 4), WaveSpawn(EnemyType.glitch, 3, delay: 2)],
        boss: BossType.phantomKing,
      ));
      continue;
    }
    if (wave == 75) {
      configs.add(WaveConfig(
        waveNumber: wave,
        spawns: [WaveSpawn(EnemyType.titan, 3), WaveSpawn(EnemyType.healer, 2, delay: 3)],
        boss: BossType.omegaCore,
      ));
      continue;
    }

    // Regular waves - progressive difficulty
    final spawns = <WaveSpawn>[];
    final difficulty = wave / 10.0;

    // Drones - always present
    spawns.add(WaveSpawn(EnemyType.drone, 5 + wave * 2));

    // Mines from wave 2
    if (wave >= 2) {
      spawns.add(WaveSpawn(EnemyType.mine, 3 + wave ~/ 2, delay: 1));
    }

    // Snakes from wave 3
    if (wave >= 3) {
      spawns.add(WaveSpawn(EnemyType.snake, 1 + wave ~/ 4, delay: 2));
    }

    // Weavers and Bouncers from wave 4
    if (wave >= 4) {
      spawns.add(WaveSpawn(EnemyType.weaver, 2 + wave ~/ 3, delay: 1.5));
      spawns.add(WaveSpawn(EnemyType.bouncer, 1 + wave ~/ 4, delay: 3));
    }

    // Spawners and Kamikazes from wave 5
    if (wave >= 5) {
      spawns.add(WaveSpawn(EnemyType.spawner, 1 + wave ~/ 8, delay: 4));
      spawns.add(WaveSpawn(EnemyType.kamikaze, 3 + wave ~/ 3, delay: 2));
    }

    // Splitters from wave 6
    if (wave >= 6) {
      spawns.add(WaveSpawn(EnemyType.splitter, 1 + wave ~/ 5, delay: 3));
    }

    // Shield enemies from wave 7
    if (wave >= 7) {
      spawns.add(WaveSpawn(EnemyType.shieldEnemy, 1 + wave ~/ 6, delay: 4));
    }

    // Black Holes from wave 8 (max 1 per wave)
    if (wave >= 8 && wave % 3 == 0) {
      spawns.add(WaveSpawn(EnemyType.blackHole, 1, delay: 5));
    }

    // New enemies from wave 9+
    if (wave >= 9) {
      spawns.add(WaveSpawn(EnemyType.pulsar, 1 + wave ~/ 7, delay: 3));
    }

    if (wave >= 11) {
      spawns.add(WaveSpawn(EnemyType.mirror, 1 + wave ~/ 8, delay: 4));
    }

    if (wave >= 13) {
      spawns.add(WaveSpawn(EnemyType.phantom, 1 + wave ~/ 10, delay: 5));
    }

    if (wave >= 15) {
      spawns.add(WaveSpawn(EnemyType.vortex, wave ~/ 12, delay: 6));
    }

    // Leech dal wave 12 (parassiti veloci)
    if (wave >= 12) {
      spawns.add(WaveSpawn(EnemyType.leech, 2 + wave ~/ 6, delay: 3));
    }

    // Titan dal wave 14 (tank corazzati, max 2)
    if (wave >= 14 && wave % 2 == 0) {
      spawns.add(WaveSpawn(EnemyType.titan, (wave ~/ 14).clamp(1, 2), delay: 5));
    }

    // Glitch dal wave 16 (teletrasporto)
    if (wave >= 16) {
      spawns.add(WaveSpawn(EnemyType.glitch, 1 + wave ~/ 10, delay: 4));
    }

    // Healer dal wave 18 (cura nemici vicini - priorità alta!)
    if (wave >= 18 && wave % 2 == 0) {
      spawns.add(WaveSpawn(EnemyType.healer, (wave ~/ 18).clamp(1, 2), delay: 5));
    }

    // Orbiter dal wave 20 (orbita e spara)
    if (wave >= 20) {
      spawns.add(WaveSpawn(EnemyType.orbiter, 1 + wave ~/ 12, delay: 4));
    }

    // Tesla dal wave 22 (archi elettrici tra nemici)
    if (wave >= 22) {
      spawns.add(WaveSpawn(EnemyType.tesla, 1 + wave ~/ 15, delay: 5));
    }

    // Siren dal wave 25 (rallenta proiettili)
    if (wave >= 25) {
      spawns.add(WaveSpawn(EnemyType.siren, (wave ~/ 15).clamp(1, 3), delay: 6));
    }

    // Necro dal wave 28 (resuscita nemici morti)
    if (wave >= 28 && wave % 3 == 0) {
      spawns.add(WaveSpawn(EnemyType.necro, 1, delay: 7));
    }

    // Swarm Drone dal wave 8 (gruppi enormi)
    if (wave >= 8 && wave % 2 == 0) {
      spawns.add(WaveSpawn(EnemyType.swarmDrone, 8 + wave, delay: 1));
    }

    // Time Bomb dal wave 20
    if (wave >= 20 && wave % 3 == 0) {
      spawns.add(WaveSpawn(EnemyType.timeBomb, 1 + wave ~/ 20, delay: 5));
    }

    // Laser Turret dal wave 24
    if (wave >= 24) {
      spawns.add(WaveSpawn(EnemyType.laserTurret, (wave ~/ 20).clamp(1, 3), delay: 6));
    }

    // Gravity Well dal wave 30 (max 1)
    if (wave >= 30 && wave % 5 == 0) {
      spawns.add(WaveSpawn(EnemyType.gravityWell, 1, delay: 7));
    }

    // Decoy dal wave 15 (trappole)
    if (wave >= 15 && wave % 3 == 0) {
      spawns.add(WaveSpawn(EnemyType.decoy, 2 + wave ~/ 10, delay: 4));
    }

    configs.add(WaveConfig(waveNumber: wave, spawns: spawns));
  }

  return configs;
}

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
}

enum BossType {
  theGrid,
  hydra,
  singularity,
  swarmMother,
  // New bosses
  theArchitect,
  chronoWraith,
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

  for (int wave = 1; wave <= 50; wave++) {
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

    configs.add(WaveConfig(waveNumber: wave, spawns: spawns));
  }

  return configs;
}

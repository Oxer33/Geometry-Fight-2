import '../../data/wave_configs.dart';
import '../game_world.dart';

class WaveSystem {
  final GeometryFightGame game;
  int currentWave = 0;
  double _spawnTimer = 0;
  int _spawnIndex = 0;
  bool _waveActive = false;
  bool _bossActive = false;
  late List<WaveConfig> _configs;
  WaveConfig? _currentConfig;

  WaveSystem(this.game) {
    _configs = generateWaveConfigs();
  }

  void startWave(int wave) {
    currentWave = wave;
    _waveActive = true;
    _spawnIndex = 0;
    _spawnTimer = 1.0; // Small delay before first spawn

    // Find config
    _currentConfig = _configs.firstWhere(
      (c) => c.waveNumber == wave,
      orElse: () => _generateEndlessWave(wave),
    );

    // Check for boss
    if (_currentConfig!.boss != null) {
      _bossActive = true;
      game.spawnBoss(_currentConfig!.boss!);
    }

    game.onWaveStart?.call(wave);
  }

  void update(double dt) {
    if (!_waveActive) return;

    if (_bossActive) {
      // Wait for boss to die
      if (game.bossCount == 0) {
        _bossActive = false;
        _completeWave();
      }
      return;
    }

    _spawnTimer -= dt;
    if (_spawnTimer <= 0 && _currentConfig != null) {
      if (_spawnIndex < _currentConfig!.spawns.length) {
        final spawn = _currentConfig!.spawns[_spawnIndex];
        for (int i = 0; i < spawn.count; i++) {
          game.spawnEnemy(spawn.type);
        }
        _spawnIndex++;

        if (_spawnIndex < _currentConfig!.spawns.length) {
          _spawnTimer = _currentConfig!.spawns[_spawnIndex].delay;
        }
      }
    }

    // Check if wave is complete
    if (_spawnIndex >= (_currentConfig?.spawns.length ?? 0) &&
        game.enemyCount == 0) {
      _completeWave();
    }
  }

  void _completeWave() {
    _waveActive = false;

    // Notifica il game che la wave è completa (per Perfect Wave bonus)
    game.onWaveComplete();

    // Wait 2 seconds then start next wave
    Future.delayed(const Duration(seconds: 2), () {
      if (game.gameState == GameState.playing) {
        startWave(currentWave + 1);
      }
    });
  }

  void onBossDefeated() {
    _bossActive = false;
  }

  WaveConfig _generateEndlessWave(int wave) {
    // Genera ondate sempre più difficili oltre le wave configurate
    final spawns = <WaveSpawn>[];

    // Nemici base sempre presenti
    spawns.add(WaveSpawn(EnemyType.drone, (10 + wave * 3).clamp(10, 80)));
    spawns.add(WaveSpawn(EnemyType.kamikaze, (wave ~/ 2).clamp(3, 20), delay: 1));
    spawns.add(WaveSpawn(EnemyType.weaver, (wave ~/ 3).clamp(2, 15), delay: 2));
    spawns.add(WaveSpawn(EnemyType.splitter, (wave ~/ 5).clamp(1, 8), delay: 3));
    spawns.add(WaveSpawn(EnemyType.shieldEnemy, (wave ~/ 6).clamp(1, 6), delay: 4));
    spawns.add(WaveSpawn(EnemyType.vortex, (wave ~/ 10).clamp(1, 3), delay: 5));

    // Nuovi nemici nelle endless waves
    spawns.add(WaveSpawn(EnemyType.leech, (wave ~/ 5).clamp(2, 10), delay: 3));
    spawns.add(WaveSpawn(EnemyType.glitch, (wave ~/ 8).clamp(1, 5), delay: 4));
    spawns.add(WaveSpawn(EnemyType.pulsar, (wave ~/ 7).clamp(1, 6), delay: 3));
    spawns.add(WaveSpawn(EnemyType.mirror, (wave ~/ 9).clamp(1, 4), delay: 5));

    // Titan (tank) ogni 3 wave
    if (wave % 3 == 0) {
      spawns.add(WaveSpawn(EnemyType.titan, (wave ~/ 15).clamp(1, 3), delay: 6));
    }

    // Black Hole ogni 5 wave
    if (wave % 5 == 0) {
      spawns.add(WaveSpawn(EnemyType.blackHole, 1, delay: 6));
    }

    // Phantom nelle wave avanzate
    if (wave > 60) {
      spawns.add(WaveSpawn(EnemyType.phantom, (wave ~/ 12).clamp(1, 4), delay: 5));
    }

    return WaveConfig(waveNumber: wave, spawns: spawns);
  }
}

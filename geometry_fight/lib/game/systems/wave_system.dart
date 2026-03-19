import '../../data/difficulty.dart';
import '../../data/wave_configs.dart';
import '../game_world.dart';

class WaveSystem {
  final GeometryFightGame game;
  int currentWave = 0;
  double _spawnTimer = 0;
  int _spawnIndex = 0;
  bool _waveActive = false;
  bool _bossActive = false;
  bool _allSpawned = false; // Tutti i gruppi sono stati spawnati
  double _postSpawnDelay = 0; // Delay dopo l'ultimo spawn prima di controllare completamento
  int _totalSpawned = 0; // Contatore nemici spawnati in questa wave
  late List<WaveConfig> _configs;
  WaveConfig? _currentConfig;

  WaveSystem(this.game) {
    _configs = generateWaveConfigs();
  }

  /// Ritorna la modalità di gioco attuale dal game
  GameMode get _mode => game.gameMode;

  void startWave(int wave) {
    currentWave = wave;
    _waveActive = true;
    _spawnIndex = 0;
    _spawnTimer = 1.0; // Delay iniziale prima del primo spawn
    _allSpawned = false;
    _postSpawnDelay = 0;
    _totalSpawned = 0;

    // Genera config in base alla modalità di gioco
    switch (_mode) {
      case GameMode.bossRush:
        _currentConfig = _generateBossRushWave(wave);
      case GameMode.survival:
        _currentConfig = _generateSurvivalWave(wave);
      case GameMode.timeAttack:
        _currentConfig = _generateTimeAttackWave(wave);
      case GameMode.zenMode:
        _currentConfig = _generateZenWave(wave);
      case GameMode.tunnel:
        _currentConfig = _generateTunnelWave(wave);
      case GameMode.classic:
        _currentConfig = _configs.firstWhere(
          (c) => c.waveNumber == wave,
          orElse: () => _generateEndlessWave(wave),
        );
    }

    // Check for boss — spawna solo se non c'è già un boss attivo
    if (_currentConfig!.boss != null && game.bossCount == 0) {
      _bossActive = true;
      game.spawnBoss(_currentConfig!.boss!);
    } else if (_currentConfig!.boss != null && game.bossCount > 0) {
      // C'è già un boss — aspetta che muoia prima di spawnare il nuovo
      _bossActive = true;
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
    if (_spawnTimer <= 0 && _currentConfig != null && !_allSpawned) {
      if (_spawnIndex < _currentConfig!.spawns.length) {
        final spawn = _currentConfig!.spawns[_spawnIndex];
        for (int i = 0; i < spawn.count; i++) {
          game.spawnEnemy(spawn.type);
          _totalSpawned++;
        }
        _spawnIndex++;

        if (_spawnIndex < _currentConfig!.spawns.length) {
          _spawnTimer = _currentConfig!.spawns[_spawnIndex].delay;
        } else {
          // Tutti i gruppi spawnati - avvia il delay di sicurezza
          _allSpawned = true;
          _postSpawnDelay = 1.5; // Aspetta 1.5s prima di controllare il completamento
        }
      }
    }

    // Check if wave is complete (SOLO dopo il delay post-spawn)
    if (_allSpawned) {
      _postSpawnDelay -= dt;
      if (_postSpawnDelay <= 0 && game.enemyCount == 0) {
        _completeWave();
      }
    }
  }

  void _completeWave() {
    _waveActive = false;

    // Notifica il game che la wave è completa (per Perfect Wave bonus)
    game.onWaveComplete();

    // Delay tra wave dipende dalla modalità
    final delayMs = (_mode == GameMode.survival || _mode == GameMode.tunnel) ? 500 : 2000;

    Future.delayed(Duration(milliseconds: delayMs), () {
      if (game.gameState == GameState.playing) {
        startWave(currentWave + 1);
      }
    });
  }

  void onBossDefeated() {
    _bossActive = false;
  }

  /// Boss Rush: ogni wave è UN SOLO boss. I nemici li spawna il boss stesso
  /// tramite _spawnMinions() nel boss_base.dart (automatico ogni 5s).
  /// NESSUN spawn separato per evitare conflitti con _bossActive.
  WaveConfig _generateBossRushWave(int wave) {
    final bosses = BossType.values;
    final bossIndex = (wave - 1) % bosses.length;
    // NESSUN spawn di nemici: il boss spawna i suoi minion automaticamente
    return WaveConfig(waveNumber: wave, spawns: [], boss: bosses[bossIndex]);
  }

  /// Survival: wave infinite con TANTI nemici crescenti, nessun boss, nessuna pausa
  WaveConfig _generateSurvivalWave(int wave) {
    final spawns = <WaveSpawn>[];
    spawns.add(WaveSpawn(EnemyType.drone, (15 + wave * 6).clamp(15, 150)));
    if (wave >= 2) spawns.add(WaveSpawn(EnemyType.kamikaze, (wave * 3).clamp(3, 50), delay: 0.5));
    if (wave >= 3) spawns.add(WaveSpawn(EnemyType.weaver, (wave * 2).clamp(2, 30), delay: 0.5));
    if (wave >= 4) spawns.add(WaveSpawn(EnemyType.swarmDrone, (wave * 4).clamp(8, 60), delay: 0.3));
    if (wave >= 5) spawns.add(WaveSpawn(EnemyType.splitter, (wave).clamp(1, 15), delay: 0.5));
    if (wave >= 7) spawns.add(WaveSpawn(EnemyType.bouncer, (wave ~/ 2).clamp(1, 12), delay: 0.5));
    if (wave >= 10) spawns.add(WaveSpawn(EnemyType.titan, 1 + wave ~/ 10, delay: 1));
    if (wave >= 12) spawns.add(WaveSpawn(EnemyType.glitch, (wave ~/ 3).clamp(1, 8), delay: 0.5));
    if (wave >= 15) spawns.add(WaveSpawn(EnemyType.blackHole, 1, delay: 2));
    return WaveConfig(waveNumber: wave, spawns: spawns);
  }

  /// Time Attack: TANTISSIMI nemici facili per fare punti velocemente
  WaveConfig _generateTimeAttackWave(int wave) {
    final spawns = <WaveSpawn>[
      WaveSpawn(EnemyType.drone, 25 + wave * 8),
      WaveSpawn(EnemyType.kamikaze, 8 + wave * 3, delay: 0.3),
      WaveSpawn(EnemyType.weaver, 5 + wave * 2, delay: 0.3),
      WaveSpawn(EnemyType.swarmDrone, 15 + wave * 5, delay: 0.2),
    ];
    if (wave >= 3) spawns.add(WaveSpawn(EnemyType.bouncer, wave * 2, delay: 0.5));
    if (wave >= 5) spawns.add(WaveSpawn(EnemyType.mine, wave * 2, delay: 0.5));
    return WaveConfig(waveNumber: wave, spawns: spawns);
  }

  /// Zen Mode: pochi nemici lenti, rilassante
  WaveConfig _generateZenWave(int wave) {
    final spawns = <WaveSpawn>[
      WaveSpawn(EnemyType.drone, 3 + wave),
      WaveSpawn(EnemyType.weaver, 1 + wave ~/ 2, delay: 2),
    ];
    if (wave >= 5) spawns.add(WaveSpawn(EnemyType.bouncer, 1 + wave ~/ 3, delay: 3));
    return WaveConfig(waveNumber: wave, spawns: spawns);
  }

  /// Tunnel: TANTI nemici in corridoio, boss ogni 5 wave, difficoltà crescente veloce
  WaveConfig _generateTunnelWave(int wave) {
    final spawns = <WaveSpawn>[];
    // Nel tunnel i nemici arrivano in fila, tanti e veloci
    spawns.add(WaveSpawn(EnemyType.drone, 12 + wave * 5));
    spawns.add(WaveSpawn(EnemyType.kamikaze, 4 + wave * 2, delay: 0.5));
    if (wave >= 3) spawns.add(WaveSpawn(EnemyType.swarmDrone, 20 + wave * 4, delay: 0.3));
    if (wave >= 5) spawns.add(WaveSpawn(EnemyType.bouncer, wave * 2, delay: 0.5));
    if (wave >= 7) spawns.add(WaveSpawn(EnemyType.weaver, wave * 2, delay: 0.5));
    if (wave >= 8) spawns.add(WaveSpawn(EnemyType.laserTurret, (wave ~/ 4).clamp(1, 4), delay: 1));
    if (wave >= 10) spawns.add(WaveSpawn(EnemyType.titan, 1 + wave ~/ 10, delay: 2));

    // Boss ogni 5 wave nel tunnel
    BossType? boss;
    if (wave % 5 == 0) {
      final bosses = BossType.values;
      boss = bosses[(wave ~/ 5 - 1) % bosses.length];
    }
    return WaveConfig(waveNumber: wave, spawns: spawns, boss: boss);
  }

  WaveConfig _generateEndlessWave(int wave) {
    // Genera ondate sempre più difficili oltre le wave configurate
    final spawns = <WaveSpawn>[];

    // Nemici base sempre presenti (RADDOPPIATI)
    spawns.add(WaveSpawn(EnemyType.drone, (20 + wave * 5).clamp(20, 120)));
    spawns.add(WaveSpawn(EnemyType.kamikaze, (wave).clamp(5, 40), delay: 1));
    spawns.add(WaveSpawn(EnemyType.weaver, (wave ~/ 2).clamp(3, 25), delay: 2));
    spawns.add(WaveSpawn(EnemyType.splitter, (wave ~/ 3).clamp(2, 12), delay: 3));
    spawns.add(WaveSpawn(EnemyType.shieldEnemy, (wave ~/ 4).clamp(2, 10), delay: 4));
    spawns.add(WaveSpawn(EnemyType.vortex, (wave ~/ 8).clamp(1, 5), delay: 5));

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

    // Batch 2+3 nemici nelle endless
    spawns.add(WaveSpawn(EnemyType.swarmDrone, (wave * 2).clamp(5, 40), delay: 1));
    if (wave % 3 == 0) {
      spawns.add(WaveSpawn(EnemyType.laserTurret, (wave ~/ 20).clamp(1, 3), delay: 5));
    }
    if (wave % 4 == 0) {
      spawns.add(WaveSpawn(EnemyType.timeBomb, (wave ~/ 15).clamp(1, 3), delay: 4));
    }
    if (wave % 5 == 0) {
      spawns.add(WaveSpawn(EnemyType.gravityWell, 1, delay: 6));
    }
    if (wave % 2 == 0) {
      spawns.add(WaveSpawn(EnemyType.decoy, (wave ~/ 8).clamp(1, 5), delay: 3));
    }
    spawns.add(WaveSpawn(EnemyType.healer, (wave ~/ 12).clamp(1, 2), delay: 5));
    spawns.add(WaveSpawn(EnemyType.tesla, (wave ~/ 10).clamp(1, 4), delay: 4));
    if (wave > 110) {
      spawns.add(WaveSpawn(EnemyType.orbiter, (wave ~/ 15).clamp(1, 3), delay: 5));
      spawns.add(WaveSpawn(EnemyType.siren, (wave ~/ 20).clamp(1, 2), delay: 6));
      spawns.add(WaveSpawn(EnemyType.necro, 1, delay: 7));
    }

    return WaveConfig(waveNumber: wave, spawns: spawns);
  }
}

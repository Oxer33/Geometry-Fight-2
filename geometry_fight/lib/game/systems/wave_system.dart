import 'dart:math' as math;
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
  int _totalSpawnedThisWave = 0; // Debug: contatore nemici spawnati
  double _interWaveDelay = 0; // Timer tra una wave e la successiva
  int? _pendingWave; // Wave da avviare dopo il delay
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
    _totalSpawnedThisWave = 0;

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
    // Gestione delay tra wave (sostituisce Future.delayed)
    if (_pendingWave != null) {
      _interWaveDelay -= dt;
      if (_interWaveDelay <= 0 && game.bossCount == 0 &&
          game.gameState == GameState.playing) {
        final wave = _pendingWave!;
        _pendingWave = null;
        startWave(wave);
      }
      return;
    }

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
          _totalSpawnedThisWave++;
        }
        _spawnIndex++;

        if (_spawnIndex < _currentConfig!.spawns.length) {
          _spawnTimer = _currentConfig!.spawns[_spawnIndex].delay;
        } else {
          // Tutti i gruppi spawnati - avvia il delay di sicurezza
          _allSpawned = true;
          _postSpawnDelay = 1.5;
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

    // Delay tra wave dipende dalla modalità (in secondi)
    double delaySec;
    if (_mode == GameMode.survival || _mode == GameMode.tunnel) {
      delaySec = 0.5;
    } else if (_mode == GameMode.bossRush) {
      delaySec = 3.0;
    } else {
      delaySec = 2.0;
    }

    // Schedula la prossima wave tramite timer (gestito in update)
    _pendingWave = currentWave + 1;
    _interWaveDelay = delaySec;
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

  /// Survival: wave infinite stile GW — TANTISSIMI mob stupidi + pochi letali
  WaveConfig _generateSurvivalWave(int wave) {
    final spawns = <WaveSpawn>[];
    // Massa stupida (70%)
    spawns.add(WaveSpawn(EnemyType.bouncer, (20 + wave * 3).clamp(20, 60)));
    spawns.add(WaveSpawn(EnemyType.swarmDrone, (15 + wave * 3).clamp(15, 50), delay: 0.3));
    spawns.add(WaveSpawn(EnemyType.drone, (10 + wave * 2).clamp(10, 30), delay: 0.5));
    // Pericolosi (30%)
    if (wave >= 2) spawns.add(WaveSpawn(EnemyType.kamikaze, (1 + wave).clamp(1, 12), delay: 1));
    if (wave >= 3) spawns.add(WaveSpawn(EnemyType.weaver, (wave ~/ 2).clamp(1, 8), delay: 1.5));
    if (wave >= 4) spawns.add(WaveSpawn(EnemyType.mine, (wave ~/ 2).clamp(1, 8), delay: 1));
    if (wave >= 5) spawns.add(WaveSpawn(EnemyType.splitter, (wave ~/ 3).clamp(1, 6), delay: 2));
    if (wave >= 7) spawns.add(WaveSpawn(EnemyType.shieldEnemy, (wave ~/ 5).clamp(1, 4), delay: 3));
    if (wave >= 10) spawns.add(WaveSpawn(EnemyType.titan, (wave ~/ 10).clamp(1, 2), delay: 4));
    if (wave >= 12) spawns.add(WaveSpawn(EnemyType.glitch, (wave ~/ 6).clamp(1, 4), delay: 3));
    if (wave >= 15) spawns.add(WaveSpawn(EnemyType.blackHole, 1, delay: 5));
    return WaveConfig(waveNumber: wave, spawns: spawns);
  }

  /// Time Attack: TANTISSIMI mob per fare punti — massa di stupidi + pochi pericolosi
  WaveConfig _generateTimeAttackWave(int wave) {
    final spawns = <WaveSpawn>[
      // Massa stupida per il punteggio
      WaveSpawn(EnemyType.bouncer, (25 + wave * 4).clamp(25, 60)),
      WaveSpawn(EnemyType.swarmDrone, (20 + wave * 4).clamp(20, 50), delay: 0.2),
      WaveSpawn(EnemyType.drone, (10 + wave * 2).clamp(10, 25), delay: 0.3),
      // Pericolosi per il challenge
      WaveSpawn(EnemyType.kamikaze, (2 + wave).clamp(2, 10), delay: 1),
      WaveSpawn(EnemyType.weaver, (1 + wave ~/ 2).clamp(1, 6), delay: 1.5),
    ];
    if (wave >= 3) spawns.add(WaveSpawn(EnemyType.mine, (2 + wave).clamp(2, 10), delay: 1));
    if (wave >= 5) spawns.add(WaveSpawn(EnemyType.splitter, (wave ~/ 3).clamp(1, 5), delay: 2));
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

  // === TUNNEL MODE: spawn continuo, no wave tradizionali ===
  double _tunnelSpawnTimer = 0.5;
  int _tunnelKillCount = 0; // Per boss ogni N kill
  int _nextBossAt = 30; // Soglia kill per il prossimo boss
  static final _tunnelRng = math.Random();

  /// Tunnel: spawn continuo di nemici randomici davanti al player.
  /// Mantiene sempre 10+ nemici vicini. Boss ogni 30 kill.
  void updateTunnel(double dt) {
    _tunnelSpawnTimer -= dt;

    // Mantieni almeno 10 nemici attivi — spawna se ce ne sono meno
    if (_tunnelSpawnTimer <= 0 || game.enemyCount < 10) {
      _tunnelSpawnTimer = 0.5 + _tunnelRng.nextDouble() * 0.8;

      // Spawna 2-4 nemici randomici ogni tick
      final count = 2 + _tunnelRng.nextInt(3);
      for (int i = 0; i < count; i++) {
        if (game.enemyCount >= 40) break; // Max 40 nel tunnel
        final type = _randomTunnelEnemyType();
        game.spawnEnemy(type);
      }
    }

    // Boss ogni 30 kill — usa _nextBossAt per evitare off-by-one
    if (_tunnelKillCount >= _nextBossAt && game.bossCount == 0) {
      final bosses = BossType.values;
      final bossIdx = (_nextBossAt ~/ 30 - 1) % bosses.length;
      game.spawnBoss(bosses[bossIdx]);
      _nextBossAt += 30; // Prossimo boss a +30 kill
    }
  }

  /// Tipo nemico casuale per il tunnel — 70% stupidi, 30% pericolosi
  EnemyType _randomTunnelEnemyType() {
    final roll = _tunnelRng.nextInt(100);
    // 70% mob stupidi
    if (roll < 30) return EnemyType.bouncer;
    if (roll < 50) return EnemyType.swarmDrone;
    if (roll < 65) return EnemyType.drone;
    if (roll < 70) return EnemyType.mine;
    // 30% pericolosi
    if (roll < 76) return EnemyType.kamikaze;
    if (roll < 82) return EnemyType.weaver;
    if (roll < 86) return EnemyType.splitter;
    if (roll < 90) return EnemyType.shieldEnemy;
    if (roll < 93) return EnemyType.glitch;
    if (roll < 96) return EnemyType.tesla;
    if (roll < 98) return EnemyType.titan;
    return EnemyType.healer;
  }

  /// Chiamato da game_world quando un nemico muore in tunnel mode
  void onTunnelKill() {
    _tunnelKillCount++;
  }

  /// Genera wave dummy per tunnel (il vero spawn è in _updateTunnel)
  WaveConfig _generateTunnelWave(int wave) {
    return WaveConfig(waveNumber: wave, spawns: []);
  }

  WaveConfig _generateEndlessWave(int wave) {
    // Endless: stile GW — massa enorme di mob stupidi + crescente varietà di pericolosi
    final spawns = <WaveSpawn>[];

    // ── MASSA STUPIDA (~70%) ──
    spawns.add(WaveSpawn(EnemyType.bouncer, (25 + wave * 2).clamp(25, 60)));
    spawns.add(WaveSpawn(EnemyType.swarmDrone, (20 + wave * 2).clamp(20, 50), delay: 0.3));
    spawns.add(WaveSpawn(EnemyType.drone, (12 + wave).clamp(12, 30), delay: 0.5));
    spawns.add(WaveSpawn(EnemyType.mine, (3 + wave ~/ 3).clamp(3, 12), delay: 1));

    // ── PERICOLOSI (~30%) ──
    spawns.add(WaveSpawn(EnemyType.kamikaze, (2 + wave ~/ 3).clamp(2, 10), delay: 2));
    spawns.add(WaveSpawn(EnemyType.weaver, (1 + wave ~/ 4).clamp(1, 8), delay: 2.5));
    spawns.add(WaveSpawn(EnemyType.splitter, (1 + wave ~/ 5).clamp(1, 6), delay: 3));
    spawns.add(WaveSpawn(EnemyType.shieldEnemy, (1 + wave ~/ 6).clamp(1, 5), delay: 3));
    spawns.add(WaveSpawn(EnemyType.leech, (wave ~/ 6).clamp(1, 5), delay: 3));
    spawns.add(WaveSpawn(EnemyType.pulsar, (wave ~/ 8).clamp(1, 4), delay: 3.5));
    spawns.add(WaveSpawn(EnemyType.glitch, (wave ~/ 10).clamp(1, 3), delay: 4));
    spawns.add(WaveSpawn(EnemyType.mirror, (wave ~/ 10).clamp(1, 3), delay: 4));
    spawns.add(WaveSpawn(EnemyType.vortex, (wave ~/ 12).clamp(1, 3), delay: 5));
    spawns.add(WaveSpawn(EnemyType.phantom, (wave ~/ 12).clamp(1, 3), delay: 5));
    spawns.add(WaveSpawn(EnemyType.tesla, (wave ~/ 12).clamp(1, 3), delay: 5));

    // Rari/speciali
    if (wave % 3 == 0) spawns.add(WaveSpawn(EnemyType.titan, (wave ~/ 15).clamp(1, 2), delay: 5));
    if (wave % 4 == 0) spawns.add(WaveSpawn(EnemyType.blackHole, 1, delay: 6));
    if (wave % 3 == 0) spawns.add(WaveSpawn(EnemyType.healer, (wave ~/ 20).clamp(1, 2), delay: 5));
    if (wave % 4 == 0) spawns.add(WaveSpawn(EnemyType.laserTurret, (wave ~/ 25).clamp(1, 2), delay: 6));
    if (wave % 5 == 0) spawns.add(WaveSpawn(EnemyType.gravityWell, 1, delay: 7));
    if (wave % 3 == 0) spawns.add(WaveSpawn(EnemyType.timeBomb, (wave ~/ 20).clamp(1, 2), delay: 5));
    if (wave % 2 == 0) spawns.add(WaveSpawn(EnemyType.decoy, (wave ~/ 10).clamp(1, 3), delay: 4));
    if (wave > 110) {
      spawns.add(WaveSpawn(EnemyType.orbiter, (wave ~/ 15).clamp(1, 3), delay: 5));
      spawns.add(WaveSpawn(EnemyType.siren, (wave ~/ 20).clamp(1, 2), delay: 6));
      spawns.add(WaveSpawn(EnemyType.necro, 1, delay: 7));
    }

    return WaveConfig(waveNumber: wave, spawns: spawns);
  }
}

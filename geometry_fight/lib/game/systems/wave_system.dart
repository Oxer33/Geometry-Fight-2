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
  double _interWaveDelay = 0; // Timer tra una wave e la successiva
  int? _pendingWave; // Wave da avviare dopo il delay
  late List<WaveConfig> _configs;
  WaveConfig? _currentConfig;

  WaveSystem(this.game) {
    _configs = generateWaveConfigs();
  }

  /// Ritorna la modalità di gioco attuale dal game
  GameMode get _mode => game.gameMode;

  /// Reset stato tunnel per nuova partita
  void reset() {
    _tunnelSpawnTimer = 0.5;
    _tunnelKillCount = 0;
    _nextBossAt = 30;
    currentWave = 0;
    _waveActive = false;
    _bossActive = false;
    _allSpawned = false;
    _pendingWave = null;
  }

  void startWave(int wave) {
    currentWave = wave;
    _waveActive = true;
    _spawnIndex = 0;
    _spawnTimer = 1.0; // Delay iniziale prima del primo spawn
    _allSpawned = false;
    _postSpawnDelay = 0;

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
      case GameMode.endlessBoss:
        _currentConfig = _generateEndlessBossWave(wave);
      case GameMode.dailyChallenge:
        _currentConfig = _generateDailyChallengeWave(wave);
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
      // Wait for boss to die, ma continua a spawnare nemici se presenti
      if (game.bossCount == 0 && _allSpawned && game.enemyCount == 0) {
        _bossActive = false;
        _completeWave();
        return;
      }
      // Se il boss è attivo ma ci sono ancora spawn da fare, NON uscire — continua sotto
      if (_allSpawned || (_currentConfig != null && _currentConfig!.spawns.isEmpty)) {
        return; // Tutti gli spawn sono stati fatti, aspetta solo il boss
      }
    }

    _spawnTimer -= dt;
    if (_spawnTimer <= 0 && _currentConfig != null && !_allSpawned) {
      if (_spawnIndex < _currentConfig!.spawns.length) {
        final spawn = _currentConfig!.spawns[_spawnIndex];
        for (int i = 0; i < spawn.count; i++) {
          game.spawnEnemy(spawn.type);
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
    // Massa stupida (70%) — raddoppiata
    spawns.add(WaveSpawn(EnemyType.bouncer, (40 + wave * 6).clamp(40, 120)));
    spawns.add(WaveSpawn(EnemyType.swarmDrone, (30 + wave * 6).clamp(30, 100), delay: 0.3));
    spawns.add(WaveSpawn(EnemyType.drone, (20 + wave * 4).clamp(20, 60), delay: 0.5));
    // Pericolosi (30%) — raddoppiati
    if (wave >= 2) spawns.add(WaveSpawn(EnemyType.kamikaze, (2 + wave * 2).clamp(2, 24), delay: 1));
    if (wave >= 3) spawns.add(WaveSpawn(EnemyType.weaver, (wave).clamp(1, 16), delay: 1.5));
    if (wave >= 4) spawns.add(WaveSpawn(EnemyType.mine, (wave).clamp(1, 16), delay: 1));
    if (wave >= 5) spawns.add(WaveSpawn(EnemyType.splitter, (wave * 2 ~/ 3).clamp(1, 12), delay: 2));
    if (wave >= 7) spawns.add(WaveSpawn(EnemyType.shieldEnemy, (wave * 2 ~/ 5).clamp(1, 8), delay: 3));
    if (wave >= 10) spawns.add(WaveSpawn(EnemyType.titan, (wave ~/ 5).clamp(1, 4), delay: 4));
    if (wave >= 12) spawns.add(WaveSpawn(EnemyType.glitch, (wave ~/ 3).clamp(1, 8), delay: 3));
    if (wave >= 15) spawns.add(WaveSpawn(EnemyType.blackHole, 2, delay: 5));
    return WaveConfig(waveNumber: wave, spawns: spawns);
  }

  /// Time Attack: TANTISSIMI mob per fare punti — massa di stupidi + pochi pericolosi
  WaveConfig _generateTimeAttackWave(int wave) {
    final spawns = <WaveSpawn>[
      // Massa stupida per il punteggio — raddoppiata
      WaveSpawn(EnemyType.bouncer, (50 + wave * 8).clamp(50, 120)),
      WaveSpawn(EnemyType.swarmDrone, (40 + wave * 8).clamp(40, 100), delay: 0.2),
      WaveSpawn(EnemyType.drone, (20 + wave * 4).clamp(20, 50), delay: 0.3),
      // Pericolosi per il challenge — raddoppiati
      WaveSpawn(EnemyType.kamikaze, (4 + wave * 2).clamp(4, 20), delay: 1),
      WaveSpawn(EnemyType.weaver, (2 + wave).clamp(2, 12), delay: 1.5),
    ];
    if (wave >= 3) spawns.add(WaveSpawn(EnemyType.mine, (4 + wave * 2).clamp(4, 20), delay: 1));
    if (wave >= 5) spawns.add(WaveSpawn(EnemyType.splitter, (wave * 2 ~/ 3).clamp(1, 10), delay: 2));
    return WaveConfig(waveNumber: wave, spawns: spawns);
  }

  /// Zen Mode: nemici rilassanti ma più numerosi
  WaveConfig _generateZenWave(int wave) {
    final spawns = <WaveSpawn>[
      WaveSpawn(EnemyType.drone, 6 + wave * 2),
      WaveSpawn(EnemyType.weaver, 2 + wave, delay: 2),
    ];
    if (wave >= 5) spawns.add(WaveSpawn(EnemyType.bouncer, 2 + wave * 2 ~/ 3, delay: 3));
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

    // Mantieni almeno 20 nemici attivi — spawna se ce ne sono meno
    if (_tunnelSpawnTimer <= 0 || game.enemyCount < 20) {
      _tunnelSpawnTimer = 0.3 + _tunnelRng.nextDouble() * 0.5;

      // Spawna 4-8 nemici randomici ogni tick
      final count = 4 + _tunnelRng.nextInt(5);
      for (int i = 0; i < count; i++) {
        if (game.enemyCount >= 80) break; // Max 80 nel tunnel
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

  /// Endless Boss: ogni wave è un boss con HP crescenti.
  /// Tra un boss e l'altro, una piccola wave di mob per fare rifornimento.
  WaveConfig _generateEndlessBossWave(int wave) {
    if (wave % 2 == 1) {
      // Wave dispari: mini-wave di mob per recuperare power-up e geom
      final mobCount = (10 + wave * 2).clamp(10, 40);
      return WaveConfig(
        waveNumber: wave,
        spawns: [
          WaveSpawn(EnemyType.bouncer, mobCount),
          WaveSpawn(EnemyType.swarmDrone, mobCount, delay: 0.5),
        ],
      );
    } else {
      // Wave pari: boss! Scala tra tutti i boss disponibili
      final bossIndex = ((wave ~/ 2) - 1) % BossType.values.length;
      return WaveConfig(
        waveNumber: wave,
        spawns: [],
        boss: BossType.values[bossIndex],
      );
    }
  }

  /// Daily Challenge: 30 wave fisse con seed giornaliero.
  /// Stesse wave per tutti i giocatori dello stesso giorno.
  WaveConfig _generateDailyChallengeWave(int wave) {
    // Seed basato sulla data: tutti i player hanno le stesse wave
    final now = DateTime.now();
    final daySeed = now.year * 10000 + now.month * 100 + now.day;
    final rng = math.Random(daySeed + wave * 7);

    // Tipi nemico filtrati per wave: early waves = solo nemici base
    final List<EnemyType> availableTypes;
    if (wave <= 3) {
      availableTypes = [EnemyType.drone, EnemyType.bouncer, EnemyType.swarmDrone, EnemyType.weaver];
    } else if (wave <= 7) {
      availableTypes = [EnemyType.drone, EnemyType.bouncer, EnemyType.swarmDrone, EnemyType.weaver, EnemyType.kamikaze, EnemyType.mine, EnemyType.splitter];
    } else if (wave <= 15) {
      availableTypes = [EnemyType.drone, EnemyType.bouncer, EnemyType.swarmDrone, EnemyType.weaver, EnemyType.kamikaze, EnemyType.mine, EnemyType.splitter, EnemyType.shieldEnemy, EnemyType.glitch, EnemyType.tesla];
    } else {
      availableTypes = EnemyType.values;
    }
    final spawns = <WaveSpawn>[];

    // 2-4 gruppi di nemici per wave
    final groupCount = 2 + rng.nextInt(3);
    for (int g = 0; g < groupCount; g++) {
      final type = availableTypes[rng.nextInt(availableTypes.length)];
      final count = (6 + wave + rng.nextInt(10)).clamp(6, 50);
      spawns.add(WaveSpawn(type, count, delay: g * 1.5));
    }

    // Boss ogni 10 wave
    BossType? boss;
    if (wave % 10 == 0 && wave > 0) {
      final bossTypes = BossType.values;
      boss = bossTypes[rng.nextInt(bossTypes.length)];
    }

    return WaveConfig(waveNumber: wave, spawns: spawns, boss: boss);
  }

  WaveConfig _generateEndlessWave(int wave) {
    // Endless: stile GW — massa enorme di mob stupidi + crescente varietà di pericolosi
    final spawns = <WaveSpawn>[];

    // ── MASSA STUPIDA (~70%) — raddoppiata ──
    spawns.add(WaveSpawn(EnemyType.bouncer, (50 + wave * 4).clamp(50, 120)));
    spawns.add(WaveSpawn(EnemyType.swarmDrone, (40 + wave * 4).clamp(40, 100), delay: 0.3));
    spawns.add(WaveSpawn(EnemyType.drone, (24 + wave * 2).clamp(24, 60), delay: 0.5));
    spawns.add(WaveSpawn(EnemyType.mine, (6 + wave * 2 ~/ 3).clamp(6, 24), delay: 1));

    // ── PERICOLOSI (~30%) — raddoppiati ──
    spawns.add(WaveSpawn(EnemyType.kamikaze, (4 + wave * 2 ~/ 3).clamp(4, 20), delay: 2));
    spawns.add(WaveSpawn(EnemyType.weaver, (2 + wave ~/ 2).clamp(2, 16), delay: 2.5));
    spawns.add(WaveSpawn(EnemyType.splitter, (2 + wave * 2 ~/ 5).clamp(2, 12), delay: 3));
    spawns.add(WaveSpawn(EnemyType.shieldEnemy, (2 + wave ~/ 3).clamp(2, 10), delay: 3));
    spawns.add(WaveSpawn(EnemyType.leech, (wave ~/ 3).clamp(2, 10), delay: 3));
    spawns.add(WaveSpawn(EnemyType.pulsar, (wave ~/ 4).clamp(2, 8), delay: 3.5));
    spawns.add(WaveSpawn(EnemyType.glitch, (wave ~/ 5).clamp(2, 6), delay: 4));
    spawns.add(WaveSpawn(EnemyType.mirror, (wave ~/ 5).clamp(2, 6), delay: 4));
    spawns.add(WaveSpawn(EnemyType.vortex, (wave ~/ 6).clamp(2, 6), delay: 5));
    spawns.add(WaveSpawn(EnemyType.phantom, (wave ~/ 6).clamp(2, 6), delay: 5));
    spawns.add(WaveSpawn(EnemyType.tesla, (wave ~/ 6).clamp(2, 6), delay: 5));

    // Rari/speciali — raddoppiati
    if (wave % 3 == 0) spawns.add(WaveSpawn(EnemyType.titan, (wave ~/ 8).clamp(1, 4), delay: 5));
    if (wave % 4 == 0) spawns.add(WaveSpawn(EnemyType.blackHole, 2, delay: 6));
    if (wave % 3 == 0) spawns.add(WaveSpawn(EnemyType.healer, (wave ~/ 10).clamp(1, 4), delay: 5));
    if (wave % 4 == 0) spawns.add(WaveSpawn(EnemyType.laserTurret, (wave ~/ 12).clamp(1, 4), delay: 6));
    if (wave % 5 == 0) spawns.add(WaveSpawn(EnemyType.gravityWell, 2, delay: 7));
    if (wave % 3 == 0) spawns.add(WaveSpawn(EnemyType.timeBomb, (wave ~/ 10).clamp(1, 4), delay: 5));
    if (wave % 2 == 0) spawns.add(WaveSpawn(EnemyType.decoy, (wave ~/ 5).clamp(2, 6), delay: 4));
    if (wave > 110) {
      spawns.add(WaveSpawn(EnemyType.orbiter, (wave ~/ 8).clamp(2, 6), delay: 5));
      spawns.add(WaveSpawn(EnemyType.siren, (wave ~/ 10).clamp(2, 4), delay: 6));
      spawns.add(WaveSpawn(EnemyType.necro, 2, delay: 7));
    }

    return WaveConfig(waveNumber: wave, spawns: spawns);
  }
}

import 'dart:math' as math;
import 'package:flame/components.dart';
import '../../data/constants.dart';
import '../../data/difficulty.dart';
import '../../data/wave_configs.dart';
import '../game_world.dart';

/// 25 formazioni geometriche uniche per il formation spawn system
enum _Formation {
  ring,
  diamond,
  cross,
  triangle,
  flower,
  star5,
  pinwheel,
  comet,
  infinity8,
  doubleSpiral,
  honeycomb,
  wShape,
  hexagon,
  tripleRing,
  sineWave,
  cascade,
  squareRing,
  burst,
  arrowHead,
  scatter,
  doublering,
  vArrow,
  xShape,
  arc,
  zigzag,
}

class WaveSystem {
  final GeometryFightGame game;
  int currentWave = 0;
  double _spawnTimer = 0;
  int _spawnIndex = 0;
  bool _waveActive = false;
  bool _bossActive = false;
  bool _allSpawned = false; // Tutti i gruppi sono stati spawnati
  double _postSpawnDelay = 0; // Delay dopo l'ultimo spawn prima di controllare completamento
  double _waveElapsedTimer = 0; // Timer per forzare completamento wave in classic mode
  double _interWaveDelay = 0; // Timer tra una wave e la successiva
  int? _pendingWave; // Wave da avviare dopo il delay
  late List<WaveConfig> _configs;
  WaveConfig? _currentConfig;
  final int _dailySeed;

  WaveSystem(this.game)
      : _dailySeed = _computeDailySeed(DateTime.now()) {
    _configs = generateWaveConfigs();
  }

  /// Ritorna la modalità di gioco attuale dal game
  GameMode get _mode => game.gameMode;

  static int _computeDailySeed(DateTime date) =>
      date.year * 10000 + date.month * 100 + date.day;

  int _scaledSpawnCount(int baseCount) {
    final scaled = (baseCount * game.diffConfig.enemyCountMultiplier).round();
    return scaled.clamp(1, 500);
  }

  double _scaledSpawnDelay(double baseDelay) {
    return (baseDelay * game.diffConfig.spawnDelayMultiplier).clamp(0.05, 10.0);
  }

  double _delayBeforeNextGroup() {
    // Richiesta design: in modalità classica ogni gruppo (tipo nemico) arriva
    // a cadenza fissa, così la wave è più leggibile.
    if (_mode == GameMode.classic) {
      return classicWaveGroupDelaySeconds;
    }
    return _scaledSpawnDelay(_currentConfig!.spawns[_spawnIndex].delay);
  }

  /// Reset stato tunnel per nuova partita
  void reset() {
    _tunnelSpawnTimer = 0.5;
    _tunnelKillCount = 0;
    _nextBossAt = 30;
    _tunnelBossCooldown = 0;
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
    _spawnTimer = _scaledSpawnDelay(1.0); // Delay iniziale prima del primo spawn
    _allSpawned = false;
    _postSpawnDelay = 0;
    _waveElapsedTimer = 0;

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

    // Wave senza gruppi spawnabili: considera subito "all spawned"
    if (_currentConfig!.spawns.isEmpty) {
      _allSpawned = true;
      _postSpawnDelay = 0;
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

    // Timer inizia solo quando tutti i gruppi sono spawnati — 30s DOPO l'ultimo spawn
    if (_allSpawned) _waveElapsedTimer += dt;

    // Classic mode: forza avanzamento wave dopo 30s — i nemici rimasti restano vivi!
    // Diventa sempre più difficile se non li uccidi.
    if (_mode == GameMode.classic && _allSpawned && _waveElapsedTimer >= 30.0 && !_bossActive) {
      _completeWave();
      return;
    }

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
        final spawnCount = _scaledSpawnCount(spawn.count);
        _spawnGroupWithFormation(spawn.type, spawnCount);
        _spawnIndex++;

        if (_spawnIndex < _currentConfig!.spawns.length) {
          _spawnTimer = _delayBeforeNextGroup();
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
    // Tunnel mode: dopo un boss ucciso aspetta 45s prima del prossimo (respiro al player)
    if (game.isTunnelMode) {
      _tunnelBossCooldown = 45.0;
    }
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
    spawns.add(WaveSpawn(EnemyType.swarmDrone, (50 + wave * 6).clamp(50, 120)));
    spawns.add(WaveSpawn(EnemyType.drone, (30 + wave * 4).clamp(30, 100), delay: 0.3));
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
    // Gate (bilanciere verde): rarissimo in survival — solo ogni 8 wave
    if (wave >= 8 && wave % 8 == 0) {
      spawns.add(WaveSpawn(EnemyType.gate, 1, delay: 10));
    }
    return WaveConfig(waveNumber: wave, spawns: spawns);
  }

  /// Time Attack: TANTISSIMI mob per fare punti — massa di stupidi + pochi pericolosi
  WaveConfig _generateTimeAttackWave(int wave) {
    final spawns = <WaveSpawn>[
      // Massa stupida per il punteggio — raddoppiata
      WaveSpawn(EnemyType.swarmDrone, (60 + wave * 8).clamp(60, 120)),
      WaveSpawn(EnemyType.drone, (40 + wave * 6).clamp(40, 100), delay: 0.2),
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
    if (wave >= 5) spawns.add(WaveSpawn(EnemyType.weaver, 2 + wave * 2 ~/ 3, delay: 3));
    return WaveConfig(waveNumber: wave, spawns: spawns);
  }

  // === TUNNEL MODE: spawn continuo, no wave tradizionali ===
  double _tunnelSpawnTimer = 0.5;
  int _tunnelKillCount = 0; // Per boss ogni N kill
  int _nextBossAt = 30; // Soglia kill per il prossimo boss
  double _tunnelBossCooldown = 0; // Tempo minimo tra boss (s)
  static final _tunnelRng = math.Random();

  /// Tunnel: spawn continuo di nemici randomici davanti al player.
  /// Mantiene sempre 10+ nemici vicini. Boss ogni 30 kill con cooldown 45s.
  void updateTunnel(double dt) {
    _tunnelSpawnTimer -= dt;
    if (_tunnelBossCooldown > 0) _tunnelBossCooldown -= dt;

    // Mantieni almeno 20 nemici attivi — spawna se ce ne sono meno
    if (_tunnelSpawnTimer <= 0 || game.enemyCount < 20) {
      _tunnelSpawnTimer = 0.3 + _tunnelRng.nextDouble() * 0.5;

      // Spawna 4-8 nemici randomici ogni tick
      final count = _scaledSpawnCount(4 + _tunnelRng.nextInt(5));
      for (int i = 0; i < count; i++) {
        if (game.enemyCount >= 80) break; // Max 80 nel tunnel
        final type = _randomTunnelEnemyType();
        game.spawnEnemy(type);
      }
    }

    // Boss ogni 30 kill — usa _nextBossAt per evitare off-by-one
    // Cooldown 45s dopo ogni boss ucciso (respiro al player)
    if (_tunnelKillCount >= _nextBossAt &&
        game.bossCount == 0 &&
        _tunnelBossCooldown <= 0) {
      final bosses = BossType.values;
      final bossIdx = (_nextBossAt ~/ 30 - 1) % bosses.length;
      game.spawnBoss(bosses[bossIdx]);
      _nextBossAt += 30; // Prossimo boss a +30 kill
    }
  }

  /// Tipo nemico casuale per il tunnel — 70% stupidi, 30% pericolosi
  EnemyType _randomTunnelEnemyType() {
    final roll = _tunnelRng.nextInt(100);
    // 70% mob stupidi — no duplicati con i bucket pericolosi sottostanti
    if (roll < 30) return EnemyType.swarmDrone;
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
    // Progressione "wave" nel tunnel: 1 wave ogni 30 kill (sincronizzata ai boss).
    final computedWave = (_tunnelKillCount ~/ 30) + 1;
    if (computedWave > currentWave) {
      currentWave = computedWave;
    }
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
          WaveSpawn(EnemyType.swarmDrone, mobCount),
          WaveSpawn(EnemyType.drone, mobCount, delay: 0.5),
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
    final rng = math.Random(_dailySeed + wave * 7);

    // Tipi nemico filtrati per wave: early waves = solo nemici base
    final List<EnemyType> availableTypes;
    if (wave <= 3) {
      availableTypes = [EnemyType.drone, EnemyType.swarmDrone, EnemyType.weaver, EnemyType.kamikaze];
    } else if (wave <= 7) {
      availableTypes = [EnemyType.drone, EnemyType.swarmDrone, EnemyType.weaver, EnemyType.kamikaze, EnemyType.mine, EnemyType.splitter];
    } else if (wave <= 15) {
      availableTypes = [EnemyType.drone, EnemyType.swarmDrone, EnemyType.weaver, EnemyType.kamikaze, EnemyType.mine, EnemyType.splitter, EnemyType.shieldEnemy, EnemyType.glitch, EnemyType.tesla];
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

  // ══════════════════════════════════════════════════════════════
  // FORMATION SPAWN SYSTEM — nemici appaiono in forme geometriche
  // invece di spawnarsi casualmente ai bordi dell'arena.
  // 25 formazioni uniche, assegnate per wave in classic mode.
  // ══════════════════════════════════════════════════════════════

  static final _formRng = math.Random();

  /// Returns the formation for a given classic-mode wave and spawn-group index.
  _Formation _classicFormation(int wave, int groupIndex) {
    const Map<int, List<_Formation>> waveFormations = {
      1:  [_Formation.ring, _Formation.cross],
      2:  [_Formation.diamond, _Formation.flower, _Formation.vArrow],
      3:  [_Formation.cross, _Formation.doublering, _Formation.cascade, _Formation.scatter, _Formation.ring],
      4:  [_Formation.triangle, _Formation.burst, _Formation.ring, _Formation.xShape, _Formation.arrowHead, _Formation.squareRing],
      5:  [_Formation.hexagon, _Formation.flower, _Formation.pinwheel, _Formation.scatter, _Formation.arrowHead, _Formation.sineWave, _Formation.cascade, _Formation.ring],
      6:  [_Formation.star5, _Formation.doublering, _Formation.diamond, _Formation.scatter, _Formation.vArrow, _Formation.sineWave, _Formation.cross, _Formation.ring],
      7:  [_Formation.pinwheel, _Formation.ring, _Formation.honeycomb, _Formation.xShape, _Formation.arrowHead, _Formation.tripleRing, _Formation.cascade, _Formation.squareRing, _Formation.arc],
      8:  [_Formation.comet, _Formation.flower, _Formation.triangle, _Formation.scatter, _Formation.burst, _Formation.sineWave, _Formation.vArrow, _Formation.cross, _Formation.diamond, _Formation.ring],
      9:  [_Formation.infinity8, _Formation.doublering, _Formation.hexagon, _Formation.scatter, _Formation.arrowHead, _Formation.sineWave, _Formation.diamond, _Formation.xShape, _Formation.cross, _Formation.arc],
      11: [_Formation.doubleSpiral, _Formation.ring, _Formation.star5, _Formation.scatter, _Formation.arrowHead, _Formation.sineWave, _Formation.doublering, _Formation.cascade],
      12: [_Formation.flower, _Formation.honeycomb, _Formation.comet, _Formation.scatter, _Formation.burst, _Formation.sineWave, _Formation.vArrow, _Formation.cross, _Formation.doublering, _Formation.arc, _Formation.ring],
      13: [_Formation.wShape, _Formation.burst, _Formation.hexagon, _Formation.scatter, _Formation.arrowHead, _Formation.zigzag, _Formation.diamond, _Formation.ring, _Formation.cross, _Formation.arc],
      14: [_Formation.honeycomb, _Formation.ring, _Formation.diamond, _Formation.cross, _Formation.arrowHead, _Formation.sineWave, _Formation.cascade, _Formation.star5, _Formation.doublering, _Formation.tripleRing, _Formation.ring],
      15: [_Formation.tripleRing, _Formation.flower, _Formation.cross, _Formation.scatter, _Formation.vArrow, _Formation.sineWave, _Formation.pinwheel, _Formation.ring, _Formation.comet],
      16: [_Formation.star5, _Formation.cascade, _Formation.hexagon, _Formation.scatter, _Formation.arrowHead, _Formation.doubleSpiral, _Formation.xShape, _Formation.ring, _Formation.sineWave, _Formation.arc],
      17: [_Formation.infinity8, _Formation.doublering, _Formation.diamond, _Formation.xShape, _Formation.burst, _Formation.zigzag, _Formation.arrowHead, _Formation.flower, _Formation.ring],
      18: [_Formation.squareRing, _Formation.ring, _Formation.triangle, _Formation.scatter, _Formation.arrowHead, _Formation.sineWave, _Formation.cascade, _Formation.cross, _Formation.diamond, _Formation.arc, _Formation.ring],
      19: [_Formation.pinwheel, _Formation.flower, _Formation.wShape, _Formation.scatter, _Formation.vArrow, _Formation.sineWave, _Formation.xShape, _Formation.hexagon, _Formation.ring, _Formation.arc, _Formation.doublering],
      21: [_Formation.arrowHead, _Formation.ring, _Formation.star5, _Formation.scatter, _Formation.burst, _Formation.sineWave, _Formation.doublering, _Formation.cascade, _Formation.ring],
      22: [_Formation.zigzag, _Formation.burst, _Formation.hexagon, _Formation.scatter, _Formation.arrowHead, _Formation.sineWave, _Formation.diamond, _Formation.xShape, _Formation.flower, _Formation.cross],
      23: [_Formation.doublering, _Formation.flower, _Formation.honeycomb, _Formation.scatter, _Formation.arrowHead, _Formation.sineWave, _Formation.cross, _Formation.comet, _Formation.ring, _Formation.arc],
      24: [_Formation.sineWave, _Formation.ring, _Formation.diamond, _Formation.xShape, _Formation.arrowHead, _Formation.zigzag, _Formation.doubleSpiral, _Formation.flower, _Formation.cross, _Formation.arc, _Formation.ring],
      25: [_Formation.xShape, _Formation.flower, _Formation.star5, _Formation.scatter, _Formation.arrowHead, _Formation.tripleRing, _Formation.pinwheel, _Formation.ring, _Formation.comet],
      26: [_Formation.cascade, _Formation.ring, _Formation.honeycomb, _Formation.scatter, _Formation.arrowHead, _Formation.wShape, _Formation.diamond, _Formation.xShape, _Formation.sineWave, _Formation.cross],
      27: [_Formation.pinwheel, _Formation.doublering, _Formation.comet, _Formation.scatter, _Formation.burst, _Formation.sineWave, _Formation.vArrow, _Formation.cross, _Formation.ring, _Formation.arc],
      28: [_Formation.comet, _Formation.flower, _Formation.triangle, _Formation.scatter, _Formation.arrowHead, _Formation.zigzag, _Formation.diamond, _Formation.ring, _Formation.cross, _Formation.doublering, _Formation.ring, _Formation.sineWave],
      29: [_Formation.wShape, _Formation.ring, _Formation.hexagon, _Formation.scatter, _Formation.arrowHead, _Formation.sineWave, _Formation.xShape, _Formation.doubleSpiral, _Formation.cross, _Formation.arc],
      31: [_Formation.star5, _Formation.flower, _Formation.ring, _Formation.scatter, _Formation.arrowHead, _Formation.sineWave, _Formation.cascade, _Formation.honeycomb, _Formation.cross, _Formation.arc, _Formation.doublering],
      32: [_Formation.honeycomb, _Formation.burst, _Formation.diamond, _Formation.scatter, _Formation.vArrow, _Formation.zigzag, _Formation.ring, _Formation.xShape, _Formation.sineWave, _Formation.comet, _Formation.cross],
      33: [_Formation.tripleRing, _Formation.ring, _Formation.hexagon, _Formation.scatter, _Formation.arrowHead, _Formation.sineWave, _Formation.squareRing, _Formation.flower, _Formation.cross, _Formation.arc],
      34: [_Formation.doubleSpiral, _Formation.flower, _Formation.star5, _Formation.scatter, _Formation.arrowHead, _Formation.sineWave, _Formation.doublering, _Formation.diamond, _Formation.xShape, _Formation.ring, _Formation.arc, _Formation.cross],
      35: [_Formation.infinity8, _Formation.ring, _Formation.honeycomb, _Formation.scatter, _Formation.vArrow, _Formation.sineWave, _Formation.cascade, _Formation.arrowHead, _Formation.cross, _Formation.doublering, _Formation.comet],
      36: [_Formation.zigzag, _Formation.burst, _Formation.diamond, _Formation.scatter, _Formation.arrowHead, _Formation.tripleRing, _Formation.ring, _Formation.xShape, _Formation.sineWave, _Formation.cross],
      37: [_Formation.squareRing, _Formation.flower, _Formation.hexagon, _Formation.scatter, _Formation.arrowHead, _Formation.sineWave, _Formation.wShape, _Formation.ring, _Formation.cross, _Formation.arc, _Formation.doublering],
      38: [_Formation.wShape, _Formation.ring, _Formation.comet, _Formation.scatter, _Formation.arrowHead, _Formation.zigzag, _Formation.diamond, _Formation.xShape, _Formation.sineWave, _Formation.flower, _Formation.cross, _Formation.doublering],
      39: [_Formation.arrowHead, _Formation.doublering, _Formation.star5, _Formation.scatter, _Formation.burst, _Formation.sineWave, _Formation.ring, _Formation.cascade, _Formation.cross, _Formation.arc, _Formation.flower],
      41: [_Formation.doubleSpiral, _Formation.flower, _Formation.ring, _Formation.scatter, _Formation.arrowHead, _Formation.zigzag, _Formation.honeycomb, _Formation.doublering, _Formation.cross, _Formation.arc],
      42: [_Formation.flower, _Formation.burst, _Formation.diamond, _Formation.scatter, _Formation.vArrow, _Formation.sineWave, _Formation.ring, _Formation.xShape, _Formation.comet, _Formation.cross, _Formation.arc],
      43: [_Formation.hexagon, _Formation.ring, _Formation.honeycomb, _Formation.scatter, _Formation.arrowHead, _Formation.sineWave, _Formation.wShape, _Formation.flower, _Formation.cross, _Formation.doublering, _Formation.arc],
      44: [_Formation.star5, _Formation.doublering, _Formation.scatter, _Formation.arrowHead, _Formation.tripleRing, _Formation.pinwheel, _Formation.ring, _Formation.cascade, _Formation.cross],
      46: [_Formation.tripleRing, _Formation.ring, _Formation.hexagon, _Formation.scatter, _Formation.vArrow, _Formation.sineWave, _Formation.squareRing, _Formation.flower, _Formation.cross, _Formation.arc],
      47: [_Formation.comet, _Formation.flower, _Formation.diamond, _Formation.scatter, _Formation.arrowHead, _Formation.zigzag, _Formation.ring, _Formation.xShape, _Formation.sineWave, _Formation.cross, _Formation.doublering],
      48: [_Formation.infinity8, _Formation.burst, _Formation.star5, _Formation.scatter, _Formation.arrowHead, _Formation.sineWave, _Formation.doublering, _Formation.honeycomb, _Formation.cross, _Formation.arc, _Formation.flower],
      49: [_Formation.pinwheel, _Formation.ring, _Formation.cascade, _Formation.scatter, _Formation.burst, _Formation.zigzag, _Formation.arrowHead, _Formation.doublering, _Formation.cross, _Formation.sineWave],
      51: [_Formation.wShape, _Formation.flower, _Formation.ring, _Formation.scatter, _Formation.arrowHead, _Formation.sineWave, _Formation.xShape, _Formation.star5, _Formation.cross, _Formation.arc, _Formation.doublering],
      52: [_Formation.squareRing, _Formation.burst, _Formation.hexagon, _Formation.scatter, _Formation.vArrow, _Formation.sineWave, _Formation.ring, _Formation.comet, _Formation.cross, _Formation.flower, _Formation.arc],
      53: [_Formation.doubleSpiral, _Formation.ring, _Formation.honeycomb, _Formation.scatter, _Formation.arrowHead, _Formation.zigzag, _Formation.diamond, _Formation.xShape, _Formation.sineWave, _Formation.cross, _Formation.doublering],
      54: [_Formation.zigzag, _Formation.doublering, _Formation.star5, _Formation.scatter, _Formation.arrowHead, _Formation.tripleRing, _Formation.ring, _Formation.flower, _Formation.cascade, _Formation.arc],
      55: [_Formation.tripleRing, _Formation.arc],
      56: [_Formation.honeycomb, _Formation.flower, _Formation.diamond, _Formation.scatter, _Formation.arrowHead, _Formation.sineWave, _Formation.wShape, _Formation.ring, _Formation.cross, _Formation.arc, _Formation.doublering],
      57: [_Formation.arrowHead, _Formation.burst, _Formation.hexagon, _Formation.scatter, _Formation.zigzag, _Formation.ring, _Formation.xShape, _Formation.sineWave, _Formation.flower, _Formation.cross],
      58: [_Formation.comet, _Formation.ring, _Formation.star5, _Formation.scatter, _Formation.vArrow, _Formation.sineWave, _Formation.doublering, _Formation.honeycomb, _Formation.cross, _Formation.arc, _Formation.flower],
      59: [_Formation.tripleRing, _Formation.flower, _Formation.cascade, _Formation.scatter, _Formation.arrowHead, _Formation.sineWave, _Formation.squareRing, _Formation.ring, _Formation.cross, _Formation.doublering, _Formation.arc],
      60: [_Formation.ring, _Formation.doubleSpiral],
      61: [_Formation.infinity8, _Formation.burst, _Formation.ring, _Formation.scatter, _Formation.arrowHead, _Formation.zigzag, _Formation.flower, _Formation.xShape, _Formation.sineWave, _Formation.cross, _Formation.doublering],
      62: [_Formation.star5, _Formation.ring, _Formation.honeycomb, _Formation.scatter, _Formation.burst, _Formation.sineWave, _Formation.wShape, _Formation.doublering, _Formation.cross, _Formation.arc, _Formation.flower],
      63: [_Formation.pinwheel, _Formation.flower, _Formation.diamond, _Formation.scatter, _Formation.arrowHead, _Formation.tripleRing, _Formation.ring, _Formation.xShape, _Formation.comet, _Formation.cross, _Formation.sineWave],
      64: [_Formation.doubleSpiral, _Formation.doublering, _Formation.hexagon, _Formation.scatter, _Formation.vArrow, _Formation.zigzag, _Formation.ring, _Formation.flower, _Formation.cross, _Formation.arc, _Formation.cascade],
      65: [_Formation.hexagon, _Formation.cascade],
      66: [_Formation.squareRing, _Formation.flower, _Formation.star5, _Formation.scatter, _Formation.arrowHead, _Formation.sineWave, _Formation.doublering, _Formation.burst, _Formation.cross, _Formation.arc, _Formation.ring],
      67: [_Formation.wShape, _Formation.ring, _Formation.comet, _Formation.scatter, _Formation.arrowHead, _Formation.zigzag, _Formation.xShape, _Formation.flower, _Formation.sineWave, _Formation.cross, _Formation.doublering],
      68: [_Formation.flower, _Formation.burst, _Formation.hexagon, _Formation.scatter, _Formation.burst, _Formation.sineWave, _Formation.honeycomb, _Formation.ring, _Formation.cross, _Formation.arc, _Formation.doublering, _Formation.flower],
      69: [_Formation.zigzag, _Formation.ring, _Formation.diamond, _Formation.scatter, _Formation.arrowHead, _Formation.tripleRing, _Formation.pinwheel, _Formation.doublering, _Formation.cross, _Formation.sineWave, _Formation.arc],
      70: [_Formation.scatter, _Formation.zigzag],
      71: [_Formation.tripleRing, _Formation.flower, _Formation.ring, _Formation.scatter, _Formation.arrowHead, _Formation.sineWave, _Formation.star5, _Formation.xShape, _Formation.cross, _Formation.arc, _Formation.doublering],
      72: [_Formation.honeycomb, _Formation.burst, _Formation.hexagon, _Formation.scatter, _Formation.vArrow, _Formation.zigzag, _Formation.ring, _Formation.flower, _Formation.sineWave, _Formation.cross, _Formation.arc],
      73: [_Formation.infinity8, _Formation.ring, _Formation.star5, _Formation.scatter, _Formation.arrowHead, _Formation.sineWave, _Formation.doublering, _Formation.wShape, _Formation.cross, _Formation.arc, _Formation.flower, _Formation.doubleSpiral],
      74: [_Formation.comet, _Formation.doublering, _Formation.cascade, _Formation.scatter, _Formation.arrowHead, _Formation.tripleRing, _Formation.ring, _Formation.xShape, _Formation.sineWave, _Formation.cross, _Formation.flower, _Formation.arc],
      75: [_Formation.squareRing, _Formation.cross],
      76: [_Formation.star5, _Formation.flower, _Formation.honeycomb, _Formation.scatter, _Formation.burst, _Formation.sineWave, _Formation.diamond, _Formation.ring, _Formation.cross, _Formation.arc, _Formation.doublering, _Formation.zigzag],
      77: [_Formation.pinwheel, _Formation.ring, _Formation.star5, _Formation.scatter, _Formation.arrowHead, _Formation.sineWave, _Formation.wShape, _Formation.flower, _Formation.cross, _Formation.comet, _Formation.doublering, _Formation.arc],
      78: [_Formation.doubleSpiral, _Formation.burst, _Formation.hexagon, _Formation.scatter, _Formation.vArrow, _Formation.zigzag, _Formation.tripleRing, _Formation.ring, _Formation.sineWave, _Formation.cross, _Formation.flower, _Formation.doublering],
      79: [_Formation.squareRing, _Formation.ring, _Formation.star5, _Formation.scatter, _Formation.arrowHead, _Formation.sineWave, _Formation.xShape, _Formation.honeycomb, _Formation.cross, _Formation.arc, _Formation.flower, _Formation.doublering],
      80: [_Formation.xShape, _Formation.scatter],
      81: [_Formation.wShape, _Formation.flower, _Formation.diamond, _Formation.scatter, _Formation.arrowHead, _Formation.tripleRing, _Formation.ring, _Formation.xShape, _Formation.sineWave, _Formation.cross, _Formation.doublering, _Formation.arc],
      82: [_Formation.honeycomb, _Formation.burst, _Formation.ring, _Formation.scatter, _Formation.zigzag, _Formation.flower, _Formation.doublering, _Formation.cross, _Formation.sineWave, _Formation.arc, _Formation.star5],
      83: [_Formation.infinity8, _Formation.ring, _Formation.hexagon, _Formation.scatter, _Formation.arrowHead, _Formation.sineWave, _Formation.comet, _Formation.xShape, _Formation.cross, _Formation.flower, _Formation.doublering, _Formation.arc, _Formation.doubleSpiral],
      84: [_Formation.squareRing, _Formation.doublering, _Formation.star5, _Formation.scatter, _Formation.vArrow, _Formation.tripleRing, _Formation.pinwheel, _Formation.ring, _Formation.cross, _Formation.sineWave, _Formation.arc, _Formation.flower, _Formation.cascade],
      85: [_Formation.honeycomb, _Formation.ring],
      86: [_Formation.tripleRing, _Formation.flower, _Formation.honeycomb, _Formation.scatter, _Formation.arrowHead, _Formation.sineWave, _Formation.star5, _Formation.ring, _Formation.cross, _Formation.arc, _Formation.doublering, _Formation.burst, _Formation.zigzag],
      87: [_Formation.doubleSpiral, _Formation.burst, _Formation.hexagon, _Formation.scatter, _Formation.arrowHead, _Formation.zigzag, _Formation.ring, _Formation.xShape, _Formation.sineWave, _Formation.flower, _Formation.cross, _Formation.doublering, _Formation.arc],
      88: [_Formation.comet, _Formation.ring, _Formation.star5, _Formation.scatter, _Formation.burst, _Formation.sineWave, _Formation.wShape, _Formation.doublering, _Formation.cross, _Formation.arc, _Formation.flower, _Formation.hexagon, _Formation.tripleRing],
      89: [_Formation.flower, _Formation.doublering, _Formation.cascade, _Formation.scatter, _Formation.arrowHead, _Formation.tripleRing, _Formation.squareRing, _Formation.ring, _Formation.cross, _Formation.sineWave, _Formation.arc, _Formation.flower, _Formation.diamond],
      90: [_Formation.ring, _Formation.doubleSpiral],
      91: [_Formation.star5, _Formation.burst, _Formation.ring, _Formation.scatter, _Formation.arrowHead, _Formation.sineWave, _Formation.infinity8, _Formation.xShape, _Formation.cross, _Formation.doublering, _Formation.arc, _Formation.flower, _Formation.zigzag, _Formation.pinwheel],
      92: [_Formation.pinwheel, _Formation.ring, _Formation.hexagon, _Formation.scatter, _Formation.vArrow, _Formation.zigzag, _Formation.flower, _Formation.doublering, _Formation.cross, _Formation.sineWave, _Formation.arc, _Formation.burst, _Formation.comet],
      93: [_Formation.wShape, _Formation.flower, _Formation.star5, _Formation.scatter, _Formation.arrowHead, _Formation.tripleRing, _Formation.ring, _Formation.xShape, _Formation.sineWave, _Formation.cross, _Formation.arc, _Formation.doublering, _Formation.honeycomb, _Formation.doubleSpiral],
      94: [_Formation.honeycomb, _Formation.burst, _Formation.cascade, _Formation.scatter, _Formation.arrowHead, _Formation.sineWave, _Formation.squareRing, _Formation.ring, _Formation.cross, _Formation.flower, _Formation.doublering, _Formation.arc, _Formation.diamond, _Formation.zigzag],
      95: [_Formation.burst, _Formation.scatter],
      96: [_Formation.infinity8, _Formation.ring, _Formation.star5, _Formation.scatter, _Formation.burst, _Formation.sineWave, _Formation.doubleSpiral, _Formation.doublering, _Formation.cross, _Formation.arc, _Formation.flower, _Formation.xShape, _Formation.tripleRing, _Formation.zigzag, _Formation.comet],
      97: [_Formation.tripleRing, _Formation.flower, _Formation.hexagon, _Formation.scatter, _Formation.arrowHead, _Formation.zigzag, _Formation.ring, _Formation.xShape, _Formation.sineWave, _Formation.cross, _Formation.doublering, _Formation.arc, _Formation.wShape, _Formation.burst, _Formation.star5],
      98: [_Formation.squareRing, _Formation.burst, _Formation.honeycomb, _Formation.scatter, _Formation.vArrow, _Formation.sineWave, _Formation.flower, _Formation.ring, _Formation.cross, _Formation.arc, _Formation.doublering, _Formation.tripleRing, _Formation.arrowHead, _Formation.diamond, _Formation.zigzag, _Formation.comet],
      99: [_Formation.doubleSpiral, _Formation.ring, _Formation.star5, _Formation.scatter, _Formation.arrowHead, _Formation.tripleRing, _Formation.pinwheel, _Formation.xShape, _Formation.sineWave, _Formation.cross, _Formation.doublering, _Formation.arc, _Formation.flower, _Formation.wShape, _Formation.burst, _Formation.zigzag, _Formation.comet, _Formation.cascade],
      100: [_Formation.squareRing, _Formation.tripleRing, _Formation.cross],
    };

    final list = waveFormations[wave];
    if (list != null && groupIndex < list.length) {
      return list[groupIndex];
    }
    // Fallback deterministic per boss waves e wave non mappate
    return _Formation.values[(wave * 7 + groupIndex * 3) % _Formation.values.length];
  }

  /// Spawna un gruppo di nemici in una formazione geometrica.
  /// In classic mode usa la formazione assegnata alla wave/gruppo.
  /// In altri modi sceglie casualmente tra le 25 formazioni.
  /// In tunnel mode mantiene lo spawn fuori schermo originale.
  void _spawnGroupWithFormation(EnemyType type, int count) {
    if (_mode == GameMode.tunnel) {
      for (int i = 0; i < count; i++) {
        game.spawnEnemy(type);
      }
      return;
    }

    final formation = (_mode == GameMode.classic)
        ? _classicFormation(currentWave, _spawnIndex)
        : _Formation.values[_formRng.nextInt(_Formation.values.length)];

    final center = _randomFormationCenter();
    final playerPos = game.player.position;
    final positions = _buildFormation(formation, count, center, playerPos);

    for (final pos in positions) {
      final clamped = Vector2(
        pos.x.clamp(20.0, arenaWidth - 20.0),
        pos.y.clamp(20.0, arenaHeight - 20.0),
      );
      game.spawnEnemy(type, clamped);
    }
  }

  /// Centro casuale nell'arena, lontano dai bordi
  Vector2 _randomFormationCenter() {
    const pad = 160.0;
    return Vector2(
      pad + _formRng.nextDouble() * (arenaWidth - pad * 2),
      pad + _formRng.nextDouble() * (arenaHeight - pad * 2),
    );
  }

  /// Dispatcher: seleziona il metodo di formazione corretto
  List<Vector2> _buildFormation(_Formation f, int count, Vector2 center, Vector2 playerPos) {
    switch (f) {
      case _Formation.ring:         return _fRing(count, center, playerPos);
      case _Formation.diamond:      return _fDiamond(count, center, playerPos);
      case _Formation.cross:        return _fCross(count, center, playerPos);
      case _Formation.triangle:     return _fTriangle(count, center, playerPos);
      case _Formation.flower:       return _fFlower(count, center, playerPos);
      case _Formation.star5:        return _fStar5(count, center, playerPos);
      case _Formation.pinwheel:     return _fPinwheel(count, center, playerPos);
      case _Formation.comet:        return _fComet(count, center, playerPos);
      case _Formation.infinity8:    return _fInfinity8(count, center, playerPos);
      case _Formation.doubleSpiral: return _fDoubleSpiral(count, center, playerPos);
      case _Formation.honeycomb:    return _fHoneycomb(count, center, playerPos);
      case _Formation.wShape:       return _fWShape(count, center, playerPos);
      case _Formation.hexagon:      return _fHexagon(count, center, playerPos);
      case _Formation.tripleRing:   return _fTripleRing(count, center, playerPos);
      case _Formation.sineWave:     return _fSineWave(count, center, playerPos);
      case _Formation.cascade:      return _fCascade(count, center, playerPos);
      case _Formation.squareRing:   return _fSquareRing(count, center, playerPos);
      case _Formation.burst:        return _fBurst(count, center, playerPos);
      case _Formation.arrowHead:    return _fArrowHead(count, center, playerPos);
      case _Formation.scatter:      return _fScatter(count, center, playerPos);
      case _Formation.doublering:   return _fDoublering(count, center, playerPos);
      case _Formation.vArrow:       return _fVArrow(count, center, playerPos);
      case _Formation.xShape:       return _fXShape(count, center, playerPos);
      case _Formation.arc:          return _fArc(count, center, playerPos);
      case _Formation.zigzag:       return _fZigzag(count, center, playerPos);
    }
  }

  // ── Formation implementations ──────────────────────────────────

  /// Ring: nemici equidistanti su una circonferenza
  List<Vector2> _fRing(int count, Vector2 center, Vector2 _) {
    final radius = 60.0 + count * 3.5;
    return List.generate(count, (i) {
      final angle = i * math.pi * 2 / count;
      return center + Vector2(math.cos(angle) * radius, math.sin(angle) * radius);
    });
  }

  /// Diamond: rombo (4 lati)
  List<Vector2> _fDiamond(int count, Vector2 center, Vector2 _) {
    final r = 70.0 + count * 2.0;
    final corners = [
      Vector2(0, -r), Vector2(r, 0), Vector2(0, r), Vector2(-r, 0),
    ];
    final perSide = math.max(2, count ~/ 4);
    final positions = <Vector2>[];
    for (int s = 0; s < 4 && positions.length < count; s++) {
      final start = corners[s];
      final end = corners[(s + 1) % 4];
      for (int p = 0; p < perSide && positions.length < count; p++) {
        final t = p / perSide;
        positions.add(center + Vector2(
          start.x + (end.x - start.x) * t,
          start.y + (end.y - start.y) * t,
        ));
      }
    }
    return positions;
  }

  /// Cross: più (+) con 4 braccia
  List<Vector2> _fCross(int count, Vector2 center, Vector2 _) {
    final perArm = math.max(2, count ~/ 4);
    // Direzioni: su, destra, giù, sinistra
    const dirs = [
      [0.0, -1.0], [1.0, 0.0], [0.0, 1.0], [-1.0, 0.0],
    ];
    final positions = <Vector2>[];
    for (int a = 0; a < 4 && positions.length < count; a++) {
      final dx = dirs[a][0];
      final dy = dirs[a][1];
      for (int p = 0; p < perArm && positions.length < count; p++) {
        final dist = 20.0 + p * (110.0 / math.max(1, perArm - 1));
        positions.add(center + Vector2(dx * dist, dy * dist));
      }
    }
    return positions;
  }

  /// Triangle: triangolo equilatero (3 lati)
  List<Vector2> _fTriangle(int count, Vector2 center, Vector2 _) {
    const r = 110.0;
    final vertices = List.generate(3, (k) {
      final angle = -math.pi / 2 + k * math.pi * 2 / 3;
      return Vector2(math.cos(angle) * r, math.sin(angle) * r);
    });
    final perSide = math.max(2, count ~/ 3);
    final positions = <Vector2>[];
    for (int s = 0; s < 3 && positions.length < count; s++) {
      final start = vertices[s];
      final end = vertices[(s + 1) % 3];
      for (int p = 0; p < perSide && positions.length < count; p++) {
        final t = p / perSide;
        positions.add(center + Vector2(
          start.x + (end.x - start.x) * t,
          start.y + (end.y - start.y) * t,
        ));
      }
    }
    return positions;
  }

  /// Flower: N petali disposti a cerchio, ognuno è un piccolo cluster
  List<Vector2> _fFlower(int count, Vector2 center, Vector2 _) {
    final petals = math.max(3, math.min(8, count ~/ 5)).clamp(3, 8);
    final enemiesPerPetal = (count / petals).ceil();
    const petalDist = 110.0;
    const petalRadius = 40.0;
    final positions = <Vector2>[];
    for (int p = 0; p < petals && positions.length < count; p++) {
      final petalAngle = p * math.pi * 2 / petals;
      final petalCenter = center + Vector2(
        math.cos(petalAngle) * petalDist,
        math.sin(petalAngle) * petalDist,
      );
      for (int e = 0; e < enemiesPerPetal && positions.length < count; e++) {
        final angle = e * math.pi * 2 / enemiesPerPetal;
        positions.add(petalCenter + Vector2(
          math.cos(angle) * petalRadius,
          math.sin(angle) * petalRadius,
        ));
      }
    }
    return positions;
  }

  /// Star5: stella a 5 punte — punti distribuiti sui 10 segmenti
  List<Vector2> _fStar5(int count, Vector2 center, Vector2 _) {
    const outerR = 120.0;
    const innerR = 50.0;
    // 10 vertici alternati: outer, inner, outer, inner...
    final starVerts = List.generate(10, (i) {
      final angle = i * math.pi / 5 - math.pi / 2;
      final r = (i % 2 == 0) ? outerR : innerR;
      return Vector2(math.cos(angle) * r, math.sin(angle) * r);
    });
    // Distribuzione dei count punti sui 10 segmenti
    final pointsPerSeg = math.max(1, count ~/ 10);
    final positions = <Vector2>[];
    for (int s = 0; s < 10 && positions.length < count; s++) {
      final start = starVerts[s];
      final end = starVerts[(s + 1) % 10];
      final pts = (s == 9) ? (count - positions.length) : pointsPerSeg;
      for (int p = 0; p < pts && positions.length < count; p++) {
        final t = pts <= 1 ? 0.0 : p / (pts - 1);
        positions.add(center + Vector2(
          start.x + (end.x - start.x) * t,
          start.y + (end.y - start.y) * t,
        ));
      }
    }
    return positions;
  }

  /// Pinwheel: 3 braccia curvilinee (spirale a 3 bracci)
  List<Vector2> _fPinwheel(int count, Vector2 center, Vector2 _) {
    const armLen = 130.0;
    final ppa = (count / 3).ceil(); // points per arm
    final positions = <Vector2>[];
    for (int a = 0; a < 3 && positions.length < count; a++) {
      final baseAngle = a * math.pi * 2 / 3;
      for (int p = 0; p < ppa && positions.length < count; p++) {
        final t = p / math.max(1, ppa - 1);
        final angle = baseAngle + t * math.pi * 0.8;
        final r = t * armLen;
        positions.add(center + Vector2(math.cos(angle) * r, math.sin(angle) * r));
      }
    }
    return positions;
  }

  /// Comet: testa densa + coda sparsa nella direzione opposta al player
  List<Vector2> _fComet(int count, Vector2 center, Vector2 playerPos) {
    final headCount = count * 2 ~/ 3;
    final tailCount = count - headCount;
    const headRadius = 35.0;
    final positions = <Vector2>[];

    // Testa: cerchio denso attorno al center
    for (int i = 0; i < headCount; i++) {
      final angle = i * math.pi * 2 / math.max(1, headCount);
      positions.add(center + Vector2(math.cos(angle) * headRadius, math.sin(angle) * headRadius));
    }

    // Coda: punti nella direzione opposta al player
    Vector2 tailDir;
    final diff = center - playerPos;
    if (diff.length > 0.001) {
      tailDir = diff.normalized();
    } else {
      tailDir = Vector2(0, -1);
    }
    for (int i = 0; i < tailCount; i++) {
      final dist = 50.0 + i * 25.0;
      positions.add(center + tailDir * dist);
    }
    return positions;
  }

  /// Infinity8: lemniscata di Bernoulli
  List<Vector2> _fInfinity8(int count, Vector2 center, Vector2 _) {
    const a = 120.0;
    return List.generate(count, (i) {
      final t = i * math.pi * 2 / math.max(1, count);
      final sin2 = math.sin(t) * math.sin(t);
      final denom = 1.0 + sin2;
      final x = a * math.cos(t) / denom;
      final y = a * math.sin(t) * math.cos(t) / denom;
      return center + Vector2(x, y);
    });
  }

  /// DoubleSpiral: galassia a 2 bracci
  List<Vector2> _fDoubleSpiral(int count, Vector2 center, Vector2 _) {
    final half = count ~/ 2;
    final positions = <Vector2>[];
    for (int arm = 0; arm < 2; arm++) {
      final armCount = (arm == 0) ? half : (count - half);
      for (int i = 0; i < armCount; i++) {
        final angle = arm * math.pi + i * 4 * math.pi / math.max(1, armCount);
        final r = 20.0 + i * 3.0;
        positions.add(center + Vector2(math.cos(angle) * r, math.sin(angle) * r));
      }
    }
    return positions;
  }

  /// Honeycomb: griglia esagonale
  List<Vector2> _fHoneycomb(int count, Vector2 center, Vector2 _) {
    const hexSize = 50.0;
    final positions = <Vector2>[];
    // Genera celle in ordine a spirale per riempire count
    final rings = (math.sqrt(count.toDouble()) + 1).ceil();
    for (int q = -rings; q <= rings && positions.length < count; q++) {
      for (int r = -rings; r <= rings && positions.length < count; r++) {
        // Filtro approssimativo sul raggio esagonale
        final s = -q - r;
        if (q.abs() > rings || r.abs() > rings || s.abs() > rings) continue;
        final px = hexSize * (3.0 / 2.0 * q);
        final py = hexSize * (math.sqrt(3.0) / 2.0 * q + math.sqrt(3.0) * r);
        positions.add(center + Vector2(px, py));
      }
    }
    // Ordina per distanza e prendi i primi `count`
    positions.sort((a, b) => (a - center).length2.compareTo((b - center).length2));
    return positions.take(count).toList();
  }

  /// WShape: W doppia-V (5 waypoints)
  List<Vector2> _fWShape(int count, Vector2 center, Vector2 _) {
    final waypoints = [
      Vector2(-130, 80), Vector2(-65, -20), Vector2(0, 80),
      Vector2(65, -20), Vector2(130, 80),
    ];
    final segments = waypoints.length - 1; // 4 segmenti
    final pointsPerSeg = math.max(1, count ~/ segments);
    final positions = <Vector2>[];
    for (int s = 0; s < segments && positions.length < count; s++) {
      final start = waypoints[s];
      final end = waypoints[s + 1];
      final pts = (s == segments - 1) ? (count - positions.length) : pointsPerSeg;
      for (int p = 0; p < pts && positions.length < count; p++) {
        final t = pts <= 1 ? 0.0 : p / (pts - 1);
        positions.add(center + Vector2(
          start.x + (end.x - start.x) * t,
          start.y + (end.y - start.y) * t,
        ));
      }
    }
    return positions;
  }

  /// Hexagon: esagono (6 lati)
  List<Vector2> _fHexagon(int count, Vector2 center, Vector2 _) {
    final r = 80.0 + count * 2.0;
    final vertices = List.generate(6, (k) {
      final angle = k * math.pi / 3;
      return Vector2(math.cos(angle) * r, math.sin(angle) * r);
    });
    final perSide = math.max(2, count ~/ 6);
    final positions = <Vector2>[];
    for (int s = 0; s < 6 && positions.length < count; s++) {
      final start = vertices[s];
      final end = vertices[(s + 1) % 6];
      for (int p = 0; p < perSide && positions.length < count; p++) {
        final t = p / perSide;
        positions.add(center + Vector2(
          start.x + (end.x - start.x) * t,
          start.y + (end.y - start.y) * t,
        ));
      }
    }
    return positions;
  }

  /// TripleRing: tre anelli concentrici
  List<Vector2> _fTripleRing(int count, Vector2 center, Vector2 _) {
    const radii = [45.0, 90.0, 135.0];
    final ring1Count = count ~/ 6;
    final ring2Count = count ~/ 3;
    final ring3Count = count - ring1Count - ring2Count;
    final ringCounts = [ring1Count, ring2Count, ring3Count];
    final positions = <Vector2>[];
    for (int ring = 0; ring < 3; ring++) {
      final n = math.max(1, ringCounts[ring]);
      for (int i = 0; i < n && positions.length < count; i++) {
        final angle = i * math.pi * 2 / n;
        positions.add(center + Vector2(
          math.cos(angle) * radii[ring],
          math.sin(angle) * radii[ring],
        ));
      }
    }
    return positions;
  }

  /// SineWave: onda sinusoidale orizzontale
  List<Vector2> _fSineWave(int count, Vector2 center, Vector2 _) {
    const width = 300.0;
    const amplitude = 80.0;
    return List.generate(count, (i) {
      final t = count <= 1 ? 0.0 : i / (count - 1);
      final x = -150.0 + t * width;
      final y = math.sin(t * math.pi * 2) * amplitude;
      return center + Vector2(x, y);
    });
  }

  /// Cascade: scalinata diagonale
  List<Vector2> _fCascade(int count, Vector2 center, Vector2 _) {
    return List.generate(count, (i) {
      final stepX = 280.0 / math.max(1, count);
      final stepY = 200.0 / math.max(1, count);
      return center + Vector2(-140.0 + i * stepX, -100.0 + i * stepY);
    });
  }

  /// SquareRing: perimetro di un quadrato
  List<Vector2> _fSquareRing(int count, Vector2 center, Vector2 _) {
    final side = 160.0 + count * 2.0;
    final half = side / 2;
    final corners = [
      Vector2(-half, -half), Vector2(half, -half),
      Vector2(half, half), Vector2(-half, half),
    ];
    final perSide = math.max(2, count ~/ 4);
    final positions = <Vector2>[];
    for (int s = 0; s < 4 && positions.length < count; s++) {
      final start = corners[s];
      final end = corners[(s + 1) % 4];
      for (int p = 0; p < perSide && positions.length < count; p++) {
        final t = p / perSide;
        positions.add(center + Vector2(
          start.x + (end.x - start.x) * t,
          start.y + (end.y - start.y) * t,
        ));
      }
    }
    return positions;
  }

  /// Burst: raggi di lunghezza variabile dal centro (starburst)
  List<Vector2> _fBurst(int count, Vector2 center, Vector2 _) {
    final rays = math.min(count, 8);
    final ppr = (count / math.max(1, rays)).ceil(); // points per ray
    final positions = <Vector2>[];
    for (int r = 0; r < rays && positions.length < count; r++) {
      final angle = r * math.pi * 2 / rays;
      for (int p = 0; p < ppr && positions.length < count; p++) {
        final t = ppr <= 1 ? 0.5 : p / (ppr - 1);
        final dist = 20.0 + t * 120.0;
        positions.add(center + Vector2(math.cos(angle) * dist, math.sin(angle) * dist));
      }
    }
    return positions;
  }

  /// ArrowHead: freccia puntata verso il player
  List<Vector2> _fArrowHead(int count, Vector2 center, Vector2 playerPos) {
    Vector2 dir;
    final diff = playerPos - center;
    if (diff.length > 0.001) {
      dir = diff.normalized();
    } else {
      dir = Vector2(0, 1);
    }
    final perp = Vector2(-dir.y, dir.x);
    final tip = center + dir * 100.0;
    final wingL = center - dir * 40.0 + perp * 80.0;
    final wingR = center - dir * 40.0 - perp * 80.0;

    // 3 segmenti: tip→wingL, tip→wingR, wingL→wingR
    final lines = [[tip, wingL], [tip, wingR], [wingL, wingR]];
    final ppl = math.max(1, count ~/ 3);
    final positions = <Vector2>[];
    for (int l = 0; l < 3 && positions.length < count; l++) {
      final start = lines[l][0];
      final end = lines[l][1];
      final pts = (l == 2) ? (count - positions.length) : ppl;
      for (int p = 0; p < pts && positions.length < count; p++) {
        final t = pts <= 1 ? 0.0 : p / (pts - 1);
        positions.add(Vector2(
          start.x + (end.x - start.x) * t,
          start.y + (end.y - start.y) * t,
        ));
      }
    }
    return positions;
  }

  /// Scatter: cluster denso deterministico (seed dal centro)
  List<Vector2> _fScatter(int count, Vector2 center, Vector2 _) {
    final rng = math.Random((center.x * 1000 + center.y).toInt().abs());
    return List.generate(count, (_) {
      final angle = rng.nextDouble() * math.pi * 2;
      final r = 30.0 + rng.nextDouble() * 100.0;
      return center + Vector2(math.cos(angle) * r, math.sin(angle) * r);
    });
  }

  /// Doublering: due anelli concentrici
  List<Vector2> _fDoublering(int count, Vector2 center, Vector2 _) {
    const innerR = 50.0;
    const outerR = 100.0;
    final innerCount = count ~/ 3;
    final outerCount = count - innerCount;
    final positions = <Vector2>[];
    for (int i = 0; i < innerCount; i++) {
      final angle = i * math.pi * 2 / math.max(1, innerCount);
      positions.add(center + Vector2(math.cos(angle) * innerR, math.sin(angle) * innerR));
    }
    for (int i = 0; i < outerCount && positions.length < count; i++) {
      final angle = i * math.pi * 2 / math.max(1, outerCount);
      positions.add(center + Vector2(math.cos(angle) * outerR, math.sin(angle) * outerR));
    }
    return positions;
  }

  /// VArrow: V aperta verso il player
  List<Vector2> _fVArrow(int count, Vector2 center, Vector2 playerPos) {
    Vector2 dir;
    final diff = playerPos - center;
    if (diff.length > 0.001) {
      dir = diff.normalized();
    } else {
      dir = Vector2(0, 1);
    }
    final perp = Vector2(-dir.y, dir.x);
    final leftEnd = center - dir * 120.0 + perp * 100.0;
    final rightEnd = center - dir * 120.0 - perp * 100.0;

    final half = count ~/ 2;
    final positions = <Vector2>[];
    // Braccio sinistro: center → leftEnd
    for (int p = 0; p < half; p++) {
      final t = half <= 1 ? 0.0 : p / (half - 1);
      positions.add(center + Vector2(
        (leftEnd.x - center.x) * t,
        (leftEnd.y - center.y) * t,
      ));
    }
    // Braccio destro: center → rightEnd
    final rem = count - half;
    for (int p = 0; p < rem && positions.length < count; p++) {
      final t = rem <= 1 ? 0.0 : p / (rem - 1);
      positions.add(center + Vector2(
        (rightEnd.x - center.x) * t,
        (rightEnd.y - center.y) * t,
      ));
    }
    return positions;
  }

  /// XShape: due diagonali incrociate (4 braccia a 45°)
  List<Vector2> _fXShape(int count, Vector2 center, Vector2 _) {
    const armLen = 130.0;
    // Angoli 45°, 135°, 225°, 315°
    final angles = [math.pi / 4, 3 * math.pi / 4, 5 * math.pi / 4, 7 * math.pi / 4];
    final perArm = math.max(2, count ~/ 4);
    final positions = <Vector2>[];
    for (int a = 0; a < 4 && positions.length < count; a++) {
      for (int p = 0; p < perArm && positions.length < count; p++) {
        final dist = 20.0 + p * (armLen - 20.0) / math.max(1, perArm - 1);
        positions.add(center + Vector2(
          math.cos(angles[a]) * dist,
          math.sin(angles[a]) * dist,
        ));
      }
    }
    return positions;
  }

  /// Arc: semicerchio con il lato concavo verso il player
  List<Vector2> _fArc(int count, Vector2 center, Vector2 playerPos) {
    final radius = 80.0 + count * 2.0;
    Vector2 dir;
    final diff = playerPos - center;
    if (diff.length > 0.001) {
      dir = diff.normalized();
    } else {
      dir = Vector2(0, 1);
    }
    // Angolo verso il player
    final baseAngle = math.atan2(dir.y, dir.x);
    return List.generate(count, (i) {
      final t = count <= 1 ? 0.0 : i / (count - 1);
      final angle = baseAngle + math.pi / 2 + t * math.pi; // da +90° a +270°
      return center + Vector2(math.cos(angle) * radius, math.sin(angle) * radius);
    });
  }

  /// Zigzag: linea a zigzag orizzontale
  List<Vector2> _fZigzag(int count, Vector2 center, Vector2 _) {
    const width = 280.0;
    const height = 80.0;
    return List.generate(count, (i) {
      final t = count <= 1 ? 0.0 : i / (count - 1);
      final x = -140.0 + t * width;
      final y = (i % 2 == 0) ? height / 2 : -height / 2;
      return center + Vector2(x, y);
    });
  }

  WaveConfig _generateEndlessWave(int wave) {
    // Endless: stile GW — massa enorme di mob stupidi + crescente varietà di pericolosi
    final spawns = <WaveSpawn>[];

    // ── MASSA STUPIDA (~70%) — raddoppiata ──
    spawns.add(WaveSpawn(EnemyType.swarmDrone, (60 + wave * 4).clamp(60, 120)));
    spawns.add(WaveSpawn(EnemyType.drone, (40 + wave * 4).clamp(40, 100), delay: 0.3));
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

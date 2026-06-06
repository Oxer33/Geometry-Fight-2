import 'dart:math' as math;
import 'package:flame/components.dart';
import '../../data/constants.dart';
import '../../data/difficulty.dart';
import '../../data/wave_configs.dart';
import '../game_world.dart';
import '../entities/enemies/swarm_drone_enemy.dart';

/// 26 formazioni geometriche uniche per il formation spawn system
/// `borderLine` dispone i nemici lungo un intero bordo dell'arena (dalla sponda
/// caricano tutti insieme verso l'interno — usato principalmente dal kamikaze).
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
  borderLine,
  // Nuove formazioni centrate sul player (richiesta utente: "cerchi
  // concentrici o forme chiuse intorno al player").
  playerRing,
  playerDoubleRing,
  playerEncircle,
}

/// Lato dell'arena da cui spawna una schiera borderLine.
enum _BorderSide { top, bottom, left, right }

class WaveSystem {
  final GeometryFightGame game;
  int currentWave = 0;
  double _spawnTimer = 0;
  int _spawnIndex = 0;
  bool _waveActive = false;
  bool _bossActive = false;
  // Se wave vuole spawnare un boss ma uno è ancora attivo, differisce
  // qui e update() riprova quando bossCount torna 0. Senza questo, nuove
  // wave con boss restavano stuck (never spawn) fino a wave successiva.
  BossType? _pendingBoss;
  bool _allSpawned = false; // Tutti i gruppi sono stati spawnati
  double _postSpawnDelay =
      0; // Delay dopo l'ultimo spawn prima di controllare completamento
  double _waveElapsedTimer =
      0; // Timer per forzare completamento wave in classic mode
  double _interWaveDelay = 0; // Timer tra una wave e la successiva
  int? _pendingWave; // Wave da avviare dopo il delay
  late List<WaveConfig> _configs;
  WaveConfig? _currentConfig;
  final int _dailySeed;

  WaveSystem(this.game)
    : _dailySeed = _computeDailySeed(DateTime.now().toUtc()) {
    _configs = generateWaveConfigs();
  }

  /// Ritorna la modalità di gioco attuale dal game
  GameMode get _mode => game.gameMode;

  /// Daily seed deterministico via UTC: tutti i player nel mondo che giocano
  /// nello stesso giorno UTC hanno la stessa Daily Challenge, indipendentemente
  /// dal fuso orario o cambio DST locale durante la sessione.
  static int _computeDailySeed(DateTime date) =>
      date.year * 10000 + date.month * 100 + date.day;

  int _scaledSpawnCount(int baseCount) {
    var mult = game.diffConfig.enemyCountMultiplier;
    // BLITZ modifier: +50% mob count. Applicato qui per propagarsi a TUTTE
    // le formation spawn/borderLine/normal pathway senza touchpoints multipli.
    if (activeModifier == WaveModifier.blitz) {
      mult *= 1.5;
    }
    final scaled = (baseCount * mult).round();
    return scaled.clamp(1, 500);
  }

  double _scaledSpawnDelay(double baseDelay) {
    return (baseDelay * game.diffConfig.spawnDelayMultiplier).clamp(0.05, 10.0);
  }

  double _delayBeforeNextGroup() {
    assert(
      _currentConfig != null && _spawnIndex < _currentConfig!.spawns.length,
      'spawnIndex out of bounds',
    );
    // Difensiva runtime: l'assert vale solo in debug, in release ritorna 0
    // se l'indice è fuori range invece di crashare con range error.
    if (_currentConfig == null ||
        _spawnIndex >= _currentConfig!.spawns.length) {
      return 0.0;
    }
    // Richiesta design: in modalità classica ogni gruppo (tipo nemico) arriva
    // a cadenza fissa, così la wave è più leggibile.
    if (_mode == GameMode.classic) {
      // SIGNATURE WAVE: se il PROSSIMO spawn ha un formation hint, è una wave
      // hand-curated (vedi `_signatureWaveOverride`) → rispetta il `delay`
      // esplicito invece di schiacciare tutto a `classicWaveGroupDelaySeconds`.
      // Senza questo: ENCIRCLE 2.5s/PINCER 0.1s/KAMIKAZE HELL 2.5s collassano
      // tutti a 1.2s → ritmo signature distrutto.
      final nextSpawn =
          (_currentConfig != null &&
              _spawnIndex < _currentConfig!.spawns.length)
          ? _currentConfig!.spawns[_spawnIndex]
          : null;
      if (nextSpawn?.formation != null) {
        return _scaledSpawnDelay(nextSpawn!.delay);
      }
      // Archetype wave classic: HASTE modifier (-40%) o constante.
      final base = classicWaveGroupDelaySeconds;
      if (activeModifier == WaveModifier.haste) {
        return base * 0.6;
      }
      return base;
    }
    return _scaledSpawnDelay(_currentConfig!.spawns[_spawnIndex].delay);
  }

  /// Modificatore attivo della wave corrente. `none` se nessun modifier o
  /// se la wave non è classic (tunnel/zen/boss-rush/time-attack vanilla).
  WaveModifier get activeModifier {
    if (_mode != GameMode.classic) return WaveModifier.none;
    return _currentConfig?.modifier ?? WaveModifier.none;
  }

  /// Reset stato tunnel + survival per nuova partita
  void reset() {
    _tunnelSpawnTimer = 0.5;
    _tunnelKillCount = 0;
    _nextBossAt = 120; // Primo boss a 120 kill (richiesta utente)
    _tunnelBossCooldown = 0;
    _tunnelBossBag.clear();
    _tunnelBossPending = null;
    _tunnelBossPendingTimer = 0;
    game.tunnelBossIncoming = false; // evita tunnel allargato stale al restart
    _resetSurvival();
    _resetSnake();
    currentWave = 0;
    _waveActive = false;
    _bossActive = false;
    _allSpawned = false;
    _pendingWave = null;
  }

  void startWave(int wave) {
    // Survival rework iter 7: orchestrato da updateSurvival, NON da
    // wave path. Guard early-return → evita _waveActive/_completeWave
    // race con currentWave incrementato anche da updateSurvival.
    if (_mode == GameMode.survival) {
      currentWave = wave;
      _waveActive = false;
      return;
    }
    // Snake mode: spawn continuo orchestrato da `updateSnake`, niente wave
    // formali. Guard early-return analogo a survival.
    if (_mode == GameMode.snake) {
      currentWave = wave;
      _waveActive = false;
      return;
    }
    currentWave = wave;
    _waveActive = true;
    _spawnIndex = 0;
    _spawnTimer = _scaledSpawnDelay(
      1.0,
    ); // Delay iniziale prima del primo spawn
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
        // Zen = classic con player immortale. Stessi wave config + boss.
        _currentConfig = _configs.firstWhere(
          (c) => c.waveNumber == wave,
          orElse: () => _generateEndlessWave(wave),
        );
      case GameMode.tunnel:
        _currentConfig = _generateTunnelWave(wave);
      case GameMode.dailyChallenge:
        _currentConfig = _generateDailyChallengeWave(wave);
        // Spawn mob diretto: 50-80 mob singolo tipo, arena-wide random.
        // `_generateDailyChallengeWave` ritorna `spawns: []` → startWave
        // imposta `_allSpawned = true` sotto, e la wave completa quando
        // tutti questi mob muoiono.
        _spawnDailyChallengeMobs(wave);
      case GameMode.pacifist:
        _currentConfig = _generatePacifistWave(wave);
      case GameMode.waves:
        _currentConfig = _generateWavesMode(wave);
      case GameMode.gravityInferno:
        _currentConfig = _generateGravityInfernoWave(wave);
        // Black hole spawn diretto (arena-wide Poisson-disc), fuori dalla
        // `spawns` list così non passa per la formation scatter clustered.
        _spawnGravityInfernoBlackHoles(wave);
      case GameMode.snake:
        // Snake non passa mai per startWave (early-return sopra). Branch
        // qui solo per exhaustiveness del switch.
        _currentConfig = WaveConfig(waveNumber: wave, spawns: const []);
      case GameMode.classic:
        _currentConfig = _configs.firstWhere(
          (c) => c.waveNumber == wave,
          orElse: () => _generateEndlessWave(wave),
        );
    }

    // Wave senza gruppi spawnabili: considera subito "all spawned".
    // PostSpawnDelay 0.8s evita race: senza un piccolo buffer, una wave
    // boss-only senza spawns può completare in zero frame e collidere col
    // ciclo di spawn del boss async.
    if (_currentConfig!.spawns.isEmpty) {
      _allSpawned = true;
      _postSpawnDelay = 0.8;
    }

    // Check for boss — spawna solo se non c'è già un boss attivo
    if (_currentConfig!.boss != null && game.bossCount == 0) {
      _bossActive = true;
      _pendingBoss = null;
      game.spawnBoss(_currentConfig!.boss!);
    } else if (_currentConfig!.boss != null && game.bossCount > 0) {
      // Boss precedente ancora attivo — memorizza e spawna quando bossCount = 0.
      _bossActive = true;
      _pendingBoss = _currentConfig!.boss;
    } else {
      _pendingBoss = null;
    }

    game.onWaveStart?.call(wave);
  }

  void update(double dt) {
    // Gestione delay tra wave (sostituisce Future.delayed)
    if (_pendingWave != null) {
      _interWaveDelay -= dt;
      if (_interWaveDelay <= 0 &&
          game.bossCount == 0 &&
          game.gameState == GameState.playing) {
        final wave = _pendingWave!;
        _pendingWave = null;
        startWave(wave);
      }
      return;
    }

    if (!_waveActive) return;

    // Timer inizia solo quando tutti i gruppi sono spawnati — N s DOPO l'ultimo spawn.
    // Limite definito da `classicWaveTimeoutSeconds` in constants.dart.
    if (_allSpawned) _waveElapsedTimer += dt;

    // Classic mode: forza avanzamento wave dopo il timeout — i nemici rimasti restano vivi!
    // Diventa sempre più difficile se non li uccidi.
    if (_mode == GameMode.classic &&
        _allSpawned &&
        _waveElapsedTimer >= classicWaveTimeoutSeconds &&
        !_bossActive) {
      _completeWave();
      return;
    }

    if (_bossActive) {
      // Pending boss: spawna ora che il precedente è morto.
      if (_pendingBoss != null && game.bossCount == 0) {
        game.spawnBoss(_pendingBoss!);
        _pendingBoss = null;
        // Skip the completion check this frame: bossCount cache is stale
        // (50ms refresh) and would immediately fire the condition below,
        // completing the wave in the same frame the pending boss was spawned.
      } else if (game.bossCount == 0 &&
          _pendingBoss == null &&
          _allSpawned &&
          game.enemyCount == 0) {
        // Wait for boss to die, ma continua a spawnare nemici se presenti
        _bossActive = false;
        _completeWave();
        return;
      }
      // Se il boss è attivo ma ci sono ancora spawn da fare, NON uscire — continua sotto
      if (_allSpawned ||
          (_currentConfig != null && _currentConfig!.spawns.isEmpty)) {
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
          // Tutti i gruppi spawnati - avvia il delay di sicurezza.
          // Ridotto 1.5→0.8 (richiesta utente: ritmo più serrato).
          _allSpawned = true;
          _postSpawnDelay = 0.8;
        }
      }
    }

    // Check if wave is complete (SOLO dopo il delay post-spawn).
    // Pacifist: skip enemyCount==0 → player non spara, drone possono accumulare
    // se gate li mancano. Senza skip, wave deadlock. Continuous wave flow ok
    // perché _maxActiveEnemies cap evita esplosione count.
    if (_allSpawned) {
      _postSpawnDelay -= dt;
      // Pacifist + Waves: skip enemyCount==0 → ondate continue, sempre
      // ravvicinate (richiesta utente per Waves "molto più ravvicinate").
      final canComplete =
          game.enemyCount == 0 ||
          _mode == GameMode.pacifist ||
          _mode == GameMode.waves;
      if (_postSpawnDelay <= 0 && canComplete) {
        _completeWave();
      }
    }
  }

  void _completeWave() {
    // Re-entry guard: senza questo, due chiamate ravvicinate (es. boss
    // defeated + timeout nello stesso frame) doppiavano `onWaveComplete`
    // e scheduling di `_pendingWave`.
    if (!_waveActive) return;
    _waveActive = false;

    // Notifica il game che la wave è completa (per Perfect Wave bonus)
    game.onWaveComplete();

    // Delay tra wave dipende dalla modalità (in secondi).
    // Classic ridotto 2.0→1.0 (richiesta utente: ritmo più serrato).
    double delaySec;
    if (_mode == GameMode.survival ||
        _mode == GameMode.tunnel ||
        _mode == GameMode.pacifist) {
      delaySec = 0.5;
    } else if (_mode == GameMode.waves) {
      // Waves: ondate continue molto ravvicinate (richiesta utente).
      delaySec = 0.2;
    } else if (_mode == GameMode.bossRush) {
      delaySec = 3.0;
    } else {
      delaySec = 1.0;
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

  /// Survival rework (richiesta utente): no wave, spawn 1-a-1 accelerante.
  /// Spawn timer decresce con tempo elapsed → mob arrivano sempre più rapidi.
  /// Mix di mob stile GW (drone/swarmDrone main, kamikaze/weaver/etc. rare).
  /// `_generateSurvivalWave` ora ritorna empty config (orchestrato da
  /// `updateSurvival` invece di waves).
  WaveConfig _generateSurvivalWave(int wave) {
    return WaveConfig(waveNumber: wave, spawns: []);
  }

  /// State survival: spawn timer + tempo elapsed (per accelerare nel tempo).
  double _survivalSpawnTimer = 0.5;
  double _survivalElapsed = 0;
  static final _survivalRng = math.Random();

  /// Aggiornamento continuo survival: ogni `_survivalSpawnTimer` secondi
  /// spawna 1 mob random. Intervallo decresce: 1.2s start → 0.15s a 5min.
  /// Tipo random pesato su pool ampio (27 tipi, vedi _randomSurvivalEnemyType).
  void updateSurvival(double dt) {
    _survivalElapsed += dt;
    _survivalSpawnTimer -= dt;
    if (_survivalSpawnTimer > 0) return;

    // Cap nemici attivi: 200 — survival design = caos crescente.
    if (game.enemyCount >= 200) {
      _survivalSpawnTimer = 0.1;
      return;
    }

    // Intervallo accelerante (iter 8 utente: 2× più veloce dall'inizio):
    // 0.6s start → 0.075s a 5min elapsed.
    final t = (_survivalElapsed / 300).clamp(0.0, 1.0);
    final base = 0.6 + (0.075 - 0.6) * t;
    // Jitter ±20% per non sentire pattern fisso.
    final jitter = 0.8 + _survivalRng.nextDouble() * 0.4;
    _survivalSpawnTimer = (base * jitter).clamp(0.1, 1.5);

    // Pesi: drone/swarmDrone main, kamikaze/weaver/mine/splitter scaling
    // con elapsed (più mob pericolosi col passare del tempo).
    final type = _randomSurvivalEnemyType();
    game.spawnEnemy(type);
    // Anche progress wave counter (usato da achievements/HUD).
    final computedWave = (_survivalElapsed / 30).floor() + 1;
    if (computedWave > currentWave) currentWave = computedWave;
  }

  /// Tipo mob pesato per survival. Pool AMPIO (richiesta utente: "non spawnano
  /// tutti i tipi" — prima erano solo 8). Spawn 1-a-1 (cap 200) → anche i tipi
  /// "intensi" sono ok qui (1 spawner ≠ 80). Pesi t-dipendenti (t = elapsed/300,
  /// 0→1 in 5min): fodder cala, attaccanti normali costanti, esotici/hazard
  /// rampano da 0 → variano solo a partita avanzata. Esclusi solo `snake`
  /// (mob scia della snake-mode) e `gate` (cancello non-killabile, spawn
  /// speciale a 2 sfere).
  EnemyType _randomSurvivalEnemyType() {
    final t = (_survivalElapsed / 300).clamp(0.0, 1.0);
    // (tipo, peso). Lista costruita per-spawn (cadenza lenta → alloc trascurabile).
    final pool = <(EnemyType, double)>[
      // Fodder — alto all'inizio, scende nel tempo.
      (EnemyType.swarmDrone, 26 - 14 * t),
      (EnemyType.drone, 26 - 14 * t),
      // Attaccanti / inseguitori comuni — peso costante.
      (EnemyType.kamikaze, 7),
      (EnemyType.mine, 5),
      (EnemyType.weaver, 5),
      (EnemyType.splitter, 5),
      (EnemyType.shieldEnemy, 4),
      (EnemyType.glitch, 4),
      (EnemyType.orbiter, 4),
      (EnemyType.pulsar, 4),
      (EnemyType.mirror, 3),
      (EnemyType.phantom, 3),
      // Tier medio — rampa col tempo.
      (EnemyType.titan, 2 + 4 * t),
      (EnemyType.tesla, 2 + 3 * t),
      (EnemyType.laserTurret, 2 + 3 * t),
      (EnemyType.timeBomb, 1 + 3 * t),
      (EnemyType.leech, 1 + 3 * t),
      (EnemyType.proton, 1 + 3 * t),
      (EnemyType.siren, 1 + 2 * t),
      (EnemyType.necro, 1 + 2 * t),
      (EnemyType.healer, 1 + 2 * t),
      (EnemyType.mutator, 1 + 2 * t),
      (EnemyType.decoy, 1 + 2 * t),
      // Tier esotico / hazard — solo tardi (peso 0 a inizio), rari.
      (EnemyType.vortex, 4 * t),
      (EnemyType.gravityWell, 3 * t),
      (EnemyType.spawner, 3 * t),
      (EnemyType.blackHole, 2 * t),
    ];
    var total = 0.0;
    for (final p in pool) {
      total += p.$2;
    }
    var r = _survivalRng.nextDouble() * total;
    for (final p in pool) {
      r -= p.$2;
      if (r <= 0) return p.$1;
    }
    return EnemyType.drone; // fallback difensivo (arrotondamenti float)
  }

  /// Survival reset (chiamato da `reset()`).
  void _resetSurvival() {
    _survivalSpawnTimer = 0.5;
    _survivalElapsed = 0;
  }

  // ───── SNAKE MODE ──────────────────────────────────────────────────
  // Spawn continuo nemici random arena-wide, no boss, no wave formali.
  // Rate 1 nemico ogni `_snakeSpawnTimer` secondi; cadenza accelera con
  // tempo elapsed (1.0s start → 0.3s a 5min). Pool nemici esclude:
  //  - boss (Snake mode ha `hasBosses: false`)
  //  - weaver / glitch ("too special" — richiesta utente)
  //  - blackHole / gravityWell / proton / mutator / gate / leech / siren /
  //    necro / decoy / healer (special/support, non standalone-attackers).
  // Tipo random uniforme per spawn. Scoring puro da kill via trail.
  double _snakeSpawnTimer = 0.8;
  double _snakeElapsed = 0;
  static final _snakeRng = math.Random();

  // Tier-based snake pool. Spawn pescato dall'unione dei tier sbloccati.
  // `_snakeElapsed` guida lo sblocco. Richiesta utente: spawnano TUTTI i mob
  // tranne quelli che NON si muovono → esclusi solo mine, laserTurret, decoy
  // (stazionari) e gate (non uccidibile dalla scia). Tutto il resto che si
  // muove è incluso, distribuito sui tier per progressione.
  static const List<EnemyType> _snakeTier1 = <EnemyType>[
    EnemyType.drone,
    EnemyType.swarmDrone,
  ];
  static const List<EnemyType> _snakeTier2 = <EnemyType>[
    EnemyType.kamikaze,
    EnemyType.snake,
    EnemyType.weaver,
    EnemyType.glitch,
  ];
  static const List<EnemyType> _snakeTier3 = <EnemyType>[
    EnemyType.orbiter,
    EnemyType.phantom,
    EnemyType.pulsar,
    EnemyType.tesla,
    EnemyType.proton,
  ];
  static const List<EnemyType> _snakeTier4 = <EnemyType>[
    EnemyType.mirror,
    EnemyType.vortex,
    EnemyType.titan,
    EnemyType.splitter,
    EnemyType.spawner,
    EnemyType.leech,
  ];
  // Tier 5: nemici tardivi più pericolosi + support (ora più efficaci). Tutti
  // si muovono attivamente.
  static const List<EnemyType> _snakeTier5 = <EnemyType>[
    EnemyType.timeBomb,
    EnemyType.shieldEnemy,
    EnemyType.healer,
    EnemyType.siren,
    EnemyType.necro,
    EnemyType.mutator,
    EnemyType.gravityWell,
    EnemyType.blackHole,
  ];

  // Soglie di sblocco (secondi): tier1 da 0, tier2 >30s, tier3 >90s,
  // tier4 >180s, tier5 >300s.
  //
  // Pool pre-costruiti per tier-mask: evita allocazione list ad ogni spawn
  // (a 10min siamo a ~8 spawn/s → ~480 alloc/min senza cache). La maschera
  // [0..4] tiene gli unlock cumulativi: 0=t1, 1=t1+t2, 2=+t3, 3=+t4, 4=+t5.
  // Le liste sono `unmodifiable` per garantire che callers non possano
  // mutare lo stato cache.
  static final List<List<EnemyType>> _snakePools = <List<EnemyType>>[
    List<EnemyType>.unmodifiable(_snakeTier1),
    List<EnemyType>.unmodifiable(<EnemyType>[..._snakeTier1, ..._snakeTier2]),
    List<EnemyType>.unmodifiable(<EnemyType>[
      ..._snakeTier1,
      ..._snakeTier2,
      ..._snakeTier3,
    ]),
    List<EnemyType>.unmodifiable(<EnemyType>[
      ..._snakeTier1,
      ..._snakeTier2,
      ..._snakeTier3,
      ..._snakeTier4,
    ]),
    List<EnemyType>.unmodifiable(<EnemyType>[
      ..._snakeTier1,
      ..._snakeTier2,
      ..._snakeTier3,
      ..._snakeTier4,
      ..._snakeTier5,
    ]),
  ];

  int _snakeTierIndex() {
    if (_snakeElapsed > 300) return 4;
    if (_snakeElapsed > 180) return 3;
    if (_snakeElapsed > 90) return 2;
    if (_snakeElapsed > 30) return 1;
    return 0;
  }

  List<EnemyType> _currentSnakePool() => _snakePools[_snakeTierIndex()];

  void _resetSnake() {
    _snakeSpawnTimer = 0.8;
    _snakeElapsed = 0;
  }

  /// Aggiornamento continuo Snake mode: spawn 1 nemico random a cadenza
  /// crescente. Wave counter avanza ogni 30s per HUD/achievement.
  void updateSnake(double dt) {
    _snakeElapsed += dt;
    _snakeSpawnTimer -= dt;
    if (_snakeSpawnTimer > 0) return;

    // Cap nemici attivi: 150 — stesso cap del game_world per coerenza.
    if (game.enemyCount >= 150) {
      _snakeSpawnTimer = 0.1;
      return;
    }

    // Intervallo accelerante "infinito": 0.8s @ t=0 → 0.15s @ t≥600s (10min).
    // Lineare decrescente, clampato sotto a 0.15s per evitare collasso totale.
    // Formula: 0.8 - t/600 → a 5min = 0.3s, a 10min = -0.2s clampato a 0.15s.
    final t = _snakeElapsed;
    final base = (0.8 - t / 600.0).clamp(0.15, 0.8);
    final jitter = 0.85 + _snakeRng.nextDouble() * 0.3;
    _snakeSpawnTimer = (base * jitter).clamp(0.12, 1.5);

    final pool = _currentSnakePool();
    // Defensive: tier1 ha 2 elementi quindi unreachable, ma se in futuro
    // un tier viene svuotato (refactor) evitiamo `nextInt(0)` → RangeError.
    if (pool.isEmpty) return;
    final type = pool[_snakeRng.nextInt(pool.length)];
    game.spawnEnemy(type);

    // Wave progression: 1 wave ogni 30s (HUD/achievement readability).
    final computedWave = (_snakeElapsed / 30).floor() + 1;
    if (computedWave > currentWave) currentWave = computedWave;
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
    if (wave >= 3) {
      spawns.add(
        WaveSpawn(EnemyType.mine, (4 + wave * 2).clamp(4, 20), delay: 1),
      );
    }
    if (wave >= 5) {
      spawns.add(
        WaveSpawn(EnemyType.splitter, (wave * 2 ~/ 3).clamp(1, 10), delay: 2),
      );
    }
    return WaveConfig(waveNumber: wave, spawns: spawns);
  }

  /// Pacifist (Geometry Wars: Retro Evolved 2 — Pacifism mode).
  /// Player non spara, 1 vita, 0 bombe. Solo Grunt (drone) lenti che caricano
  /// dritti verso il player. Gate spawnano in continuazione: il player deve
  /// attraversarli per esplosioni a catena.
  /// Combo successive di gate triggerati a breve distanza temporale → punti
  /// moltiplicati + AoE più ampia (gestito in game_world + gate_enemy).
  ///
  /// Iter 6 rebalance:
  /// - Gate count DIMEZZATO (era 2-4, ora 1-2). Cresce molto lento (~ogni 8w).
  /// - Drone count cresce più aggressivo (era 6-60, ora 6-100, +33% rate).
  /// - Wave 5+: aggiunti swarmDrone (mini-grunts veloci che inseguono player).
  /// - Wave 10+: aggiunti snake (serpentina che vaga, non insegue direttamente).
  /// Mantenuti SOLO mob non-letali: drone/swarmDrone/snake. NO kamikaze, mine,
  /// splitter, weaver, glitch, blackHole, tesla, etc.
  /// Waves mode (richiesta utente "solo mob rossi a triangolo, sx/dx + su/giù,
  /// rare blackhole"). Solo kamikaze spawnati da bordi arena + black hole
  /// occasionali in posizioni FISSE lontane dal player.
  ///
  /// Scaling:
  /// - kamikaze count per ondata: 8 + wave × 3 (cap implicito tramite
  ///   `_scaledSpawnCount`).
  /// - 2 ondate per wave (delay 0 + 3s) per pressione continua.
  /// - blackhole: ogni 5 wave, 1 + wave/10 (max 4).
  ///
  /// `borderLine` formation spawna dai bordi (sx/dx/su/giù entry points).
  /// Il movimento cardinale del kamikaze è gestito SEPARATAMENTE da
  /// `_pickCardinalDirection` in kamikaze_enemy.dart, che sceglie l'asse
  /// maggiore verso il player dopo la fase di idle/charging (~1.5s).
  WaveConfig _generateWavesMode(int wave) {
    // Cap singolo via `_scaledSpawnCount.clamp(1, 500)`. Qui solo formula.
    // Mix dei DUE triangoli rossi (utente: "spawnano i cerchi rossi invece
    // dei triangoli rossi dell'altro tipo" → proton era SBAGLIATO, è una
    // sfera. Sostituito con swarmDrone, l'altro triangolo rosso del game).
    // - kamikaze (cardinali rosso) — movimento sx/dx + su/giù
    // - swarmDrone (rosa-rosso, follower veloce) — varietà aggressiva
    // Split 60/40 per onda. 4 ondate ravvicinate (delay 1.5s).
    final totalCount = 8 + wave * 3;
    final kamikazeCount = (totalCount * 0.6).round();
    final swarmCount = totalCount - kamikazeCount;
    final spawns = <WaveSpawn>[
      WaveSpawn(
        EnemyType.kamikaze,
        kamikazeCount,
        formation: SpawnFormation.borderLine,
      ),
      WaveSpawn(
        EnemyType.swarmDrone,
        swarmCount,
        formation: SpawnFormation.borderLine,
        delay: 1.5,
      ),
      WaveSpawn(
        EnemyType.kamikaze,
        kamikazeCount,
        formation: SpawnFormation.borderLine,
        delay: 1.5,
      ),
      WaveSpawn(
        EnemyType.swarmDrone,
        swarmCount,
        formation: SpawnFormation.borderLine,
        delay: 1.5,
      ),
    ];
    // Black hole rari: ogni 5 wave. Formation `cross` per posizionamento
    // FISSO ai 4 punti cardinali lontani dal centro.
    if (wave > 0 && wave % 5 == 0) {
      final bhCount = (1 + wave ~/ 10).clamp(1, 4);
      spawns.add(
        WaveSpawn(
          EnemyType.blackHole,
          bhCount,
          formation: SpawnFormation.cross,
          delay: 2.5,
        ),
      );
    }
    return WaveConfig(waveNumber: wave, spawns: spawns);
  }

  /// Gravity Inferno (utente: "tanti buchi neri + pochi mob di tutti i tipi
  /// e senza boss"). Caos gravitazionale: 3-8 blackhole per wave + 6-12 mob
  /// random tra il pool standard. No boss.
  ///
  /// Fix recenti (richiesta utente):
  /// - Mob "appaiono molto più tardi" → tutte le ondate mob compresse nel
  ///   primo 25% della wave (delay 0 / 0.5 / 1.0 invece di 0/2.5/5.0/7.5).
  /// - Black hole apparivano clustered → ora vengono spawnati direttamente
  ///   in `_spawnGravityInfernoBlackHoles` (chiamato da `startWave`) con
  ///   distribuzione Poisson-disc arena-wide (min 250px tra BH, max 20
  ///   tentativi di rejection per BH). Restano fuori dalla `spawns` list
  ///   per evitare di passare per la `_fScatter` formation che li avrebbe
  ///   raggruppati attorno ad un singolo centro.
  WaveConfig _generateGravityInfernoWave(int wave) {
    final mobCount = (6 + wave ~/ 2).clamp(6, 12);
    // Pool mob misti — variety, no spam stesso tipo.
    final mobTypes = [
      EnemyType.drone,
      EnemyType.kamikaze,
      EnemyType.weaver,
      EnemyType.splitter,
      EnemyType.shieldEnemy,
      EnemyType.glitch,
      EnemyType.tesla,
      EnemyType.swarmDrone,
    ];
    final rng = math.Random(wave * 7919);
    final spawns = <WaveSpawn>[];
    // 3 ondate mob compresse nel primo 25% della wave: delays 0 / 0.5 / 1.0.
    // Prima erano 2.0/4.5/7.0 → ondate tarde lette dall'utente come "mob
    // appaiono molto più tardi". Ora arrivano tutte presto.
    //
    // Spawn batch ceiling: 3 batch × (mobCount/3).clamp(2,5) = max 15 mob per
    // wave dichiarati qui + 3-8 black hole spawnati direttamente in
    // `_spawnGravityInfernoBlackHoles`. Anche con BLITZ modifier (×1.5 in
    // `_scaledSpawnCount`) si raggiungono ~22 mob/sec, ben sotto il cap
    // globale `_maxActiveEnemies = 150` in game_world.dart. Nessun rischio
    // di overload della spawn queue: `spawnEnemy` ritorna `null` quando il
    // cap è raggiunto, fallback graceful.
    const earlyDelays = [0.0, 0.5, 1.0];
    for (int i = 0; i < 3; i++) {
      final type = mobTypes[rng.nextInt(mobTypes.length)];
      final cnt = (mobCount ~/ 3).clamp(2, 5);
      spawns.add(
        WaveSpawn(
          type,
          cnt,
          formation: SpawnFormation.scatter,
          delay: earlyDelays[i],
        ),
      );
    }
    // I blackhole NON sono in `spawns`: vengono spawnati direttamente in
    // `_spawnGravityInfernoBlackHoles` (chiamato da `startWave`) con
    // distribuzione Poisson-disc per evitare il clustering di `_fScatter`.
    return WaveConfig(waveNumber: wave, spawns: spawns);
  }

  /// Spawna `count` blackhole con distribuzione arena-wide (Poisson-disc
  /// rejection sampling). Garantisce minDist tra BH così non si sovrappongono
  /// in un singolo punto come faceva la formation scatter.
  ///
  /// - count: 3-8 in base alla wave (3 + wave/3, clamp 3..8).
  /// - minDist: 250px (richiesta utente).
  /// - maxAttempts: 20 per BH (richiesta utente). Se non trova posizione
  ///   valida entro 20 tentativi, prende l'ultima candidata generata
  ///   (degrado graceful, mai dead-lock).
  /// - Margine bordi: 80px così i blackhole non spawnano contro il muro.
  void _spawnGravityInfernoBlackHoles(int wave) {
    final bhCount = (3 + wave ~/ 3).clamp(3, 8);
    final eW = game.effectiveArenaWidth;
    final eH = game.effectiveArenaHeight;
    const margin = 80.0;
    const minDist = 250.0;
    const minDist2 = minDist * minDist;
    const maxAttempts = 20;
    // Seed deterministico per wave: stessa partita stessa disposizione.
    final rng = math.Random(_dailySeed ^ (wave * 31337));
    final placed = <Vector2>[];
    for (int i = 0; i < bhCount; i++) {
      Vector2? lastCandidate;
      for (int attempt = 0; attempt < maxAttempts; attempt++) {
        final c = Vector2(
          margin + rng.nextDouble() * (eW - margin * 2),
          margin + rng.nextDouble() * (eH - margin * 2),
        );
        lastCandidate = c;
        bool ok = true;
        for (final p in placed) {
          if (p.distanceToSquared(c) < minDist2) {
            ok = false;
            break;
          }
        }
        if (ok) {
          placed.add(c);
          break;
        }
      }
      // Fallback: se nessun tentativo è passato il vincolo di distanza
      // usa l'ultima candidata (arena densa di BH → meglio averne uno in
      // più ravvicinato che nessuno).
      if (placed.length <= i && lastCandidate != null) {
        placed.add(lastCandidate);
      }
    }
    for (final pos in placed) {
      game.spawnEnemy(EnemyType.blackHole, pos);
    }
  }

  WaveConfig _generatePacifistWave(int wave) {
    // Drone count cresce aggressivo con la wave (cap 100 per perf, sotto 150).
    final droneCount = (6 + wave * 4).clamp(6, 100);
    // Gate count DIMEZZATO: 1 base, +1 ogni 8 wave, max 2.
    final gateCount = (1 + wave ~/ 8).clamp(1, 2);
    final spawns = <WaveSpawn>[
      // Drone burst iniziale
      WaveSpawn(EnemyType.drone, droneCount ~/ 2),
      // Gate spawnano subito per dare al player risk/reward immediato
      WaveSpawn(EnemyType.gate, gateCount, delay: 0.8),
      // Secondo burst di drone
      WaveSpawn(EnemyType.drone, droneCount ~/ 2, delay: 1.5),
    ];
    // Wave 5+: swarmDrone (piccoli grunts veloci, follower) — solo follower.
    if (wave >= 5) {
      final swarmCount = (wave ~/ 2).clamp(1, 12);
      spawns.add(WaveSpawn(EnemyType.swarmDrone, swarmCount, delay: 2.5));
    }
    // Wave 10+: snake (serpentina che vaga, non insegue direttamente) —
    // varietà visiva, basso pericolo (pattern prevedibile = facile schivare).
    if (wave >= 10) {
      final snakeCount = (1 + wave ~/ 15).clamp(1, 2);
      spawns.add(WaveSpawn(EnemyType.snake, snakeCount, delay: 3.0));
    }
    return WaveConfig(waveNumber: wave, spawns: spawns);
  }

  /// Zen Mode: nemici rilassanti ma più numerosi
  // NOTA: `_generateZenWave` rimosso — zen mode ora usa i config classic.

  // === TUNNEL MODE: spawn continuo, no wave tradizionali ===
  double _tunnelSpawnTimer = 0.5;
  int _tunnelKillCount = 0; // Per boss ogni N kill
  // Primo boss a 120 kill (era 60 — richiesta utente: arriva troppo presto).
  // Boss successivi a +30 kill incrementali.
  int _nextBossAt = 120;
  double _tunnelBossCooldown = 0; // Tempo minimo tra boss (s)
  // Boss "incoming": alla soglia kill il tunnel inizia ad allargarsi e dopo 5s
  // spawna il boss (richiesta utente: "il tunnel deve allargarsi 5s prima").
  BossType? _tunnelBossPending;
  double _tunnelBossPendingTimer = 0;
  // Shuffle bag per ordine randomico dei boss (richiesta utente "ordine
  // randomico"). Riempito con tutti i BossType.values, pescato dal front,
  // refill quando vuoto → nessun boss ripete finché non li hai visti tutti.
  final List<BossType> _tunnelBossBag = [];
  static final _tunnelRng = math.Random();

  void _refillTunnelBossBag() {
    _tunnelBossBag
      ..clear()
      ..addAll(BossType.values)
      ..shuffle(_tunnelRng);
  }

  /// Tunnel: spawn continuo di nemici randomici davanti al player.
  /// Spawn dimezzato rispetto a prima (era troppo caotico): min 10 nemici
  /// attivi (era 20), batch 2-4 (era 4-8), cap 40 (era 80), timer 2x più lento.
  /// Boss: primo a 120 kill, poi gap +60 (raddoppiato), cooldown 5s. Durante
  /// la boss fight lo spawn generico è sospeso (solo minion del boss).
  void updateTunnel(double dt) {
    _tunnelSpawnTimer -= dt;
    if (_tunnelBossCooldown > 0) _tunnelBossCooldown -= dt;

    // Mantieni almeno 10 nemici attivi (era 20).
    // OR intenzionale: due condizioni di spawn legittime e indipendenti —
    // (a) il timer è scaduto, oppure (b) il count è sotto la soglia minima.
    // Il reset di `_tunnelSpawnTimer` qui sotto vale per entrambi i path
    // (anche quello count-based), così non si ha double-fire nel frame
    // successivo.
    // `bossCount == 0`: durante una boss fight NON spawnare mob generici — solo
    // il boss spawna i suoi minion a tema/colore (come in modalità classica).
    // Prima spawnava "qualsiasi tipo" anche durante i boss (richiesta utente).
    if ((_tunnelSpawnTimer <= 0 || game.enemyCount < 10) &&
        game.bossCount == 0) {
      // Timer raddoppiato: 0.6-1.6s invece di 0.3-0.8s.
      // Reset incondizionato: copre sia il path "timer scaduto" sia
      // "count basso" → niente double-fire al prossimo frame.
      _tunnelSpawnTimer = 0.6 + _tunnelRng.nextDouble() * 1.0;

      // Batch dimezzato: 2-4 nemici (era 4-8)
      final count = _scaledSpawnCount(2 + _tunnelRng.nextInt(3));
      for (int i = 0; i < count; i++) {
        if (game.enemyCount >= 40) break; // Cap dimezzato (era 80)
        final type = _randomTunnelEnemyType();
        game.spawnEnemy(type);
      }
    }

    // Boss a intervalli crescenti via _nextBossAt (primo a 120 kill, poi +60).
    // FIX multi-boss: `world.add` è async (la boss viene aggiunta al prossimo
    // update), quindi `bossCount == 0` può essere true per qualche frame dopo
    // lo spawn → potevano partire 3-4 boss in sequenza. Ora settiamo subito
    // un cooldown di 5s per dare tempo alla boss di materializzarsi.
    // Soglia kill raggiunta: avvia l'allargamento del tunnel SUBITO e spawna
    // il boss 5s dopo (richiesta utente: "il tunnel deve allargarsi 5s prima").
    if (_tunnelKillCount >= _nextBossAt &&
        game.bossCount == 0 &&
        _tunnelBossCooldown <= 0 &&
        _tunnelBossPending == null) {
      // Ordine randomico via shuffle bag (richiesta utente).
      if (_tunnelBossBag.isEmpty) _refillTunnelBossBag();
      _tunnelBossPending = _tunnelBossBag.removeAt(0);
      _tunnelBossPendingTimer = 5.0;
      game.tunnelBossIncoming = true; // game_world allarga il tunnel ORA
    }
    // Conto alla rovescia 5s → spawn del boss a tunnel già allargato.
    if (_tunnelBossPending != null) {
      _tunnelBossPendingTimer -= dt;
      if (_tunnelBossPendingTimer <= 0) {
        game.spawnBoss(_tunnelBossPending!);
        _tunnelBossPending = null;
        game.tunnelBossIncoming = false;
        // Gap tra boss RADDOPPIATO (richiesta utente): +60 kill invece di +30.
        _nextBossAt += 60;
        _tunnelBossCooldown = 5.0; // copre materializzazione async
      }
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
    // Progressione "wave" nel tunnel: 1 wave ogni 60 kill (sincronizzata al
    // gap boss raddoppiato).
    final computedWave = (_tunnelKillCount ~/ 60) + 1;
    if (computedWave > currentWave) {
      currentWave = computedWave;
    }
  }

  /// Genera wave dummy per tunnel (il vero spawn è in _updateTunnel)
  WaveConfig _generateTunnelWave(int wave) {
    return WaveConfig(waveNumber: wave, spawns: []);
  }

  /// Daily Challenge — redesign (richiesta utente):
  /// - NO boss (anche le wave "boss" precedenti diventano mob waves).
  /// - Grande numero di mob per wave (50-80 invece di 6-50).
  /// - UN SOLO tipo per wave, scelto col seed giornaliero (procedurale,
  ///   stesso per tutti i player nello stesso giorno).
  /// - Mob distribuiti arena-wide random (no cluster ai bordi/centro).
  /// - Wave count: ENDLESS (nessun cap esplicito, come tutti gli altri mode
  ///   non-bossRush). `_completeWave` schedula sempre `currentWave + 1`. La
  ///   nota storica "10 wave nominali" si riferiva al numero di
  ///   `WaveConfig` originariamente hand-tuned; col redesign ogni wave è
  ///   procedurale via `_dailyChallengeMobPool[typeRng]` quindi continua
  ///   indefinitamente. Lo score continua a contare wave dopo wave.
  ///
  /// Implementation note: il `WaveConfig` ritorna `spawns: []` perché lo
  /// spawn vero avviene in `_spawnDailyChallengeMobs` (chiamato direttamente
  /// da `startWave`). Stesso pattern di Gravity Inferno black holes — evita
  /// di passare per la formation scatter clustered, e ci permette di
  /// distribuire i mob arena-wide con il nostro RNG dedicato.
  WaveConfig _generateDailyChallengeWave(int wave) {
    // Nessun spawn dichiarato: lo spawn diretto è in `_spawnDailyChallengeMobs`.
    // Lo `startWave` rileva `spawns.isEmpty` e attiva direttamente
    // `_allSpawned = true; _postSpawnDelay = 0.8;` → la wave completa quando
    // tutti i nemici muoiono.
    return WaveConfig(waveNumber: wave, spawns: const [], boss: null);
  }

  /// Pool di tipi mob per Daily Challenge (richiesta utente: pool ampio per
  /// varietà). Esclusi SOLO 3 tipi che romperebbero la modalità a 50-80×
  /// simultanei:
  /// - blackHole: hazard che risucchia/assorbe gli altri mob, non un mob.
  /// - gate: cancello non-killabile coi proiettili (mechanic pacifist).
  /// - vortex: spiral-shooter → ~400+ proiettili/sec a 50-80× = ingiocabile.
  ///
  /// Tutti i tipi spawnano con lo STESSO range 50-80× (richiesta utente: "più
  /// o meno uguali di numero"). I tipi "intensi" sono safe anche a 80× nel
  /// daily single-type: necro non rianima altri necro (no-op), spawner si
  /// auto-limita a enemyCount<60, healer cura solo +1/2.5s (il burst del daily
  /// weapon uccide comunque), mutator si auto-distrugge dopo N mutazioni.
  static const List<EnemyType> _dailyChallengeMobPool = [
    // Attaccanti / inseguitori puri (roll pieno 50-80×).
    EnemyType.drone,
    EnemyType.swarmDrone,
    EnemyType.kamikaze,
    EnemyType.snake,
    EnemyType.mine,
    EnemyType.splitter,
    EnemyType.shieldEnemy,
    EnemyType.pulsar,
    EnemyType.mirror,
    EnemyType.phantom,
    EnemyType.titan,
    EnemyType.orbiter,
    EnemyType.tesla,
    EnemyType.laserTurret,
    EnemyType.timeBomb,
    EnemyType.weaver,
    EnemyType.glitch,
    EnemyType.proton,
    EnemyType.decoy,
    // Tipi "intensi" (support/hazard) — stesso range 50-80× degli altri.
    EnemyType.siren,
    EnemyType.mutator,
    EnemyType.healer,
    EnemyType.necro,
    EnemyType.spawner,
    EnemyType.gravityWell,
    EnemyType.leech,
  ];

  /// Distanza minima di spawn dal player in Daily Challenge (px, center-to-
  /// center). 50 era troppo poco (mob grossi → comunque "addosso" al player);
  /// 160 dà un gap chiaro così non spawnano vicino. Tunabile.
  static const double _dailyMinPlayerSpawnDist = 160.0;

  /// Tipo mob per la wave Daily via SHUFFLE BAG (richiesta utente: "non
  /// devono mai spawnare due volte di fila gli stessi mob ... prima un giro
  /// completo di tutti i mob"). Ogni "ciclo" di N wave (N = pool.length)
  /// mostra TUTTI i tipi una volta in ordine shuffle deterministico (è una
  /// permutazione → nessuna ripetizione interna). La correzione di seam tra
  /// cicli garantisce che nemmeno al confine ciclo-su-ciclo si ripeta lo
  /// stesso tipo due wave di fila. Deterministico dal seed giornaliero →
  /// stesso ordine per tutti i player nello stesso giorno.
  EnemyType _dailyTypeForWave(int wave) {
    final pool = _dailyChallengeMobPool;
    final n = pool.length;
    if (n <= 1) return pool.first;
    final cycle = wave ~/ n;
    final idx = wave % n;
    return pool[_dailyShuffledOrder(cycle)[idx]];
  }

  /// Permutazione [0..n) deterministica per il `cycle`-esimo giro del pool,
  /// con correzione di seam: se il primo elemento di questo ciclo coincide
  /// con l'ultimo del ciclo precedente, scambia i primi due → mai due wave
  /// consecutive con lo stesso tipo. Iterativo da 0 a `cycle` (no ricorsione);
  /// chiamato una volta per wave-start, costo O(cycle·n) trascurabile.
  List<int> _dailyShuffledOrder(int cycle) {
    final n = _dailyChallengeMobPool.length;
    List<int>? prev;
    var order = <int>[];
    for (int c = 0; c <= cycle; c++) {
      order = List<int>.generate(n, (i) => i);
      // Stream distinto per ciclo, scorrelato dal seed posizioni.
      final rng = math.Random(_dailySeed ^ (0x9E3779B9 + c * 0x85EBCA77));
      for (int i = n - 1; i > 0; i--) {
        final j = rng.nextInt(i + 1);
        final tmp = order[i];
        order[i] = order[j];
        order[j] = tmp;
      }
      // Seam fix (solo n>2: con n<=2 lo swap [0]<->[1] ricreerebbe l'adiacenza
      // vietata). Pool attuale = 26 → sempre attivo.
      if (n > 2 && prev != null && order[0] == prev[n - 1]) {
        final tmp = order[0];
        order[0] = order[1];
        order[1] = tmp;
      }
      prev = order;
    }
    return order;
  }

  /// Spawna i mob della Daily Challenge: 50-80 mob di un singolo tipo,
  /// distribuiti arena-wide random (no clustering). Tipo deterministico
  /// dal seed giornaliero + wave (chiamate RNG sequenziali → tipo diverso
  /// per wave dallo stesso seed).
  ///
  /// Distribuzione: random uniforme su arena con margine bordi 60px. Niente
  /// Poisson-disc (con 50-80 mob sarebbe troppo restrittivo e degraderebbe
  /// in fallback ammassato) — il caos è desiderato qui.
  void _spawnDailyChallengeMobs(int wave) {
    // Tipo via shuffle bag: giro completo di tutti i mob prima di ripetere,
    // mai due wave di fila lo stesso tipo (richiesta utente).
    final chosenType = _dailyTypeForWave(wave);
    // RNG per posizioni: seed include wave per varietà posizionale ma
    // resta deterministico per la stessa data + wave.
    final posRng = math.Random(_dailySeed * 13 + wave * 17);
    // 50-80 mob per wave, UGUALE per ogni tipo (richiesta utente: "più o meno
    // uguali di numero"). Nessun soft-cap: i tipi intensi sono safe a 80× nel
    // daily single-type (vedi commento del pool).
    final mobCount = _scaledSpawnCount(50 + posRng.nextInt(31)).clamp(50, 80);

    final eW = game.effectiveArenaWidth;
    final eH = game.effectiveArenaHeight;
    const margin = 60.0;
    // Esclusione spawn vicino al player (richiesta utente). Best-of-N: campiona
    // finché trova un punto oltre minDist; se nessuno passa (arena minuscola),
    // TIENE il candidato PIÙ LONTANO campionato. Niente più push+clamp, che
    // vicino ai bordi poteva ri-avvicinare al player → "ancora spawn vicino".
    // A inizio partita il player è già posizionato al centro (game_world setta
    // player.position PRIMA di startWave) ma NON è ancora mounted nello stesso
    // tick: il vecchio gate `isMounted` rendeva playerPos null → esclusione
    // saltata → mob addosso a inizio partita (utente). La position è valida
    // anche prima del mount → usala sempre.
    final playerPos = game.player.position.clone();
    const minDist2 = _dailyMinPlayerSpawnDist * _dailyMinPlayerSpawnDist;
    const maxPosAttempts = 30;
    Vector2 samplePos() => Vector2(
          margin + posRng.nextDouble() * (eW - margin * 2),
          margin + posRng.nextDouble() * (eH - margin * 2),
        );
    for (int i = 0; i < mobCount; i++) {
      var pos = samplePos();
      var bestD2 = pos.distanceToSquared(playerPos);
      var attempts = 0;
      while (bestD2 < minDist2 && attempts < maxPosAttempts) {
        final cand = samplePos();
        final d2 = cand.distanceToSquared(playerPos);
        if (d2 > bestD2) {
          pos = cand;
          bestD2 = d2;
        }
        attempts++;
      }
      game.spawnEnemy(chosenType, pos);
    }
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
      1: [_Formation.ring, _Formation.cross],
      2: [
        _Formation.diamond,
        _Formation.flower,
        _Formation.vArrow,
        _Formation.borderLine,
      ],
      3: [
        _Formation.cross,
        _Formation.doublering,
        _Formation.cascade,
        _Formation.scatter,
        _Formation.ring,
        _Formation.borderLine,
        _Formation.playerRing,
      ],
      4: [
        _Formation.triangle,
        _Formation.burst,
        _Formation.ring,
        _Formation.xShape,
        _Formation.arrowHead,
        _Formation.squareRing,
        _Formation.playerDoubleRing,
      ],
      5: [
        _Formation.hexagon,
        _Formation.flower,
        _Formation.pinwheel,
        _Formation.scatter,
        _Formation.arrowHead,
        _Formation.sineWave,
        _Formation.cascade,
        _Formation.ring,
      ],
      6: [
        _Formation.star5,
        _Formation.doublering,
        _Formation.diamond,
        _Formation.scatter,
        _Formation.vArrow,
        _Formation.sineWave,
        _Formation.cross,
        _Formation.ring,
        _Formation.borderLine,
        _Formation.playerEncircle,
      ],
      7: [
        _Formation.pinwheel,
        _Formation.ring,
        _Formation.honeycomb,
        _Formation.xShape,
        _Formation.arrowHead,
        _Formation.tripleRing,
        _Formation.cascade,
        _Formation.squareRing,
        _Formation.arc,
        _Formation.borderLine,
      ],
      8: [
        _Formation.comet,
        _Formation.flower,
        _Formation.triangle,
        _Formation.scatter,
        _Formation.burst,
        _Formation.sineWave,
        _Formation.vArrow,
        _Formation.cross,
        _Formation.diamond,
        _Formation.ring,
        _Formation.playerRing,
      ],
      9: [
        _Formation.infinity8,
        _Formation.doublering,
        _Formation.hexagon,
        _Formation.scatter,
        _Formation.arrowHead,
        _Formation.sineWave,
        _Formation.diamond,
        _Formation.xShape,
        _Formation.cross,
        _Formation.arc,
      ],
      11: [
        _Formation.doubleSpiral,
        _Formation.ring,
        _Formation.star5,
        _Formation.scatter,
        _Formation.arrowHead,
        _Formation.sineWave,
        _Formation.doublering,
        _Formation.cascade,
      ],
      12: [
        _Formation.flower,
        _Formation.honeycomb,
        _Formation.comet,
        _Formation.scatter,
        _Formation.burst,
        _Formation.sineWave,
        _Formation.vArrow,
        _Formation.cross,
        _Formation.doublering,
        _Formation.arc,
        _Formation.ring,
        _Formation.borderLine,
      ],
      13: [
        _Formation.wShape,
        _Formation.burst,
        _Formation.hexagon,
        _Formation.scatter,
        _Formation.arrowHead,
        _Formation.zigzag,
        _Formation.diamond,
        _Formation.ring,
        _Formation.cross,
        _Formation.arc,
      ],
      14: [
        _Formation.honeycomb,
        _Formation.ring,
        _Formation.diamond,
        _Formation.cross,
        _Formation.arrowHead,
        _Formation.sineWave,
        _Formation.cascade,
        _Formation.star5,
        _Formation.doublering,
        _Formation.tripleRing,
        _Formation.ring,
      ],
      15: [
        _Formation.tripleRing,
        _Formation.flower,
        _Formation.cross,
        _Formation.scatter,
        _Formation.vArrow,
        _Formation.sineWave,
        _Formation.pinwheel,
        _Formation.ring,
        _Formation.comet,
      ],
      16: [
        _Formation.star5,
        _Formation.cascade,
        _Formation.hexagon,
        _Formation.scatter,
        _Formation.arrowHead,
        _Formation.doubleSpiral,
        _Formation.xShape,
        _Formation.ring,
        _Formation.sineWave,
        _Formation.arc,
      ],
      17: [
        _Formation.infinity8,
        _Formation.doublering,
        _Formation.diamond,
        _Formation.xShape,
        _Formation.burst,
        _Formation.zigzag,
        _Formation.arrowHead,
        _Formation.flower,
        _Formation.ring,
        _Formation.borderLine,
      ],
      18: [
        _Formation.squareRing,
        _Formation.ring,
        _Formation.triangle,
        _Formation.scatter,
        _Formation.arrowHead,
        _Formation.sineWave,
        _Formation.cascade,
        _Formation.cross,
        _Formation.diamond,
        _Formation.arc,
        _Formation.ring,
      ],
      19: [
        _Formation.pinwheel,
        _Formation.flower,
        _Formation.wShape,
        _Formation.scatter,
        _Formation.vArrow,
        _Formation.sineWave,
        _Formation.xShape,
        _Formation.hexagon,
        _Formation.ring,
        _Formation.arc,
        _Formation.doublering,
      ],
      21: [
        _Formation.arrowHead,
        _Formation.ring,
        _Formation.star5,
        _Formation.scatter,
        _Formation.burst,
        _Formation.sineWave,
        _Formation.doublering,
        _Formation.cascade,
        _Formation.ring,
      ],
      22: [
        _Formation.zigzag,
        _Formation.burst,
        _Formation.hexagon,
        _Formation.scatter,
        _Formation.arrowHead,
        _Formation.sineWave,
        _Formation.diamond,
        _Formation.xShape,
        _Formation.flower,
        _Formation.cross,
      ],
      23: [
        _Formation.doublering,
        _Formation.flower,
        _Formation.honeycomb,
        _Formation.scatter,
        _Formation.arrowHead,
        _Formation.sineWave,
        _Formation.cross,
        _Formation.comet,
        _Formation.ring,
        _Formation.arc,
        _Formation.borderLine,
      ],
      24: [
        _Formation.sineWave,
        _Formation.ring,
        _Formation.diamond,
        _Formation.xShape,
        _Formation.arrowHead,
        _Formation.zigzag,
        _Formation.doubleSpiral,
        _Formation.flower,
        _Formation.cross,
        _Formation.arc,
        _Formation.ring,
      ],
      25: [
        _Formation.xShape,
        _Formation.flower,
        _Formation.star5,
        _Formation.scatter,
        _Formation.arrowHead,
        _Formation.tripleRing,
        _Formation.pinwheel,
        _Formation.ring,
        _Formation.comet,
      ],
      26: [
        _Formation.cascade,
        _Formation.ring,
        _Formation.honeycomb,
        _Formation.scatter,
        _Formation.arrowHead,
        _Formation.wShape,
        _Formation.diamond,
        _Formation.xShape,
        _Formation.sineWave,
        _Formation.cross,
      ],
      27: [
        _Formation.pinwheel,
        _Formation.doublering,
        _Formation.comet,
        _Formation.scatter,
        _Formation.burst,
        _Formation.sineWave,
        _Formation.vArrow,
        _Formation.cross,
        _Formation.ring,
        _Formation.arc,
      ],
      28: [
        _Formation.comet,
        _Formation.flower,
        _Formation.triangle,
        _Formation.scatter,
        _Formation.arrowHead,
        _Formation.zigzag,
        _Formation.diamond,
        _Formation.ring,
        _Formation.cross,
        _Formation.doublering,
        _Formation.ring,
        _Formation.sineWave,
        _Formation.borderLine,
      ],
      29: [
        _Formation.wShape,
        _Formation.ring,
        _Formation.hexagon,
        _Formation.scatter,
        _Formation.arrowHead,
        _Formation.sineWave,
        _Formation.xShape,
        _Formation.doubleSpiral,
        _Formation.cross,
        _Formation.arc,
      ],
      31: [
        _Formation.star5,
        _Formation.flower,
        _Formation.ring,
        _Formation.scatter,
        _Formation.arrowHead,
        _Formation.sineWave,
        _Formation.cascade,
        _Formation.honeycomb,
        _Formation.cross,
        _Formation.arc,
        _Formation.doublering,
      ],
      32: [
        _Formation.honeycomb,
        _Formation.burst,
        _Formation.diamond,
        _Formation.scatter,
        _Formation.vArrow,
        _Formation.zigzag,
        _Formation.ring,
        _Formation.xShape,
        _Formation.sineWave,
        _Formation.comet,
        _Formation.cross,
      ],
      33: [
        _Formation.tripleRing,
        _Formation.ring,
        _Formation.hexagon,
        _Formation.scatter,
        _Formation.arrowHead,
        _Formation.sineWave,
        _Formation.squareRing,
        _Formation.flower,
        _Formation.cross,
        _Formation.arc,
      ],
      34: [
        _Formation.doubleSpiral,
        _Formation.flower,
        _Formation.star5,
        _Formation.scatter,
        _Formation.arrowHead,
        _Formation.sineWave,
        _Formation.doublering,
        _Formation.diamond,
        _Formation.xShape,
        _Formation.ring,
        _Formation.arc,
        _Formation.cross,
        _Formation.borderLine,
      ],
      35: [
        _Formation.infinity8,
        _Formation.ring,
        _Formation.honeycomb,
        _Formation.scatter,
        _Formation.vArrow,
        _Formation.sineWave,
        _Formation.cascade,
        _Formation.arrowHead,
        _Formation.cross,
        _Formation.doublering,
        _Formation.comet,
      ],
      36: [
        _Formation.zigzag,
        _Formation.burst,
        _Formation.diamond,
        _Formation.scatter,
        _Formation.arrowHead,
        _Formation.tripleRing,
        _Formation.ring,
        _Formation.xShape,
        _Formation.sineWave,
        _Formation.cross,
      ],
      37: [
        _Formation.squareRing,
        _Formation.flower,
        _Formation.hexagon,
        _Formation.scatter,
        _Formation.arrowHead,
        _Formation.sineWave,
        _Formation.wShape,
        _Formation.ring,
        _Formation.cross,
        _Formation.arc,
        _Formation.doublering,
      ],
      38: [
        _Formation.wShape,
        _Formation.ring,
        _Formation.comet,
        _Formation.scatter,
        _Formation.arrowHead,
        _Formation.zigzag,
        _Formation.diamond,
        _Formation.xShape,
        _Formation.sineWave,
        _Formation.flower,
        _Formation.cross,
        _Formation.doublering,
      ],
      39: [
        _Formation.arrowHead,
        _Formation.doublering,
        _Formation.star5,
        _Formation.scatter,
        _Formation.burst,
        _Formation.sineWave,
        _Formation.ring,
        _Formation.cascade,
        _Formation.cross,
        _Formation.arc,
        _Formation.flower,
      ],
      41: [
        _Formation.doubleSpiral,
        _Formation.flower,
        _Formation.ring,
        _Formation.scatter,
        _Formation.arrowHead,
        _Formation.zigzag,
        _Formation.honeycomb,
        _Formation.doublering,
        _Formation.cross,
        _Formation.arc,
      ],
      42: [
        _Formation.flower,
        _Formation.burst,
        _Formation.diamond,
        _Formation.scatter,
        _Formation.vArrow,
        _Formation.sineWave,
        _Formation.ring,
        _Formation.xShape,
        _Formation.comet,
        _Formation.cross,
        _Formation.arc,
        _Formation.borderLine,
      ],
      43: [
        _Formation.hexagon,
        _Formation.ring,
        _Formation.honeycomb,
        _Formation.scatter,
        _Formation.arrowHead,
        _Formation.sineWave,
        _Formation.wShape,
        _Formation.flower,
        _Formation.cross,
        _Formation.doublering,
        _Formation.arc,
      ],
      44: [
        _Formation.star5,
        _Formation.doublering,
        _Formation.scatter,
        _Formation.arrowHead,
        _Formation.tripleRing,
        _Formation.pinwheel,
        _Formation.ring,
        _Formation.cascade,
        _Formation.cross,
      ],
      46: [
        _Formation.tripleRing,
        _Formation.ring,
        _Formation.hexagon,
        _Formation.scatter,
        _Formation.vArrow,
        _Formation.sineWave,
        _Formation.squareRing,
        _Formation.flower,
        _Formation.cross,
        _Formation.arc,
      ],
      47: [
        _Formation.comet,
        _Formation.flower,
        _Formation.diamond,
        _Formation.scatter,
        _Formation.arrowHead,
        _Formation.zigzag,
        _Formation.ring,
        _Formation.xShape,
        _Formation.sineWave,
        _Formation.cross,
        _Formation.doublering,
      ],
      48: [
        _Formation.infinity8,
        _Formation.burst,
        _Formation.star5,
        _Formation.scatter,
        _Formation.arrowHead,
        _Formation.sineWave,
        _Formation.doublering,
        _Formation.honeycomb,
        _Formation.cross,
        _Formation.arc,
        _Formation.flower,
      ],
      49: [
        _Formation.pinwheel,
        _Formation.ring,
        _Formation.cascade,
        _Formation.scatter,
        _Formation.burst,
        _Formation.zigzag,
        _Formation.arrowHead,
        _Formation.doublering,
        _Formation.cross,
        _Formation.sineWave,
      ],
      51: [
        _Formation.wShape,
        _Formation.flower,
        _Formation.ring,
        _Formation.scatter,
        _Formation.arrowHead,
        _Formation.sineWave,
        _Formation.xShape,
        _Formation.star5,
        _Formation.cross,
        _Formation.arc,
        _Formation.doublering,
      ],
      52: [
        _Formation.squareRing,
        _Formation.burst,
        _Formation.hexagon,
        _Formation.scatter,
        _Formation.vArrow,
        _Formation.sineWave,
        _Formation.ring,
        _Formation.comet,
        _Formation.cross,
        _Formation.flower,
        _Formation.arc,
      ],
      53: [
        _Formation.doubleSpiral,
        _Formation.ring,
        _Formation.honeycomb,
        _Formation.scatter,
        _Formation.arrowHead,
        _Formation.zigzag,
        _Formation.diamond,
        _Formation.xShape,
        _Formation.sineWave,
        _Formation.cross,
        _Formation.doublering,
        _Formation.borderLine,
      ],
      54: [
        _Formation.zigzag,
        _Formation.doublering,
        _Formation.star5,
        _Formation.scatter,
        _Formation.arrowHead,
        _Formation.tripleRing,
        _Formation.ring,
        _Formation.flower,
        _Formation.cascade,
        _Formation.arc,
      ],
      55: [_Formation.tripleRing, _Formation.arc],
      56: [
        _Formation.honeycomb,
        _Formation.flower,
        _Formation.diamond,
        _Formation.scatter,
        _Formation.arrowHead,
        _Formation.sineWave,
        _Formation.wShape,
        _Formation.ring,
        _Formation.cross,
        _Formation.arc,
        _Formation.doublering,
      ],
      57: [
        _Formation.arrowHead,
        _Formation.burst,
        _Formation.hexagon,
        _Formation.scatter,
        _Formation.zigzag,
        _Formation.ring,
        _Formation.xShape,
        _Formation.sineWave,
        _Formation.flower,
        _Formation.cross,
      ],
      58: [
        _Formation.comet,
        _Formation.ring,
        _Formation.star5,
        _Formation.scatter,
        _Formation.vArrow,
        _Formation.sineWave,
        _Formation.doublering,
        _Formation.honeycomb,
        _Formation.cross,
        _Formation.arc,
        _Formation.flower,
      ],
      59: [
        _Formation.tripleRing,
        _Formation.flower,
        _Formation.cascade,
        _Formation.scatter,
        _Formation.arrowHead,
        _Formation.sineWave,
        _Formation.squareRing,
        _Formation.ring,
        _Formation.cross,
        _Formation.doublering,
        _Formation.arc,
      ],
      60: [_Formation.ring, _Formation.doubleSpiral],
      61: [
        _Formation.infinity8,
        _Formation.burst,
        _Formation.ring,
        _Formation.scatter,
        _Formation.arrowHead,
        _Formation.zigzag,
        _Formation.flower,
        _Formation.xShape,
        _Formation.sineWave,
        _Formation.cross,
        _Formation.doublering,
      ],
      62: [
        _Formation.star5,
        _Formation.ring,
        _Formation.honeycomb,
        _Formation.scatter,
        _Formation.burst,
        _Formation.sineWave,
        _Formation.wShape,
        _Formation.doublering,
        _Formation.cross,
        _Formation.arc,
        _Formation.flower,
      ],
      63: [
        _Formation.pinwheel,
        _Formation.flower,
        _Formation.diamond,
        _Formation.scatter,
        _Formation.arrowHead,
        _Formation.tripleRing,
        _Formation.ring,
        _Formation.xShape,
        _Formation.comet,
        _Formation.cross,
        _Formation.sineWave,
      ],
      64: [
        _Formation.doubleSpiral,
        _Formation.doublering,
        _Formation.hexagon,
        _Formation.scatter,
        _Formation.vArrow,
        _Formation.zigzag,
        _Formation.ring,
        _Formation.flower,
        _Formation.cross,
        _Formation.arc,
        _Formation.cascade,
      ],
      65: [_Formation.hexagon, _Formation.cascade],
      66: [
        _Formation.squareRing,
        _Formation.flower,
        _Formation.star5,
        _Formation.scatter,
        _Formation.arrowHead,
        _Formation.sineWave,
        _Formation.doublering,
        _Formation.burst,
        _Formation.cross,
        _Formation.arc,
        _Formation.ring,
      ],
      67: [
        _Formation.wShape,
        _Formation.ring,
        _Formation.comet,
        _Formation.scatter,
        _Formation.arrowHead,
        _Formation.zigzag,
        _Formation.xShape,
        _Formation.flower,
        _Formation.sineWave,
        _Formation.cross,
        _Formation.doublering,
        _Formation.borderLine,
      ],
      68: [
        _Formation.flower,
        _Formation.burst,
        _Formation.hexagon,
        _Formation.scatter,
        _Formation.burst,
        _Formation.sineWave,
        _Formation.honeycomb,
        _Formation.ring,
        _Formation.cross,
        _Formation.arc,
        _Formation.doublering,
        _Formation.flower,
      ],
      69: [
        _Formation.zigzag,
        _Formation.ring,
        _Formation.diamond,
        _Formation.scatter,
        _Formation.arrowHead,
        _Formation.tripleRing,
        _Formation.pinwheel,
        _Formation.doublering,
        _Formation.cross,
        _Formation.sineWave,
        _Formation.arc,
      ],
      70: [_Formation.scatter, _Formation.zigzag],
      71: [
        _Formation.tripleRing,
        _Formation.flower,
        _Formation.ring,
        _Formation.scatter,
        _Formation.arrowHead,
        _Formation.sineWave,
        _Formation.star5,
        _Formation.xShape,
        _Formation.cross,
        _Formation.arc,
        _Formation.doublering,
      ],
      72: [
        _Formation.honeycomb,
        _Formation.burst,
        _Formation.hexagon,
        _Formation.scatter,
        _Formation.vArrow,
        _Formation.zigzag,
        _Formation.ring,
        _Formation.flower,
        _Formation.sineWave,
        _Formation.cross,
        _Formation.arc,
      ],
      73: [
        _Formation.infinity8,
        _Formation.ring,
        _Formation.star5,
        _Formation.scatter,
        _Formation.arrowHead,
        _Formation.sineWave,
        _Formation.doublering,
        _Formation.wShape,
        _Formation.cross,
        _Formation.arc,
        _Formation.flower,
        _Formation.doubleSpiral,
      ],
      74: [
        _Formation.comet,
        _Formation.doublering,
        _Formation.cascade,
        _Formation.scatter,
        _Formation.arrowHead,
        _Formation.tripleRing,
        _Formation.ring,
        _Formation.xShape,
        _Formation.sineWave,
        _Formation.cross,
        _Formation.flower,
        _Formation.arc,
      ],
      75: [_Formation.squareRing, _Formation.cross],
      76: [
        _Formation.star5,
        _Formation.flower,
        _Formation.honeycomb,
        _Formation.scatter,
        _Formation.burst,
        _Formation.sineWave,
        _Formation.diamond,
        _Formation.ring,
        _Formation.cross,
        _Formation.arc,
        _Formation.doublering,
        _Formation.zigzag,
      ],
      77: [
        _Formation.pinwheel,
        _Formation.ring,
        _Formation.star5,
        _Formation.scatter,
        _Formation.arrowHead,
        _Formation.sineWave,
        _Formation.wShape,
        _Formation.flower,
        _Formation.cross,
        _Formation.comet,
        _Formation.doublering,
        _Formation.arc,
      ],
      78: [
        _Formation.doubleSpiral,
        _Formation.burst,
        _Formation.hexagon,
        _Formation.scatter,
        _Formation.vArrow,
        _Formation.zigzag,
        _Formation.tripleRing,
        _Formation.ring,
        _Formation.sineWave,
        _Formation.cross,
        _Formation.flower,
        _Formation.doublering,
      ],
      79: [
        _Formation.squareRing,
        _Formation.ring,
        _Formation.star5,
        _Formation.scatter,
        _Formation.arrowHead,
        _Formation.sineWave,
        _Formation.xShape,
        _Formation.honeycomb,
        _Formation.cross,
        _Formation.arc,
        _Formation.flower,
        _Formation.doublering,
      ],
      80: [_Formation.xShape, _Formation.scatter],
      81: [
        _Formation.wShape,
        _Formation.flower,
        _Formation.diamond,
        _Formation.scatter,
        _Formation.arrowHead,
        _Formation.tripleRing,
        _Formation.ring,
        _Formation.xShape,
        _Formation.sineWave,
        _Formation.cross,
        _Formation.doublering,
        _Formation.arc,
      ],
      82: [
        _Formation.honeycomb,
        _Formation.burst,
        _Formation.ring,
        _Formation.scatter,
        _Formation.zigzag,
        _Formation.flower,
        _Formation.doublering,
        _Formation.cross,
        _Formation.sineWave,
        _Formation.arc,
        _Formation.star5,
        _Formation.borderLine,
      ],
      83: [
        _Formation.infinity8,
        _Formation.ring,
        _Formation.hexagon,
        _Formation.scatter,
        _Formation.arrowHead,
        _Formation.sineWave,
        _Formation.comet,
        _Formation.xShape,
        _Formation.cross,
        _Formation.flower,
        _Formation.doublering,
        _Formation.arc,
        _Formation.doubleSpiral,
      ],
      84: [
        _Formation.squareRing,
        _Formation.doublering,
        _Formation.star5,
        _Formation.scatter,
        _Formation.vArrow,
        _Formation.tripleRing,
        _Formation.pinwheel,
        _Formation.ring,
        _Formation.cross,
        _Formation.sineWave,
        _Formation.arc,
        _Formation.flower,
        _Formation.cascade,
      ],
      85: [_Formation.honeycomb, _Formation.ring],
      86: [
        _Formation.tripleRing,
        _Formation.flower,
        _Formation.honeycomb,
        _Formation.scatter,
        _Formation.arrowHead,
        _Formation.sineWave,
        _Formation.star5,
        _Formation.ring,
        _Formation.cross,
        _Formation.arc,
        _Formation.doublering,
        _Formation.burst,
        _Formation.zigzag,
      ],
      87: [
        _Formation.doubleSpiral,
        _Formation.burst,
        _Formation.hexagon,
        _Formation.scatter,
        _Formation.arrowHead,
        _Formation.zigzag,
        _Formation.ring,
        _Formation.xShape,
        _Formation.sineWave,
        _Formation.flower,
        _Formation.cross,
        _Formation.doublering,
        _Formation.arc,
      ],
      88: [
        _Formation.comet,
        _Formation.ring,
        _Formation.star5,
        _Formation.scatter,
        _Formation.burst,
        _Formation.sineWave,
        _Formation.wShape,
        _Formation.doublering,
        _Formation.cross,
        _Formation.arc,
        _Formation.flower,
        _Formation.hexagon,
        _Formation.tripleRing,
      ],
      89: [
        _Formation.flower,
        _Formation.doublering,
        _Formation.cascade,
        _Formation.scatter,
        _Formation.arrowHead,
        _Formation.tripleRing,
        _Formation.squareRing,
        _Formation.ring,
        _Formation.cross,
        _Formation.sineWave,
        _Formation.arc,
        _Formation.flower,
        _Formation.diamond,
      ],
      90: [_Formation.ring, _Formation.doubleSpiral],
      91: [
        _Formation.star5,
        _Formation.burst,
        _Formation.ring,
        _Formation.scatter,
        _Formation.arrowHead,
        _Formation.sineWave,
        _Formation.infinity8,
        _Formation.xShape,
        _Formation.cross,
        _Formation.doublering,
        _Formation.arc,
        _Formation.flower,
        _Formation.zigzag,
        _Formation.pinwheel,
      ],
      92: [
        _Formation.pinwheel,
        _Formation.ring,
        _Formation.hexagon,
        _Formation.scatter,
        _Formation.vArrow,
        _Formation.zigzag,
        _Formation.flower,
        _Formation.doublering,
        _Formation.cross,
        _Formation.sineWave,
        _Formation.arc,
        _Formation.burst,
        _Formation.comet,
      ],
      93: [
        _Formation.wShape,
        _Formation.flower,
        _Formation.star5,
        _Formation.scatter,
        _Formation.arrowHead,
        _Formation.tripleRing,
        _Formation.ring,
        _Formation.xShape,
        _Formation.sineWave,
        _Formation.cross,
        _Formation.arc,
        _Formation.doublering,
        _Formation.honeycomb,
        _Formation.doubleSpiral,
      ],
      94: [
        _Formation.honeycomb,
        _Formation.burst,
        _Formation.cascade,
        _Formation.scatter,
        _Formation.arrowHead,
        _Formation.sineWave,
        _Formation.squareRing,
        _Formation.ring,
        _Formation.cross,
        _Formation.flower,
        _Formation.doublering,
        _Formation.arc,
        _Formation.diamond,
        _Formation.zigzag,
      ],
      95: [_Formation.burst, _Formation.scatter],
      96: [
        _Formation.infinity8,
        _Formation.ring,
        _Formation.star5,
        _Formation.scatter,
        _Formation.burst,
        _Formation.sineWave,
        _Formation.doubleSpiral,
        _Formation.doublering,
        _Formation.cross,
        _Formation.arc,
        _Formation.flower,
        _Formation.xShape,
        _Formation.tripleRing,
        _Formation.zigzag,
        _Formation.comet,
      ],
      97: [
        _Formation.tripleRing,
        _Formation.flower,
        _Formation.hexagon,
        _Formation.scatter,
        _Formation.arrowHead,
        _Formation.zigzag,
        _Formation.ring,
        _Formation.xShape,
        _Formation.sineWave,
        _Formation.cross,
        _Formation.doublering,
        _Formation.arc,
        _Formation.wShape,
        _Formation.burst,
        _Formation.star5,
      ],
      98: [
        _Formation.squareRing,
        _Formation.burst,
        _Formation.honeycomb,
        _Formation.scatter,
        _Formation.vArrow,
        _Formation.sineWave,
        _Formation.flower,
        _Formation.ring,
        _Formation.cross,
        _Formation.arc,
        _Formation.doublering,
        _Formation.tripleRing,
        _Formation.arrowHead,
        _Formation.diamond,
        _Formation.zigzag,
        _Formation.comet,
      ],
      99: [
        _Formation.doubleSpiral,
        _Formation.ring,
        _Formation.star5,
        _Formation.scatter,
        _Formation.arrowHead,
        _Formation.tripleRing,
        _Formation.pinwheel,
        _Formation.xShape,
        _Formation.sineWave,
        _Formation.cross,
        _Formation.doublering,
        _Formation.arc,
        _Formation.flower,
        _Formation.wShape,
        _Formation.burst,
        _Formation.zigzag,
        _Formation.comet,
        _Formation.cascade,
      ],
      100: [_Formation.squareRing, _Formation.tripleRing, _Formation.cross],
    };

    final list = waveFormations[wave];
    if (list != null && groupIndex < list.length) {
      return list[groupIndex];
    }
    // Fallback deterministic per boss waves e wave non mappate
    return _Formation.values[(wave * 7 + groupIndex * 3) %
        _Formation.values.length];
  }

  /// Traduce SpawnFormation pubblico (in wave_configs.dart) → _Formation
  /// privato di questo file. Mantiene il privato come single-source-of-truth
  /// per i builder geometrici, mentre wave_configs può specificare hint senza
  /// doverli importare.
  _Formation _translateSpawnFormation(SpawnFormation s) {
    switch (s) {
      case SpawnFormation.ring:
        return _Formation.ring;
      case SpawnFormation.diamond:
        return _Formation.diamond;
      case SpawnFormation.cross:
        return _Formation.cross;
      case SpawnFormation.triangle:
        return _Formation.triangle;
      case SpawnFormation.flower:
        return _Formation.flower;
      case SpawnFormation.star5:
        return _Formation.star5;
      case SpawnFormation.pinwheel:
        return _Formation.pinwheel;
      case SpawnFormation.comet:
        return _Formation.comet;
      case SpawnFormation.infinity8:
        return _Formation.infinity8;
      case SpawnFormation.doubleSpiral:
        return _Formation.doubleSpiral;
      case SpawnFormation.honeycomb:
        return _Formation.honeycomb;
      case SpawnFormation.wShape:
        return _Formation.wShape;
      case SpawnFormation.hexagon:
        return _Formation.hexagon;
      case SpawnFormation.tripleRing:
        return _Formation.tripleRing;
      case SpawnFormation.sineWave:
        return _Formation.sineWave;
      case SpawnFormation.cascade:
        return _Formation.cascade;
      case SpawnFormation.squareRing:
        return _Formation.squareRing;
      case SpawnFormation.burst:
        return _Formation.burst;
      case SpawnFormation.arrowHead:
        return _Formation.arrowHead;
      case SpawnFormation.scatter:
        return _Formation.scatter;
      case SpawnFormation.doublering:
        return _Formation.doublering;
      case SpawnFormation.vArrow:
        return _Formation.vArrow;
      case SpawnFormation.xShape:
        return _Formation.xShape;
      case SpawnFormation.arc:
        return _Formation.arc;
      case SpawnFormation.zigzag:
        return _Formation.zigzag;
      case SpawnFormation.borderLine:
        return _Formation.borderLine;
      case SpawnFormation.playerRing:
        return _Formation.playerRing;
      case SpawnFormation.playerDoubleRing:
        return _Formation.playerDoubleRing;
      case SpawnFormation.playerEncircle:
        return _Formation.playerEncircle;
    }
  }

  /// Spawna un gruppo di nemici in una formazione geometrica.
  /// In classic mode usa la formazione assegnata alla wave/gruppo.
  /// In altri modi sceglie casualmente tra le 25 formazioni.
  /// In tunnel mode mantiene lo spawn fuori schermo originale.
  ///
  /// I SwarmDrone (mini triangoli cardinali) usano SEMPRE borderLine: spawnano
  /// in schiera lungo un intero bordo e avanzano tutti insieme perpendicolari
  /// al bordo. Coerente col design GW (ondate di "arrows" da un lato).
  void _spawnGroupWithFormation(EnemyType type, int count) {
    if (_mode == GameMode.tunnel) {
      for (int i = 0; i < count; i++) {
        game.spawnEnemy(type);
      }
      return;
    }

    // SwarmDrone: sempre borderLine con direzione iniziale forzata verso
    // l'interno — la schiera marcia come ondata cardinale.
    if (type == EnemyType.swarmDrone) {
      _spawnSwarmBorderLine(count);
      return;
    }

    // Signature wave override: il `WaveSpawn.formation` (se settato) ha
    // priorità sul lookup `_classicFormation`. Permette wave hand-curated
    // con design unico (vedi `_signatureWaveOverride` in wave_configs.dart).
    // NB: il caller incrementa `_spawnIndex` DOPO questa call → l'indice
    // corrente del gruppo in spawn è `_spawnIndex` (stesso che usa
    // `_classicFormation` sotto).
    final groupIdx = _spawnIndex;
    final spawnFormationHint =
        _currentConfig != null && groupIdx < _currentConfig!.spawns.length
        ? _currentConfig!.spawns[groupIdx].formation
        : null;
    final _Formation formation;
    if (spawnFormationHint != null) {
      formation = _translateSpawnFormation(spawnFormationHint);
    } else if (_mode == GameMode.classic) {
      formation = _classicFormation(currentWave, _spawnIndex);
    } else {
      formation = _Formation.values[_formRng.nextInt(_Formation.values.length)];
    }

    // Clamp usa effectiveArena per rispettare `tiny_arena` modifier.
    // Prima usava arenaWidth/Height full → enemy spawnavano fuori view
    // quando arena era ridotta.
    final eW = game.effectiveArenaWidth;
    final eH = game.effectiveArenaHeight;

    // borderLine per altri tipi: dispone lungo un bordo senza rush forzato.
    if (formation == _Formation.borderLine) {
      final positions = _fBorderLine(count);
      for (final pos in positions) {
        final clamped = Vector2(
          pos.x.clamp(20.0, eW - 20.0),
          pos.y.clamp(20.0, eH - 20.0),
        );
        game.spawnEnemy(type, clamped);
      }
      return;
    }

    final center = _randomFormationCenter();
    final playerPos = game.player.position;
    final positions = _buildFormation(formation, count, center, playerPos);

    for (final pos in positions) {
      final clamped = Vector2(
        pos.x.clamp(20.0, eW - 20.0),
        pos.y.clamp(20.0, eH - 20.0),
      );
      game.spawnEnemy(type, clamped);
    }
  }

  /// Spawna schiere di SwarmDrone lungo un bordo, in ondate sfalsate
  /// (richiesta utente: "più di una schiera sfalsate per renderle davvero
  /// pericolose"). 2-3 righe parallele con offset perpendicolare.
  /// Direzione di marcia applicata SUBITO via setMarchDirection → nessun
  /// glitch di rotazione random al frame 0.
  void _spawnSwarmBorderLine(int count) {
    final side = _BorderSide.values[_formRng.nextInt(4)];
    final marchDir = _borderRushDirection(side);
    final rows = 2 + _formRng.nextInt(2); // 2 o 3 schiere
    final perRow = (count / rows).ceil();
    const rowSpacing = 32.0;
    // Clamp usa effectiveArena per rispettare `tiny_arena` modifier.
    final eW = game.effectiveArenaWidth;
    final eH = game.effectiveArenaHeight;
    // Cap totale a `count` così rows*perRow non eccede il target wave.
    int totalSpawned = 0;
    for (int r = 0; r < rows && totalSpawned < count; r++) {
      final basePositions = _fBorderLine(perRow, side: side);
      for (final pos in basePositions) {
        if (totalSpawned >= count) break;
        final offset = marchDir * (rowSpacing * r);
        final sidewayShift = (r.isOdd) ? rowSpacing * 0.5 : 0.0;
        final rowPos = Vector2(
          pos.x + offset.x + (marchDir.x == 0 ? sidewayShift : 0),
          pos.y + offset.y + (marchDir.y == 0 ? sidewayShift : 0),
        );
        final clamped = Vector2(
          rowPos.x.clamp(20.0, eW - 20.0),
          rowPos.y.clamp(20.0, eH - 20.0),
        );
        final spawned = game.spawnEnemy(EnemyType.swarmDrone, clamped);
        if (spawned is SwarmDroneEnemy) {
          spawned.setMarchDirection(marchDir);
        }
        totalSpawned++;
      }
    }
  }

  /// Direzione perpendicolare al bordo, puntata verso l'interno dell'arena.
  Vector2 _borderRushDirection(_BorderSide side) {
    switch (side) {
      case _BorderSide.top:
        return Vector2(0, 1);
      case _BorderSide.bottom:
        return Vector2(0, -1);
      case _BorderSide.left:
        return Vector2(1, 0);
      case _BorderSide.right:
        return Vector2(-1, 0);
    }
  }

  /// Centro casuale nell'arena, lontano dai bordi.
  /// Usa effectiveArena per rispettare `tiny_arena` modifier — altrimenti
  /// il centro cadeva nella zona fuori-arena e tutte le posizioni
  /// venivano clampate al bordo → formazione ammassata.
  Vector2 _randomFormationCenter() {
    final eW = game.effectiveArenaWidth;
    final eH = game.effectiveArenaHeight;
    final pad = math.min(160.0, math.min(eW, eH) * 0.25);
    return Vector2(
      pad + _formRng.nextDouble() * (eW - pad * 2),
      pad + _formRng.nextDouble() * (eH - pad * 2),
    );
  }

  /// Dispatcher: seleziona il metodo di formazione corretto
  List<Vector2> _buildFormation(
    _Formation f,
    int count,
    Vector2 center,
    Vector2 playerPos,
  ) {
    switch (f) {
      case _Formation.ring:
        return _fRing(count, center, playerPos);
      case _Formation.diamond:
        return _fDiamond(count, center, playerPos);
      case _Formation.cross:
        return _fCross(count, center, playerPos);
      case _Formation.triangle:
        return _fTriangle(count, center, playerPos);
      case _Formation.flower:
        return _fFlower(count, center, playerPos);
      case _Formation.star5:
        return _fStar5(count, center, playerPos);
      case _Formation.pinwheel:
        return _fPinwheel(count, center, playerPos);
      case _Formation.comet:
        return _fComet(count, center, playerPos);
      case _Formation.infinity8:
        return _fInfinity8(count, center, playerPos);
      case _Formation.doubleSpiral:
        return _fDoubleSpiral(count, center, playerPos);
      case _Formation.honeycomb:
        return _fHoneycomb(count, center, playerPos);
      case _Formation.wShape:
        return _fWShape(count, center, playerPos);
      case _Formation.hexagon:
        return _fHexagon(count, center, playerPos);
      case _Formation.tripleRing:
        return _fTripleRing(count, center, playerPos);
      case _Formation.sineWave:
        return _fSineWave(count, center, playerPos);
      case _Formation.cascade:
        return _fCascade(count, center, playerPos);
      case _Formation.squareRing:
        return _fSquareRing(count, center, playerPos);
      case _Formation.burst:
        return _fBurst(count, center, playerPos);
      case _Formation.arrowHead:
        return _fArrowHead(count, center, playerPos);
      case _Formation.scatter:
        return _fScatter(count, center, playerPos);
      case _Formation.doublering:
        return _fDoublering(count, center, playerPos);
      case _Formation.vArrow:
        return _fVArrow(count, center, playerPos);
      case _Formation.xShape:
        return _fXShape(count, center, playerPos);
      case _Formation.arc:
        return _fArc(count, center, playerPos);
      case _Formation.zigzag:
        return _fZigzag(count, center, playerPos);
      case _Formation.borderLine:
        return _fBorderLine(count);
      // Player-centered: formazioni chiuse attorno al player.
      case _Formation.playerRing:
        return _fRing(count, playerPos, playerPos);
      case _Formation.playerDoubleRing:
        return _fDoublering(count, playerPos, playerPos);
      case _Formation.playerEncircle:
        return _fTripleRing(count, playerPos, playerPos);
    }
  }

  // ── Formation implementations ──────────────────────────────────

  /// Ring: nemici equidistanti su una circonferenza
  List<Vector2> _fRing(int count, Vector2 center, Vector2 _) {
    final radius = 60.0 + count * 3.5;
    return List.generate(count, (i) {
      final angle = i * math.pi * 2 / count;
      return center +
          Vector2(math.cos(angle) * radius, math.sin(angle) * radius);
    });
  }

  /// Diamond: rombo (4 lati)
  /// FIX: distribuzione greedy su 4 lati — prima con count<8 i lati 3/4
  /// restavano vuoti → rombo diventava triangolo storto.
  List<Vector2> _fDiamond(int count, Vector2 center, Vector2 _) {
    final r = 70.0 + count * 2.0;
    final corners = [
      Vector2(0, -r),
      Vector2(r, 0),
      Vector2(0, r),
      Vector2(-r, 0),
    ];
    final positions = <Vector2>[];
    for (int s = 0; s < 4 && positions.length < count; s++) {
      final start = corners[s];
      final end = corners[(s + 1) % 4];
      final sideCount = ((count - positions.length) / (4 - s)).ceil();
      for (int p = 0; p < sideCount && positions.length < count; p++) {
        final t = sideCount <= 1 ? 0.0 : p / sideCount;
        positions.add(
          center +
              Vector2(
                start.x + (end.x - start.x) * t,
                start.y + (end.y - start.y) * t,
              ),
        );
      }
    }
    return positions;
  }

  /// Cross: più (+) con 4 braccia
  /// FIX: distribuisce count equamente tra 4 braccia — prima con count<8
  /// solo 1-2 braccia ricevevano nemici → la "+" diventava "/" o "L".
  List<Vector2> _fCross(int count, Vector2 center, Vector2 _) {
    // Direzioni: su, destra, giù, sinistra
    const dirs = [
      [0.0, -1.0],
      [1.0, 0.0],
      [0.0, 1.0],
      [-1.0, 0.0],
    ];
    final positions = <Vector2>[];
    for (int a = 0; a < 4 && positions.length < count; a++) {
      final dx = dirs[a][0];
      final dy = dirs[a][1];
      // Distribuzione greedy: arm a riceve `count/4` arrotondato con resto.
      final armCount = ((count - positions.length) / (4 - a)).ceil();
      for (int p = 0; p < armCount && positions.length < count; p++) {
        final dist = armCount <= 1 ? 65.0 : 20.0 + p * (110.0 / (armCount - 1));
        positions.add(center + Vector2(dx * dist, dy * dist));
      }
    }
    return positions;
  }

  /// Triangle: triangolo equilatero (3 lati)
  /// FIX: distribuzione greedy su 3 lati — prima con count<6 un lato restava vuoto.
  List<Vector2> _fTriangle(int count, Vector2 center, Vector2 _) {
    const r = 110.0;
    final vertices = List.generate(3, (k) {
      final angle = -math.pi / 2 + k * math.pi * 2 / 3;
      return Vector2(math.cos(angle) * r, math.sin(angle) * r);
    });
    final positions = <Vector2>[];
    for (int s = 0; s < 3 && positions.length < count; s++) {
      final start = vertices[s];
      final end = vertices[(s + 1) % 3];
      final sideCount = ((count - positions.length) / (3 - s)).ceil();
      for (int p = 0; p < sideCount && positions.length < count; p++) {
        final t = sideCount <= 1 ? 0.0 : p / sideCount;
        positions.add(
          center +
              Vector2(
                start.x + (end.x - start.x) * t,
                start.y + (end.y - start.y) * t,
              ),
        );
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
      final petalCenter =
          center +
          Vector2(
            math.cos(petalAngle) * petalDist,
            math.sin(petalAngle) * petalDist,
          );
      for (int e = 0; e < enemiesPerPetal && positions.length < count; e++) {
        final angle = e * math.pi * 2 / enemiesPerPetal;
        positions.add(
          petalCenter +
              Vector2(
                math.cos(angle) * petalRadius,
                math.sin(angle) * petalRadius,
              ),
        );
      }
    }
    return positions;
  }

  /// Star5: stella a 5 punte — punti distribuiti sui 10 segmenti.
  /// FIX: distribuzione greedy — prima con count<10 alcuni segmenti restavano vuoti.
  List<Vector2> _fStar5(int count, Vector2 center, Vector2 _) {
    const outerR = 120.0;
    const innerR = 50.0;
    // 10 vertici alternati: outer, inner, outer, inner...
    final starVerts = List.generate(10, (i) {
      final angle = i * math.pi / 5 - math.pi / 2;
      final r = (i % 2 == 0) ? outerR : innerR;
      return Vector2(math.cos(angle) * r, math.sin(angle) * r);
    });
    final positions = <Vector2>[];
    for (int s = 0; s < 10 && positions.length < count; s++) {
      final start = starVerts[s];
      final end = starVerts[(s + 1) % 10];
      final pts = ((count - positions.length) / (10 - s)).ceil();
      for (int p = 0; p < pts && positions.length < count; p++) {
        final t = pts <= 1 ? 0.0 : p / (pts - 1);
        positions.add(
          center +
              Vector2(
                start.x + (end.x - start.x) * t,
                start.y + (end.y - start.y) * t,
              ),
        );
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
        positions.add(
          center + Vector2(math.cos(angle) * r, math.sin(angle) * r),
        );
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
      positions.add(
        center +
            Vector2(math.cos(angle) * headRadius, math.sin(angle) * headRadius),
      );
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
        positions.add(
          center + Vector2(math.cos(angle) * r, math.sin(angle) * r),
        );
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
    positions.sort(
      (a, b) => (a - center).length2.compareTo((b - center).length2),
    );
    return positions.take(count).toList();
  }

  /// WShape: W doppia-V (5 waypoints)
  List<Vector2> _fWShape(int count, Vector2 center, Vector2 _) {
    final waypoints = [
      Vector2(-130, 80),
      Vector2(-65, -20),
      Vector2(0, 80),
      Vector2(65, -20),
      Vector2(130, 80),
    ];
    final segments = waypoints.length - 1; // 4 segmenti
    final pointsPerSeg = math.max(1, count ~/ segments);
    final positions = <Vector2>[];
    for (int s = 0; s < segments && positions.length < count; s++) {
      final start = waypoints[s];
      final end = waypoints[s + 1];
      final pts = (s == segments - 1)
          ? (count - positions.length)
          : pointsPerSeg;
      for (int p = 0; p < pts && positions.length < count; p++) {
        final t = pts <= 1 ? 0.0 : p / (pts - 1);
        positions.add(
          center +
              Vector2(
                start.x + (end.x - start.x) * t,
                start.y + (end.y - start.y) * t,
              ),
        );
      }
    }
    return positions;
  }

  /// Hexagon: esagono (6 lati)
  /// FIX: distribuzione greedy su 6 lati — prima con count<12 più lati restavano vuoti.
  List<Vector2> _fHexagon(int count, Vector2 center, Vector2 _) {
    final r = 80.0 + count * 2.0;
    final vertices = List.generate(6, (k) {
      final angle = k * math.pi / 3;
      return Vector2(math.cos(angle) * r, math.sin(angle) * r);
    });
    final positions = <Vector2>[];
    for (int s = 0; s < 6 && positions.length < count; s++) {
      final start = vertices[s];
      final end = vertices[(s + 1) % 6];
      final sideCount = ((count - positions.length) / (6 - s)).ceil();
      for (int p = 0; p < sideCount && positions.length < count; p++) {
        final t = sideCount <= 1 ? 0.0 : p / sideCount;
        positions.add(
          center +
              Vector2(
                start.x + (end.x - start.x) * t,
                start.y + (end.y - start.y) * t,
              ),
        );
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
      final n = ringCounts[ring];
      // Skip empty rings (e.g. count < 6 → ring0/ring1 may be 0).
      // math.max(1, n) was wrong: it forced enemies into inner rings for small
      // counts, causing wrong distribution (e.g. count=2 → 1 inner + 1 middle
      // instead of 2 in outer). The division `/ n` is never reached when n=0
      // because the inner loop runs 0 times.
      if (n == 0) continue;
      for (int i = 0; i < n && positions.length < count; i++) {
        final angle = i * math.pi * 2 / n;
        positions.add(
          center +
              Vector2(
                math.cos(angle) * radii[ring],
                math.sin(angle) * radii[ring],
              ),
        );
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
  /// FIX: distribuzione greedy su 4 lati — prima con count<8 lati vuoti.
  List<Vector2> _fSquareRing(int count, Vector2 center, Vector2 _) {
    final side = 160.0 + count * 2.0;
    final half = side / 2;
    final corners = [
      Vector2(-half, -half),
      Vector2(half, -half),
      Vector2(half, half),
      Vector2(-half, half),
    ];
    final positions = <Vector2>[];
    for (int s = 0; s < 4 && positions.length < count; s++) {
      final start = corners[s];
      final end = corners[(s + 1) % 4];
      final sideCount = ((count - positions.length) / (4 - s)).ceil();
      for (int p = 0; p < sideCount && positions.length < count; p++) {
        final t = sideCount <= 1 ? 0.0 : p / sideCount;
        positions.add(
          center +
              Vector2(
                start.x + (end.x - start.x) * t,
                start.y + (end.y - start.y) * t,
              ),
        );
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
        positions.add(
          center + Vector2(math.cos(angle) * dist, math.sin(angle) * dist),
        );
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
    final lines = [
      [tip, wingL],
      [tip, wingR],
      [wingL, wingR],
    ];
    final ppl = math.max(1, count ~/ 3);
    final positions = <Vector2>[];
    for (int l = 0; l < 3 && positions.length < count; l++) {
      final start = lines[l][0];
      final end = lines[l][1];
      final pts = (l == 2) ? (count - positions.length) : ppl;
      for (int p = 0; p < pts && positions.length < count; p++) {
        final t = pts <= 1 ? 0.0 : p / (pts - 1);
        positions.add(
          Vector2(
            start.x + (end.x - start.x) * t,
            start.y + (end.y - start.y) * t,
          ),
        );
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
      positions.add(
        center + Vector2(math.cos(angle) * innerR, math.sin(angle) * innerR),
      );
    }
    for (int i = 0; i < outerCount && positions.length < count; i++) {
      final angle = i * math.pi * 2 / math.max(1, outerCount);
      positions.add(
        center + Vector2(math.cos(angle) * outerR, math.sin(angle) * outerR),
      );
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
      positions.add(
        center +
            Vector2((leftEnd.x - center.x) * t, (leftEnd.y - center.y) * t),
      );
    }
    // Braccio destro: center → rightEnd
    final rem = count - half;
    for (int p = 0; p < rem && positions.length < count; p++) {
      final t = rem <= 1 ? 0.0 : p / (rem - 1);
      positions.add(
        center +
            Vector2((rightEnd.x - center.x) * t, (rightEnd.y - center.y) * t),
      );
    }
    return positions;
  }

  /// XShape: due diagonali incrociate (4 braccia a 45°)
  /// FIX: distribuzione greedy su 4 braccia — prima con count<8 alcune braccia vuote.
  List<Vector2> _fXShape(int count, Vector2 center, Vector2 _) {
    const armLen = 130.0;
    // Angoli 45°, 135°, 225°, 315°
    final angles = [
      math.pi / 4,
      3 * math.pi / 4,
      5 * math.pi / 4,
      7 * math.pi / 4,
    ];
    final positions = <Vector2>[];
    for (int a = 0; a < 4 && positions.length < count; a++) {
      final armCount = ((count - positions.length) / (4 - a)).ceil();
      for (int p = 0; p < armCount && positions.length < count; p++) {
        final dist = armCount <= 1
            ? 75.0
            : 20.0 + p * (armLen - 20.0) / (armCount - 1);
        positions.add(
          center +
              Vector2(math.cos(angles[a]) * dist, math.sin(angles[a]) * dist),
        );
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
      return center +
          Vector2(math.cos(angle) * radius, math.sin(angle) * radius);
    });
  }

  /// BorderLine: schiera lungo un intero bordo dell'arena.
  /// Se `side` è null ne pesca uno a caso. I nemici sono equispaziati con un
  /// padding laterale per evitare che il primo/ultimo tocchino subito l'angolo.
  /// Usa effectiveArena per rispettare `tiny_arena` modifier.
  List<Vector2> _fBorderLine(int count, {_BorderSide? side}) {
    final chosen = side ?? _BorderSide.values[_formRng.nextInt(4)];
    final eW = game.effectiveArenaWidth;
    final eH = game.effectiveArenaHeight;
    const edgePad = 40.0; // distanza dal bordo perpendicolare (dentro arena)
    // sidePad: distanza dagli angoli. Modalità classic/zen/etc lasciano
    // 140px buffer per dare spazio al player.
    // Waves mode (richiesta utente "spawnano lungo TUTTO il bordo, anche
    // angoli"): sidePad ridotto a 20 → triangoli partono da quasi-angolo.
    final double sidePad = _mode == GameMode.waves
        ? 20.0
        : math.min(140.0, math.min(eW, eH) * 0.25);

    final positions = <Vector2>[];
    final n = math.max(1, count);

    switch (chosen) {
      case _BorderSide.top:
      case _BorderSide.bottom:
        final y = chosen == _BorderSide.top ? edgePad : eH - edgePad;
        final startX = sidePad;
        final endX = eW - sidePad;
        for (int i = 0; i < count; i++) {
          final t = n == 1 ? 0.5 : i / (n - 1);
          positions.add(Vector2(startX + (endX - startX) * t, y));
        }
      case _BorderSide.left:
      case _BorderSide.right:
        final x = chosen == _BorderSide.left ? edgePad : eW - edgePad;
        final startY = sidePad;
        final endY = eH - sidePad;
        for (int i = 0; i < count; i++) {
          final t = n == 1 ? 0.5 : i / (n - 1);
          positions.add(Vector2(x, startY + (endY - startY) * t));
        }
    }
    return positions;
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
    spawns.add(
      WaveSpawn(EnemyType.drone, (40 + wave * 4).clamp(40, 100), delay: 0.3),
    );
    spawns.add(
      WaveSpawn(EnemyType.drone, (24 + wave * 2).clamp(24, 60), delay: 0.5),
    );
    spawns.add(
      WaveSpawn(EnemyType.mine, (6 + wave * 2 ~/ 3).clamp(6, 24), delay: 1),
    );

    // ── PERICOLOSI (~30%) — raddoppiati ──
    spawns.add(
      WaveSpawn(EnemyType.kamikaze, (4 + wave * 2 ~/ 3).clamp(4, 20), delay: 2),
    );
    spawns.add(
      WaveSpawn(EnemyType.weaver, (2 + wave ~/ 2).clamp(2, 16), delay: 2.5),
    );
    spawns.add(
      WaveSpawn(EnemyType.splitter, (2 + wave * 2 ~/ 5).clamp(2, 12), delay: 3),
    );
    spawns.add(
      WaveSpawn(EnemyType.shieldEnemy, (2 + wave ~/ 3).clamp(2, 10), delay: 3),
    );
    spawns.add(WaveSpawn(EnemyType.leech, (wave ~/ 3).clamp(2, 10), delay: 3));
    spawns.add(
      WaveSpawn(EnemyType.pulsar, (wave ~/ 4).clamp(2, 8), delay: 3.5),
    );
    spawns.add(WaveSpawn(EnemyType.glitch, (wave ~/ 5).clamp(2, 6), delay: 4));
    spawns.add(WaveSpawn(EnemyType.mirror, (wave ~/ 5).clamp(2, 6), delay: 4));
    spawns.add(WaveSpawn(EnemyType.vortex, (wave ~/ 6).clamp(2, 6), delay: 5));
    spawns.add(WaveSpawn(EnemyType.phantom, (wave ~/ 6).clamp(2, 6), delay: 5));
    spawns.add(WaveSpawn(EnemyType.tesla, (wave ~/ 6).clamp(2, 6), delay: 5));

    // Rari/speciali — raddoppiati
    if (wave % 3 == 0) {
      spawns.add(WaveSpawn(EnemyType.titan, (wave ~/ 8).clamp(1, 4), delay: 5));
    }
    if (wave % 4 == 0) {
      spawns.add(const WaveSpawn(EnemyType.blackHole, 2, delay: 6));
    }
    if (wave % 3 == 0) {
      spawns.add(
        WaveSpawn(EnemyType.healer, (wave ~/ 10).clamp(1, 4), delay: 5),
      );
    }
    if (wave % 4 == 0) {
      spawns.add(
        WaveSpawn(EnemyType.laserTurret, (wave ~/ 12).clamp(1, 4), delay: 6),
      );
    }
    if (wave % 5 == 0) {
      spawns.add(const WaveSpawn(EnemyType.gravityWell, 2, delay: 7));
    }
    if (wave % 3 == 0) {
      spawns.add(
        WaveSpawn(EnemyType.timeBomb, (wave ~/ 10).clamp(1, 4), delay: 5),
      );
    }
    if (wave % 2 == 0) {
      spawns.add(WaveSpawn(EnemyType.decoy, (wave ~/ 5).clamp(2, 6), delay: 4));
    }
    if (wave > 110) {
      spawns.add(
        WaveSpawn(EnemyType.orbiter, (wave ~/ 8).clamp(2, 6), delay: 5),
      );
      spawns.add(
        WaveSpawn(EnemyType.siren, (wave ~/ 10).clamp(2, 4), delay: 6),
      );
      spawns.add(const WaveSpawn(EnemyType.necro, 2, delay: 7));
    }

    return WaveConfig(waveNumber: wave, spawns: spawns);
  }
}

import 'dart:async' show unawaited;
import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show KeyEventResult;
import '../data/constants.dart';
import '../data/difficulty.dart';
import '../data/modifiers.dart';
import '../data/save_data.dart';
import '../data/wave_configs.dart';
import 'entities/player.dart';
import 'entities/enemies/enemy_base.dart';
import 'entities/enemies/drone_enemy.dart';
import 'entities/enemies/snake_enemy.dart';
import 'entities/enemies/mine_enemy.dart';
import 'entities/enemies/spawner_enemy.dart';
import 'entities/enemies/weaver_enemy.dart';
import 'entities/enemies/splitter_enemy.dart';
import 'entities/enemies/shield_enemy.dart';
import 'entities/enemies/black_hole_enemy.dart';
import 'entities/enemies/kamikaze_enemy.dart';
import 'entities/enemies/pulsar_enemy.dart';
import 'entities/enemies/mirror_enemy.dart';
import 'entities/enemies/phantom_enemy.dart';
import 'entities/enemies/vortex_enemy.dart';
import 'entities/enemies/leech_enemy.dart';
import 'entities/enemies/titan_enemy.dart';
import 'entities/enemies/glitch_enemy.dart';
import 'entities/enemies/healer_enemy.dart';
import 'entities/enemies/orbiter_enemy.dart';
import 'entities/enemies/siren_enemy.dart';
import 'entities/enemies/necro_enemy.dart';
import 'entities/enemies/tesla_enemy.dart';
import 'entities/enemies/gravity_well_enemy.dart';
import 'entities/enemies/swarm_drone_enemy.dart';
import 'entities/enemies/laser_turret_enemy.dart';
import 'entities/enemies/time_bomb_enemy.dart';
import 'entities/enemies/decoy_enemy.dart';
import 'entities/enemies/gate_enemy.dart';
import 'entities/enemies/proton_enemy.dart';
import 'entities/enemies/mutator_enemy.dart';
import 'entities/bosses/boss_base.dart';
import 'entities/bosses/the_grid_boss.dart';
import 'entities/bosses/hydra_boss.dart';
import 'entities/bosses/singularity_boss.dart';
import 'entities/bosses/swarm_mother_boss.dart';
import 'entities/bosses/the_architect_boss.dart';
import 'entities/bosses/chrono_wraith_boss.dart';
import 'entities/bosses/nexus_prime_boss.dart';
import 'entities/bosses/void_reaper_boss.dart';
import 'entities/bosses/tesla_lord_boss.dart';
import 'entities/bosses/phantom_king_boss.dart';
import 'entities/bosses/omega_core_boss.dart';
import 'entities/bosses/mirror_master_boss.dart';
import 'entities/bosses/swarm_queen_boss.dart';
import 'entities/bosses/graviton_boss.dart';
import 'entities/bosses/inferno_boss.dart';
import 'entities/bosses/crimson_crown_boss.dart';
import 'entities/bosses/prism_hunter_boss.dart';
import 'entities/bosses/void_kraken_boss.dart';
import 'entities/bosses/astral_sentinel_boss.dart';
import 'entities/bosses/eternity_engine_boss.dart';
import 'entities/geom.dart';
import 'entities/pets/pet_base.dart';
import 'entities/projectiles.dart';
import '../data/pet_types.dart';
import 'effects/grid_distortion.dart';
import 'effects/screen_shake.dart';
import 'effects/explosion.dart';
import 'effects/space_background.dart';
import 'effects/tunnel_renderer.dart';
import 'systems/wave_system.dart';
import 'systems/score_system.dart';
import 'systems/powerup_system.dart';
import 'systems/audio_system.dart';
import 'systems/music_manager.dart';

enum GameState { playing, paused, gameOver, bossIntro, waveIntro }

class _DelayedExplosion {
  double timeLeft;
  final Color color;
  final double radius;
  final int particleCount;

  _DelayedExplosion({
    required this.timeLeft,
    required this.color,
    required this.radius,
    required this.particleCount,
  });
}

class GeometryFightGame extends FlameGame
    with HasCollisionDetection, KeyboardEvents {
  late Player player;
  late SpaceBackground spaceBackground;
  late GridDistortion grid;
  late ScreenShakeEffect screenShake;
  late WaveSystem waveSystem;
  ScoreSystem scoreSystem = ScoreSystem();
  // waveSystem inizializzato late perché necessita di `this` (game reference)
  late PowerUpSystem powerUpSystem;

  GameState gameState = GameState.playing;
  double timeScale = 1.0;
  double _slowMoTimer = 0;
  double get slowMoTimer => _slowMoTimer;

  // Modificatori attivi
  List<String> activeModifiers = [];

  // Achievement tracking per sessione
  int sessionBombs = 0;
  int sessionBossKills = 0;
  int sessionPowerUps = 0;
  int consecutivePerfectWaves = 0;
  int maxMultiplierReached = 0;

  double _chaosTimer = 10.0;

  // Bomb explosion timer (sostituisce Future.delayed per rispettare pause/dispose)
  List<_DelayedExplosion>? _bombExplosionTimers;
  Vector2? _bombExplosionPos;

  // Death explosion timer (mega shockwave quando il player muore)
  List<_DelayedExplosion>? _deathExplosionTimers;
  Vector2? _deathExplosionPos;

  // Shared Random instance (evita creazione ripetuta)
  final math.Random _random = math.Random();

  // Grid distortion cap: massimo 4 distorsioni per frame (evita lag su kill multipli)
  int _gridDistortionCount = 0;

  // Difficoltà e modalità di gioco
  final Difficulty difficulty;
  final GameMode gameMode;
  late DifficultyConfig diffConfig;

  SaveData saveData = SaveData();

  /// Pet companion attivo (Geometry Wars 3 style drone). null se loadout
  /// = 'none'. Settato in `onLoad` post-spawn player, distrutto al restart.
  PetBase? activePet;

  GeometryFightGame({
    this.difficulty = Difficulty.normal,
    this.gameMode = GameMode.classic,
  }) {
    diffConfig = difficultyConfigs[difficulty]!;
    scoreSystem.geomValueMultiplier = diffConfig.geomValueMultiplier;
    scoreSystem.scoreMultiplier = diffConfig.scoreMultiplier;
    waveSystem = WaveSystem(this);
  }

  // Input state
  Vector2 moveInput = Vector2.zero();
  Vector2 aimInput = Vector2.zero();
  bool bombPressed = false;
  bool isShooting = false;

  // Keyboard state
  final Set<LogicalKeyboardKey> _pressedKeys = {};

  // Game stats for current session
  int sessionGeoms = 0;
  int sessionKills = 0;
  // Contatore morti — usato in zen mode (player immortale).
  int sessionDeaths = 0;
  double _sessionTimeSec = 0;

  /// Helper: true se zen mode (player immortale, deaths count, no game over).
  bool get isZenMode => gameMode == GameMode.zenMode;

  // Perfect Wave tracking
  bool _hitThisWave = false;
  bool showPerfectWave = false;
  double _perfectWaveTimer = 0;

  // Screen flash rosso quando colpito
  double hitFlashTimer = 0;

  // Tunnel mode: arena dinamica con scrolling automatico.
  // Altezza ridotta del 30% rispetto al valore originale (600 → 420) per
  // aumentare la pressione sul player — meno spazio per manovrare.
  double tunnelHeight = 420; // Altezza corridoio (si allarga per boss)
  double tunnelTargetHeight = 420;
  bool get isTunnelMode => gameMode == GameMode.tunnel;

  /// Pacifist (GW2 Pacifism mode): player non spara, 1 vita, 0 bombe.
  /// Solo grunt + gate. Combo gate per scoring.
  bool get isPacifistMode => gameMode == GameMode.pacifist;

  /// Combo gate corrente (Pacifism scoring). Si incrementa ad ogni
  /// gate triggerato entro `_gateComboWindow` secondi dal precedente.
  /// Reset a 0 quando il timer scade.
  int gateCombo = 0;
  double gateComboTimer = 0;
  static const double _gateComboWindow = 4.0;
  /// AoE multiplier scaling con combo (gate_enemy.dart legge questo per
  /// allargare il raggio di kill). 1.0 base, +0.15 per combo, max 2.5x.
  double get gateComboAoeMultiplier =>
      (1.0 + gateCombo * 0.15).clamp(1.0, 2.5);
  /// Score multiplier scaling con combo. 1× per primo gate, fino a 10×.
  int get gateComboScoreMultiplier => gateCombo.clamp(1, 10);

  /// Riferimento al TunnelRenderer attivo (null se non tunnel mode).
  /// Esposto per permettere a proiettili/mob di fare collision-check con
  /// i muri rossi (richiesta utente: impenetrabili da tutti gli entità).
  TunnelRenderer? tunnelRenderer;

  /// True se la posizione è dentro un ostacolo tunnel rosso.
  bool hitsTunnelObstacle(Vector2 pos) {
    return tunnelRenderer?.hitsObstacle(pos) ?? false;
  }
  double tunnelScrollSpeed = 100; // Velocità scroll camera (px/s, cresce nel tempo)
  double _tunnelCameraX = 0; // Posizione X della camera (avanza indipendentemente dal player)
  // Dopo morte boss: 5s di grace period con tunnel pieno, poi 5s di shrink
  // graduale per un totale di 10s. `_tunnelBossShrinkDelay` gestisce il
  // grace; `_tunnelShrinkProgress` gestisce il lerp progressivo (0→1).
  double _tunnelBossShrinkDelay = 0;
  double _tunnelShrinkProgress = 1.0; // 1.0 = pieno, 0.0 = ristretto
  double _tunnelShrinkStartHeight = 420; // altezza all'inizio dello shrink

  /// Contatore boss uccisi in modalità tunnel: usato per scalare l'altezza
  /// degli ostacoli (muri rossi) +3% per ogni boss ucciso.
  int tunnelBossesKilled = 0;

  /// Scala altezza ostacoli (muri rossi) nel tunnel.
  /// Base: 20% dello span tunnel. +3% per ogni boss ucciso.
  double get tunnelObstacleScale => 0.20 + tunnelBossesKilled * 0.03;

  // Callbacks for UI
  void Function()? onGameOver;
  void Function()? onPause;
  void Function(int wave)? onWaveStart;
  void Function(String bossName)? onBossStart;

  @override
  Color backgroundColor() => const Color(0xFF000000);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Reset stato statico HomingMissile (volley counters, activeCount).
    // Senza questo, se il player esce mid-game (quit da pausa, app kill
    // durante volo missili), il counter resta sporco e il nuovo game cappa
    // i missili a valori random → "spara pochissimi missili".
    HomingMissile.resetStaticState();
    // Reset altri stati statici per sicurezza (idempotenti).
    SwarmDroneEnemy.resetGlobalEnrage();
    LeechEnemy.resetAttachedCount();

    // Load save data
    saveData = SaveManager.load();

    // Camera setup - centrata sulla navicella fin dall'inizio
    camera.viewfinder.anchor = Anchor.center;
    // Posiziona la camera subito al centro dell'arena (dove spawna il player)
    camera.viewfinder.position = Vector2(arenaWidth / 2, arenaHeight / 2);

    // Add space background (layer più basso)
    spaceBackground = SpaceBackground();
    world.add(spaceBackground);

    // Add grid (sopra lo sfondo) - NO in tunnel mode
    grid = GridDistortion();
    if (!isTunnelMode) {
      world.add(grid);
    }

    // Add tunnel renderer per modalità Tunnel
    if (isTunnelMode) {
      tunnelRenderer = TunnelRenderer();
      world.add(tunnelRenderer!);
    } else {
      tunnelRenderer = null;
      // Bordo arena bianco fluo 4x spesso (solo modalità non-tunnel)
      world.add(ArenaBorder());
    }

    // Add player (applica difficoltà alle vite/bombe iniziali)
    player = Player();
    player.position = Vector2(arenaWidth / 2, arenaHeight / 2);
    player.lives = diffConfig.startingLives + (saveData.startingLives - 3);
    player.bombs = diffConfig.startingBombs;
    player.setWeaponFromId(saveData.startingWeapon);
    world.add(player);

    // Pet companion (Geometry Wars 3 style drone). Solo se loadout != 'none'.
    // Pacifist mode: nessun pet (pet attaccano nemici → rompe regola Pacifism).
    if (!isPacifistMode) {
      final petType = petTypeById(saveData.activePet);
      activePet = createPet(petType);
      if (activePet != null) {
        activePet!.position = player.position + Vector2(40, 0);
        world.add(activePet!);
      }
    } else {
      activePet = null;
    }

    // Applica modificatori
    _applyModifiers();

    // Screen shake
    screenShake = ScreenShakeEffect();
    camera.viewfinder.add(screenShake);

    // Systems — scoreSystem e waveSystem già inizializzati nel costruttore
    // Li ri-creiamo qui solo per powerUpSystem che necessita del game caricato
    powerUpSystem = PowerUpSystem(this);

    // Start first wave
    waveSystem.startWave(1);
  }

  @override
  void update(double dt) {
    if (gameState == GameState.paused || gameState == GameState.gameOver) {
      // Processa lifecycle events (mount/unmount) anche in pausa/game over.
      // Senza questo, componenti in _addLater/_removeLater restano zombie
      // e si accumulano ad ogni restart causando lag progressivo.
      super.update(0);
      return;
    }

    // Reset grid distortion cap ogni frame
    _gridDistortionCount = 0;

    // Reset budget globale split per frame: max N splitter si dividono
    // simultaneamente → cascata controllata quando laser/AoE ne investe molti.
    SplitterEnemy.resetFrameBudget();

    // Apply time scale
    final scaledDt = dt * timeScale;

    // Slow-mo timer (bomba/morte — brevi burst)
    if (_slowMoTimer > 0) {
      _slowMoTimer -= dt;
      if (_slowMoTimer <= 0) {
        // Non resettare timeScale se il player ha ancora il power-up TimeSlow attivo
        if (player.timeSlowTimer <= 0) {
          timeScale = 1.0;
        } else {
          timeScale = 0.4; // Ripristina la scala del power-up TimeSlow
        }
      }
    }

    // Pacifism gate combo: timer decay → reset combo allo scadere.
    // Usa dt reale (non scaledDt) perché la combo è esperienza giocatore.
    if (gateComboTimer > 0) {
      gateComboTimer -= dt;
      if (gateComboTimer <= 0) {
        gateCombo = 0;
        gateComboTimer = 0;
      }
    }

    // Update keyboard input
    _updateKeyboardInput();

    // Update global swarm enrage timer (performance: evita iterazione O(n²))
    SwarmDroneEnemy.updateGlobalEnrage(scaledDt);

    // Cache conteggi nemici/boss (evita O(n) per ogni chiamata)
    _updateEntityCounts();

    // NOTA: spatial hash rimosso — Flame usa HasCollisionDetection built-in
    // che è più efficiente. Il spatial hash iterava TUTTI i children ogni frame
    // causando lag con molti nemici.

    // Update systems
    if (isTunnelMode) {
      waveSystem.updateTunnel(scaledDt); // Tunnel: spawn continuo
    } else {
      waveSystem.update(scaledDt);
    }
    scoreSystem.update(scaledDt);
    // Traccia tempo di gioco sessione (usa dt reale, non scalato)
    _sessionTimeSec += dt;
    // Vite extra per soglie punteggio (10K, 100K, 1M, 10M, 100M, 1B).
    // extraLivesThisFrame conta TUTTE le soglie attraversate in un singolo
    // tick (es. boss kill che salta 9K → 200K = 2 vite, non 1).
    // Pacifist: NO extra lives da score (regola GW2 = 1 vita fissa).
    final livesGained = scoreSystem.extraLivesThisFrame;
    if (livesGained > 0 && !isPacifistMode) {
      player.lives += livesGained;
      triggerScreenShake(3, 0.1);
    }
    powerUpSystem.update(scaledDt);

    // Chaos modifier: power-up random ogni 10 secondi
    if (hasModifier('chaos')) {
      _chaosTimer -= scaledDt;
      if (_chaosTimer <= 0) {
        _chaosTimer = 10.0;
        powerUpSystem.spawnRandomPowerUp(player.position + Vector2(
          (_random.nextDouble() - 0.5) * 200,
          (_random.nextDouble() - 0.5) * 200,
        ));
      }
    }

    // Bomb explosion delayed waves (timer-based, rispetta pause)
    if (_bombExplosionTimers != null && _bombExplosionPos != null) {
      for (int i = _bombExplosionTimers!.length - 1; i >= 0; i--) {
        final explosion = _bombExplosionTimers![i];
        explosion.timeLeft -= scaledDt;
        if (explosion.timeLeft <= 0) {
          spawnExplosion(
            _bombExplosionPos!,
            explosion.color,
            radius: explosion.radius,
            particleCount: explosion.particleCount,
          );
          _bombExplosionTimers!.removeAt(i);
        }
      }
      if (_bombExplosionTimers!.isEmpty) {
        _bombExplosionTimers = null;
        _bombExplosionPos = null;
      }
    }

    // Death explosion delayed waves (timer-based, rispetta pause)
    if (_deathExplosionTimers != null && _deathExplosionPos != null) {
      for (int i = _deathExplosionTimers!.length - 1; i >= 0; i--) {
        final explosion = _deathExplosionTimers![i];
        explosion.timeLeft -= scaledDt;
        if (explosion.timeLeft <= 0) {
          spawnExplosion(
            _deathExplosionPos!,
            explosion.color,
            radius: explosion.radius,
            particleCount: explosion.particleCount,
          );
          _deathExplosionTimers!.removeAt(i);
        }
      }
      if (_deathExplosionTimers!.isEmpty) {
        _deathExplosionTimers = null;
        _deathExplosionPos = null;
      }
    }

    // Timer flash rosso
    if (hitFlashTimer > 0) hitFlashTimer -= dt;
    // Timer perfect wave
    if (_perfectWaveTimer > 0) {
      _perfectWaveTimer -= dt;
      if (_perfectWaveTimer <= 0) showPerfectWave = false;
    }

    // Time Attack: countdown timer
    if (isTimeAttackMode && gameState == GameState.playing) {
      timeAttackTimer -= dt;
      if (timeAttackTimer <= 0) {
        timeAttackTimer = 0;
        // Tempo scaduto = game over
        gameState = GameState.gameOver;
        saveSessionData();
        pauseEngine();
        onGameOver?.call();
        return;
      }
    }

    // Tunnel mode: aggiorna altezza corridoio.
    // Sequenza post-boss: 5s grace (tunnel pieno) → 5s shrink graduale.
    //   Boss alive          → target 1800, lerp rapido
    //   Boss morto + grace  → target 1800, lerp rapido (resta allargato)
    //   Boss morto + shrink → interpola linearmente da 1800 a 420 su 5s
    if (isTunnelMode) {
      if (_tunnelBossShrinkDelay > 0) _tunnelBossShrinkDelay -= dt;
      final tunnelExpanded = bossCount > 0 || _tunnelBossShrinkDelay > 0;
      if (tunnelExpanded) {
        // Pieno: target 1800, lerp rapido. Reset shrink state per prossimo ciclo.
        tunnelTargetHeight = 1800;
        tunnelHeight += (tunnelTargetHeight - tunnelHeight) * 2.0 * dt;
        _tunnelShrinkProgress = 1.0;
        _tunnelShrinkStartHeight = tunnelHeight;
      } else if (_tunnelShrinkProgress > 0.0) {
        // Shrink graduale su 5s (1.0 → 0.0 in 5s = 0.2/s).
        _tunnelShrinkProgress -= dt / 5.0;
        if (_tunnelShrinkProgress < 0.0) _tunnelShrinkProgress = 0.0;
        // Linear interpolation tra altezza iniziale shrink e 420.
        tunnelHeight = 420 + (_tunnelShrinkStartHeight - 420) * _tunnelShrinkProgress;
        tunnelTargetHeight = tunnelHeight;
      } else {
        // Stato normale post-shrink: target fisso 420.
        tunnelTargetHeight = 420;
        tunnelHeight += (tunnelTargetHeight - tunnelHeight) * 2.0 * dt;
      }

      // Camera avanza automaticamente verso destra (side-scroller)
      // Accelera lentamente nel tempo: da 100 a ~200 px/s in ~5 minuti
      // Durante boss fight: rallenta a 25 px/s per dare spazio al combattimento
      final baseSpeed = 100.0 + (_tunnelCameraX * 0.005).clamp(0.0, 120.0);
      final targetSpeed = bossCount > 0 ? 25.0 : baseSpeed;
      // Lerp graduale verso la velocità target (non scatto improvviso)
      tunnelScrollSpeed += (targetSpeed - tunnelScrollSpeed) * 3.0 * dt;
      _tunnelCameraX += tunnelScrollSpeed * dt;

      // Camera X: scrolling costante. Camera Y: segue player per comfort
      final currentPos = camera.viewfinder.position;
      final targetY = player.position.y;
      // Frame-rate independent lerp: stesso feeling a qualunque fps
      final lerpFactorTunnel = 1.0 - math.pow(1.0 - cameraSmoothing, scaledDt * 60).toDouble();
      camera.viewfinder.position = Vector2(
        _tunnelCameraX + arenaWidth / 2, // Offset iniziale + scroll
        currentPos.y + (targetY - currentPos.y) * lerpFactorTunnel,
      );
    } else {
      // Modalità normali: camera segue player
      final targetPos = player.position.clone();
      final currentPos = camera.viewfinder.position;
      // Frame-rate independent lerp: stesso feeling a qualunque fps
      final lerpFactor = 1.0 - math.pow(1.0 - cameraSmoothing, scaledDt * 60).toDouble();
      camera.viewfinder.position =
          currentPos + (targetPos - currentPos) * lerpFactor;
    }

    super.update(scaledDt);
  }

  // Flag per distinguere input touch da tastiera (pubblici per accesso da game_screen)
  bool usingTouchMove = false;
  bool usingTouchAim = false;

  void _updateKeyboardInput() {
    // NON sovrascrivere l'input touch del joystick!
    // Se il touch joystick è attivo, non toccare moveInput/aimInput
    if (usingTouchMove && usingTouchAim) return;

    // Calcola input da tastiera separatamente
    final keyboardMove = Vector2.zero();
    if (_pressedKeys.contains(LogicalKeyboardKey.keyW) ||
        _pressedKeys.contains(LogicalKeyboardKey.arrowUp)) {
      keyboardMove.y -= 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyS) ||
        _pressedKeys.contains(LogicalKeyboardKey.arrowDown)) {
      keyboardMove.y += 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyA) ||
        _pressedKeys.contains(LogicalKeyboardKey.arrowLeft)) {
      keyboardMove.x -= 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyD) ||
        _pressedKeys.contains(LogicalKeyboardKey.arrowRight)) {
      keyboardMove.x += 1;
    }

    // Mira tastiera: SOLO frecce (non movimento), per evitare auto-fire mentre ci si muove.
    final keyboardAim = Vector2.zero();
    if (_pressedKeys.contains(LogicalKeyboardKey.arrowUp)) {
      keyboardAim.y -= 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.arrowDown)) {
      keyboardAim.y += 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.arrowLeft)) {
      keyboardAim.x -= 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.arrowRight)) {
      keyboardAim.x += 1;
    }

    // Applica input movimento da tastiera solo se non c'è touch attivo
    if (!usingTouchMove) {
      if (keyboardMove.length > 0) {
        keyboardMove.normalize();
      }
      moveInput = keyboardMove;
    }

    // Aim da tastiera con frecce (solo se touch aim non attivo)
    if (!usingTouchAim) {
      if (keyboardAim.length > 0) {
        keyboardAim.normalize();
        aimInput = keyboardAim;
      } else {
        aimInput = Vector2.zero();
      }
    }
  }

  @override
  KeyEventResult onKeyEvent(
      KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    _pressedKeys.clear();
    _pressedKeys.addAll(keysPressed);

    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.space) {
        bombPressed = true;
      }
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        togglePause();
      }
    }

    // Auto-shoot when aim keys are pressed
    isShooting = _pressedKeys.contains(LogicalKeyboardKey.arrowUp) ||
        _pressedKeys.contains(LogicalKeyboardKey.arrowDown) ||
        _pressedKeys.contains(LogicalKeyboardKey.arrowLeft) ||
        _pressedKeys.contains(LogicalKeyboardKey.arrowRight);

    return KeyEventResult.handled;
  }

  void activateSlowMo(double duration, double scale) {
    timeScale = scale;
    _slowMoTimer = duration;
  }

  void triggerScreenShake([double intensity = 4, double duration = 0.2]) {
    screenShake.shake(intensity, duration);
  }

  // Limite massimo nemici attivi — ottimizzato per 150+ con blur rimossi dai mob di massa
  static const int _maxActiveEnemies = 150;

  EnemyBase? spawnEnemy(EnemyType type, [Vector2? position]) {
    // Limita nemici attivi per evitare scatti di performance
    if (enemyCount >= _maxActiveEnemies) return null;

    final pos = position ?? _randomSpawnPosition();
    EnemyBase enemy;

    switch (type) {
      case EnemyType.drone:
        enemy = DroneEnemy();
      case EnemyType.snake:
        enemy = SnakeEnemy();
      case EnemyType.mine:
        enemy = MineEnemy();
      case EnemyType.spawner:
        enemy = SpawnerEnemy();
      case EnemyType.weaver:
        enemy = WeaverEnemy();
      case EnemyType.splitter:
        enemy = SplitterEnemy();
      case EnemyType.shieldEnemy:
        enemy = ShieldEnemy();
      case EnemyType.blackHole:
        enemy = BlackHoleEnemy();
      case EnemyType.kamikaze:
        enemy = KamikazeEnemy();
      case EnemyType.pulsar:
        enemy = PulsarEnemy();
      case EnemyType.mirror:
        enemy = MirrorEnemy();
      case EnemyType.phantom:
        enemy = PhantomEnemy();
      case EnemyType.vortex:
        enemy = VortexEnemy();
      case EnemyType.leech:
        enemy = LeechEnemy();
      case EnemyType.titan:
        enemy = TitanEnemy();
      case EnemyType.glitch:
        enemy = GlitchEnemy();
      case EnemyType.healer:
        enemy = HealerEnemy();
      case EnemyType.orbiter:
        enemy = OrbiterEnemy();
      case EnemyType.siren:
        enemy = SirenEnemy();
      case EnemyType.necro:
        enemy = NecroEnemy();
      case EnemyType.tesla:
        enemy = TeslaEnemy();
      case EnemyType.gravityWell:
        enemy = GravityWellEnemy();
      case EnemyType.swarmDrone:
        enemy = SwarmDroneEnemy();
      case EnemyType.laserTurret:
        enemy = LaserTurretEnemy();
      case EnemyType.timeBomb:
        enemy = TimeBombEnemy();
      case EnemyType.decoy:
        enemy = DecoyEnemy();
      case EnemyType.proton:
        enemy = ProtonEnemy();
      case EnemyType.mutator:
        enemy = MutatorEnemy();
      case EnemyType.gate:
        // Gate non è un EnemyBase — spawn diretto come PositionComponent
        final gate = GateEnemy();
        gate.position = pos;
        world.add(gate);
        return null;
    }

    // Applica moltiplicatori di difficoltà a HP e velocità
    // Tutti i mob sono il 20% più lenti di base
    var hpMul = diffConfig.enemyHpMultiplier;
    var speedMul = diffConfig.enemySpeedMultiplier * 0.8;
    var geomMul = 1.0;

    // ── WAVE MODIFIER (solo classic, applicato sopra le difficoltà) ──────
    // Dà alle wave classic una "regola speciale" senza riscrivere il
    // balancing per-difficoltà. Stack-multiplied: difficoltà base + modifier.
    final waveMod = waveSystem.activeModifier;
    switch (waveMod) {
      case WaveModifier.frenzy:
        speedMul *= 1.35;
      case WaveModifier.tank:
        hpMul *= 1.6;
      case WaveModifier.glass:
        hpMul *= 0.4; // score×1.6 applicato in onEnemyKilled
      case WaveModifier.iron:
        hpMul *= 1.3;
        speedMul *= 0.75;
      case WaveModifier.loot:
        geomMul = 2.0;
      case WaveModifier.none:
      case WaveModifier.blitz:    // count handled in WaveSystem._scaledSpawnCount
      case WaveModifier.haste:    // delay handled in WaveSystem._delayBeforeNextGroup
      case WaveModifier.magnetic: // magnet radius handled in geom.dart
        break;
    }

    enemy.hp = enemy.hp * hpMul;
    enemy.maxHp = enemy.hp;
    enemy.speed = enemy.speed * speedMul;
    if (geomMul != 1.0) {
      enemy.geomValue = (enemy.geomValue * geomMul).round();
    }

    // Modifier giant_mode: nemici 2× più grandi (richiesta utente).
    if (hasModifier('giant_mode')) {
      enemy.size.scale(2.0);
    }

    enemy.position = pos;
    // Tunnel mode: i mob compaiono OLTRE il margine destro (vedi
    // `_randomSpawnPosition`), quindi lo spawn invuln flash è invisibile e
    // crea solo rallentamenti al primo appearance. Clear per skip.
    if (isTunnelMode) {
      enemy.clearSpawnInvulnerability();
    }
    world.add(enemy);
    return enemy;
  }

  void spawnBoss(BossType type) {
    // In tunnel mode: spawna davanti alla camera (visibile)
    final pos = isTunnelMode
        ? Vector2(
            camera.viewfinder.position.x + size.x / 2 + 100,
            camera.viewfinder.position.y,
          )
        : Vector2(arenaWidth / 2, arenaHeight / 2 - 300);
    BossBase boss;

    switch (type) {
      case BossType.theGrid:
        boss = TheGridBoss();
      case BossType.hydra:
        boss = HydraBoss();
      case BossType.singularity:
        boss = SingularityBoss();
      case BossType.swarmMother:
        boss = SwarmMotherBoss();
      case BossType.theArchitect:
        boss = TheArchitectBoss();
      case BossType.chronoWraith:
        boss = ChronoWraithBoss();
      case BossType.nexusPrime:
        boss = NexusPrimeBoss();
      case BossType.voidReaper:
        boss = VoidReaperBoss();
      case BossType.teslaLord:
        boss = TeslaLordBoss();
      case BossType.phantomKing:
        boss = PhantomKingBoss();
      case BossType.omegaCore:
        boss = OmegaCoreBoss();
      case BossType.mirrorMaster:
        boss = MirrorMasterBoss();
      case BossType.swarmQueen:
        boss = SwarmQueenBoss();
      case BossType.graviton:
        boss = GravitonBoss();
      case BossType.inferno:
        boss = InfernoBoss();
      case BossType.eternityEngine:
        boss = EternityEngineBoss();
      case BossType.crimsonCrown:
        boss = CrimsonCrownBoss();
      case BossType.prismHunter:
        boss = PrismHunterBoss();
      case BossType.voidKraken:
        boss = VoidKrakenBoss();
      case BossType.astralSentinel:
        boss = AstralSentinelBoss();
    }

    // HP dimezzati per tutti i boss (bilanciamento), poi scalati per difficoltà
    boss.hp = (boss.hp * 0.5 * diffConfig.enemyHpMultiplier).roundToDouble();
    boss.maxHp = boss.hp;

    boss.position = pos;
    world.add(boss);
    onBossStart?.call(boss.bossName);
  }

  Vector2 _randomSpawnPosition() {
    final random = _random;
    // Range spawn +50% rispetto al viewport per distribuire i mob più ampiamente
    // ed evitare cluster ammassati attorno al bordo visibile.
    const viewWidth = 1200.0; // era 800
    const viewHeight = 900.0; // era 600
    const padding = 300.0; // era 200

    // Tunnel mode: spawn davanti alla camera. Y calcolato usando i muri ALLA
    // X DI SPAWN — altrimenti il sinusoidale dei muri può far finire mob
    // oltre la parete inferiore → enemy_base clamp li incolla al muro
    // ("mob rimangono appiccicati alla parete sotto" — richiesta utente).
    if (isTunnelMode) {
      final cameraX = camera.viewfinder.position.x;
      final screenHalfW = size.x / 2;
      final spawnX =
          cameraX + screenHalfW + 50 + random.nextDouble() * 450;
      final (topWall, bottomWall) = tunnelWallsAtX(spawnX);
      const margin = 20.0;
      final ySafe = topWall + margin +
          random.nextDouble() * (bottomWall - topWall - 2 * margin);
      return Vector2(spawnX, ySafe);
    }

    // Modalità normali: spawn da tutti e 4 i lati.
    // Genera 4 candidati, sceglie quello più lontano dal nemico più vicino
    // (min-distance maximization) per ridurre cluster visivi.
    Vector2 best = _rollCandidate(random, viewWidth, viewHeight, padding);
    double bestMinDist = _minDistanceToExistingEnemy(best);
    for (int i = 0; i < 3; i++) {
      final cand = _rollCandidate(random, viewWidth, viewHeight, padding);
      final d = _minDistanceToExistingEnemy(cand);
      if (d > bestMinDist) {
        best = cand;
        bestMinDist = d;
      }
    }
    return best;
  }

  Vector2 _rollCandidate(math.Random random, double vw, double vh, double padding) {
    final side = random.nextInt(4);
    switch (side) {
      case 0: // top
        return Vector2(
          player.position.x + (random.nextDouble() - 0.5) * vw,
          player.position.y - vh / 2 - padding,
        );
      case 1: // right
        return Vector2(
          player.position.x + vw / 2 + padding,
          player.position.y + (random.nextDouble() - 0.5) * vh,
        );
      case 2: // bottom
        return Vector2(
          player.position.x + (random.nextDouble() - 0.5) * vw,
          player.position.y + vh / 2 + padding,
        );
      default: // left
        return Vector2(
          player.position.x - vw / 2 - padding,
          player.position.y + (random.nextDouble() - 0.5) * vh,
        );
    }
  }

  double _minDistanceToExistingEnemy(Vector2 pos) {
    double minDist = double.infinity;
    // Campiona solo i primi 40 nemici per evitare O(N) costoso con 150 attivi
    int checked = 0;
    for (final child in world.children) {
      if (child is EnemyBase) {
        final d = child.position.distanceToSquared(pos);
        if (d < minDist) minDist = d;
        if (++checked >= 40) break;
      }
    }
    return minDist;
  }

  void spawnGeom(Vector2 position, int value) {
    final geom = Geom(value: value);
    geom.position = position.clone();
    world.add(geom);
  }

  void spawnExplosion(Vector2 position, Color color,
      {double radius = 50, int particleCount = 20, bool epic = false}) {
    final explosion = ExplosionEffect(
      color: color,
      radius: radius,
      particleCount: particleCount,
      epic: epic,
    );
    explosion.position = position.clone();
    world.add(explosion);
    // Grid distortion: tutte le esplosioni distorcono la griglia, ma capped a 4/frame
    // Epic = forza e raggio maggiori; mob normali = distorsione piccola e sottile
    if (!isTunnelMode && _gridDistortionCount < 4) {
      final distRadius = epic ? radius * 3.75 : radius * 1.5;
      final distForce  = epic ? 1200.0 : 270.0;
      grid.applyForce(position, distRadius, distForce);
      _gridDistortionCount++;
    }
    // Screen shake solo per esplosioni epic (boss/titan/ecc.)
    if (epic) {
      triggerScreenShake(4, 0.15);
    }
  }

  void spawnPowerUp(Vector2 position) {
    powerUpSystem.spawnRandomPowerUp(position);
  }

  void onEnemyKilled(EnemyBase enemy) {
    AudioSystem.playEnemyDeath();
    // GLASS modifier: score ×1.6 (compensa hp ×0.4 high-risk/reward).
    final waveMod = waveSystem.activeModifier;
    final pointsBoosted = waveMod == WaveModifier.glass
        ? (enemy.pointValue * 1.6).round()
        : enemy.pointValue;
    scoreSystem.addKill(pointsBoosted, enemy.position);
    sessionKills++;

    // Track max multiplier per achievement
    final currentMult = scoreSystem.multiplierDisplay;
    if (currentMult > maxMultiplierReached) maxMultiplierReached = currentMult;

    // Tunnel mode: traccia kill per boss spawn ogni 30
    if (isTunnelMode) {
      waveSystem.onTunnelKill();
    }

    // Drop geoms — conteggio FISSO, NON scalato dalla difficoltà.
    // La difficoltà cambia solo i punti (scoreMultiplier), non la quantità
    // di geom che dropppano (richiesta utente: "i geom droppati devono restare
    // uguali ma cambiano i punteggi dati dai nemici").
    //
    // Regole:
    // - Splitter large/medium: NIENTE geom (solo i small droppano → evita
    //   cascata di geom quando un large si spezza in 2 medium → 4 small).
    // - BlackHole: 1 geom viola (value 5), stesso tier di un boss per kill.
    // - Altri: 1 geom cyan (value 1).
    bool shouldDropGeoms = true;
    int geomUnitValue = 1;
    if (enemy is SplitterEnemy && enemy.splitterSize != SplitterSize.small) {
      shouldDropGeoms = false;
    } else if (enemy is BlackHoleEnemy) {
      geomUnitValue = 5;
    }
    if (shouldDropGeoms) {
      spawnGeom(enemy.position, geomUnitValue);
    }

    // Chance to drop power-up (influenzata dalla difficoltà)
    if (_random.nextDouble() < diffConfig.powerUpDropRate) {
      spawnPowerUp(enemy.position);
    }

    // Notifica Necro nemici vicini della morte (per resurrezione).
    // Usa cached list invece di iterare world.children (O(N_all) → O(N_necro)).
    // Con molti proiettili/esplosioni il loop costava parecchio per kill.
    final enemyType = _getEnemyType(enemy);
    if (enemyType != EnemyType.necro && _cachedNecros.isNotEmpty) {
      for (final necro in _cachedNecros) {
        if (necro != enemy && !necro.isRemoved) {
          necro.onNearbyEnemyDeath(enemyType, enemy.position);
        }
      }
    }
  }

  /// Determina il tipo EnemyType di un nemico dalla sua classe
  EnemyType _getEnemyType(EnemyBase enemy) {
    if (enemy is DroneEnemy) return EnemyType.drone;
    if (enemy is SwarmDroneEnemy) return EnemyType.swarmDrone;
    if (enemy is KamikazeEnemy) return EnemyType.kamikaze;
    if (enemy is WeaverEnemy) return EnemyType.weaver;
    if (enemy is MineEnemy) return EnemyType.mine;
    if (enemy is SplitterEnemy) return EnemyType.splitter;
    if (enemy is ShieldEnemy) return EnemyType.shieldEnemy;
    if (enemy is BlackHoleEnemy) return EnemyType.blackHole;
    if (enemy is TitanEnemy) return EnemyType.titan;
    if (enemy is PulsarEnemy) return EnemyType.pulsar;
    if (enemy is MirrorEnemy) return EnemyType.mirror;
    if (enemy is PhantomEnemy) return EnemyType.phantom;
    if (enemy is VortexEnemy) return EnemyType.vortex;
    if (enemy is LeechEnemy) return EnemyType.leech;
    if (enemy is GlitchEnemy) return EnemyType.glitch;
    if (enemy is HealerEnemy) return EnemyType.healer;
    if (enemy is OrbiterEnemy) return EnemyType.orbiter;
    if (enemy is SirenEnemy) return EnemyType.siren;
    if (enemy is NecroEnemy) return EnemyType.necro;
    if (enemy is TeslaEnemy) return EnemyType.tesla;
    if (enemy is GravityWellEnemy) return EnemyType.gravityWell;
    if (enemy is LaserTurretEnemy) return EnemyType.laserTurret;
    if (enemy is TimeBombEnemy) return EnemyType.timeBomb;
    if (enemy is DecoyEnemy) return EnemyType.decoy;
    if (enemy is SnakeEnemy) return EnemyType.snake;
    if (enemy is SpawnerEnemy) return EnemyType.spawner;
    if (enemy is ProtonEnemy) return EnemyType.proton;
    if (enemy is MutatorEnemy) return EnemyType.mutator;
    return EnemyType.drone;
  }

  void onBossKilled(BossBase boss) {
    // FX fanfara boss killed (asset dedicato dell'utente)
    AudioSystem.playBossKilled();

    scoreSystem.addKill(boss.pointValue * 10, boss.position);
    sessionBossKills++;

    // Tunnel: ritarda il restringimento di 5s (grace period per raccogliere
    // drop) + 5s di shrink graduale = 10s totali dal boss death al tunnel
    // completamente ristretto. Incrementa anche il counter per ostacoli +3%.
    if (isTunnelMode) {
      _tunnelBossShrinkDelay = 5.0;
      tunnelBossesKilled++;
    }

    // Drop fisso di 10 geom viola (value 5) — reward leggibile per boss kill,
    // niente più "pioggia" di 30-120 geomi che lagga e svilisce la purple.
    const bossGeomDrops = 10;
    for (int i = 0; i < bossGeomDrops; i++) {
      final offset = Vector2(
        (_random.nextDouble() - 0.5) * 100,
        (_random.nextDouble() - 0.5) * 100,
      );
      spawnGeom(boss.position + offset, 5);
    }

    waveSystem.onBossDefeated();
  }

  void onPlayerHit() {
    // FX esplosione player (mp3 dell'utente) — ogni vita persa.
    AudioSystem.playPlayerDeath();

    // Skip a nuova canzone SOLO se non è la morte finale. Ritardato 150ms
    // per evitare contention MediaPlayer con il FX appena partito: con call
    // back-to-back uno dei due veniva silenziato randomicamente.
    if (player.lives > 0) {
      final capturedSession = _sessionId;
      Future.delayed(const Duration(milliseconds: 150), () {
        // Guard: session bumped (restart in corso) → callback obsoleto.
        if (_sessionId != capturedSession) return;
        if (player.lives > 0) {
          unawaited(MusicManager.skipToNext());
        }
      });
    }

    scoreSystem.resetMultiplier();
    _hitThisWave = true; // Questa wave non è più "perfect"

    // MEGA SHOCKWAVE — onda d'urto devastante come la bomba
    activateSlowMo(0.4, 0.3); // Slow-mo drammatico
    triggerScreenShake(15, 0.8); // Shake più intenso della bomba
    hitFlashTimer = 0.5; // Flash rosso prolungato

    // Uccidi tutti i nemici nel raggio SENZA dare punti/geom/kill
    const deathRadius = 600.0;
    final enemies = world.children.whereType<EnemyBase>().toList();
    for (final enemy in enemies) {
      final dist = enemy.position.distanceTo(player.position);
      if (dist < deathRadius) {
        enemy.killSilently();
      }
    }

    // Tripla esplosione concentrica (rosso → arancione → bianco)
    _deathExplosionTimers = [
      _DelayedExplosion(
        timeLeft: 0.12,
        color: const Color(0xFFFF6600),
        radius: 450,
        particleCount: 50,
      ),
      _DelayedExplosion(
        timeLeft: 0.25,
        color: const Color(0xFFFFFFFF),
        radius: 300,
        particleCount: 35,
      ),
    ];
    _deathExplosionPos = player.position.clone();
    spawnExplosion(_deathExplosionPos!, const Color(0xFFFF2200),
        radius: 600, particleCount: 70);

    // Distorsione griglia massima
    if (!isTunnelMode) {
      grid.applyForce(player.position, 600, 2500);
    }
  }

  /// Chiamato quando una wave viene completata (dal WaveSystem)
  void onWaveComplete() {
    // Pacifist: no concept di "wave perfetta" (modalità continua, non a wave).
    // Skip Perfect Wave display + bonus geom + streak counter.
    if (isPacifistMode) {
      _hitThisWave = false;
      consecutivePerfectWaves = 0;
      return;
    }
    if (!_hitThisWave) {
      // PERFECT WAVE! Nessun colpo subito durante la wave
      showPerfectWave = true;
      _perfectWaveTimer = 2.5;
      // Bonus: +10 al moltiplicatore per perfect wave
      scoreSystem.addGeoms(10);
      consecutivePerfectWaves++;
    } else {
      consecutivePerfectWaves = 0;
    }
    _hitThisWave = false; // Reset per la prossima wave
  }

  // Time Attack: timer countdown
  double timeAttackTimer = 180; // 3 minuti
  bool get isTimeAttackMode => gameMode == GameMode.timeAttack;

  bool _sessionSaved = false;

  /// Salva dati sessione (highscore, gold, stats). Idempotente.
  void saveSessionData() {
    if (_sessionSaved) return;
    _sessionSaved = true;

    // Convert session geoms to gold
    final goldEarned =
        (sessionGeoms / geomToGoldRatio * saveData.xpBoostMultiplier).round();
    saveData.goldGeoms += goldEarned;

    // Update highscore
    final mode = gameMode.name;
    final currentHigh = saveData.highscores[mode] ?? 0;
    if (scoreSystem.score > currentHigh) {
      saveData.highscores[mode] = scoreSystem.score;
    }

    // Update stats
    saveData.stats['totalKills'] =
        (saveData.stats['totalKills'] ?? 0) + sessionKills;
    saveData.stats['gamesPlayed'] =
        (saveData.stats['gamesPlayed'] ?? 0) + 1;
    saveData.stats['totalBosses'] =
        (saveData.stats['totalBosses'] ?? 0) + sessionBossKills;
    saveData.stats['totalBombs'] =
        (saveData.stats['totalBombs'] ?? 0) + sessionBombs;
    saveData.stats['totalPowerUps'] =
        (saveData.stats['totalPowerUps'] ?? 0) + sessionPowerUps;
    saveData.stats['totalGeoms'] =
        (saveData.stats['totalGeoms'] ?? 0) + sessionGeoms;

    // Record per sessione
    final currentMaxKills = saveData.stats['maxSessionKills'] ?? 0;
    if (sessionKills > currentMaxKills) {
      saveData.stats['maxSessionKills'] = sessionKills;
    }
    final currentMaxWave = saveData.stats['maxWave'] ?? 0;
    if (waveSystem.currentWave > currentMaxWave) {
      saveData.stats['maxWave'] = waveSystem.currentWave;
    }
    final currentMaxMult = saveData.stats['maxMultiplier'] ?? 0;
    if (maxMultiplierReached > currentMaxMult) {
      saveData.stats['maxMultiplier'] = maxMultiplierReached;
    }
    final currentMaxPerfect = saveData.stats['maxPerfectStreak'] ?? 0;
    if (consecutivePerfectWaves > currentMaxPerfect) {
      saveData.stats['maxPerfectStreak'] = consecutivePerfectWaves;
    }

    // Track playtime (secondi)
    saveData.totalPlaytime += _sessionTimeSec.round();

    // Track mode played
    if (!saveData.playedModes.contains(gameMode.name)) {
      saveData.playedModes.add(gameMode.name);
    }

    SaveManager.save(saveData);
  }

  void onPlayerDeath() {
    // Zen mode: player immortale. Conta le morti, ripristina lives al valore
    // iniziale della difficoltà, niente game over.
    if (isZenMode) {
      sessionDeaths++;
      player.lives = diffConfig.startingLives + (saveData.startingLives - 3);
      return;
    }

    if (player.lives <= 0) {
      gameState = GameState.gameOver;
      // FX gameover_explosion.mp3 (drammatico finale).
      AudioSystem.playGameOver();
      // Stop musica ritardato 250ms: lascia a game-over FX MediaPlayer
      // libero per partire senza contention. Senza stagger, bgm.stop() +
      // FlameAudio.play concorrenti sullo stesso thread audio nativo
      // causano silenzio random sull'uno o l'altro.
      final capturedSession = _sessionId;
      Future.delayed(const Duration(milliseconds: 250), () {
        // Guard: se l'utente ha già riavviato, stop() killa la nuova bgm.
        if (_sessionId != capturedSession) return;
        unawaited(MusicManager.stop());
      });
      saveSessionData();
      pauseEngine(); // Ferma il loop Flame: niente più update/render/audio
      onGameOver?.call();
    }
  }

  void collectGeom(int value) {
    // Ogni geom raccolto aggiunge +1 al moltiplicatore (non moltiplicato)
    scoreSystem.addGeoms(value);
    sessionGeoms += value;
  }

  void _applyModifiers() {
    for (final modId in activeModifiers) {
      switch (modId) {
        case 'glass_cannon':
          player.lives = 1;
          // 3x danno applicato nel player shoot
          break;
        case 'speed_demon':
          player.speed = playerSpeed * 1.5;
          break;
        case 'one_shot':
          player.lives = 1;
          break;
        case 'infinite_bombs':
          player.bombs = 999;
          break;
        case 'magnet_king':
          // Handled in geom collection
          break;
        case 'tiny_arena':
          // Arena 50% più piccola - handled via getter
          break;
        // Others handled in their respective systems
      }
    }
    // Applica il moltiplicatore score dai modifier (glass_cannon 3×, bullet_hell 2×, ecc.)
    scoreSystem.modifierMultiplier = modifierScoreMultiplier;

    // Pacifist mode override: 1 vita, 0 bombe (Pacifism GW2 hard-coded).
    // Override DOPO i modifier perché alcuni (es. infinite_bombs) potrebbero
    // dare bombe → in pacifist non servono comunque (no shooting → no bomb fire).
    if (isPacifistMode) {
      player.lives = 1;
      player.bombs = 0;
    }
  }

  /// Chiamato da GateEnemy.`_triggerExplosion()`. Solo in pacifist mode
  /// applica la combo (scoring + AoE). Negli altri modi (survival, signature
  /// wave classic) il gate scoring rimane invariato — gestito direttamente
  /// dal gate stesso. Ritorna true se combo applicata.
  void onGateExplosion(int killCount, Vector2 pos) {
    if (!isPacifistMode) return;
    gateCombo++;
    gateComboTimer = _gateComboWindow;
    if (killCount > 0) {
      // Pacifism scoring: base 25 + 10 per kill, × combo multiplier (1-10×).
      // Boost rispetto a survival per dare drama alle catene gate.
      final basePts = 25 + killCount * 10;
      final pts = basePts * gateComboScoreMultiplier;
      scoreSystem.addKill(pts, pos);
    }
  }

  bool hasModifier(String id) => activeModifiers.contains(id);
  double get modifierScoreMultiplier => combinedScoreMultiplier(activeModifiers);

  // Arena effettiva (con modificatore tiny_arena)
  double get effectiveArenaWidth => hasModifier('tiny_arena') ? arenaWidth * 0.5 : arenaWidth;
  double get effectiveArenaHeight => hasModifier('tiny_arena') ? arenaHeight * 0.5 : arenaHeight;

  // ══════════════════════════════════════════════════════════════
  // TUNNEL GEOMETRY — usata da nemici, proiettili e TunnelRenderer
  // (duplicata qui per accesso diretto senza cercare il componente)
  // ══════════════════════════════════════════════════════════════

  /// Offset Y del centro del tunnel alla posizione X (curva sinusoidale)
  double tunnelCenterOffsetAt(double x) {
    final slow  = math.sin(x * 0.0008) * 120;
    final med   = math.sin(x * 0.003  + 1.7) * 60;
    final fast  = math.sin(x * 0.008  + 3.1) * 25;
    final sharp = math.sin(x * 0.015  + 0.5) * 15;
    final sCurve = math.atan(math.sin(x * 0.002 + 2.3) * 3) * 50;
    return slow + med + fast + sharp + sCurve;
  }

  /// Metà altezza del tunnel alla posizione X (varia per strozzature)
  double tunnelHalfHeightAt(double x) {
    final base   = tunnelHeight / 2;
    final narrow = math.sin(x * 0.004 + 0.8) * base * 0.15;
    final wide   = math.sin(x * 0.001 + 2.0) * base * 0.10;
    return (base + narrow + wide).clamp(base * 0.5, base * 1.3);
  }

  /// Restituisce (topWall, bottomWall) per la posizione X nel tunnel
  (double, double) tunnelWallsAtX(double x) {
    final offset = tunnelCenterOffsetAt(x);
    final half   = tunnelHalfHeightAt(x);
    final cy     = arenaHeight / 2;
    return (cy + offset - half, cy + offset + half);
  }

  void useBomb() {
    if (player.bombs <= 0) return;
    player.bombs--;
    sessionBombs++;

    // Slow-mo breve (0.3s, scala 0.5 — meno aggressivo)
    activateSlowMo(0.3, 0.5);

    // Uccidi TUTTI i nemici nell'area dell'esplosione (raggio = visual)
    // Bomba = danno AREA → splitter immuni (evita cascata di divisioni
    // simultanee che può crashare il frame).
    const bombRadius = 800.0;
    final enemies = world.children.whereType<EnemyBase>().toList();
    for (final enemy in enemies) {
      final dist = enemy.position.distanceTo(player.position);
      if (dist < bombRadius) {
        enemy.takeDamage(999, isArea: true);
      }
    }

    // Danneggia anche i boss nel raggio. PASS isArea: true così boss con
    // shield-meccaniche (es. NexusPrime con satelliti) accettano il danno
    // tramite il branch AoE invece di bloccarlo come direct hit.
    // Bug pre-fix: senza isArea, NexusPrime takeDamage cadeva nel ramo
    // "_aliveSatellites > 0 && !isArea" → return early → boss invuln.
    final bosses = world.children.whereType<BossBase>().toList();
    for (final boss in bosses) {
      final dist = boss.position.distanceTo(player.position);
      if (dist < bombRadius) {
        boss.takeDamage(50, isArea: true);
      }
    }

    // Esplosione DEVASTANTE: tripla esplosione concentrica (timer-based, rispetta pause/dispose)
    _bombExplosionTimers = [
      _DelayedExplosion(
        timeLeft: 0.1,
        color: NeonColors.cyan,
        radius: 600,
        particleCount: 60,
      ),
      _DelayedExplosion(
        timeLeft: 0.2,
        color: NeonColors.spreadOrange,
        radius: 400,
        particleCount: 40,
      ),
    ];
    _bombExplosionPos = player.position.clone();
    spawnExplosion(_bombExplosionPos!, NeonColors.white,
        radius: 800, particleCount: 80);

    // Screen shake intenso e prolungato
    triggerScreenShake(12, 0.6);
    // Distorsione griglia massima (solo se non tunnel mode)
    if (!isTunnelMode) {
      grid.applyForce(player.position, bombRadius, 3000);
    }
  }

  void togglePause() {
    if (gameState == GameState.playing) {
      gameState = GameState.paused;
      pauseEngine();
      unawaited(MusicManager.pause());
      onPause?.call();
    } else if (gameState == GameState.paused) {
      gameState = GameState.playing;
      resumeEngine();
      unawaited(MusicManager.resume());
    }
  }

  void restartGame() {
    // Bump session: invalida Future.delayed callback pending (music stop/skip).
    _sessionId++;
    // Riprendi il motore se era stato fermato (game over / pausa)
    resumeEngine();

    // Rimuovi screenShake dal viewfinder prima di pulire il world
    screenShake.removeFromParent();

    world.removeAll(world.children.toList());
    gameState = GameState.playing;
    timeScale = 1.0;
    _slowMoTimer = 0;
    sessionGeoms = 0;
    sessionKills = 0;
    sessionDeaths = 0;
    sessionBombs = 0;
    sessionBossKills = 0;
    sessionPowerUps = 0;
    consecutivePerfectWaves = 0;
    maxMultiplierReached = 0;
    _hitThisWave = false;
    _sessionSaved = false;
    _sessionTimeSec = 0;
    showPerfectWave = false;
    hitFlashTimer = 0;
    timeAttackTimer = 180;
    tunnelHeight = 420;
    tunnelTargetHeight = 420;
    tunnelScrollSpeed = 100;
    _tunnelCameraX = 0;
    _tunnelBossShrinkDelay = 0;
    // Fix: era 0.0 ma `_tunnelShrinkProgress` è full-height=1.0; con 0.0
    // il tunnel partiva pre-shrunk al primo frame di un nuovo game tunnel.
    _tunnelShrinkProgress = 1.0;
    _tunnelShrinkStartHeight = 420;
    tunnelBossesKilled = 0;
    _chaosTimer = 10.0;
    // Reset Pacifism gate combo state — campi sopravvivono restart se game
    // world non viene ricreato (resetGame mid-session) → senza reset, prima
    // gate post-restart partirebbe con AoE/score multiplier dal session prima.
    gateCombo = 0;
    gateComboTimer = 0;
    _bombExplosionTimers = null;
    _bombExplosionPos = null;
    _deathExplosionTimers = null;
    _deathExplosionPos = null;
    SwarmDroneEnemy.resetGlobalEnrage();
    LeechEnemy.resetAttachedCount();
    HomingMissile.resetStaticState();
    SplitterEnemy.resetFrameBudget();
    // Reset count cache: stale values dal session precedente potevano far
    // credere al WaveSystem che ci fosse ancora un boss attivo → wave 1
    // con boss entrava in _pendingBoss invece che spawn immediato.
    _cachedEnemyCount = 0;
    _cachedBossCount = 0;
    _cachedActiveBoss = null;
    _cachedNecros.clear();
    _countCacheTimer = 0;
    // Clear held keys: se user teneva premuto un tasto durante game over,
    // il set resta sporco. Il primo onKeyEvent ripulisce, ma cleanup qui
    // evita 1-frame di input fantasma in retry.
    _pressedKeys.clear();
    scoreSystem.reset();
    scoreSystem.geomValueMultiplier = diffConfig.geomValueMultiplier;
    scoreSystem.scoreMultiplier = diffConfig.scoreMultiplier;
    scoreSystem.modifierMultiplier = modifierScoreMultiplier;

    // Re-add components
    spaceBackground = SpaceBackground();
    world.add(spaceBackground);

    // Grid solo se NON in tunnel mode
    grid = GridDistortion();
    if (!isTunnelMode) {
      world.add(grid);
      // Ri-aggiunge ArenaBorder (era missing post-restart: bordo arena
      // scompariva in classic mode dopo primo retry).
      world.add(ArenaBorder());
    }

    // Tunnel renderer solo in tunnel mode
    if (isTunnelMode) {
      tunnelRenderer = TunnelRenderer();
      world.add(tunnelRenderer!);
    } else {
      tunnelRenderer = null;
    }

    player = Player();
    player.position = Vector2(arenaWidth / 2, arenaHeight / 2);
    player.lives = diffConfig.startingLives + (saveData.startingLives - 3);
    player.bombs = diffConfig.startingBombs;
    player.setWeaponFromId(saveData.startingWeapon);
    world.add(player);

    // Pet companion: respawn al restart (fix caveman-review: prima attivePet
    // restava reference stale alla vecchia istanza distrutta dal world reset).
    // Pacifist: niente pet (regola Pacifism = no offensiva).
    if (!isPacifistMode) {
      final petType = petTypeById(saveData.activePet);
      activePet = createPet(petType);
      if (activePet != null) {
        activePet!.position = player.position + Vector2(40, 0);
        world.add(activePet!);
      }
    } else {
      activePet = null;
    }

    // Re-apply modifiers (glass_cannon, speed_demon, etc.)
    _applyModifiers();

    // Ricrea screenShake sul viewfinder
    screenShake = ScreenShakeEffect();
    camera.viewfinder.add(screenShake);

    waveSystem = WaveSystem(this);
    waveSystem.reset(); // Reset tunnel counters e stato wave
    powerUpSystem.reset(); // Resetta spawn timer
    waveSystem.startWave(1);
    resumeEngine();
  }

  // Cache conteggi nemici/boss — aggiornati una volta per frame in update()
  int _cachedEnemyCount = 0;
  int _cachedBossCount = 0;
  // Session id — bump su restartGame. Future.delayed outliving gioco può
  // usarlo per skippare callback post-restart (evita MusicManager.stop() /
  // skipToNext() fired contro session nuova).
  int _sessionId = 0;
  // Lista cached dei Necro per iterare in onEnemyKilled senza walk world.children.
  // Early-exit per O(n²) NecroEnemy loop quando il player uccide molti nemici.
  final List<NecroEnemy> _cachedNecros = <NecroEnemy>[];
  BossBase? _cachedActiveBoss;
  double _countCacheTimer = 0;

  int get enemyCount => _cachedEnemyCount;
  int get bossCount => _cachedBossCount;

  /// Ritorna il boss attivo (se presente) per mostrare la barra HP nella HUD
  BossBase? get activeBoss => _cachedActiveBoss;

  /// Aggiorna i conteggi cached (chiamato ogni 3 frame, singolo pass)
  void _updateEntityCounts() {
    _countCacheTimer -= 1;
    if (_countCacheTimer > 0) return;
    _countCacheTimer = 3; // Aggiorna ogni 3 frame (~20 volte/sec a 60fps)
    int enemies = 0;
    int bosses = 0;
    _cachedNecros.clear();
    BossBase? firstBoss;
    for (final child in world.children) {
      if (child is NecroEnemy) {
        enemies++;
        _cachedNecros.add(child);
      } else if (child is EnemyBase) {
        enemies++;
      } else if (child is BossBase) {
        bosses++;
        firstBoss ??= child;
      }
    }
    _cachedEnemyCount = enemies;
    _cachedBossCount = bosses;
    _cachedActiveBoss = firstBoss;
  }
}

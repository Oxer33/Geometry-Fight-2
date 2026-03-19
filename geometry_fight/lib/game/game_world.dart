import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show KeyEventResult;
import '../data/constants.dart';
import '../data/difficulty.dart';
import '../data/save_data.dart';
import '../data/wave_configs.dart';
import '../utils/spatial_hash.dart';
import 'entities/player.dart';
import 'entities/projectiles.dart';
import 'entities/enemies/enemy_base.dart';
import 'entities/enemies/drone_enemy.dart';
import 'entities/enemies/snake_enemy.dart';
import 'entities/enemies/mine_enemy.dart';
import 'entities/enemies/spawner_enemy.dart';
import 'entities/enemies/weaver_enemy.dart';
import 'entities/enemies/bouncer_enemy.dart';
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
import 'entities/bosses/eternity_engine_boss.dart';
import 'entities/geom.dart';
import 'entities/powerups.dart';
import 'effects/grid_distortion.dart';
import 'effects/screen_shake.dart';
import 'effects/explosion.dart';
import 'effects/space_background.dart';
import 'effects/tunnel_renderer.dart';
import 'systems/wave_system.dart';
import 'systems/score_system.dart';
import 'systems/powerup_system.dart';
import 'systems/audio_system.dart';

enum GameState { playing, paused, gameOver, bossIntro, waveIntro }

class GeometryFightGame extends FlameGame
    with HasCollisionDetection, KeyboardEvents {
  late Player player;
  late SpaceBackground spaceBackground;
  late GridDistortion grid;
  late ScreenShakeEffect screenShake;
  late WaveSystem waveSystem;
  late ScoreSystem scoreSystem;
  late PowerUpSystem powerUpSystem;

  final SpatialHash<PositionComponent> spatialHash =
      SpatialHash(cellSize: spatialCellSize);

  GameState gameState = GameState.playing;
  double timeScale = 1.0;
  double _slowMoTimer = 0;

  // Difficoltà e modalità di gioco
  final Difficulty difficulty;
  final GameMode gameMode;
  late DifficultyConfig diffConfig;

  SaveData saveData = SaveData();

  GeometryFightGame({
    this.difficulty = Difficulty.normal,
    this.gameMode = GameMode.classic,
  }) {
    diffConfig = difficultyConfigs[difficulty]!;
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

  // Perfect Wave tracking
  bool _hitThisWave = false;
  bool showPerfectWave = false;
  double _perfectWaveTimer = 0;

  // Screen flash rosso quando colpito
  double hitFlashTimer = 0;

  // Tunnel mode: arena dinamica
  double tunnelHeight = 600; // Altezza corridoio (si allarga per boss)
  double tunnelTargetHeight = 600;
  bool get isTunnelMode => gameMode == GameMode.tunnel;

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
      world.add(TunnelRenderer());
    }

    // Add player (applica difficoltà alle vite/bombe iniziali)
    player = Player();
    player.position = Vector2(arenaWidth / 2, arenaHeight / 2);
    player.lives = diffConfig.startingLives + (saveData.startingLives - 3);
    player.bombs = diffConfig.startingBombs;
    world.add(player);

    // Screen shake
    screenShake = ScreenShakeEffect();
    camera.viewfinder.add(screenShake);

    // Systems
    scoreSystem = ScoreSystem();
    waveSystem = WaveSystem(this);
    powerUpSystem = PowerUpSystem(this);

    // Start first wave
    waveSystem.startWave(1);
  }

  @override
  void update(double dt) {
    if (gameState == GameState.paused || gameState == GameState.gameOver) return;

    // Apply time scale
    final scaledDt = dt * timeScale;

    // Slow-mo timer
    if (_slowMoTimer > 0) {
      _slowMoTimer -= dt;
      if (_slowMoTimer <= 0) {
        timeScale = 1.0;
      }
    }

    // Update keyboard input
    _updateKeyboardInput();

    // NOTA: spatial hash rimosso — Flame usa HasCollisionDetection built-in
    // che è più efficiente. Il spatial hash iterava TUTTI i children ogni frame
    // causando lag con molti nemici.

    // Update systems
    waveSystem.update(scaledDt);
    scoreSystem.update(scaledDt);
    powerUpSystem.update(scaledDt);

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
        final goldEarned = (sessionGeoms / geomToGoldRatio * saveData.xpBoostMultiplier).round();
        saveData.goldGeoms += goldEarned;
        final mode = gameMode.name;
        if (scoreSystem.score > (saveData.highscores[mode] ?? 0)) {
          saveData.highscores[mode] = scoreSystem.score;
        }
        SaveManager.save(saveData);
        onGameOver?.call();
        return;
      }
    }

    // Tunnel mode: aggiorna altezza corridoio (lerp verso il target)
    if (isTunnelMode) {
      tunnelTargetHeight = bossCount > 0 ? 1800 : 600; // Allarga per boss fight
      tunnelHeight += (tunnelTargetHeight - tunnelHeight) * 2.0 * dt;
    }

    // Camera follow player
    final targetPos = player.position.clone();
    final currentPos = camera.viewfinder.position;
    camera.viewfinder.position =
        currentPos + (targetPos - currentPos) * cameraSmoothing;

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

    // Applica input tastiera solo se non c'è touch attivo
    if (!usingTouchMove) {
      if (keyboardMove.length > 0) {
        keyboardMove.normalize();
      }
      moveInput = keyboardMove;
    }

    // Aim con frecce (solo se touch aim non attivo)
    if (!usingTouchAim && moveInput.length > 0 && aimInput.length == 0) {
      aimInput = moveInput.clone();
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

  // Limite massimo nemici attivi per performance (evita scatti con 50+)
  static const int _maxActiveEnemies = 60;

  void spawnEnemy(EnemyType type, [Vector2? position]) {
    // Limita nemici attivi per evitare scatti di performance
    if (enemyCount >= _maxActiveEnemies) return;

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
      case EnemyType.bouncer:
        enemy = BouncerEnemy();
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
    }

    // Applica moltiplicatori di difficoltà a HP e velocità
    enemy.hp = (enemy.hp * diffConfig.enemyHpMultiplier);
    enemy.maxHp = enemy.hp;
    enemy.speed = (enemy.speed * diffConfig.enemySpeedMultiplier);

    enemy.position = pos;
    world.add(enemy);
  }

  void spawnBoss(BossType type) {
    final pos = Vector2(arenaWidth / 2, arenaHeight / 2 - 300);
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
    }

    boss.position = pos;
    world.add(boss);
    onBossStart?.call(boss.bossName);
  }

  Vector2 _randomSpawnPosition() {
    final random = math.Random();
    const viewWidth = 800.0;
    const viewHeight = 600.0;
    const padding = 200.0;

    // Nel tunnel mode: nemici spawnano SEMPRE davanti al player (lato destro)
    if (isTunnelMode) {
      final centerY = arenaHeight / 2;
      final halfH = tunnelHeight / 2;
      return Vector2(
        player.position.x + viewWidth / 2 + padding + random.nextDouble() * 300,
        centerY + (random.nextDouble() - 0.5) * halfH * 1.5,
      );
    }

    // Modalità normali: spawn da tutti e 4 i lati
    final side = random.nextInt(4);
    switch (side) {
      case 0: // top
        return Vector2(
          player.position.x + (random.nextDouble() - 0.5) * viewWidth,
          player.position.y - viewHeight / 2 - padding,
        );
      case 1: // right
        return Vector2(
          player.position.x + viewWidth / 2 + padding,
          player.position.y + (random.nextDouble() - 0.5) * viewHeight,
        );
      case 2: // bottom
        return Vector2(
          player.position.x + (random.nextDouble() - 0.5) * viewWidth,
          player.position.y + viewHeight / 2 + padding,
        );
      default: // left
        return Vector2(
          player.position.x - viewWidth / 2 - padding,
          player.position.y + (random.nextDouble() - 0.5) * viewHeight,
        );
    }
  }

  void spawnGeom(Vector2 position, int value) {
    final geom = Geom(value: value);
    geom.position = position.clone();
    world.add(geom);
  }

  void spawnExplosion(Vector2 position, Color color,
      {double radius = 50, int particleCount = 20}) {
    final explosion = ExplosionEffect(
      color: color,
      radius: radius,
      particleCount: particleCount,
    );
    explosion.position = position.clone();
    world.add(explosion);
    grid.applyForce(position, radius * 2, 500);
    triggerScreenShake();
  }

  void spawnPowerUp(Vector2 position) {
    powerUpSystem.spawnRandomPowerUp(position);
  }

  void onEnemyKilled(EnemyBase enemy) {
    AudioSystem.playEnemyDeath();
    scoreSystem.addKill(enemy.pointValue, enemy.position);
    sessionKills++;

    // Drop geoms
    for (int i = 0; i < enemy.geomValue; i++) {
      final offset = Vector2(
        (math.Random().nextDouble() - 0.5) * 30,
        (math.Random().nextDouble() - 0.5) * 30,
      );
      spawnGeom(enemy.position + offset, 1);
    }

    // Chance to drop power-up (influenzata dalla difficoltà)
    if (math.Random().nextDouble() < diffConfig.powerUpDropRate) {
      spawnPowerUp(enemy.position);
    }

    // Notifica Necro nemici vicini della morte (per resurrezione)
    for (final child in world.children) {
      if (child is NecroEnemy) {
        child.onNearbyEnemyDeath(_getEnemyType(enemy), enemy.position);
      }
    }
  }

  /// Determina il tipo EnemyType di un nemico dalla sua classe
  EnemyType _getEnemyType(EnemyBase enemy) {
    if (enemy is DroneEnemy) return EnemyType.drone;
    if (enemy is SwarmDroneEnemy) return EnemyType.swarmDrone;
    if (enemy is KamikazeEnemy) return EnemyType.kamikaze;
    if (enemy is WeaverEnemy) return EnemyType.weaver;
    if (enemy is BouncerEnemy) return EnemyType.bouncer;
    return EnemyType.drone; // Default
  }

  void onBossKilled(BossBase boss) {
    scoreSystem.addKill(boss.pointValue * 10, boss.position);

    // Drop lots of geoms
    for (int i = 0; i < 50; i++) {
      final offset = Vector2(
        (math.Random().nextDouble() - 0.5) * 100,
        (math.Random().nextDouble() - 0.5) * 100,
      );
      spawnGeom(boss.position + offset, 5);
    }

    waveSystem.onBossDefeated();
  }

  void onPlayerHit() {
    AudioSystem.playPlayerHit();
    scoreSystem.resetMultiplier();
    triggerScreenShake(6, 0.3);
    hitFlashTimer = 0.3; // Flash rosso sullo schermo per 0.3s
    _hitThisWave = true; // Questa wave non è più "perfect"
  }

  /// Chiamato quando una wave viene completata (dal WaveSystem)
  void onWaveComplete() {
    if (!_hitThisWave) {
      // PERFECT WAVE! Nessun colpo subito durante la wave
      showPerfectWave = true;
      _perfectWaveTimer = 2.5;
      // Bonus: geomi raddoppiati per questa wave
      scoreSystem.addGeoms(50);
    }
    _hitThisWave = false; // Reset per la prossima wave
  }

  // Time Attack: timer countdown
  double timeAttackTimer = 180; // 3 minuti
  bool get isTimeAttackMode => gameMode == GameMode.timeAttack;

  void onPlayerDeath() {
    // Zen mode: vite infinite - respawn immediato
    if (gameMode == GameMode.zenMode) {
      player.lives = 1; // Ripristina 1 vita
      return;
    }

    if (player.lives <= 0) {
      gameState = GameState.gameOver;

      // Convert session geoms to gold
      final goldEarned =
          (sessionGeoms / geomToGoldRatio * saveData.xpBoostMultiplier).round();
      saveData.goldGeoms += goldEarned;

      // Update highscore (usa la modalità di gioco corrente, non hardcoded)
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

      SaveManager.save(saveData);
      onGameOver?.call();
    }
  }

  void collectGeom(int value) {
    final actualValue = (value * scoreSystem.multiplier).round();
    scoreSystem.addGeoms(actualValue);
    sessionGeoms += value;
  }

  void useBomb() {
    if (player.bombs <= 0) return;
    player.bombs--;

    // Slow-mo drammatico
    activateSlowMo(0.8, 0.2);

    // Uccidi TUTTI i nemici nell'intera area visibile (raggio enorme)
    final enemies = world.children.whereType<EnemyBase>().toList();
    for (final enemy in enemies) {
      final dist = enemy.position.distanceTo(player.position);
      if (dist < 1200) {
        enemy.takeDamage(999);
      }
    }

    // Danneggia anche i boss nel raggio
    final bosses = world.children.whereType<BossBase>().toList();
    for (final boss in bosses) {
      final dist = boss.position.distanceTo(player.position);
      if (dist < 1200) {
        boss.takeDamage(50); // Danno significativo ai boss
      }
    }

    // Esplosione DEVASTANTE: tripla esplosione concentrica
    spawnExplosion(player.position, NeonColors.white,
        radius: 800, particleCount: 80);
    // Seconda onda con colore diverso
    Future.delayed(const Duration(milliseconds: 100), () {
      if (gameState == GameState.playing) {
        spawnExplosion(player.position, NeonColors.cyan,
            radius: 600, particleCount: 60);
      }
    });
    // Terza onda
    Future.delayed(const Duration(milliseconds: 200), () {
      if (gameState == GameState.playing) {
        spawnExplosion(player.position, NeonColors.spreadOrange,
            radius: 400, particleCount: 40);
      }
    });

    // Screen shake intenso e prolungato
    triggerScreenShake(12, 0.6);
    // Distorsione griglia massima
    grid.applyForce(player.position, 1200, 3000);
  }

  void togglePause() {
    if (gameState == GameState.playing) {
      gameState = GameState.paused;
      pauseEngine();
      onPause?.call();
    } else if (gameState == GameState.paused) {
      gameState = GameState.playing;
      resumeEngine();
    }
  }

  void restartGame() {
    world.removeAll(world.children);
    gameState = GameState.playing;
    timeScale = 1.0;
    sessionGeoms = 0;
    sessionKills = 0;
    _hitThisWave = false;
    showPerfectWave = false;
    hitFlashTimer = 0;
    timeAttackTimer = 180;
    tunnelHeight = 600;
    scoreSystem.reset();

    // Re-add components
    spaceBackground = SpaceBackground();
    world.add(spaceBackground);

    // Grid solo se NON in tunnel mode
    grid = GridDistortion();
    if (!isTunnelMode) {
      world.add(grid);
    }

    // Tunnel renderer solo in tunnel mode
    if (isTunnelMode) {
      world.add(TunnelRenderer());
    }

    player = Player();
    player.position = Vector2(arenaWidth / 2, arenaHeight / 2);
    player.lives = diffConfig.startingLives + (saveData.startingLives - 3);
    player.bombs = diffConfig.startingBombs;
    world.add(player);

    waveSystem = WaveSystem(this);
    waveSystem.startWave(1);
    resumeEngine();
  }

  int get enemyCount => world.children.whereType<EnemyBase>().length;
  int get bossCount => world.children.whereType<BossBase>().length;

  /// Ritorna il boss attivo (se presente) per mostrare la barra HP nella HUD
  BossBase? get activeBoss {
    final bosses = world.children.whereType<BossBase>();
    return bosses.isEmpty ? null : bosses.first;
  }
}

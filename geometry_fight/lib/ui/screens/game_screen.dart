import 'dart:async';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/achievements.dart';
import '../../data/constants.dart';
import '../../data/difficulty.dart';
import '../../data/leaderboard.dart';
import '../../data/save_data.dart';
import '../../game/game_world.dart';
import '../../game/systems/audio_system.dart';
import '../../game/systems/music_manager.dart';
import '../hud.dart';
import '../widgets/animated_builder_widget.dart';
import '../widgets/virtual_joystick.dart';
import '../widgets/tutorial_overlay.dart';
import 'game_over_screen.dart';
import 'pause_screen.dart';

/// Schermata di gioco principale con GameWidget, joystick visuali e HUD.
class GameScreen extends StatefulWidget {
  final VoidCallback onQuit;
  final Difficulty difficulty;
  final GameMode gameMode;

  const GameScreen({
    super.key,
    required this.onQuit,
    this.difficulty = Difficulty.normal,
    this.gameMode = GameMode.classic,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late GeometryFightGame _game;
  bool _showPause = false;
  bool _showGameOver = false;
  bool _showTutorial = false;
  bool _leaderboardSaved = false;
  List<AchievementDef> _newAchievements = [];
  // Overlay nero per nascondere il flash bianco del GameWidget durante l'init
  double _fadeOverlayOpacity = 1.0;
  // Key per forzare ricostruzione GameWidget su restart (pulisce completamente lo stato Flame)
  int _gameKey = 0;
  // Timer cancellabile per overlay fade. Prima Future.delayed senza
  // cancel → doppia-retry rapida pending multipli.
  Timer? _fadeTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initGame();
    // Tutorial al primo avvio
    _checkTutorial();
    // Dissolvi overlay nero dopo GameWidget render primi frame (cancellabile).
    _fadeTimer?.cancel();
    _fadeTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _fadeOverlayOpacity = 0.0);
    });
  }

  /// Crea una nuova istanza del gioco con tutti i callback configurati.
  /// Usato sia in initState che su Retry per avere uno stato completamente pulito.
  void _initGame() {
    // Assicura che l'audio sia inizializzato (potrebbe essere stato fermato).
    // `unawaited` evita Future scartata + lint warning; l'init completa in
    // background mentre Flame compila il primo frame (accettabile: SFX
    // partono silenziosi per ~100-200ms, poi online).
    unawaited(AudioSystem.init());
    // Switch dalla musica intro/menu alla musica gameplay (random shuffle bag)
    unawaited(MusicManager.playBgm());
    _game = GeometryFightGame(
      difficulty: widget.difficulty,
      gameMode: widget.gameMode,
    );
    // Load active modifiers from save data
    final saveData = SaveManager.load();
    _game.activeModifiers = List.from(saveData.activeModifiers);
    _game.onGameOver = () {
      if (!mounted) return;
      unawaited(_saveLeaderboard());
      setState(() => _showGameOver = true);
    };
    _game.onPause = () {
      if (!mounted) return;
      setState(() => _showPause = true);
    };
  }

  Future<void> _saveLeaderboard() async {
    if (_leaderboardSaved || _game.scoreSystem.score <= 0) return;
    _leaderboardSaved = true;
    await LeaderboardManager.addEntry(LeaderboardEntry(
      mode: widget.gameMode.name,
      difficulty: widget.difficulty.name,
      score: _game.scoreSystem.score,
      wave: _game.waveSystem.currentWave,
      kills: _game.sessionKills,
      date: DateTime.now(),
    ));

    // Check achievements
    final saveData = _game.saveData;
    final stats = saveData.stats;
    _newAchievements = AchievementManager.checkAfterSession(
      totalKills: stats['totalKills'] ?? 0,
      sessionKills: _game.sessionKills,
      totalBosses: stats['totalBosses'] ?? 0,
      sessionScore: _game.scoreSystem.score,
      maxMultiplier: _game.maxMultiplierReached,
      totalGeoms: stats['totalGeoms'] ?? 0,
      waveReached: _game.waveSystem.currentWave,
      consecutivePerfectWaves: _game.consecutivePerfectWaves,
      gamesPlayed: stats['gamesPlayed'] ?? 0,
      totalGold: saveData.goldGeoms,
      totalPowerUps: stats['totalPowerUps'] ?? 0,
      totalBombs: stats['totalBombs'] ?? 0,
      modesPlayed: saveData.playedModes.length,
      allUpgradesBought: _checkAllUpgrades(saveData),
      completedClassicNormal: _game.gameMode == GameMode.classic &&
          _game.difficulty == Difficulty.normal &&
          _game.waveSystem.currentWave >= 50,
      completedClassicHard: _game.gameMode == GameMode.classic &&
          _game.difficulty == Difficulty.hard &&
          _game.waveSystem.currentWave >= 50,
      completedClassicNightmare: _game.gameMode == GameMode.classic &&
          _game.difficulty == Difficulty.nightmare &&
          _game.waveSystem.currentWave >= 50,
      bossRushWave: _game.gameMode == GameMode.bossRush
          ? _game.waveSystem.currentWave
          : 0,
      // Iter 13: nuovi achievement.
      sessionBosses: _game.sessionBossKills,
      gameMode: _game.gameMode,
      maxGateCombo: _game.maxGateCombo,
      gaussKills: stats['gaussKills'] ?? 0,
      chainKills: stats['chainKills'] ?? 0,
    );

    // Calculate and grant performance bonus gold
    int perfBonus = 0;
    if (_game.sessionKills >= 200) perfBonus += 50;
    if (_game.sessionKills >= 500) perfBonus += 100;
    if (_game.waveSystem.currentWave >= 20) perfBonus += 50;
    if (_game.waveSystem.currentWave >= 50) perfBonus += 150;
    if (_game.sessionBossKills >= 3) perfBonus += 100;
    if (_game.sessionBossKills >= 5) perfBonus += 200;
    saveData.goldGeoms += perfBonus;

    // Grant gold rewards for new achievements
    for (final achievement in _newAchievements) {
      saveData.goldGeoms += achievement.reward;
    }
    if (perfBonus > 0 || _newAchievements.isNotEmpty) {
      await SaveManager.save(saveData);
    }
  }

  bool _checkAllUpgrades(SaveData data) {
    const maxLevels = {
      'firepower': 5, 'speed': 5, 'fire_rate': 5,
      'shield_capacity': 3, 'starting_lives': 2, 'bomb_capacity': 2,
      'magnet_range': 3, 'xp_boost': 3,
    };
    for (final entry in maxLevels.entries) {
      if (data.getUpgradeLevel(entry.key) < entry.value) return false;
    }
    return true;
  }

  Future<void> _checkTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('tutorial_seen') ?? false;
    if (!seen && mounted) {
      setState(() => _showTutorial = true);
      _game.togglePause(); // Pausa durante il tutorial
    }
  }

  Future<void> _dismissTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tutorial_seen', true);
    if (!mounted) return;
    setState(() => _showTutorial = false);
    _game.togglePause(); // Riprendi il gioco
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Gate: il callback può arrivare durante dispose o prima del primo
    // frame → evito di toccare `_game` se lo State non è più montato.
    if (!mounted) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (_game.gameState == GameState.playing) {
        _game.pauseEngine();
        AudioSystem.stopAll();
      }
      // Pausa la musica BGM quando l'app va in background (preserva posizione)
      unawaited(MusicManager.pause());
    } else if (state == AppLifecycleState.resumed) {
      // Non auto-resume del gioco: l'utente deve riprendere manualmente
      // dalla pausa UI. Ma:
      //   - ricarica i pool SFX (`stopAll()` li ha disposed su paused) così
      //     i suoni di gioco tornano attivi al riprendere del gameplay;
      //   - riprendi la musica (era in pausa) solo se non siamo su overlay
      //     game over (in GameOver la BGM deve restare silenziata).
      unawaited(AudioSystem.init());
      if (!_showGameOver) {
        unawaited(MusicManager.resume());
      }
    } else if (state == AppLifecycleState.detached) {
      // App in chiusura: flush + chiusura box Hive per rilasciare il file
      // handle. Hive flusha già su ogni put(), quindi non c'è data-loss,
      // ma close() è buona pratica.
      unawaited(SaveManager.close());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fadeTimer?.cancel();
    // Ferma il motore Flame e l'audio quando si esce dalla schermata
    // per evitare che suoni/vibrazioni continuino in background.
    _game.pauseEngine();
    _game.onGameOver = null;
    _game.onPause = null;
    AudioSystem.stopAll();
    // ITER 3 FIX (utente: "torno nel menù la musica non parte"):
    // dispose NON tocca più la musica. Race precedenti:
    //   v1) pause() unawaited → completa DOPO playIntro+play del menu
    //       → pausa l'intro appena partito → silenzio.
    //   v2) stop() unawaited → idem, stop ritardato uccide intro
    //       appena partito → silenzio.
    //   v3) dispose silent → main_menu.initState → playIntro (sempre
    //       stop+play su mode change). Il bgm continua per la durata
    //       della AnimatedSwitcher transition (~350ms) e poi viene
    //       sostituito atomicamente da playIntro.
    // Trade-off: bgm udibile durante transition fade, accettabile vs
    // silenzio totale al menu.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: ColoredBox(
        color: Colors.black,
        child: Stack(
          children: [
          // Safety net: background nero pieno dietro GameWidget.
          // ColoredBox + SizedBox.expand → garantito full-size (Container
          // color-only può avere size indeterminata in alcune configurazioni).
          const Positioned.fill(
            child: SizedBox.expand(
              child: ColoredBox(color: Colors.black),
            ),
          ),

          // === GAME ENGINE ===
          // Key cambia ad ogni restart → Flutter distrugge il vecchio GameWidget
          // e ne crea uno nuovo, garantendo pulizia completa dello stato Flame.
          // Wrap ColoredBox esterno: forza background nero anche se Flame
          // avesse un white flash prima del primo render di SpaceBackground.
          Positioned.fill(
            child: ColoredBox(
              color: Colors.black,
              child: GameWidget(
                key: ValueKey(_gameKey),
                game: _game,
                loadingBuilder: (context) => const SizedBox.expand(
                  child: ColoredBox(color: Colors.black),
                ),
                backgroundBuilder: (context) => const SizedBox.expand(
                  child: ColoredBox(color: Colors.black),
                ),
              ),
            ),
          ),

          // === JOYSTICK VISUALI (dual-stick) ===
          _buildDualJoysticks(),

          // === HUD OVERLAY ===
          GameHud(game: _game),

          // === PULSANTE BOMBA (lato destro, sopra il joystick aim) ===
          // bottom alzato di ~50px così il pollice destro arriva senza ostacolo
          // dal joystick aim (richiesta utente — bomba prima inarrivabile).
          // Pacifist: nessun bottone bomba (regola GW2 Pacifism — 0 bombe).
          if (!_game.isPacifistMode)
            Positioned(
              bottom: 140,
              right: 20,
              child: _BombButton(onPressed: () => _game.bombPressed = true),
            ),

          // === PULSANTE PAUSA (lato destro, sopra il tasto bomba) ===
          Positioned(
            bottom: 215,
            right: 24,
            child: _PauseButton(onPressed: () {
              if (!_showPause && !_showGameOver) {
                _game.togglePause();
                setState(() => _showPause = true);
              }
            }),
          ),

          // === OVERLAY PAUSA ===
          if (_showPause)
            PauseScreen(
              onResume: () {
                setState(() => _showPause = false);
                _game.togglePause();
              },
              onQuit: () {
                _game.saveSessionData();
                unawaited(_saveLeaderboard());
                widget.onQuit();
              },
            ),

          // === TUTORIAL PRIMO AVVIO ===
          if (_showTutorial)
            TutorialOverlay(onDismiss: _dismissTutorial),

          // === OVERLAY GAME OVER ===
          if (_showGameOver)
            GameOverScreen(
              score: _game.scoreSystem.score,
              wave: _game.waveSystem.currentWave,
              geoms: _game.sessionGeoms,
              goldEarned: (_game.sessionGeoms / geomToGoldRatio).round(),
              kills: _game.sessionKills,
              bossKills: _game.sessionBossKills,
              newAchievements: _newAchievements,
              onRetry: () {
                // Ferma il vecchio gioco e l'audio
                _game.pauseEngine();
                _game.onGameOver = null;
                _game.onPause = null;
                AudioSystem.stopAll();
                // Crea un gioco NUOVO da zero — niente leak di stato Flame
                _initGame();
                setState(() {
                  _showGameOver = false;
                  _leaderboardSaved = false;
                  _newAchievements = [];
                  _gameKey++; // Forza ricostruzione GameWidget
                  _fadeOverlayOpacity = 1.0; // Reset overlay
                });
                // Dissolvi overlay dopo init nuovo GameWidget (cancellabile).
                _fadeTimer?.cancel();
                _fadeTimer = Timer(const Duration(milliseconds: 300), () {
                  if (mounted) setState(() => _fadeOverlayOpacity = 0.0);
                });
              },
              onQuit: widget.onQuit,
            ),

          // === OVERLAY NERO anti-flash (si dissolve in 300ms dopo l'init) ===
          // BUG FIX: Container(color: black) senza Positioned.fill in Stack
          // ha size zero (nessun child + nessuna size) → overlay non copriva
          // nulla, flash bianco frame iniziali GameWidget visibile.
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: _fadeOverlayOpacity,
                duration: const Duration(milliseconds: 250),
                child: const SizedBox.expand(
                  child: ColoredBox(color: Colors.black),
                ),
              ),
            ),
          ),
          ],
        ),
      ),
    );
  }

  /// Costruisce i due joystick visuali: movimento (sinistra) e mira (destra)
  Widget _buildDualJoysticks() {
    return Row(
      children: [
        // === JOYSTICK SINISTRO - MOVIMENTO ===
        Expanded(
          child: VirtualJoystick(
            color: const Color(0xFF00FFFF), // Cyan neon
            label: 'MOVE',
            radius: 55,
            onStart: () {
              _game.usingTouchMove = true;
            },
            onMove: (direction) {
              _game.moveInput.x = direction.dx;
              _game.moveInput.y = direction.dy;
            },
            onRelease: () {
              _game.moveInput = Vector2.zero();
              _game.usingTouchMove = false;
            },
          ),
        ),
        // === JOYSTICK DESTRO - MIRA/SPARO ===
        Expanded(
          child: VirtualJoystick(
            color: const Color(0xFFFF4444), // Rosso neon
            label: 'AIM',
            radius: 55,
            onStart: () {
              _game.isShooting = true;
              _game.usingTouchAim = true;
            },
            onMove: (direction) {
              _game.aimInput.x = direction.dx;
              _game.aimInput.y = direction.dy;
            },
            onRelease: () {
              _game.isShooting = false;
              _game.aimInput = Vector2.zero();
              _game.usingTouchAim = false;
            },
          ),
        ),
      ],
    );
  }
}

/// Pulsante bomba con effetto neon rosso pulsante
class _BombButton extends StatefulWidget {
  final VoidCallback onPressed;
  const _BombButton({required this.onPressed});

  @override
  State<_BombButton> createState() => _BombButtonState();
}

class _BombButtonState extends State<_BombButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NeonAnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final glowIntensity = 0.2 + _controller.value * 0.15;
        return GestureDetector(
          onTap: widget.onPressed,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.redAccent.withValues(alpha: 0.7),
                width: 2,
              ),
              gradient: RadialGradient(
                colors: [
                  Colors.red.withValues(alpha: glowIntensity),
                  Colors.red.withValues(alpha: 0.05),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.redAccent.withValues(alpha: glowIntensity),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.flash_on, color: Colors.redAccent, size: 26),
            ),
          ),
        );
      },
    );
  }
}

/// Pulsante pausa stilizzato con glow neon
class _PauseButton extends StatefulWidget {
  final VoidCallback onPressed;
  const _PauseButton({required this.onPressed});

  @override
  State<_PauseButton> createState() => _PauseButtonState();
}

class _PauseButtonState extends State<_PauseButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, _) {
        final glow = _glowController.value;
        return GestureDetector(
          onTap: widget.onPressed,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.cyanAccent.withValues(alpha: 0.3 + glow * 0.15),
                width: 1.5,
              ),
              gradient: RadialGradient(
                colors: [
                  Colors.cyanAccent.withValues(alpha: 0.08 + glow * 0.04),
                  Colors.cyanAccent.withValues(alpha: 0.02),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.cyanAccent.withValues(alpha: 0.1 + glow * 0.05),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.pause_rounded,
                color: Colors.cyanAccent.withValues(alpha: 0.6 + glow * 0.2),
                size: 20,
              ),
            ),
          ),
        );
      },
    );
  }
}

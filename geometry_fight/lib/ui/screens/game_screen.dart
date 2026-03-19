import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../../data/difficulty.dart';
import '../../data/leaderboard.dart';
import '../../game/game_world.dart';
import '../hud.dart';
import '../widgets/animated_builder_widget.dart';
import '../widgets/virtual_joystick.dart';
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

class _GameScreenState extends State<GameScreen> {
  late GeometryFightGame _game;
  bool _showPause = false;
  bool _showGameOver = false;

  @override
  void initState() {
    super.initState();
    _game = GeometryFightGame(
      difficulty: widget.difficulty,
      gameMode: widget.gameMode,
    );
    _game.onGameOver = () {
      // Salva nella leaderboard
      LeaderboardManager.addEntry(LeaderboardEntry(
        mode: widget.gameMode.name,
        difficulty: widget.difficulty.name,
        score: _game.scoreSystem.score,
        wave: _game.waveSystem.currentWave,
        kills: _game.sessionKills,
        date: DateTime.now(),
      ));
      setState(() => _showGameOver = true);
    };
    _game.onPause = () {
      setState(() => _showPause = true);
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // === GAME ENGINE ===
          GameWidget(game: _game),

          // === JOYSTICK VISUALI (dual-stick) ===
          _buildDualJoysticks(),

          // === HUD OVERLAY ===
          GameHud(game: _game),

          // === PULSANTE BOMBA (vicino al joystick destro, in basso a destra) ===
          Positioned(
            bottom: 80,
            right: MediaQuery.of(context).size.width * 0.25 - 28,
            child: _BombButton(onPressed: () => _game.bombPressed = true),
          ),

          // === PULSANTE PAUSA (in alto al centro, non sovrapposto alle vite) ===
          Positioned(
            top: MediaQuery.of(context).padding.top + 4,
            left: 0,
            right: 0,
            child: Center(
              child: _PauseButton(onPressed: () {
                _game.togglePause();
                setState(() => _showPause = true);
              }),
            ),
          ),

          // === OVERLAY PAUSA ===
          if (_showPause)
            PauseScreen(
              onResume: () {
                setState(() => _showPause = false);
                _game.togglePause();
              },
              onQuit: widget.onQuit,
            ),

          // === OVERLAY GAME OVER ===
          if (_showGameOver)
            GameOverScreen(
              score: _game.scoreSystem.score,
              wave: _game.waveSystem.currentWave,
              geoms: _game.sessionGeoms,
              goldEarned: (_game.sessionGeoms / 10).round(),
              onRetry: () {
                setState(() => _showGameOver = false);
                _game.restartGame();
              },
              onQuit: widget.onQuit,
            ),
        ],
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
              _game.aimInput = Vector2.zero();
              _game.isShooting = false;
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

/// Pulsante pausa stilizzato
class _PauseButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _PauseButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24, width: 1),
          color: Colors.white.withValues(alpha: 0.05),
        ),
        child: const Center(
          child: Icon(Icons.pause, color: Colors.white38, size: 20),
        ),
      ),
    );
  }
}

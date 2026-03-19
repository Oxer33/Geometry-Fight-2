import 'dart:math' as math;
import 'package:flame/components.dart' show Vector2;
import 'package:flutter/material.dart';
import '../game/game_world.dart';
import '../game/entities/enemies/enemy_base.dart';
import '../game/entities/bosses/boss_base.dart';
import 'widgets/animated_builder_widget.dart';

/// HUD moderna e accattivante con effetti glassmorphism neon.
/// Mostra: score, moltiplicatore, vite, bombe, geomi, wave, combo,
/// power-up attivi, e barra HP boss durante le boss fight.
class GameHud extends StatelessWidget {
  final GeometryFightGame game;

  const GameHud({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: NeonAnimatedBuilder(
        animation: _GameNotifier(game),
        builder: (context, _) {
          final topPad = MediaQuery.of(context).padding.top + 8;
          return Stack(
            children: [
              // === PANNELLO SCORE (top-left) con glassmorphism ===
              Positioned(
                top: topPad,
                left: 12,
                child: _ScorePanel(
                  score: game.scoreSystem.score,
                  multiplier: game.scoreSystem.multiplier,
                  hasDoubleMultiplier: game.scoreSystem.hasDoubleMultiplier,
                ),
              ),

              // === PANNELLO STATUS (top-right): vite, bombe, geomi ===
              Positioned(
                top: topPad,
                right: 12,
                child: _StatusPanel(
                  lives: game.player.lives,
                  bombs: game.player.bombs,
                  geoms: game.scoreSystem.geoms,
                  hasShield: game.player.hasShield,
                ),
              ),

              // === WAVE INDICATOR (top-center) ===
              Positioned(
                top: topPad,
                left: 0,
                right: 0,
                child: Center(
                  child: _WaveIndicator(
                    wave: game.waveSystem.currentWave,
                    enemyCount: game.enemyCount,
                  ),
                ),
              ),

              // === TIMER TIME ATTACK (sotto wave indicator) ===
              if (game.isTimeAttackMode)
                Positioned(
                  top: topPad + 24,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: (game.timeAttackTimer < 30
                            ? Colors.red : Colors.cyanAccent).withValues(alpha: 0.1),
                        border: Border.all(
                          color: (game.timeAttackTimer < 30
                              ? Colors.red : Colors.cyanAccent).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        '⏱ ${_formatTime(game.timeAttackTimer)}',
                        style: TextStyle(
                          color: game.timeAttackTimer < 30
                              ? Colors.redAccent
                              : Colors.cyanAccent,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'monospace',
                          letterSpacing: 2,
                          shadows: [
                            Shadow(
                              color: game.timeAttackTimer < 30
                                  ? Colors.red : Colors.cyanAccent,
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              // === BARRA HP BOSS (centro, sotto wave indicator) ===
              if (game.activeBoss != null)
                Positioned(
                  top: topPad + 28,
                  left: MediaQuery.of(context).size.width * 0.2,
                  right: MediaQuery.of(context).size.width * 0.2,
                  child: _BossHpBar(
                    bossName: game.activeBoss!.bossName,
                    healthPercent: game.activeBoss!.healthPercent,
                    bossColor: game.activeBoss!.neonColor,
                  ),
                ),

              // === COMBO POPUP (centro schermo) ===
              if (game.scoreSystem.showingCombo)
                Center(
                  child: _ComboPopup(
                    comboCount: game.scoreSystem.comboCount,
                  ),
                ),

              // === POWER-UP ATTIVI (sotto score, a sinistra) ===
              if (_hasActivePowerUps())
                Positioned(
                  top: topPad + 70,
                  left: 12,
                  child: _PowerUpBar(player: game.player),
                ),

              // === PERFECT WAVE! (centro schermo) ===
              if (game.showPerfectWave)
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 60),
                      Text(
                        'PERFECT WAVE!',
                        style: TextStyle(
                          color: const Color(0xFF00FF88),
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'monospace',
                          letterSpacing: 4,
                          shadows: [
                            const Shadow(color: Color(0xFF00FF88), blurRadius: 16),
                            Shadow(color: const Color(0xFF00FF88).withValues(alpha: 0.5), blurRadius: 32),
                          ],
                        ),
                      ),
                      Text(
                        '+50 GEOMI BONUS',
                        style: TextStyle(
                          color: const Color(0xFF00FF88).withValues(alpha: 0.6),
                          fontSize: 12,
                          fontFamily: 'monospace',
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),

              // === FLASH ROSSO QUANDO COLPITO ===
              if (game.hitFlashTimer > 0)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      color: Colors.red.withValues(alpha: game.hitFlashTimer * 0.5),
                    ),
                  ),
                ),

              // === FRECCE NEMICI FUORI SCHERMO ===
              _OffscreenEnemyArrows(game: game),

              // === NEMICI RIMANENTI (mini-bar in basso al centro) ===
              Positioned(
                bottom: 8,
                left: 0,
                right: 0,
                child: Center(
                  child: _EnemyCounter(count: game.enemyCount),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatTime(double seconds) {
    final mins = (seconds / 60).floor();
    final secs = (seconds % 60).floor();
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  bool _hasActivePowerUps() {
    return game.player.rapidFireTimer > 0 ||
        game.player.overdriveTimer > 0 ||
        game.player.magnetTimer > 0 ||
        game.player.weaponTimer > 0 ||
        game.player.timeSlowTimer > 0;
  }
}

// ===================================================================
// PANNELLO SCORE - Glassmorphism con glow neon
// ===================================================================
class _ScorePanel extends StatelessWidget {
  final int score;
  final double multiplier;
  final bool hasDoubleMultiplier;

  const _ScorePanel({
    required this.score,
    required this.multiplier,
    required this.hasDoubleMultiplier,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Score principale con glow dinamico
          Text(
            _formatScore(score),
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
              letterSpacing: 1.5,
              shadows: [
                Shadow(
                  color: _getScoreGlowColor(),
                  blurRadius: 12,
                ),
                Shadow(
                  color: _getScoreGlowColor().withValues(alpha: 0.5),
                  blurRadius: 24,
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          // Riga moltiplicatore
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _MultiplierBadge(multiplier: multiplier),
              if (hasDoubleMultiplier) ...[
                const SizedBox(width: 6),
                _GlowBadge(
                  text: '2x BOOST',
                  color: const Color(0xFFFFD700),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Color _getScoreGlowColor() {
    if (score > 100000) return const Color(0xFFFF00FF);
    if (score > 50000) return const Color(0xFFFFD700);
    if (score > 10000) return const Color(0xFF00FFFF);
    return const Color(0xFF4488FF);
  }

  String _formatScore(int s) {
    if (s >= 1000000) return '${(s / 1000000).toStringAsFixed(1)}M';
    if (s >= 1000) return '${(s / 1000).toStringAsFixed(1)}K';
    return '$s';
  }
}

// ===================================================================
// BADGE MOLTIPLICATORE - Cambia colore in base al valore
// ===================================================================
class _MultiplierBadge extends StatelessWidget {
  final double multiplier;

  const _MultiplierBadge({required this.multiplier});

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
        color: color.withValues(alpha: 0.1),
      ),
      child: Text(
        'x${multiplier.toStringAsFixed(1)}',
        style: TextStyle(
          color: color,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
          shadows: [Shadow(color: color, blurRadius: 6)],
        ),
      ),
    );
  }

  Color _getColor() {
    if (multiplier >= 15) return const Color(0xFFFF2244);
    if (multiplier >= 10) return const Color(0xFFFF6600);
    if (multiplier >= 5) return const Color(0xFFFFD700);
    if (multiplier >= 2) return const Color(0xFF00FFAA);
    return const Color(0xFF8899AA);
  }
}

// ===================================================================
// PANNELLO STATUS - Vite, bombe, geomi con icone neon
// ===================================================================
class _StatusPanel extends StatelessWidget {
  final int lives;
  final int bombs;
  final int geoms;
  final bool hasShield;

  const _StatusPanel({
    required this.lives,
    required this.bombs,
    required this.geoms,
    required this.hasShield,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Vite con icone triangolo (come la nave del player)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasShield)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(
                    Icons.shield,
                    color: Colors.cyanAccent.withValues(alpha: 0.8),
                    size: 14,
                  ),
                ),
              ...List.generate(
                lives,
                (i) => Padding(
                  padding: const EdgeInsets.only(left: 3),
                  child: CustomPaint(
                    size: const Size(12, 14),
                    painter: _LifeIconPainter(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Bombe con icone cerchio rosso
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              bombs,
              (i) => Padding(
                padding: const EdgeInsets.only(left: 3),
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.redAccent.withValues(alpha: 0.3),
                    border: Border.all(
                      color: Colors.redAccent.withValues(alpha: 0.7),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.redAccent.withValues(alpha: 0.3),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Geomi raccolti
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomPaint(
                size: const Size(12, 12),
                painter: _GeomIconPainter(),
              ),
              const SizedBox(width: 4),
              Text(
                '$geoms',
                style: TextStyle(
                  color: Colors.cyanAccent.withValues(alpha: 0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  shadows: [
                    Shadow(
                      color: Colors.cyanAccent.withValues(alpha: 0.5),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ===================================================================
// WAVE INDICATOR - Badge centrale stilizzato
// ===================================================================
class _WaveIndicator extends StatelessWidget {
  final int wave;
  final int enemyCount;

  const _WaveIndicator({required this.wave, required this.enemyCount});

  @override
  Widget build(BuildContext context) {
    final isBossWave = wave % 10 == 0;
    final color = isBossWave ? const Color(0xFFFF2244) : const Color(0xFF4488FF);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        color: color.withValues(alpha: 0.08),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isBossWave)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(Icons.warning_amber,
                  color: color.withValues(alpha: 0.8), size: 14),
            ),
          Text(
            isBossWave ? 'BOSS WAVE $wave' : 'WAVE $wave',
            style: TextStyle(
              color: color.withValues(alpha: 0.9),
              fontSize: 13,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              letterSpacing: 2,
              shadows: [
                Shadow(color: color.withValues(alpha: 0.5), blurRadius: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ===================================================================
// BARRA HP BOSS - Prominente durante le boss fight
// ===================================================================
class _BossHpBar extends StatelessWidget {
  final String bossName;
  final double healthPercent;
  final Color bossColor;

  const _BossHpBar({
    required this.bossName,
    required this.healthPercent,
    required this.bossColor,
  });

  @override
  Widget build(BuildContext context) {
    // Colore barra in base alla vita rimasta
    final barColor = healthPercent > 0.5
        ? bossColor
        : healthPercent > 0.25
            ? const Color(0xFFFFAA00)
            : const Color(0xFFFF2244);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Nome boss
        Text(
          bossName.toUpperCase(),
          style: TextStyle(
            color: barColor.withValues(alpha: 0.9),
            fontSize: 11,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            letterSpacing: 3,
            shadows: [Shadow(color: barColor, blurRadius: 8)],
          ),
        ),
        const SizedBox(height: 3),
        // Barra HP con glow
        SizedBox(
          height: 8,
          child: CustomPaint(
            size: const Size(double.infinity, 8),
            painter: _BossHpBarPainter(
              progress: healthPercent.clamp(0.0, 1.0),
              color: barColor,
            ),
          ),
        ),
        const SizedBox(height: 2),
        // Percentuale HP
        Text(
          '${(healthPercent * 100).toInt()}%',
          style: TextStyle(
            color: barColor.withValues(alpha: 0.6),
            fontSize: 9,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}

/// Painter per la barra HP del boss con glow neon
class _BossHpBarPainter extends CustomPainter {
  final double progress;
  final Color color;

  _BossHpBarPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final radius = Radius.circular(4);

    // Background scuro
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        radius,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.08),
    );

    // Bordo esterno
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        radius,
      ),
      Paint()
        ..color = color.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Barra HP con glow
    final barWidth = size.width * progress;
    if (barWidth > 0) {
      // Glow
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, -2, barWidth, size.height + 4),
          radius,
        ),
        Paint()
          ..color = color.withValues(alpha: 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );

      // Barra piena
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, barWidth, size.height),
          radius,
        ),
        Paint()..color = color.withValues(alpha: 0.8),
      );

      // Highlight superiore
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(1, 1, barWidth - 2, size.height * 0.4),
          radius,
        ),
        Paint()..color = Colors.white.withValues(alpha: 0.15),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BossHpBarPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

// ===================================================================
// COMBO POPUP - Grande e luminoso al centro
// ===================================================================
class _ComboPopup extends StatelessWidget {
  final int comboCount;

  const _ComboPopup({required this.comboCount});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'COMBO',
          style: TextStyle(
            color: const Color(0xFFFFD700).withValues(alpha: 0.7),
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            letterSpacing: 6,
          ),
        ),
        Text(
          'x$comboCount',
          style: const TextStyle(
            color: Color(0xFFFFD700),
            fontSize: 42,
            fontWeight: FontWeight.w900,
            fontFamily: 'monospace',
            shadows: [
              Shadow(color: Color(0xFFFFD700), blurRadius: 20),
              Shadow(color: Color(0xFFFF8800), blurRadius: 40),
            ],
          ),
        ),
      ],
    );
  }
}

// ===================================================================
// POWER-UP BAR - Barre colorate con countdown
// ===================================================================
class _PowerUpBar extends StatelessWidget {
  final dynamic player;

  const _PowerUpBar({required this.player});

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];

    if (player.rapidFireTimer > 0) {
      items.add(_NeonPowerUpIndicator(
        label: 'RAPID FIRE',
        icon: Icons.speed,
        color: const Color(0xFFFF4400),
        remaining: player.rapidFireTimer / 15,
      ));
    }
    if (player.overdriveTimer > 0) {
      items.add(_NeonPowerUpIndicator(
        label: 'OVERDRIVE',
        icon: Icons.flash_on,
        color: const Color(0xFFFFFFFF),
        remaining: player.overdriveTimer / 15,
      ));
    }
    if (player.magnetTimer > 0) {
      items.add(_NeonPowerUpIndicator(
        label: 'MAGNET',
        icon: Icons.all_inclusive,
        color: const Color(0xFFFFEE00),
        remaining: player.magnetTimer / 15,
      ));
    }
    if (player.timeSlowTimer > 0) {
      items.add(_NeonPowerUpIndicator(
        label: 'TIME SLOW',
        icon: Icons.hourglass_bottom,
        color: const Color(0xFFAA00FF),
        remaining: player.timeSlowTimer / 15,
      ));
    }
    if (player.weaponTimer > 0) {
      items.add(_NeonPowerUpIndicator(
        label: 'WEAPON',
        icon: Icons.gps_fixed,
        color: const Color(0xFFFF8800),
        remaining: player.weaponTimer / 15,
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items,
    );
  }
}

// ===================================================================
// SINGOLO INDICATORE POWER-UP - Barra neon con icona
// ===================================================================
class _NeonPowerUpIndicator extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final double remaining;

  const _NeonPowerUpIndicator({
    required this.label,
    required this.icon,
    required this.color,
    required this.remaining,
  });

  @override
  Widget build(BuildContext context) {
    final clampedRemaining = remaining.clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icona con glow
          Icon(icon, color: color.withValues(alpha: 0.8), size: 12),
          const SizedBox(width: 4),
          // Label
          SizedBox(
            width: 65,
            child: Text(
              label,
              style: TextStyle(
                color: color.withValues(alpha: 0.8),
                fontSize: 9,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                letterSpacing: 0.5,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          // Barra di progresso neon
          SizedBox(
            width: 50,
            height: 4,
            child: CustomPaint(
              painter: _NeonBarPainter(
                progress: clampedRemaining,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===================================================================
// CONTATORE NEMICI IN BASSO
// ===================================================================
class _EnemyCounter extends StatelessWidget {
  final int count;

  const _EnemyCounter({required this.count});

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 0.5,
        ),
      ),
      child: Text(
        '$count NEMICI',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.35),
          fontSize: 10,
          fontFamily: 'monospace',
          letterSpacing: 1,
        ),
      ),
    );
  }
}

// ===================================================================
// CONTAINER GLASSMORPHISM RIUTILIZZABILE
// ===================================================================
class _GlassContainer extends StatelessWidget {
  final Widget child;

  const _GlassContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.black.withValues(alpha: 0.35),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
          ),
        ],
      ),
      child: child,
    );
  }
}

// ===================================================================
// BADGE GLOW (es: "2x BOOST")
// ===================================================================
class _GlowBadge extends StatelessWidget {
  final String text;
  final Color color;

  const _GlowBadge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.5),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
          shadows: [Shadow(color: color, blurRadius: 4)],
        ),
      ),
    );
  }
}

// ===================================================================
// PAINTERS CUSTOM
// ===================================================================

/// Painter per l'icona vita (triangolo cyan come la nave)
class _LifeIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00FFFF).withValues(alpha: 0.8);
    final glowPaint = Paint()
      ..color = const Color(0xFF00FFFF).withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Painter per l'icona geom (diamante rotante)
class _GeomIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    final paint = Paint()
      ..color = const Color(0xFF00FFFF).withValues(alpha: 0.9);
    final glowPaint = Paint()
      ..color = const Color(0xFF00FFFF).withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final path = Path()
      ..moveTo(cx, cy - r)
      ..lineTo(cx + r * 0.6, cy)
      ..lineTo(cx, cy + r)
      ..lineTo(cx - r * 0.6, cy)
      ..close();

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Painter per la barra di progresso neon dei power-up
class _NeonBarPainter extends CustomPainter {
  final double progress;
  final Color color;

  _NeonBarPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    // Background scuro
    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(2),
      ),
      bgPaint,
    );

    // Barra di progresso con glow
    final barWidth = size.width * progress;
    if (barWidth > 0) {
      // Glow
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, -1, barWidth, size.height + 2),
          const Radius.circular(2),
        ),
        glowPaint,
      );

      // Barra
      final barPaint = Paint()..color = color.withValues(alpha: 0.8);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, barWidth, size.height),
          const Radius.circular(2),
        ),
        barPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _NeonBarPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

// ===================================================================
// GAME NOTIFIER - Triggera rebuild della HUD ogni 80ms
// ===================================================================
/// Frecce rosse ai margini dello schermo che indicano nemici fuori vista.
/// Mostra max 8 frecce per i nemici più vicini che sono fuori dall'area visibile.
class _OffscreenEnemyArrows extends StatelessWidget {
  final GeometryFightGame game;

  const _OffscreenEnemyArrows({required this.game});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: CustomPaint(
        painter: _ArrowPainter(game),
      ),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  final GeometryFightGame game;
  _ArrowPainter(this.game);

  @override
  void paint(Canvas canvas, Size size) {
    final playerPos = game.player.position;
    final camPos = game.camera.viewfinder.position;
    final halfW = size.width / 2;
    final halfH = size.height / 2;
    final margin = 20.0; // Distanza dal bordo

    // Raccogli nemici fuori schermo (max 8, i più vicini)
    final offscreen = <_EnemyDir>[];
    for (final child in game.world.children) {
      if (child is EnemyBase) {
        // Posizione relativa alla camera
        final rel = child.position - camPos;
        if (rel.x.abs() > halfW + 20 || rel.y.abs() > halfH + 20) {
          offscreen.add(_EnemyDir(
            direction: (child.position - playerPos).normalized(),
            distance: child.position.distanceTo(playerPos),
          ));
        }
      }
      if (child is BossBase) {
        final rel = child.position - camPos;
        if (rel.x.abs() > halfW + 40 || rel.y.abs() > halfH + 40) {
          offscreen.add(_EnemyDir(
            direction: (child.position - playerPos).normalized(),
            distance: child.position.distanceTo(playerPos),
            isBoss: true,
          ));
        }
      }
    }

    // Ordina per distanza e prendi max 8
    offscreen.sort((a, b) => a.distance.compareTo(b.distance));
    final arrows = offscreen.take(8);

    for (final enemy in arrows) {
      final dir = enemy.direction;
      // Calcola posizione della freccia sul bordo dello schermo
      double arrowX, arrowY;
      // Interseca il bordo dello schermo
      final scaleX = dir.x != 0 ? (halfW - margin) / dir.x.abs() : double.infinity;
      final scaleY = dir.y != 0 ? (halfH - margin) / dir.y.abs() : double.infinity;
      final scale = scaleX < scaleY ? scaleX : scaleY;
      arrowX = halfW + dir.x * scale;
      arrowY = halfH + dir.y * scale;

      // Clamp
      arrowX = arrowX.clamp(margin, size.width - margin);
      arrowY = arrowY.clamp(margin, size.height - margin);

      // Angolo della freccia: atan2 per puntare verso il nemico
      final angle = math.atan2(dir.y, dir.x) + math.pi / 2;

      // Disegna freccia
      final arrowSize = enemy.isBoss ? 10.0 : 7.0;
      final color = enemy.isBoss ? const Color(0xFFFFD700) : const Color(0xFFFF2244);
      final alpha = (1.0 - (enemy.distance / 1500).clamp(0.0, 0.7));

      canvas.save();
      canvas.translate(arrowX, arrowY);
      canvas.rotate(angle);

      // Glow
      final glowPaint = Paint()
        ..color = color.withValues(alpha: alpha * 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      final path = Path()
        ..moveTo(0, -arrowSize)
        ..lineTo(arrowSize * 0.6, arrowSize * 0.4)
        ..lineTo(-arrowSize * 0.6, arrowSize * 0.4)
        ..close();
      canvas.drawPath(path, glowPaint);

      // Freccia solida
      final paint = Paint()..color = color.withValues(alpha: alpha);
      canvas.drawPath(path, paint);

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ArrowPainter oldDelegate) => true;
}

class _EnemyDir {
  final Vector2 direction;
  final double distance;
  final bool isBoss;
  _EnemyDir({required this.direction, required this.distance, this.isBoss = false});
}

class _GameNotifier extends ChangeNotifier implements Listenable {
  final GeometryFightGame game;
  bool _disposed = false;

  _GameNotifier(this.game) {
    // Rebuild periodico per aggiornare la HUD
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 80));
      if (!_disposed) {
        notifyListeners();
      }
      return !_disposed;
    });
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

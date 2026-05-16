import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../data/achievements.dart';
import '../../data/save_data.dart';
import '../../game/systems/music_manager.dart';
import '../widgets/animated_builder_widget.dart';

/// Menu principale con effetti neon cinematografici.
/// Entrance staggered, scanline, glitch title, particelle con trail,
/// bottone GIOCA con bordo animato, griglia bottoni con glow.
class MainMenuScreen extends StatefulWidget {
  final VoidCallback onPlay;
  final VoidCallback onShop;
  final VoidCallback onSettings;
  final VoidCallback? onLeaderboard;
  final VoidCallback? onStats;
  final VoidCallback? onAchievements;

  const MainMenuScreen({
    super.key,
    required this.onPlay,
    required this.onShop,
    required this.onSettings,
    this.onLeaderboard,
    this.onStats,
    this.onAchievements,
  });

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen>
    with TickerProviderStateMixin {
  late AnimationController _bgController;
  late AnimationController _entranceController;
  late AnimationController _pulseController;
  late AnimationController _particleController;
  late AnimationController _scanlineController;
  late AnimationController _borderController;
  late AnimationController _glitchController;

  // Stagger entrance
  late Animation<double> _titleFade;
  late Animation<Offset> _titleSlide;
  late Animation<double> _titleScale;
  late Animation<double> _statsFade;
  late Animation<double> _playFade;
  late Animation<Offset> _playSlide;
  late Animation<double> _gridFade;
  late Animation<Offset> _gridSlide;
  late Animation<double> _settingsFade;

  late SaveData _saveData;

  @override
  void initState() {
    super.initState();
    _saveData = SaveManager.load();

    // Daily reward (utente: "daily reward che dà +100 geom"). Mostra dialog
    // post-frame se claim disponibile (data oggi != lastDailyClaim).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowDailyReward();
    });

    // Garantisce che la musica intro stia suonando ogni volta che si torna
    // al main menu (es. dopo game over). Idempotente se già in modalità intro.
    unawaited(MusicManager.playIntro());

    _bgController = AnimationController(
      vsync: this, duration: const Duration(seconds: 20),
    )..repeat();

    _particleController = AnimationController(
      vsync: this, duration: const Duration(seconds: 30),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _scanlineController = AnimationController(
      vsync: this, duration: const Duration(seconds: 4),
    )..repeat();

    _borderController = AnimationController(
      vsync: this, duration: const Duration(seconds: 3),
    )..repeat();

    _glitchController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 4000),
    )..repeat();

    _entranceController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2200),
    );

    // Stagger con timing cinematografico
    _titleFade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: const Interval(0.0, 0.3, curve: Curves.easeOut)),
    );
    _titleSlide = Tween(begin: const Offset(0, -0.5), end: Offset.zero).animate(
      CurvedAnimation(parent: _entranceController, curve: const Interval(0.0, 0.35, curve: Curves.easeOutBack)),
    );
    _titleScale = Tween(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: const Interval(0.0, 0.35, curve: Curves.easeOutBack)),
    );
    _statsFade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: const Interval(0.2, 0.5, curve: Curves.easeOut)),
    );
    _playFade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: const Interval(0.35, 0.65, curve: Curves.easeOut)),
    );
    _playSlide = Tween(begin: const Offset(0.4, 0), end: Offset.zero).animate(
      CurvedAnimation(parent: _entranceController, curve: const Interval(0.35, 0.65, curve: Curves.easeOutCubic)),
    );
    _gridFade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: const Interval(0.5, 0.8, curve: Curves.easeOut)),
    );
    _gridSlide = Tween(begin: const Offset(0.3, 0), end: Offset.zero).animate(
      CurvedAnimation(parent: _entranceController, curve: const Interval(0.5, 0.8, curve: Curves.easeOutCubic)),
    );
    _settingsFade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: const Interval(0.7, 1.0, curve: Curves.easeOut)),
    );

    _entranceController.forward();
  }

  @override
  void dispose() {
    _bgController.dispose();
    _entranceController.dispose();
    _pulseController.dispose();
    _particleController.dispose();
    _scanlineController.dispose();
    _borderController.dispose();
    _glitchController.dispose();
    super.dispose();
  }

  /// Mostra dialog daily reward se claim disponibile (oggi != lastDailyClaim).
  /// Auto-claim su tap "RISCATTA" → +100 geom + streak update + save.
  Future<void> _maybeShowDailyReward() async {
    if (!mounted) return;
    if (!_saveData.canClaimDailyReward()) return;
    final reward = _saveData.claimDailyReward();
    if (reward == 0) return;
    await SaveManager.save(_saveData);
    if (!mounted) return;
    // Iter 13 (caveman-review): rebuild necessario per refresh badge
    // gold counter dopo `goldGeoms += kDailyRewardAmount`. Body vuoto
    // perché `_saveData` mutato in-place — basta re-render.
    setState(() {});
    final streak = _saveData.dailyStreak;
    // Track streak achievement
    AchievementManager.updateProgress('daily_streak_7', streak);
    AchievementManager.updateProgress('daily_streak_30', streak);
    unawaited(showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0A0A14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFFFD700), width: 2),
        ),
        title: const Text(
          'DAILY REWARD',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFFFFD700),
            fontWeight: FontWeight.w900,
            fontFamily: 'monospace',
            letterSpacing: 4,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.diamond, color: Color(0xFFFFD700), size: 48),
            const SizedBox(height: 12),
            Text(
              '+$reward GEOM',
              style: const TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 28,
                fontWeight: FontWeight.w900,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Streak: $streak ${streak == 1 ? "giorno" : "giorni"}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'CONTINUA',
              style: TextStyle(
                color: Color(0xFFFFD700),
                fontWeight: FontWeight.w900,
                fontFamily: 'monospace',
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      ),
    ));
  }

  String _formatNumber(int n) {
    if (n >= 1000000000) { return '${(n / 1000000000).toStringAsFixed(1)}B'; }
    if (n >= 1000000) { return '${(n / 1000000).toStringAsFixed(1)}M'; }
    if (n >= 1000) { return '${(n / 1000).toStringAsFixed(1)}K'; }
    return n.toString();
  }

  String _formatTime(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) { return '${h}h ${m}m'; }
    return '${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isLandscape = screenSize.width > screenSize.height;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // === DEEP SPACE BACKGROUND ===
          NeonAnimatedBuilder(
            animation: _bgController,
            builder: (context, _) => CustomPaint(
              painter: _DeepSpaceBackgroundPainter(_bgController.value),
              size: screenSize,
            ),
          ),

          // === FLOATING PARTICLES CON TRAIL ===
          NeonAnimatedBuilder(
            animation: _particleController,
            builder: (context, _) => CustomPaint(
              painter: _NeonParticlesPainter(_particleController.value),
              size: screenSize,
            ),
          ),

          // === SCANLINE OVERLAY ===
          NeonAnimatedBuilder(
            animation: _scanlineController,
            builder: (context, _) => CustomPaint(
              painter: _ScanlinePainter(_scanlineController.value),
              size: screenSize,
            ),
          ),

          // === CONTENUTO ===
          SafeArea(
            child: AnimatedBuilder(
              animation: _entranceController,
              builder: (context, _) => isLandscape
                  ? _buildLandscapeLayout(screenSize)
                  : _buildPortraitLayout(screenSize),
            ),
          ),

          // === VIGNETTE OVERLAY ===
          IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.3),
                    Colors.black.withValues(alpha: 0.7),
                  ],
                  stops: const [0.3, 0.7, 1.0],
                ),
              ),
            ),
          ),

          // === VERSIONE ===
          Positioned(
            bottom: 8, right: 12,
            child: FadeTransition(
              opacity: _settingsFade,
              child: Text(
                'v2.0',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.12),
                  fontSize: 10, fontFamily: 'monospace',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== LAYOUT ====================

  Widget _buildLandscapeLayout(Size screenSize) {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SlideTransition(
                position: _titleSlide,
                child: FadeTransition(
                  opacity: _titleFade,
                  child: ScaleTransition(
                    scale: _titleScale,
                    child: _buildTitle(),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              FadeTransition(
                opacity: _statsFade,
                child: _buildStatsBar(),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 4,
          child: _buildRightPanel(),
        ),
      ],
    );
  }

  Widget _buildPortraitLayout(Size screenSize) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 30),
            SlideTransition(
              position: _titleSlide,
              child: FadeTransition(
                opacity: _titleFade,
                child: ScaleTransition(
                  scale: _titleScale,
                  child: _buildTitle(),
                ),
              ),
            ),
            const SizedBox(height: 20),
            FadeTransition(opacity: _statsFade, child: _buildStatsBar()),
            const SizedBox(height: 30),
            _buildRightPanel(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ==================== TITLE ====================

  Widget _buildTitle() {
    return NeonAnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        final pulse = _pulseController.value;
        final glow = 10 + pulse * 16;

        // Micro glitch: shift orizzontale per 2 frame ogni ~4s
        final glitchPhase = _glitchController.value;
        final isGlitch = glitchPhase > 0.92 && glitchPhase < 0.94;
        final glitchOffset = isGlitch ? (math.Random().nextDouble() - 0.5) * 4 : 0.0;

        return Transform.translate(
          offset: Offset(glitchOffset, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // === GEOMETRY ===
              _glitchText(
                'GEOMETRY',
                fontSize: 30,
                letterSpacing: 10,
                glow: glow,
                isGlitch: isGlitch,
              ),
              const SizedBox(height: 2),

              // === FIGHT 2 ===
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  _glitchText(
                    'FIGHT',
                    fontSize: 54,
                    letterSpacing: 16,
                    glow: glow,
                    isGlitch: isGlitch,
                  ),
                  const SizedBox(width: 8),
                  // "2" con gradiente animato cyan→magenta
                  NeonAnimatedBuilder(
                    animation: _borderController,
                    builder: (context, _) {
                      final hue = _borderController.value * 360;
                      return ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            HSVColor.fromAHSV(1, hue % 360, 0.8, 1).toColor(),
                            HSVColor.fromAHSV(1, (hue + 120) % 360, 0.9, 1).toColor(),
                          ],
                        ).createShader(bounds),
                        child: Text(
                          '2',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 70,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'monospace',
                            shadows: [
                              Shadow(
                                color: HSVColor.fromAHSV(0.6, hue % 360, 1, 1).toColor(),
                                blurRadius: glow * 2,
                              ),
                              Shadow(
                                color: Colors.cyanAccent.withValues(alpha: 0.3),
                                blurRadius: glow * 3,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // === LINEA DECORATIVA ANIMATA ===
              NeonAnimatedBuilder(
                animation: _borderController,
                builder: (context, _) {
                  return CustomPaint(
                    size: const Size(220, 2),
                    painter: _AnimatedLinePainter(
                      _borderController.value,
                      Colors.cyanAccent,
                    ),
                  );
                },
              ),

              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _glitchText(String text, {
    required double fontSize,
    required double letterSpacing,
    required double glow,
    required bool isGlitch,
  }) {
    final baseStyle = TextStyle(
      color: Colors.cyanAccent,
      fontSize: fontSize,
      fontWeight: FontWeight.w900,
      fontFamily: 'monospace',
      letterSpacing: letterSpacing,
      shadows: [
        Shadow(color: Colors.cyanAccent, blurRadius: glow),
        Shadow(color: Colors.cyanAccent.withValues(alpha: 0.4), blurRadius: glow * 2.5),
      ],
    );

    if (!isGlitch) {
      return Text(text, textAlign: TextAlign.center, style: baseStyle);
    }

    // Glitch: RGB split
    return Stack(
      children: [
        // Red channel shifted
        Transform.translate(
          offset: const Offset(-2, 0),
          child: Text(
            text, textAlign: TextAlign.center,
            style: baseStyle.copyWith(
              color: Colors.redAccent.withValues(alpha: 0.7),
              shadows: [],
            ),
          ),
        ),
        // Blue channel shifted
        Transform.translate(
          offset: const Offset(2, 0),
          child: Text(
            text, textAlign: TextAlign.center,
            style: baseStyle.copyWith(
              color: Colors.blueAccent.withValues(alpha: 0.7),
              shadows: [],
            ),
          ),
        ),
        // Main
        Text(text, textAlign: TextAlign.center, style: baseStyle),
      ],
    );
  }

  // ==================== STATS BAR ====================

  Widget _buildStatsBar() {
    final totalKills = _saveData.stats['totalKills'] ?? 0;
    final bestScore = _saveData.highscores.values.fold<int>(0, (a, b) => a > b ? a : b);
    final gold = _saveData.goldGeoms;
    final playtime = _saveData.totalPlaytime;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.02),
            Colors.cyanAccent.withValues(alpha: 0.01),
            Colors.white.withValues(alpha: 0.02),
          ],
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StatChip(icon: Icons.hexagon_outlined, value: _formatNumber(gold),
              color: const Color(0xFFFFD700), label: 'GEOMS'),
          _statDivider(),
          _StatChip(icon: Icons.emoji_events_outlined, value: _formatNumber(bestScore),
              color: Colors.cyanAccent, label: 'BEST'),
          _statDivider(),
          _StatChip(icon: Icons.track_changes, value: _formatNumber(totalKills),
              color: const Color(0xFFFF4466), label: 'KILLS'),
          _statDivider(),
          _StatChip(icon: Icons.timer_outlined, value: _formatTime(playtime),
              color: const Color(0xFF00FF88), label: 'TIME'),
        ],
      ),
    );
  }

  Widget _statDivider() => Container(
    width: 1, height: 28,
    margin: const EdgeInsets.symmetric(horizontal: 10),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          Colors.cyanAccent.withValues(alpha: 0.1),
          Colors.transparent,
        ],
      ),
    ),
  );

  // ==================== RIGHT PANEL ====================

  Widget _buildRightPanel() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // === BOTTONE GIOCA ===
        SlideTransition(
          position: _playSlide,
          child: FadeTransition(
            opacity: _playFade,
            child: _buildPlayButton(),
          ),
        ),
        const SizedBox(height: 22),

        // === GRIGLIA BOTTONI ===
        SlideTransition(
          position: _gridSlide,
          child: FadeTransition(
            opacity: _gridFade,
            child: _buildButtonGrid(),
          ),
        ),

        const SizedBox(height: 16),

        // === IMPOSTAZIONI ===
        FadeTransition(
          opacity: _settingsFade,
          child: _NeonSmallButton(
            text: 'IMPOSTAZIONI',
            icon: Icons.settings_outlined,
            color: Colors.white,
            onTap: widget.onSettings,
          ),
        ),
      ],
    );
  }

  Widget _buildPlayButton() {
    return NeonAnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        final pulse = _pulseController.value;
        final scale = 1.0 + pulse * 0.025;

        return GestureDetector(
          onTap: widget.onPlay,
          child: Transform.scale(
            scale: scale,
            child: // === ANIMATED BORDER (rotating gradient) ===
                NeonAnimatedBuilder(
                  animation: _borderController,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _AnimatedBorderPainter(
                        progress: _borderController.value,
                        borderRadius: 14,
                        strokeWidth: 2,
                        glowIntensity: pulse,
                      ),
                      child: Container(
                        width: 240,
                        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.cyanAccent.withValues(alpha: 0.06 + pulse * 0.04),
                              const Color(0xFFFF00AA).withValues(alpha: 0.02 + pulse * 0.02),
                              Colors.cyanAccent.withValues(alpha: 0.04 + pulse * 0.03),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.cyanAccent.withValues(alpha: 0.1 + pulse * 0.12),
                              blurRadius: 20 + pulse * 15,
                              spreadRadius: 2,
                            ),
                            BoxShadow(
                              color: const Color(0xFFFF00AA).withValues(alpha: 0.04 + pulse * 0.04),
                              blurRadius: 30 + pulse * 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.cyanAccent,
                              size: 30,
                              shadows: [
                                Shadow(color: Colors.cyanAccent, blurRadius: 10),
                              ],
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'GIOCA',
                              style: TextStyle(
                                color: Colors.cyanAccent,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'monospace',
                                letterSpacing: 8,
                                shadows: [
                                  const Shadow(color: Colors.cyanAccent, blurRadius: 10),
                                  Shadow(
                                    color: Colors.cyanAccent.withValues(alpha: 0.5),
                                    blurRadius: 20,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          ),
        );
      },
    );
  }

  Widget _buildButtonGrid() {
    final buttons = <Widget>[
      _NeonMenuButton(
        text: 'NEGOZIO',
        icon: Icons.storefront_outlined,
        color: const Color(0xFFFFD700),
        onTap: widget.onShop,
        badge: _saveData.goldGeoms > 0 ? _formatNumber(_saveData.goldGeoms) : null,
      ),
      if (widget.onLeaderboard != null)
        _NeonMenuButton(
          text: 'CLASSIFICA',
          icon: Icons.emoji_events_outlined,
          color: const Color(0xFFFFAA44),
          onTap: widget.onLeaderboard!,
        ),
      if (widget.onAchievements != null)
        _NeonMenuButton(
          text: 'ACHIEVEMENT',
          icon: Icons.military_tech_outlined,
          color: const Color(0xFF00FF88),
          onTap: widget.onAchievements!,
        ),
      if (widget.onStats != null)
        _NeonMenuButton(
          text: 'STATISTICHE',
          icon: Icons.bar_chart_rounded,
          color: const Color(0xFFFF4466),
          onTap: widget.onStats!,
        ),
    ];

    final rows = <Widget>[];
    for (int i = 0; i < buttons.length; i += 2) {
      rows.add(Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          buttons[i],
          if (i + 1 < buttons.length) ...[
            const SizedBox(width: 10),
            buttons[i + 1],
          ],
        ],
      ));
      if (i + 2 < buttons.length) {
        rows.add(const SizedBox(height: 10));
      }
    }

    return Column(mainAxisSize: MainAxisSize.min, children: rows);
  }
}

// ==================== STAT CHIP ====================

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;
  final String label;

  const _StatChip({
    required this.icon, required this.value,
    required this.color, required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 13),
            const SizedBox(width: 4),
            Text(value, style: TextStyle(
              color: color, fontSize: 13,
              fontWeight: FontWeight.bold, fontFamily: 'monospace',
            )),
          ],
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(
          color: Colors.white.withValues(alpha: 0.18),
          fontSize: 7, fontFamily: 'monospace', letterSpacing: 1,
        )),
      ],
    );
  }
}

// ==================== MENU BUTTON ====================

class _NeonMenuButton extends StatefulWidget {
  final String text;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String? badge;

  const _NeonMenuButton({
    required this.text, required this.icon,
    required this.color, required this.onTap, this.badge,
  });

  @override
  State<_NeonMenuButton> createState() => _NeonMenuButtonState();
}

class _NeonMenuButtonState extends State<_NeonMenuButton>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late AnimationController _hoverGlow;

  @override
  void initState() {
    super.initState();
    _hoverGlow = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _hoverGlow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _pressed = true);
        _hoverGlow.forward();
      },
      onTapUp: (_) {
        setState(() => _pressed = false);
        _hoverGlow.reverse();
        widget.onTap();
      },
      onTapCancel: () {
        setState(() => _pressed = false);
        _hoverGlow.reverse();
      },
      child: AnimatedBuilder(
        animation: _hoverGlow,
        builder: (context, _) {
          final glow = _hoverGlow.value;
          return AnimatedScale(
            scale: _pressed ? 0.92 : 1.0,
            duration: const Duration(milliseconds: 80),
            child: Container(
              width: 110,
              padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: widget.color.withValues(alpha: 0.45 + glow * 0.45),
                  width: 1.8 + glow * 0.5,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    widget.color.withValues(alpha: 0.02 + glow * 0.06),
                    widget.color.withValues(alpha: 0.01 + glow * 0.03),
                  ],
                ),
                boxShadow: glow > 0
                    ? [
                        BoxShadow(
                          color: widget.color.withValues(alpha: glow * 0.2),
                          blurRadius: 14 * glow,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        widget.icon,
                        color: widget.color.withValues(alpha: 0.8 + glow * 0.2),
                        size: 24,
                        shadows: [Shadow(color: widget.color, blurRadius: 6)],
                      ),
                      if (widget.badge != null)
                        Positioned(
                          top: -7, right: -16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: widget.color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: widget.color.withValues(alpha: 0.4),
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              widget.badge!,
                              style: TextStyle(
                                color: widget.color, fontSize: 7,
                                fontWeight: FontWeight.bold, fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    widget.text,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: widget.color.withValues(alpha: 0.7 + glow * 0.3),
                      fontSize: 10, fontWeight: FontWeight.w900,
                      fontFamily: 'monospace', letterSpacing: 1,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ==================== SMALL BUTTON ====================

class _NeonSmallButton extends StatefulWidget {
  final String text;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _NeonSmallButton({
    required this.text, required this.icon,
    required this.color, required this.onTap,
  });

  @override
  State<_NeonSmallButton> createState() => _NeonSmallButtonState();
}

class _NeonSmallButtonState extends State<_NeonSmallButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: AnimatedOpacity(
          opacity: _pressed ? 0.9 : 0.7,
          duration: const Duration(milliseconds: 80),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: widget.color.withValues(alpha: 0.5),
                width: 1.5,
              ),
              color: widget.color.withValues(alpha: 0.04),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, color: widget.color, size: 16),
                const SizedBox(width: 6),
                Text(widget.text, style: TextStyle(
                  color: widget.color, fontSize: 11,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'monospace', letterSpacing: 2,
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== ANIMATED BORDER PAINTER ====================

class _AnimatedBorderPainter extends CustomPainter {
  final double progress;
  final double borderRadius;
  final double strokeWidth;
  final double glowIntensity;

  _AnimatedBorderPainter({
    required this.progress,
    required this.borderRadius,
    required this.strokeWidth,
    required this.glowIntensity,
  });

  // Cache: colors/stops + Paint statica. Shader rebuild per frame
  // (rotazione animata continua).
  static final List<Color> _sweepColors = [
    Colors.cyanAccent.withValues(alpha: 0.8),
    const Color(0xFFFF00AA).withValues(alpha: 0.6),
    const Color(0xFF00FF88).withValues(alpha: 0.5),
    Colors.cyanAccent.withValues(alpha: 0.6),
    const Color(0xFFFF00AA).withValues(alpha: 0.6),
    Colors.cyanAccent.withValues(alpha: 0.8),
  ];
  static const List<double> _sweepStops = [0.0, 0.2, 0.4, 0.6, 0.8, 1.0];
  static final Paint _borderPaint = Paint()..style = PaintingStyle.stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    final sweep = SweepGradient(
      center: Alignment.center,
      transform: GradientRotation(progress * math.pi * 2),
      colors: _sweepColors,
      stops: _sweepStops,
    );

    _borderPaint
      ..shader = sweep.createShader(rect)
      ..strokeWidth = strokeWidth;

    canvas.drawRRect(rrect, _borderPaint);
  }

  @override
  bool shouldRepaint(covariant _AnimatedBorderPainter old) =>
      old.progress != progress || old.glowIntensity != glowIntensity;
}

// ==================== ANIMATED LINE PAINTER ====================

class _AnimatedLinePainter extends CustomPainter {
  final double progress;
  final Color color;

  _AnimatedLinePainter(this.progress, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    // Linea con punto luminoso che scorre
    final basePaint = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      basePaint,
    );

    // Punto luminoso che scorre
    final spotX = progress * size.width;
    final spotPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: 0.6),
          color.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: Offset(spotX, size.height / 2), radius: 30));

    canvas.drawRect(
      Rect.fromCenter(center: Offset(spotX, size.height / 2), width: 60, height: 4),
      spotPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _AnimatedLinePainter old) => old.progress != progress;
}

// ==================== DEEP SPACE BACKGROUND ====================

class _DeepSpaceBackgroundPainter extends CustomPainter {
  final double progress;

  _DeepSpaceBackgroundPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Gradiente base molto scuro
    final bgPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(0.3, -0.2),
        radius: 1.5,
        colors: [
          Color(0xFF0A0A25),
          Color(0xFF050518),
          Color(0xFF020210),
          Color(0xFF010108),
        ],
        stops: [0.0, 0.3, 0.6, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, bgPaint);

    final t = progress * math.pi * 2;

    // Nebulosa animata (2 blob colorati sottili)
    _drawNebula(canvas, size, t,
      center: Offset(size.width * 0.2, size.height * 0.3),
      color: const Color(0xFF00AAFF),
      radius: 200,
      alpha: 0.015,
    );
    _drawNebula(canvas, size, t + 1.5,
      center: Offset(size.width * 0.75, size.height * 0.7),
      color: const Color(0xFFFF00AA),
      radius: 180,
      alpha: 0.012,
    );
    _drawNebula(canvas, size, t + 3.0,
      center: Offset(size.width * 0.5, size.height * 0.5),
      color: const Color(0xFF00FF88),
      radius: 150,
      alpha: 0.008,
    );

    // Griglia distorta
    final gridPaint = Paint()
      ..color = Colors.cyanAccent.withValues(alpha: 0.02)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    const spacing = 70.0;
    for (double x = 0; x < size.width; x += spacing) {
      final path = Path()..moveTo(x, 0);
      for (double y = 0; y < size.height; y += 15) {
        final dx = math.sin(t * 0.3 + y * 0.008 + x * 0.003) * 4;
        path.lineTo(x + dx, y);
      }
      canvas.drawPath(path, gridPaint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      final path = Path()..moveTo(0, y);
      for (double x = 0; x < size.width; x += 15) {
        final dy = math.cos(t * 0.3 + x * 0.008 + y * 0.003) * 4;
        path.lineTo(x, y + dy);
      }
      canvas.drawPath(path, gridPaint);
    }

    // Forme geometriche lente
    final shapePaint = Paint()..style = PaintingStyle.stroke..strokeWidth = 1.2;
    final random = math.Random(42);

    for (int i = 0; i < 6; i++) {
      final bx = random.nextDouble() * size.width;
      final by = random.nextDouble() * size.height;
      final spd = 0.1 + random.nextDouble() * 0.2;
      final angle = t * spd + i;
      final x = bx + math.cos(angle) * 60;
      final y = by + math.sin(angle * 0.6) * 45;
      final r = 25 + random.nextDouble() * 45;

      final colors = [Colors.cyanAccent, const Color(0xFFFF00AA), const Color(0xFFFFD700), const Color(0xFF00FF88)];
      shapePaint.color = colors[i % colors.length].withValues(alpha: 0.035);

      switch (i % 4) {
        case 0:
          canvas.drawCircle(Offset(x, y), r, shapePaint);
          break;
        case 1:
          canvas.save();
          canvas.translate(x, y);
          canvas.rotate(angle * 0.1);
          canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: r * 1.6, height: r * 1.6), shapePaint);
          canvas.restore();
          break;
        case 2:
          final path = Path();
          for (int j = 0; j < 3; j++) {
            final a = j * math.pi * 2 / 3 - math.pi / 2 + angle * 0.08;
            final px = x + r * math.cos(a);
            final py = y + r * math.sin(a);
            if (j == 0) { path.moveTo(px, py); } else { path.lineTo(px, py); }
          }
          path.close();
          canvas.drawPath(path, shapePaint);
          break;
        case 3:
          final path = Path();
          for (int j = 0; j < 6; j++) {
            final a = j * math.pi / 3 + angle * 0.06;
            final px = x + r * math.cos(a);
            final py = y + r * math.sin(a);
            if (j == 0) { path.moveTo(px, py); } else { path.lineTo(px, py); }
          }
          path.close();
          canvas.drawPath(path, shapePaint);
          break;
      }
    }
  }

  void _drawNebula(Canvas canvas, Size size, double t, {
    required Offset center,
    required Color color,
    required double radius,
    required double alpha,
  }) {
    final cx = center.dx + math.cos(t * 0.15) * 40;
    final cy = center.dy + math.sin(t * 0.12) * 30;
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: alpha * 1.5),
          color.withValues(alpha: alpha * 0.5),
          color.withValues(alpha: 0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: radius));
    canvas.drawCircle(Offset(cx, cy), radius, paint);
  }

  @override
  bool shouldRepaint(covariant _DeepSpaceBackgroundPainter old) =>
      old.progress != progress;
}

// ==================== NEON PARTICLES ====================

class _NeonParticlesPainter extends CustomPainter {
  final double progress;

  _NeonParticlesPainter(this.progress);

  // Cache: Paint + colors costanti + seeds precomputed.
  static const int _particleCount = 30;
  static const List<Color> _particleColors = [
    Colors.cyanAccent,
    Color(0xFFFF00AA),
    Color(0xFF00FF88),
    Color(0xFFFFD700),
    Colors.white,
  ];
  static final Paint _particlePaint = Paint();
  static final List<_ParticleSeed> _seeds = _buildSeeds();

  static List<_ParticleSeed> _buildSeeds() {
    final r = math.Random(77);
    return List.generate(_particleCount, (_) {
      final baseXNorm = r.nextDouble();
      final baseYNorm = r.nextDouble();
      final speed = 0.15 + r.nextDouble() * 0.4;
      final phase = r.nextDouble() * math.pi * 2;
      final radius = 1.0 + r.nextDouble() * 2.5;
      return _ParticleSeed(baseXNorm, baseYNorm, speed, phase, radius);
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress * math.pi * 2;

    for (int i = 0; i < _particleCount; i++) {
      final s = _seeds[i];
      final baseX = s.baseXNorm * size.width;
      final baseY = s.baseYNorm * size.height;
      final speed = s.speed;
      final phase = s.phase;

      final x = baseX + math.cos(t * speed + phase) * 35 +
          math.sin(t * speed * 0.6 + phase * 2.3) * 18;
      final y = baseY + math.sin(t * speed * 0.7 + phase) * 28 +
          math.cos(t * speed * 0.4 + phase * 1.7) * 12;

      final alpha = (0.05 + math.sin(t * speed * 2 + phase) * 0.04).clamp(0.01, 0.12);
      final radius = s.radius;
      final color = _particleColors[i % _particleColors.length];

      _particlePaint.color = color.withValues(alpha: alpha);
      canvas.drawCircle(Offset(x, y), radius, _particlePaint);

      _particlePaint.color = color.withValues(alpha: alpha * 0.3);
      canvas.drawCircle(Offset(x, y), radius * 3, _particlePaint);

      if (i % 2 == 0) {
        final dx = math.cos(t * speed + phase) * speed * 12;
        final dy = math.sin(t * speed * 0.7 + phase) * speed * 10;
        _particlePaint
          ..color = color.withValues(alpha: alpha * 0.3)
          ..strokeWidth = radius * 0.6
          ..style = PaintingStyle.stroke;
        canvas.drawLine(Offset(x - dx, y - dy), Offset(x, y), _particlePaint);
        _particlePaint.style = PaintingStyle.fill;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _NeonParticlesPainter old) =>
      old.progress != progress;
}

class _ParticleSeed {
  final double baseXNorm;
  final double baseYNorm;
  final double speed;
  final double phase;
  final double radius;
  const _ParticleSeed(
    this.baseXNorm,
    this.baseYNorm,
    this.speed,
    this.phase,
    this.radius,
  );
}

// ==================== SCANLINE OVERLAY ====================

class _ScanlinePainter extends CustomPainter {
  final double progress;

  _ScanlinePainter(this.progress);

  // Cache: scanPaint costante; glowPaint riusa con shader rebuild per frame.
  static final Paint _scanPaint = Paint()
    ..color = Colors.white.withValues(alpha: 0.012)
    ..strokeWidth = 0.5;
  static final Paint _scanGlowPaint = Paint();
  static final LinearGradient _glowGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Colors.cyanAccent.withValues(alpha: 0),
      Colors.cyanAccent.withValues(alpha: 0.03),
      Colors.cyanAccent.withValues(alpha: 0),
    ],
  );

  @override
  void paint(Canvas canvas, Size size) {
    for (double y = 0; y < size.height; y += 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), _scanPaint);
    }

    final scanY = progress * (size.height + 60) - 30;
    final glowRect = Rect.fromLTWH(0, scanY - 20, size.width, 40);
    _scanGlowPaint.shader = _glowGradient.createShader(glowRect);
    canvas.drawRect(glowRect, _scanGlowPaint);
  }

  @override
  bool shouldRepaint(covariant _ScanlinePainter old) => old.progress != progress;
}

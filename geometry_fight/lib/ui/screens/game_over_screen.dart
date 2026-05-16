import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../data/achievements.dart';
import '../widgets/shared_painters.dart';

class GameOverScreen extends StatefulWidget {
  final int score;
  final int wave;
  final int geoms;
  final int goldEarned;
  final int kills;
  final int bossKills;
  final List<AchievementDef> newAchievements;
  final VoidCallback onRetry;
  final VoidCallback onQuit;

  const GameOverScreen({
    super.key,
    required this.score,
    required this.wave,
    required this.geoms,
    required this.goldEarned,
    this.kills = 0,
    this.bossKills = 0,
    this.newAchievements = const [],
    required this.onRetry,
    required this.onQuit,
  });

  @override
  State<GameOverScreen> createState() => _GameOverScreenState();
}

class _GameOverScreenState extends State<GameOverScreen>
    with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late AnimationController _pulseController;
  late AnimationController _counterController;
  late AnimationController _particleController;
  Timer? _delayedTimer;

  // Cached computed values (constant for widget lifetime)
  late final int _perfBonus;
  late final int _achievementGold;
  late final int _totalGold;

  // Staggered entrance animations
  late Animation<double> _bgFade;
  late Animation<double> _titleScale;
  late Animation<double> _titleFade;
  late Animation<double> _statsFade;
  late Animation<double> _statsSlide;
  late Animation<double> _goldFade;
  late Animation<double> _goldSlide;
  late Animation<double> _badgesFade;
  late Animation<double> _buttonsFade;
  late Animation<double> _buttonsSlide;

  int _calcPerformanceBonus() {
    int bonus = 0;
    if (widget.kills >= 200) bonus += 50;
    if (widget.kills >= 500) bonus += 100;
    if (widget.wave >= 20) bonus += 50;
    if (widget.wave >= 50) bonus += 150;
    if (widget.bossKills >= 3) bonus += 100;
    if (widget.bossKills >= 5) bonus += 200;
    return bonus;
  }

  @override
  void initState() {
    super.initState();

    _perfBonus = _calcPerformanceBonus();
    _achievementGold = widget.newAchievements.fold(0, (sum, a) => sum + a.reward);
    _totalGold = widget.goldEarned + _perfBonus + _achievementGold;

    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat(reverse: true);

    _counterController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _particleController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    // Staggered entrance
    _bgFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.25, curve: Curves.easeOut),
    );
    _titleScale = Tween<double>(begin: 1.5, end: 1.0).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.05, 0.3, curve: Curves.easeOutBack),
    ));
    _titleFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.05, 0.3, curve: Curves.easeOut),
    );
    _statsFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.2, 0.5, curve: Curves.easeOut),
    );
    _statsSlide = Tween<double>(begin: 20, end: 0).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.2, 0.5, curve: Curves.easeOutCubic),
    ));
    _goldFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.4, 0.65, curve: Curves.easeOut),
    );
    _goldSlide = Tween<double>(begin: 20, end: 0).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.4, 0.65, curve: Curves.easeOutCubic),
    ));
    _badgesFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.55, 0.8, curve: Curves.easeOut),
    );
    _buttonsFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
    );
    _buttonsSlide = Tween<double>(begin: 30, end: 0).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.7, 1.0, curve: Curves.easeOutCubic),
    ));

    _entranceController.forward();
    // Start counter animation after stats appear
    _delayedTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) _counterController.forward();
    });
  }

  @override
  void dispose() {
    _delayedTimer?.cancel();
    _entranceController.dispose();
    _pulseController.dispose();
    _counterController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _entranceController,
        _pulseController,
        _counterController,
        _particleController,
      ]),
      builder: (context, _) {
        final pulse = _pulseController.value;
        return Stack(
          children: [
            // Blurred background
            BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 6.0 * _bgFade.value,
                sigmaY: 6.0 * _bgFade.value,
              ),
              child: Container(
                color: Colors.black.withValues(alpha: 0.75 * _bgFade.value),
              ),
            ),

            // Particle effects
            CustomPaint(
              painter: _GameOverParticlesPainter(
                time: _particleController.value,
                opacity: _bgFade.value,
                hasNewRecord: widget.newAchievements.isNotEmpty,
              ),
              size: Size.infinite,
            ),

            // Scanlines
            IgnorePointer(
              child: Opacity(
                opacity: 0.025 * _bgFade.value,
                child: CustomPaint(
                  painter: ScanlinePainter(),
                  size: Size.infinite,
                ),
              ),
            ),

            // Content
            Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 16),

                    // GAME OVER title
                    Transform.scale(
                      scale: _titleScale.value,
                      child: Opacity(
                        opacity: _titleFade.value,
                        child: _buildTitle(pulse),
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Decorative line
                    Opacity(
                      opacity: _titleFade.value * 0.6,
                      child: Container(
                        width: 160 + pulse * 20,
                        height: 1.5,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.redAccent.withValues(alpha: 0.8),
                              const Color(0xFFFF6600).withValues(alpha: 0.6),
                              Colors.transparent,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.redAccent.withValues(alpha: 0.4),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Stats panel with glassmorphism
                    Transform.translate(
                      offset: Offset(0, _statsSlide.value),
                      child: Opacity(
                        opacity: _statsFade.value,
                        child: _buildStatsPanel(),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Gold earned panel
                    Transform.translate(
                      offset: Offset(0, _goldSlide.value),
                      child: Opacity(
                        opacity: _goldFade.value,
                        child: _buildGoldPanel(_totalGold, _perfBonus,
                            _achievementGold),
                      ),
                    ),

                    // Performance badges
                    if (_perfBonus > 0) ...[
                      const SizedBox(height: 8),
                      Opacity(
                        opacity: _badgesFade.value,
                        child: _buildBadges(),
                      ),
                    ],

                    // Achievement notifications
                    if (widget.newAchievements.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Opacity(
                        opacity: _badgesFade.value,
                        child: _buildAchievements(),
                      ),
                    ],

                    // Buttons spostati fuori (Positioned right side) per
                    // evitare taglio fondo schermo (richiesta utente).
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Vignette
            IgnorePointer(
              child: Opacity(
                opacity: _bgFade.value,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.6),
                      ],
                      radius: 1.3,
                    ),
                  ),
                ),
              ),
            ),

            // Buttons (right side, vertical stack — richiesta utente:
            // "metterli sulla destra" perché in basso erano tagliati).
            Positioned(
              right: 24,
              top: 0,
              bottom: 0,
              child: Center(
                child: Transform.translate(
                  offset: Offset(_buttonsSlide.value, 0),
                  child: Opacity(
                    opacity: _buttonsFade.value,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _NeonGameOverButton(
                          text: 'RIPROVA',
                          icon: Icons.refresh_rounded,
                          color: Colors.cyanAccent,
                          onTap: widget.onRetry,
                          pulse: pulse,
                          isPrimary: true,
                        ),
                        const SizedBox(height: 14),
                        _NeonGameOverButton(
                          text: 'ESCI',
                          icon: Icons.home_rounded,
                          color: Colors.white70,
                          onTap: widget.onQuit,
                          pulse: pulse,
                          isPrimary: false,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTitle(double pulse) {
    final glowRadius = 15.0 + pulse * 8.0;
    return Stack(
      children: [
        // Red glow layer
        Transform.translate(
          offset: Offset(-1.5 + pulse * 0.3, 0),
          child: Text(
            'GAME OVER',
            style: TextStyle(
              color: Colors.redAccent.withValues(alpha: 0.4),
              fontSize: 38,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              letterSpacing: 8,
            ),
          ),
        ),
        // Orange glow layer
        Transform.translate(
          offset: Offset(1.5 - pulse * 0.3, 0),
          child: Text(
            'GAME OVER',
            style: TextStyle(
              color: const Color(0xFFFF6600).withValues(alpha: 0.3),
              fontSize: 38,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              letterSpacing: 8,
            ),
          ),
        ),
        // Main text
        Text(
          'GAME OVER',
          style: TextStyle(
            color: Colors.white,
            fontSize: 38,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            letterSpacing: 8,
            shadows: [
              Shadow(color: Colors.redAccent, blurRadius: glowRadius),
              Shadow(
                  color: Colors.redAccent.withValues(alpha: 0.5),
                  blurRadius: glowRadius * 2),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsPanel() {
    final counterVal = _counterController.value;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        color: Colors.white.withValues(alpha: 0.05),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _AnimatedStat(
            label: 'SCORE',
            value: (widget.score * counterVal).round(),
            color: Colors.white,
            icon: Icons.star_rounded,
          ),
          _statDivider(),
          _AnimatedStat(
            label: 'WAVE',
            value: (widget.wave * counterVal).round(),
            color: Colors.cyanAccent,
            icon: Icons.waves_rounded,
          ),
          _statDivider(),
          _AnimatedStat(
            label: 'KILLS',
            value: (widget.kills * counterVal).round(),
            color: const Color(0xFFFF4466),
            icon: Icons.local_fire_department_rounded,
          ),
          _statDivider(),
          _AnimatedStat(
            label: 'BOSS',
            value: (widget.bossKills * counterVal).round(),
            color: const Color(0xFFCC00FF),
            icon: Icons.shield_rounded,
          ),
        ],
      ),
    );
  }

  Widget _statDivider() {
    return Container(
      width: 1,
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: Colors.white.withValues(alpha: 0.08),
    );
  }

  Widget _buildGoldPanel(int totalGold, int perfBonus, int achievementGold) {
    final counterVal = _counterController.value;
    final animGold = (totalGold * counterVal).round();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFFFFD700).withValues(alpha: 0.3)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFFD700).withValues(alpha: 0.08),
            const Color(0xFFFFD700).withValues(alpha: 0.02),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withValues(alpha: 0.1),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.diamond, color: Color(0xFFFFD700), size: 22),
              const SizedBox(width: 8),
              Text(
                '+$animGold',
                style: const TextStyle(
                  color: Color(0xFFFFD700),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  shadows: [
                    Shadow(color: Color(0xFFFFD700), blurRadius: 8),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'GOLD GEOMS',
                style: TextStyle(
                  color: Color(0xFFFFD700),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          if (perfBonus > 0 || achievementGold > 0) ...[
            const SizedBox(height: 4),
            Text(
              '${widget.goldEarned} base${perfBonus > 0 ? ' + $perfBonus bonus' : ''}${achievementGold > 0 ? ' + $achievementGold achievement' : ''}',
              style: TextStyle(
                color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                fontSize: 9,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBadges() {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      alignment: WrapAlignment.center,
      children: [
        if (widget.kills >= 200)
          const _GlowBadge(text: 'KILLER', color: Colors.orangeAccent),
        if (widget.kills >= 500)
          const _GlowBadge(text: 'MASSACRO', color: Colors.redAccent),
        if (widget.wave >= 20)
          const _GlowBadge(text: 'PERSISTENTE', color: Colors.cyanAccent),
        if (widget.wave >= 50)
          const _GlowBadge(text: 'VETERANO', color: Colors.purpleAccent),
        if (widget.bossKills >= 3)
          const _GlowBadge(text: 'BOSS HUNTER', color: Colors.amberAccent),
        if (widget.bossKills >= 5)
          const _GlowBadge(text: 'REGICIDA', color: Colors.amber),
      ],
    );
  }

  Widget _buildAchievements() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: Colors.greenAccent.withValues(alpha: 0.4)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.greenAccent.withValues(alpha: 0.08),
            Colors.greenAccent.withValues(alpha: 0.02),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.greenAccent.withValues(alpha: 0.1),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            '★ NUOVO ACHIEVEMENT! ★',
            style: TextStyle(
              color: Colors.greenAccent,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              letterSpacing: 2,
              shadows: [Shadow(color: Colors.greenAccent, blurRadius: 6)],
            ),
          ),
          const SizedBox(height: 8),
          ...widget.newAchievements.map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(a.icon, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text(
                      a.name,
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 12,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (a.reward > 0) ...[
                      const SizedBox(width: 8),
                      Text(
                        '+${a.reward}',
                        style: const TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.diamond,
                          color: Color(0xFFFFD700), size: 10),
                    ],
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

// ==================== ANIMATED STAT ====================
class _AnimatedStat extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final IconData icon;

  const _AnimatedStat({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color.withValues(alpha: 0.7), size: 16),
        const SizedBox(height: 4),
        Text(
          _formatNumber(value),
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            shadows: [Shadow(color: color.withValues(alpha: 0.5), blurRadius: 6)],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: color.withValues(alpha: 0.5),
            fontSize: 9,
            fontFamily: 'monospace',
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 10000) return '${n ~/ 1000}K';
    return '$n';
  }
}

// ==================== GLOW BADGE ====================
class _GlowBadge extends StatelessWidget {
  final String text;
  final Color color;
  const _GlowBadge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.6)),
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.05),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontFamily: 'monospace',
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
          shadows: [Shadow(color: color.withValues(alpha: 0.5), blurRadius: 4)],
        ),
      ),
    );
  }
}

// ==================== NEON BUTTON ====================
class _NeonGameOverButton extends StatefulWidget {
  final String text;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final double pulse;
  final bool isPrimary;

  const _NeonGameOverButton({
    required this.text,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.pulse,
    required this.isPrimary,
  });

  @override
  State<_NeonGameOverButton> createState() => _NeonGameOverButtonState();
}

class _NeonGameOverButtonState extends State<_NeonGameOverButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final glowAlpha = widget.isPrimary ? 0.15 + widget.pulse * 0.08 : 0.05;

    return GestureDetector(
      onTapDown: (_) => _pressController.forward(),
      onTapUp: (_) {
        _pressController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _pressController.reverse(),
      child: AnimatedBuilder(
        animation: _pressController,
        builder: (context, _) {
          final scale = 1.0 - _pressController.value * 0.05;
          return Transform.scale(
            scale: scale,
            child: Container(
              width: 160,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: widget.color
                      .withValues(alpha: widget.isPrimary ? 0.8 : 0.4),
                  width: widget.isPrimary ? 2 : 1,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    widget.color.withValues(alpha: glowAlpha),
                    widget.color.withValues(alpha: glowAlpha * 0.3),
                  ],
                ),
                boxShadow: widget.isPrimary
                    ? [
                        BoxShadow(
                          color: widget.color.withValues(alpha: 0.2),
                          blurRadius: 12,
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(widget.icon, color: widget.color, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    widget.text,
                    style: TextStyle(
                      color: widget.color,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      letterSpacing: 3,
                      shadows: widget.isPrimary
                          ? [
                              Shadow(
                                  color:
                                      widget.color.withValues(alpha: 0.5),
                                  blurRadius: 6)
                            ]
                          : null,
                    ),
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

// ==================== PARTICLES ====================
class _GameOverParticlesPainter extends CustomPainter {
  // Static cache: evita alloc per frame × 30 particles.
  static final Paint _paintCache = Paint()..style = PaintingStyle.fill;

  final double time;
  final double opacity;
  final bool hasNewRecord;

  _GameOverParticlesPainter({
    required this.time,
    required this.opacity,
    required this.hasNewRecord,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity < 0.01) return;
    final rng = Random(77);
    final paint = _paintCache;
    paint.maskFilter = null; // reset: blur da prev frame potrebbe leaked

    final count = hasNewRecord ? 30 : 15;
    for (int i = 0; i < count; i++) {
      final baseX = rng.nextDouble() * size.width;
      final baseY = rng.nextDouble() * size.height;
      final speed = 0.3 + rng.nextDouble() * 0.5;
      final phase = rng.nextDouble() * 2 * pi;
      final radius = 0.8 + rng.nextDouble() * 1.5;

      final x = baseX + sin(time * 2 * pi * speed + phase) * 15;
      final y = baseY + cos(time * 2 * pi * speed * 0.6 + phase) * 12 -
          time * 20;
      final wrappedY = y % size.height;
      final alpha = (0.15 + sin(time * 2 * pi + phase) * 0.1) * opacity;

      if (hasNewRecord) {
        // Confetti-like colors for achievements
        final hue = (i * 37.0 + time * 360) % 360;
        paint.color =
            HSVColor.fromAHSV(alpha.clamp(0.0, 1.0).toDouble(), hue, 0.8, 1.0)
                .toColor();
      } else {
        paint.color = (rng.nextBool()
                ? Colors.redAccent
                : const Color(0xFFFF6600))
            .withValues(alpha: alpha);
      }

      canvas.drawCircle(Offset(x, wrappedY), radius, paint);

      paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      paint.color = paint.color.withValues(alpha: alpha * 0.3);
      canvas.drawCircle(Offset(x, wrappedY), radius * 2.5, paint);
      paint.maskFilter = null;
    }
  }

  @override
  bool shouldRepaint(covariant _GameOverParticlesPainter old) => true;
}


import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';
import '../widgets/shared_painters.dart';

class PauseScreen extends StatefulWidget {
  final VoidCallback onResume;
  final VoidCallback onQuit;

  const PauseScreen({super.key, required this.onResume, required this.onQuit});

  @override
  State<PauseScreen> createState() => _PauseScreenState();
}

class _PauseScreenState extends State<PauseScreen>
    with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late AnimationController _pulseController;
  late AnimationController _particleController;

  late Animation<double> _bgFade;
  late Animation<double> _titleSlide;
  late Animation<double> _titleFade;
  late Animation<double> _buttonsSlide;
  late Animation<double> _buttonsFade;
  late Animation<double> _blurAnim;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _particleController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();

    _bgFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    );
    _blurAnim = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );
    _titleSlide = Tween<double>(begin: -30, end: 0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.15, 0.55, curve: Curves.easeOutCubic),
      ),
    );
    _titleFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.15, 0.55, curve: Curves.easeOut),
    );
    _buttonsSlide = Tween<double>(begin: 40, end: 0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.35, 0.75, curve: Curves.easeOutCubic),
      ),
    );
    _buttonsFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.35, 0.75, curve: Curves.easeOut),
    );

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _pulseController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Rebuild scope is narrowed per region so each repeating ~60fps controller
    // only rebuilds the subtree that reads it. The rendered result every frame
    // is identical to wrapping the whole Stack in one merged AnimatedBuilder.
    return Stack(
      children: [
        // Frosted glass background (entrance-only: _blurAnim, _bgFade)
        AnimatedBuilder(
          animation: _entranceController,
          builder: (context, _) {
            return BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 8.0 * _blurAnim.value,
                sigmaY: 8.0 * _blurAnim.value,
              ),
              child: Container(
                color: Colors.black.withValues(alpha: 0.6 * _bgFade.value),
              ),
            );
          },
        ),

        // Floating particles (repeating: _particleController + entrance _bgFade)
        AnimatedBuilder(
          animation: Listenable.merge([
            _entranceController,
            _particleController,
          ]),
          builder: (context, _) {
            return CustomPaint(
              painter: _PauseParticlesPainter(
                time: _particleController.value,
                opacity: _bgFade.value,
              ),
              size: Size.infinite,
            );
          },
        ),

        // Scanline overlay (entrance-only: _bgFade)
        AnimatedBuilder(
          animation: _entranceController,
          builder: (context, _) {
            return Opacity(
              opacity: 0.03 * _bgFade.value,
              child: CustomPaint(
                painter: ScanlinePainter(),
                size: Size.infinite,
              ),
            );
          },
        ),

        // Content (entrance slides/fades + repeating _pulseController)
        Center(
          child: AnimatedBuilder(
            animation: Listenable.merge([
              _entranceController,
              _pulseController,
            ]),
            builder: (context, _) {
              final pulse = _pulseController.value;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // PAUSED title with glitch + pulse
                  Transform.translate(
                    offset: Offset(0, _titleSlide.value),
                    child: Opacity(
                      opacity: _titleFade.value,
                      child: _buildTitle(pulse, l10n.pause),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Decorative line
                  Transform.translate(
                    offset: Offset(0, _titleSlide.value),
                    child: Opacity(
                      opacity: _titleFade.value * 0.6,
                      child: Container(
                        width: 120 + pulse * 20,
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.cyanAccent.withValues(alpha: 0.8),
                              Colors.transparent,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.cyanAccent.withValues(alpha: 0.4),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Buttons
                  Transform.translate(
                    offset: Offset(0, _buttonsSlide.value),
                    child: Opacity(
                      opacity: _buttonsFade.value,
                      child: Column(
                        children: [
                          _NeonPauseButton(
                            text: l10n.resume,
                            color: Colors.cyanAccent,
                            icon: Icons.play_arrow_rounded,
                            onTap: widget.onResume,
                            pulse: pulse,
                            isPrimary: true,
                          ),
                          const SizedBox(height: 16),
                          _NeonPauseButton(
                            text: l10n.quit,
                            color: const Color(0xFFFF4466),
                            icon: Icons.exit_to_app_rounded,
                            onTap: widget.onQuit,
                            pulse: pulse,
                            isPrimary: false,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),

        // Vignette (entrance-only: _bgFade)
        IgnorePointer(
          child: AnimatedBuilder(
            animation: _entranceController,
            builder: (context, _) {
              return Opacity(
                opacity: _bgFade.value,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7),
                      ],
                      radius: 1.2,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTitle(double pulse, String title) {
    final glowRadius = 15.0 + pulse * 10.0;
    return Stack(
      children: [
        // Cyan channel offset
        Transform.translate(
          offset: Offset(-1.5 + pulse * 0.5, 0),
          child: Text(
            title,
            style: TextStyle(
              color: Colors.cyanAccent.withValues(alpha: 0.4),
              fontSize: 48,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              letterSpacing: 12,
            ),
          ),
        ),
        // Red channel offset
        Transform.translate(
          offset: Offset(1.5 - pulse * 0.5, 0),
          child: Text(
            title,
            style: TextStyle(
              color: const Color(0xFFFF4466).withValues(alpha: 0.3),
              fontSize: 48,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              letterSpacing: 12,
            ),
          ),
        ),
        // Main text
        Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 48,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            letterSpacing: 12,
            shadows: [
              Shadow(color: Colors.cyanAccent, blurRadius: glowRadius),
              Shadow(
                color: Colors.cyanAccent.withValues(alpha: 0.5),
                blurRadius: glowRadius * 2,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NeonPauseButton extends StatefulWidget {
  final String text;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  final double pulse;
  final bool isPrimary;

  const _NeonPauseButton({
    required this.text,
    required this.color,
    required this.icon,
    required this.onTap,
    required this.pulse,
    required this.isPrimary,
  });

  @override
  State<_NeonPauseButton> createState() => _NeonPauseButtonState();
}

class _NeonPauseButtonState extends State<_NeonPauseButton>
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
    final glowAlpha = widget.isPrimary ? 0.15 + widget.pulse * 0.1 : 0.05;
    final borderAlpha = widget.isPrimary ? 0.8 : 0.5;

    return Semantics(
      button: true,
      label: widget.text,
      child: GestureDetector(
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
                width: 220,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: widget.color.withValues(alpha: borderAlpha),
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
                            color: widget.color.withValues(
                              alpha: 0.2 + widget.pulse * 0.1,
                            ),
                            blurRadius: 16,
                            spreadRadius: -2,
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(widget.icon, color: widget.color, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      widget.text,
                      style: TextStyle(
                        color: widget.color,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        letterSpacing: 4,
                        shadows: widget.isPrimary
                            ? [
                                Shadow(
                                  color: widget.color.withValues(alpha: 0.5),
                                  blurRadius: 8,
                                ),
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
      ),
    );
  }
}

class _PauseParticlesPainter extends CustomPainter {
  // Static cache: the painter is reconstructed every frame by AnimatedBuilder,
  // so an instance field would allocate a new Paint each frame.  A static
  // field is safe because CustomPainter.paint() runs on the main isolate only.
  static final Paint _paintCache = Paint()..style = PaintingStyle.fill;

  final double time;
  final double opacity;

  _PauseParticlesPainter({required this.time, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity < 0.01) return;
    final rng = Random(42);
    final paint = _paintCache;
    paint.maskFilter = null; // reset: blur da prev frame potrebbe leaked

    for (int i = 0; i < 20; i++) {
      final baseX = rng.nextDouble() * size.width;
      final baseY = rng.nextDouble() * size.height;
      final speed = 0.3 + rng.nextDouble() * 0.7;
      final phase = rng.nextDouble() * 2 * pi;
      final radius = 1.0 + rng.nextDouble() * 2.0;

      final x = baseX + sin(time * 2 * pi * speed + phase) * 20;
      final y = baseY + cos(time * 2 * pi * speed * 0.7 + phase) * 15;
      final alpha = (0.2 + sin(time * 2 * pi + phase) * 0.15) * opacity;

      final isCyan = rng.nextBool();
      paint.color = isCyan
          ? Colors.cyanAccent.withValues(alpha: alpha)
          : const Color(0xFFFF4466).withValues(alpha: alpha * 0.7);

      canvas.drawCircle(Offset(x, y), radius, paint);

      // Glow halo
      paint.color = paint.color.withValues(alpha: alpha * 0.3);
      paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(Offset(x, y), radius * 3, paint);
      paint.maskFilter = null;
    }
  }

  @override
  bool shouldRepaint(covariant _PauseParticlesPainter old) =>
      old.time != time || old.opacity != opacity;
}

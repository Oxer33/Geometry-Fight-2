import 'dart:math' as math;
import 'package:flutter/material.dart';

class MainMenuScreen extends StatefulWidget {
  final VoidCallback onPlay;
  final VoidCallback onShop;
  final VoidCallback onSettings;
  final VoidCallback? onLeaderboard;

  const MainMenuScreen({
    super.key,
    required this.onPlay,
    required this.onShop,
    required this.onSettings,
    this.onLeaderboard,
  });

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Animated background
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, _) => CustomPaint(
              painter: _MenuBackgroundPainter(_bgController.value),
              size: MediaQuery.of(context).size,
            ),
          ),

          // Content
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),

                  // Title
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, _) {
                      final glow = 8 + _pulseController.value * 12;
                      return Text(
                        'GEOMETRY\nFIGHT',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.cyanAccent,
                          fontSize: 52,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'monospace',
                          letterSpacing: 8,
                          height: 1.1,
                          shadows: [
                            Shadow(
                                color: Colors.cyanAccent, blurRadius: glow),
                            Shadow(
                                color: Colors.cyanAccent.withValues(alpha: 0.5),
                                blurRadius: glow * 2),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 8),
                  Text(
                    'TWIN-STICK NEON SHOOTER',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                      fontFamily: 'monospace',
                      letterSpacing: 4,
                    ),
                  ),

                  const Spacer(flex: 2),

                  // Buttons
                  _NeonButton(
                    text: 'PLAY',
                    color: Colors.cyanAccent,
                    onTap: widget.onPlay,
                  ),
                  const SizedBox(height: 16),
                  _NeonButton(
                    text: 'SHOP',
                    color: const Color(0xFFFFD700),
                    onTap: widget.onShop,
                  ),
                  const SizedBox(height: 16),
                  if (widget.onLeaderboard != null) ...[
                    const SizedBox(height: 16),
                    _NeonButton(
                      text: 'CLASSIFICA',
                      color: const Color(0xFFFFD700),
                      onTap: widget.onLeaderboard!,
                    ),
                  ],
                  const SizedBox(height: 16),
                  _NeonButton(
                    text: 'IMPOSTAZIONI',
                    color: Colors.white70,
                    onTap: widget.onSettings,
                  ),

                  const Spacer(flex: 3),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NeonButton extends StatelessWidget {
  final String text;
  final Color color;
  final VoidCallback onTap;

  const _NeonButton({
    required this.text,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 220,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 1.5),
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 12),
          ],
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            letterSpacing: 4,
            shadows: [Shadow(color: color, blurRadius: 8)],
          ),
        ),
      ),
    );
  }
}

class _MenuBackgroundPainter extends CustomPainter {
  final double progress;

  _MenuBackgroundPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.cyanAccent.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // Grid lines
    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Floating shapes
    final shapePaint = Paint()
      ..color = Colors.cyanAccent.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 0; i < 8; i++) {
      final angle = progress * math.pi * 2 + i * math.pi / 4;
      final x = size.width / 2 + math.cos(angle + i) * (100 + i * 30);
      final y = size.height / 2 + math.sin(angle * 0.7 + i) * (80 + i * 25);
      final r = 15 + i * 5.0;

      if (i % 3 == 0) {
        canvas.drawCircle(Offset(x, y), r, shapePaint);
      } else if (i % 3 == 1) {
        canvas.drawRect(
            Rect.fromCenter(center: Offset(x, y), width: r * 2, height: r * 2),
            shapePaint);
      } else {
        final path = Path()
          ..moveTo(x, y - r)
          ..lineTo(x + r, y + r)
          ..lineTo(x - r, y + r)
          ..close();
        canvas.drawPath(path, shapePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MenuBackgroundPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// Re-export AnimatedBuilder
class AnimatedBuilder extends StatefulWidget {
  final Listenable animation;
  final Widget Function(BuildContext, Widget?) builder;

  const AnimatedBuilder({
    super.key,
    required this.animation,
    required this.builder,
  });

  @override
  State<AnimatedBuilder> createState() => _AnimatedBuilderState();
}

class _AnimatedBuilderState extends State<AnimatedBuilder> {
  @override
  void initState() {
    super.initState();
    widget.animation.addListener(_rebuild);
  }

  @override
  void dispose() {
    widget.animation.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, null);
}

import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Splash screen di avvio con animazione logo neon e particelle.
/// Si auto-chiude dopo 3 secondi o al tap.
class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const SplashScreen({super.key, required this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _particleController;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _subtitleOpacity;

  @override
  void initState() {
    super.initState();

    // Animazione logo: fade in + scale
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );
    _subtitleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );

    // Particelle di sfondo
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    // Start animazione
    _logoController.forward();

    // Auto-avanza dopo 3.5 secondi
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) widget.onComplete();
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onComplete, // Tap per saltare
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Particelle di sfondo animate
            AnimatedBuilder(
              animation: _particleController,
              builder: (context, _) => CustomPaint(
                painter: _SplashParticlePainter(_particleController.value),
                size: MediaQuery.of(context).size,
              ),
            ),

            // Logo centrale
            Center(
              child: AnimatedBuilder(
                animation: _logoController,
                builder: (context, _) => Opacity(
                  opacity: _logoOpacity.value,
                  child: Transform.scale(
                    scale: _logoScale.value,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icona geometrica
                        CustomPaint(
                          size: const Size(120, 120),
                          painter: _LogoPainter(_particleController.value),
                        ),
                        const SizedBox(height: 24),
                        // Titolo
                        Text(
                          'GEOMETRY\nFIGHT',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.cyanAccent,
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'monospace',
                            letterSpacing: 6,
                            height: 1.1,
                            shadows: [
                              const Shadow(
                                color: Colors.cyanAccent,
                                blurRadius: 20,
                              ),
                              Shadow(
                                color: Colors.cyanAccent.withValues(alpha: 0.5),
                                blurRadius: 40,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Sottotitolo
                        Opacity(
                          opacity: _subtitleOpacity.value,
                          child: Text(
                            'TWIN-STICK NEON SHOOTER',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 11,
                              fontFamily: 'monospace',
                              letterSpacing: 5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        // "Tocca per continuare"
                        Opacity(
                          opacity: _subtitleOpacity.value,
                          child: Text(
                            'TOCCA PER INIZIARE',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.25),
                              fontSize: 10,
                              fontFamily: 'monospace',
                              letterSpacing: 3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Painter per il logo geometrico animato
class _LogoPainter extends CustomPainter {
  final double phase;
  _LogoPainter(this.phase);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2 - 10;

    // Esagono esterno rotante
    final outerPaint = Paint()
      ..color = Colors.cyanAccent.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(phase * math.pi * 2 * 0.3);
    _drawHexagon(canvas, 0, 0, r, outerPaint);
    canvas.restore();

    // Esagono interno (rotazione opposta)
    final innerPaint = Paint()
      ..color = Colors.cyanAccent.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(-phase * math.pi * 2 * 0.2);
    _drawHexagon(canvas, 0, 0, r * 0.6, innerPaint);
    canvas.restore();

    // Triangolo centrale (come la nave del player)
    final shipPaint = Paint()
      ..color = Colors.cyanAccent
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    final shipPath = Path()
      ..moveTo(cx, cy - r * 0.35)
      ..lineTo(cx - r * 0.25, cy + r * 0.25)
      ..lineTo(cx + r * 0.25, cy + r * 0.25)
      ..close();
    canvas.drawPath(shipPath, shipPaint);

    // Glow del triangolo
    shipPaint
      ..color = Colors.cyanAccent.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawPath(shipPath, shipPaint);
  }

  void _drawHexagon(Canvas canvas, double cx, double cy, double r, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = i * math.pi / 3 - math.pi / 6;
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _LogoPainter oldDelegate) =>
      oldDelegate.phase != phase;
}

/// Particelle fluttuanti nello sfondo dello splash
class _SplashParticlePainter extends CustomPainter {
  final double phase;
  _SplashParticlePainter(this.phase);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final random = math.Random(42); // Seed fisso per consistenza

    for (int i = 0; i < 40; i++) {
      final baseX = random.nextDouble() * size.width;
      final baseY = random.nextDouble() * size.height;
      final speed = 0.5 + random.nextDouble() * 1.5;
      final particleSize = 0.5 + random.nextDouble() * 2;

      final x = baseX + math.sin(phase * math.pi * 2 * speed + i) * 30;
      final y = baseY + math.cos(phase * math.pi * 2 * speed * 0.7 + i) * 20;
      final alpha = 0.1 + random.nextDouble() * 0.2;

      paint
        ..color = Colors.cyanAccent.withValues(alpha: alpha)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, particleSize);
      canvas.drawCircle(Offset(x, y), particleSize, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SplashParticlePainter oldDelegate) =>
      oldDelegate.phase != phase;
}

/// AnimatedBuilder helper (locale per questa schermata)
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

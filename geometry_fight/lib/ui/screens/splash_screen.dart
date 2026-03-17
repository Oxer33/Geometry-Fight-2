import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../widgets/animated_builder_widget.dart';

/// Splash screen cinematografico: navicella cyan insegue un drone rosa
/// attraverso lo schermo con scia luminosa, stelle e esplosione finale.
/// Poi appare il logo GEOMETRY FIGHT con glow spettacolare.
class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const SplashScreen({super.key, required this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Animazione inseguimento (0-1: navicella insegue drone)
  late AnimationController _chaseController;
  // Animazione logo (appare dopo l'esplosione)
  late AnimationController _logoController;
  // Particelle sfondo
  late AnimationController _bgController;

  late Animation<double> _logoOpacity;
  late Animation<double> _logoScale;

  bool _showLogo = false;
  bool _showExplosion = false;
  double _explosionPhase = 0;

  @override
  void initState() {
    super.initState();

    // Fase 1: Inseguimento (2.5 secondi)
    _chaseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    // Fase 2: Logo (dopo esplosione)
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: const Interval(0.0, 0.5)),
    );
    _logoScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    // Background continuo
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    // Avvia sequenza
    _chaseController.forward();
    _chaseController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() {
          _showExplosion = true;
          _showLogo = true;
        });
        _logoController.forward();
        // Auto-avanza dopo 2 secondi dal logo
        Future.delayed(const Duration(milliseconds: 2000), () {
          if (mounted) widget.onComplete();
        });
      }
    });

    // Timer esplosione
    _bgController.addListener(() {
      if (_showExplosion && mounted) {
        setState(() => _explosionPhase += 0.02);
        if (_explosionPhase > 1.5) _showExplosion = false;
      }
    });
  }

  @override
  void dispose() {
    _chaseController.dispose();
    _logoController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onComplete,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: NeonAnimatedBuilder(
          animation: Listenable.merge([_chaseController, _bgController, _logoController]),
          builder: (context, _) {
            final screenSize = MediaQuery.of(context).size;
            return CustomPaint(
              painter: _SplashPainter(
                chaseProgress: _chaseController.value,
                bgPhase: _bgController.value,
                logoOpacity: _showLogo ? _logoOpacity.value : 0,
                logoScale: _showLogo ? _logoScale.value : 0,
                showExplosion: _showExplosion,
                explosionPhase: _explosionPhase,
              ),
              size: screenSize,
            );
          },
        ),
      ),
    );
  }
}

/// Painter unico per tutto lo splash: sfondo stelle, inseguimento, esplosione, logo
class _SplashPainter extends CustomPainter {
  final double chaseProgress;
  final double bgPhase;
  final double logoOpacity;
  final double logoScale;
  final bool showExplosion;
  final double explosionPhase;

  _SplashPainter({
    required this.chaseProgress,
    required this.bgPhase,
    required this.logoOpacity,
    required this.logoScale,
    required this.showExplosion,
    required this.explosionPhase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // === 1. SFONDO STELLE ===
    _drawStars(canvas, size);

    // === 2. INSEGUIMENTO NAVICELLA -> DRONE ===
    if (chaseProgress < 1.0) {
      _drawChaseScene(canvas, size);
    }

    // === 3. ESPLOSIONE ===
    if (showExplosion) {
      _drawExplosion(canvas, cx, cy);
    }

    // === 4. LOGO ===
    if (logoOpacity > 0) {
      _drawLogo(canvas, cx, cy, size);
    }
  }

  void _drawStars(Canvas canvas, Size size) {
    final random = math.Random(42);
    final paint = Paint();
    for (int i = 0; i < 60; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final s = 0.5 + random.nextDouble() * 1.5;
      final twinkle = 0.3 + 0.7 * ((math.sin(bgPhase * math.pi * 2 * (1 + random.nextDouble()) + i) + 1) / 2);
      paint
        ..color = Color.fromRGBO(200, 220, 255, twinkle * 0.5)
        ..maskFilter = null;
      canvas.drawCircle(Offset(x, y), s, paint);
    }
  }

  void _drawChaseScene(Canvas canvas, Size size) {
    // Percorso curvo: drone scappa da sinistra a destra con curva
    final t = chaseProgress;

    // Posizione drone (avanti, percorso sinusoidale)
    final droneX = -50 + (size.width + 100) * (t * 1.1).clamp(0, 1);
    final droneY = size.height * 0.5 + math.sin(t * math.pi * 3) * size.height * 0.15;

    // Posizione navicella (insegue con leggero ritardo)
    final shipT = (t - 0.08).clamp(0, 1).toDouble();
    final shipX = -50 + (size.width + 100) * (shipT * 1.1).clamp(0, 1);
    final shipY = size.height * 0.5 + math.sin(shipT * math.pi * 3) * size.height * 0.15;

    // Scia della navicella (trail luminoso)
    for (int i = 1; i <= 12; i++) {
      final trailT = (shipT - i * 0.015).clamp(0, 1).toDouble();
      final tx = -50 + (size.width + 100) * (trailT * 1.1).clamp(0, 1);
      final ty = size.height * 0.5 + math.sin(trailT * math.pi * 3) * size.height * 0.15;
      final alpha = (1 - i / 12.0) * 0.3;
      final trailSize = (1 - i / 12.0) * 4;
      final tp = Paint()
        ..color = Color.fromRGBO(0, 255, 255, alpha)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, trailSize + 1);
      canvas.drawCircle(Offset(tx, ty), trailSize, tp);
    }

    // Proiettili dalla navicella (punti gialli)
    if (t > 0.2) {
      for (int i = 0; i < 3; i++) {
        final bulletT = t - 0.05 * i;
        if (bulletT > 0.2) {
          final bx = shipX + (droneX - shipX) * (0.3 + i * 0.2);
          final by = shipY + (droneY - shipY) * (0.3 + i * 0.2);
          final bp = Paint()
            ..color = const Color(0xFFFFE500)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
          canvas.drawCircle(Offset(bx, by), 2, bp);
        }
      }
    }

    // Drone (rombo rosa)
    _drawDrone(canvas, droneX, droneY, t);

    // Navicella player (triangolo cyan)
    _drawShip(canvas, shipX, shipY, shipT);
  }

  void _drawDrone(Canvas canvas, double x, double y, double t) {
    final r = 12.0;
    final rot = t * 15;
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(rot);

    // Glow
    final gp = Paint()
      ..color = const Color(0xFFFF00AA).withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    final path = Path()..moveTo(0, -r)..lineTo(r, 0)..lineTo(0, r)..lineTo(-r, 0)..close();
    canvas.drawPath(path, gp);
    // Corpo
    gp.color = const Color(0xFFFF00AA);
    gp.maskFilter = null;
    canvas.drawPath(path, gp);
    canvas.restore();
  }

  void _drawShip(Canvas canvas, double x, double y, double t) {
    canvas.save();
    canvas.translate(x, y);
    // Punta verso la direzione di movimento
    final angle = math.sin(t * math.pi * 3) * 0.3;
    canvas.rotate(angle - math.pi / 2);

    // Glow
    final gp = Paint()
      ..color = const Color(0xFF00FFFF).withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    final path = Path()..moveTo(0, -16)..lineTo(-10, 10)..lineTo(10, 10)..close();
    canvas.drawPath(path, gp);
    // Corpo
    gp.color = const Color(0xFF00FFFF);
    gp.maskFilter = null;
    canvas.drawPath(path, gp);
    // Cockpit
    final cp = Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.7);
    canvas.drawCircle(const Offset(0, -2), 2.5, cp);
    // Thruster
    final fp = Paint()
      ..color = const Color(0xFFFF6600).withValues(alpha: 0.8)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(Offset(0, 12 + math.sin(t * 50) * 2), 3, fp);
    canvas.restore();
  }

  void _drawExplosion(Canvas canvas, double cx, double cy) {
    final p = explosionPhase;
    // Flash bianco
    if (p < 0.3) {
      final alpha = (1 - p / 0.3) * 0.6;
      canvas.drawRect(
        Rect.fromLTWH(0, 0, cx * 2, cy * 2),
        Paint()..color = Color.fromRGBO(255, 255, 255, alpha),
      );
    }
    // Cerchi espansivi
    for (int i = 0; i < 3; i++) {
      final r = p * 150 + i * 30;
      final alpha = (1 - p).clamp(0, 1) * 0.4;
      final ep = Paint()
        ..color = Color.fromRGBO(0, 255, 255, alpha.toDouble())
        ..style = PaintingStyle.stroke
        ..strokeWidth = (3 - i).toDouble();
      canvas.drawCircle(Offset(cx, cy), r.toDouble(), ep);
    }
    // Particelle
    final random = math.Random(99);
    for (int i = 0; i < 20; i++) {
      final angle = random.nextDouble() * math.pi * 2;
      final dist = p * (50 + random.nextDouble() * 100);
      final alpha = (1 - p).clamp(0, 1) * 0.6;
      final pp = Paint()
        ..color = Color.fromRGBO(0, 255, 255, alpha.toDouble())
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawCircle(
        Offset(cx + math.cos(angle) * dist, cy + math.sin(angle) * dist),
        2, pp,
      );
    }
  }

  void _drawLogo(Canvas canvas, double cx, double cy, Size size) {
    final scale = logoScale;
    final alpha = logoOpacity;

    // Titolo "GEOMETRY FIGHT"
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'GEOMETRY FIGHT',
        style: TextStyle(
          color: Color.fromRGBO(0, 255, 255, alpha),
          fontSize: 42 * scale,
          fontWeight: FontWeight.w900,
          fontFamily: 'monospace',
          letterSpacing: 6,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    // Glow del testo
    final glowPainter = TextPainter(
      text: TextSpan(
        text: 'GEOMETRY FIGHT',
        style: TextStyle(
          color: Color.fromRGBO(0, 255, 255, alpha * 0.3),
          fontSize: 42 * scale,
          fontWeight: FontWeight.w900,
          fontFamily: 'monospace',
          letterSpacing: 6,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final textX = cx - textPainter.width / 2;
    final textY = cy - textPainter.height / 2;
    glowPainter.paint(canvas, Offset(textX, textY));
    textPainter.paint(canvas, Offset(textX, textY));

    // Sottotitolo
    if (alpha > 0.5) {
      final subAlpha = ((alpha - 0.5) * 2).clamp(0, 1).toDouble();
      final subPainter = TextPainter(
        text: TextSpan(
          text: 'TOCCA PER INIZIARE',
          style: TextStyle(
            color: Color.fromRGBO(255, 255, 255, subAlpha * 0.3),
            fontSize: 11,
            fontFamily: 'monospace',
            letterSpacing: 4,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      subPainter.paint(canvas, Offset(cx - subPainter.width / 2, textY + textPainter.height + 20));
    }
  }

  @override
  bool shouldRepaint(covariant _SplashPainter oldDelegate) => true;
}

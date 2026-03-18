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
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // === ANIMAZIONE PRINCIPALE ===
          NeonAnimatedBuilder(
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

          // === TASTO SKIP (sempre visibile, in alto a destra) ===
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 16,
            child: GestureDetector(
              onTap: widget.onComplete,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white24, width: 1),
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.black.withValues(alpha: 0.3),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'SKIP',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.skip_next,
                      color: Colors.white.withValues(alpha: 0.6),
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
    final t = chaseProgress;
    final cx = size.width / 2;
    final cy = size.height / 2;

    // === PERCORSO: entrano da sinistra, il drone scappa con curve, si avvicinano al centro ===
    // Il drone parte dalla sinistra e si dirige verso il centro-destra con zigzag
    final droneX = size.width * (-0.1 + t * 0.7); // Da -10% a 60% dello schermo
    final droneY = cy + math.sin(t * math.pi * 4) * size.height * 0.12;

    // La navicella insegue con ritardo
    final shipDelay = 0.12;
    final shipT = (t - shipDelay).clamp(0.0, 1.0);
    final shipX = size.width * (-0.1 + shipT * 0.7);
    final shipY = cy + math.sin(shipT * math.pi * 4) * size.height * 0.12;

    // === SCIA DRONE (rosa, più sottile) ===
    for (int i = 1; i <= 8; i++) {
      final dt2 = (t - i * 0.012).clamp(0.0, 1.0);
      final dtx = size.width * (-0.1 + dt2 * 0.7);
      final dty = cy + math.sin(dt2 * math.pi * 4) * size.height * 0.12;
      final a = (1 - i / 8.0) * 0.2;
      final s = (1 - i / 8.0) * 3;
      canvas.drawCircle(
        Offset(dtx, dty), s,
        Paint()..color = Color.fromRGBO(255, 0, 170, a)..maskFilter = MaskFilter.blur(BlurStyle.normal, s),
      );
    }

    // === SCIA NAVICELLA (cyan, luminosa) ===
    for (int i = 1; i <= 12; i++) {
      final st = (shipT - i * 0.012).clamp(0.0, 1.0);
      final stx = size.width * (-0.1 + st * 0.7);
      final sty = cy + math.sin(st * math.pi * 4) * size.height * 0.12;
      final a = (1 - i / 12.0) * 0.35;
      final s = (1 - i / 12.0) * 4;
      canvas.drawCircle(
        Offset(stx, sty), s,
        Paint()..color = Color.fromRGBO(0, 255, 255, a)..maskFilter = MaskFilter.blur(BlurStyle.normal, s + 1),
      );
    }

    // === PROIETTILI: sparati dalla navicella verso il drone ===
    // Ogni proiettile viaggia dal punto di sparo verso dove era il drone
    if (t > 0.15 && t < 0.95) {
      for (int i = 0; i < 5; i++) {
        // Ogni proiettile ha un momento di sparo diverso
        final fireTime = 0.15 + i * 0.14;
        if (t > fireTime) {
          final bulletAge = (t - fireTime) / 0.12; // Velocità proiettile
          if (bulletAge < 1.0) {
            // Posizione di sparo (dove era la navicella)
            final fst = (fireTime - shipDelay).clamp(0.0, 1.0);
            final fromX = size.width * (-0.1 + fst * 0.7);
            final fromY = cy + math.sin(fst * math.pi * 4) * size.height * 0.12;
            // Posizione target (dove era il drone)
            final toX = size.width * (-0.1 + fireTime * 0.7);
            final toY = cy + math.sin(fireTime * math.pi * 4) * size.height * 0.12;
            // Interpola posizione proiettile
            final bx = fromX + (toX - fromX) * bulletAge * 2; // Proiettile più veloce
            final by = fromY + (toY - fromY) * bulletAge * 2;

            // Trail del proiettile
            final trailPaint = Paint()
              ..color = const Color(0xFFFFE500).withValues(alpha: 0.3)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
            canvas.drawCircle(Offset(bx - (toX - fromX) * 0.05, by - (toY - fromY) * 0.05), 1.5, trailPaint);

            // Proiettile principale
            final bp = Paint()
              ..color = const Color(0xFFFFE500)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
            canvas.drawCircle(Offset(bx, by), 2.5, bp);

            // Impatto: quando il proiettile raggiunge il drone, flash
            if (bulletAge > 0.45 && bulletAge < 0.55) {
              final impactPaint = Paint()
                ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.4)
                ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
              canvas.drawCircle(Offset(droneX, droneY), 15, impactPaint);
            }
          }
        }
      }
    }

    // === DRONE che lampeggia quando viene colpito (ultimi 20% dell'animazione) ===
    final droneHit = t > 0.8;
    if (!droneHit || ((t * 30).toInt() % 2 == 0)) {
      _drawDrone(canvas, droneX, droneY, t);
    }

    // === NAVICELLA ===
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
    // La navicella punta verso DESTRA (direzione di movimento) con leggera oscillazione
    final wobble = math.sin(t * math.pi * 4) * 0.2;
    canvas.rotate(wobble); // 0 = punta a destra

    // Forma nave identica al gioco: freccia con ali che punta a DESTRA
    // (nel gioco la punta è in alto perché è ruotata, qui punta a destra)
    final s = 1.0;
    final shipPath = Path()
      ..moveTo(16 * s, 0)           // Punta (destra)
      ..lineTo(6 * s, -4 * s)      // Lato sopra punta
      ..lineTo(-10 * s, -13 * s)   // Ala sopra esterna
      ..lineTo(-8 * s, -8 * s)     // Rientro ala sopra
      ..lineTo(-14 * s, -5 * s)    // Coda sopra
      ..lineTo(-10 * s, 0)         // Centro coda
      ..lineTo(-14 * s, 5 * s)     // Coda sotto
      ..lineTo(-8 * s, 8 * s)      // Rientro ala sotto
      ..lineTo(-10 * s, 13 * s)    // Ala sotto esterna
      ..lineTo(6 * s, 4 * s)       // Lato sotto punta
      ..close();

    // Glow
    final gp = Paint()
      ..color = const Color(0xFF00FFFF).withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawPath(shipPath, gp);
    // Corpo
    gp.color = const Color(0xFF00FFFF);
    gp.maskFilter = null;
    canvas.drawPath(shipPath, gp);
    // Cockpit (verso la punta)
    final cp = Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.7);
    canvas.drawCircle(const Offset(5, 0), 2.5, cp);
    // Thruster (dietro, a sinistra della nave)
    final thrusterSize = 3 + math.sin(t * 50) * 1.5;
    final fp = Paint()
      ..color = const Color(0xFFFF6600).withValues(alpha: 0.8)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(Offset(-13, -4), thrusterSize, fp);
    canvas.drawCircle(Offset(-13, 4), thrusterSize, fp);
    // Wing-tip lights
    final leftLight = Paint()..color = Color.fromRGBO(255, 50, 50, 0.6 + math.sin(t * 8) * 0.3);
    canvas.drawCircle(const Offset(-10, -12), 1.5, leftLight);
    final rightLight = Paint()..color = Color.fromRGBO(50, 255, 100, 0.6 + math.sin(t * 8) * 0.3);
    canvas.drawCircle(const Offset(-10, 12), 1.5, rightLight);
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

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
  late AnimationController _chaseController;
  late AnimationController _logoController;
  late AnimationController _bgController;

  late Animation<double> _logoOpacity;
  late Animation<double> _logoScale;

  bool _showLogo = false;
  bool _showExplosion = false;
  double _explosionPhase = 0;

  @override
  void initState() {
    super.initState();

    // Fase 1: Inseguimento (3.5 secondi — più lungo e cinematografico)
    _chaseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    );

    // Fase 2: Logo (dopo esplosione)
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: const Interval(0.0, 0.4)),
    );
    _logoScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    // Background continuo
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _chaseController.forward();
    _chaseController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() {
          _showExplosion = true;
          _showLogo = true;
        });
        _logoController.forward();
        Future.delayed(const Duration(milliseconds: 2200), () {
          if (mounted) widget.onComplete();
        });
      }
    });

    _bgController.addListener(() {
      if (_showExplosion && mounted) {
        setState(() => _explosionPhase += 0.018);
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
      body: GestureDetector(
        onTap: widget.onComplete,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
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

            // SKIP button
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
                      Icon(Icons.skip_next,
                          color: Colors.white.withValues(alpha: 0.6), size: 16),
                    ],
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

    _drawNebula(canvas, size);
    _drawScrollingBg(canvas, size);
    _drawStars(canvas, size);

    if (chaseProgress > 0.05 && chaseProgress < 1.0) {
      _drawSpeedLines(canvas, size);
    }

    if (chaseProgress < 1.0) {
      _drawChaseScene(canvas, size);
    }

    if (showExplosion) {
      _drawExplosion(canvas, cx, cy, size);
    }

    if (logoOpacity > 0) {
      _drawLogo(canvas, cx, cy, size);
    }
  }

  // === NEBULOSA (sfondo colorato sfumato) ===
  void _drawNebula(Canvas canvas, Size size) {
    final paint = Paint();

    // Nebulosa blu-viola in alto a sinistra
    final p1 = Offset(size.width * 0.2, size.height * 0.3);
    final pulse1 = 0.03 + math.sin(bgPhase * math.pi * 2) * 0.01;
    paint.shader = RadialGradient(
      colors: [
        Color.fromRGBO(30, 0, 100, pulse1),
        Colors.transparent,
      ],
    ).createShader(Rect.fromCircle(center: p1, radius: size.width * 0.5));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Nebulosa cyan in basso a destra
    final p2 = Offset(size.width * 0.8, size.height * 0.7);
    final pulse2 = 0.02 + math.sin(bgPhase * math.pi * 2 + 2) * 0.01;
    paint.shader = RadialGradient(
      colors: [
        Color.fromRGBO(0, 50, 80, pulse2),
        Colors.transparent,
      ],
    ).createShader(Rect.fromCircle(center: p2, radius: size.width * 0.4));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    paint.shader = null;
  }

  // === SFONDO SCORREVOLE veloce (strie da destra a sinistra) ===
  void _drawScrollingBg(Canvas canvas, Size size) {
    if (chaseProgress < 0.03) return;
    final intensity = (chaseProgress * 2.0).clamp(0.0, 1.0);
    final paint = Paint()..strokeCap = StrokeCap.round;
    final rng = math.Random(33);

    for (int i = 0; i < 60; i++) {
      final y = rng.nextDouble() * size.height;
      final baseLen = 20.0 + rng.nextDouble() * 100.0;
      final speedFactor = 400.0 + rng.nextDouble() * 600.0;
      final baseX = rng.nextDouble() * size.width * 2;
      final travel = chaseProgress * speedFactor;
      final x = ((baseX - travel) % (size.width + baseLen + 50)) - baseLen;
      final alpha = (0.03 + rng.nextDouble() * 0.06) * intensity;
      final strokeW = 0.2 + rng.nextDouble() * 0.6;
      paint.color = Color.fromRGBO(160, 210, 255, alpha);
      paint.strokeWidth = strokeW;
      canvas.drawLine(Offset(x, y), Offset(x + baseLen, y), paint);
    }

    // Strie più luminose (poche, molto veloci)
    final rng2 = math.Random(77);
    for (int i = 0; i < 12; i++) {
      final y = rng2.nextDouble() * size.height;
      final baseLen = 40.0 + rng2.nextDouble() * 120.0;
      final speedFactor = 900.0 + rng2.nextDouble() * 500.0;
      final baseX = rng2.nextDouble() * size.width * 2;
      final travel = chaseProgress * speedFactor;
      final x = ((baseX - travel) % (size.width + baseLen + 50)) - baseLen;
      final alpha = (0.06 + rng2.nextDouble() * 0.08) * intensity;
      paint.color = Color.fromRGBO(220, 240, 255, alpha);
      paint.strokeWidth = 0.8;
      canvas.drawLine(Offset(x, y), Offset(x + baseLen, y), paint);
    }
  }

  // === STELLE con parallax (3 layer di profondità) ===
  void _drawStars(Canvas canvas, Size size) {
    final random = math.Random(42);
    final paint = Paint();

    // Layer lontano: piccole, molte, lente
    for (int i = 0; i < 80; i++) {
      final baseX = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final parallax = bgPhase * 20 + (chaseProgress * 200);
      final x = (baseX - parallax) % size.width;
      final s = 0.3 + random.nextDouble() * 0.7;
      final twinkle = 0.2 + 0.5 * ((math.sin(bgPhase * math.pi * 2 * (0.5 + random.nextDouble()) + i) + 1) / 2);
      paint.color = Color.fromRGBO(180, 200, 255, twinkle * 0.4);
      canvas.drawCircle(Offset(x, y), s, paint);
    }

    // Layer medio: medie, moderate
    for (int i = 0; i < 30; i++) {
      final baseX = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final parallax = bgPhase * 40 + (chaseProgress * 500);
      final x = (baseX - parallax) % size.width;
      final s = 0.5 + random.nextDouble() * 1.2;
      final twinkle = 0.3 + 0.7 * ((math.sin(bgPhase * math.pi * 2 * (1 + random.nextDouble()) + i * 3) + 1) / 2);
      paint.color = Color.fromRGBO(200, 220, 255, twinkle * 0.6);
      canvas.drawCircle(Offset(x, y), s, paint);
    }

    // Layer vicino: grandi, poche, veloci
    for (int i = 0; i < 8; i++) {
      final baseX = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final parallax = bgPhase * 80 + (chaseProgress * 1000);
      final x = (baseX - parallax) % size.width;
      final s = 1.0 + random.nextDouble() * 1.5;
      final twinkle = 0.4 + 0.6 * ((math.sin(bgPhase * math.pi * 2 * (2 + random.nextDouble()) + i * 7) + 1) / 2);
      paint.color = Color.fromRGBO(220, 240, 255, twinkle * 0.7);
      canvas.drawCircle(Offset(x, y), s, paint);
    }
  }

  // === LINEE DI VELOCITÀ (effetto warp) ===
  void _drawSpeedLines(Canvas canvas, Size size) {
    final random = math.Random(77);
    final intensity = (chaseProgress * 2).clamp(0.0, 1.0);
    final paint = Paint()..strokeWidth = 0.5;

    for (int i = 0; i < 15; i++) {
      final y = random.nextDouble() * size.height;
      final baseLen = 20 + random.nextDouble() * 40;
      final len = baseLen * intensity;
      final x = (random.nextDouble() * size.width * 1.5 - chaseProgress * size.width * 2) % (size.width + len);
      final alpha = 0.08 + random.nextDouble() * 0.07;
      paint.color = Color.fromRGBO(100, 180, 255, alpha * intensity);
      canvas.drawLine(Offset(x, y), Offset(x + len, y), paint);
    }
  }

  void _drawChaseScene(Canvas canvas, Size size) {
    final t = chaseProgress;
    final cy = size.height / 2;

    // === PERCORSO: entrano da sinistra, il drone scappa con zigzag ampio ===
    final droneX = size.width * (-0.15 + t * 0.75);
    final droneY = cy + math.sin(t * math.pi * 5) * size.height * 0.13
        + math.cos(t * math.pi * 3) * size.height * 0.05;

    // La navicella insegue con ritardo
    const shipDelay = 0.1;
    final shipT = (t - shipDelay).clamp(0.0, 1.0);
    final shipX = size.width * (-0.15 + shipT * 0.75);
    final shipY = cy + math.sin(shipT * math.pi * 5) * size.height * 0.13
        + math.cos(shipT * math.pi * 3) * size.height * 0.05;

    // === SCIA DRONE (rosa, particelle sfumate) ===
    for (int i = 1; i <= 12; i++) {
      final dt2 = (t - i * 0.01).clamp(0.0, 1.0);
      final dtx = size.width * (-0.15 + dt2 * 0.75);
      final dty = cy + math.sin(dt2 * math.pi * 5) * size.height * 0.13
          + math.cos(dt2 * math.pi * 3) * size.height * 0.05;
      final a = (1 - i / 12.0) * 0.25;
      final s = (1 - i / 12.0) * 4;
      canvas.drawCircle(
        Offset(dtx, dty), s,
        Paint()
          ..color = Color.fromRGBO(255, 0, 170, a)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, s),
      );
    }

    // === SCIA NAVICELLA (cyan, lunga e luminosa) ===
    for (int i = 1; i <= 18; i++) {
      final st = (shipT - i * 0.008).clamp(0.0, 1.0);
      final stx = size.width * (-0.15 + st * 0.75);
      final sty = cy + math.sin(st * math.pi * 5) * size.height * 0.13
          + math.cos(st * math.pi * 3) * size.height * 0.05;
      final a = (1 - i / 18.0) * 0.35;
      final s = (1 - i / 18.0) * 5;
      canvas.drawCircle(
        Offset(stx, sty), s,
        Paint()
          ..color = Color.fromRGBO(0, 255, 255, a)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, s + 1),
      );
    }

    // === PROIETTILI multipli con raffica ===
    if (t > 0.1 && t < 0.95) {
      for (int i = 0; i < 7; i++) {
        final fireTime = 0.10 + i * 0.11;
        if (t > fireTime) {
          final bulletAge = (t - fireTime) / 0.10;
          if (bulletAge < 1.0) {
            final fst = (fireTime - shipDelay).clamp(0.0, 1.0);
            final fromX = size.width * (-0.15 + fst * 0.75);
            final fromY = cy + math.sin(fst * math.pi * 5) * size.height * 0.13
                + math.cos(fst * math.pi * 3) * size.height * 0.05;
            final toX = size.width * (-0.15 + fireTime * 0.75);
            final toY = cy + math.sin(fireTime * math.pi * 5) * size.height * 0.13
                + math.cos(fireTime * math.pi * 3) * size.height * 0.05;
            final bx = fromX + (toX - fromX) * bulletAge * 2.5;
            final by = fromY + (toY - fromY) * bulletAge * 2.5;

            // Trail proiettile
            final trailPaint = Paint()
              ..color = const Color(0xFFFFE500).withValues(alpha: 0.25)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
            final dx = (toX - fromX);
            final dy = (toY - fromY);
            final dist = math.sqrt(dx * dx + dy * dy);
            if (dist > 0) {
              final nx = dx / dist;
              final ny = dy / dist;
              canvas.drawLine(
                Offset(bx, by),
                Offset(bx - nx * 8, by - ny * 8),
                trailPaint,
              );
            }

            // Proiettile
            canvas.drawCircle(
              Offset(bx, by), 2.5,
              Paint()
                ..color = const Color(0xFFFFE500)
                ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
            );

            // Impatto flash
            if (bulletAge > 0.4 && bulletAge < 0.55) {
              canvas.drawCircle(
                Offset(droneX, droneY), 18,
                Paint()
                  ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.3)
                  ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
              );
            }
          }
        }
      }
    }

    // === DRONE (lampeggia quando colpito) ===
    final droneHit = t > 0.75;
    if (!droneHit || ((t * 35).toInt() % 2 == 0)) {
      _drawDrone(canvas, droneX, droneY, t, droneHit);
    }

    // Fumo dal drone quando danneggiato
    if (droneHit) {
      final random = math.Random(55);
      for (int i = 0; i < 5; i++) {
        final smokeAge = ((t - 0.75) * 4 + i * 0.3) % 1.0;
        final sx = droneX - 5 + random.nextDouble() * 10 - smokeAge * 20;
        final sy = droneY + random.nextDouble() * 6 - 3;
        final sa = (1 - smokeAge) * 0.2;
        canvas.drawCircle(
          Offset(sx, sy), 2 + smokeAge * 4,
          Paint()..color = Color.fromRGBO(255, 100, 0, sa),
        );
      }
    }

    // === NAVICELLA ===
    _drawShip(canvas, shipX, shipY, shipT);
  }

  void _drawDrone(Canvas canvas, double x, double y, double t, bool damaged) {
    final r = 14.0;
    final rot = t * 18;
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(rot);

    final path = Path()
      ..moveTo(0, -r)..lineTo(r, 0)..lineTo(0, r)..lineTo(-r, 0)..close();

    // Glow esterno
    canvas.drawPath(path, Paint()
      ..color = Color.fromRGBO(255, 0, 170, damaged ? 0.15 : 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12));

    // Corpo
    canvas.drawPath(path, Paint()
      ..color = damaged
          ? Color.fromRGBO(255, 100, 50, 0.8)
          : const Color(0xFFFF00AA));

    // Rombo interno
    final ir = r * 0.45;
    final innerPath = Path()
      ..moveTo(0, -ir)..lineTo(ir, 0)..lineTo(0, ir)..lineTo(-ir, 0)..close();
    canvas.drawPath(innerPath, Paint()
      ..color = const Color(0xFFFF00AA).withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8);

    // Nucleo
    canvas.drawCircle(Offset.zero, r * 0.15, Paint()
      ..color = Color.fromRGBO(255, 255, 255, 0.5 + math.sin(t * 20) * 0.3));

    canvas.restore();
  }

  void _drawShip(Canvas canvas, double x, double y, double t) {
    canvas.save();
    canvas.translate(x, y);
    final wobble = math.sin(t * math.pi * 5) * 0.15;
    canvas.rotate(wobble);

    const s = 1.2; // Leggermente più grande
    final shipPath = Path()
      ..moveTo(16 * s, 0)
      ..lineTo(6 * s, -4 * s)
      ..lineTo(-10 * s, -13 * s)
      ..lineTo(-8 * s, -8 * s)
      ..lineTo(-14 * s, -5 * s)
      ..lineTo(-10 * s, 0)
      ..lineTo(-14 * s, 5 * s)
      ..lineTo(-8 * s, 8 * s)
      ..lineTo(-10 * s, 13 * s)
      ..lineTo(6 * s, 4 * s)
      ..close();

    // Glow esterno
    canvas.drawPath(shipPath, Paint()
      ..color = const Color(0xFF00FFFF).withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15));

    // Corpo
    canvas.drawPath(shipPath, Paint()..color = const Color(0xFF00FFFF));

    // Bordo luminoso
    canvas.drawPath(shipPath, Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8);

    // Cockpit
    canvas.drawCircle(const Offset(6, 0), 2.5, Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.8));

    // Thruster animati (fiamma più grande e dinamica)
    final thrustBase = 4 + math.sin(t * 60) * 2;
    final thrustLen = 6 + math.sin(t * 45) * 3;
    // Fiamme
    final flamePath1 = Path()
      ..moveTo(-14 * s, -4 * s)
      ..lineTo(-14 * s - thrustLen, -4 * s + 1)
      ..lineTo(-14 * s - thrustLen * 0.7, -4 * s - 1)
      ..close();
    final flamePath2 = Path()
      ..moveTo(-14 * s, 4 * s)
      ..lineTo(-14 * s - thrustLen, 4 * s - 1)
      ..lineTo(-14 * s - thrustLen * 0.7, 4 * s + 1)
      ..close();
    final flamePaint = Paint()
      ..color = const Color(0xFFFF6600).withValues(alpha: 0.8)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawPath(flamePath1, flamePaint);
    canvas.drawPath(flamePath2, flamePaint);

    // Nucleo fiamma (bianco)
    canvas.drawCircle(Offset(-14 * s, -4 * s), thrustBase * 0.4, Paint()
      ..color = const Color(0xFFFFCC00).withValues(alpha: 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));
    canvas.drawCircle(Offset(-14 * s, 4 * s), thrustBase * 0.4, Paint()
      ..color = const Color(0xFFFFCC00).withValues(alpha: 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));

    // Wing-tip lights
    canvas.drawCircle(const Offset(-12, -15), 1.5, Paint()
      ..color = Color.fromRGBO(255, 50, 50, 0.6 + math.sin(t * 8) * 0.3));
    canvas.drawCircle(const Offset(-12, 15), 1.5, Paint()
      ..color = Color.fromRGBO(50, 255, 100, 0.6 + math.sin(t * 8) * 0.3));

    canvas.restore();
  }

  void _drawExplosion(Canvas canvas, double cx, double cy, Size size) {
    final p = explosionPhase;

    // Flash bianco intenso
    if (p < 0.25) {
      final alpha = (1 - p / 0.25) * 0.8;
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = Color.fromRGBO(255, 255, 255, alpha),
      );
    }

    // Shockwave ring (anello che si espande)
    if (p < 0.8) {
      final ringR = p * size.width * 0.4;
      final ringAlpha = (1 - p / 0.8) * 0.5;
      canvas.drawCircle(
        Offset(cx, cy), ringR,
        Paint()
          ..color = Color.fromRGBO(0, 255, 255, ringAlpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3 * (1 - p / 0.8),
      );
    }

    // Cerchi concentrici multipli
    for (int i = 0; i < 4; i++) {
      final delay = i * 0.06;
      final rp = (p - delay).clamp(0.0, 1.5);
      if (rp <= 0) continue;
      final r = rp * 120 + i * 20;
      final alpha = (1 - rp / 1.5).clamp(0, 1) * 0.35;
      canvas.drawCircle(
        Offset(cx, cy), r.toDouble(),
        Paint()
          ..color = Color.fromRGBO(0, 255, 255, alpha.toDouble())
          ..style = PaintingStyle.stroke
          ..strokeWidth = (3 - i * 0.5).clamp(0.5, 3),
      );
    }

    // Particelle esplosione (più numerose e colorate)
    final random = math.Random(99);
    for (int i = 0; i < 35; i++) {
      final angle = random.nextDouble() * math.pi * 2;
      final speed = 60 + random.nextDouble() * 140;
      final dist = p * speed;
      final alpha = (1 - p).clamp(0, 1) * 0.7;
      final pSize = 1.5 + random.nextDouble() * 2.5;
      // Mix di colori: cyan, bianco, rosa
      final colorChoice = i % 3;
      final color = colorChoice == 0
          ? Color.fromRGBO(0, 255, 255, alpha.toDouble())
          : colorChoice == 1
              ? Color.fromRGBO(255, 255, 255, alpha.toDouble())
              : Color.fromRGBO(255, 0, 170, alpha.toDouble() * 0.6);
      canvas.drawCircle(
        Offset(cx + math.cos(angle) * dist, cy + math.sin(angle) * dist),
        pSize * (1 - p * 0.5).clamp(0.3, 1),
        Paint()
          ..color = color
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
    }

    // Detriti (linee che volano via)
    for (int i = 0; i < 12; i++) {
      final angle = random.nextDouble() * math.pi * 2;
      final dist = p * (80 + random.nextDouble() * 100);
      final alpha = (1 - p).clamp(0, 1) * 0.4;
      final dx = math.cos(angle);
      final dy = math.sin(angle);
      final sx = cx + dx * dist;
      final sy = cy + dy * dist;
      canvas.drawLine(
        Offset(sx, sy),
        Offset(sx + dx * 6, sy + dy * 6),
        Paint()
          ..color = Color.fromRGBO(0, 255, 255, alpha.toDouble())
          ..strokeWidth = 1,
      );
    }
  }

  void _drawLogo(Canvas canvas, double cx, double cy, Size size) {
    final scale = logoScale;
    final alpha = logoOpacity;

    // Linea decorativa sopra il titolo
    if (alpha > 0.3) {
      final lineAlpha = ((alpha - 0.3) / 0.7).clamp(0.0, 1.0);
      final lineW = 100 * scale * lineAlpha;
      final lineY = cy - 35 * scale;
      canvas.drawLine(
        Offset(cx - lineW, lineY),
        Offset(cx + lineW, lineY),
        Paint()
          ..color = Color.fromRGBO(0, 255, 255, lineAlpha * 0.3)
          ..strokeWidth = 1,
      );
    }

    // Glow dietro il testo
    if (alpha > 0.2) {
      canvas.drawCircle(
        Offset(cx, cy),
        80 * scale,
        Paint()
          ..color = Color.fromRGBO(0, 255, 255, alpha * 0.05)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40),
      );
    }

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
          shadows: [
            Shadow(
              color: Color.fromRGBO(0, 255, 255, alpha * 0.5),
              blurRadius: 20,
            ),
            Shadow(
              color: Color.fromRGBO(0, 150, 255, alpha * 0.3),
              blurRadius: 40,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final textX = cx - textPainter.width / 2;
    final textY = cy - textPainter.height / 2;
    textPainter.paint(canvas, Offset(textX, textY));

    // Linea decorativa sotto
    if (alpha > 0.3) {
      final lineAlpha = ((alpha - 0.3) / 0.7).clamp(0.0, 1.0);
      final lineW = 100 * scale * lineAlpha;
      final lineY2 = cy + 30 * scale;
      canvas.drawLine(
        Offset(cx - lineW, lineY2),
        Offset(cx + lineW, lineY2),
        Paint()
          ..color = Color.fromRGBO(0, 255, 255, lineAlpha * 0.3)
          ..strokeWidth = 1,
      );
    }

    // Sottotitolo
    if (alpha > 0.5) {
      final subAlpha = ((alpha - 0.5) * 2).clamp(0, 1).toDouble();
      // Pulsazione del sottotitolo
      final pulse = 0.3 + math.sin(bgPhase * math.pi * 4) * 0.15;
      final subPainter = TextPainter(
        text: TextSpan(
          text: 'TOCCA PER INIZIARE',
          style: TextStyle(
            color: Color.fromRGBO(255, 255, 255, subAlpha * pulse),
            fontSize: 12,
            fontFamily: 'monospace',
            letterSpacing: 5,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      subPainter.paint(canvas, Offset(cx - subPainter.width / 2, textY + textPainter.height + 30));
    }
  }

  @override
  bool shouldRepaint(covariant _SplashPainter oldDelegate) => true;
}

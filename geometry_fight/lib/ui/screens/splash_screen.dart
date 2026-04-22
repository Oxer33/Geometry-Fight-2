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

  // Paint cache statici — evitano migliaia di alloc/sec durante la splash.
  // Il chase-scene renderizza 18 trail nave × 2 layer × 60fps = 2160 alloc,
  // più 5 bullet × 4 trail × 60fps = 1200 alloc. Riutilizziamo un Paint per
  // famiglia con `.color =` per update inline.
  static final Paint _droneTrailPaint = Paint();
  static final Paint _shipTrailGlowPaint = Paint();
  static final Paint _shipTrailCorePaint = Paint();
  static final Paint _bulletTrailPaint = Paint();
  static final Paint _bulletGlowPaint = Paint();
  static final Paint _bulletBodyPaint = Paint();
  static final Paint _bulletCorePaint = Paint();
  static final Paint _muzzleGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  static final Paint _muzzleCorePaint = Paint();
  static final Paint _impactGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
  static final Paint _impactCorePaint = Paint();

  // Ship paint cache (10 Paint allocs/frame → 0)
  static final Paint _shipGlowPaint = Paint()
    ..color = const Color(0xFF00FFFF).withValues(alpha: 0.25)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
  static final Paint _shipBodyPaint = Paint()
    ..color = const Color(0xFF00FFFF);
  static final Paint _shipStrokePaint = Paint()
    ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.35)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;
  static final Paint _cockpitHaloPaint = Paint();
  static final Paint _cockpitWhitePaint = Paint();
  static final Paint _cockpitCyanPaint = Paint();
  static final Paint _shipLinePaint = Paint()
    ..color = const Color(0xFF00FFFF).withValues(alpha: 0.35)
    ..strokeWidth = 0.6
    ..style = PaintingStyle.stroke;
  static final Paint _wingRedGlowPaint = Paint();
  static final Paint _wingRedCorePaint = Paint();
  static final Paint _wingGreenGlowPaint = Paint();
  static final Paint _wingGreenCorePaint = Paint();

  // Flame paint cache (6 allocs/frame → 0)
  static final Paint _flameOuterPaint = Paint()
    ..color = const Color(0xFFFF2200).withValues(alpha: 0.25)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  static final Paint _flameMidPaint = Paint()
    ..color = const Color(0xFFFF6600).withValues(alpha: 0.75);
  static final Paint _flameCorePaint = Paint()
    ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.9);

  // Drone paint cache (6+ allocs/frame → 0)
  static final Paint _droneGlowPaint = Paint();
  static final Paint _droneFillPaint = Paint();
  static final Paint _droneStrokePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0;
  static final Paint _droneInnerPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;
  static final Paint _droneVertexPaint = Paint();
  static final Paint _droneCoreHaloPaint = Paint();
  static final Paint _droneCorePaint = Paint();

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
  // 3x particelle, 2x velocità base, variate per parallasse
  void _drawScrollingBg(Canvas canvas, Size size) {
    if (chaseProgress < 0.03) return;
    final intensity = (chaseProgress * 2.0).clamp(0.0, 1.0);
    final paint = Paint()..strokeCap = StrokeCap.round;
    final rng = math.Random(33);

    // Strie lente: 60 → 180
    for (int i = 0; i < 180; i++) {
      final y = rng.nextDouble() * size.height;
      final baseLen = 20.0 + rng.nextDouble() * 100.0;
      // Velocità variata con moltiplicatore individuale per parallasse
      final speedMul = 0.6 + rng.nextDouble() * 1.8;
      final speedFactor = (400.0 + rng.nextDouble() * 600.0) * 2.0 * speedMul;
      final baseX = rng.nextDouble() * size.width * 2;
      final travel = chaseProgress * speedFactor;
      final x = ((baseX - travel) % (size.width + baseLen + 50)) - baseLen;
      final alpha = (0.03 + rng.nextDouble() * 0.06) * intensity;
      final strokeW = 0.2 + rng.nextDouble() * 0.6;
      paint.color = Color.fromRGBO(160, 210, 255, alpha);
      paint.strokeWidth = strokeW;
      canvas.drawLine(Offset(x, y), Offset(x + baseLen, y), paint);
    }

    // Strie più luminose (veloci): 12 → 36
    final rng2 = math.Random(77);
    for (int i = 0; i < 36; i++) {
      final y = rng2.nextDouble() * size.height;
      final baseLen = 40.0 + rng2.nextDouble() * 120.0;
      final speedMul = 0.8 + rng2.nextDouble() * 2.2;
      final speedFactor = (900.0 + rng2.nextDouble() * 500.0) * 2.0 * speedMul;
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
  // 3x particelle, 2x velocità base, variate per parallasse
  void _drawStars(Canvas canvas, Size size) {
    final random = math.Random(42);
    final paint = Paint();

    // Layer lontano: 80 → 240, velocità base x2 con variazione individuale
    for (int i = 0; i < 240; i++) {
      final baseX = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final speedMul = 0.5 + random.nextDouble() * 1.5;
      final parallax = bgPhase * 40 * speedMul + (chaseProgress * 400 * speedMul);
      final x = (baseX - parallax) % size.width;
      final s = 0.3 + random.nextDouble() * 0.7;
      final twinkle = 0.2 + 0.5 * ((math.sin(bgPhase * math.pi * 2 * (0.5 + random.nextDouble()) + i) + 1) / 2);
      paint.color = Color.fromRGBO(180, 200, 255, twinkle * 0.4);
      canvas.drawCircle(Offset(x, y), s, paint);
    }

    // Layer medio: 30 → 90
    for (int i = 0; i < 90; i++) {
      final baseX = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final speedMul = 0.6 + random.nextDouble() * 1.8;
      final parallax = bgPhase * 80 * speedMul + (chaseProgress * 1000 * speedMul);
      final x = (baseX - parallax) % size.width;
      final s = 0.5 + random.nextDouble() * 1.2;
      final twinkle = 0.3 + 0.7 * ((math.sin(bgPhase * math.pi * 2 * (1 + random.nextDouble()) + i * 3) + 1) / 2);
      paint.color = Color.fromRGBO(200, 220, 255, twinkle * 0.6);
      canvas.drawCircle(Offset(x, y), s, paint);
    }

    // Layer vicino: 8 → 24, velocità massima variata per profondità
    for (int i = 0; i < 24; i++) {
      final baseX = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final speedMul = 0.7 + random.nextDouble() * 2.3;
      final parallax = bgPhase * 160 * speedMul + (chaseProgress * 2000 * speedMul);
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

    // Angolo di mira: la nave si orienta verso il drone, come in gioco.
    // Convenzione `_rotation = atan2(aim.y, aim.x) + π/2`. Guard su vettore
    // nullo (ship/drone stessa posizione nei primi frame): aim di fallback
    // a destra (0 rad pre-offset) così la nave NON punta verso il basso
    // quando atan2(0,0) = 0.
    final dxAim = droneX - shipX;
    final dyAim = droneY - shipY;
    final aimAngle = (dxAim * dxAim + dyAim * dyAim < 0.01)
        ? math.pi / 2 // muso a destra (default chase direction)
        : math.atan2(dyAim, dxAim) + math.pi / 2;

    // === SCIA DRONE (rosa, particelle sfumate) ===
    // Skip sample non-ancora-storici (come per la ship trail).
    for (int i = 1; i <= 12; i++) {
      final raw = t - i * 0.01;
      if (raw <= 0) break;
      final dt2 = raw.clamp(0.0, 1.0);
      final dtx = size.width * (-0.15 + dt2 * 0.75);
      final dty = cy + math.sin(dt2 * math.pi * 5) * size.height * 0.13
          + math.cos(dt2 * math.pi * 3) * size.height * 0.05;
      final a = (1 - i / 12.0) * 0.25;
      final s = (1 - i / 12.0) * 4;
      // MaskFilter varia col raggio → NON cacheable statico. Assegniamo
      // per-iterazione ma sul Paint condiviso invece di alloc un nuovo Paint.
      _droneTrailPaint.color = Color.fromRGBO(255, 0, 170, a);
      _droneTrailPaint.maskFilter = MaskFilter.blur(BlurStyle.normal, s);
      canvas.drawCircle(Offset(dtx, dty), s, _droneTrailPaint);
    }

    // === SCIA NAVICELLA (cyan — simile al trail del Player in gioco) ===
    // Due layer per ogni punto: soft glow esterno + core luminoso come
    // `Player._renderTrail`. Skip i sample non ancora "storici" (st == 0)
    // quando shipT è prossimo a 0: altrimenti 18 cerchi si sovrappongono
    // sullo stesso punto iniziale al primo frame.
    for (int i = 1; i <= 18; i++) {
      final rawSt = shipT - i * 0.008;
      if (rawSt <= 0) break; // tutti i sample successivi sarebbero clampati
      final st = rawSt.clamp(0.0, 1.0);
      final stx = size.width * (-0.15 + st * 0.75);
      final sty = cy + math.sin(st * math.pi * 5) * size.height * 0.13
          + math.cos(st * math.pi * 3) * size.height * 0.05;
      final a = (1 - i / 18.0) * 0.4;
      final s = (1 - i / 18.0) * 3.5;
      _shipTrailGlowPaint.color =
          const Color(0xFF00FFFF).withValues(alpha: a * 0.4);
      canvas.drawCircle(Offset(stx, sty), s * 1.8, _shipTrailGlowPaint);
      _shipTrailCorePaint.color =
          const Color(0xFF00FFFF).withValues(alpha: a);
      canvas.drawCircle(Offset(stx, sty), s, _shipTrailCorePaint);
    }

    // === PROIETTILI stile in-game `PlayerBullet` (giallo neon + trail) ===
    if (t > 0.1 && t < 0.95) {
      const shotCount = 5;
      const shotInterval = 0.15;
      const bulletColor = Color(0xFFFFE500); // NeonColors.bulletYellow
      for (int i = 0; i < shotCount; i++) {
        final fireTime = 0.10 + i * shotInterval;
        if (t > fireTime) {
          final bulletAge = (t - fireTime) / 0.12;
          // Cutoff a 0.55: bullet sparisce subito dopo l'impact flash
          // (0.4..0.55). Prima restava disegnato sul target per il 45%
          // residuo della vita con il clamp, sembrando "incastrato".
          if (bulletAge < 0.55) {
            final fst = (fireTime - shipDelay).clamp(0.0, 1.0);
            final shipCenterX = size.width * (-0.15 + fst * 0.75);
            final shipCenterY = cy + math.sin(fst * math.pi * 5) * size.height * 0.13
                + math.cos(fst * math.pi * 3) * size.height * 0.05;
            // Bersaglio al momento dello sparo
            final toX = size.width * (-0.15 + fireTime * 0.75);
            final toY = cy + math.sin(fireTime * math.pi * 5) * size.height * 0.13
                + math.cos(fireTime * math.pi * 3) * size.height * 0.05;
            // Origine: muso della nave ruotato verso il bersaglio.
            // Il muso in local è a (0,-14*s) → ruotando di aimAngle-π/2
            // diventa direzione di mira * 14*1.2 ≈ 16.8 px dal centro.
            final shotAim =
                math.atan2(toY - shipCenterY, toX - shipCenterX);
            const noseOffset = 14.0 * 1.2;
            final fromX = shipCenterX + math.cos(shotAim) * noseOffset;
            final fromY = shipCenterY + math.sin(shotAim) * noseOffset;
            // Progress clamp a 1.0 → bullet si ferma sul drone invece di
            // oltrepassarlo (evita il bullet che attraversa il nemico prima
            // del flash di impatto a age 0.55).
            final bulletProgress = (bulletAge * 2.5).clamp(0.0, 1.0);
            final bx = fromX + (toX - fromX) * bulletProgress;
            final by = fromY + (toY - fromY) * bulletProgress;

            // Trail giallo (cerchietti dietro il bullet) usando paint cached.
            final dx = toX - fromX;
            final dy = toY - fromY;
            final dist = math.sqrt(dx * dx + dy * dy);
            if (dist > 0) {
              final nx = dx / dist;
              final ny = dy / dist;
              for (int ti = 1; ti <= 4; ti++) {
                final tAlpha = (1 - ti / 4) * 0.3;
                _bulletTrailPaint.color =
                    bulletColor.withValues(alpha: tAlpha);
                canvas.drawCircle(
                  Offset(bx - nx * ti * 3, by - ny * ti * 3),
                  1.5 * (1 - ti / 4.5),
                  _bulletTrailPaint,
                );
              }
            }

            // Glow + corpo + core del bullet (paint cached)
            _bulletGlowPaint.color = bulletColor.withValues(alpha: 0.35);
            canvas.drawCircle(Offset(bx, by), 4.5, _bulletGlowPaint);
            _bulletBodyPaint.color = bulletColor;
            canvas.drawCircle(Offset(bx, by), 3.0, _bulletBodyPaint);
            _bulletCorePaint.color =
                const Color(0xFFFFFFFF).withValues(alpha: 0.8);
            canvas.drawCircle(Offset(bx, by), 1.2, _bulletCorePaint);

            // Muzzle flash al nose della nave appena sparato
            if (bulletAge < 0.15) {
              final flashAlpha = (1 - bulletAge / 0.15) * 0.7;
              _muzzleGlowPaint.color =
                  bulletColor.withValues(alpha: flashAlpha * 0.5);
              canvas.drawCircle(Offset(fromX, fromY), 8, _muzzleGlowPaint);
              _muzzleCorePaint.color =
                  const Color(0xFFFFFFFF).withValues(alpha: flashAlpha);
              canvas.drawCircle(Offset(fromX, fromY), 4, _muzzleCorePaint);
            }

            // Impatto flash sul drone
            if (bulletAge > 0.4 && bulletAge < 0.55) {
              _impactGlowPaint.color =
                  const Color(0xFFFFFFFF).withValues(alpha: 0.35);
              canvas.drawCircle(
                  Offset(droneX, droneY), 18, _impactGlowPaint);
              _impactCorePaint.color =
                  bulletColor.withValues(alpha: 0.6);
              canvas.drawCircle(
                  Offset(droneX, droneY), 10, _impactCorePaint);
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

    // === NAVICELLA (in-game graphics, ruota verso il drone) ===
    _drawShip(canvas, shipX, shipY, shipT, aimAngle);
  }

  /// Drone nemico stile in-game: rombo con bordo neon stroke (come gli
  /// EnemyBase), glow esterno senza blur pesante, nucleo pulsante bianco.
  void _drawDrone(Canvas canvas, double x, double y, double t, bool damaged) {
    final r = 14.0;
    final rot = t * 18;
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(rot);

    final bodyColor = damaged
        ? const Color(0xFFFF6633)
        : const Color(0xFFFF00AA);

    // ─── GLOW ESTERNO (senza blur: cerchio più grande, alpha basso) ───
    final glowPath = Path()
      ..moveTo(0, -r * 1.4)
      ..lineTo(r * 1.4, 0)
      ..lineTo(0, r * 1.4)
      ..lineTo(-r * 1.4, 0)
      ..close();
    _droneGlowPaint.color = bodyColor.withValues(alpha: 0.25);
    canvas.drawPath(glowPath, _droneGlowPaint);

    // ─── CORPO (stroke neon come EnemyBase in gioco) ───
    final bodyPath = Path()
      ..moveTo(0, -r)
      ..lineTo(r, 0)
      ..lineTo(0, r)
      ..lineTo(-r, 0)
      ..close();
    // Fill interno trasparente
    _droneFillPaint.color = bodyColor.withValues(alpha: 0.35);
    canvas.drawPath(bodyPath, _droneFillPaint);
    // Bordo neon brillante (stile GW enemy)
    _droneStrokePaint.color = bodyColor;
    canvas.drawPath(bodyPath, _droneStrokePaint);

    // ─── ROMBO INTERNO (decorativo) ───
    final ir = r * 0.5;
    final innerPath = Path()
      ..moveTo(0, -ir)
      ..lineTo(ir, 0)
      ..lineTo(0, ir)
      ..lineTo(-ir, 0)
      ..close();
    _droneInnerPaint.color = bodyColor.withValues(alpha: 0.6);
    canvas.drawPath(innerPath, _droneInnerPaint);

    // ─── 4 PUNTI SUI VERTICI ───
    final vertexPulse = 0.5 + math.sin(t * 30) * 0.5;
    _droneVertexPaint.color = bodyColor.withValues(alpha: vertexPulse);
    for (int i = 0; i < 4; i++) {
      final angle = i * math.pi / 2;
      final vx = math.cos(angle) * r * 0.95;
      final vy = math.sin(angle) * r * 0.95;
      canvas.drawCircle(Offset(vx, vy), 1.8, _droneVertexPaint);
    }

    // ─── NUCLEO bianco pulsante ───
    final corePulse = 0.6 + math.sin(t * 20) * 0.4;
    _droneCoreHaloPaint.color =
        const Color(0xFFFFFFFF).withValues(alpha: corePulse * 0.3);
    canvas.drawCircle(Offset.zero, r * 0.3, _droneCoreHaloPaint);
    _droneCorePaint.color =
        const Color(0xFFFFFFFF).withValues(alpha: corePulse);
    canvas.drawCircle(Offset.zero, r * 0.15, _droneCorePaint);

    canvas.restore();
  }

  /// Disegna la navicella con la SAME grafica di gioco (`Player._drawShipBody`
  /// standard + thrusters + cockpit + wing-tip lights), ruotata verso il
  /// bersaglio — stesso meccanismo del `_rotation` in `Player.update`.
  void _drawShip(Canvas canvas, double x, double y, double t, double aimAngle) {
    canvas.save();
    canvas.translate(x, y);
    // Rotazione verso il bersaglio + micro-wobble per vivacità
    final wobble = math.sin(t * math.pi * 5) * 0.08;
    canvas.rotate(aimAngle + wobble);

    // ─── THRUSTERS (disegnati PRIMA del corpo → fiamma dietro) ───
    final thrustPulse = 0.6 + math.sin(t * 30) * 0.4;
    _drawShipFlame(canvas, -5, 13, thrustPulse);
    _drawShipFlame(canvas, 5, 13, thrustPulse);

    // ─── CORPO NAVE (stesso Path di `Player._drawShipBody` standard) ───
    const s = 1.35; // Leggermente più grande per risaltare nel splash
    final shipPath = Path()
      ..moveTo(0, -14 * s)           // Punta
      ..lineTo(4 * s, -6 * s)        // Lato destro punta
      ..lineTo(13 * s, 10 * s)       // Ala destra esterna
      ..lineTo(8 * s, 8 * s)         // Rientro ala destra
      ..lineTo(5 * s, 14 * s)        // Coda destra
      ..lineTo(0, 10 * s)            // Centro coda
      ..lineTo(-5 * s, 14 * s)       // Coda sinistra
      ..lineTo(-8 * s, 8 * s)        // Rientro ala sinistra
      ..lineTo(-13 * s, 10 * s)      // Ala sinistra esterna
      ..lineTo(-4 * s, -6 * s)       // Lato sinistro punta
      ..close();

    // Glow esterno (come `Player.render` layer 3 — `_drawShipBody(1.7)`)
    canvas.drawPath(shipPath, _shipGlowPaint);

    // Corpo principale (cyan pieno)
    canvas.drawPath(shipPath, _shipBodyPaint);

    // Bordo luminoso bianco sottile
    canvas.drawPath(shipPath, _shipStrokePaint);

    // ─── COCKPIT (stesso stile di `Player._renderShipDetails`) ───
    final cockpitGlow = 0.6 + math.sin(t * 10) * 0.2;
    _cockpitHaloPaint.color =
        const Color(0xFFFFFFFF).withValues(alpha: cockpitGlow * 0.5);
    canvas.drawCircle(Offset(0, -4 * s), 5, _cockpitHaloPaint);
    _cockpitWhitePaint.color =
        const Color(0xFFFFFFFF).withValues(alpha: cockpitGlow);
    canvas.drawCircle(Offset(0, -4 * s), 3, _cockpitWhitePaint);
    _cockpitCyanPaint.color =
        const Color(0xFF00FFFF).withValues(alpha: 0.9);
    canvas.drawCircle(Offset(0, -4 * s), 2, _cockpitCyanPaint);

    // Linee strutturali (stesse di `Player._renderShipDetails`)
    canvas.drawLine(
        Offset(-2 * s, 0), Offset(-10 * s, 10 * s), _shipLinePaint);
    canvas.drawLine(
        Offset(2 * s, 0), Offset(10 * s, 10 * s), _shipLinePaint);
    canvas.drawLine(
        Offset(0, -8 * s), Offset(0, 8 * s), _shipLinePaint);

    // ─── WING-TIP LIGHTS (rossa a sx, verde a dx — come in gioco) ───
    final wingPulse = 0.5 + math.sin(t * 15) * 0.5;
    _wingRedGlowPaint.color =
        Color.fromRGBO(255, 50, 50, wingPulse * 0.3);
    canvas.drawCircle(Offset(-12 * s, 10 * s), 4, _wingRedGlowPaint);
    _wingRedCorePaint.color =
        Color.fromRGBO(255, 50, 50, wingPulse * 0.9);
    canvas.drawCircle(Offset(-12 * s, 10 * s), 2, _wingRedCorePaint);
    _wingGreenGlowPaint.color =
        Color.fromRGBO(50, 255, 100, wingPulse * 0.3);
    canvas.drawCircle(Offset(12 * s, 10 * s), 4, _wingGreenGlowPaint);
    _wingGreenCorePaint.color =
        Color.fromRGBO(50, 255, 100, wingPulse * 0.9);
    canvas.drawCircle(Offset(12 * s, 10 * s), 2, _wingGreenCorePaint);

    canvas.restore();
  }

  /// Fiamma thruster: replica di `Player._drawFlame` (paint cache statici).
  void _drawShipFlame(Canvas canvas, double x, double y, double pulse) {
    final length = 10 + pulse * 6;
    const width = 4.0;
    // Strato esterno rosso scuro
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(x, y + length * 0.6),
        width: width * 2.2,
        height: length * 1.3,
      ),
      _flameOuterPaint,
    );
    // Arancione brillante
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(x, y + length * 0.5),
        width: width,
        height: length * 0.7,
      ),
      _flameMidPaint,
    );
    // Core bianco
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(x, y + length * 0.3),
        width: width * 0.6,
        height: length * 0.5,
      ),
      _flameCorePaint,
    );
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

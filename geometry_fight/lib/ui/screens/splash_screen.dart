import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';
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
  // Prevent double-fire quando SKIP tap e 2200ms timer si accavallano.
  bool _completed = false;
  void _fireCompleteOnce() {
    if (_completed) return;
    _completed = true;
    widget.onComplete();
  }

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
          if (mounted) _fireCompleteOnce();
        });
      }
    });

    _bgController.addListener(() {
      if (!mounted) return;
      if (_showExplosion) {
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
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _fireCompleteOnce,
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
                    tapToStartText: l10n.splashTapToStart,
                  ),
                  size: screenSize,
                );
              },
            ),

            // SKIP button — neon fluo con HSV rainbow ciclante
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              right: 16,
              child: GestureDetector(
                onTap: _fireCompleteOnce,
                child: NeonAnimatedBuilder(
                  animation: _bgController,
                  builder: (context, _) {
                    // Hue ciclante da `_bgController` (10s loop) + shift
                    // sinusoidale per pulse extra.
                    final hue = (_bgController.value * 360) % 360;
                    final pulse = 0.6 + math.sin(_bgController.value * math.pi * 4) * 0.4;
                    final neonColor =
                        HSVColor.fromAHSV(1.0, hue, 0.85, 1.0).toColor();
                    final neonColorShift =
                        HSVColor.fromAHSV(1.0, (hue + 90) % 360, 0.85, 1.0).toColor();
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 9),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: neonColor.withValues(alpha: 0.85),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            neonColor.withValues(alpha: 0.18),
                            Colors.black.withValues(alpha: 0.35),
                            neonColorShift.withValues(alpha: 0.18),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: neonColor.withValues(alpha: 0.4 * pulse),
                            blurRadius: 14,
                            spreadRadius: 1,
                          ),
                          BoxShadow(
                            color: neonColorShift.withValues(alpha: 0.25 * pulse),
                            blurRadius: 22,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l10n.splashSkip,
                            style: TextStyle(
                              color: neonColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'monospace',
                              letterSpacing: 2.5,
                              shadows: [
                                Shadow(color: neonColor, blurRadius: 8),
                                Shadow(
                                  color: neonColorShift.withValues(alpha: 0.6),
                                  blurRadius: 16,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 5),
                          Icon(
                            Icons.skip_next,
                            color: neonColor,
                            size: 18,
                            shadows: [
                              Shadow(color: neonColor, blurRadius: 8),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
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
  final String tapToStartText;

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
  // NOTA: `_impactGlowPaint` + `_impactCorePaint` rimossi — il weaver ora
  // schiva tutti i proiettili quindi non c'è mai impact flash.

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

  // Nebula paint cache (2 allocs/frame → 0; shader + .color mutati inline).
  static final Paint _nebulaPaint = Paint();

  // Scrolling bg paint cache (216 linee/frame → 1 Paint; .color/.strokeWidth mutati)
  static final Paint _scrollBgPaint = Paint()..strokeCap = StrokeCap.round;

  // Stars paint cache (354 cerchi/frame × 3 layer → 1 Paint riutilizzato)
  static final Paint _starsPaint = Paint();

  // Speed lines paint cache (15 linee/frame → 1 Paint; strokeWidth costante)
  static final Paint _speedLinesPaint = Paint()..strokeWidth = 0.5;

  // Explosion paint cache: flash + shockwave + rings(4) + particelle(35) + debris(12)
  // → 52 alloc/frame su fase esplosione, ora 5 Paint riutilizzati.
  static final Paint _explosionFlashPaint = Paint();
  static final Paint _explosionShockPaint = Paint()
    ..style = PaintingStyle.stroke;
  static final Paint _explosionRingPaint = Paint()
    ..style = PaintingStyle.stroke;
  // MaskFilter blur costante (radius=2) pre-cached → evita rebuild ogni frame.
  static final Paint _explosionParticlePaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
  static final Paint _explosionDebrisPaint = Paint()..strokeWidth = 1;

  // Logo line paint cache (2 linee decorative → 1 Paint; strokeWidth=1 costante)
  static final Paint _logoLinePaint = Paint()..strokeWidth = 1;

  // Iter 10 game-like upgrade: grid distortion + geom drops + HUD + kills.
  static final Paint _gridPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.7;
  static final Paint _gridGlowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  static final Paint _geomFillPaint = Paint();
  static final Paint _geomStrokePaint = Paint()..style = PaintingStyle.stroke;
  static final Paint _hudBgPaint = Paint();
  static final Paint _killExpPaint = Paint();
  static final Paint _killShockPaint = Paint()..style = PaintingStyle.stroke;
  static final Paint _floatyTrailPaint = Paint();
  static TextPainter? _cachedScorePainter;
  static int _cachedScoreValue = -1;
  static TextPainter? _cachedMultPainter;
  static int _cachedMultValue = -1;

  // Logo glow paint cache: MaskFilter blur(radius=40) cached all'init (nota
  // che `_drawLogo` disegna cerchio costante, blur costante → Paint totalmente
  // stabile, solo .color cambia con alpha).
  static final Paint _logoGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);

  // TextPainter cache — quantizza alpha (0..255) e scale (×100 int) così
  // micro-delta tra frame non forzano re-layout. Cache invalida solo quando
  // quantized values cambiano (≈32 distinti durante l'animazione).
  static TextPainter? _cachedTitlePainter;
  static int _cachedTitleAlphaQ = -1;
  static int _cachedTitleScaleQ = -1;
  static TextPainter? _cachedSubPainter;
  static int _cachedSubAlphaPulseQ = -1;
  static String? _cachedSubText;

  _SplashPainter({
    required this.chaseProgress,
    required this.bgPhase,
    required this.logoOpacity,
    required this.logoScale,
    required this.showExplosion,
    required this.explosionPhase,
    required this.tapToStartText,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Iter 13 (utente: "no griglia"): rimossa _drawGameGrid.
    _drawNebula(canvas, size);
    _drawScrollingBg(canvas, size);
    _drawStars(canvas, size);

    if (chaseProgress > 0.05 && chaseProgress < 1.0) {
      _drawSpeedLines(canvas, size);
    }

    // Iter 11 (utente: "no HUD, solo ship insegue mob"): rimossi
    // _drawFloatingGeoms, _drawSecondaryKills, _drawHUDOverlay.
    // Splash = pure chase simulation (ship + bullets + 1 weaver).
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
    // Nebulosa blu-viola in alto a sinistra
    final p1 = Offset(size.width * 0.2, size.height * 0.3);
    final pulse1 = 0.03 + math.sin(bgPhase * math.pi * 2) * 0.01;
    _nebulaPaint.shader = RadialGradient(
      colors: [
        Color.fromRGBO(30, 0, 100, pulse1),
        Colors.transparent,
      ],
    ).createShader(Rect.fromCircle(center: p1, radius: size.width * 0.5));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), _nebulaPaint);

    // Nebulosa cyan in basso a destra
    final p2 = Offset(size.width * 0.8, size.height * 0.7);
    final pulse2 = 0.02 + math.sin(bgPhase * math.pi * 2 + 2) * 0.01;
    _nebulaPaint.shader = RadialGradient(
      colors: [
        Color.fromRGBO(0, 50, 80, pulse2),
        Colors.transparent,
      ],
    ).createShader(Rect.fromCircle(center: p2, radius: size.width * 0.4));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), _nebulaPaint);

    _nebulaPaint.shader = null;
  }

  // === SFONDO SCORREVOLE veloce (strie da destra a sinistra) ===
  // 3x particelle, 2x velocità base, variate per parallasse
  void _drawScrollingBg(Canvas canvas, Size size) {
    if (chaseProgress < 0.03) return;
    final intensity = (chaseProgress * 2.0).clamp(0.0, 1.0);
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
      _scrollBgPaint.color = Color.fromRGBO(160, 210, 255, alpha);
      _scrollBgPaint.strokeWidth = strokeW;
      canvas.drawLine(Offset(x, y), Offset(x + baseLen, y), _scrollBgPaint);
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
      _scrollBgPaint.color = Color.fromRGBO(220, 240, 255, alpha);
      _scrollBgPaint.strokeWidth = 0.8;
      canvas.drawLine(Offset(x, y), Offset(x + baseLen, y), _scrollBgPaint);
    }
  }

  // === STELLE con parallax (3 layer di profondità) ===
  // 3x particelle, 2x velocità base, variate per parallasse
  void _drawStars(Canvas canvas, Size size) {
    final random = math.Random(42);

    // Layer lontano: 80 → 240, velocità base x2 con variazione individuale
    for (int i = 0; i < 240; i++) {
      final baseX = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final speedMul = 0.5 + random.nextDouble() * 1.5;
      final parallax = bgPhase * 40 * speedMul + (chaseProgress * 400 * speedMul);
      final x = (baseX - parallax) % size.width;
      final s = 0.3 + random.nextDouble() * 0.7;
      final twinkle = 0.2 + 0.5 * ((math.sin(bgPhase * math.pi * 2 * (0.5 + random.nextDouble()) + i) + 1) / 2);
      _starsPaint.color = Color.fromRGBO(180, 200, 255, twinkle * 0.4);
      canvas.drawCircle(Offset(x, y), s, _starsPaint);
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
      _starsPaint.color = Color.fromRGBO(200, 220, 255, twinkle * 0.6);
      canvas.drawCircle(Offset(x, y), s, _starsPaint);
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
      _starsPaint.color = Color.fromRGBO(220, 240, 255, twinkle * 0.7);
      canvas.drawCircle(Offset(x, y), s, _starsPaint);
    }
  }

  // === LINEE DI VELOCITÀ (effetto warp) ===
  void _drawSpeedLines(Canvas canvas, Size size) {
    final random = math.Random(77);
    final intensity = (chaseProgress * 2).clamp(0.0, 1.0);

    for (int i = 0; i < 15; i++) {
      final y = random.nextDouble() * size.height;
      final baseLen = 20 + random.nextDouble() * 40;
      final len = baseLen * intensity;
      final x = (random.nextDouble() * size.width * 1.5 - chaseProgress * size.width * 2) % (size.width + len);
      final alpha = 0.08 + random.nextDouble() * 0.07;
      _speedLinesPaint.color = Color.fromRGBO(100, 180, 255, alpha * intensity);
      canvas.drawLine(Offset(x, y), Offset(x + len, y), _speedLinesPaint);
    }
  }

  void _drawChaseScene(Canvas canvas, Size size) {
    final t = chaseProgress;
    final cy = size.height / 2;

    // === PERCORSO: weaver scappa con sinusoide AMPIA (utente iter 13:
    // "ampiezza maggiore, più alto/basso") + micro-jitter leggero per
    // sentirsi vivo. Niente più dodge 40Hz/70Hz aggressivo che creava
    // tremore (era jittery sia per il mob che per ship aim follow). ===
    // Iter 14 (utente: "2x speed, raggiunge margine destro"): factor
    // 0.75 → 1.20 → ship+drone vanno -0.15 fino a +1.05 width (oltre right).
    final droneX = size.width * (-0.15 + t * 1.20);
    // Sinusoide singola lenta: 1 onda completa nel chase, amp 0.32 size.h
    // → mob copre da alto a basso schermo. Jitter sottile aggiunge vita.
    final droneJitter = math.sin(t * math.pi * 8) * 6;
    final droneY = cy + math.sin(t * math.pi * 2) * size.height * 0.32 +
        droneJitter;

    // La navicella insegue con ritardo. Iter 12 (utente: "navicella si
    // muove strana"): smussato traiettoria ship → 1 oscillazione lenta
    // invece di 5+3 (era jittery). Wobble ridotto a 0.10 (era 0.13+0.05).
    const shipDelay = 0.1;
    final shipT = (t - shipDelay).clamp(0.0, 1.0);
    final shipX = size.width * (-0.15 + shipT * 1.20);
    final shipY = cy + math.sin(shipT * math.pi * 1.5) * size.height * 0.10;

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

    // === SCIA WEAVER (verde, matching ampia sinusoide nuova trajectory) ===
    for (int i = 1; i <= 12; i++) {
      final raw = t - i * 0.01;
      if (raw <= 0) break;
      final dt2 = raw.clamp(0.0, 1.0);
      final dtx = size.width * (-0.15 + dt2 * 1.20);
      final dJitterPast = math.sin(dt2 * math.pi * 8) * 6;
      final dty = cy +
          math.sin(dt2 * math.pi * 2) * size.height * 0.32 +
          dJitterPast;
      final a = (1 - i / 12.0) * 0.22;
      final s = (1 - i / 12.0) * 3.5;
      _droneTrailPaint.color = Color.fromRGBO(0, 255, 90, a);
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
      final stx = size.width * (-0.15 + st * 1.20);
      // Iter 12: trajectory smussata matching ship.
      final sty = cy + math.sin(st * math.pi * 1.5) * size.height * 0.10;
      final a = (1 - i / 18.0) * 0.4;
      final s = (1 - i / 18.0) * 3.5;
      _shipTrailGlowPaint.color =
          const Color(0xFF00FFFF).withValues(alpha: a * 0.4);
      canvas.drawCircle(Offset(stx, sty), s * 1.8, _shipTrailGlowPaint);
      _shipTrailCorePaint.color =
          const Color(0xFF00FFFF).withValues(alpha: a);
      canvas.drawCircle(Offset(stx, sty), s, _shipTrailCorePaint);
    }

    // === PROIETTILI in-game basic weapon: 3 RAFFICHE × 4 COPPIE.
    // Iter 11 (utente: "in fila come arma base + 2-3 raffiche, mob schiva").
    // Pattern in-game: ogni `_shoot()` spawna 1 coppia (2 bullet ±6px perp).
    // baseFireRate=8/s → fireInterval=0.125s tra coppie. In chase-units
    // (chase=3.5s): 0.125/3.5 ≈ 0.0357 per coppia. Burst = 4 coppie =
    // 0.143 chase-units (~0.5s). 3 burst start a t=0.10, 0.40, 0.70.
    // AIM SNAPSHOT al burst-start (NON per coppia) → tutte 4 coppie del
    // burst stessa direzione → "in fila" come gioco. Mob schiva grazie al
    // dodge che continua a muoverlo durante i 0.5s del burst. ===
    if (t > 0.1 && t < 0.99) {
      const burstStarts = [0.10, 0.40, 0.70];
      const pairsPerBurst = 4;
      const pairInterval = 0.0357; // 0.125s @ chase=3.5s = baseFireRate 8/s
      const bulletColor = Color(0xFFFFE500); // NeonColors.bulletYellow
      const pairOffset = 6.0;
      // Velocità bullet: matchata ad in-game (700 px/s). 1.4 width/s →
      // bullet attraversa schermo in ~0.7s = velocità realistica.
      final bulletSpeedWorldPerSec = size.width * 1.4;

      for (int b = 0; b < burstStarts.length; b++) {
        final burstStart = burstStarts[b];
        if (t <= burstStart) continue;

        // Aim SNAPSHOT al burst-start: tutte le coppie del burst usano la
        // stessa dir → bullet in fila parallela come basic weapon in-game.
        // Iter 13: traiettoria drone aggiornata (sin singola ampia + jitter).
        final dJitter = math.sin(burstStart * math.pi * 8) * 6;
        final toX = size.width * (-0.15 + burstStart * 1.20);
        final toY = cy +
            math.sin(burstStart * math.pi * 2) * size.height * 0.32 +
            dJitter;
        final burstShipT = (burstStart - shipDelay).clamp(0.0, 1.0);
        final burstShipX = size.width * (-0.15 + burstShipT * 1.20);
        final burstShipY = cy +
            math.sin(burstShipT * math.pi * 1.5) * size.height * 0.10;
        final aimDx = toX - burstShipX;
        final aimDy = toY - burstShipY;
        final aimLen = math.sqrt(aimDx * aimDx + aimDy * aimDy);
        if (aimLen < 0.1) continue;
        final dirX = aimDx / aimLen;
        final dirY = aimDy / aimLen;
        final perpX = -dirY;
        final perpY = dirX;
        // Iter 14 (utente: "bullets dal centro non punta"): noseOffset
        // bumped 16.8 → 24 → bullet emerge OLTRE tip nave (era esattamente
        // sul tip → sembrava centro). Tip nave a -14*s=-18.9 local.
        const noseOffset = 24.0;
        // Iter 12 (utente: "bullets non in fila"): tutte le coppie del burst
        // emergono dalla STESSA ship pos (snapshot al burst-start) → bullet
        // perfettamente in fila lungo aimDir, distanziati solo da
        // velocità × pairInterval → linea retta come basic weapon in-game.
        final shipCenterX = burstShipX;
        final shipCenterY = burstShipY;

        // Itera coppie del burst.
        for (int p = 0; p < pairsPerBurst; p++) {
          final fireTime = burstStart + p * pairInterval;
          if (t <= fireTime) continue;
          final dtSinceFire = t - fireTime;

          // Distanza percorsa dal bullet: velocity costante × dt.
          final travel = bulletSpeedWorldPerSec * dtSinceFire;

        // Disegna COPPIA di bullet paralleli (±perp offset come basic weapon)
        for (int side = -1; side <= 1; side += 2) {
          final offsetX = perpX * pairOffset * side;
          final offsetY = perpY * pairOffset * side;
          final fromX = shipCenterX + dirX * noseOffset + offsetX;
          final fromY = shipCenterY + dirY * noseOffset + offsetY;
          final bx = fromX + dirX * travel;
          final by = fromY + dirY * travel;

          // Culling: bullet fuori schermo (+margine) → skip render
          const margin = 60.0;
          if (bx < -margin ||
              bx > size.width + margin ||
              by < -margin ||
              by > size.height + margin) {
            continue;
          }

          // Trail (cerchietti dietro al bullet lungo -aimDir)
          for (int ti = 1; ti <= 5; ti++) {
            final tAlpha = (1 - ti / 5) * 0.35;
            _bulletTrailPaint.color =
                bulletColor.withValues(alpha: tAlpha);
            canvas.drawCircle(
              Offset(bx - dirX * ti * 4, by - dirY * ti * 4),
              1.6 * (1 - ti / 5.5),
              _bulletTrailPaint,
            );
          }

          // Glow + corpo + core del bullet
          _bulletGlowPaint.color = bulletColor.withValues(alpha: 0.4);
          canvas.drawCircle(Offset(bx, by), 5, _bulletGlowPaint);
          _bulletBodyPaint.color = bulletColor;
          canvas.drawCircle(Offset(bx, by), 3.2, _bulletBodyPaint);
          _bulletCorePaint.color =
              const Color(0xFFFFFFFF).withValues(alpha: 0.85);
          canvas.drawCircle(Offset(bx, by), 1.3, _bulletCorePaint);

          // Muzzle flash al nose durante primi 0.05 chase-time del bullet
          if (dtSinceFire < 0.05) {
            final flashAlpha = (1 - dtSinceFire / 0.05) * 0.7;
            _muzzleGlowPaint.color =
                bulletColor.withValues(alpha: flashAlpha * 0.5);
            canvas.drawCircle(Offset(fromX, fromY), 8, _muzzleGlowPaint);
            _muzzleCorePaint.color =
                const Color(0xFFFFFFFF).withValues(alpha: flashAlpha);
            canvas.drawCircle(Offset(fromX, fromY), 4, _muzzleCorePaint);
          }
        } // for side
        } // for p (pair within burst)
      } // for b (burst)
    } // if (t > 0.1)

    // === WEAVER: schiva TUTTI i proiettili, non viene mai colpito.
    // Nessun fumo/damage — il mob sopravvive per tutto lo splash. ===
    _drawDrone(canvas, droneX, droneY, t, false);

    // === NAVICELLA (in-game graphics, ruota verso il drone) ===
    _drawShip(canvas, shipX, shipY, shipT, aimAngle);
  }

  /// Weaver verde (stile `WeaverEnemy` in gioco): rombo ALLUNGATO vertical
  /// con bordo neon, flusso energetico interno, nodi sulle 4 punte.
  /// Orientato orizzontale (punta verso sx = direzione di fuga).
  void _drawDrone(Canvas canvas, double x, double y, double t, bool damaged) {
    // Scala: `w=6, h=12` come WeaverEnemy in gioco × fattore per splash.
    const w = 8.5; // lato corto (perpendicolare alla fuga)
    const h = 17.0; // lato lungo (direzione di fuga)
    canvas.save();
    canvas.translate(x, y);
    // Weaver in fuga: orientato verso SX (−X in world) — rotazione π/2
    // per allungarlo orizzontale.
    canvas.rotate(math.pi / 2);

    final bodyColor = damaged
        ? const Color(0xFFFF6633) // arancio danno
        : const Color(0xFF00FF44); // verde neon (NeonColors.green)

    // ─── GLOW ESTERNO (rombo più grande, no blur) ───
    final glowPath = Path()
      ..moveTo(0, -h * 1.25)
      ..lineTo(w * 1.25, 0)
      ..lineTo(0, h * 1.25)
      ..lineTo(-w * 1.25, 0)
      ..close();
    _droneGlowPaint.color = bodyColor.withValues(alpha: 0.28);
    canvas.drawPath(glowPath, _droneGlowPaint);

    // ─── CORPO: rombo allungato (stile weaver) ───
    final bodyPath = Path()
      ..moveTo(0, -h)
      ..lineTo(w, 0)
      ..lineTo(0, h)
      ..lineTo(-w, 0)
      ..close();
    // Fill interno verde trasparente
    _droneFillPaint.color = bodyColor.withValues(alpha: 0.28);
    canvas.drawPath(bodyPath, _droneFillPaint);
    // Bordo neon brillante
    _droneStrokePaint.color = bodyColor;
    canvas.drawPath(bodyPath, _droneStrokePaint);

    // ─── ROMBO INTERNO (scafo) ───
    final innerPath = Path()
      ..moveTo(0, -h * 0.55)
      ..lineTo(w * 0.55, 0)
      ..lineTo(0, h * 0.55)
      ..lineTo(-w * 0.55, 0)
      ..close();
    _droneInnerPaint.color = bodyColor.withValues(alpha: 0.55);
    canvas.drawPath(innerPath, _droneInnerPaint);

    // ─── FLUSSO ENERGETICO: puntino luminoso che scorre lungo l'asse ───
    final flowProgress = (t * 2) % 1.0;
    final flowY = -h * 0.8 + flowProgress * h * 1.6;
    final flowAlpha = 0.5 * (1 - (flowProgress - 0.5).abs() * 2);
    if (flowAlpha > 0) {
      _droneCorePaint.color =
          const Color(0xFFFFFFFF).withValues(alpha: flowAlpha);
      canvas.drawCircle(Offset(0, flowY), 1.3, _droneCorePaint);
    }

    // ─── 4 NODI SUI VERTICI (pulsanti, stile weaver in gioco) ───
    final vertexPulse = 0.4 + math.sin(t * 20) * 0.4;
    _droneVertexPaint.color = bodyColor.withValues(alpha: vertexPulse);
    final vertices = [
      const Offset(0, -h * 0.9),
      const Offset(w * 0.9, 0),
      const Offset(0, h * 0.9),
      const Offset(-w * 0.9, 0),
    ];
    for (final v in vertices) {
      canvas.drawCircle(v, 1.6, _droneVertexPaint);
    }

    // ─── NUCLEO pulsante centrale ───
    final corePulse = 0.5 + math.sin(t * 15) * 0.4;
    _droneCoreHaloPaint.color =
        const Color(0xFFFFFFFF).withValues(alpha: corePulse * 0.35);
    canvas.drawCircle(Offset.zero, w * 0.45, _droneCoreHaloPaint);
    _droneCorePaint.color =
        const Color(0xFFFFFFFF).withValues(alpha: corePulse);
    canvas.drawCircle(Offset.zero, w * 0.22, _droneCorePaint);

    canvas.restore();
  }

  /// Disegna la navicella con la SAME grafica di gioco (`Player._drawShipBody`
  /// standard + thrusters + cockpit + wing-tip lights), ruotata verso il
  /// bersaglio — stesso meccanismo del `_rotation` in `Player.update`.
  void _drawShip(Canvas canvas, double x, double y, double t, double aimAngle) {
    canvas.save();
    canvas.translate(x, y);
    // Rotazione verso il bersaglio. Iter 13 (utente: "ship trema"):
    // micro-wobble ridotto da sin(π*5)*0.08 → sin(π*1.5)*0.025 →
    // movimento elegante senza tremore visibile.
    final wobble = math.sin(t * math.pi * 1.5) * 0.025;
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
    canvas.drawCircle(const Offset(0, -4 * s), 5, _cockpitHaloPaint);
    _cockpitWhitePaint.color =
        const Color(0xFFFFFFFF).withValues(alpha: cockpitGlow);
    canvas.drawCircle(const Offset(0, -4 * s), 3, _cockpitWhitePaint);
    _cockpitCyanPaint.color =
        const Color(0xFF00FFFF).withValues(alpha: 0.9);
    canvas.drawCircle(const Offset(0, -4 * s), 2, _cockpitCyanPaint);

    // Linee strutturali (stesse di `Player._renderShipDetails`)
    canvas.drawLine(
        const Offset(-2 * s, 0), const Offset(-10 * s, 10 * s), _shipLinePaint);
    canvas.drawLine(
        const Offset(2 * s, 0), const Offset(10 * s, 10 * s), _shipLinePaint);
    canvas.drawLine(
        const Offset(0, -8 * s), const Offset(0, 8 * s), _shipLinePaint);

    // ─── WING-TIP LIGHTS (rossa a sx, verde a dx — come in gioco) ───
    final wingPulse = 0.5 + math.sin(t * 15) * 0.5;
    _wingRedGlowPaint.color =
        Color.fromRGBO(255, 50, 50, wingPulse * 0.3);
    canvas.drawCircle(const Offset(-12 * s, 10 * s), 4, _wingRedGlowPaint);
    _wingRedCorePaint.color =
        Color.fromRGBO(255, 50, 50, wingPulse * 0.9);
    canvas.drawCircle(const Offset(-12 * s, 10 * s), 2, _wingRedCorePaint);
    _wingGreenGlowPaint.color =
        Color.fromRGBO(50, 255, 100, wingPulse * 0.3);
    canvas.drawCircle(const Offset(12 * s, 10 * s), 4, _wingGreenGlowPaint);
    _wingGreenCorePaint.color =
        Color.fromRGBO(50, 255, 100, wingPulse * 0.9);
    canvas.drawCircle(const Offset(12 * s, 10 * s), 2, _wingGreenCorePaint);

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
      _explosionFlashPaint.color = Color.fromRGBO(255, 255, 255, alpha);
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        _explosionFlashPaint,
      );
    }

    // Shockwave ring (anello che si espande)
    if (p < 0.8) {
      final ringR = p * size.width * 0.4;
      final ringAlpha = (1 - p / 0.8) * 0.5;
      _explosionShockPaint.color = Color.fromRGBO(0, 255, 255, ringAlpha);
      _explosionShockPaint.strokeWidth = 3 * (1 - p / 0.8);
      canvas.drawCircle(Offset(cx, cy), ringR, _explosionShockPaint);
    }

    // Cerchi concentrici multipli
    for (int i = 0; i < 4; i++) {
      final delay = i * 0.06;
      final rp = (p - delay).clamp(0.0, 1.5);
      if (rp <= 0) continue;
      final r = rp * 120 + i * 20;
      final alpha = (1 - rp / 1.5).clamp(0, 1) * 0.35;
      _explosionRingPaint.color =
          Color.fromRGBO(0, 255, 255, alpha.toDouble());
      _explosionRingPaint.strokeWidth = (3 - i * 0.5).clamp(0.5, 3);
      canvas.drawCircle(Offset(cx, cy), r.toDouble(), _explosionRingPaint);
    }

    // Particelle esplosione (più numerose e colorate) — MaskFilter blur(2)
    // è pre-cached sul Paint statico (const).
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
      _explosionParticlePaint.color = color;
      canvas.drawCircle(
        Offset(cx + math.cos(angle) * dist, cy + math.sin(angle) * dist),
        pSize * (1 - p * 0.5).clamp(0.3, 1),
        _explosionParticlePaint,
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
      _explosionDebrisPaint.color =
          Color.fromRGBO(0, 255, 255, alpha.toDouble());
      canvas.drawLine(
        Offset(sx, sy),
        Offset(sx + dx * 6, sy + dy * 6),
        _explosionDebrisPaint,
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
      _logoLinePaint.color = Color.fromRGBO(0, 255, 255, lineAlpha * 0.3);
      canvas.drawLine(
        Offset(cx - lineW, lineY),
        Offset(cx + lineW, lineY),
        _logoLinePaint,
      );
    }

    // Glow dietro il testo (MaskFilter blur(40) è pre-cached sul Paint)
    if (alpha > 0.2) {
      _logoGlowPaint.color = Color.fromRGBO(0, 255, 255, alpha * 0.05);
      canvas.drawCircle(Offset(cx, cy), 80 * scale, _logoGlowPaint);
    }

    // Titolo "GEOMETRY FIGHT" — TextPainter riusato se alpha/scale quantizzati
    // invariati rispetto al frame precedente. Quantizzazione a 256 step alpha
    // × 100 step scale ≈ invisibile all'occhio ma taglia ~60 alloc TextPainter
    // durante fade-in (1.8s × 60fps = 108 frame).
    final titleAlphaQ = (alpha * 255).round();
    final titleScaleQ = (scale * 100).round();
    if (_cachedTitlePainter == null ||
        _cachedTitleAlphaQ != titleAlphaQ ||
        _cachedTitleScaleQ != titleScaleQ) {
      _cachedTitlePainter = TextPainter(
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
      _cachedTitleAlphaQ = titleAlphaQ;
      _cachedTitleScaleQ = titleScaleQ;
    }
    final textPainter = _cachedTitlePainter!;

    final textX = cx - textPainter.width / 2;
    final textY = cy - textPainter.height / 2;
    textPainter.paint(canvas, Offset(textX, textY));

    // Linea decorativa sotto
    if (alpha > 0.3) {
      final lineAlpha = ((alpha - 0.3) / 0.7).clamp(0.0, 1.0);
      final lineW = 100 * scale * lineAlpha;
      final lineY2 = cy + 30 * scale;
      _logoLinePaint.color = Color.fromRGBO(0, 255, 255, lineAlpha * 0.3);
      canvas.drawLine(
        Offset(cx - lineW, lineY2),
        Offset(cx + lineW, lineY2),
        _logoLinePaint,
      );
    }

    // Sottotitolo
    if (alpha > 0.5) {
      final subAlpha = ((alpha - 0.5) * 2).clamp(0, 1).toDouble();
      // Pulsazione del sottotitolo
      final pulse = 0.3 + math.sin(bgPhase * math.pi * 4) * 0.15;
      // Cache sub-painter per alpha*pulse quantizzato (stesso approccio).
      // Cache invalidata anche se il testo localizzato cambia (es. cambio lingua).
      final subAlphaPulseQ = (subAlpha * pulse * 255).round();
      if (_cachedSubPainter == null ||
          _cachedSubAlphaPulseQ != subAlphaPulseQ ||
          _cachedSubText != tapToStartText) {
        _cachedSubPainter = TextPainter(
          text: TextSpan(
            text: tapToStartText,
            style: TextStyle(
              color: Color.fromRGBO(255, 255, 255, subAlpha * pulse),
              fontSize: 12,
              fontFamily: 'monospace',
              letterSpacing: 5,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        _cachedSubAlphaPulseQ = subAlphaPulseQ;
        _cachedSubText = tapToStartText;
      }
      final subPainter = _cachedSubPainter!;
      subPainter.paint(
        canvas,
        Offset(cx - subPainter.width / 2, textY + textPainter.height + 30),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // ITER 10 game-like helpers: grid distortion bg + geom drops + HUD +
  // secondary kills chain. Trasforma splash in vera simulazione di gioco.
  // ═══════════════════════════════════════════════════════════════════

  /// Geometry Wars style grid: linee blu/ciano distorte da sin waves.
  /// Iter 13: dead code (utente: "no griglia"). Tenuto per ref.
  // ignore: unused_element
  void _drawGameGrid(Canvas canvas, Size size) {
    const cellSize = 70.0;
    final scrollX = (bgPhase * 80) % cellSize;
    final scrollY = (bgPhase * 30) % cellSize;
    final intensity = (0.5 + chaseProgress * 0.5).clamp(0.5, 1.0);
    final baseAlpha = 0.18 * intensity;
    final glowAlpha = 0.28 * intensity;

    // Glow layer (più spesso + blur, pulsing).
    final pulse = 0.7 + math.sin(bgPhase * math.pi * 4) * 0.3;
    _gridGlowPaint.color = const Color(0xFF0066FF).withValues(alpha: glowAlpha * pulse * 0.4);

    // Linee orizzontali distorte da sin verticale.
    for (double y = -scrollY; y < size.height + cellSize; y += cellSize) {
      final path = Path();
      bool started = false;
      for (double x = 0; x <= size.width; x += 12) {
        final dy = math.sin(x * 0.011 + bgPhase * math.pi * 2 + y * 0.004) * 6 +
            math.cos(x * 0.005 + bgPhase * math.pi) * 3;
        if (!started) {
          path.moveTo(x, y + dy);
          started = true;
        } else {
          path.lineTo(x, y + dy);
        }
      }
      _gridPaint.color = const Color(0xFF44CCFF).withValues(alpha: baseAlpha);
      canvas.drawPath(path, _gridPaint);
    }

    // Linee verticali distorte da cos orizzontale.
    for (double x = -scrollX; x < size.width + cellSize; x += cellSize) {
      final path = Path();
      bool started = false;
      for (double y = 0; y <= size.height; y += 12) {
        final dx = math.cos(y * 0.011 + bgPhase * math.pi * 2 + x * 0.004) * 6 +
            math.sin(y * 0.005 + bgPhase * math.pi) * 3;
        if (!started) {
          path.moveTo(x + dx, y);
          started = true;
        } else {
          path.lineTo(x + dx, y);
        }
      }
      _gridPaint.color = const Color(0xFF44CCFF).withValues(alpha: baseAlpha);
      canvas.drawPath(path, _gridPaint);
    }

    // Highlight ondulato — onda di "energia" che attraversa il grid.
    final waveX = (chaseProgress * size.width * 1.5) - size.width * 0.3;
    for (double y = 0; y <= size.height; y += cellSize / 2) {
      final dy = math.sin(waveX * 0.01 + y * 0.01 + bgPhase * math.pi * 4) * 12;
      final dist = (waveX - size.width * 0.5).abs();
      final waveAlpha = (1.0 - (dist / (size.width * 0.5)).clamp(0.0, 1.0)) * 0.35 * intensity;
      if (waveAlpha > 0.05) {
        _gridGlowPaint.color =
            const Color(0xFF00CCFF).withValues(alpha: waveAlpha);
        canvas.drawLine(
          Offset(waveX - 50, y + dy),
          Offset(waveX + 50, y + dy),
          _gridGlowPaint,
        );
      }
    }
  }

  /// Geom drops drifting in arena (cyan/pink/yellow shards, simula loot).
  /// Iter 11: dead code (utente: solo chase, no extra). Tenuto per ref.
  // ignore: unused_element
  void _drawFloatingGeoms(Canvas canvas, Size size) {
    if (chaseProgress < 0.08) return;
    final intensity = ((chaseProgress - 0.08) * 3).clamp(0.0, 1.0);
    final rng = math.Random(2024);
    const geomCount = 14;
    for (int i = 0; i < geomCount; i++) {
      final baseX = rng.nextDouble() * size.width;
      final baseY = rng.nextDouble() * size.height;
      // Drift orbitale lento.
      final angle = bgPhase * math.pi * 2 + i * 0.7;
      final wobble = 18.0 + rng.nextDouble() * 12.0;
      final x = baseX + math.cos(angle) * wobble;
      final y = baseY + math.sin(angle * 1.3) * wobble;
      // Color cycling tra 3 shade GW.
      final colorChoice = i % 3;
      final color = colorChoice == 0
          ? const Color(0xFF00FFFF)  // ciano
          : colorChoice == 1
              ? const Color(0xFFFF00AA)  // pink
              : const Color(0xFFFFE500); // yellow
      final pulse = 0.55 + math.sin(bgPhase * math.pi * 4 + i * 1.3) * 0.45;
      final r = (3.5 + rng.nextDouble() * 2.5) * intensity;
      // Diamond shape rotato da bgPhase.
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(bgPhase * math.pi * 2 + i);
      final p = Path()
        ..moveTo(0, -r)
        ..lineTo(r * 0.65, 0)
        ..lineTo(0, r)
        ..lineTo(-r * 0.65, 0)
        ..close();
      _geomFillPaint.color = color.withValues(alpha: 0.45 * pulse * intensity);
      canvas.drawPath(p, _geomFillPaint);
      _geomStrokePaint
        ..color = color.withValues(alpha: 0.85 * pulse * intensity)
        ..strokeWidth = 1.2;
      canvas.drawPath(p, _geomStrokePaint);
      // Core bianco
      _geomFillPaint.color =
          const Color(0xFFFFFFFF).withValues(alpha: pulse * 0.6 * intensity);
      canvas.drawCircle(Offset.zero, r * 0.35, _geomFillPaint);
      canvas.restore();
    }
  }

  /// Secondary kills chain: 3 mini esplosioni distribuiti nel tempo a
  /// posizioni casuali → simula multi-kill mentre il player insegue weaver.
  /// Iter 11: dead code (utente: solo chase, no extra). Tenuto per ref.
  // ignore: unused_element
  void _drawSecondaryKills(Canvas canvas, Size size) {
    final rng = math.Random(7);
    // 3 kill events con tempi crescenti.
    const killTimes = [0.18, 0.42, 0.68];
    const killColors = [
      Color(0xFF00FFFF),
      Color(0xFFFF00AA),
      Color(0xFFFFAA00),
    ];
    for (int i = 0; i < 3; i++) {
      final ft = killTimes[i];
      if (chaseProgress <= ft) continue;
      final dt = chaseProgress - ft;
      if (dt > 0.20) continue;  // explosion lifetime ~0.2 chase units
      final t = dt / 0.20;  // 0..1
      // Posizione kill: random per i, but stable.
      final kx = size.width * (0.25 + rng.nextDouble() * 0.55);
      final ky = size.height * (0.25 + rng.nextDouble() * 0.5);
      final color = killColors[i];
      // Shockwave ring.
      final ringR = 8 + t * 50;
      final ringAlpha = (1 - t) * 0.7;
      _killShockPaint
        ..color = color.withValues(alpha: ringAlpha)
        ..strokeWidth = 2.5 * (1 - t);
      canvas.drawCircle(Offset(kx, ky), ringR, _killShockPaint);
      // Inner flash.
      final flashAlpha = (1 - t * 2).clamp(0.0, 1.0) * 0.85;
      _killExpPaint.color =
          const Color(0xFFFFFFFF).withValues(alpha: flashAlpha);
      canvas.drawCircle(Offset(kx, ky), 8 + t * 20, _killExpPaint);
      // Particelle radiali.
      for (int j = 0; j < 8; j++) {
        final ang = j * math.pi / 4 + i;
        final dist = t * 40 + 10;
        final pAlpha = (1 - t).clamp(0.0, 1.0) * 0.7;
        _killExpPaint.color = color.withValues(alpha: pAlpha);
        canvas.drawCircle(
          Offset(kx + math.cos(ang) * dist, ky + math.sin(ang) * dist),
          1.6 + (1 - t) * 1.4,
          _killExpPaint,
        );
      }
      // Geom drop volante che fluisce verso ship — disegnato come scia.
      if (t < 0.85) {
        final shipT = (chaseProgress - 0.1).clamp(0.0, 1.0);
        final cy = size.height / 2;
        final shipX = size.width * (-0.15 + shipT * 1.20);
        final shipY = cy + math.sin(shipT * math.pi * 5) * size.height * 0.13
            + math.cos(shipT * math.pi * 3) * size.height * 0.05;
        // Posizione lerp dal kill verso ship con curva
        final lerpT = (t / 0.85).clamp(0.0, 1.0);
        final gx = kx + (shipX - kx) * lerpT;
        final gy = ky + (shipY - ky) * lerpT;
        _floatyTrailPaint.color = color.withValues(alpha: 0.7 * (1 - lerpT * 0.5));
        canvas.drawCircle(Offset(gx, gy), 3.0, _floatyTrailPaint);
        // Trail
        for (int k = 1; k <= 4; k++) {
          final tk = (lerpT - k * 0.05).clamp(0.0, 1.0);
          if (tk <= 0) break;
          final tx = kx + (shipX - kx) * tk;
          final ty = ky + (shipY - ky) * tk;
          _floatyTrailPaint.color = color.withValues(alpha: 0.4 * (1 - k / 4));
          canvas.drawCircle(Offset(tx, ty), 1.8, _floatyTrailPaint);
        }
      }
    }
  }

  /// HUD overlay: score counter top-left + multiplier badge top-right.
  /// Iter 11: dead code (utente: "no HUD nel video iniziale"). Tenuto.
  // ignore: unused_element
  void _drawHUDOverlay(Canvas canvas, Size size) {
    final intensity = ((chaseProgress - 0.05) * 5).clamp(0.0, 1.0);
    if (intensity < 0.05) return;

    // Score salendo: ramping basato su chaseProgress + secondary kills.
    final baseScore = (chaseProgress * 32500).round();
    final killBonus = chaseProgress > 0.18 ? 1500 : 0;
    final killBonus2 = chaseProgress > 0.42 ? 3000 : 0;
    final killBonus3 = chaseProgress > 0.68 ? 5500 : 0;
    final score = baseScore + killBonus + killBonus2 + killBonus3;

    // Multiplier ramping: x1 → x9 con kills.
    final mult = chaseProgress < 0.18
        ? 1
        : chaseProgress < 0.42
            ? 3
            : chaseProgress < 0.68
                ? 5
                : 9;

    // === SCORE top-left ===
    if (_cachedScorePainter == null || _cachedScoreValue != score) {
      _cachedScorePainter = TextPainter(
        text: TextSpan(
          text: _formatScore(score),
          style: TextStyle(
            color: const Color(0xFFFFFFFF).withValues(alpha: intensity),
            fontSize: 24,
            fontWeight: FontWeight.w900,
            fontFamily: 'monospace',
            letterSpacing: 2,
            shadows: [
              Shadow(
                  color:
                      const Color(0xFF00FFFF).withValues(alpha: intensity * 0.7),
                  blurRadius: 10),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      _cachedScoreValue = score;
    }
    final sp = _cachedScorePainter!;
    sp.paint(canvas, const Offset(20, 24));

    // === MULTIPLIER top-right (badge cyan glow) ===
    if (_cachedMultPainter == null || _cachedMultValue != mult) {
      _cachedMultPainter = TextPainter(
        text: TextSpan(
          text: 'x$mult',
          style: TextStyle(
            color: mult >= 5
                ? const Color(0xFFFFE500).withValues(alpha: intensity)
                : const Color(0xFF00FFFF).withValues(alpha: intensity),
            fontSize: 28,
            fontWeight: FontWeight.w900,
            fontFamily: 'monospace',
            letterSpacing: 3,
            shadows: [
              Shadow(
                  color: (mult >= 5
                          ? const Color(0xFFFFE500)
                          : const Color(0xFF00FFFF))
                      .withValues(alpha: intensity * 0.8),
                  blurRadius: 12),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      _cachedMultValue = mult;
    }
    final mp = _cachedMultPainter!;
    final mx = size.width - mp.width - 20;
    final my = 24.0;
    // Badge bg
    _hudBgPaint.color = Colors.black.withValues(alpha: 0.35 * intensity);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(mx - 10, my - 4, mp.width + 20, mp.height + 8),
        const Radius.circular(8),
      ),
      _hudBgPaint,
    );
    mp.paint(canvas, Offset(mx, my));
  }

  String _formatScore(int s) {
    final str = s.toString();
    final buf = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buf.write(',');
      buf.write(str[i]);
    }
    return buf.toString();
  }

  @override
  bool shouldRepaint(covariant _SplashPainter oldDelegate) => true;
}

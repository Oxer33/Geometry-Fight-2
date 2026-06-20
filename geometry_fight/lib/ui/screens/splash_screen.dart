import 'dart:math' as math;
import 'package:flutter/foundation.dart' show listEquals;
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

  // === Iter 15: steering-based ship motion ===
  // Stato mutabile per integrazione frame-by-frame (al posto della formula
  // pre-computed). Il chaseController tick driva l'update.
  static const double _chaseDurationSec = 3.5;
  // Posizione/velocità ship in world-space (px). Inizializzati al primo
  // frame quando conosciamo size.
  double _shipX = 0;
  double _shipY = 0;
  double _shipVx = 0;
  double _shipVy = 0;
  double _shipAim = math.pi / 2; // default: muso a destra
  bool _shipInit = false;
  double _prevChaseT = 0.0;
  Size? _lastSize;
  // Snapshot ship pos/vel/aim quando ogni burst-start viene attraversato
  // (per bullet origins). 3 burst → fino a 3 snapshot. captured=false
  // finché il burst non è iniziato.
  // Iter 17 (utente: "bullets sembrano partire da dietro la navicella"):
  // salviamo anche velocity vector al snapshot (`_burstSnapVx/Vy` in px/s)
  // per ricalcolare la pos della nave a `fireTime` di ogni pair (la nave
  // si muove durante il burst di 0.5s, quindi pos fissa snapshot faceva
  // sì che le pair successive parteggiavano da pos vecchia → bullets
  // visivamente "dietro" la nave corrente).
  final List<bool> _burstCaptured = [false, false, false];
  final List<double> _burstSnapX = [0, 0, 0];
  final List<double> _burstSnapY = [0, 0, 0];
  final List<double> _burstSnapDx = [1, 0, 0]; // dir aim al snapshot
  final List<double> _burstSnapDy = [0, 0, 0];
  final List<double> _burstSnapVx = [0, 0, 0]; // velocity vector px/s
  final List<double> _burstSnapVy = [0, 0, 0];
  // Trail ring buffer: 18 past positions per la scia cyan (mantiene il
  // look del trail in-game `Player._renderTrail`). Push ad ogni frame.
  static const int _trailLen = 18;
  final List<double> _trailX = List.filled(_trailLen, 0);
  final List<double> _trailY = List.filled(_trailLen, 0);
  int _trailHead = 0; // index del sample più recente
  int _trailFilled = 0; // numero di sample validi (0..18)

  @override
  void initState() {
    super.initState();

    // Fase 1: Inseguimento (3.5 secondi — più lungo e cinematografico)
    _chaseController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (_chaseDurationSec * 1000).round()),
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
    _chaseController.addListener(_updateShipSteering);
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
        setState(() {
          _explosionPhase += 0.018;
          if (_explosionPhase > 1.5) _showExplosion = false;
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Memorizza size per `_updateShipSteering` (chiamato dal listener del
    // chaseController, che non ha accesso al context). Aggiornato qui invece
    // che nel builder per evitare un side-effect di stato durante il build;
    // `MediaQuery.sizeOf` ri-triggera questo callback a ogni cambio di size.
    _lastSize = MediaQuery.sizeOf(context);
  }

  /// Iter 15: integrazione steering frame-by-frame della nave.
  /// - seek mob (lerp velocity verso desiredVel)
  /// - strafe perpendicolare entro 200px (orbita invece di "baciare" il mob)
  /// - boundary keepaway entro 60px dal bordo canvas
  /// - subtle bob perpendicolare (8px amp, 0.6Hz)
  /// - speed clamp 300-400 px/s
  /// - aim segue velocity vector (non target)
  void _updateShipSteering() {
    if (!mounted) return;
    final size = _lastSize;
    if (size == null || size.width <= 0 || size.height <= 0) return;

    final t = _chaseController.value;
    // dt in secondi reali. Il chase è 3.5s di durata controller.
    var dtT = t - _prevChaseT;
    _prevChaseT = t;
    if (dtT < 0) dtT = 0; // restart o reverse: skip frame
    // Cap dt per evitare scatti su frame drop pesanti.
    if (dtT > 0.05) dtT = 0.05;
    final dt = dtT * _chaseDurationSec; // chase-units → secondi

    // Mob (weaver) target: stessa traiettoria del painter, calcolata qui
    // così steering e render condividono la verità geometrica.
    final cy = size.height / 2;
    final droneX = size.width * (-0.15 + t * 1.20);
    final droneJitter = math.sin(t * math.pi * 8) * 6;
    final droneY =
        cy + math.sin(t * math.pi * 2) * size.height * 0.32 + droneJitter;

    // Init lazy: prima frame con size valido → ship parte un po' a sx del
    // mob, allineata verticalmente. Velocity iniziale verso il mob.
    if (!_shipInit) {
      _shipX = -size.width * 0.10;
      _shipY = cy;
      final dx0 = droneX - _shipX;
      final dy0 = droneY - _shipY;
      final len0 = math.sqrt(dx0 * dx0 + dy0 * dy0);
      // Iter 17: velocità iniziale 350 → 250 (coerente con nuovo
      // maxSpeed=280, minSpeed=220 — la nave parte già nel range stabile).
      if (len0 > 0.01) {
        _shipVx = (dx0 / len0) * 250;
        _shipVy = (dy0 / len0) * 250;
      } else {
        _shipVx = 250;
        _shipVy = 0;
      }
      _shipInit = true;
    }

    // === SEEK: desiredVel verso il mob a maxSpeed. ===
    // Iter 17 (utente: "nave un pò più lenta"): rallentata del ~30%
    // (400→280, 300→220) → bullet a 2000 px/s la supera molto di più
    // visivamente, no più sensazione di "bullets dietro alla nave".
    const maxSpeed = 280.0;
    const minSpeed = 220.0;
    final dxM = droneX - _shipX;
    final dyM = droneY - _shipY;
    final distM = math.sqrt(dxM * dxM + dyM * dyM);
    double desiredVx;
    double desiredVy;
    if (distM > 0.01) {
      desiredVx = (dxM / distM) * maxSpeed;
      desiredVy = (dyM / distM) * maxSpeed;
    } else {
      desiredVx = _shipVx;
      desiredVy = _shipVy;
    }

    // Blend ratio: 0.04 per chase-unit (3.5s) → ~0.0114/s. Per stabilità
    // numerica usiamo `1 - exp(-rate * dt)` invece di blending lineare.
    // Con rate scelto in modo che blendT ≈ 0.04 quando dt = 1 chase-unit.
    // rate = -ln(1 - 0.04) ≈ 0.0408 per chase-unit → /3.5 per sec.
    const seekRatePerChaseUnit = 0.0408;
    final seekBlend = 1 - math.exp(-seekRatePerChaseUnit * dtT);
    _shipVx += (desiredVx - _shipVx) * seekBlend;
    _shipVy += (desiredVy - _shipVy) * seekBlend;

    // === STRAFE: entro 200px aggiungi componente perpendicolare. ===
    // Sceglie il lato perpendicolare consistente in base al cross product
    // tra velocità attuale e direzione-al-mob → no flip-flop di lato.
    if (distM < 200 && distM > 0.01) {
      // Quanto più vicino, tanto più strafe. strafe peak a distM≈40.
      final strafeIntensity = ((200 - distM) / 200).clamp(0.0, 1.0);
      final dirX = dxM / distM;
      final dirY = dyM / distM;
      // Perpendicolare (rotazione +90°): (-dy, dx).
      var perpX = -dirY;
      var perpY = dirX;
      // Allinea il segno della perpendicolare con la velocità corrente
      // così la ship "continua a girare nella stessa direzione".
      final dot = perpX * _shipVx + perpY * _shipVy;
      if (dot < 0) {
        perpX = -perpX;
        perpY = -perpY;
      }
      // Force perpendicolare in unità px/s² · dt → contributo px/s.
      const strafeAccel = 900.0;
      _shipVx += perpX * strafeAccel * strafeIntensity * dt;
      _shipVy += perpY * strafeAccel * strafeIntensity * dt;
    }

    // === BOUNDARY KEEPAWAY: entro 60px dal bordo, push verso il centro. ===
    const edgeMargin = 60.0;
    const edgeAccel = 1200.0;
    if (_shipX < edgeMargin) {
      final k = ((edgeMargin - _shipX) / edgeMargin).clamp(0.0, 1.0);
      _shipVx += edgeAccel * k * dt;
    } else if (_shipX > size.width - edgeMargin) {
      final k = ((_shipX - (size.width - edgeMargin)) / edgeMargin).clamp(
        0.0,
        1.0,
      );
      _shipVx -= edgeAccel * k * dt;
    }
    if (_shipY < edgeMargin) {
      final k = ((edgeMargin - _shipY) / edgeMargin).clamp(0.0, 1.0);
      _shipVy += edgeAccel * k * dt;
    } else if (_shipY > size.height - edgeMargin) {
      final k = ((_shipY - (size.height - edgeMargin)) / edgeMargin).clamp(
        0.0,
        1.0,
      );
      _shipVy -= edgeAccel * k * dt;
    }

    // === SUBTLE BOB: piccola onda perpendicolare alla velocità. ===
    // amplitude 8px, frequency 0.6Hz → ω=2π·0.6. Forza = amp·ω² (analogia
    // SHM) modulata per dt → la nave guadagna oscillazione leggera.
    final vLen = math.sqrt(_shipVx * _shipVx + _shipVy * _shipVy);
    if (vLen > 1) {
      const bobAmp = 8.0;
      const bobFreq = 0.6;
      final omega = 2 * math.pi * bobFreq;
      // Velocità impulsiva perpendicolare (SHM derivata):
      // v_perp(t) = amp · ω · cos(ω · t)
      // Approssimazione: settiamo direttamente un offset di velocità
      // perpendicolare, additivo, piccolo.
      final realT = t * _chaseDurationSec;
      final bobV = bobAmp * omega * math.cos(omega * realT);
      final pX = -_shipVy / vLen;
      final pY = _shipVx / vLen;
      _shipVx += pX * bobV * dt;
      _shipVy += pY * bobV * dt;
    }

    // === SPEED CLAMP 300..400 px/s. ===
    final speed = math.sqrt(_shipVx * _shipVx + _shipVy * _shipVy);
    if (speed > maxSpeed) {
      final k = maxSpeed / speed;
      _shipVx *= k;
      _shipVy *= k;
    } else if (speed > 0.01 && speed < minSpeed) {
      final k = minSpeed / speed;
      _shipVx *= k;
      _shipVy *= k;
    }

    // === INTEGRAZIONE POSIZIONE. ===
    _shipX += _shipVx * dt;
    _shipY += _shipVy * dt;

    // === AIM: punta al MOB (non più alla velocity). Iter 23 (utente: "i
    // colpi non sfiorano il mob"): la nave ora si orienta verso il weaver
    // mentre lo orbita, così muso + muzzle + proiettili sono allineati sul
    // bersaglio. Durante l'avvicinamento velocity≈direzione-al-mob, quindi
    // l'orientamento resta quasi identico al video precedente; cambia solo
    // nelle fasi di strafe ravvicinato (legge come "circla e spara").
    // Convenzione game: _rotation = atan2(dir.y, dir.x) + π/2.
    final aimToMobX = droneX - _shipX;
    final aimToMobY = droneY - _shipY;
    if (aimToMobX * aimToMobX + aimToMobY * aimToMobY > 1) {
      _shipAim = math.atan2(aimToMobY, aimToMobX) + math.pi / 2;
    }

    // === BURST SNAPSHOT: quando t supera ogni burst-start, cattura
    // pos/aim correnti → usate da painter per origin/direction proiettili
    // (stessa logica dell'old: snapshot al burst-start, tutte le coppie
    // del burst sparate dalla stessa origine in fila).
    //
    // Bullet direction = ship aim direction (velocity normalized), NON
    // direzione-al-mob. Match comportamento in-game: in `Player.update`
    // `_rotation = atan2(aimDir.y, aimDir.x) + π/2` e `shootDir = aimDir`
    // (sparo allineato all'orientamento della nave). Snapshot mob-dir
    // creava muzzle disallineato dalla punta visuale quando velocity ≠
    // direzione-al-mob (strafe). ===
    const burstStarts = [0.10, 0.40, 0.70];
    for (int i = 0; i < burstStarts.length; i++) {
      if (!_burstCaptured[i] && t >= burstStarts[i]) {
        _burstCaptured[i] = true;
        _burstSnapX[i] = _shipX;
        _burstSnapY[i] = _shipY;
        // Velocity vector al snapshot — usata da painter per ricalcolare
        // la pos della nave a `fireTime` di ogni pair durante il burst
        // (assumendo movimento approx lineare nei 0.5s del burst).
        _burstSnapVx[i] = _shipVx;
        _burstSnapVy[i] = _shipVy;
        // Direzione = velocity direction (= ship aim direction).
        if (speed > 0.1) {
          _burstSnapDx[i] = _shipVx / speed;
          _burstSnapDy[i] = _shipVy / speed;
        } else {
          // Fallback: verso il mob se la nave è ferma (raro).
          final aimDxB = droneX - _shipX;
          final aimDyB = droneY - _shipY;
          final aimLenB = math.sqrt(aimDxB * aimDxB + aimDyB * aimDyB);
          if (aimLenB > 0.1) {
            _burstSnapDx[i] = aimDxB / aimLenB;
            _burstSnapDy[i] = aimDyB / aimLenB;
          } else {
            _burstSnapDx[i] = 1;
            _burstSnapDy[i] = 0;
          }
        }
      }
    }

    // === TRAIL PUSH: ring buffer di 18 past pos per scia cyan render. ===
    _trailHead = (_trailHead + 1) % _trailLen;
    _trailX[_trailHead] = _shipX;
    _trailY[_trailHead] = _shipY;
    if (_trailFilled < _trailLen) _trailFilled++;
  }

  @override
  void dispose() {
    _chaseController.dispose();
    _logoController.dispose();
    _bgController.dispose();
    // Iter 22 (flutter-review): rilascia le TextPainter cache statiche
    // del painter — eviterebbe accumulazione di paragraph layouts oltre
    // la durata della splash (l'unico screen che le popola).
    _SplashPainter.disposeStaticCaches();
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
              animation: Listenable.merge([
                _chaseController,
                _bgController,
                _logoController,
              ]),
              builder: (context, _) {
                // Iter 22 (flutter-review): `MediaQuery.sizeOf` narrows
                // sottoscrizione a sole `size` changes (vs `.of` che si
                // iscrive a tutto: orientation/textScale/padding/insets).
                // NOTA: `_lastSize` è memorizzato in `didChangeDependencies`
                // (non qui) — scrivere stato dentro un builder è un side-effect
                // di build; `MediaQuery.sizeOf` registra comunque la stessa
                // dipendenza, quindi il valore è già aggiornato a ogni resize.
                final screenSize = MediaQuery.sizeOf(context);
                return CustomPaint(
                  painter: _SplashPainter(
                    chaseProgress: _chaseController.value,
                    bgPhase: _bgController.value,
                    logoOpacity: _showLogo ? _logoOpacity.value : 0,
                    logoScale: _showLogo ? _logoScale.value : 0,
                    showExplosion: _showExplosion,
                    explosionPhase: _explosionPhase,
                    tapToStartText: l10n.splashTapToStart,
                    shipX: _shipX,
                    shipY: _shipY,
                    shipAim: _shipAim,
                    shipInit: _shipInit,
                    burstCaptured: _burstCaptured,
                    burstSnapX: _burstSnapX,
                    burstSnapY: _burstSnapY,
                    burstSnapDx: _burstSnapDx,
                    burstSnapDy: _burstSnapDy,
                    burstSnapVx: _burstSnapVx,
                    burstSnapVy: _burstSnapVy,
                    chaseDurationSec: _chaseDurationSec,
                    trailX: _trailX,
                    trailY: _trailY,
                    trailHead: _trailHead,
                    trailFilled: _trailFilled,
                    trailLen: _trailLen,
                  ),
                  size: screenSize,
                );
              },
            ),

            // SKIP button — neon fluo con HSV rainbow ciclante
            Positioned(
              top: MediaQuery.paddingOf(context).top + 12,
              right: 16,
              child: Semantics(
                button: true,
                label: l10n.splashSkip,
                child: GestureDetector(
                  onTap: _fireCompleteOnce,
                  child: NeonAnimatedBuilder(
                    animation: _bgController,
                    builder: (context, _) {
                      // Hue ciclante da `_bgController` (10s loop) + shift
                      // sinusoidale per pulse extra.
                      final hue = (_bgController.value * 360) % 360;
                      final pulse =
                          0.6 +
                          math.sin(_bgController.value * math.pi * 4) * 0.4;
                      final neonColor = HSVColor.fromAHSV(
                        1.0,
                        hue,
                        0.85,
                        1.0,
                      ).toColor();
                      final neonColorShift = HSVColor.fromAHSV(
                        1.0,
                        (hue + 90) % 360,
                        0.85,
                        1.0,
                      ).toColor();
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 9,
                        ),
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
                              color: neonColorShift.withValues(
                                alpha: 0.25 * pulse,
                              ),
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
                                    color: neonColorShift.withValues(
                                      alpha: 0.6,
                                    ),
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
  // Iter 15: ship state da steering (vedi `_updateShipSteering` nello State).
  final double shipX;
  final double shipY;
  final double shipAim;
  final bool shipInit;
  // Snapshot per bullet origins (3 burst). `burstCaptured[i]` controlla
  // se il burst è già stato avviato; coordinate + velocity al momento del
  // snapshot. La velocity è usata per ricalcolare pos della nave al fireTime
  // di ogni pair durante il burst (iter 17 fix "bullets dietro la nave").
  final List<bool> burstCaptured;
  final List<double> burstSnapX;
  final List<double> burstSnapY;
  final List<double> burstSnapDx;
  final List<double> burstSnapDy;
  final List<double> burstSnapVx; // velocity vector al snapshot (px/s reali)
  final List<double> burstSnapVy;
  final double chaseDurationSec; // conversione chase-units ↔ secondi reali
  // Trail ring buffer (vedi `_SplashScreenState._trailX/Y`).
  final List<double> trailX;
  final List<double> trailY;
  final int trailHead;
  final int trailFilled;
  final int trailLen;

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
  static final Paint _shipBodyPaint = Paint()..color = const Color(0xFF00FFFF);
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

  // Iter 22 (flutter-review): rimossi 8 Paint + 4 TextPainter cache associati
  // a `_drawGameGrid`, `_drawFloatingGeoms`, `_drawSecondaryKills`,
  // `_drawHUDOverlay` (tutti dead code rimossi nella stessa iter). Le iter
  // 11-13 li avevano marcati come "Tenuto per ref" ma git history è la
  // location corretta per il ref, non il file live.

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

  /// Rilascia le TextPainter cache statiche e azzera i sentinel di
  /// invalidation. Chiamato da `_SplashScreenState.dispose()`. Evita
  /// che paragraph layouts (UI native object) sopravvivano oltre la
  /// durata della splash e potenzialmente vengano riusati con stato
  /// stale in caso di hot-restart o splash re-mount.
  static void disposeStaticCaches() {
    _cachedTitlePainter?.dispose();
    _cachedTitlePainter = null;
    _cachedTitleAlphaQ = -1;
    _cachedTitleScaleQ = -1;
    _cachedSubPainter?.dispose();
    _cachedSubPainter = null;
    _cachedSubAlphaPulseQ = -1;
    _cachedSubText = null;
  }

  _SplashPainter({
    required this.chaseProgress,
    required this.bgPhase,
    required this.logoOpacity,
    required this.logoScale,
    required this.showExplosion,
    required this.explosionPhase,
    required this.tapToStartText,
    required this.shipX,
    required this.shipY,
    required this.shipAim,
    required this.shipInit,
    required this.burstCaptured,
    required this.burstSnapX,
    required this.burstSnapY,
    required this.burstSnapDx,
    required this.burstSnapDy,
    required this.burstSnapVx,
    required this.burstSnapVy,
    required this.chaseDurationSec,
    required this.trailX,
    required this.trailY,
    required this.trailHead,
    required this.trailFilled,
    required this.trailLen,
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
      colors: [Color.fromRGBO(30, 0, 100, pulse1), Colors.transparent],
    ).createShader(Rect.fromCircle(center: p1, radius: size.width * 0.5));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), _nebulaPaint);

    // Nebulosa cyan in basso a destra
    final p2 = Offset(size.width * 0.8, size.height * 0.7);
    final pulse2 = 0.02 + math.sin(bgPhase * math.pi * 2 + 2) * 0.01;
    _nebulaPaint.shader = RadialGradient(
      colors: [Color.fromRGBO(0, 50, 80, pulse2), Colors.transparent],
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
      final parallax =
          bgPhase * 40 * speedMul + (chaseProgress * 400 * speedMul);
      final x = (baseX - parallax) % size.width;
      final s = 0.3 + random.nextDouble() * 0.7;
      final twinkle =
          0.2 +
          0.5 *
              ((math.sin(
                        bgPhase * math.pi * 2 * (0.5 + random.nextDouble()) + i,
                      ) +
                      1) /
                  2);
      _starsPaint.color = Color.fromRGBO(180, 200, 255, twinkle * 0.4);
      canvas.drawCircle(Offset(x, y), s, _starsPaint);
    }

    // Layer medio: 30 → 90
    for (int i = 0; i < 90; i++) {
      final baseX = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final speedMul = 0.6 + random.nextDouble() * 1.8;
      final parallax =
          bgPhase * 80 * speedMul + (chaseProgress * 1000 * speedMul);
      final x = (baseX - parallax) % size.width;
      final s = 0.5 + random.nextDouble() * 1.2;
      final twinkle =
          0.3 +
          0.7 *
              ((math.sin(
                        bgPhase * math.pi * 2 * (1 + random.nextDouble()) +
                            i * 3,
                      ) +
                      1) /
                  2);
      _starsPaint.color = Color.fromRGBO(200, 220, 255, twinkle * 0.6);
      canvas.drawCircle(Offset(x, y), s, _starsPaint);
    }

    // Layer vicino: 8 → 24, velocità massima variata per profondità
    for (int i = 0; i < 24; i++) {
      final baseX = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final speedMul = 0.7 + random.nextDouble() * 2.3;
      final parallax =
          bgPhase * 160 * speedMul + (chaseProgress * 2000 * speedMul);
      final x = (baseX - parallax) % size.width;
      final s = 1.0 + random.nextDouble() * 1.5;
      final twinkle =
          0.4 +
          0.6 *
              ((math.sin(
                        bgPhase * math.pi * 2 * (2 + random.nextDouble()) +
                            i * 7,
                      ) +
                      1) /
                  2);
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
      final x =
          (random.nextDouble() * size.width * 1.5 -
              chaseProgress * size.width * 2) %
          (size.width + len);
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
    final droneY =
        cy + math.sin(t * math.pi * 2) * size.height * 0.32 + droneJitter;

    // === Iter 15: ship pos da steering (NON più formula). ===
    // Lo state `_updateShipSteering` integra velocity + position frame-by-frame.
    // Se non ancora inizializzata (primissimi frame), usa pos iniziale
    // ragionevole per evitare disegno della nave a (0,0).
    final double effShipX;
    final double effShipY;
    final double effAim;
    if (shipInit) {
      effShipX = shipX;
      effShipY = shipY;
      effAim = shipAim;
    } else {
      effShipX = -size.width * 0.10;
      effShipY = cy;
      effAim = math.pi / 2;
    }
    // shipT è usato dalle animazioni interne della nave (thrust pulse,
    // cockpit glow, wing lights) — manteniamo la stessa derivazione dal
    // chase progress in modo che le animazioni rimangano fluide.
    const shipDelay = 0.1;
    final shipT = (t - shipDelay).clamp(0.0, 1.0);
    final aimAngle = effAim;

    // === SCIA WEAVER (verde, matching ampia sinusoide nuova trajectory) ===
    for (int i = 1; i <= 12; i++) {
      final raw = t - i * 0.01;
      if (raw <= 0) break;
      final dt2 = raw.clamp(0.0, 1.0);
      final dtx = size.width * (-0.15 + dt2 * 1.20);
      final dJitterPast = math.sin(dt2 * math.pi * 8) * 6;
      final dty =
          cy + math.sin(dt2 * math.pi * 2) * size.height * 0.32 + dJitterPast;
      final a = (1 - i / 12.0) * 0.22;
      final s = (1 - i / 12.0) * 3.5;
      _droneTrailPaint.color = Color.fromRGBO(0, 255, 90, a);
      _droneTrailPaint.maskFilter = MaskFilter.blur(BlurStyle.normal, s);
      canvas.drawCircle(Offset(dtx, dty), s, _droneTrailPaint);
    }

    // === SCIA NAVICELLA (cyan — usa ring buffer past pos da state). ===
    // i=1 = sample appena precedente; i=trailFilled-1 = sample più vecchio.
    // Skip i>=trailFilled (non ancora popolati nei primissimi frame).
    final maxTrail = trailFilled < trailLen ? trailFilled : trailLen;
    for (int i = 1; i < maxTrail; i++) {
      final idx = (trailHead - i + trailLen) % trailLen;
      final tx = trailX[idx];
      final ty = trailY[idx];
      final a = (1 - i / trailLen.toDouble()) * 0.4;
      final s = (1 - i / trailLen.toDouble()) * 3.5;
      _shipTrailGlowPaint.color = const Color(
        0xFF00FFFF,
      ).withValues(alpha: a * 0.4);
      canvas.drawCircle(Offset(tx, ty), s * 1.8, _shipTrailGlowPaint);
      _shipTrailCorePaint.color = const Color(0xFF00FFFF).withValues(alpha: a);
      canvas.drawCircle(Offset(tx, ty), s, _shipTrailCorePaint);
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
      // Velocità bullet: cinematica splash, ~2.85× in-game (700 px/s)
      // per dare effetto "raffica fulmine" e impedire alla nave di
      // sorpassare i proiettili visivamente. 2000 px/s × 3.5 = 7000.
      // Iter 16 era 2450 (match in-game) → bullets troppo vicini alla
      // nave durante il burst (nave a 400 px/s, gap solo 300 px/s).
      // Ora gap 2000-280 = 1720 px/s, i bullet schizzano via davanti.
      const bulletSpeedPerChaseUnit = 7000.0;

      for (int b = 0; b < burstStarts.length; b++) {
        final burstStart = burstStarts[b];
        if (t <= burstStart) continue;
        // Iter 15: usa SNAPSHOT catturato dallo state al burst-start
        // (steering-based pos/aim) invece di ricalcolare dalla formula.
        // Skip se snapshot non ancora catturato (transitorio raro).
        if (!burstCaptured[b]) continue;
        final burstShipX = burstSnapX[b];
        final burstShipY = burstSnapY[b];
        // Velocity vector al snapshot — usata per ricalcolare pos della
        // nave a fireTime di ogni pair (iter 17 fix "bullets dietro").
        final snapVx = burstSnapVx[b];
        final snapVy = burstSnapVy[b];
        // Iter 23 (utente: "i colpi non sfiorano il mob"): la direzione del
        // proiettile ora PUNTA AL MOB (non più alla velocity/orientamento
        // nave). Calcolata per-coppia verso la pos del weaver al fireTime,
        // con bias perpendicolare costante sul lato di coda → i bullet
        // passano SEMPRE a un soffio dal mob (graze) invece di mancarlo
        // largo. Il weaver continua la sua sinusoide, quindi il near-miss
        // legge come "schiva all'ultimo". noseOffset 22 = match in-game
        // `nose = position + dir.normalized() * 22` (Player.dart line 467).
        const noseOffset = 22.0;
        // grazeBias: clearance verticale (px) tra la mira e il centro mob.
        // Con la coppia ±pairOffset il bullet interno passa ~grazeBias-
        // pairOffset dal centro (mob mezzo-asse verticale ≈ 8.5px) → sfiora
        // il bordo senza colpire.
        const grazeBias = 18.0;

        // Itera coppie del burst.
        for (int p = 0; p < pairsPerBurst; p++) {
          final fireTime = burstStart + p * pairInterval;
          if (t <= fireTime) continue;
          final dtSinceFire = t - fireTime;

          // Iter 17: pos della nave a `fireTime` ricalcolata da
          // posSnap + velSnap × (fireTime - burstStart_in_seconds), così i
          // bullet non partono "dietro" alla nave che si è già mossa.
          final dtFromBurstStartSec =
              (fireTime - burstStart) * chaseDurationSec;
          final shipCenterX = burstShipX + snapVx * dtFromBurstStartSec;
          final shipCenterY = burstShipY + snapVy * dtFromBurstStartSec;

          // Pos mob al fireTime (stessa traiettoria di _drawChaseScene).
          final mobAtX = size.width * (-0.15 + fireTime * 1.20);
          final mobAtY =
              cy +
              math.sin(fireTime * math.pi * 2) * size.height * 0.32 +
              math.sin(fireTime * math.pi * 8) * 6;
          // Direzione base verso il mob + perpendicolare a essa: il graze
          // bias è applicato LUNGO questa perpendicolare (non verticale) così
          // la clearance ≈ grazeBias in QUALSIASI orientamento — anche se la
          // nave è sopra/sotto il mob (dove un bias verticale collasserebbe a
          // zero e il bullet centrerebbe).
          var baseDx = mobAtX - shipCenterX;
          var baseDy = mobAtY - shipCenterY;
          final baseLen = math.sqrt(baseDx * baseDx + baseDy * baseDy);
          if (baseLen < 0.5) continue;
          baseDx /= baseLen;
          baseDy /= baseLen;
          final basePerpX = -baseDy;
          final basePerpY = baseDx;
          // Velocità mob (finite diff) → bias sul lato di CODA (opposto al
          // moto): il mob "slitta via" dalla traiettoria → near-miss schivato.
          final mobAheadX = size.width * (-0.15 + (fireTime + 0.01) * 1.20);
          final mobAheadY =
              cy +
              math.sin((fireTime + 0.01) * math.pi * 2) * size.height * 0.32 +
              math.sin((fireTime + 0.01) * math.pi * 8) * 6;
          final mvDotPerp =
              (mobAheadX - mobAtX) * basePerpX +
              (mobAheadY - mobAtY) * basePerpY;
          final biasSign = mvDotPerp >= 0 ? -1.0 : 1.0;
          // Aim = mob + perp × graze bias → dir normalizzata.
          final aimX =
              (mobAtX + basePerpX * biasSign * grazeBias) - shipCenterX;
          final aimY =
              (mobAtY + basePerpY * biasSign * grazeBias) - shipCenterY;
          final aimLen = math.sqrt(aimX * aimX + aimY * aimY);
          if (aimLen < 0.5) continue;
          final dirX = aimX / aimLen;
          final dirY = aimY / aimLen;
          final perpX = -dirY;
          final perpY = dirX;

          // Distanza percorsa dal bullet: velocity costante × dt
          // (dt in chase-units, speed in px/chase-unit).
          final travel = bulletSpeedPerChaseUnit * dtSinceFire;

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
              _bulletTrailPaint.color = bulletColor.withValues(alpha: tAlpha);
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
            _bulletCorePaint.color = const Color(
              0xFFFFFFFF,
            ).withValues(alpha: 0.85);
            canvas.drawCircle(Offset(bx, by), 1.3, _bulletCorePaint);

            // Muzzle flash al nose durante primi 0.05 chase-time del bullet
            if (dtSinceFire < 0.05) {
              final flashAlpha = (1 - dtSinceFire / 0.05) * 0.7;
              _muzzleGlowPaint.color = bulletColor.withValues(
                alpha: flashAlpha * 0.5,
              );
              canvas.drawCircle(Offset(fromX, fromY), 8, _muzzleGlowPaint);
              _muzzleCorePaint.color = const Color(
                0xFFFFFFFF,
              ).withValues(alpha: flashAlpha);
              canvas.drawCircle(Offset(fromX, fromY), 4, _muzzleCorePaint);
            }
          } // for side
        } // for p (pair within burst)
      } // for b (burst)
    } // if (t > 0.1)

    // === WEAVER: schiva TUTTI i proiettili, non viene mai colpito.
    // Nessun fumo/damage — il mob sopravvive per tutto lo splash. ===
    _drawDrone(canvas, droneX, droneY, t);

    // === NAVICELLA (in-game graphics, ruota verso velocity per Iter 15). ===
    _drawShip(canvas, effShipX, effShipY, shipT, aimAngle);
  }

  /// Weaver verde (stile `WeaverEnemy` in gioco): rombo ALLUNGATO vertical
  /// con bordo neon, flusso energetico interno, nodi sulle 4 punte.
  /// Orientato orizzontale (punta verso sx = direzione di fuga).
  void _drawDrone(Canvas canvas, double x, double y, double t) {
    // Scala: `w=6, h=12` come WeaverEnemy in gioco × fattore per splash.
    const w = 8.5; // lato corto (perpendicolare alla fuga)
    const h = 17.0; // lato lungo (direzione di fuga)
    canvas.save();
    canvas.translate(x, y);
    // Weaver in fuga: orientato verso SX (−X in world) — rotazione π/2
    // per allungarlo orizzontale.
    canvas.rotate(math.pi / 2);

    // Iter 22 (flutter-review): rimosso branch `damaged` — il weaver
    // schiva tutti i bullets e non viene mai colpito, quindi il body
    // resta sempre verde neon. Era dead code.
    const bodyColor = Color(0xFF00FF44); // verde neon (NeonColors.green)

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
      _droneCorePaint.color = const Color(
        0xFFFFFFFF,
      ).withValues(alpha: flowAlpha);
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
    _droneCoreHaloPaint.color = const Color(
      0xFFFFFFFF,
    ).withValues(alpha: corePulse * 0.35);
    canvas.drawCircle(Offset.zero, w * 0.45, _droneCoreHaloPaint);
    _droneCorePaint.color = const Color(
      0xFFFFFFFF,
    ).withValues(alpha: corePulse);
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
      ..moveTo(0, -14 * s) // Punta
      ..lineTo(4 * s, -6 * s) // Lato destro punta
      ..lineTo(13 * s, 10 * s) // Ala destra esterna
      ..lineTo(8 * s, 8 * s) // Rientro ala destra
      ..lineTo(5 * s, 14 * s) // Coda destra
      ..lineTo(0, 10 * s) // Centro coda
      ..lineTo(-5 * s, 14 * s) // Coda sinistra
      ..lineTo(-8 * s, 8 * s) // Rientro ala sinistra
      ..lineTo(-13 * s, 10 * s) // Ala sinistra esterna
      ..lineTo(-4 * s, -6 * s) // Lato sinistro punta
      ..close();

    // Glow esterno (come `Player.render` layer 3 — `_drawShipBody(1.7)`)
    canvas.drawPath(shipPath, _shipGlowPaint);

    // Corpo principale (cyan pieno)
    canvas.drawPath(shipPath, _shipBodyPaint);

    // Bordo luminoso bianco sottile
    canvas.drawPath(shipPath, _shipStrokePaint);

    // ─── COCKPIT (stesso stile di `Player._renderShipDetails`) ───
    final cockpitGlow = 0.6 + math.sin(t * 10) * 0.2;
    _cockpitHaloPaint.color = const Color(
      0xFFFFFFFF,
    ).withValues(alpha: cockpitGlow * 0.5);
    canvas.drawCircle(const Offset(0, -4 * s), 5, _cockpitHaloPaint);
    _cockpitWhitePaint.color = const Color(
      0xFFFFFFFF,
    ).withValues(alpha: cockpitGlow);
    canvas.drawCircle(const Offset(0, -4 * s), 3, _cockpitWhitePaint);
    _cockpitCyanPaint.color = const Color(0xFF00FFFF).withValues(alpha: 0.9);
    canvas.drawCircle(const Offset(0, -4 * s), 2, _cockpitCyanPaint);

    // Linee strutturali (stesse di `Player._renderShipDetails`)
    canvas.drawLine(
      const Offset(-2 * s, 0),
      const Offset(-10 * s, 10 * s),
      _shipLinePaint,
    );
    canvas.drawLine(
      const Offset(2 * s, 0),
      const Offset(10 * s, 10 * s),
      _shipLinePaint,
    );
    canvas.drawLine(
      const Offset(0, -8 * s),
      const Offset(0, 8 * s),
      _shipLinePaint,
    );

    // ─── WING-TIP LIGHTS (rossa a sx, verde a dx — come in gioco) ───
    final wingPulse = 0.5 + math.sin(t * 15) * 0.5;
    _wingRedGlowPaint.color = Color.fromRGBO(255, 50, 50, wingPulse * 0.3);
    canvas.drawCircle(const Offset(-12 * s, 10 * s), 4, _wingRedGlowPaint);
    _wingRedCorePaint.color = Color.fromRGBO(255, 50, 50, wingPulse * 0.9);
    canvas.drawCircle(const Offset(-12 * s, 10 * s), 2, _wingRedCorePaint);
    _wingGreenGlowPaint.color = Color.fromRGBO(50, 255, 100, wingPulse * 0.3);
    canvas.drawCircle(const Offset(12 * s, 10 * s), 4, _wingGreenGlowPaint);
    _wingGreenCorePaint.color = Color.fromRGBO(50, 255, 100, wingPulse * 0.9);
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
      _explosionRingPaint.color = Color.fromRGBO(0, 255, 255, alpha.toDouble());
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
      _explosionDebrisPaint.color = Color.fromRGBO(
        0,
        255,
        255,
        alpha.toDouble(),
      );
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

  @override
  bool shouldRepaint(covariant _SplashPainter oldDelegate) {
    // Ripaint solo se un campo letto dal painter è cambiato. Gli scalari sono
    // confrontati per valore; le liste di snapshot/trail sono mutate in-place
    // dallo State (stessa identità ogni frame), quindi i loro contenuti sono
    // tracciati tramite i cursori scalari che cambiano in lockstep:
    //  - trail ring buffer → trailHead/trailFilled avanzano ad ogni nuovo
    //    sample (vedi `_updateShipSteering`), con il sample più recente in
    //    shipX/shipY (già confrontati);
    //  - burst snapshot → burstCaptured[i] passa a true nello stesso istante in
    //    cui burstSnap* viene scritto, e poi la posizione è ricalcolata da
    //    chaseProgress/chaseDurationSec (già confrontati). burstCaptured è una
    //    lista bool mutata in-place, quindi va confrontata elemento per
    //    elemento (l'identità non cambia).
    return chaseProgress != oldDelegate.chaseProgress ||
        bgPhase != oldDelegate.bgPhase ||
        logoOpacity != oldDelegate.logoOpacity ||
        logoScale != oldDelegate.logoScale ||
        showExplosion != oldDelegate.showExplosion ||
        explosionPhase != oldDelegate.explosionPhase ||
        tapToStartText != oldDelegate.tapToStartText ||
        shipX != oldDelegate.shipX ||
        shipY != oldDelegate.shipY ||
        shipAim != oldDelegate.shipAim ||
        shipInit != oldDelegate.shipInit ||
        chaseDurationSec != oldDelegate.chaseDurationSec ||
        trailHead != oldDelegate.trailHead ||
        trailFilled != oldDelegate.trailFilled ||
        trailLen != oldDelegate.trailLen ||
        !listEquals(burstCaptured, oldDelegate.burstCaptured);
  }
}

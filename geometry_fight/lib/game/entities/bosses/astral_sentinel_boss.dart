import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../../data/constants.dart';
import '../../../data/wave_configs.dart';
import 'boss_base.dart';
import '../projectiles.dart';

/// ASTRAL SENTINEL (wave 35).
///
/// Meccaniche uniche:
///   - Boss "star-gate" semi-stazionario (drift verso centro arena).
///   - Ciclicamente spawna N stelle sui vertici di un poligono attorno al
///     player. Dopo un wind-up di 2.5s (1.8s in fase 1+), le stelle emettono
///     una rete di "laser" (proiettili lungo le linee fra vertici).
///   - Fase 1: pentagono (5 stelle).
///   - Fase 2 (<60% HP): ettagono (7 stelle), wind-up più veloce.
///   - Fase 3 (<30% HP): decagono (10 stelle).
///
/// FX: esagono cristallino ruotante (corpo), aura cosmica 4 strati pulsanti,
/// stelle con 5 raggi animati, linee laser gradient che si intensificano
/// durante il wind-up.
// Fire samples per linea ridotti 6→4 + chunk di 2 linee/frame per evitare
// frame hitch (fase 3 era 60 bullet in 1 frame → ora 8 bullet × 5 frame).
const int _kLineSamples = 4;
const int _kLinesPerFrame = 2;
// Raggio base poligono — scala con star count per evitare sovrapposizione.
const double _kBaseRadius = 140;
const double _kRadiusPerExtraStar = 15;

class AstralSentinelBoss extends BossBase {
  double _phase = 0;
  double _starWindUp = 2.5;
  double _cycleTimer = 4.0;
  bool _starsActive = false;
  List<Vector2> _starPositions = [];
  double _linesFireTimer = 0;
  // Queue di indici linee da processare (spalma il fire su più frame).
  final List<int> _fireQueue = [];

  static final _starPaint = Paint();
  static final _starGlowPaint = Paint();
  static final _linePaint = Paint()..style = PaintingStyle.stroke;
  // Due Paint separati per corpo hex: evita style switch 3× per render.
  static final _hexFillPaint = Paint()..style = PaintingStyle.fill;
  static final _hexStrokePaint = Paint()..style = PaintingStyle.stroke;
  static final _coreInnerPaint = Paint();
  static final _auraPaint = Paint();
  static final _starRayPaint = Paint()..style = PaintingStyle.stroke;

  AstralSentinelBoss()
      : super(
          hp: 900,
          bossName: 'ASTRAL SENTINEL',
          pointValue: 9000,
          neonColor: NeonColors.cyan,
          size: Vector2(130, 130),
        );

  int get _starCount {
    if (currentPhase >= 2) return 10;
    if (currentPhase >= 1) return 7;
    return 5;
  }

  // AstralSentinel è CIANO COSMICO → mob ciano/stellari (drone + orbiter + pulsar).
  @override
  List<EnemyType> get colorMatchedMinions =>
      const [EnemyType.drone, EnemyType.orbiter, EnemyType.pulsar];

  @override
  int getPhase() {
    if (healthPercent < 0.30) return 2;
    if (healthPercent < 0.60) return 1;
    return 0;
  }

  @override
  void updateBoss(double dt) {
    _phase += dt;

    // Drift lento verso centro arena (boss semi-stazionario).
    final centerArena = Vector2(arenaWidth / 2, arenaHeight / 2);
    final toCenter = centerArena - position;
    if (toCenter.length > 10) {
      position += toCenter.normalized() * 20 * dt;
    }

    _cycleTimer -= dt;
    if (_cycleTimer <= 0 && !_starsActive) {
      _cycleTimer = 0;
      _starsActive = true;
      _starWindUp = currentPhase >= 1 ? 1.8 : 2.5;
      final cnt = _starCount;
      // Scala raggio col numero di stelle per evitare sovrapposizioni
      // (pentagon=140, heptagon=170, decagon=215).
      final radius = _kBaseRadius + (cnt - 5) * _kRadiusPerExtraStar;
      _starPositions = List.generate(cnt, (i) {
        final ang = _phase * 0.8 + i * math.pi * 2 / cnt;
        final raw = playerPosition +
            Vector2(math.cos(ang), math.sin(ang)) * radius;
        // Clamp a arena bounds così le stelle restano sempre dentro la zona
        // di gioco (player vicino al bordo non "imbrogliava").
        return Vector2(
          raw.x.clamp(30.0, arenaWidth - 30.0),
          raw.y.clamp(30.0, arenaHeight - 30.0),
        );
      });
      _fireQueue.clear();
    }

    if (_starsActive) {
      _starWindUp -= dt;
      if (_starWindUp <= 0 && _fireQueue.isEmpty && _linesFireTimer <= 0) {
        // Inizia il fire: carica la coda con gli indici delle linee.
        for (int i = 0; i < _starPositions.length; i++) {
          _fireQueue.add(i);
        }
      }
      // Processa chunk di linee per frame.
      if (_fireQueue.isNotEmpty) {
        final chunk = _fireQueue.length < _kLinesPerFrame
            ? _fireQueue.length
            : _kLinesPerFrame;
        for (int c = 0; c < chunk; c++) {
          final i = _fireQueue.removeAt(0);
          final a = _starPositions[i];
          final b = _starPositions[(i + 1) % _starPositions.length];
          final dir = (b - a);
          final dist = dir.length;
          if (dist < 0.001) continue; // skip linee degeneri
          final dirN = dir.normalized();
          for (int s = 0; s < _kLineSamples; s++) {
            final t = s / (_kLineSamples - 1);
            final pos = a + dirN * (dist * t);
            // speed 0 → bullet statico (laser-like). Lifetime default 4s
            // copre la durata della ricarica (cycleTimer 3-4s).
            final perp = Vector2(-dirN.y, dirN.x);
            final bullet = EnemyBullet(
                direction: perp, speed: 0, color: NeonColors.cyan);
            bullet.position = pos;
            game.world.add(bullet);
          }
        }
        if (_fireQueue.isEmpty) {
          // Fire completato: reset per il prossimo ciclo.
          _starsActive = false;
          _cycleTimer = currentPhase >= 2 ? 3.0 : 4.0;
          _linesFireTimer = 0;
        }
      }
    }
  }

  @override
  void renderBoss(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;

    // Aura cosmica multi-strato
    for (int i = 0; i < 4; i++) {
      final auraR = (50 + i * 15) * scale;
      final auraAlpha =
          (0.2 - i * 0.04) * (0.5 + math.sin(_phase * 2 + i) * 0.5);
      _auraPaint.color =
          NeonColors.cyan.withValues(alpha: auraAlpha * paint.color.a);
      canvas.drawCircle(Offset(cx, cy), auraR, _auraPaint);
    }

    // Corpo: esagono ruotante
    const hexSides = 6;
    final hexR = 32 * scale;
    final hexRot = _phase * 0.6;
    final hexPath = Path();
    for (int i = 0; i < hexSides; i++) {
      final a = hexRot + i * math.pi * 2 / hexSides;
      final x = cx + math.cos(a) * hexR;
      final y = cy + math.sin(a) * hexR;
      if (i == 0) {
        hexPath.moveTo(x, y);
      } else {
        hexPath.lineTo(x, y);
      }
    }
    hexPath.close();
    // Due Paint separati (fill + stroke) → no state churn.
    _hexFillPaint.color = paint.color.withValues(alpha: paint.color.a * 0.5);
    canvas.drawPath(hexPath, _hexFillPaint);
    _hexStrokePaint.strokeWidth = 2 * scale;
    _hexStrokePaint.color = paint.color;
    canvas.drawPath(hexPath, _hexStrokePaint);
    _coreInnerPaint.color =
        const Color(0xFFFFFFFF).withValues(alpha: paint.color.a);
    canvas.drawCircle(Offset(cx, cy), 10 * scale, _coreInnerPaint);

    // Stelle + linee (render relativo a boss)
    if (_starsActive && _starPositions.isNotEmpty) {
      final windFrac = 1.0 - (_starWindUp / 2.5).clamp(0.0, 1.0);
      final lineAlpha = windFrac.clamp(0.0, 1.0);

      _linePaint.color =
          NeonColors.cyan.withValues(alpha: 0.3 + lineAlpha * 0.5);
      _linePaint.strokeWidth = 1 + lineAlpha * 2;
      for (int i = 0; i < _starPositions.length; i++) {
        final a = _starPositions[i] - position + Vector2(cx, cy);
        final b = _starPositions[(i + 1) % _starPositions.length] -
                position +
            Vector2(cx, cy);
        canvas.drawLine(
            Offset(a.x, a.y), Offset(b.x, b.y), _linePaint);
      }

      for (final star in _starPositions) {
        final local = star - position + Vector2(cx, cy);
        final pulse = 0.7 + math.sin(_phase * 6) * 0.3;
        _starGlowPaint.color = NeonColors.cyan
            .withValues(alpha: 0.4 * pulse * lineAlpha);
        canvas.drawCircle(
            Offset(local.x, local.y), 12 * scale * pulse, _starGlowPaint);
        // 5 raggi punte stella
        _starRayPaint.color = const Color(0xFFFFFFFF)
            .withValues(alpha: pulse * lineAlpha);
        _starRayPaint.strokeWidth = 1.2 * scale;
        for (int k = 0; k < 5; k++) {
          final a = _phase * 2 + k * math.pi * 2 / 5;
          final tipX = local.x + math.cos(a) * 9 * scale;
          final tipY = local.y + math.sin(a) * 9 * scale;
          canvas.drawLine(
              Offset(local.x, local.y), Offset(tipX, tipY), _starRayPaint);
        }
        _starPaint.color = const Color(0xFFFFFFFF)
            .withValues(alpha: pulse * lineAlpha);
        canvas.drawCircle(Offset(local.x, local.y), 3 * scale, _starPaint);
      }
    }
  }
}

import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../../data/constants.dart';
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
class AstralSentinelBoss extends BossBase {
  double _phase = 0;
  double _starWindUp = 2.5;
  double _cycleTimer = 4.0;
  bool _starsActive = false;
  List<Vector2> _starPositions = [];
  double _linesFireTimer = 0;

  static final _starPaint = Paint();
  static final _starGlowPaint = Paint();
  static final _linePaint = Paint()..style = PaintingStyle.stroke;
  static final _coreHexPaint = Paint();
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
      const radius = 140.0;
      _starPositions = List.generate(cnt, (i) {
        final ang = _phase * 0.8 + i * math.pi * 2 / cnt;
        return playerPosition +
            Vector2(math.cos(ang), math.sin(ang)) * radius;
      });
    }

    if (_starsActive) {
      _starWindUp -= dt;
      if (_starWindUp <= 0 && _linesFireTimer <= 0) {
        _linesFireTimer = 0.4;
        // Fire: spara proiettili lungo ogni linea fra vertici consecutivi.
        for (int i = 0; i < _starPositions.length; i++) {
          final a = _starPositions[i];
          final b = _starPositions[(i + 1) % _starPositions.length];
          final dir = (b - a).normalized();
          final dist = (b - a).length;
          const samples = 6;
          for (int s = 0; s < samples; s++) {
            final t = s / (samples - 1);
            final pos = a + dir * (dist * t);
            final perp = Vector2(-dir.y, dir.x) * 2;
            final bullet = EnemyBullet(
                direction: perp, speed: 30, color: NeonColors.cyan);
            bullet.position = pos;
            game.world.add(bullet);
          }
        }
        _starsActive = false;
        _cycleTimer = currentPhase >= 2 ? 3.0 : 4.0;
      }
      if (_linesFireTimer > 0) _linesFireTimer -= dt;
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
    _coreHexPaint.style = PaintingStyle.fill;
    _coreHexPaint.color = paint.color.withValues(alpha: paint.color.a * 0.5);
    canvas.drawPath(hexPath, _coreHexPaint);
    _coreHexPaint.style = PaintingStyle.stroke;
    _coreHexPaint.strokeWidth = 2 * scale;
    _coreHexPaint.color = paint.color;
    canvas.drawPath(hexPath, _coreHexPaint);
    _coreHexPaint.style = PaintingStyle.fill;
    _coreHexPaint.color =
        const Color(0xFFFFFFFF).withValues(alpha: paint.color.a);
    canvas.drawCircle(Offset(cx, cy), 10 * scale, _coreHexPaint);

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

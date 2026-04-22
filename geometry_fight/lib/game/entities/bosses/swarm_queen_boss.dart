import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../../data/wave_configs.dart';
import 'boss_base.dart';

/// SWARM QUEEN - Boss che genera sciami infiniti di SwarmDrone.
/// Forma: grande esagono con celle (alveare) e ali membranose
/// Colore: rosa intenso (#FF2288)
/// HP: 1800 · 3 fasi
/// Meccanica: spawna ondate di SwarmDrone ogni 2s.
/// In fase 2 i droni sono più veloci. In fase 3 spawna anche Kamikaze.
class SwarmQueenBoss extends BossBase {
  double _spawnTimer = 2.0;
  double _cellPhase = 0;
  double _wingPhase = 0;

  SwarmQueenBoss()
      : super(
          hp: 1800,
          bossName: 'SWARM QUEEN',
          pointValue: 3500,
          neonColor: const Color(0xFFFF2288),
          size: Vector2(110, 110),
        );

  @override
  int getPhase() {
    if (healthPercent > 0.6) return 0;
    if (healthPercent > 0.25) return 1;
    return 2;
  }

  @override
  void updateBoss(double dt) {
    _cellPhase += dt * 3;
    _wingPhase += dt * 5;

    // Movimento lento
    final toPlayer = (playerPosition - position);
    if (toPlayer.length > 200) {
      position += toPlayer.normalized() * 50 * dt;
    }

    // Spawna sciami
    _spawnTimer -= dt;
    if (_spawnTimer <= 0) {
      _spawnTimer = (2.5 - currentPhase * 0.5).clamp(1.0, 3.0);
      _spawnSwarm();
    }
  }

  void _spawnSwarm() {
    // Cap: non spawnare se ci sono già troppi nemici
    if (game.enemyCount >= 30) return;
    final count = 5 + currentPhase * 3;
    for (int i = 0; i < count; i++) {
      final angle = math.Random().nextDouble() * math.pi * 2;
      final dist = 40 + math.Random().nextDouble() * 30;
      final pos = position + Vector2(math.cos(angle) * dist, math.sin(angle) * dist);
      game.spawnEnemy(EnemyType.swarmDrone, pos);
    }
    // Fase 3: spawna anche kamikaze
    if (currentPhase >= 2) {
      for (int i = 0; i < 2; i++) {
        game.spawnEnemy(EnemyType.kamikaze, position + Vector2(
          (math.Random().nextDouble() - 0.5) * 80,
          (math.Random().nextDouble() - 0.5) * 80,
        ));
      }
    }
  }

  // Signature FX paints
  static final _wingPaint = Paint();
  static final _wingShimmerPaint = Paint()..style = PaintingStyle.stroke;
  static final _pollenPaint = Paint();
  static final _crownPaint = Paint();
  static final _crownJewelPaint = Paint();
  static final _cellPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.8;
  static final _cellFillPaint = Paint();
  static final _coreHaloPaint = Paint();
  static final _corePaint = Paint();
  static final _droneOrbitPaint = Paint();

  @override
  void renderBoss(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final r = size.x / 2 * scale;

    // ─── ALI MEMBRANOSE CON SHIMMER ───
    if (scale <= 1.01) {
      final wingFlap = math.sin(_wingPhase) * 0.15;
      for (int side = -1; side <= 1; side += 2) {
        _wingPaint.color = neonColor.withValues(alpha: 0.18);
        final wingPath = Path()
          ..moveTo(cx + side * r * 0.4, cy)
          ..quadraticBezierTo(
            cx + side * r * 1.2, cy - r * 0.3 + wingFlap * 30,
            cx + side * r * 0.8, cy + r * 0.5,
          )
          ..lineTo(cx + side * r * 0.4, cy + r * 0.2)
          ..close();
        canvas.drawPath(wingPath, _wingPaint);
        _wingShimmerPaint.color = const Color(0xFFFFAACC)
            .withValues(alpha: 0.35 + math.sin(_wingPhase * 2) * 0.25);
        _wingShimmerPaint.strokeWidth = 1;
        canvas.drawPath(wingPath, _wingShimmerPaint);
      }
    }

    // ─── POLLINE (particelle gialle che fluttuano attorno) ───
    if (scale <= 1.01) {
      for (int i = 0; i < 10; i++) {
        final pP = _cellPhase * 0.4 + i * 0.6;
        final pAngle = pP;
        final pDist = r * (1.15 + ((pP * 0.25) % 1.0) * 0.5);
        final pAlpha = (1.0 - ((pP * 0.25) % 1.0)) * 0.7;
        _pollenPaint.color =
            const Color(0xFFFFDD88).withValues(alpha: pAlpha);
        canvas.drawCircle(
          Offset(cx + math.cos(pAngle) * pDist,
              cy + math.sin(pAngle) * pDist),
          1.8,
          _pollenPaint,
        );
      }
    }

    // ─── MINI DRONI ORBITANTI (4 piccole api-triangoli) ───
    if (scale <= 1.01) {
      for (int d = 0; d < 4; d++) {
        final dAngle = _cellPhase * 0.8 + d * math.pi / 2;
        final dR = r * 1.3;
        final dx = cx + math.cos(dAngle) * dR;
        final dy = cy + math.sin(dAngle) * dR;
        _droneOrbitPaint.color =
            const Color(0xFFFF3388).withValues(alpha: 0.85);
        canvas.save();
        canvas.translate(dx, dy);
        canvas.rotate(dAngle + math.pi / 2);
        final dronePath = Path()
          ..moveTo(0, -4)
          ..lineTo(3, 3)
          ..lineTo(-3, 3)
          ..close();
        canvas.drawPath(dronePath, _droneOrbitPaint);
        canvas.restore();
      }
    }

    // ─── CORONA a 5 spuntoni con jewel sulla punta ───
    if (scale <= 1.01) {
      _crownPaint.color = const Color(0xFFFFDD44).withValues(alpha: 0.85);
      for (int i = 0; i < 5; i++) {
        final cAng = -math.pi / 2 + (i - 2) * 0.35;
        final cDist = r * 0.85;
        final tipX = cx + math.cos(cAng) * cDist * 1.25;
        final tipY = cy + math.sin(cAng) * cDist * 1.25;
        final baseAL = cAng - 0.1;
        final baseAR = cAng + 0.1;
        final crownPath = Path()
          ..moveTo(tipX, tipY)
          ..lineTo(cx + math.cos(baseAL) * cDist,
              cy + math.sin(baseAL) * cDist)
          ..lineTo(cx + math.cos(baseAR) * cDist,
              cy + math.sin(baseAR) * cDist)
          ..close();
        canvas.drawPath(crownPath, _crownPaint);
        _crownJewelPaint.color = const Color(0xFFFFFFFF)
            .withValues(alpha: 0.7 + math.sin(_cellPhase * 4 + i) * 0.3);
        canvas.drawCircle(Offset(tipX, tipY), 2, _crownJewelPaint);
      }
    }

    // Esagono corpo principale
    canvas.save();
    canvas.translate(cx, cy);
    final hexPath = Path();
    for (int i = 0; i < 6; i++) {
      final angle = i * math.pi / 3 - math.pi / 6;
      final x = r * 0.7 * math.cos(angle);
      final y = r * 0.7 * math.sin(angle);
      if (i == 0) {
        hexPath.moveTo(x, y);
      } else {
        hexPath.lineTo(x, y);
      }
    }
    hexPath.close();
    canvas.drawPath(hexPath, paint);

    // Celle alveare (fill miele + bordo rosa)
    if (scale <= 1.01) {
      for (int i = 0; i < 7; i++) {
        final cAngle = i * math.pi / 3 + _cellPhase * 0.1;
        final cDist = i == 0 ? 0.0 : r * 0.35;
        final ccx = cDist * math.cos(cAngle);
        final ccy = cDist * math.sin(cAngle);
        final cellAlpha = 0.15 + math.sin(_cellPhase + i) * 0.1;
        final miniPath = Path();
        for (int j = 0; j < 6; j++) {
          final a = j * math.pi / 3;
          final mx = ccx + r * 0.12 * math.cos(a);
          final my = ccy + r * 0.12 * math.sin(a);
          if (j == 0) {
            miniPath.moveTo(mx, my);
          } else {
            miniPath.lineTo(mx, my);
          }
        }
        miniPath.close();
        _cellFillPaint.color =
            const Color(0xFFFFDD44).withValues(alpha: cellAlpha * 0.6);
        canvas.drawPath(miniPath, _cellFillPaint);
        _cellPaint.color = paint.color.withValues(alpha: cellAlpha);
        canvas.drawPath(miniPath, _cellPaint);
      }

      // Core halo + bianco pulsante
      final pulse = 0.5 + math.sin(_cellPhase * 2) * 0.4;
      _coreHaloPaint.color =
          const Color(0xFFFF88BB).withValues(alpha: pulse * 0.5);
      canvas.drawCircle(Offset.zero, r * 0.22, _coreHaloPaint);
      _corePaint.color =
          const Color(0xFFFFFFFF).withValues(alpha: pulse);
      canvas.drawCircle(Offset.zero, r * 0.14 * pulse, _corePaint);
    }
    canvas.restore();
  }
}

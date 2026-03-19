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
      _spawnTimer = 2.5 - currentPhase * 0.5;
      _spawnSwarm();
    }
  }

  void _spawnSwarm() {
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

  @override
  void renderBoss(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final r = size.x / 2 * scale;

    // Ali membranose (solo layer principale)
    if (scale <= 1.01) {
      final wingFlap = math.sin(_wingPhase) * 0.15;
      for (int side = -1; side <= 1; side += 2) {
        final wingPaint = Paint()
          ..color = neonColor.withValues(alpha: 0.15)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        final wingPath = Path()
          ..moveTo(cx + side * r * 0.4, cy)
          ..quadraticBezierTo(
            cx + side * r * 1.2, cy - r * 0.3 + wingFlap * 30,
            cx + side * r * 0.8, cy + r * 0.5,
          )
          ..lineTo(cx + side * r * 0.4, cy + r * 0.2)
          ..close();
        canvas.drawPath(wingPath, wingPaint);
      }
    }

    // Esagono corpo principale (alveare)
    canvas.save();
    canvas.translate(cx, cy);
    final hexPath = Path();
    for (int i = 0; i < 6; i++) {
      final angle = i * math.pi / 3 - math.pi / 6;
      final x = r * 0.7 * math.cos(angle);
      final y = r * 0.7 * math.sin(angle);
      if (i == 0) hexPath.moveTo(x, y); else hexPath.lineTo(x, y);
    }
    hexPath.close();
    canvas.drawPath(hexPath, paint);

    // Celle alveare interne
    if (scale <= 1.01) {
      for (int i = 0; i < 7; i++) {
        final cAngle = i * math.pi / 3 + _cellPhase * 0.1;
        final cDist = i == 0 ? 0.0 : r * 0.35;
        final ccx = cDist * math.cos(cAngle);
        final ccy = cDist * math.sin(cAngle);
        final cellAlpha = 0.15 + math.sin(_cellPhase + i) * 0.1;
        final cellPaint = Paint()
          ..color = paint.color.withValues(alpha: cellAlpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8;
        // Mini esagono
        final miniPath = Path();
        for (int j = 0; j < 6; j++) {
          final a = j * math.pi / 3;
          final mx = ccx + r * 0.12 * math.cos(a);
          final my = ccy + r * 0.12 * math.sin(a);
          if (j == 0) miniPath.moveTo(mx, my); else miniPath.lineTo(mx, my);
        }
        miniPath.close();
        canvas.drawPath(miniPath, cellPaint);
      }

      // Nucleo pulsante
      final pulse = 0.5 + math.sin(_cellPhase * 2) * 0.3;
      canvas.drawCircle(
        Offset.zero, r * 0.15,
        Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: pulse)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
    }
    canvas.restore();
  }
}

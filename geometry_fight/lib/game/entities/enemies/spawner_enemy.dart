import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../../data/constants.dart';
import '../../../data/wave_configs.dart';
import 'enemy_base.dart';

class SpawnerEnemy extends EnemyBase {
  double _spawnTimer = 3.0;

  SpawnerEnemy()
      : super(
          hp: 15,
          speed: 60,
          pointValue: 500,
          geomValue: 5,
          neonColor: NeonColors.orange,
          size: Vector2(30, 30),
        );

  @override
  void updateBehavior(double dt) {
    // Move slowly away from player (towards edges)
    final awayDir = (position - playerPosition);
    if (awayDir.length > 0) {
      awayDir.normalize();
      position += awayDir * speed * dt;
    }

    // Spawn drones periodically
    _spawnTimer -= dt;
    if (_spawnTimer <= 0) {
      _spawnTimer = 3.0;
      for (int i = 0; i < 2; i++) {
        final offset = Vector2(
          (math.Random().nextDouble() - 0.5) * 40,
          (math.Random().nextDouble() - 0.5) * 40,
        );
        game.spawnEnemy(EnemyType.drone, position + offset);
      }
    }
  }

  @override
  void renderShape(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final r = 14 * scale;

    // Esagono principale
    final path = Path();
    final vertices = <Offset>[];
    for (int i = 0; i < 6; i++) {
      final angle = i * math.pi / 3 - math.pi / 6;
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      vertices.add(Offset(x, y));
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);

    // Dettagli solo sul layer principale
    if (scale <= 1.01) {
      // Linee strutturali: collegano vertici opposti
      final linePaint = Paint()
        ..color = paint.color.withValues(alpha: 0.2)
        ..strokeWidth = 0.5;
      for (int i = 0; i < 3; i++) {
        canvas.drawLine(vertices[i], vertices[i + 3], linePaint);
      }

      // Indicatore spawn (cerchio che si riempie)
      final spawnProgress = 1.0 - (_spawnTimer / 3.0).clamp(0.0, 1.0);
      if (spawnProgress > 0.1) {
        final spawnPaint = Paint()
          ..color = NeonColors.orange.withValues(alpha: spawnProgress * 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawArc(
          Rect.fromCircle(center: Offset(cx, cy), radius: r * 1.2),
          -math.pi / 2, math.pi * 2 * spawnProgress, false, spawnPaint,
        );
      }

      // Punti energetici sui vertici
      for (int i = 0; i < 6; i++) {
        final dotAlpha = 0.3 + math.sin(idlePhase * 3 + i) * 0.2;
        final dotPaint = Paint()
          ..color = paint.color.withValues(alpha: dotAlpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
        canvas.drawCircle(vertices[i], 1.5, dotPaint);
      }
    }

    // Nucleo pulsante (più grande e luminoso)
    final corePulse = 5 + math.sin(idlePhase * 4) * 2;
    final coreGlow = Paint()
      ..color = NeonColors.orange.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawCircle(Offset(cx, cy), corePulse * 1.3, coreGlow);
    final corePaint = Paint()
      ..color = NeonColors.orange.withValues(alpha: 0.8);
    canvas.drawCircle(Offset(cx, cy), corePulse, corePaint);
  }
}

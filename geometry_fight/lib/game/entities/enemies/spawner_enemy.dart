import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../../data/constants.dart';
import '../../../data/wave_configs.dart';
import 'enemy_base.dart';

class SpawnerEnemy extends EnemyBase {
  double _spawnTimer = 3.0;

  // Rng + Paint caches condivisi (evita alloc per spawn + per frame).
  static final math.Random _rng = math.Random();
  static final Paint _linePaint = Paint()..strokeWidth = 0.5;
  static final Paint _spawnPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;

  SpawnerEnemy()
      : super(
          hp: 15,
          speed: 60,
          pointValue: 18,
          geomValue: 5,
          neonColor: NeonColors.orange,
          size: Vector2(30, 30),
        );

  @override
  void updateBehavior(double dt) {
    // Move slowly away from player (towards edges)
    final awayDir = position - playerPosition;
    if (awayDir.length2 > 1e-6) {
      awayDir.normalize();
      position += awayDir * speed * dt;
    }

    // Spawn drones periodically (solo se ci sono meno di 60 nemici attivi)
    _spawnTimer -= dt;
    if (_spawnTimer <= 0 && game.enemyCount < 60) {
      _spawnTimer = 3.0;
      for (int i = 0; i < 2; i++) {
        final offset = Vector2(
          (_rng.nextDouble() - 0.5) * 40,
          (_rng.nextDouble() - 0.5) * 40,
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
      _linePaint.color = paint.color.withValues(alpha: 0.2);
      for (int i = 0; i < 3; i++) {
        canvas.drawLine(vertices[i], vertices[i + 3], _linePaint);
      }

      // Indicatore spawn (cerchio che si riempie)
      final spawnProgress = 1.0 - (_spawnTimer / 3.0).clamp(0.0, 1.0);
      if (spawnProgress > 0.1) {
        _spawnPaint.color = NeonColors.orange.withValues(alpha: spawnProgress * 0.4);
        canvas.drawArc(
          Rect.fromCircle(center: Offset(cx, cy), radius: r * 1.2),
          -math.pi / 2, math.pi * 2 * spawnProgress, false, _spawnPaint,
        );
      }

      // Punti energetici sui vertici — senza blur
      for (int i = 0; i < 6; i++) {
        final dotAlpha = 0.3 + math.sin(idlePhase * 3 + i) * 0.2;
        EnemyBase.detailPaint.color = paint.color.withValues(alpha: dotAlpha);
        canvas.drawCircle(vertices[i], 1.5, EnemyBase.detailPaint);
      }
    }

    // Nucleo pulsante — senza blur
    final corePulse = 5 + math.sin(idlePhase * 4) * 2;
    EnemyBase.detailPaint.color = NeonColors.orange.withValues(alpha: 0.15);
    canvas.drawCircle(Offset(cx, cy), corePulse * 1.8, EnemyBase.detailPaint);
    EnemyBase.detailPaint.color = NeonColors.orange.withValues(alpha: 0.8);
    canvas.drawCircle(Offset(cx, cy), corePulse, EnemyBase.detailPaint);
  }
}

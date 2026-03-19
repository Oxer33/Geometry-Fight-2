import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import 'enemy_base.dart';

/// SIREN - Nemico che emette onde soniche che rallentano i proiettili del player.
/// Forma: pentagono con onde concentriche che si espandono
/// Colore: viola chiaro (#BB66FF)
/// Meccanica unica: crea un campo di interferenza che rallenta i proiettili del 50%
/// I proiettili nel suo raggio diventano più lenti e fanno meno danno.
class SirenEnemy extends EnemyBase {
  double _wavePhase = 0;
  static const double _interferenceRadius = 150.0;

  SirenEnemy()
      : super(
          hp: 5,
          speed: 80,
          pointValue: 400,
          geomValue: 4,
          neonColor: const Color(0xFFBB66FF),
          size: Vector2(22, 22),
        );

  @override
  void updateBehavior(double dt) {
    _wavePhase += dt * 3;

    // Movimento lento verso il player
    final velocity = seekPlayer(speed);
    position += velocity * dt;

    // Rallenta i proiettili del player nel raggio
    for (final child in game.world.children.toList()) {
      if (child is PositionComponent && child.runtimeType.toString().contains('PlayerBullet')) {
        final dist = child.position.distanceTo(position);
        if (dist < _interferenceRadius) {
          // Rallenta il proiettile spingendolo leggermente indietro
          final pushDir = (child.position - position).normalized();
          child.position -= pushDir * 100 * dt; // Controvento
        }
      }
    }
  }

  @override
  void renderShape(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final r = size.x / 2 * scale;

    // Onde concentriche di interferenza (solo layer principale)
    if (scale <= 1.01) {
      for (int i = 0; i < 3; i++) {
        final waveR = ((_wavePhase + i * 1.5) % 4) / 4 * _interferenceRadius * 0.5;
        final waveAlpha = (1 - waveR / (_interferenceRadius * 0.5)) * 0.2;
        if (waveAlpha > 0) {
          final wavePaint = Paint()
            ..color = neonColor.withValues(alpha: waveAlpha)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1;
          canvas.drawCircle(Offset(cx, cy), waveR + r, wavePaint);
        }
      }
    }

    // Pentagono
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(idlePhase * 0.5);
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final angle = i * math.pi * 2 / 5 - math.pi / 2;
      final x = r * math.cos(angle);
      final y = r * math.sin(angle);
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paint);

    // Dettagli interni
    if (scale <= 1.01) {
      // Anelli interni
      final innerPaint = Paint()
        ..color = paint.color.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5;
      canvas.drawCircle(Offset.zero, r * 0.5, innerPaint);
      canvas.drawCircle(Offset.zero, r * 0.3, innerPaint);

      // Nucleo pulsante
      final pulse = 0.5 + math.sin(_wavePhase * 2) * 0.3;
      final corePaint = Paint()
        ..color = const Color(0xFFFFFFFF).withValues(alpha: pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(Offset.zero, r * 0.2, corePaint);
    }
    canvas.restore();
  }
}

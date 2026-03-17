import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../../data/constants.dart';
import 'enemy_base.dart';

/// TESLA - Nemico che crea archi elettrici tra sé e altri nemici vicini.
/// Forma: ottagono con scariche elettriche
/// Colore: giallo elettrico (#FFEE44)
/// Meccanica unica: crea connessioni elettriche con nemici vicini (150px).
/// Se il player tocca un arco elettrico, subisce danno.
/// Più Tesla sono vicini, più archi pericolosi creano.
class TeslaEnemy extends EnemyBase {
  double _sparkPhase = 0;
  final List<Vector2> _connectedPositions = [];

  TeslaEnemy()
      : super(
          hp: 3,
          speed: 110,
          pointValue: 350,
          geomValue: 4,
          neonColor: const Color(0xFFFFEE44),
          size: Vector2(20, 20),
        );

  @override
  void updateBehavior(double dt) {
    _sparkPhase += dt * 12;

    // Movimento verso il player
    final velocity = seekPlayer(speed);
    position += velocity * dt;

    // Trova nemici vicini per creare archi
    _connectedPositions.clear();
    for (final child in game.world.children) {
      if (child is EnemyBase && child != this) {
        final dist = child.position.distanceTo(position);
        if (dist < 150 && _connectedPositions.length < 3) {
          _connectedPositions.add(child.position.clone());

          // Se il player è vicino all'arco, danno!
          final playerDist = _distanceToLine(
            game.player.position, position, child.position,
          );
          if (playerDist < 15) {
            game.player.takeDamage();
          }
        }
      }
    }
  }

  /// Distanza punto-segmento per check collisione arco
  double _distanceToLine(Vector2 point, Vector2 lineStart, Vector2 lineEnd) {
    final line = lineEnd - lineStart;
    final len = line.length;
    if (len == 0) return point.distanceTo(lineStart);
    final t = ((point - lineStart).dot(line) / (len * len)).clamp(0.0, 1.0);
    final projection = lineStart + line * t;
    return point.distanceTo(projection);
  }

  @override
  void renderShape(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final r = size.x / 2 * scale;

    // Archi elettrici verso nemici connessi (solo layer principale)
    if (scale <= 1.01) {
      for (final connPos in _connectedPositions) {
        final offset = connPos - position;
        _drawLightning(canvas, cx, cy, cx + offset.x, cy + offset.y);
      }
    }

    // Ottagono
    canvas.save();
    canvas.translate(cx, cy);
    final path = Path();
    for (int i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      final x = r * math.cos(angle);
      final y = r * math.sin(angle);
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paint);

    // Dettagli interni
    if (scale <= 1.01) {
      // Nucleo elettrico pulsante
      final spark = 0.4 + math.sin(_sparkPhase) * 0.4;
      final sparkPaint = Paint()
        ..color = const Color(0xFFFFFFFF).withValues(alpha: spark)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(Offset.zero, r * 0.3, sparkPaint);

      // Mini scariche dal centro ai vertici
      for (int i = 0; i < 4; i++) {
        final angle = i * math.pi / 2 + _sparkPhase * 0.3;
        final lp = Paint()
          ..color = paint.color.withValues(alpha: 0.3)
          ..strokeWidth = 0.5;
        canvas.drawLine(
          Offset.zero,
          Offset(r * 0.6 * math.cos(angle), r * 0.6 * math.sin(angle)),
          lp,
        );
      }
    }
    canvas.restore();
  }

  /// Disegna un arco elettrico tra due punti
  void _drawLightning(Canvas canvas, double x1, double y1, double x2, double y2) {
    final random = math.Random((_sparkPhase * 10).toInt());
    final dx = x2 - x1;
    final dy = y2 - y1;
    final steps = 6;

    final lightningPaint = Paint()
      ..color = neonColor.withValues(alpha: 0.6)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final glowPaint = Paint()
      ..color = neonColor.withValues(alpha: 0.2)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    final path = Path()..moveTo(x1, y1);
    for (int i = 1; i < steps; i++) {
      final t = i / steps;
      final mx = x1 + dx * t + (random.nextDouble() - 0.5) * 15;
      final my = y1 + dy * t + (random.nextDouble() - 0.5) * 15;
      path.lineTo(mx, my);
    }
    path.lineTo(x2, y2);

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, lightningPaint);
  }
}

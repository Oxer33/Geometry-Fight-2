import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import 'enemy_base.dart';

/// TESLA - Nemico che crea archi elettrici tra sé e altri nemici vicini.
/// Movimento: PACK FLANKING - cerca di posizionarsi sul lato opposto del player
/// rispetto ad altri Tesla, formando un triangolo/rete attorno al player.
/// Se solo, circla il player a distanza media.
class TeslaEnemy extends EnemyBase {
  double _sparkPhase = 0;
  final List<Vector2> _connectedPositions = [];
  double _flankAngle;
  static const double _orbitDistance = 130.0;
  static const double _soloOrbitSpeed = 1.5; // rad/s quando solo

  TeslaEnemy()
      : _flankAngle = math.Random().nextDouble() * math.pi * 2,
        super(
          hp: 3,
          speed: 110,
          pointValue: 12,
          geomValue: 4,
          neonColor: const Color(0xFFFFEE44),
          size: Vector2(20, 20),
        );

  @override
  void updateBehavior(double dt) {
    _sparkPhase += dt * 12;

    // Trova altri Tesla per comportamento a branco
    final otherTeslas = <TeslaEnemy>[];
    for (final child in game.world.children) {
      if (child is TeslaEnemy && child != this) {
        otherTeslas.add(child);
      }
    }

    if (otherTeslas.isEmpty) {
      // SOLO: orbita attorno al player
      _flankAngle += _soloOrbitSpeed * dt;
      final targetPos = playerPosition +
          Vector2(math.cos(_flankAngle), math.sin(_flankAngle)) *
              _orbitDistance;
      final toTarget = targetPos - position;
      if (toTarget.length > 5) {
        position += toTarget.normalized() * speed * dt;
      }
    } else {
      // PACK: posizionati sul lato opposto del player rispetto agli altri Tesla
      double avgAngle = 0;
      int myIndex = 0;
      int teslaIndex = 0;
      for (final other in otherTeslas) {
        final diff = other.position - playerPosition;
        avgAngle += math.atan2(diff.y, diff.x);
        if (other.hashCode < hashCode) myIndex = teslaIndex + 1;
        teslaIndex++;
      }
      avgAngle /= otherTeslas.length;

      final spreadAngle = math.pi / (otherTeslas.length + 1);
      final targetAngle =
          avgAngle + math.pi + (myIndex - otherTeslas.length / 2) * spreadAngle;

      final targetPos = playerPosition +
          Vector2(math.cos(targetAngle), math.sin(targetAngle)) *
              _orbitDistance;
      final toTarget = targetPos - position;
      if (toTarget.length > 5) {
        position += toTarget.normalized() * speed * dt;
      }
    }

    // Trova nemici vicini per creare archi
    _connectedPositions.clear();
    for (final child in game.world.children) {
      if (child is EnemyBase && child != this) {
        final dist = child.position.distanceTo(position);
        if (dist < 150 && _connectedPositions.length < 3) {
          _connectedPositions.add(child.position.clone());

          // Se il player è vicino all'arco, danno!
          final playerDist = _distanceToLine(
            game.player.position,
            position,
            child.position,
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
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);

    // Dettagli interni
    if (scale <= 1.01) {
      // Nucleo elettrico pulsante (no blur per performance)
      final spark = 0.4 + math.sin(_sparkPhase) * 0.4;
      EnemyBase.detailPaint.color = const Color(0xFFFFFFFF).withValues(alpha: spark);
      canvas.drawCircle(Offset.zero, r * 0.3, EnemyBase.detailPaint);

      // Mini scariche dal centro ai vertici
      EnemyBase.detailPaint.color = paint.color.withValues(alpha: 0.3);
      EnemyBase.detailPaint.strokeWidth = 0.5;
      EnemyBase.detailPaint.style = PaintingStyle.stroke;
      for (int i = 0; i < 4; i++) {
        final angle = i * math.pi / 2 + _sparkPhase * 0.3;
        canvas.drawLine(
          Offset.zero,
          Offset(r * 0.6 * math.cos(angle), r * 0.6 * math.sin(angle)),
          EnemyBase.detailPaint,
        );
      }
      EnemyBase.detailPaint.style = PaintingStyle.fill;
    }
    canvas.restore();
  }

  static final _lightningPaint = Paint()
    ..strokeWidth = 1.5
    ..style = PaintingStyle.stroke;
  static final _lightningGlowPaint = Paint()
    ..strokeWidth = 3
    ..style = PaintingStyle.stroke;

  /// Disegna un arco elettrico tra due punti
  void _drawLightning(
      Canvas canvas, double x1, double y1, double x2, double y2) {
    final random = math.Random((_sparkPhase * 10).toInt());
    final dx = x2 - x1;
    final dy = y2 - y1;
    const steps = 6;

    _lightningPaint.color = neonColor.withValues(alpha: 0.6);
    _lightningGlowPaint.color = neonColor.withValues(alpha: 0.2);

    final path = Path()..moveTo(x1, y1);
    for (int i = 1; i < steps; i++) {
      final t = i / steps;
      final mx = x1 + dx * t + (random.nextDouble() - 0.5) * 15;
      final my = y1 + dy * t + (random.nextDouble() - 0.5) * 15;
      path.lineTo(mx, my);
    }
    path.lineTo(x2, y2);

    canvas.drawPath(path, _lightningGlowPaint);
    canvas.drawPath(path, _lightningPaint);
  }
}

import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../../data/constants.dart';
import 'enemy_base.dart';

/// SWARM DRONE - Piccolo e debole ma spawna in gruppi enormi.
/// Si muovono in formazione e cambiano pattern collettivamente.
/// Forma: triangolino minuscolo con scia
/// Colore: rosa caldo (#FF3388)
/// Meccanica: si muovono in formazione a V verso il player,
/// se uno viene ucciso gli altri accelerano per 1s ("furia").
class SwarmDroneEnemy extends EnemyBase {
  double _formationOffset = 0;
  bool _enraged = false;
  double _enrageTimer = 0;

  SwarmDroneEnemy()
      : super(
          hp: 1,
          speed: 200,
          pointValue: 20,
          geomValue: 1,
          neonColor: const Color(0xFFFF3388),
          size: Vector2(10, 10),
        ) {
    _formationOffset = math.Random().nextDouble() * math.pi * 2;
  }

  @override
  void updateBehavior(double dt) {
    if (_enrageTimer > 0) {
      _enrageTimer -= dt;
      if (_enrageTimer <= 0) _enraged = false;
    }

    final currentSpeed = _enraged ? speed * 1.8 : speed;
    final baseDir = seekPlayer(currentSpeed);

    // Movimento con leggera oscillazione laterale (formazione)
    final sideOffset = math.sin(idlePhase * 3 + _formationOffset) * 40;
    final perpDir = Vector2(-baseDir.y, baseDir.x);
    if (perpDir.length > 0) perpDir.normalize();

    position += (baseDir + perpDir * sideOffset * dt) * dt;
  }

  @override
  void onDeath() {
    // Enrage nemici SwarmDrone vicini
    for (final child in game.world.children) {
      if (child is SwarmDroneEnemy && child != this) {
        final dist = child.position.distanceTo(position);
        if (dist < 200) {
          child._enraged = true;
          child._enrageTimer = 1.5;
        }
      }
    }
    super.onDeath();
  }

  @override
  void renderShape(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final s = size.x / 2 * scale;

    // Triangolino piccolo
    canvas.save();
    canvas.translate(cx, cy);
    final angle = math.atan2(
      playerPosition.y - position.y,
      playerPosition.x - position.x,
    ) + math.pi / 2;
    canvas.rotate(angle);

    final color = _enraged
        ? const Color(0xFFFF0000)
        : paint.color;
    final p = Paint()..color = color;

    final path = Path()
      ..moveTo(0, -s)
      ..lineTo(s * 0.7, s * 0.5)
      ..lineTo(-s * 0.7, s * 0.5)
      ..close();
    canvas.drawPath(path, p);

    // Nucleo quando enraged
    if (_enraged && scale <= 1.01) {
      final ragePaint = Paint()
        ..color = const Color(0xFFFF4400).withValues(alpha: 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(Offset.zero, s * 0.4, ragePaint);
    }

    canvas.restore();
  }
}

import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
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
          pointValue: 1,
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

    final currentSpeed = (_enraged || isGloballyEnraged) ? speed * 1.8 : speed;
    final baseDir = seekPlayer(currentSpeed);

    // Movimento con leggera oscillazione laterale (formazione)
    final sideOffset = math.sin(idlePhase * 3 + _formationOffset) * 40;
    final perpDir = Vector2(-baseDir.y, baseDir.x);
    if (perpDir.length > 0) perpDir.normalize();

    position += (baseDir + perpDir * sideOffset * dt) * dt;
  }

  @override
  void onDeath() {
    // Enrage: tutti gli SwarmDrone si enragiano globalmente per 1.5s
    // (evita iterazione O(n²) che causa lag con 100+ nemici)
    _globalEnrageTimer = 1.5;
    super.onDeath();
  }

  // Timer globale condiviso: quando uno muore, tutti si enragiano
  static double _globalEnrageTimer = 0;
  static void updateGlobalEnrage(double dt) {
    if (_globalEnrageTimer > 0) _globalEnrageTimer -= dt;
  }
  bool get isGloballyEnraged => _globalEnrageTimer > 0;

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

    final color = (_enraged || isGloballyEnraged)
        ? const Color(0xFFFF0000)
        : paint.color;
    final p = Paint()..color = color;

    final path = Path()
      ..moveTo(0, -s)
      ..lineTo(s * 0.7, s * 0.5)
      ..lineTo(-s * 0.7, s * 0.5)
      ..close();
    canvas.drawPath(path, p);

    // Nucleo quando enraged (senza blur per performance)
    if ((_enraged || isGloballyEnraged) && scale <= 1.01) {
      final ragePaint = Paint()
        ..color = const Color(0xFFFF4400).withValues(alpha: 0.6);
      canvas.drawCircle(Offset.zero, s * 0.4, ragePaint);
    }

    canvas.restore();
  }
}

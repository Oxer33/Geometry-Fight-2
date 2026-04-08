import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../../data/constants.dart';
import '../projectiles.dart';
import 'enemy_base.dart';

/// WEAVER (Green Scare) - Quadrato verde che insegue il player.
/// Come in GW: homing + SCHIVA i proiettili che si avvicinano.
/// Leggermente più veloce del player. 85% probabilità di schivare.
class WeaverEnemy extends EnemyBase {
  double _dodgeCooldown = 0;
  static final _rng = math.Random();
  final double _waveOffset = _rng.nextDouble() * math.pi * 2;

  WeaverEnemy()
      : super(
          hp: 1,
          speed: 220, // Leggermente più veloce del player (200)
          pointValue: 4,
          geomValue: 2,
          neonColor: NeonColors.green, // Verde come GW
          size: Vector2(16, 16),
        );

  @override
  void updateBehavior(double dt) {
    if (_dodgeCooldown > 0) _dodgeCooldown -= dt;

    // Homing verso il player
    final toPlayer = seekPlayer(speed);

    // SCHIVA proiettili vicini (85% probabilità, come GW)
    if (_dodgeCooldown <= 0) {
      for (final child in game.world.children.toList()) {
        if (child is PlayerBullet) {
          final dist = child.position.distanceTo(position);
          if (dist < 80) {
            // 85% probabilità di schivare
            if (_rng.nextDouble() < 0.85) {
              final bulletDir = (child.position - position).normalized();
              final sign = _rng.nextBool() ? 1.0 : -1.0;
              final dodgeDir = Vector2(-bulletDir.y * sign, bulletDir.x * sign);
              position += dodgeDir * 150 * dt;
              _dodgeCooldown = 0.3;
            }
            break;
          }
        }
      }
    }

    position += toPlayer * dt;
  }

  @override
  void renderShape(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final w = 6 * scale;
    final h = 12 * scale;

    // Rombo allungato (corpo principale)
    final path = Path()
      ..moveTo(cx, cy - h)
      ..lineTo(cx + w, cy)
      ..lineTo(cx, cy + h)
      ..lineTo(cx - w, cy)
      ..close();
    canvas.drawPath(path, paint);

    if (scale <= 1.01) {
      // Rombo interno (scafo)
      final innerPath = Path()
        ..moveTo(cx, cy - h * 0.55)
        ..lineTo(cx + w * 0.55, cy)
        ..lineTo(cx, cy + h * 0.55)
        ..lineTo(cx - w * 0.55, cy)
        ..close();
      final innerPaint = Paint()
        ..color = paint.color.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6;
      canvas.drawPath(innerPath, innerPaint);

      // Pannelli ala (linee diagonali strutturali)
      final linePaint = Paint()
        ..color = paint.color.withValues(alpha: 0.2)
        ..strokeWidth = 0.5;
      // Ala superiore dx/sx
      canvas.drawLine(Offset(cx + w * 0.2, cy - h * 0.4), Offset(cx + w * 0.8, cy - h * 0.05), linePaint);
      canvas.drawLine(Offset(cx - w * 0.2, cy - h * 0.4), Offset(cx - w * 0.8, cy - h * 0.05), linePaint);
      // Ala inferiore dx/sx
      canvas.drawLine(Offset(cx + w * 0.2, cy + h * 0.4), Offset(cx + w * 0.8, cy + h * 0.05), linePaint);
      canvas.drawLine(Offset(cx - w * 0.2, cy + h * 0.4), Offset(cx - w * 0.8, cy + h * 0.05), linePaint);

      // Flusso energetico: linea centrale pulsante
      final flowProgress = (idlePhase * 2 + _waveOffset) % 1.0;
      final flowY = cy - h * 0.6 + flowProgress * h * 1.2;
      final flowAlpha = 0.4 * (1 - (flowProgress - 0.5).abs() * 2);
      if (flowAlpha > 0) {
        EnemyBase.detailPaint.color = const Color(0xFFFFFFFF).withValues(alpha: flowAlpha);
        canvas.drawCircle(Offset(cx, flowY), 1.0, EnemyBase.detailPaint);
      }

      // Nodi energetici sulle 4 punte
      for (int i = 0; i < 4; i++) {
        final dotAlpha = 0.3 + math.sin(idlePhase * 4 + i * 1.5) * 0.3;
        EnemyBase.detailPaint.color = paint.color.withValues(alpha: dotAlpha);
        final dx = [0.0, w * 0.85, 0.0, -w * 0.85][i];
        final dy = [-h * 0.85, 0.0, h * 0.85, 0.0][i];
        canvas.drawCircle(Offset(cx + dx, cy + dy), 1.0, EnemyBase.detailPaint);
      }

      // Nucleo pulsante al centro
      final pulse = 0.5 + math.sin(idlePhase * 5 + _waveOffset) * 0.3;
      EnemyBase.detailPaint.color = const Color(0xFFFFFFFF).withValues(alpha: pulse);
      canvas.drawCircle(Offset(cx, cy), w * 0.2, EnemyBase.detailPaint);
    }
  }
}

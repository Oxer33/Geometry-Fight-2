import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../../data/constants.dart';
import '../projectiles.dart';
import 'enemy_base.dart';

/// WEAVER (Green Scare) - Quadrato verde che insegue il player.
/// Come in GW: homing + SCHIVA i proiettili che si avvicinano.
/// Molto aggressivo nella schivata: reazione rapida, raggio ampio.
class WeaverEnemy extends EnemyBase {
  double _dodgeCooldown = 0;
  static final _rng = math.Random();
  final double _waveOffset = _rng.nextDouble() * math.pi * 2;
  // Direzione dodge corrente per smoothing
  Vector2? _currentDodge;
  double _dodgeMomentum = 0;

  WeaverEnemy()
      : super(
          hp: 1,
          speed: 250, // Più veloce del player (200) — aggressivo
          pointValue: 4,
          geomValue: 2,
          neonColor: NeonColors.green,
          size: Vector2(16, 16),
        );

  @override
  bool get canFearDodge => true;

  @override
  void updateBehavior(double dt) {
    if (_dodgeCooldown > 0) _dodgeCooldown -= dt;
    if (_dodgeMomentum > 0) _dodgeMomentum -= dt;

    // Homing verso il player
    final toPlayer = seekPlayer(speed);

    // Se ha momentum dalla schivata precedente, continua
    if (_dodgeMomentum > 0 && _currentDodge != null) {
      position += _currentDodge! * 350 * dt;
    }

    // SCHIVA proiettili — raggio ampio (140px), reazione rapida
    if (_dodgeCooldown <= 0) {
      PlayerBullet? closestBullet;
      double closestDist = 140; // Raggio di rilevamento ampio

      for (final child in game.world.children) {
        if (child is PlayerBullet) {
          final dist = child.position.distanceTo(position);
          if (dist < closestDist) {
            closestDist = dist;
            closestBullet = child;
          }
        }
      }

      if (closestBullet != null) {
        // 90% probabilità di schivare (più alta del base 85%)
        if (_rng.nextDouble() < 0.90) {
          // Direzione di schivata: perpendicolare alla direzione del proiettile
          final bulletToMe = (position - closestBullet.position).normalized();
          final bulletDir = closestBullet.direction.normalized();

          // Scegli il lato che allontana di più dal proiettile
          final side1 = Vector2(-bulletDir.y, bulletDir.x);
          final side2 = Vector2(bulletDir.y, -bulletDir.x);
          final dodgeDir = (side1.dot(bulletToMe) > side2.dot(bulletToMe)) ? side1 : side2;

          // Schivata forte e veloce — scala con vicinanza
          final urgency = 1.0 - (closestDist / 140);
          final dodgeSpeed = 300 + urgency * 200; // 300-500 px/s
          position += dodgeDir * dodgeSpeed * dt;

          // Mantieni momentum per smoothing
          _currentDodge = dodgeDir;
          _dodgeMomentum = 0.08; // Continua per 80ms

          _dodgeCooldown = 0.12; // Può ri-schivare molto velocemente (120ms)
        } else {
          _dodgeCooldown = 0.2;
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

      // Pannelli ala
      final linePaint = Paint()
        ..color = paint.color.withValues(alpha: 0.2)
        ..strokeWidth = 0.5;
      canvas.drawLine(Offset(cx + w * 0.2, cy - h * 0.4), Offset(cx + w * 0.8, cy - h * 0.05), linePaint);
      canvas.drawLine(Offset(cx - w * 0.2, cy - h * 0.4), Offset(cx - w * 0.8, cy - h * 0.05), linePaint);
      canvas.drawLine(Offset(cx + w * 0.2, cy + h * 0.4), Offset(cx + w * 0.8, cy + h * 0.05), linePaint);
      canvas.drawLine(Offset(cx - w * 0.2, cy + h * 0.4), Offset(cx - w * 0.8, cy + h * 0.05), linePaint);

      // Flusso energetico
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

      // Nucleo pulsante
      final pulse = 0.5 + math.sin(idlePhase * 5 + _waveOffset) * 0.3;
      EnemyBase.detailPaint.color = const Color(0xFFFFFFFF).withValues(alpha: pulse);
      canvas.drawCircle(Offset(cx, cy), w * 0.2, EnemyBase.detailPaint);
    }
  }
}

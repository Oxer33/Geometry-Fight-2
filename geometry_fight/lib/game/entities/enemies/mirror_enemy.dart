import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../../data/constants.dart';
import 'enemy_base.dart';
import '../projectiles.dart';

/// MIRROR - Riflette i proiettili del player.
/// Movimento: STRAFING a distanza media (120-180px dal player).
/// Vuole stare nella linea di fuoco per massimizzare le riflessioni.
/// Orbita attorno al player mantenendo la distanza ideale.
class MirrorEnemy extends EnemyBase {
  double _reflectCooldown = 0;
  double _shieldFlash = 0;
  double _orbitAngle;
  static const double _idealDistance = 150.0;
  static const double _orbitSpeed = 1.8; // rad/s

  MirrorEnemy()
      : _orbitAngle = math.Random().nextDouble() * math.pi * 2,
        super(
          hp: 5,
          speed: 90,
          pointValue: 10,
          geomValue: 4,
          neonColor: NeonColors.magenta,
          size: Vector2(26, 26),
        );

  @override
  void updateBehavior(double dt) {
    if (_reflectCooldown > 0) _reflectCooldown -= dt;
    if (_shieldFlash > 0) _shieldFlash -= dt;

    // Strafing: orbita attorno al player a distanza ideale
    _orbitAngle += _orbitSpeed * dt;

    if (distanceToPlayer > 0) {
      // Posizione target: punto sull'orbita attorno al player
      final targetPos = playerPosition +
          Vector2(math.cos(_orbitAngle), math.sin(_orbitAngle)) *
              _idealDistance;

      final toTarget = targetPos - position;
      if (toTarget.length > 5) {
        position += toTarget.normalized() * speed * dt;
      }
    }

    // Check for nearby player bullets and reflect them
    if (_reflectCooldown <= 0) {
      for (final child in game.world.children.whereType<PlayerBullet>()) {
        final bulletDist = child.position.distanceTo(position);
        if (bulletDist < 30) {
          // Reflect: remove player bullet, spawn enemy bullet going back
          final reflectDir = (child.position - position).normalized();
          final reflected = EnemyBullet(
            direction: reflectDir,
            speed: 400,
            color: NeonColors.magenta,
          );
          reflected.position = child.position.clone();
          game.world.add(reflected);
          child.removeFromParent();
          _reflectCooldown = 0.3;
          _shieldFlash = 0.2;
          break;
        }
      }
    }
  }

  @override
  void renderShape(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final r = 12 * scale;

    // Ottagono con rotazione lenta
    final path = Path();
    final verts = <Offset>[];
    for (int i = 0; i < 8; i++) {
      final angle = i * math.pi / 4 + idlePhase * 0.5;
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      verts.add(Offset(x, y));
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);

    if (scale <= 1.01) {
      // Facce riflettenti (shimmer sulle facce dell'ottagono)
      for (int i = 0; i < 8; i++) {
        final next = (i + 1) % 8;
        final shimmer = 0.15 + math.sin(idlePhase * 4 + i * 0.9) * 0.15;
        final facePaint = Paint()
          ..color = const Color(0xFFFFFFFF).withValues(alpha: shimmer)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;
        canvas.drawLine(verts[i], verts[next], facePaint);
      }

      // Linee interne diagonali (struttura prismatica)
      final diagPaint = Paint()
        ..color = paint.color.withValues(alpha: 0.15)
        ..strokeWidth = 0.5;
      for (int i = 0; i < 4; i++) {
        canvas.drawLine(verts[i], verts[i + 4], diagPaint);
      }

      // Nucleo specchiato (riflette la luce)
      final coreShimmer = 0.3 + math.sin(idlePhase * 6) * 0.3;
      final corePaint = Paint()
        ..color = const Color(0xFFFFFFFF).withValues(alpha: coreShimmer)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(Offset(cx, cy), r * 0.25, corePaint);

      // Indicatore cooldown riflesso
      if (_reflectCooldown > 0) {
        final cooldownProgress = (_reflectCooldown / 0.3).clamp(0.0, 1.0);
        final cdPaint = Paint()
          ..color = NeonColors.magenta.withValues(alpha: cooldownProgress * 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;
        canvas.drawCircle(Offset(cx, cy), r * 1.1, cdPaint);
      }
    }

    // Flash prismatico quando riflette
    if (_shieldFlash > 0) {
      // Flash bianco centrale
      final flashPaint = Paint()
        ..color = NeonColors.white.withValues(alpha: _shieldFlash * 3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawCircle(Offset(cx, cy), r * 1.3, flashPaint);
      // Effetto prismatico (arcobaleno)
      final prismPaint = Paint()
        ..color = NeonColors.cyan.withValues(alpha: _shieldFlash * 1.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(Offset(cx + 2, cy), r * 1.2, prismPaint);
      prismPaint.color =
          NeonColors.spreadOrange.withValues(alpha: _shieldFlash * 1.5);
      canvas.drawCircle(Offset(cx - 2, cy), r * 1.2, prismPaint);
    }
  }
}

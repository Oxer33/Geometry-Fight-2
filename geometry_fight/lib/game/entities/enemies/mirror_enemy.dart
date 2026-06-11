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

  // Paint cache: evita alloc per frame × N mirror enemies.
  static final Paint _facePaint = Paint()
    ..strokeWidth = 1.5
    ..style = PaintingStyle.stroke;
  static final Paint _diagPaint = Paint()..strokeWidth = 0.5;
  static final Paint _cdPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  // Static RNG shared across all MirrorEnemy instances — avoids per-instance alloc.
  static final math.Random _rng = math.Random();

  MirrorEnemy()
    : _orbitAngle = _rng.nextDouble() * math.pi * 2,
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
      final targetPos =
          playerPosition +
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
          // Reflect: remove player bullet, spawn enemy bullet going back.
          // NaN guard: bullet coincide col mirror → fallback verso sud.
          final delta = child.position - position;
          final reflectDir = delta.length < 0.001
              ? Vector2(0, 1)
              : delta.normalized();
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
        _facePaint.color = const Color(0xFFFFFFFF).withValues(alpha: shimmer);
        canvas.drawLine(verts[i], verts[next], _facePaint);
      }

      // Linee interne diagonali (struttura prismatica)
      _diagPaint.color = paint.color.withValues(alpha: 0.15);
      for (int i = 0; i < 4; i++) {
        canvas.drawLine(verts[i], verts[i + 4], _diagPaint);
      }

      // Nucleo specchiato (riflette la luce)
      final coreShimmer = 0.3 + math.sin(idlePhase * 6) * 0.3;
      EnemyBase.detailPaint.color = const Color(
        0xFFFFFFFF,
      ).withValues(alpha: coreShimmer * 0.5);
      canvas.drawCircle(Offset(cx, cy), r * 0.35, EnemyBase.detailPaint);
      EnemyBase.detailPaint.color = const Color(
        0xFFFFFFFF,
      ).withValues(alpha: coreShimmer);
      canvas.drawCircle(Offset(cx, cy), r * 0.25, EnemyBase.detailPaint);

      // Indicatore cooldown riflesso
      if (_reflectCooldown > 0) {
        final cooldownProgress = (_reflectCooldown / 0.3).clamp(0.0, 1.0);
        _cdPaint.color = NeonColors.magenta.withValues(
          alpha: cooldownProgress * 0.3,
        );
        canvas.drawCircle(Offset(cx, cy), r * 1.1, _cdPaint);
      }
    }

    // Flash prismatico quando riflette — senza blur
    if (_shieldFlash > 0) {
      // Flash bianco — cerchio grande, no blur
      EnemyBase.detailPaint.color = NeonColors.white.withValues(
        alpha: _shieldFlash * 1.5,
      );
      EnemyBase.detailPaint.style = PaintingStyle.fill;
      canvas.drawCircle(Offset(cx, cy), r * 1.8, EnemyBase.detailPaint);
      EnemyBase.detailPaint.color = NeonColors.white.withValues(
        alpha: _shieldFlash * 3,
      );
      canvas.drawCircle(Offset(cx, cy), r * 1.3, EnemyBase.detailPaint);
      // Prisma
      EnemyBase.detailPaint.color = NeonColors.cyan.withValues(
        alpha: _shieldFlash * 1.5,
      );
      EnemyBase.detailPaint.style = PaintingStyle.stroke;
      EnemyBase.detailPaint.strokeWidth = 1;
      canvas.drawCircle(Offset(cx + 2, cy), r * 1.2, EnemyBase.detailPaint);
      EnemyBase.detailPaint.color = NeonColors.spreadOrange.withValues(
        alpha: _shieldFlash * 1.5,
      );
      canvas.drawCircle(Offset(cx - 2, cy), r * 1.2, EnemyBase.detailPaint);
    }
  }
}

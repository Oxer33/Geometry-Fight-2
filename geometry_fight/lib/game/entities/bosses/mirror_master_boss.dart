import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../game_world.dart';
import 'boss_base.dart';

/// MIRROR MASTER - Boss che riflette i proiettili del player contro di lui.
/// Forma: ottagono con specchi rotanti sulle facce
/// Colore: argento (#CCDDEE)
/// HP: 1400 · 3 fasi
/// Meccanica: ha facce riflettenti che rimbalzano i proiettili.
/// Solo i colpi da dietro o area danneggiano. Crea cloni-specchio.
class MirrorMasterBoss extends BossBase {
  double _mirrorAngle = 0;
  double _attackTimer = 2.5;

  MirrorMasterBoss()
      : super(
          hp: 1400,
          bossName: 'MIRROR MASTER',
          pointValue: 2800,
          neonColor: const Color(0xFFCCDDEE),
          size: Vector2(95, 95),
        );

  @override
  int getPhase() {
    if (healthPercent > 0.6) return 0;
    if (healthPercent > 0.3) return 1;
    return 2;
  }

  @override
  void updateBoss(double dt) {
    _mirrorAngle += dt * (1.0 + currentPhase * 0.5);

    // Orbita attorno al player
    final orbitDist = 250 - currentPhase * 40;
    final targetPos = playerPosition + Vector2(
      math.cos(_mirrorAngle * 0.3) * orbitDist,
      math.sin(_mirrorAngle * 0.3) * orbitDist,
    );
    final toTarget = targetPos - position;
    if (toTarget.length > 5) {
      position += toTarget.normalized() * 90 * dt;
    }

    // Attacco
    _attackTimer -= dt;
    if (_attackTimer <= 0) {
      _attackTimer = 2.0 - currentPhase * 0.4;
      _shootMirrorBurst();
    }
  }

  void _shootMirrorBurst() {
    final count = 6 + currentPhase * 3;
    for (int i = 0; i < count; i++) {
      final angle = _mirrorAngle + i * math.pi * 2 / count;
      final dir = Vector2(math.cos(angle), math.sin(angle));
      final bullet = _MirrorBullet(direction: dir, color: neonColor);
      bullet.position = position.clone();
      game.world.add(bullet);
    }
  }

  // Signature FX paints
  static final _shardPaint = Paint();
  static final _shardStrokePaint = Paint()..style = PaintingStyle.stroke;
  static final _facePaint = Paint()
    ..strokeWidth = 2
    ..style = PaintingStyle.stroke;
  static final _innerOctPaint = Paint()..style = PaintingStyle.stroke;
  static final _coreHaloPaint = Paint();
  static final _coreWhitePaint = Paint();
  static final _prismaticPaint = Paint()..style = PaintingStyle.stroke;

  @override
  void renderBoss(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final r = size.x / 2 * scale;

    // ─── PRISMATIC SHARDS ORBITANTI (6 frammenti) ───
    if (scale <= 1.01) {
      for (int i = 0; i < 6; i++) {
        final sAngle = _mirrorAngle * 0.6 + i * math.pi / 3;
        final sDist = r * 1.35;
        final sx = cx + math.cos(sAngle) * sDist;
        final sy = cy + math.sin(sAngle) * sDist;
        final shardPulse = 0.6 + math.sin(_mirrorAngle * 3 + i * 1.1) * 0.4;
        canvas.save();
        canvas.translate(sx, sy);
        canvas.rotate(_mirrorAngle * 2 + i);
        final shardPath = Path()
          ..moveTo(0, -4)
          ..lineTo(3, 0)
          ..lineTo(0, 4)
          ..lineTo(-3, 0)
          ..close();
        _shardPaint.color = const Color(0xFFCCDDFF)
            .withValues(alpha: 0.5 * shardPulse);
        canvas.drawPath(shardPath, _shardPaint);
        _shardStrokePaint.color =
            const Color(0xFFFFFFFF).withValues(alpha: shardPulse);
        _shardStrokePaint.strokeWidth = 1;
        canvas.drawPath(shardPath, _shardStrokePaint);
        canvas.restore();
      }
    }

    // Ottagono principale
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(_mirrorAngle * 0.2);

    final path = Path();
    for (int i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      final x = r * 0.85 * math.cos(angle);
      final y = r * 0.85 * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);

    if (scale <= 1.01) {
      // Shimmer sulle 8 facce
      for (int i = 0; i < 8; i++) {
        final a1 = i * math.pi / 4;
        final a2 = (i + 1) * math.pi / 4;
        final shimmer = 0.3 + math.sin(_mirrorAngle * 3 + i * 0.8) * 0.3;
        _facePaint.color =
            const Color(0xFFFFFFFF).withValues(alpha: shimmer);
        canvas.drawLine(
          Offset(r * 0.85 * math.cos(a1), r * 0.85 * math.sin(a1)),
          Offset(r * 0.85 * math.cos(a2), r * 0.85 * math.sin(a2)),
          _facePaint,
        );
      }

      // ─── 3 RAGGI CROMATICI dal centro ───
      for (int p = 0; p < 3; p++) {
        final pAngle = _mirrorAngle * 2 + p * math.pi * 2 / 3;
        _prismaticPaint.color = [
          const Color(0xFFFF4488),
          const Color(0xFF44FFDD),
          const Color(0xFFFFDD44),
        ][p].withValues(alpha: 0.5);
        _prismaticPaint.strokeWidth = 1.2;
        canvas.drawLine(
          Offset.zero,
          Offset(math.cos(pAngle) * r * 0.75,
              math.sin(pAngle) * r * 0.75),
          _prismaticPaint,
        );
      }

      // Ottagono interno contro-rotante
      canvas.rotate(-_mirrorAngle * 0.5);
      _innerOctPaint.color =
          const Color(0xFFFFFFFF).withValues(alpha: 0.4);
      _innerOctPaint.strokeWidth = 1;
      final innerPath = Path();
      for (int i = 0; i < 8; i++) {
        final a = i * math.pi / 4 + math.pi / 8;
        final x = r * 0.45 * math.cos(a);
        final y = r * 0.45 * math.sin(a);
        if (i == 0) {
          innerPath.moveTo(x, y);
        } else {
          innerPath.lineTo(x, y);
        }
      }
      innerPath.close();
      canvas.drawPath(innerPath, _innerOctPaint);
      canvas.rotate(_mirrorAngle * 0.5);

      // Core halo + bianco pulsante
      final pulse = 0.5 + math.sin(_mirrorAngle * 2) * 0.4;
      _coreHaloPaint.color =
          const Color(0xFFCCDDFF).withValues(alpha: pulse * 0.5);
      canvas.drawCircle(Offset.zero, r * 0.32, _coreHaloPaint);
      _coreWhitePaint.color =
          const Color(0xFFFFFFFF).withValues(alpha: pulse);
      canvas.drawCircle(
          Offset.zero, r * 0.18 * (0.85 + pulse * 0.2), _coreWhitePaint);
    }
    canvas.restore();
  }
}

class _MirrorBullet extends PositionComponent with HasGameReference<GeometryFightGame> {
  final Vector2 direction;
  final Color color;
  late Vector2 _velocity;
  double _lifetime = 3.5;

  _MirrorBullet({required this.direction, required this.color})
      : super(size: Vector2(7, 7), anchor: Anchor.center);

  @override
  Future<void> onLoad() async { _velocity = direction.normalized() * 200; }

  @override
  void update(double dt) {
    super.update(dt);
    position += _velocity * dt;
    _lifetime -= dt;
    if (_lifetime <= 0) removeFromParent();
    if (position.distanceTo(game.player.position) < 10) {
      game.player.takeDamage();
      removeFromParent();
    }
  }

  static final _bulletPaint = Paint();
  static final _bulletCorePaint = Paint();

  @override
  void render(Canvas canvas) {
    _bulletPaint.color = color;
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), 3.5, _bulletPaint);
    _bulletCorePaint.color = const Color(0xFFFFFFFF).withValues(alpha: 0.7);
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), 1.5, _bulletCorePaint);
  }
}

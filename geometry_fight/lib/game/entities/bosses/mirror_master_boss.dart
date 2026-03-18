import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../../data/constants.dart';
import '../../../data/wave_configs.dart';
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

  @override
  void renderBoss(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final r = size.x / 2 * scale;

    // Ottagono con facce riflettenti
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(_mirrorAngle * 0.2);

    final path = Path();
    for (int i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      final x = r * 0.85 * math.cos(angle);
      final y = r * 0.85 * math.sin(angle);
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paint);

    if (scale <= 1.01) {
      // Facce riflettenti (linee luminose sulle facce)
      for (int i = 0; i < 8; i++) {
        final a1 = i * math.pi / 4;
        final a2 = (i + 1) * math.pi / 4;
        final shimmer = 0.3 + math.sin(_mirrorAngle * 3 + i * 0.8) * 0.3;
        final facePaint = Paint()
          ..color = const Color(0xFFFFFFFF).withValues(alpha: shimmer)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;
        canvas.drawLine(
          Offset(r * 0.85 * math.cos(a1), r * 0.85 * math.sin(a1)),
          Offset(r * 0.85 * math.cos(a2), r * 0.85 * math.sin(a2)),
          facePaint,
        );
      }

      // Nucleo
      final pulse = 0.4 + math.sin(_mirrorAngle * 2) * 0.3;
      canvas.drawCircle(
        Offset.zero, r * 0.25,
        Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: pulse)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
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

  @override
  void render(Canvas canvas) {
    final p = Paint()..color = color..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), 3.5, p);
  }
}

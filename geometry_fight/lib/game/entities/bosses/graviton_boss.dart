import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../../data/constants.dart';
import '../../game_world.dart';
import 'boss_base.dart';

/// GRAVITON - Boss che manipola la gravità, attira e respinge tutto.
/// Forma: sfera nera con anelli gravitazionali multipli e particelle aspirate
/// Colore: viola scuro con bordo dorato (#220044 + #FFD700)
/// HP: 2200 · 3 fasi
/// Meccanica: alterna tra fase PULL (aspira player e proiettili) e PUSH (respinge tutto).
class GravitonBoss extends BossBase {
  double _gravPhase = 0;
  double _pullPushTimer = 4.0;
  bool _isPulling = true;
  double _attackTimer = 2.0;
  static const double _gravityRadius = 350.0;

  GravitonBoss()
      : super(
          hp: 2200,
          bossName: 'GRAVITON',
          pointValue: 4500,
          neonColor: const Color(0xFF220044),
          size: Vector2(100, 100),
        );

  @override
  int getPhase() {
    if (healthPercent > 0.6) return 0;
    if (healthPercent > 0.3) return 1;
    return 2;
  }

  @override
  void updateBoss(double dt) {
    _gravPhase += dt * 3;

    // Alterna pull/push
    _pullPushTimer -= dt;
    if (_pullPushTimer <= 0) {
      _isPulling = !_isPulling;
      _pullPushTimer = _isPulling ? 4.0 : 2.5;
      game.triggerScreenShake(3, 0.15);
    }

    // Applica gravità al player
    final toPlayer = playerPosition - position;
    final dist = toPlayer.length;
    if (dist < _gravityRadius && dist > 10) {
      final force = (_isPulling ? 1.0 : -1.0) * 120 * dt * (1 - dist / _gravityRadius);
      game.player.position += toPlayer.normalized() * force * (_isPulling ? -1 : 1);
    }

    // Distorci griglia
    if (_isPulling) {
      game.grid.applyAttraction(position, _gravityRadius * 0.5, 200 * dt);
    } else {
      game.grid.applyForce(position, _gravityRadius * 0.5, 200 * dt);
    }

    // Movimento lento verso centro arena
    final center = Vector2(arenaWidth / 2, arenaHeight / 2);
    final toCenter = center - position;
    if (toCenter.length > 100) {
      position += toCenter.normalized() * 30 * dt;
    }

    // Attacco
    _attackTimer -= dt;
    if (_attackTimer <= 0) {
      _attackTimer = 2.0 - currentPhase * 0.3;
      _shootGravityBurst();
    }
  }

  void _shootGravityBurst() {
    final count = 8 + currentPhase * 4;
    for (int i = 0; i < count; i++) {
      final angle = i * math.pi * 2 / count + _gravPhase * 0.1;
      final dir = Vector2(math.cos(angle), math.sin(angle));
      final bullet = _GravBullet(direction: dir, color: const Color(0xFFFFD700));
      bullet.position = position.clone();
      game.world.add(bullet);
    }
  }

  @override
  void renderBoss(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final r = size.x / 2 * scale;

    // Campo gravitazionale visibile
    if (scale <= 1.01) {
      final fieldColor = _isPulling
          ? const Color(0xFF4400AA).withValues(alpha: 0.08)
          : const Color(0xFFFFD700).withValues(alpha: 0.06);
      canvas.drawCircle(Offset(cx, cy), _gravityRadius * 0.4, Paint()..color = fieldColor);

      // Particelle aspirate/respinte
      for (int i = 0; i < 12; i++) {
        final pAngle = _gravPhase * (_isPulling ? 1.5 : -1.5) + i * math.pi / 6;
        final pProgress = (_gravPhase * 0.5 + i * 0.2) % 1.0;
        final pDist = _isPulling
            ? r * 2 * (1 - pProgress) // Verso il centro
            : r * 0.5 + r * 2 * pProgress; // Dal centro
        final px = cx + pDist * math.cos(pAngle);
        final py = cy + pDist * math.sin(pAngle);
        final pAlpha = _isPulling ? pProgress * 0.3 : (1 - pProgress) * 0.3;
        canvas.drawCircle(
          Offset(px, py), 1.5,
          Paint()..color = const Color(0xFFFFD700).withValues(alpha: pAlpha),
        );
      }
    }

    // Anelli gravitazionali rotanti
    for (int ring = 0; ring < 3; ring++) {
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(_gravPhase * (0.3 + ring * 0.2) * (_isPulling ? 1 : -1));
      final ringPaint = Paint()
        ..color = const Color(0xFFFFD700).withValues(alpha: 0.3 - ring * 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (2 - ring * 0.5) * scale;
      canvas.drawCircle(Offset.zero, r * (0.6 + ring * 0.15), ringPaint);
      canvas.restore();
    }

    // Sfera nera centrale
    canvas.drawCircle(Offset(cx, cy), r * 0.4, Paint()..color = const Color(0xFF000011));
    // Bordo dorato
    canvas.drawCircle(
      Offset(cx, cy), r * 0.4,
      Paint()
        ..color = const Color(0xFFFFD700).withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 * scale,
    );

    // Nucleo
    if (scale <= 1.01) {
      final pulse = _isPulling ? 0.6 : 0.3;
      canvas.drawCircle(
        Offset(cx, cy), r * 0.15,
        Paint()..color = const Color(0xFFFFD700).withValues(alpha: pulse)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );

      // Indicatore pull/push
      final indicatorColor = _isPulling
          ? const Color(0xFF4400AA)
          : const Color(0xFFFFD700);
      canvas.drawCircle(
        Offset(cx, cy - r * 0.55), 3,
        Paint()..color = indicatorColor..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }
  }
}

class _GravBullet extends PositionComponent with HasGameReference<GeometryFightGame> {
  final Vector2 direction;
  final Color color;
  late Vector2 _velocity;
  double _lifetime = 4.0;

  _GravBullet({required this.direction, required this.color})
      : super(size: Vector2(7, 7), anchor: Anchor.center);

  @override
  Future<void> onLoad() async { _velocity = direction.normalized() * 180; }

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
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2), 3.5,
      Paint()..color = color..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
  }
}

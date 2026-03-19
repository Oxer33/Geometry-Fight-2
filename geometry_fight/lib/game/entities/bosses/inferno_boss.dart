import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../game_world.dart';
import 'boss_base.dart';

/// INFERNO - Boss di fuoco che lascia scie infuocate e crea muri di fiamma.
/// Forma: stella a 5 punte con fiamme animate
/// Colore: arancione/rosso fuoco (#FF4400)
/// HP: 1900 · 3 fasi
/// Meccanica: si muove velocemente lasciando scie di fuoco che danneggiano.
/// Crea muri di fiamma lineari nell'arena.
class InfernoBoss extends BossBase {
  double _flamePhase = 0;
  double _attackTimer = 3.0;
  double _moveAngle = 0;
  final List<_FlameTrail> _trails = [];

  InfernoBoss()
      : super(
          hp: 1900,
          bossName: 'INFERNO',
          pointValue: 3800,
          neonColor: const Color(0xFFFF4400),
          size: Vector2(90, 90),
        );

  @override
  int getPhase() {
    if (healthPercent > 0.6) return 0;
    if (healthPercent > 0.3) return 1;
    return 2;
  }

  @override
  void updateBoss(double dt) {
    _flamePhase += dt * 8;
    _moveAngle += dt * (1.5 + currentPhase * 0.5);

    // Movimento veloce in pattern circolare
    final speed = 120.0 + currentPhase * 40;
    final targetPos = playerPosition + Vector2(
      math.cos(_moveAngle) * (200 - currentPhase * 30),
      math.sin(_moveAngle) * (200 - currentPhase * 30),
    );
    final toTarget = targetPos - position;
    if (toTarget.length > 5) {
      position += toTarget.normalized() * speed * dt;
    }

    // Lascia scia di fuoco
    _trails.add(_FlameTrail(position: position.clone(), lifetime: 3.0));
    // Aggiorna e rimuovi trails
    for (int i = _trails.length - 1; i >= 0; i--) {
      _trails[i].lifetime -= dt;
      if (_trails[i].lifetime <= 0) {
        _trails.removeAt(i);
      } else {
        // Danno al player dalle scie
        final dist = game.player.position.distanceTo(_trails[i].position);
        if (dist < 15) {
          game.player.takeDamage();
          _trails.removeAt(i);
        }
      }
    }
    // Limita trails
    while (_trails.length > 60) _trails.removeAt(0);

    // Attacco: proiettili di fuoco
    _attackTimer -= dt;
    if (_attackTimer <= 0) {
      _attackTimer = 2.0 - currentPhase * 0.4;
      _fireAttack();
    }
  }

  void _fireAttack() {
    final count = 5 + currentPhase * 3;
    for (int i = 0; i < count; i++) {
      final angle = i * math.pi * 2 / count + _flamePhase * 0.05;
      final dir = Vector2(math.cos(angle), math.sin(angle));
      final bullet = _FireBullet(direction: dir);
      bullet.position = position.clone();
      game.world.add(bullet);
    }
  }

  @override
  void renderBoss(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final r = size.x / 2 * scale;

    // Scie di fuoco
    if (scale <= 1.01) {
      for (final trail in _trails) {
        final offset = trail.position - position;
        final alpha = (trail.lifetime / 3.0).clamp(0.0, 1.0) * 0.4;
        final trailR = 6 * (trail.lifetime / 3.0);
        canvas.drawCircle(
          Offset(cx + offset.x, cy + offset.y), trailR,
          Paint()
            ..color = neonColor.withValues(alpha: alpha)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, trailR),
        );
      }
    }

    // Stella a 5 punte con fiamme
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(_flamePhase * 0.1);

    final starPath = Path();
    for (int i = 0; i < 10; i++) {
      final angle = i * math.pi / 5 - math.pi / 2;
      final flameWobble = i % 2 == 0 ? math.sin(_flamePhase + i) * 3 : 0.0;
      final starR = i % 2 == 0 ? r * 0.85 + flameWobble : r * 0.4;
      final x = starR * math.cos(angle);
      final y = starR * math.sin(angle);
      if (i == 0) starPath.moveTo(x, y); else starPath.lineTo(x, y);
    }
    starPath.close();
    canvas.drawPath(starPath, paint);

    if (scale <= 1.01) {
      // Nucleo incandescente
      final pulse = 0.5 + math.sin(_flamePhase * 0.5) * 0.3;
      canvas.drawCircle(
        Offset.zero, r * 0.25,
        Paint()..color = const Color(0xFFFFDD00).withValues(alpha: pulse)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      // Centro bianco
      canvas.drawCircle(
        Offset.zero, r * 0.1,
        Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.7),
      );
    }
    canvas.restore();
  }
}

class _FlameTrail {
  Vector2 position;
  double lifetime;
  _FlameTrail({required this.position, required this.lifetime});
}

class _FireBullet extends PositionComponent with HasGameReference<GeometryFightGame> {
  final Vector2 direction;
  late Vector2 _velocity;
  double _lifetime = 3.0;

  _FireBullet({required this.direction})
      : super(size: Vector2(8, 8), anchor: Anchor.center);

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
    final p = Paint()
      ..color = const Color(0xFFFF6600)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), 4, p);
    p.color = const Color(0xFFFFDD00).withValues(alpha: 0.8);
    p.maskFilter = null;
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), 2, p);
  }
}

import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../../data/constants.dart';
import 'enemy_base.dart';

class MineEnemy extends EnemyBase {
  double _detonateTimer = -1;
  bool _detonating = false;
  bool _exploded = false;

  MineEnemy()
      : super(
          hp: 2,
          speed: 0,
          pointValue: 3,
          geomValue: 2,
          neonColor: NeonColors.gray,
          size: Vector2(20, 20),
        );

  @override
  void updateBehavior(double dt) {
    // Check proximity to player
    if (!_detonating && distanceToPlayer < 80) {
      _detonating = true;
      _detonateTimer = 0.5;
    }

    if (_detonating) {
      _detonateTimer -= dt;
      if (_detonateTimer <= 0) {
        onDeath(); // onDeath chiama _explode + super.onDeath
        return;
      }
    }
  }

  @override
  void takeDamage(double amount) {
    if (!_detonating) {
      _detonating = true;
      _detonateTimer = 0.5;
    }
    super.takeDamage(amount);
  }

  void _explode() {
    // Damage player if in range
    if (distanceToPlayer < 100) {
      game.player.takeDamage();
    }
    game.spawnExplosion(position, NeonColors.gray, radius: 100, particleCount: 25);
    if (!game.isTunnelMode) {
      game.grid.applyForce(position, 150, 800);
    }
  }

  @override
  void onDeath() {
    if (!_exploded) {
      _exploded = true;
      _explode();
    }
    super.onDeath();
  }

  @override
  void renderShape(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final r = 8 * scale;

    // Anelli di pericolo concentrici (durante detonazione)
    if (_detonating && scale <= 1.01) {
      final progress = 1.0 - (_detonateTimer / 0.5).clamp(0.0, 1.0);
      for (int ring = 0; ring < 3; ring++) {
        final ringR = 15 + ring * 12.0 + progress * 20;
        final ringAlpha = (0.3 - ring * 0.08) * (1 - progress);
        final ringPaint = Paint()
          ..color = const Color(0xFFFF0000).withValues(alpha: ringAlpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;
        canvas.drawCircle(Offset(cx, cy), ringR, ringPaint);
      }
    }

    // Stella con punte animate (8 punte)
    final path = Path();
    for (int i = 0; i < 16; i++) {
      final angle = i * math.pi / 8 + idlePhase * 0.5;
      // Punte che pulsano leggermente
      final pulseFactor = 1.0 + math.sin(idlePhase * 3 + i * 0.5) * 0.1;
      final radius = (i % 2 == 0 ? r : r * 0.45) * pulseFactor;
      final x = cx + radius * math.cos(angle);
      final y = cy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    // Flash rosso quando si sta per detonare
    if (_detonating) {
      final flashSpeed = 20 + (1 - _detonateTimer / 0.5) * 30;
      final flash = ((idlePhase * flashSpeed).toInt() % 2 == 0);
      if (flash) {
        paint.color = const Color(0xFFFF0000);
      }
    }

    canvas.drawPath(path, paint);

    // Dettagli interni (solo layer principale, senza blur per performance)
    if (scale <= 1.01) {
      // Nucleo interno
      final coreColor = _detonating
          ? const Color(0xFFFF0000).withValues(alpha: 0.8)
          : paint.color.withValues(alpha: 0.5);
      final corePaint = Paint()..color = coreColor;
      canvas.drawCircle(Offset(cx, cy), r * 0.25, corePaint);
    }
  }
}

import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../../data/constants.dart';
import 'enemy_base.dart';

/// NEW ENEMY: Phantom - phases in and out of visibility, only vulnerable when visible
class PhantomEnemy extends EnemyBase {
  double _phaseTimer = 0;
  bool _visible = true;
  double _opacity = 1.0;

  PhantomEnemy()
      : super(
          hp: 3,
          speed: 160,
          pointValue: 400,
          geomValue: 5,
          neonColor: NeonColors.electricBlue,
          size: Vector2(20, 20),
        );

  @override
  void updateBehavior(double dt) {
    _phaseTimer += dt;

    // Phase cycle: visible 2s, fade 0.5s, invisible 1.5s, fade in 0.5s
    final cycle = _phaseTimer % 4.5;
    if (cycle < 2.0) {
      _visible = true;
      _opacity = 1.0;
    } else if (cycle < 2.5) {
      _opacity = 1.0 - (cycle - 2.0) / 0.5;
      _visible = true;
    } else if (cycle < 4.0) {
      _visible = false;
      _opacity = 0.1;
    } else {
      _opacity = (cycle - 4.0) / 0.5;
      _visible = false;
    }

    // Always move towards player
    final velocity = seekPlayer(speed);
    position += velocity * dt;
  }

  @override
  void takeDamage(double amount) {
    if (!_visible) return; // Immune when phased out
    super.takeDamage(amount);
  }

  @override
  void render(Canvas canvas) {
    // Override render to apply opacity
    final glowPaint = Paint()
      ..color = neonColor.withValues(alpha: 0.3 * _opacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    renderShape(canvas, glowPaint, 1.3);

    final mainPaint = Paint()..color = neonColor.withValues(alpha: _opacity);
    renderShape(canvas, mainPaint, 1.0);
  }

  @override
  void renderShape(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final r = 10 * scale;

    // Ghostly diamond with wavy edges
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(idlePhase * 1.5);

    final path = Path();
    for (int i = 0; i < 12; i++) {
      final angle = i * math.pi * 2 / 12;
      final wobble = math.sin(idlePhase * 5 + i * 0.8) * 2;
      final x = (r + wobble) * math.cos(angle);
      final y = (r + wobble) * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
    canvas.restore();
  }
}

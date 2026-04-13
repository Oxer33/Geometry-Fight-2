import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../../data/constants.dart';
import 'enemy_base.dart';

/// PHANTOM - Si fa invisibile e attacca dai fianchi.
/// Movimento: FLANKING - non va dritto verso il player, ma cerca di avvicinarsi
/// da un angolo laterale/posteriore. Quando è invisibile accelera per
/// riposizionarsi, quando è visibile avanza lento per colpire.
class PhantomEnemy extends EnemyBase {
  double _phaseTimer = 0;
  bool _visible = true;
  double _opacity = 1.0;
  final double _flankAngle;

  PhantomEnemy()
      : _flankAngle =
            (math.Random().nextBool() ? 1.0 : -1.0) * math.pi * 0.6,
        super(
          hp: 3,
          speed: 160,
          pointValue: 15,
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

    final toPlayer = playerPosition - position;
    if (toPlayer.length == 0) return;

    if (!_visible) {
      // INVISIBILE: riposizionamento veloce verso il fianco del player
      // Calcola posizione target sul fianco
      final playerAngle = math.atan2(toPlayer.y, toPlayer.x);
      final targetAngle = playerAngle + _flankAngle;
      final targetDist = 80.0; // Vicino al player ma non addosso

      final targetPos = playerPosition -
          Vector2(math.cos(targetAngle), math.sin(targetAngle)) * targetDist;

      final toTarget = targetPos - position;
      if (toTarget.length > 10) {
        position += toTarget.normalized() * speed * 1.3 * dt; // Più veloce
      }
    } else {
      // VISIBILE: avanza diretto ma più lento (l'attacco vero)
      position += toPlayer.normalized() * speed * 0.7 * dt;
    }
  }

  @override
  void takeDamage(double amount) {
    if (!_visible) return; // Immune when phased out
    super.takeDamage(amount);
  }

  @override
  void render(Canvas canvas) {
    // Override render to apply opacity — senza blur
    final glowPaint = Paint()
      ..color = neonColor.withValues(alpha: 0.15 * _opacity);
    renderShape(canvas, glowPaint, 1.6);

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

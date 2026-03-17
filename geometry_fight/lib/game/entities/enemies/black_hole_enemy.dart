import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../../data/constants.dart';
import '../../../data/wave_configs.dart';
import 'enemy_base.dart';
import '../projectiles.dart';

class BlackHoleEnemy extends EnemyBase {
  double _rotAngle = 0;
  double _spawnTimer = 5.0;

  BlackHoleEnemy()
      : super(
          hp: 20,
          speed: 0,
          pointValue: 1000,
          geomValue: 10,
          neonColor: NeonColors.darkRed,
          size: Vector2(40, 40),
        );

  @override
  void updateBehavior(double dt) {
    _rotAngle += dt * 2;

    // Attract player (weak force)
    final toHole = position - game.player.position;
    if (toHole.length > 0 && toHole.length < 300) {
      final force = toHole.normalized() * 50 * dt;
      game.player.position += force;
    }

    // Attract nearby enemies
    for (final child in game.world.children) {
      if (child is EnemyBase && child != this) {
        final toHole = position - child.position;
        if (toHole.length > 0 && toHole.length < 200) {
          child.position += toHole.normalized() * 30 * dt;
        }
      }
    }

    // Curve player projectiles
    for (final child in game.world.children) {
      if (child is PlayerBullet) {
        final toBH = position - child.position;
        if (toBH.length > 0 && toBH.length < 200) {
          child.position += toBH.normalized() * 80 * dt;
        }
      }
    }

    // Spawn bonus enemies
    _spawnTimer -= dt;
    if (_spawnTimer <= 0) {
      _spawnTimer = 5.0;
      game.spawnEnemy(
          EnemyType.drone,
          position +
              Vector2(
                (math.Random().nextDouble() - 0.5) * 60,
                (math.Random().nextDouble() - 0.5) * 60,
              ));
    }
  }

  @override
  void takeDamage(double amount) {
    // Immune to normal bullets - only plasma, bomb, laser do damage
    // This is handled by checking weapon type in the bullet collision
    // For simplicity, all damage works but normal bullets do reduced
    super.takeDamage(amount * 0.3);
  }

  @override
  void renderShape(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final r = 18 * scale;

    // === INDICATORE RAGGIO GRAVITAZIONALE (cerchio sottile) ===
    if (scale <= 1.01) {
      final rangePaint = Paint()
        ..color = NeonColors.darkRed.withValues(alpha: 0.06)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5;
      canvas.drawCircle(Offset(cx, cy), 150, rangePaint); // raggio attrazione
    }

    // === GLOW ESTERNO ROSSO (ampio, pulsante) ===
    final glowPulse = 0.15 + math.sin(_rotAngle * 1.5) * 0.05;
    final outerGlow = Paint()
      ..color = NeonColors.red.withValues(alpha: glowPulse)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25);
    canvas.drawCircle(Offset(cx, cy), r * 2, outerGlow);

    // === ANELLI GRAVITAZIONALI ROTANTI ===
    // Anello 1: esterno, rotazione oraria
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(_rotAngle);
    final ring1Paint = Paint()
      ..color = NeonColors.red.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * scale;
    for (int i = 0; i < 4; i++) {
      final angle = i * math.pi / 2;
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: r),
        angle, math.pi / 3, false, ring1Paint,
      );
    }
    canvas.restore();

    // Anello 2: interno, rotazione antioraria
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(-_rotAngle * 1.3);
    final ring2Paint = Paint()
      ..color = NeonColors.red.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * scale;
    for (int i = 0; i < 3; i++) {
      final angle = i * math.pi * 2 / 3;
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: r * 0.7),
        angle, math.pi / 4, false, ring2Paint,
      );
    }
    canvas.restore();

    // === NUCLEO NERO con bordo rosso ===
    final darkPaint = Paint()..color = const Color(0xFF000000);
    canvas.drawCircle(Offset(cx, cy), r * 0.5, darkPaint);
    // Bordo rosso pulsante del nucleo
    final borderPulse = 0.5 + math.sin(_rotAngle * 3) * 0.3;
    final borderPaint = Paint()
      ..color = NeonColors.red.withValues(alpha: borderPulse)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(Offset(cx, cy), r * 0.5, borderPaint);

    // === PARTICELLE SPIRALANTI (solo layer principale) ===
    if (scale <= 1.01) {
      for (int i = 0; i < 8; i++) {
        final pAngle = _rotAngle * 2 + i * math.pi / 4;
        final pDist = r * (0.6 + 0.4 * math.sin(_rotAngle + i * 0.5));
        final px = cx + pDist * math.cos(pAngle);
        final py = cy + pDist * math.sin(pAngle);
        final pAlpha = 0.2 + math.sin(_rotAngle * 3 + i) * 0.15;
        final particlePaint = Paint()
          ..color = NeonColors.red.withValues(alpha: pAlpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
        canvas.drawCircle(Offset(px, py), 1.5, particlePaint);
      }

      // Punto luminoso centrale
      final corePaint = Paint()
        ..color = const Color(0xFFFF4400).withValues(alpha: 0.5 + math.sin(_rotAngle * 4) * 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(Offset(cx, cy), r * 0.15, corePaint);
    }

    paint.style = PaintingStyle.fill;
  }
}

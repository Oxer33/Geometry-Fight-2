import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../../data/constants.dart';
import 'enemy_base.dart';

// Paint cache condivisi da tutte le Mine a schermo.
final Paint _mineRingPaint = Paint()
  ..style = PaintingStyle.stroke
  ..strokeWidth = 1;
final Paint _mineArcPaint = Paint()
  ..style = PaintingStyle.stroke
  ..strokeWidth = 0.8;
final Paint _mineCircuitPaint = Paint()..strokeWidth = 0.5;
final Paint _mineInnerRingPaint = Paint()
  ..style = PaintingStyle.stroke
  ..strokeWidth = 0.5;

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
          // Size -30% dal precedente 40x40 (richiesta utente: "enormi").
          // 40 × 0.7 = 28 → mantiene ~1.4x rispetto all'originale 20x20.
          size: Vector2(28, 28),
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
      if (_detonateTimer <= 0 && !_exploded) { // FIX C2: evita double-death se già esplosa
        onDeath(); // onDeath chiama _explode + super.onDeath
        return;
      }
    }
  }

  @override
  void takeDamage(double amount, {bool isArea = false}) {
    if (!_detonating) {
      _detonating = true;
      _detonateTimer = 0.5;
    }
    super.takeDamage(amount, isArea: isArea);
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
    // FIX: r deve scalare con size (prima hardcoded 8 → mob 8px in hitbox 40px
    // dopo il raddoppio size). 0.4 mantiene il ratio originale (8/20).
    final r = size.x * 0.4 * scale;

    // Anelli di pericolo concentrici (durante detonazione)
    if (_detonating && scale <= 1.01) {
      final progress = 1.0 - (_detonateTimer / 0.5).clamp(0.0, 1.0);
      for (int ring = 0; ring < 3; ring++) {
        // Scalati anch'essi con size (base 15 era tarato per size 20).
        final ringR = (15 + ring * 12.0 + progress * 20) * (size.x / 20);
        final ringAlpha = (0.3 - ring * 0.08) * (1 - progress);
        _mineRingPaint.color =
            const Color(0xFFFF0000).withValues(alpha: ringAlpha);
        canvas.drawCircle(Offset(cx, cy), ringR, _mineRingPaint);
      }
    }

    // Stella con punte animate (8 punte)
    final path = Path();
    for (int i = 0; i < 16; i++) {
      final angle = i * math.pi / 8 + idlePhase * 0.5;
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

    // Flash rosso quando si sta per detonare.
    // FIX: `paint` è condiviso/cache — non mutarne il color senza ripristino.
    // Salviamo l'originale e ripristiniamo dopo il drawPath.
    final originalColor = paint.color;
    if (_detonating) {
      final flashSpeed = 20 + (1 - _detonateTimer / 0.5) * 30;
      final flash = ((idlePhase * flashSpeed).toInt() % 2 == 0);
      if (flash) {
        paint.color = const Color(0xFFFF0000);
      }
    }

    canvas.drawPath(path, paint);
    paint.color = originalColor;

    if (scale <= 1.01) {
      // Archi rotanti di pericolo (2 archi opposti)
      _mineArcPaint.color = (_detonating
              ? const Color(0xFFFF4400)
              : paint.color)
          .withValues(alpha: 0.25);
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(idlePhase * 1.5);
      final arcRect = Rect.fromCircle(center: Offset.zero, radius: r * 0.7);
      canvas.drawArc(arcRect, 0, math.pi * 0.6, false, _mineArcPaint);
      canvas.drawArc(arcRect, math.pi, math.pi * 0.6, false, _mineArcPaint);
      canvas.restore();

      // Circuiti interni (4 linee radiali + anello)
      _mineCircuitPaint.color = paint.color.withValues(alpha: 0.2);
      for (int i = 0; i < 4; i++) {
        final angle = i * math.pi / 2 + idlePhase * 0.5;
        canvas.drawLine(
          Offset(cx, cy),
          Offset(cx + math.cos(angle) * r * 0.6, cy + math.sin(angle) * r * 0.6),
          _mineCircuitPaint,
        );
      }

      // Anello interno
      _mineInnerRingPaint.color = paint.color.withValues(alpha: 0.2);
      canvas.drawCircle(Offset(cx, cy), r * 0.35, _mineInnerRingPaint);

      // Nucleo interno pulsante
      final coreAlpha = _detonating
          ? 0.6 + math.sin(idlePhase * 15) * 0.4
          : 0.4 + math.sin(idlePhase * 3) * 0.2;
      final coreColor = _detonating
          ? const Color(0xFFFF0000)
          : const Color(0xFFFFFFFF);
      EnemyBase.detailPaint.color = coreColor.withValues(alpha: coreAlpha);
      canvas.drawCircle(Offset(cx, cy), r * 0.2, EnemyBase.detailPaint);

      // 8 punti sulle punte della stella (energia)
      for (int i = 0; i < 8; i++) {
        final tipAngle = i * math.pi / 4 + idlePhase * 0.5;
        final tipPulse = 0.2 + math.sin(idlePhase * 4 + i * 0.8) * 0.2;
        final tipColor = _detonating ? const Color(0xFFFF4400) : paint.color;
        EnemyBase.detailPaint.color = tipColor.withValues(alpha: tipPulse);
        canvas.drawCircle(
          Offset(cx + math.cos(tipAngle) * r * 0.9, cy + math.sin(tipAngle) * r * 0.9),
          0.8, EnemyBase.detailPaint,
        );
      }
    }
  }
}

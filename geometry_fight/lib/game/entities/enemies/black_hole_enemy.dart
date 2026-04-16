import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../../data/constants.dart';
import 'enemy_base.dart';
import 'proton_enemy.dart';

class BlackHoleEnemy extends EnemyBase {
  static final _ringPaint = Paint()..style = PaintingStyle.stroke;
  static final _darkPaint = Paint();

  double _rotAngle = 0;
  int _absorbedCount = 0;
  bool _dead = false;
  bool _activated = false;

  static const int _protonThreshold = 7;

  // HP alto: con baseFireRate 8 e damageMultiplier ~1.0, servono ~3-5s di fuoco diretto
  BlackHoleEnemy()
      : super(
          hp: 35,
          speed: 0,
          pointValue: 30,
          geomValue: 10,
          neonColor: NeonColors.darkRed,
          size: Vector2(40, 40),
        );

  @override
  void takeDamage(double amount) {
    if (_dead) return;
    // Il primo colpo attiva il black hole
    if (!_activated) {
      _activated = true;
    }
    // Danno reale — ci vogliono 3-5 secondi per ucciderlo
    super.takeDamage(amount);
  }

  @override
  void updateBehavior(double dt) {
    // Rotation speed doubles when activated
    _rotAngle += dt * (_activated ? 4 : 2);

    if (!_activated) return;

    // Attract nearby enemies (NOT player, NOT player bullets)
    final toAbsorb = <EnemyBase>[];
    for (final child in game.world.children) {
      if (child is EnemyBase && child != this) {
        // Black holes cannot absorb other black holes
        if (child is BlackHoleEnemy) continue;
        final toHole = position - child.position;
        if (toHole.length > 0 && toHole.length < 250) {
          child.position += toHole.normalized() * 60 * dt;
          if (toHole.length < 15) {
            toAbsorb.add(child);
          }
        }
      }
    }

    // Remove absorbed enemies outside the loop
    for (final enemy in toAbsorb) {
      enemy.removeFromParent();
      _absorbedCount++;
    }

    // Proton explosion after absorbing enough enemies
    if (_absorbedCount >= _protonThreshold) {
      _explodeIntoProtons();
    }
  }

  void _explodeIntoProtons() {
    if (_dead) return;
    _dead = true;
    final protonCount = 8 + _absorbedCount;
    for (int i = 0; i < protonCount; i++) {
      final angle = i * math.pi * 2 / protonCount;
      final dir = Vector2(math.cos(angle), math.sin(angle));
      final proton = ProtonEnemy(direction: dir);
      proton.position = position + dir * 20;
      game.world.add(proton);
    }

    // Shockwave: uccidi nemici vicini (non altri black hole) e respingi player
    for (final child in List.from(game.world.children)) {
      if (child is EnemyBase && child != this && child is! BlackHoleEnemy) {
        if (child.position.distanceTo(position) < 200) {
          child.killSilently();
        }
      }
    }
    final toPlayer = game.player.position - position;
    if (toPlayer.length > 0 && toPlayer.length < 300) {
      game.player.position += toPlayer.normalized() * 400 * (1.0 - toPlayer.length / 300);
    }

    game.spawnExplosion(position, NeonColors.red, radius: 150, particleCount: 30, epic: true);
    game.triggerScreenShake(8, 0.4);
    if (!game.isTunnelMode) {
      game.grid.applyForce(position, 300, 2500);
    }

    game.onEnemyKilled(this);
    removeFromParent();
  }

  @override
  void onDeath() {
    if (_dead) return;
    _dead = true;

    // Esplosione alla morte: uccide nemici vicini (esclusi altri black hole) e respinge player
    _deathExplosion();

    super.onDeath();
  }

  /// Shockwave alla morte: uccide nemici entro 200px e respinge il player
  void _deathExplosion() {
    const killRadius = 200.0;
    const pushForce = 400.0;

    // Uccidi nemici vicini (non altri black hole)
    for (final child in List.from(game.world.children)) {
      if (child is EnemyBase && child != this && child is! BlackHoleEnemy) {
        final dist = child.position.distanceTo(position);
        if (dist < killRadius) {
          child.killSilently();
        }
      }
    }

    // Respingi il player
    final toPlayer = game.player.position - position;
    if (toPlayer.length > 0 && toPlayer.length < killRadius * 1.5) {
      final pushDir = toPlayer.normalized();
      game.player.position += pushDir * pushForce * (1.0 - toPlayer.length / (killRadius * 1.5));
    }

    // Mega esplosione visiva
    game.spawnExplosion(position, NeonColors.red, radius: 150, particleCount: 25, epic: true);
    game.triggerScreenShake(6, 0.3);
    if (!game.isTunnelMode) {
      game.grid.applyForce(position, 300, 2500);
    }
  }

  @override
  void renderShape(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final r = 18 * scale;

    // Gravitational radius indicator (subtle circle)
    if (scale <= 1.01) {
      final indicatorAlpha = _activated ? 0.12 : 0.06;
      EnemyBase.detailPaint.color = NeonColors.darkRed.withValues(alpha: indicatorAlpha);
      EnemyBase.detailPaint.style = PaintingStyle.stroke;
      EnemyBase.detailPaint.strokeWidth = 0.5;
      canvas.drawCircle(Offset(cx, cy), 150, EnemyBase.detailPaint);
      EnemyBase.detailPaint.style = PaintingStyle.fill;
    }

    // Outer red glow (pulsing)
    final glowPulse = 0.15 + math.sin(_rotAngle * 1.5) * 0.05;
    final glowAlpha = _activated ? glowPulse * 2 : glowPulse;
    EnemyBase.detailPaint.color = NeonColors.red.withValues(alpha: glowAlpha.clamp(0.0, 1.0));
    canvas.drawCircle(Offset(cx, cy), r * 2, EnemyBase.detailPaint);

    // Rotating gravitational rings
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(_rotAngle);
    _ringPaint.color = NeonColors.red.withValues(alpha: 0.4);
    _ringPaint.strokeWidth = 2 * scale;
    for (int i = 0; i < 4; i++) {
      final angle = i * math.pi / 2;
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: r),
        angle, math.pi / 3, false, _ringPaint,
      );
    }
    canvas.restore();

    // Inner ring, counter-rotating
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(-_rotAngle * 1.3);
    _ringPaint.color = NeonColors.red.withValues(alpha: 0.25);
    _ringPaint.strokeWidth = 1.5 * scale;
    for (int i = 0; i < 3; i++) {
      final angle = i * math.pi * 2 / 3;
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: r * 0.7),
        angle, math.pi / 4, false, _ringPaint,
      );
    }
    canvas.restore();

    // Black core with red border
    _darkPaint.color = const Color(0xFF000000);
    canvas.drawCircle(Offset(cx, cy), r * 0.5, _darkPaint);
    final borderPulse = 0.5 + math.sin(_rotAngle * 3) * 0.3;
    _ringPaint.color = NeonColors.red.withValues(alpha: borderPulse);
    _ringPaint.strokeWidth = 1.5;
    canvas.drawCircle(Offset(cx, cy), r * 0.5, _ringPaint);

    // Spiraling particles (main layer only)
    if (scale <= 1.01) {
      for (int i = 0; i < 8; i++) {
        final pAngle = _rotAngle * 2 + i * math.pi / 4;
        final pDist = r * (0.6 + 0.4 * math.sin(_rotAngle + i * 0.5));
        final px = cx + pDist * math.cos(pAngle);
        final py = cy + pDist * math.sin(pAngle);
        final pAlpha = 0.2 + math.sin(_rotAngle * 3 + i) * 0.15;
        EnemyBase.detailPaint.color = NeonColors.red.withValues(alpha: pAlpha);
        canvas.drawCircle(Offset(px, py), 1.5, EnemyBase.detailPaint);
      }

      // Central bright dot
      EnemyBase.detailPaint.color = const Color(0xFFFF4400).withValues(alpha: 0.5 + math.sin(_rotAngle * 4) * 0.3);
      canvas.drawCircle(Offset(cx, cy), r * 0.15, EnemyBase.detailPaint);

      // Dormant state indicator: a small dim ring to hint it's waiting
      if (!_activated) {
        EnemyBase.detailPaint.color = NeonColors.red.withValues(alpha: 0.15);
        EnemyBase.detailPaint.style = PaintingStyle.stroke;
        // ignore: deprecated_member_use
        EnemyBase.detailPaint.strokeWidth = 1.0;
        canvas.drawCircle(Offset(cx, cy), r * 1.1, EnemyBase.detailPaint);
        EnemyBase.detailPaint.style = PaintingStyle.fill;
      }
    }

    paint.style = PaintingStyle.fill;
  }
}

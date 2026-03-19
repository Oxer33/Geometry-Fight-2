import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/painting.dart' show TextPainter, TextSpan, TextStyle, FontWeight, TextDirection;
import '../../../data/constants.dart';
import 'enemy_base.dart';

/// TIME BOMB - Nemico con countdown visibile che esplode in area enorme.
/// Forma: cerchio con countdown numerico e anelli di pericolo
/// Colore: rosso/arancio (#FF6600)
/// Meccanica: ha un timer di 8 secondi visibile. Quando esplode, danno area 200px.
/// Se il player lo uccide prima, il timer si resetta e dropa power-up.
/// Immune ai proiettili per i primi 2 secondi (scudo di attivazione).
class TimeBombEnemy extends EnemyBase {
  double _countdown = 8.0;
  static const double _explosionRadius = 200.0;
  bool _activated = false;
  double _activationTimer = 2.0;

  TimeBombEnemy()
      : super(
          hp: 4,
          speed: 90,
          pointValue: 350,
          geomValue: 4,
          neonColor: const Color(0xFFFF6600),
          size: Vector2(24, 24),
        );

  @override
  void updateBehavior(double dt) {
    // Fase attivazione (immune per 2s)
    if (!_activated) {
      _activationTimer -= dt;
      if (_activationTimer <= 0) _activated = true;
      // Si avvicina lentamente
      position += seekPlayer(speed * 0.5) * dt;
      return;
    }

    // Si avvicina al player
    position += seekPlayer(speed) * dt;

    // Countdown
    _countdown -= dt;
    if (_countdown <= 0) {
      _explode();
    }
  }

  @override
  void takeDamage(double amount) {
    if (!_activated) return; // Immune durante attivazione
    super.takeDamage(amount);
  }

  void _explode() {
    // Danno area al player
    if (distanceToPlayer < _explosionRadius) {
      game.player.takeDamage();
    }
    // Esplosione enorme
    game.spawnExplosion(position, neonColor, radius: _explosionRadius, particleCount: 40);
    game.grid.applyForce(position, _explosionRadius * 1.5, 1500);
    game.triggerScreenShake(8, 0.4);
    removeFromParent();
    game.onEnemyKilled(this);
  }

  @override
  void onDeath() {
    // Ucciso dal player: no esplosione, drop power-up garantito
    game.spawnPowerUp(position);
    game.onEnemyKilled(this);
    game.spawnExplosion(position, NeonColors.green, radius: 30, particleCount: 15);
    removeFromParent();
  }

  @override
  void renderShape(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final r = size.x / 2 * scale;

    // Colore cambia col countdown (arancio → rosso → rosso lampeggiante)
    final urgency = 1.0 - (_countdown / 8.0).clamp(0.0, 1.0);
    Color bodyColor;
    if (_countdown > 4) {
      bodyColor = paint.color;
    } else if (_countdown > 2) {
      bodyColor = Color.lerp(paint.color, const Color(0xFFFF0000), urgency)!;
    } else {
      // Lampeggia
      bodyColor = ((idlePhase * 8).toInt() % 2 == 0)
          ? const Color(0xFFFF0000)
          : const Color(0xFFFF6600);
    }

    // Cerchio principale
    canvas.drawCircle(Offset(cx, cy), r, Paint()..color = bodyColor);

    if (scale <= 1.01) {
      // Scudo attivazione (se non ancora attivato)
      if (!_activated) {
        final shieldAlpha = (_activationTimer / 2.0).clamp(0.0, 1.0);
        final shieldPaint = Paint()
          ..color = const Color(0xFF4488FF).withValues(alpha: shieldAlpha * 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawCircle(Offset(cx, cy), r * 1.3, shieldPaint);
      }

      // Anelli di pericolo (appaiono quando countdown < 4s)
      if (_activated && _countdown < 4) {
        for (int i = 0; i < 2; i++) {
          final ringProgress = ((idlePhase * 2 + i * 0.5) % 1.0);
          final ringR = r * 1.5 + ringProgress * _explosionRadius * 0.3;
          final ringAlpha = (1 - ringProgress) * urgency * 0.3;
          canvas.drawCircle(
            Offset(cx, cy), ringR,
            Paint()
              ..color = const Color(0xFFFF0000).withValues(alpha: ringAlpha)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1,
          );
        }
      }

      // Countdown numerico al centro
      if (_activated) {
        final countText = _countdown.ceil().toString();
        final tp = TextPainter(
          text: TextSpan(
            text: countText,
            style: TextStyle(
              color: _countdown < 3 ? const Color(0xFFFF0000) : const Color(0xFFFFFFFF),
              fontSize: r * 1.0,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
      } else {
        // Icona scudo durante attivazione
        final lockPaint = Paint()
          ..color = const Color(0xFF4488FF).withValues(alpha: 0.6);
        canvas.drawCircle(Offset(cx, cy), r * 0.3, lockPaint);
      }
    }
  }
}

import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../../data/constants.dart';
import 'enemy_base.dart';

/// SHIELD ENEMY - Avanza a scatti con lo scudo avanti.
/// Stati: APPROACH (lento) → LOCK_ON (pausa, mira) → CHARGE (dash veloce con scudo)
/// Lo scudo assorbe danni frontali. Vulnerabile dal retro e durante recovery.
class ShieldEnemy extends EnemyBase {
  double shieldHp = 5;
  double _shieldRegenTimer = 0;
  final double _shieldRegenDelay = 4.0;

  // State machine per il movimento a cariche
  _ShieldState _state = _ShieldState.approach;
  double _stateTimer = 0;
  Vector2 _chargeDir = Vector2.zero();
  static const double _approachSpeed = 60; // Lento
  static const double _chargeSpeed = 400; // Veloce!
  static const double _lockOnDuration = 1.0;
  static const double _chargeDuration = 0.6;
  static const double _recoverDuration = 1.2;
  static const double _chargeRange = 200; // Distanza per iniziare lock-on

  ShieldEnemy()
      : super(
          hp: 3,
          speed: 100,
          pointValue: 12,
          geomValue: 4,
          neonColor: NeonColors.purple,
          size: Vector2(24, 24),
        );

  @override
  void updateBehavior(double dt) {
    _stateTimer += dt;

    // Shield regen
    if (shieldHp <= 0) {
      _shieldRegenTimer += dt;
      if (_shieldRegenTimer >= _shieldRegenDelay) {
        shieldHp = 5;
        _shieldRegenTimer = 0;
      }
    }

    switch (_state) {
      case _ShieldState.approach:
        // Avvicinamento lento al player
        final velocity = seekPlayer(_approachSpeed);
        position += velocity * dt;
        // Quando abbastanza vicino, inizia lock-on
        if (distanceToPlayer < _chargeRange) {
          _state = _ShieldState.lockOn;
          _stateTimer = 0;
        }
        break;

      case _ShieldState.lockOn:
        // Fermo, si orienta verso il player (piccolo movimento)
        final velocity = seekPlayer(15);
        position += velocity * dt;
        _chargeDir = (playerPosition - position).normalized();
        // Dopo lock-on, carica!
        // Safety check: ensure _chargeDir is never zero when transitioning to charge
        if (_chargeDir.length == 0) {
          final fallback = playerPosition - position;
          _chargeDir = fallback.length > 0
              ? fallback.normalized()
              : Vector2(1, 0); // default rightward if player is exactly on top
        }
        if (_stateTimer >= _lockOnDuration) {
          _state = _ShieldState.charging;
          _stateTimer = 0;
        }
        break;

      case _ShieldState.charging:
        // Dash veloce nella direzione fissata al lock-on
        position += _chargeDir * _chargeSpeed * dt;
        // Fine carica
        if (_stateTimer >= _chargeDuration) {
          _state = _ShieldState.recovering;
          _stateTimer = 0;
        }
        break;

      case _ShieldState.recovering:
        // Fermo, vulnerabile
        if (_stateTimer >= _recoverDuration) {
          _state = _ShieldState.approach;
          _stateTimer = 0;
        }
        break;
    }
  }

  @override
  void takeDamage(double amount) {
    // Lo scudo assorbe i danni durante approach e charging (scudo avanti)
    if (shieldHp > 0 && _state != _ShieldState.recovering) {
      shieldHp -= amount;
      if (shieldHp < 0) shieldHp = 0;
      return;
    }

    super.takeDamage(amount);
  }

  @override
  void renderShape(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final r = 10 * scale;

    // Corpo - cerchio con anello interno
    canvas.drawCircle(Offset(cx, cy), r, paint);

    if (scale <= 1.01) {
      // Anello interno strutturale
      final ringPaint = Paint()
        ..color = paint.color.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8;
      canvas.drawCircle(Offset(cx, cy), r * 0.6, ringPaint);

      // Nucleo pulsante (più veloce durante lock-on)
      final pulseSpeed = _state == _ShieldState.lockOn ? 12.0 : 4.0;
      final pulse = 0.4 + math.sin(idlePhase * pulseSpeed) * 0.3;
      final corePaint = Paint()
        ..color = const Color(0xFFFFFFFF).withValues(alpha: pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawCircle(Offset(cx, cy), r * 0.25, corePaint);

      // Indicatore stato (flash durante charging)
      if (_state == _ShieldState.charging) {
        final rushPaint = Paint()
          ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
        canvas.drawCircle(Offset(cx, cy), r * 1.3, rushPaint);
      }
    }

    // Scudo frontale force field
    if (shieldHp > 0) {
      final toPlayer = (playerPosition - position);
      final angle = math.atan2(toPlayer.y, toPlayer.x);
      final shieldAlpha = (shieldHp / 5.0).clamp(0.0, 1.0);

      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(angle);

      // Glow dello scudo
      final glowPaint = Paint()
        ..color = NeonColors.purple.withValues(alpha: shieldAlpha * 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: 15 * scale),
        -math.pi / 3,
        math.pi * 2 / 3,
        false,
        glowPaint
          ..strokeWidth = 5
          ..style = PaintingStyle.stroke,
      );

      // Scudo principale (più largo durante charge)
      final shieldArc =
          _state == _ShieldState.charging ? math.pi * 0.9 : math.pi * 2 / 3;
      final shieldPaint = Paint()
        ..color = NeonColors.purple.withValues(alpha: shieldAlpha * 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5 * scale;
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: 14 * scale),
        -shieldArc / 2,
        shieldArc,
        false,
        shieldPaint,
      );

      // Segmenti HP scudo (puntini lungo l'arco)
      if (scale <= 1.01) {
        for (int i = 0; i < 5; i++) {
          final segAngle = -math.pi / 3 + i * (math.pi * 2 / 3) / 4;
          final segX = 14 * scale * math.cos(segAngle);
          final segY = 14 * scale * math.sin(segAngle);
          final segActive = i < shieldHp;
          final segPaint = Paint()
            ..color = segActive
                ? NeonColors.purple.withValues(alpha: 0.8)
                : NeonColors.purple.withValues(alpha: 0.15);
          canvas.drawCircle(Offset(segX, segY), 1.5, segPaint);
        }
      }

      canvas.restore();
    } else if (scale <= 1.01) {
      // Indicatore rigenerazione (cerchio tratteggiato debole)
      final regenProgress =
          (_shieldRegenTimer / _shieldRegenDelay).clamp(0.0, 1.0);
      if (regenProgress > 0) {
        final regenPaint = Paint()
          ..color = NeonColors.purple.withValues(alpha: regenProgress * 0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5;
        canvas.drawCircle(Offset(cx, cy), 14 * scale, regenPaint);
      }
    }
  }
}

enum _ShieldState { approach, lockOn, charging, recovering }

import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../../data/constants.dart';
import 'enemy_base.dart';
import '../projectiles.dart';

/// SHIELD ENEMY - Avanza a scatti con lo scudo avanti.
/// Stati: APPROACH (lento) → LOCK_ON (pausa, mira) → CHARGE (dash veloce con scudo)
/// Lo scudo assorbe danni frontali. Vulnerabile dal retro e durante recovery.
class ShieldEnemy extends EnemyBase {
  double shieldHp =
      10; // 2× scudo (richiesta utente: support più efficaci). Era 5.
  double _shieldRegenTimer = 0;
  final double _shieldRegenDelay = 4.0;

  // Paint caches: evita alloc per frame × N shield enemies.
  static final Paint _ringPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.8;
  static final Paint _shieldPaint = Paint()..style = PaintingStyle.stroke;
  static final Paint _segPaint = Paint();
  static final Paint _regenPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.5;

  // Throttle per repel bullets (ogni 3 frame, non ogni frame)
  int _repelFrameCounter = 0;

  // Cached toPlayer vector — updated in updateBehavior, reused in renderShape
  // per evitare un secondo `playerPosition - position` per frame (e tenere il
  // valore stabile tra logic e render).
  Vector2 _cachedToPlayer = Vector2.zero();

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
    // Cache toPlayer once per frame for reuse in renderShape (stable tra logic/render).
    _cachedToPlayer = playerPosition - position;

    // Shield regen
    if (shieldHp <= 0) {
      _shieldRegenTimer += dt;
      if (_shieldRegenTimer >= _shieldRegenDelay) {
        shieldHp = 10; // rigenera al massimo (2×, era 5)
        _shieldRegenTimer = 0;
      }
    }

    // GW Repulsor mechanic: respingi proiettili frontali attivamente (throttled: ogni 3 frame)
    _repelFrameCounter++;
    if (_repelFrameCounter >= 3 &&
        shieldHp > 0 &&
        _state != _ShieldState.recovering) {
      _repelFrameCounter = 0;
      _repelNearbyBullets();
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
        {
          final delta = playerPosition - position;
          if (delta.length2 > 1e-6) {
            _chargeDir = delta.normalized();
          } else {
            _chargeDir = Vector2(
              1,
              0,
            ); // default rightward if player is exactly on top
          }
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
          // Reset regen timer on entry to recovering: prima un ciclo di shield
          // a 0 hp che entrava in recovering vedeva un regen "lampo" residuo
          // (timer accumulato da approach/lockOn → rigenerava istantaneamente).
          _shieldRegenTimer = 0;
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

  /// GW:RE2 Repulsor mechanic: lo scudo respinge attivamente i proiettili del player.
  /// I proiettili rimbalzano via nella direzione opposta allo scudo.
  void _repelNearbyBullets() {
    final shieldDir = (playerPosition - position);
    if (shieldDir.length2 < 1e-6) return;
    final shieldNormal = shieldDir.normalized();

    // Colleziona i proiettili da respingere (senza rimuoverli durante l'iterazione)
    final toRepel = <PlayerBullet>[];
    const double kRepelRangeSq = 25.0 * 25.0;
    for (final child in game.world.children) {
      if (child is PlayerBullet) {
        final toBullet = child.position - position;
        final lenSq = toBullet.length2;
        if (lenSq > 1e-6 && lenSq < kRepelRangeSq) {
          final dot = toBullet.normalized().dot(shieldNormal);
          if (dot > 0.3) {
            toRepel.add(child);
          }
        }
      }
    }
    // Rimuovi fuori dal loop per evitare ConcurrentModificationError
    for (final bullet in toRepel) {
      final delta = bullet.position - position;
      if (delta.length2 < 1e-6) continue;
      final pushDir = delta.normalized();
      bullet.position += pushDir * 30;
      game.spawnExplosion(
        bullet.position,
        NeonColors.purple,
        radius: 8,
        particleCount: 3,
      );
      bullet.removeFromParent();
      shieldHp -= 0.5;
      if (shieldHp < 0) shieldHp = 0;
    }
  }

  @override
  void takeDamage(double amount, {bool isArea = false}) {
    // Lo scudo assorbe i danni durante approach e charging (scudo avanti)
    if (shieldHp > 0 && _state != _ShieldState.recovering) {
      shieldHp -= amount;
      if (shieldHp < 0) shieldHp = 0;
      return;
    }

    super.takeDamage(amount, isArea: isArea);
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
      _ringPaint.color = paint.color.withValues(alpha: 0.3);
      canvas.drawCircle(Offset(cx, cy), r * 0.6, _ringPaint);

      // Nucleo pulsante (più veloce durante lock-on, no blur)
      final pulseSpeed = _state == _ShieldState.lockOn ? 12.0 : 4.0;
      final pulse = 0.4 + math.sin(idlePhase * pulseSpeed) * 0.3;
      EnemyBase.detailPaint.color = const Color(
        0xFFFFFFFF,
      ).withValues(alpha: pulse);
      canvas.drawCircle(Offset(cx, cy), r * 0.25, EnemyBase.detailPaint);

      // Indicatore stato (flash durante charging, no blur)
      if (_state == _ShieldState.charging) {
        EnemyBase.detailPaint.color = const Color(
          0xFFFFFFFF,
        ).withValues(alpha: 0.4);
        canvas.drawCircle(Offset(cx, cy), r * 1.3, EnemyBase.detailPaint);
      }
    }

    // Scudo frontale force field
    if (shieldHp > 0) {
      // Usa il vettore cachato in updateBehavior — evita un secondo lookup
      // di playerPosition per frame e mantiene logic/render coerenti.
      final toPlayer = _cachedToPlayer;
      final angle = math.atan2(toPlayer.y, toPlayer.x);
      final shieldAlpha = (shieldHp / 10.0).clamp(0.0, 1.0);

      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(angle);

      // Glow dello scudo (no blur per performance)
      EnemyBase.detailPaint.color = NeonColors.purple.withValues(
        alpha: shieldAlpha * 0.3,
      );
      EnemyBase.detailPaint.strokeWidth = 5;
      EnemyBase.detailPaint.style = PaintingStyle.stroke;
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: 15 * scale),
        -math.pi / 3,
        math.pi * 2 / 3,
        false,
        EnemyBase.detailPaint,
      );
      EnemyBase.detailPaint.style = PaintingStyle.fill;

      // Scudo principale (più largo durante charge)
      final shieldArc = _state == _ShieldState.charging
          ? math.pi * 0.9
          : math.pi * 2 / 3;
      _shieldPaint.color = NeonColors.purple.withValues(
        alpha: shieldAlpha * 0.7,
      );
      _shieldPaint.strokeWidth = 2.5 * scale;
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: 14 * scale),
        -shieldArc / 2,
        shieldArc,
        false,
        _shieldPaint,
      );

      // Segmenti HP scudo (puntini lungo l'arco)
      if (scale <= 1.01) {
        for (int i = 0; i < 5; i++) {
          final segAngle = -math.pi / 3 + i * (math.pi * 2 / 3) / 4;
          final segX = 14 * scale * math.cos(segAngle);
          final segY = 14 * scale * math.sin(segAngle);
          // 5 segmenti = 10 HP (2 HP/seg). `i*2 < shieldHp` tiene acceso
          // l'ultimo segmento finché lo scudo non è davvero a 0 (prima
          // `i < shieldHp/2` lo spegneva già a 1 HP residuo).
          final segActive = i * 2 < shieldHp;
          _segPaint.color = segActive
              ? NeonColors.purple.withValues(alpha: 0.8)
              : NeonColors.purple.withValues(alpha: 0.15);
          canvas.drawCircle(Offset(segX, segY), 1.5, _segPaint);
        }
      }

      canvas.restore();
    } else if (scale <= 1.01) {
      // Indicatore rigenerazione (cerchio tratteggiato debole)
      final regenProgress = (_shieldRegenTimer / _shieldRegenDelay).clamp(
        0.0,
        1.0,
      );
      if (regenProgress > 0) {
        _regenPaint.color = NeonColors.purple.withValues(
          alpha: regenProgress * 0.2,
        );
        canvas.drawCircle(Offset(cx, cy), 14 * scale, _regenPaint);
      }
    }
  }
}

enum _ShieldState { approach, lockOn, charging, recovering }

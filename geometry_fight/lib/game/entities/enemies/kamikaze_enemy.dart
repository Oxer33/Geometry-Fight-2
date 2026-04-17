import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../../data/constants.dart';
import 'enemy_base.dart';

enum KamikazeState { idle, charging, rushing, recovering }

class KamikazeEnemy extends EnemyBase {
  KamikazeState _state = KamikazeState.idle;
  double _stateTimer = 1.5;
  Vector2? _rushDirection;
  double _flashRate = 2;
  // Direzione forzata quando il kamikaze è spawnato in formazione dal bordo.
  // Se settata, _pickCardinalDirection la restituisce invece di targettare il player.
  Vector2? forcedRushDirection;

  // Paint cache statica — evita allocazione per frame × N kamikazes.
  // Il colore/strokeWidth viene mutato su ogni drawCall.
  static final Paint _ringPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;
  static final Paint _trailPaint = Paint();
  static final Paint _spikePaint = Paint();
  static final Paint _exhaustPaint = Paint();
  static final Paint _linePaint = Paint()..strokeWidth = 0.6;
  static final Paint _coreOuterPaint = Paint();
  static final Paint _coreInnerPaint = Paint();
  static final Paint _eyePaint = Paint();

  KamikazeEnemy()
      : super(
          hp: 1,
          speed: 500,
          pointValue: 4,
          geomValue: 2,
          neonColor: NeonColors.red,
          size: Vector2(16, 22),
        );

  @override
  void updateBehavior(double dt) {
    _stateTimer -= dt;

    switch (_state) {
      case KamikazeState.idle:
        if (_stateTimer <= 0) {
          _state = KamikazeState.charging;
          _stateTimer = 1.5;
          _flashRate = 2;
        }
      case KamikazeState.charging:
        // Accelerating flash to telegraph
        _flashRate += dt * 15;
        if (_stateTimer <= 0) {
          _state = KamikazeState.rushing;
          // Sceglie SOLO un asse cardinale: sx/dx o su/giù
          _rushDirection = _pickCardinalDirection();
          _stateTimer = 1.2;
        }
      case KamikazeState.rushing:
        position += _rushDirection! * speed * dt;
        // Bounds check: se esce dall'arena, inverti direzione per tornare
        if (position.x < -50 || position.x > arenaWidth + 50 ||
            position.y < -50 || position.y > arenaHeight + 50) {
          _state = KamikazeState.recovering;
          _stateTimer = 0.8;
        }
        if (_stateTimer <= 0) {
          _state = KamikazeState.recovering;
          _stateTimer = 0.8;
        }
      case KamikazeState.recovering:
        if (_stateTimer <= 0) {
          _state = KamikazeState.charging;
          _stateTimer = 1.5;
          _flashRate = 2;
        }
    }
  }

  /// Se settata `forcedRushDirection` (kamikaze spawnato in formazione dal bordo),
  /// usa quella direzione SOLO per il primo rush — dopo viene consumata, così i
  /// charge successivi riprendono a puntare il player (evita che la schiera,
  /// una volta arrivata al bordo opposto, resti incastrata caricando fuori arena).
  Vector2 _pickCardinalDirection() {
    if (forcedRushDirection != null) {
      final dir = forcedRushDirection!.clone();
      forcedRushDirection = null; // consume: i rush successivi targettano il player
      return dir;
    }
    final diff = playerPosition - position;
    // Sceglie l'asse con la distanza maggiore
    if (diff.x.abs() >= diff.y.abs()) {
      // Asse orizzontale
      return Vector2(diff.x > 0 ? 1 : -1, 0);
    } else {
      // Asse verticale
      return Vector2(0, diff.y > 0 ? 1 : -1);
    }
  }

  @override
  void renderShape(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final w = 7 * scale;
    final h = 11 * scale;

    // Direzione di puntamento
    final angle = _rushDirection != null
        ? math.atan2(_rushDirection!.y, _rushDirection!.x) + math.pi / 2
        : math.atan2(playerPosition.y - position.y,
                playerPosition.x - position.x) +
            math.pi / 2;

    // === EFFETTI SPECIALI PER STATO (solo layer principale) ===
    if (scale <= 1.01) {
      // Anelli di carica durante charging
      if (_state == KamikazeState.charging) {
        final chargeProgress = 1.0 - (_stateTimer / 1.5).clamp(0.0, 1.0);
        for (int i = 0; i < 2; i++) {
          final ringR = 20 - chargeProgress * 12 + i * 8;
          final ringAlpha = chargeProgress * 0.4 - i * 0.1;
          if (ringAlpha > 0) {
            _ringPaint.color = const Color(0xFFFF4400).withValues(alpha: ringAlpha);
            canvas.drawCircle(Offset(cx, cy), ringR, _ringPaint);
          }
        }
      }

      // Scia di fuoco durante il rush (senza blur per performance)
      if (_state == KamikazeState.rushing && _rushDirection != null) {
        final trailDir = -_rushDirection!;
        for (int i = 1; i <= 4; i++) {
          final trailAlpha = 0.4 - i * 0.09;
          final trailSize = 3.0 - i * 0.55;
          if (trailAlpha > 0 && trailSize > 0) {
            _trailPaint.color = const Color(0xFFFF6600).withValues(alpha: trailAlpha);
            canvas.drawCircle(
              Offset(cx + trailDir.x * i * 7, cy + trailDir.y * i * 7),
              trailSize, _trailPaint,
            );
          }
        }
      }
    }

    // Flash bianco durante charging (accelera)
    if (_state == KamikazeState.charging) {
      if ((idlePhase * _flashRate).toInt() % 2 == 0) {
        paint.color = const Color(0xFFFFFFFF);
      }
    }
    // Rosso brillante durante il rush
    if (_state == KamikazeState.rushing && scale <= 1.01) {
      paint.color = const Color(0xFFFF2200);
    }

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(angle);

    // === CORPO PRINCIPALE — freccia slanciata più aggressiva ===
    final path = Path()
      ..moveTo(0, -h * 1.15)                  // punta affilata più lunga
      ..lineTo(w * 0.55, -h * 0.35)
      ..lineTo(w, h * 0.55)                   // ala destra
      ..lineTo(w * 0.45, h * 0.35)
      ..lineTo(w * 0.25, h * 0.2)
      ..lineTo(-w * 0.25, h * 0.2)
      ..lineTo(-w * 0.45, h * 0.35)
      ..lineTo(-w, h * 0.55)                  // ala sinistra
      ..lineTo(-w * 0.55, -h * 0.35)
      ..close();
    canvas.drawPath(path, paint);

    // === SPINE LATERALI (solo layer principale) ===
    if (scale <= 1.01) {
      // Spine aggressive sui fianchi — aumentano la sensazione di minaccia
      final spikePath = Path()
        ..moveTo(w * 0.55, -h * 0.1)
        ..lineTo(w * 1.15, -h * 0.25)
        ..lineTo(w * 0.8, h * 0.1)
        ..close()
        ..moveTo(-w * 0.55, -h * 0.1)
        ..lineTo(-w * 1.15, -h * 0.25)
        ..lineTo(-w * 0.8, h * 0.1)
        ..close();
      _spikePaint.color = paint.color;
      canvas.drawPath(spikePath, _spikePaint);

      // Doppio propulsore posteriore (due esaustori)
      final exhaustColor = _state == KamikazeState.rushing
          ? const Color(0xFFFF8800)
          : const Color(0xFFFF4400);
      final exhaustAlpha = _state == KamikazeState.rushing ? 0.9 : 0.5;
      _exhaustPaint.color = exhaustColor.withValues(alpha: exhaustAlpha);
      canvas.drawCircle(Offset(-w * 0.45, h * 0.4), 1.6, _exhaustPaint);
      canvas.drawCircle(Offset(w * 0.45, h * 0.4), 1.6, _exhaustPaint);

      // Linea centrale di rinforzo (chiglia) + dettagli ala
      _linePaint.color = paint.color.withValues(alpha: 0.35);
      canvas.drawLine(Offset(0, -h * 0.9), Offset(0, h * 0.35), _linePaint);
      canvas.drawLine(Offset(w * 0.35, h * 0.1), Offset(w * 0.75, h * 0.35), _linePaint);
      canvas.drawLine(Offset(-w * 0.35, h * 0.1), Offset(-w * 0.75, h * 0.35), _linePaint);

      // Nucleo pulsante — più evidente durante charging/rushing
      if (_state == KamikazeState.charging || _state == KamikazeState.rushing) {
        final glowAlpha = _state == KamikazeState.rushing ? 0.9 : 0.5;
        final pulseScale = _state == KamikazeState.charging
            ? 1.0 + math.sin(idlePhase * _flashRate * 2) * 0.25
            : 1.0;
        _coreOuterPaint.color = const Color(0xFFFF4400).withValues(alpha: glowAlpha * 0.5);
        canvas.drawCircle(Offset(0, -h * 0.15), 4 * pulseScale, _coreOuterPaint);
        _coreInnerPaint.color = const Color(0xFFFFAA00).withValues(alpha: glowAlpha);
        canvas.drawCircle(Offset(0, -h * 0.15), 2 * pulseScale, _coreInnerPaint);
      } else {
        // Occhio rosso minaccioso in idle
        _eyePaint.color = const Color(0xFFFF2200).withValues(alpha: 0.7);
        canvas.drawCircle(Offset(0, -h * 0.15), 1.5, _eyePaint);
      }
    }

    canvas.restore();
  }
}

import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../../data/constants.dart';
import '../../../data/wave_configs.dart';
import 'boss_base.dart';
import '../projectiles.dart';

class TheGridBoss extends BossBase {
  double _attackTimer = 0;
  double _mineTimer = 4;
  double _droneTimer = 2;
  double _laserAngle = 0;
  bool _laserActive = false;
  double _laserTimer = 0;
  double _laserCooldown = 6.0; // Cooldown tra laser sweep
  // Wind-up telegraph (richiesta utente): laser mostra linea dim per 1.2s
  // prima di diventare letale → player può schivare.
  double _laserTelegraphTimer = 0;
  static const double _kLaserTelegraphDuration = 1.2;
  int _patternIndex = 0;
  double _gridPhase = 0;

  // Rng + Paint caches per evitare alloc per frame.
  static final math.Random _rng = math.Random();
  static final Paint _coreGlowPaint = Paint();
  static final Paint _corePaint = Paint();
  static final Paint _centerWhitePaint = Paint();
  static final Paint _cornerPaint = Paint();
  static final Paint _phaseDotPaint = Paint();
  static final Paint _warnPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;
  static final Paint _laserPaint = Paint();
  static final Paint _laserWhitePaint = Paint();

  TheGridBoss()
      : super(
          // +50% HP secondo passaggio (era 500 → 750 → 1125) —
          // utente: "the grid deve avere il 50% in piu degli hp".
          hp: 1125,
          bossName: 'THE GRID',
          pointValue: 5000,
          neonColor: NeonColors.white,
          size: Vector2(200, 200),
        );

  // TheGrid è BIANCO → mob bianchi/neutri (drone + decoy).
  @override
  List<EnemyType> get colorMatchedMinions =>
      const [EnemyType.drone, EnemyType.decoy];

  @override
  int getPhase() {
    if (healthPercent > 0.6) return 0;
    if (healthPercent > 0.3) return 1;
    return 2;
  }

  @override
  void updateBoss(double dt) {
    _gridPhase += dt;
    final speed = 60.0 * (1 + currentPhase * 0.5);

    // Move towards player slowly
    final dir = (playerPosition - position);
    // NaN guard: float comparison tighter (0.001) evita normalize inf.
    if (dir.length > 0.001) {
      position += dir.normalized() * speed * dt;
    }

    // Attack patterns
    _attackTimer -= dt;
    if (_attackTimer <= 0) {
      final interval = currentPhase == 2 ? 0.8 : currentPhase == 1 ? 1.2 : 2.0;
      _attackTimer = interval;
      _firePattern();
    }

    // Phase 1+: Mines
    _mineTimer -= dt;
    if (_mineTimer <= 0 && currentPhase >= 1) {
      _mineTimer = 4;
      game.spawnEnemy(EnemyType.mine, position + Vector2(
        (_rng.nextDouble() - 0.5) * 150,
        (_rng.nextDouble() - 0.5) * 150,
      ));
    }

    // Phase 2+: Drones
    if (currentPhase >= 1) {
      _droneTimer -= dt;
      if (_droneTimer <= 0) {
        _droneTimer = 2;
        for (int i = 0; i < 2; i++) {
          game.spawnEnemy(EnemyType.drone, position + Vector2(
            (_rng.nextDouble() - 0.5) * 100,
            (_rng.nextDouble() - 0.5) * 100,
          ));
        }
      }
    }

    // Phase 3: Laser sweep (con wind-up telegraph — richiesta utente)
    if (currentPhase >= 2 && _laserActive) {
      _laserAngle += dt * math.pi * 2 / 3; // Full rotation in 3s
      _laserTimer -= dt;
      if (_laserTimer <= 0) {
        _laserActive = false;
        // BUG fix: reset cooldown al termine dello sweep. Senza questo
        // _laserCooldown restava ≤0 → il telegraph ri-partiva al frame
        // successivo (loop laser → telegraph → laser infinito).
        _laserCooldown = 6.0;
      }

      // Damage player if in laser path (solo quando ATTIVO, non wind-up).
      final laserDir = Vector2(math.cos(_laserAngle), math.sin(_laserAngle));
      final toPlayer = playerPosition - position;
      final dot = toPlayer.dot(laserDir);
      if (dot > 0) {
        final perpDist = (toPlayer - laserDir * dot).length;
        if (perpDist < 20) {
          game.player.takeDamage();
        }
      }
    }

    // Wind-up telegraph: angolo bloccato, linea dim visibile, NO danno.
    if (_laserTelegraphTimer > 0) {
      _laserTelegraphTimer -= dt;
      if (_laserTelegraphTimer <= 0) {
        // Fire: attiva sweep vero.
        _laserActive = true;
        _laserTimer = 3.0;
      }
    }

    // Activate laser telegraph periodically in phase 3
    if (currentPhase >= 2 && !_laserActive && _laserTelegraphTimer <= 0) {
      _laserCooldown -= dt;
      if (_laserCooldown <= 0) {
        _laserCooldown = 6.0;
        _laserTelegraphTimer = _kLaserTelegraphDuration;
        _laserAngle = math.atan2(
            playerPosition.y - position.y, playerPosition.x - position.x);
      }
    }
  }

  void _firePattern() {
    _patternIndex = (_patternIndex + 1) % 4;

    switch (_patternIndex) {
      case 0: // Cross
        for (int i = 0; i < 4; i++) {
          final angle = i * math.pi / 2;
          _shootBullet(angle);
        }
      case 1: // Diagonal
        for (int i = 0; i < 4; i++) {
          final angle = i * math.pi / 2 + math.pi / 4;
          _shootBullet(angle);
        }
      case 2: // Spiral
        for (int i = 0; i < 8; i++) {
          final angle = i * math.pi / 4 + _gridPhase;
          _shootBullet(angle);
        }
      case 3: // Spread towards player
        final toPlayer =
            math.atan2(playerPosition.y - position.y, playerPosition.x - position.x);
        for (int i = -3; i <= 3; i++) {
          _shootBullet(toPlayer + i * 0.15);
        }
    }
  }

  void _shootBullet(double angle) {
    final dir = Vector2(math.cos(angle), math.sin(angle));
    final bullet = EnemyBullet(direction: dir, speed: 250, color: NeonColors.white);
    bullet.position = position.clone();
    game.world.add(bullet);
  }

  @override
  void renderBoss(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final s = size.x / 2 * scale * 0.9;

    // Colore per fase (bianco → giallo → rosso)
    Color phaseColor;
    if (currentPhase == 0) {
      phaseColor = NeonColors.white;
    } else if (currentPhase == 1) {
      phaseColor = NeonColors.yellow;
    } else {
      phaseColor = NeonColors.red;
    }

    // Se il paint è per il glow, usa alpha ridotto
    final isGlow = scale > 1.1;
    if (!isGlow) paint.color = phaseColor;

    // Quadrato esterno principale
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 3 * scale;
    canvas.drawRect(
      Rect.fromCenter(center: Offset(cx, cy), width: s * 2, height: s * 2),
      paint,
    );

    // Griglia interna animata
    final gridLines = 4 + currentPhase; // Più linee nelle fasi avanzate
    for (int i = 1; i < gridLines; i++) {
      final t = i / gridLines;
      final wobble = math.sin(_gridPhase * 2 + i * 0.5) * 3; // Oscillazione
      final offset = -s + s * 2 * t;
      canvas.drawLine(
        Offset(cx - s, cy + offset + wobble),
        Offset(cx + s, cy + offset + wobble), paint);
      canvas.drawLine(
        Offset(cx + offset + wobble, cy - s),
        Offset(cx + offset + wobble, cy + s), paint);
    }

    paint.style = PaintingStyle.fill;

    if (scale <= 1.01) {
      // Nucleo centrale pulsante (più grande nelle fasi avanzate)
      final pulseR = s * (0.15 + currentPhase * 0.05) + math.sin(_gridPhase * 3) * 5;
      _coreGlowPaint.color = phaseColor.withValues(alpha: 0.2);
      canvas.drawCircle(Offset(cx, cy), pulseR * 1.5, _coreGlowPaint);
      _corePaint.color = phaseColor.withValues(alpha: 0.5);
      canvas.drawCircle(Offset(cx, cy), pulseR, _corePaint);
      // Centro bianco
      _centerWhitePaint.color = const Color(0xFFFFFFFF).withValues(alpha: 0.6);
      canvas.drawCircle(Offset(cx, cy), pulseR * 0.4, _centerWhitePaint);

      // Punti luminosi ai 4 angoli del quadrato
      final cornerGlow = 0.4 + math.sin(_gridPhase * 4) * 0.3;
      _cornerPaint.color = phaseColor.withValues(alpha: cornerGlow);
      canvas.drawCircle(Offset(cx - s, cy - s), 4, _cornerPaint);
      canvas.drawCircle(Offset(cx + s, cy - s), 4, _cornerPaint);
      canvas.drawCircle(Offset(cx + s, cy + s), 4, _cornerPaint);
      canvas.drawCircle(Offset(cx - s, cy + s), 4, _cornerPaint);

      // Indicatore fase (punti sotto il boss)
      _phaseDotPaint.color = phaseColor;
      for (int i = 0; i <= currentPhase; i++) {
        canvas.drawCircle(
          Offset(cx - 8 + i * 8.0, cy + s + 12), 2, _phaseDotPaint);
      }
    }

    // Laser telegraph (wind-up visibile, no danno)
    if (_laserTelegraphTimer > 0) {
      // Blink per visibilità (2x per sec → 6 blink in 1.2s window).
      final blinkPhase = (_laserTelegraphTimer * 4) % 1.0;
      final blinkAlpha = blinkPhase < 0.5 ? 0.8 : 0.3;
      _warnPaint.color = NeonColors.laserRed.withValues(alpha: blinkAlpha * 0.55);
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(_laserAngle);
      // Linea sottile dim: telegraph
      canvas.drawLine(const Offset(0, 0), const Offset(1500, 0), _warnPaint);
      // Ticks di avviso lungo la linea
      for (double x = 80; x < 1500; x += 120) {
        canvas.drawLine(Offset(x, -4), Offset(x, 4), _warnPaint);
      }
      canvas.restore();
    }

    // Laser beam ATTIVO (fase 2+)
    if (_laserActive) {
      _laserPaint.color = NeonColors.laserRed.withValues(alpha: 0.6);
      _laserPaint.style = PaintingStyle.fill;
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(_laserAngle);
      // Glow laser
      canvas.drawRect(Rect.fromLTWH(0, -6, 1500, 12), _laserPaint);
      // Core laser
      _laserPaint.color = NeonColors.laserRed;
      canvas.drawRect(Rect.fromLTWH(0, -2, 1500, 4), _laserPaint);
      // Centro bianco del laser
      _laserWhitePaint.color = const Color(0xFFFFFFFF).withValues(alpha: 0.5);
      canvas.drawRect(Rect.fromLTWH(0, -1, 1500, 2), _laserWhitePaint);
      canvas.restore();
    }
  }
}

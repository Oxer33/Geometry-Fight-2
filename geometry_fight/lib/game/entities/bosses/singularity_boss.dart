import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../../data/constants.dart';
import '../../../data/wave_configs.dart';
import 'boss_base.dart';
import '../projectiles.dart';

class SingularityBoss extends BossBase {
  double _pulseTimer = 3;
  double _pullTimer = 3.33; // +50% frequenza (era 5, richiesta utente)
  double _cloneTimer = 8;
  double _vortexTimer = 12;
  double _blackRainTimer = 4.0;
  bool _pulling = false;

  /// Clamp player to arena/tunnel bounds dopo una pull. Evita di
  /// trascinarlo fuori dalle mura.
  void _clampPlayerToBounds() {
    if (game.isTunnelMode) {
      final camY = game.camera.viewfinder.position.y;
      final halfH = game.tunnelHeight / 2;
      game.player.position.y = game.player.position.y
          .clamp(camY - halfH + 10, camY + halfH - 10);
    } else {
      game.player.position.x = game.player.position.x.clamp(10.0, arenaWidth - 10);
      game.player.position.y = game.player.position.y.clamp(10.0, arenaHeight - 10);
    }
  }
  double _pullDuration = 0;
  double _phase = 0;
  final List<Vector2> _vortexPositions = [];

  SingularityBoss()
      : super(
          hp: 1800, // +50% (era 1200, richiesta utente)
          bossName: 'SINGULARITY',
          pointValue: 12000,
          neonColor: NeonColors.green,
          size: Vector2(140, 140),
        );

  // Singularity è VERDE → mob verdi (snake + pulsar + weaver).
  @override
  List<EnemyType> get colorMatchedMinions =>
      const [EnemyType.snake, EnemyType.pulsar, EnemyType.weaver];

  @override
  int getPhase() {
    if (healthPercent > 0.6) return 0;
    if (healthPercent > 0.3) return 1;
    return 2;
  }

  @override
  void updateBoss(double dt) {
    _phase += dt;

    // Slow movement
    final dir = (playerPosition - position);
    if (dir.length > 300) {
      position += dir.normalized() * 50 * dt;
    }

    // Pulse attack
    _pulseTimer -= dt;
    if (_pulseTimer <= 0) {
      _pulseTimer = 3.0 - currentPhase * 0.5;
      _doPulse();
    }

    // Pull attack — forza +50% (150→225) e durata +50% (2.0→3.0s) richiesta utente.
    _pullTimer -= dt;
    if (_pullTimer <= 0 && !_pulling) {
      _pulling = true;
      _pullDuration = 3.0; // +50% da 2.0
      _pullTimer = 3.33; // +50% frequenza (era 5.0, richiesta utente)
    }

    if (_pulling) {
      // Pull player verso il boss. Skip durante iframe post-hit (UX).
      final pullDir = (position - playerPosition);
      if (pullDir.length > 20 &&
          !game.player.isInvincible &&
          game.player.lives > 0) {
        // Forza 225 (era 150, +50%).
        game.player.position += pullDir.normalized() * 225 * dt;
        // Clamp post-pull: evita di trascinare il player fuori arena/tunnel.
        _clampPlayerToBounds();
      }
      _pullDuration -= dt;
      if (_pullDuration <= 0) _pulling = false;
    }

    // Clone attack (phase 1+)
    if (currentPhase >= 1) {
      _cloneTimer -= dt;
      if (_cloneTimer <= 0) {
        _cloneTimer = 8.0;
        _spawnClones();
      }
    }

    // Vortex (phase 2)
    if (currentPhase >= 2) {
      _vortexTimer -= dt;
      if (_vortexTimer <= 0) {
        _vortexTimer = 12.0;
        _createVortex();
      }

    }

    // Black rain (phase 2, periodic)
    if (currentPhase >= 2) {
      _blackRainTimer -= dt;
      if (_blackRainTimer <= 0) {
        _blackRainTimer = 4.0;
        _blackRain();
      }
    }
  }

  void _doPulse() {
    // Push wave
    for (int i = 0; i < 16; i++) {
      final angle = i * math.pi * 2 / 16;
      final dir = Vector2(math.cos(angle), math.sin(angle));
      final bullet = EnemyBullet(direction: dir, speed: 200, color: NeonColors.green);
      bullet.position = position.clone();
      game.world.add(bullet);
    }
  }

  void _spawnClones() {
    for (int i = 0; i < 2; i++) {
      final offset = Vector2(
        (math.Random().nextDouble() - 0.5) * 400,
        (math.Random().nextDouble() - 0.5) * 400,
      );
      // Spawn a weak drone that looks like the boss (simplified as special drone)
      game.spawnEnemy(EnemyType.drone, position + offset);
    }
  }

  void _createVortex() {
    // Cap: non creare vortici se troppi nemici
    if (game.enemyCount >= 20) return;
    _vortexPositions.clear();
    for (int i = 0; i < 4; i++) {
      final angle = i * math.pi / 2;
      _vortexPositions.add(Vector2(math.cos(angle) * 200, math.sin(angle) * 200));
    }
    // Spawn black holes
    for (final vPos in _vortexPositions) {
      game.spawnEnemy(EnemyType.blackHole, position + vPos);
    }
  }

  void _blackRain() {
    for (int i = 0; i < 5; i++) {
      final x = playerPosition.x + (math.Random().nextDouble() - 0.5) * 400;
      final bullet = EnemyBullet(
        direction: Vector2(0, 1),
        speed: 300,
        color: NeonColors.darkRed,
      );
      bullet.position = Vector2(x, playerPosition.y - 500);
      game.world.add(bullet);
    }
  }

  // Paint cache FX
  static final _darkPaint = Paint()..color = const Color(0xFF050505);
  static final _greenGlowPaint = Paint();
  static final _accretionPaint = Paint()..style = PaintingStyle.stroke;
  static final _lensingPaint = Paint()..style = PaintingStyle.stroke;
  static final _edgePaint = Paint()..style = PaintingStyle.stroke;
  static final _pullPaint = Paint()..style = PaintingStyle.stroke;
  static final _innerCorePaint = Paint();

  @override
  void renderBoss(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final r = 55 * scale;

    // ─── GREEN RADIOACTIVE GLOW (alone esterno pulsante) ───
    final glowIntensity = 0.4 + math.sin(_phase * 2) * 0.15;
    _greenGlowPaint.color =
        NeonColors.green.withValues(alpha: glowIntensity);
    canvas.drawCircle(Offset(cx, cy), r * 1.7, _greenGlowPaint);

    // ─── LENSING RINGS (distorsione gravitazionale — 4 stroke) ───
    if (scale <= 1.01) {
      for (int i = 0; i < 4; i++) {
        final ringR = r * (1.25 + i * 0.18);
        final ringAlpha = 0.25 - i * 0.05;
        _lensingPaint.color = const Color(0xFF88FFBB)
            .withValues(alpha: ringAlpha);
        _lensingPaint.strokeWidth = 1.0;
        canvas.drawCircle(Offset(cx, cy), ringR, _lensingPaint);
      }
    }

    // ─── ACCRETION DISK (3 bracci a spirale rotanti) ───
    if (scale <= 1.01) {
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(_phase * 0.8);
      for (int arm = 0; arm < 3; arm++) {
        final armOffset = arm * math.pi * 2 / 3;
        final armPath = Path();
        const segCount = 24;
        for (int s = 0; s <= segCount; s++) {
          final t = s / segCount;
          final spiralR = r * (0.9 + t * 0.9);
          final spiralAngle =
              armOffset + t * math.pi * 3.5 + _phase * 0.4;
          final sx = spiralR * math.cos(spiralAngle);
          final sy = spiralR * math.sin(spiralAngle);
          if (s == 0) {
            armPath.moveTo(sx, sy);
          } else {
            armPath.lineTo(sx, sy);
          }
        }
        _accretionPaint.color = const Color(0xFF00FF88)
            .withValues(alpha: 0.35 + math.sin(_phase * 2 + arm) * 0.15);
        _accretionPaint.strokeWidth = 2;
        canvas.drawPath(armPath, _accretionPaint);
      }
      canvas.restore();
    }

    // ─── EVENT HORIZON (sfera nera assorbente) ───
    canvas.drawCircle(Offset(cx, cy), r, _darkPaint);

    // ─── BORDO NEON DEL CORPO ───
    _edgePaint.color = paint.color;
    _edgePaint.strokeWidth = 3 * scale;
    canvas.drawCircle(Offset(cx, cy), r, _edgePaint);

    // ─── INNER CORE (occhio verde pulsante) ───
    if (scale <= 1.01) {
      final corePulse = 0.4 + math.sin(_phase * 5) * 0.3;
      _innerCorePaint.color =
          const Color(0xFF00FF88).withValues(alpha: corePulse);
      canvas.drawCircle(Offset(cx, cy), r * 0.25 * corePulse, _innerCorePaint);
      _innerCorePaint.color =
          const Color(0xFFFFFFFF).withValues(alpha: corePulse);
      canvas.drawCircle(Offset(cx, cy), r * 0.08, _innerCorePaint);
    }

    // ─── PULL INDICATOR (ring viola espansivi) ───
    if (_pulling) {
      for (int ring = 0; ring < 3; ring++) {
        final ringR = r + 20 + ring * 30 + (_pullDuration * 50);
        _pullPaint.color =
            NeonColors.purple.withValues(alpha: 0.35 - ring * 0.1);
        _pullPaint.strokeWidth = 2;
        canvas.drawCircle(Offset(cx, cy), ringR, _pullPaint);
      }
    }
  }
}

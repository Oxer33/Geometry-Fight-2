import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../../data/constants.dart';
import '../../../data/wave_configs.dart';
import 'boss_base.dart';

class SwarmMotherBoss extends BossBase {
  double _spawnTimer = 3;
  double _laserAngle = 0;
  bool _laserActive = false;
  double _laserTimer = 0;
  double _laserCooldown = 8.0;
  // Wind-up telegraph (richiesta utente): linea dim 1.2s prima del sweep letale.
  double _laserTelegraphTimer = 0;
  static const double _kLaserTelegraphDuration = 1.2;
  double _phase = 0;
  bool _split = false;
  Vector2? _halfOffset;

  SwarmMotherBoss()
      : super(
          hp: 2000,
          bossName: 'THE SWARM MOTHER',
          pointValue: 20000,
          neonColor: NeonColors.orange,
          size: Vector2(180, 180),
        );

  // SwarmMother è ARANCIONE → mob arancio/rossi (kamikaze + splitter + swarmDrone).
  @override
  List<EnemyType> get colorMatchedMinions =>
      const [EnemyType.kamikaze, EnemyType.splitter, EnemyType.swarmDrone];

  @override
  int getPhase() {
    if (healthPercent > 0.7) return 0;
    if (healthPercent > 0.4) return 1;
    if (healthPercent > 0.2) return 2;
    return 3;
  }

  @override
  void onPhaseChange(int phase) {
    if (phase == 1) _split = true;
    if (phase == 2) _split = false;
    if (phase == 3) {
      // Berserk - spawn black hole
      final bhCenter = game.isTunnelMode
          ? game.camera.viewfinder.position
          : Vector2(arenaWidth / 2, arenaHeight / 2);
      game.spawnEnemy(EnemyType.blackHole, bhCenter);
    }
  }

  @override
  void updateBoss(double dt) {
    _phase += dt;

    final speed = currentPhase == 3 ? 180.0 : 60.0;
    final dir = (playerPosition - position);
    if (dir.length > 150) {
      position += dir.normalized() * speed * dt;
    }

    // Split movement
    if (_split) {
      _halfOffset = Vector2(math.sin(_phase * 2) * 100, math.cos(_phase * 2) * 100);
    } else {
      _halfOffset = null;
    }

    // Spawn enemies
    _spawnTimer -= dt;
    if (_spawnTimer <= 0) {
      switch (currentPhase) {
        case 0:
          _spawnTimer = 4;
          for (int i = 0; i < 6; i++) {
            game.spawnEnemy(EnemyType.drone, position + Vector2(
              (math.Random().nextDouble() - 0.5) * 200,
              (math.Random().nextDouble() - 0.5) * 200,
            ));
          }
        case 1:
          _spawnTimer = 3;
          for (int i = 0; i < 5; i++) {
            game.spawnEnemy(EnemyType.drone, position + Vector2(
              (math.Random().nextDouble() - 0.5) * 150,
              (math.Random().nextDouble() - 0.5) * 150,
            ));
          }
        case 2:
          _spawnTimer = 2;
          game.spawnEnemy(EnemyType.splitter, position + Vector2(50, 0));
          game.spawnEnemy(EnemyType.kamikaze, position + Vector2(-50, 0));
          game.spawnEnemy(EnemyType.kamikaze, position + Vector2(0, 50));
        case 3:
          _spawnTimer = 1.5;
          for (int i = 0; i < 5; i++) {
            game.spawnEnemy(EnemyType.kamikaze, position + Vector2(
              (math.Random().nextDouble() - 0.5) * 100,
              (math.Random().nextDouble() - 0.5) * 100,
            ));
          }
      }
    }

    // Laser sweep (phase 2+) — wind-up telegraph 1.2s prima del danno.
    if (currentPhase >= 2) {
      // Countdown telegraph → fire.
      if (_laserTelegraphTimer > 0) {
        _laserTelegraphTimer -= dt;
        if (_laserTelegraphTimer <= 0) {
          _laserActive = true;
          _laserTimer = 3.0;
        }
      }

      // Activate telegraph su cooldown (non parte subito il laser vero).
      if (!_laserActive && _laserTelegraphTimer <= 0) {
        _laserCooldown -= dt;
        if (_laserCooldown <= 0) {
          _laserCooldown = 8.0;
          _laserTelegraphTimer = _kLaserTelegraphDuration;
          _laserAngle = math.atan2(
              playerPosition.y - position.y, playerPosition.x - position.x);
        }
      }

      if (_laserActive) {
        _laserAngle += dt * math.pi * 2 / 3;
        _laserTimer -= dt;
        if (_laserTimer <= 0) _laserActive = false;

        // Damage player (solo laser ATTIVO, non durante telegraph).
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
    }
  }

  // Signature FX paints
  static final _eggClusterPaint = Paint();
  static final _veinPaint = Paint()..style = PaintingStyle.stroke;
  static final _spawnBurstPaint = Paint()..style = PaintingStyle.stroke;
  static final _berserkPaint = Paint();
  static final _laserGlowPaint = Paint();
  static final _laserCorePaint = Paint();

  @override
  void renderBoss(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;

    // ─── SPAWN BURST: ring pulsante pre-spawn nemici ───
    if (scale <= 1.01 && _spawnTimer < 0.4) {
      final burstT = 1.0 - _spawnTimer.clamp(0.0, 0.4) / 0.4;
      _spawnBurstPaint.color =
          NeonColors.orange.withValues(alpha: burstT * 0.6);
      _spawnBurstPaint.strokeWidth = 2 + burstT * 4;
      canvas.drawCircle(Offset(cx, cy), 110 * scale * (0.6 + burstT * 0.5),
          _spawnBurstPaint);
    }

    // ─── ORBITANTE EGG CLUSTER: 8 uova che ruotano attorno ───
    if (scale <= 1.01) {
      for (int i = 0; i < 8; i++) {
        final eggAngle = _phase * 0.8 + i * math.pi / 4;
        final eggR = 95 * scale + math.sin(_phase * 2 + i) * 8;
        final ex = cx + math.cos(eggAngle) * eggR;
        final ey = cy + math.sin(eggAngle) * eggR;
        final eggPulse = 0.6 + math.sin(_phase * 3 + i * 0.7) * 0.4;
        _eggClusterPaint.color =
            NeonColors.orange.withValues(alpha: 0.8 * eggPulse);
        canvas.drawCircle(Offset(ex, ey), 4.5, _eggClusterPaint);
        _eggClusterPaint.color =
            const Color(0xFFFFFFFF).withValues(alpha: 0.6 * eggPulse);
        canvas.drawCircle(Offset(ex, ey), 2, _eggClusterPaint);
      }
    }

    if (_split && _halfOffset != null) {
      _drawHalf(canvas, paint, scale,
          Offset(cx + _halfOffset!.x / 2, cy + _halfOffset!.y / 2));
      _drawHalf(canvas, paint, scale,
          Offset(cx - _halfOffset!.x / 2, cy - _halfOffset!.y / 2));
    } else {
      _drawHexagon(canvas, paint, scale, Offset(cx, cy));
    }

    // ─── VENE ORGANICHE sul corpo (pulsanti dal centro) ───
    if (scale <= 1.01 && !_split) {
      _veinPaint.color = const Color(0xFFFF8800)
          .withValues(alpha: 0.5 + math.sin(_phase * 4) * 0.25);
      _veinPaint.strokeWidth = 1.5;
      for (int i = 0; i < 6; i++) {
        final vAngle = i * math.pi / 3 + _phase * 0.15;
        final inner = 30 * scale;
        final outer = 68 * scale + math.sin(_phase * 2 + i) * 8;
        canvas.drawLine(
          Offset(cx + math.cos(vAngle) * inner,
              cy + math.sin(vAngle) * inner),
          Offset(cx + math.cos(vAngle) * outer,
              cy + math.sin(vAngle) * outer),
          _veinPaint,
        );
      }
    }

    // ─── BERSERK GLOW fase 3 ───
    if (currentPhase == 3) {
      _berserkPaint.color = NeonColors.red
          .withValues(alpha: 0.3 + math.sin(_phase * 10) * 0.2);
      canvas.drawCircle(Offset(cx, cy), 120 * scale, _berserkPaint);
    }

    // ─── LASER TELEGRAPH (wind-up, no danno) ───
    if (_laserTelegraphTimer > 0) {
      final blinkPhase = (_laserTelegraphTimer * 4) % 1.0;
      final blinkAlpha = blinkPhase < 0.5 ? 0.75 : 0.25;
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(_laserAngle);
      final warnPaint = Paint()
        ..color = NeonColors.laserRed.withValues(alpha: blinkAlpha * 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawLine(const Offset(0, 0), const Offset(1500, 0), warnPaint);
      for (double x = 80; x < 1500; x += 120) {
        canvas.drawLine(Offset(x, -4), Offset(x, 4), warnPaint);
      }
      canvas.restore();
    }

    // ─── LASER ATTIVO (doppio layer: glow + core bianco) ───
    if (_laserActive) {
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(_laserAngle);
      _laserGlowPaint.color = NeonColors.laserRed.withValues(alpha: 0.35);
      canvas.drawRect(Rect.fromLTWH(0, -10, 1500, 20), _laserGlowPaint);
      _laserCorePaint.color = NeonColors.laserRed;
      canvas.drawRect(Rect.fromLTWH(0, -2, 1500, 4), _laserCorePaint);
      _laserCorePaint.color =
          const Color(0xFFFFFFFF).withValues(alpha: 0.7);
      canvas.drawRect(Rect.fromLTWH(0, -1, 1500, 2), _laserCorePaint);
      canvas.restore();
    }
  }

  void _drawHalf(Canvas canvas, Paint paint, double scale, Offset center) {
    final r = 60 * scale;
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = i * math.pi / 3 + _phase * 0.3;
      final irregularity = 1.0 + math.sin(i * 1.5 + _phase) * 0.15;
      final x = center.dx + r * irregularity * math.cos(angle);
      final y = center.dy + r * irregularity * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawHexagon(Canvas canvas, Paint paint, double scale, Offset center) {
    final r = 80 * scale;
    final path = Path();

    // Membrane pulsation
    for (int i = 0; i < 8; i++) {
      final angle = i * math.pi / 4 + _phase * 0.2;
      final irregularity = 1.0 + math.sin(i * 2.0 + _phase * 2) * 0.1;
      final x = center.dx + r * irregularity * math.cos(angle);
      final y = center.dy + r * irregularity * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }
}

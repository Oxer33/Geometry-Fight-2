import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../../data/constants.dart';
import '../../../data/wave_configs.dart';
import 'boss_base.dart';

/// SwarmMother — 3 fasi (richiesta utente iter 7):
///  - Phase 0 (>70% HP): spawna molti laserTurret minion + boss usa raggio
///    laser come altri boss.
///  - Phase 1 (40-70%): si divide in 2 metà. Una segue il player (boss
///    position), l'altra vaga random per l'arena (`_wanderHalfPos`).
///  - Phase 2 (<40%): rage rosso. Le 2 metà vorticano velocemente attorno
///    al boss e inseguono player più veloce.
class SwarmMotherBoss extends BossBase {
  double _spawnTimer = 3;
  double _laserAngle = 0;
  bool _laserActive = false;
  double _laserTimer = 0;
  double _laserCooldown = 6.0;
  static final math.Random _rng = math.Random();
  double _laserTelegraphTimer = 0;
  static const double _kLaserTelegraphDuration = 1.2;
  double _phase = 0;

  // Wander half (phase 1+): vaga indipendente dal chase half (boss position).
  Vector2 _wanderHalfPos = Vector2.zero();
  Vector2 _wanderHalfDir = Vector2(1, 0)..normalize();
  double _wanderRetargetTimer = 0;
  bool _wanderInited = false;

  // Vortex angle (phase 2): rotazione veloce delle 2 metà attorno al boss.
  double _vortexAngle = 0;

  // Cooldown danno da contatto della metà wander/vortex. Questa metà è solo
  // renderizzata (la hitbox del boss copre solo il chase half), quindi il
  // danno da contatto va applicato a mano per distanza (richiesta utente:
  // "una delle due metà non fa nulla, posso passarci attraverso").
  double _wanderHitCd = 0;
  static const double _kHalfContactRadius = 60.0; // ≈ raggio visivo (_drawHalf)

  SwarmMotherBoss()
    : super(
        hp: 2000,
        bossName: 'THE SWARM MOTHER',
        pointValue: 20000,
        neonColor: NeonColors.orange,
        size: Vector2(180, 180),
      );

  // SwarmMother arancione → mob arancio/rossi.
  @override
  List<EnemyType> get colorMatchedMinions => const [
    EnemyType.kamikaze,
    EnemyType.splitter,
    EnemyType.swarmDrone,
  ];

  // Fase 0: ottagono irregolare ~80-88px su bbox 180. 0.90 (81px) copre il
  // corpo centrale. La SECONDA metà (fase 1+) vaga lontano ed è gestita a
  // parte in codice via _kHalfContactRadius → non va coperta da questo cerchio.
  @override
  double get hitboxRadiusFactor => 0.90;

  @override
  int getPhase() {
    // 3 fasi (richiesta utente). Cutoff a 70% e 40%.
    if (healthPercent > 0.70) return 0;
    if (healthPercent > 0.40) return 1;
    return 2;
  }

  @override
  void onPhaseChange(int phase) {
    if (phase == 1 && !_wanderInited) {
      // Init wander half a 200px da boss in direzione random.
      final ang = _rng.nextDouble() * math.pi * 2;
      _wanderHalfPos = position + Vector2(math.cos(ang), math.sin(ang)) * 200;
      _wanderHalfDir = Vector2(math.cos(ang), math.sin(ang));
      _wanderRetargetTimer = 3 + _rng.nextDouble() * 2;
      _wanderInited = true;
    }
    // Phase 2: rage red — niente init speciale, vortex inizia automatico.
  }

  @override
  void updateBoss(double dt) {
    _phase += dt;

    // ── MOVIMENTO chase half (boss position) ──────────────────────────
    final chaseSpeed = switch (currentPhase) {
      0 => 50.0, // lento, sta a spawnare turret + sparare laser
      1 => 90.0, // medio, una metà insegue
      _ => 200.0, // veloce rage
    };
    final dir = (playerPosition - position);
    final stopDist = currentPhase == 2 ? 60.0 : 150.0;
    if (dir.length > stopDist) {
      position += dir.normalized() * chaseSpeed * dt;
    }

    // ── WANDER half (phase 1) ─────────────────────────────────────────
    if (currentPhase == 1) {
      _wanderRetargetTimer -= dt;
      if (_wanderRetargetTimer <= 0) {
        _wanderRetargetTimer = 3 + _rng.nextDouble() * 2;
        final ang = _rng.nextDouble() * math.pi * 2;
        _wanderHalfDir = Vector2(math.cos(ang), math.sin(ang));
      }
      _wanderHalfPos += _wanderHalfDir * 100 * dt;
      // Bounce ai bordi arena.
      if (_wanderHalfPos.x < 60 || _wanderHalfPos.x > arenaWidth - 60) {
        _wanderHalfDir.x *= -1;
      }
      if (_wanderHalfPos.y < 60 || _wanderHalfPos.y > arenaHeight - 60) {
        _wanderHalfDir.y *= -1;
      }
      _wanderHalfPos.x = _wanderHalfPos.x.clamp(60.0, arenaWidth - 60.0);
      _wanderHalfPos.y = _wanderHalfPos.y.clamp(60.0, arenaHeight - 60.0);
    }

    // ── VORTEX (phase 2): le 2 metà ruotano veloci attorno al boss ──
    if (currentPhase == 2) {
      _vortexAngle += dt * 6.0;
      const vortexR = 90.0;
      _wanderHalfPos =
          position +
          Vector2(math.cos(_vortexAngle), math.sin(_vortexAngle)) * vortexR;
    }

    // ── CONTATTO metà wander/vortex (phase 1+): danno manuale per distanza,
    //    perché questa metà non ha hitbox propria (richiesta utente: non
    //    deve essere attraversabile a vuoto). Cooldown per evitare 60 dmg/s.
    if (_wanderHitCd > 0) _wanderHitCd -= dt;
    if (currentPhase >= 1 &&
        _wanderHitCd <= 0 &&
        game.player.isMounted &&
        playerPosition.distanceTo(_wanderHalfPos) < _kHalfContactRadius) {
      game.player.takeDamage();
      _wanderHitCd = 0.6;
    }

    // ── SPAWN nemici per fase ─────────────────────────────────────────
    _spawnTimer -= dt;
    if (_spawnTimer <= 0) {
      switch (currentPhase) {
        case 0:
          // Phase 1 (utente): "spawna molti mob torretta (laserTurret)".
          _spawnTimer = 4.0;
          for (int i = 0; i < 3; i++) {
            game.spawnEnemy(
              EnemyType.laserTurret,
              position +
                  Vector2(
                    (_rng.nextDouble() - 0.5) * 280,
                    (_rng.nextDouble() - 0.5) * 280,
                  ),
            );
          }
        case 1:
          // Phase 2: kamikaze scatter attorno al chase half.
          _spawnTimer = 3.0;
          for (int i = 0; i < 4; i++) {
            game.spawnEnemy(
              EnemyType.kamikaze,
              position +
                  Vector2(
                    (_rng.nextDouble() - 0.5) * 180,
                    (_rng.nextDouble() - 0.5) * 180,
                  ),
            );
          }
        case 2:
          // Phase 3 rage: kamikaze rapidi.
          _spawnTimer = 1.5;
          for (int i = 0; i < 6; i++) {
            game.spawnEnemy(
              EnemyType.kamikaze,
              position +
                  Vector2(
                    (_rng.nextDouble() - 0.5) * 120,
                    (_rng.nextDouble() - 0.5) * 120,
                  ),
            );
          }
      }
    }

    // ── LASER sweep (richiesta utente: "lo stesso boss deve usare il
    //     raggio laser come gli altri boss"). Solo phase 0. ─────────────
    if (currentPhase == 0) {
      if (_laserTelegraphTimer > 0) {
        _laserTelegraphTimer -= dt;
        if (_laserTelegraphTimer <= 0) {
          _laserActive = true;
          _laserTimer = 2.0;
        }
      }
      if (!_laserActive && _laserTelegraphTimer <= 0) {
        _laserCooldown -= dt;
        if (_laserCooldown <= 0) {
          _laserCooldown = 6.0;
          _laserTelegraphTimer = _kLaserTelegraphDuration;
          _laserAngle = math.atan2(
            playerPosition.y - position.y,
            playerPosition.x - position.x,
          );
        }
      }
      if (_laserActive) {
        // Sweep 20° in 2s (rate π/18).
        _laserAngle += dt * math.pi / 18;
        _laserTimer -= dt;
        if (_laserTimer <= 0) {
          _laserActive = false;
          _laserCooldown = 6.0;
        }
        // Damage check
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
    } else {
      // Reset laser state quando passa a fase 1+ (no laser).
      _laserActive = false;
      _laserTelegraphTimer = 0;
    }
  }

  // ── PAINT cache ───────────────────────────────────────────────────────
  static final _eggClusterPaint = Paint();
  static final _veinPaint = Paint()..style = PaintingStyle.stroke;
  static final _spawnBurstPaint = Paint()..style = PaintingStyle.stroke;
  static final _berserkPaint = Paint();
  static final _laserGlowPaint = Paint();
  static final _laserCorePaint = Paint();
  static final _laserWarnPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;
  static final _ragePaint = Paint();
  static final _linkPaint = Paint()..style = PaintingStyle.stroke;

  @override
  void renderBoss(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;

    // Phase 2 rage → tinta rossa override.
    final Paint bodyPaint;
    if (currentPhase == 2) {
      _ragePaint.color = NeonColors.red;
      bodyPaint = _ragePaint;
    } else {
      bodyPaint = paint;
    }

    // ── SPAWN BURST ring pre-spawn ──────────────────────────────────
    if (scale <= 1.01 && _spawnTimer < 0.4) {
      final burstT = 1.0 - _spawnTimer.clamp(0.0, 0.4) / 0.4;
      _spawnBurstPaint.color =
          (currentPhase == 2 ? NeonColors.red : NeonColors.orange).withValues(
            alpha: burstT * 0.6,
          );
      _spawnBurstPaint.strokeWidth = 2 + burstT * 4;
      canvas.drawCircle(
        Offset(cx, cy),
        110 * scale * (0.6 + burstT * 0.5),
        _spawnBurstPaint,
      );
    }

    // ── EGG CLUSTER orbitanti (solo phase 0) ────────────────────────
    if (scale <= 1.01 && currentPhase == 0) {
      for (int i = 0; i < 8; i++) {
        final eggAngle = _phase * 0.8 + i * math.pi / 4;
        final eggR = 95 * scale + math.sin(_phase * 2 + i) * 8;
        final ex = cx + math.cos(eggAngle) * eggR;
        final ey = cy + math.sin(eggAngle) * eggR;
        final eggPulse = 0.6 + math.sin(_phase * 3 + i * 0.7) * 0.4;
        _eggClusterPaint.color = NeonColors.orange.withValues(
          alpha: 0.8 * eggPulse,
        );
        canvas.drawCircle(Offset(ex, ey), 4.5, _eggClusterPaint);
        _eggClusterPaint.color = const Color(
          0xFFFFFFFF,
        ).withValues(alpha: 0.6 * eggPulse);
        canvas.drawCircle(Offset(ex, ey), 2, _eggClusterPaint);
      }
    }

    // ── BODY rendering per fase ─────────────────────────────────────
    if (currentPhase == 0) {
      // Single hexagon center.
      _drawOctagon(canvas, bodyPaint, scale, Offset(cx, cy));
    } else {
      // Phase 1+: 2 metà. Chase half = boss center. Wander/vortex half
      // = offset locale = (wanderHalfPos - position).
      final wanderOffset = _wanderHalfPos - position;
      _drawHalf(canvas, bodyPaint, scale, Offset(cx, cy));
      _drawHalf(
        canvas,
        bodyPaint,
        scale,
        Offset(cx + wanderOffset.x, cy + wanderOffset.y),
      );
      // Linea connettiva luminosa fra le 2 metà.
      _linkPaint.color =
          (currentPhase == 2 ? NeonColors.red : NeonColors.orange).withValues(
            alpha: 0.4 + math.sin(_phase * 4) * 0.2,
          );
      _linkPaint.strokeWidth = 2.5;
      canvas.drawLine(
        Offset(cx, cy),
        Offset(cx + wanderOffset.x, cy + wanderOffset.y),
        _linkPaint,
      );
    }

    // ── VENE pulsanti (solo phase 0, sotto il singolo body) ─────────
    if (scale <= 1.01 && currentPhase == 0) {
      _veinPaint.color = const Color(
        0xFFFF8800,
      ).withValues(alpha: 0.5 + math.sin(_phase * 4) * 0.25);
      _veinPaint.strokeWidth = 1.5;
      for (int i = 0; i < 6; i++) {
        final vAngle = i * math.pi / 3 + _phase * 0.15;
        final inner = 30 * scale;
        final outer = 68 * scale + math.sin(_phase * 2 + i) * 8;
        canvas.drawLine(
          Offset(cx + math.cos(vAngle) * inner, cy + math.sin(vAngle) * inner),
          Offset(cx + math.cos(vAngle) * outer, cy + math.sin(vAngle) * outer),
          _veinPaint,
        );
      }
    }

    // ── BERSERK GLOW phase 2 (rage red) ─────────────────────────────
    if (currentPhase == 2) {
      _berserkPaint.color = NeonColors.red.withValues(
        alpha: 0.35 + math.sin(_phase * 12) * 0.25,
      );
      canvas.drawCircle(Offset(cx, cy), 130 * scale, _berserkPaint);
    }

    // ── LASER TELEGRAPH (wind-up) ───────────────────────────────────
    if (_laserTelegraphTimer > 0) {
      final blinkPhase = (_laserTelegraphTimer * 4) % 1.0;
      final blinkAlpha = blinkPhase < 0.5 ? 0.75 : 0.25;
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(_laserAngle);
      _laserWarnPaint.color = NeonColors.laserRed.withValues(
        alpha: blinkAlpha * 0.55,
      );
      canvas.drawLine(
        const Offset(0, 0),
        const Offset(1500, 0),
        _laserWarnPaint,
      );
      for (double x = 80; x < 1500; x += 120) {
        canvas.drawLine(Offset(x, -4), Offset(x, 4), _laserWarnPaint);
      }
      canvas.restore();
    }

    // ── LASER ATTIVO ────────────────────────────────────────────────
    if (_laserActive) {
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(_laserAngle);
      _laserGlowPaint.color = NeonColors.laserRed.withValues(alpha: 0.35);
      canvas.drawRect(const Rect.fromLTWH(0, -10, 1500, 20), _laserGlowPaint);
      _laserCorePaint.color = NeonColors.laserRed;
      canvas.drawRect(const Rect.fromLTWH(0, -2, 1500, 4), _laserCorePaint);
      _laserCorePaint.color = const Color(0xFFFFFFFF).withValues(alpha: 0.7);
      canvas.drawRect(const Rect.fromLTWH(0, -1, 1500, 2), _laserCorePaint);
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

  void _drawOctagon(Canvas canvas, Paint paint, double scale, Offset center) {
    final r = 80 * scale;
    final path = Path();
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

import 'dart:collection';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/painting.dart' show HSVColor;
import '../../../data/constants.dart';
import '../../../data/wave_configs.dart';
import '../../game_world.dart';
import 'boss_base.dart';

/// Rewind orb (nuova meccanica richiesta utente).
/// Fase orbiting: orbita attorno al boss per 3s (visibile, nessun danno).
/// Fase hazard: teletrasportato alla posizione del player 3s fa → zona
/// pericolosa stazionaria per 2s che infligge danno se player ci torna.
class _RewindOrb {
  Vector2 position = Vector2.zero();
  double orbitAngle = 0;
  double timer = 3.0; // 3s orbit, poi hazard
  double hazardTimer = 0; // 2s hazard
  bool isHazard = false;
  double activationDelay = 0.3; // grace post-teleport prima del danno
}

/// ETERNITY ENGINE - Boss finale definitivo. Macchina cosmica infinita.
/// Forma: triplo anello concentrico con nucleo quantistico
/// Colore: arcobaleno rotante con nucleo bianco
/// HP: 3500 · 4 fasi
/// Meccanica: ogni fase aggiunge un anello e un pattern di attacco.
/// Fase 4: tutti gli anelli ruotano in direzioni opposte sparando contemporaneamente.
class EternityEngineBoss extends BossBase {
  double _phase = 0;
  double _attackTimer = 2.0;
  double _spiralAngle = 0;
  double _ringRotation1 = 0;
  double _ringRotation2 = 0;
  double _ringRotation3 = 0;
  // Rage (phase 3): spawn black hole ogni 10s invece di burst totali
  // (richiesta utente: rage sparava troppi proiettili).
  double _rageBlackHoleTimer = 10.0;
  // Shared rng — evita alloc in onPhaseChange/attackHoming/attackWall.
  static final math.Random _rng = math.Random();

  // Rewind mechanic (nuova meccanica richiesta utente):
  // traccia posizioni player nei precedenti 3s → orbi teletrasportati
  // alla posizione passata come zona pericolosa.
  // ListQueue: removeFirst O(1) invece di list.removeAt(0) O(N).
  final ListQueue<Vector2> _posHistory = ListQueue<Vector2>();
  static const int _kHistoryMaxSize = 180; // 3s at 60fps
  double _rewindSpawnTimer = 5.0;
  final List<_RewindOrb> _rewindOrbs = [];
  static const double _kRewindSpawnInterval = 5.0;
  static const double _kRewindOrbitRadius = 70;
  static const double _kRewindHazardRadius = 55;
  // Cached orb paints (evita alloc/frame × N orbi).
  static final _orbGlowPaint = Paint();
  static final _orbCorePaint = Paint();
  static final _hazardFillPaint = Paint();
  static final _hazardBorderPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.2;
  static final _clockPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;

  EternityEngineBoss()
      : super(
          hp: 3500,
          bossName: 'ETERNITY ENGINE',
          pointValue: 12000,
          neonColor: const Color(0xFFFFFFFF),
          size: Vector2(130, 130),
        );

  // EternityEngine è ARCOBALENO ROTANTE → mob neutri (drone + orbiter + decoy).
  @override
  List<EnemyType> get colorMatchedMinions =>
      const [EnemyType.drone, EnemyType.orbiter, EnemyType.decoy];

  @override
  int getPhase() {
    if (healthPercent > 0.85) return 0;
    if (healthPercent > 0.70) return 1;
    if (healthPercent > 0.40) return 2;
    return 3;
  }

  @override
  void onPhaseChange(int phase) {
    game.triggerScreenShake(12, 0.6);
    if (!game.isTunnelMode) {
      game.grid.applyForce(position, 400, 2000);
    }
    // Ogni fase spawna nemici di supporto
    for (int i = 0; i < 3 + phase * 2; i++) {
      final angle = _rng.nextDouble() * math.pi * 2;
      game.spawnEnemy(EnemyType.drone, position + Vector2(
        math.cos(angle) * 200, math.sin(angle) * 200,
      ));
    }
  }

  @override
  void updateBoss(double dt) {
    _phase += dt * 5;
    _spiralAngle += dt * (1.5 + currentPhase * 0.5);
    _ringRotation1 += dt * 1.0;
    _ringRotation2 -= dt * 0.7;
    _ringRotation3 += dt * 0.4;

    // Movimento: orbita lenta attorno al centro arena (o camera in tunnel mode)
    final center = game.isTunnelMode
        ? game.camera.viewfinder.position
        : Vector2(arenaWidth / 2, arenaHeight / 2);
    final orbitR = 200 + math.sin(_phase * 0.2) * 80;
    final targetPos = center + Vector2(
      math.cos(_phase * 0.1) * orbitR,
      math.sin(_phase * 0.1) * orbitR,
    );
    final toTarget = targetPos - position;
    if (toTarget.length > 5) {
      position += toTarget.normalized() * 60 * dt;
    }

    // Distorsione griglia costante
    if (!game.isTunnelMode) {
      game.grid.applyForce(position, 150, 80 * dt);
    }

    // ─── REWIND ORBS: track player pos history ────────────────────
    _posHistory.addLast(playerPosition.clone());
    if (_posHistory.length > _kHistoryMaxSize) {
      _posHistory.removeFirst();
    }

    // Spawn 3 rewind orb ogni 5s.
    _rewindSpawnTimer -= dt;
    if (_rewindSpawnTimer <= 0) {
      _rewindSpawnTimer = _kRewindSpawnInterval;
      for (int i = 0; i < 3; i++) {
        _rewindOrbs.add(_RewindOrb()
          ..position = position.clone()
          ..orbitAngle = i * math.pi * 2 / 3);
      }
    }

    // Update orbs: orbit phase → teleport → hazard → remove.
    for (int i = _rewindOrbs.length - 1; i >= 0; i--) {
      final orb = _rewindOrbs[i];
      if (!orb.isHazard) {
        // Fase orbita: gira attorno al boss.
        orb.orbitAngle += dt * 2.5;
        orb.position = position +
            Vector2(math.cos(orb.orbitAngle), math.sin(orb.orbitAngle)) *
                _kRewindOrbitRadius;
        orb.timer -= dt;
        if (orb.timer <= 0) {
          // Teleport a posizione player 3s fa (primo elemento history).
          orb.isHazard = true;
          orb.hazardTimer = 2.0;
          orb.activationDelay = 0.3;
          if (_posHistory.isNotEmpty) {
            orb.position = _posHistory.first.clone();
          }
        }
      } else {
        // Fase hazard: zona statica con danno (dopo grace).
        orb.hazardTimer -= dt;
        if (orb.activationDelay > 0) orb.activationDelay -= dt;
        if (orb.hazardTimer <= 0) {
          _rewindOrbs.removeAt(i);
          continue;
        }
        // Danno se player entra nel raggio hazard (post-grace).
        if (orb.activationDelay <= 0 &&
            game.player.position.distanceTo(orb.position) <
                _kRewindHazardRadius &&
            !game.player.isInvincible) {
          game.player.takeDamage();
          _rewindOrbs.removeAt(i);
        }
      }
    }

    // Attacco in base alla fase
    _attackTimer -= dt;
    if (_attackTimer <= 0) {
      _attackTimer = (1.8 - currentPhase * 0.3).clamp(0.5, 2.0);
      switch (currentPhase) {
        case 0: _attackSpiral(8);
        case 1: _attackSpiral(12); _attackRadial();
        case 2: _attackSpiral(16); _attackRadial(); _attackHoming();
        // Rage (richiesta utente): spara come phase 2 — no burst totale.
        case 3: _attackSpiral(16); _attackRadial(); _attackHoming();
      }
    }

    // Rage: spawn black hole ogni 10s (richiesta utente).
    if (currentPhase == 3) {
      _rageBlackHoleTimer -= dt;
      if (_rageBlackHoleTimer <= 0) {
        _rageBlackHoleTimer = 10.0;
        final spawnPos = playerPosition +
            Vector2(
              (_rng.nextDouble() - 0.5) * 300,
              (_rng.nextDouble() - 0.5) * 300,
            );
        game.spawnEnemy(EnemyType.blackHole, spawnPos);
      }
    }
  }

  void _attackSpiral(int count) {
    for (int i = 0; i < count; i++) {
      final angle = _spiralAngle + i * math.pi * 2 / count;
      final dir = Vector2(math.cos(angle), math.sin(angle));
      final bullet = _EternityBullet(direction: dir, color: _getPhaseColor(0));
      bullet.position = position.clone();
      game.world.add(bullet);
    }
  }

  void _attackRadial() {
    // NaN guard: se boss coincide col player, usa baseAngle 0.
    final delta = playerPosition - position;
    final baseAngle = delta.length < 0.001
        ? 0.0
        : math.atan2(delta.y, delta.x);
    for (int i = 0; i < 6; i++) {
      final angle = baseAngle + (i - 2.5) * 0.15;
      final bulletDir = Vector2(math.cos(angle), math.sin(angle));
      final bullet = _EternityBullet(direction: bulletDir, color: _getPhaseColor(1), speed: 250);
      bullet.position = position.clone();
      game.world.add(bullet);
    }
  }

  void _attackHoming() {
    for (int i = 0; i < 2; i++) {
      game.spawnEnemy(EnemyType.swarmDrone, position + Vector2(
        (_rng.nextDouble() - 0.5) * 100,
        (_rng.nextDouble() - 0.5) * 100,
      ));
    }
  }

  // `_attackWall` rimosso: richiesta utente rage spari uniformi phase-2
  // style + black hole ogni 10s (non più burst totale).

  Color _getPhaseColor(int ring) {
    final hue = (_phase * 30 + ring * 90) % 360;
    return HSVColor.fromAHSV(1.0, hue, 0.8, 1.0).toColor();
  }

  // Signature FX paints
  static final _ringPaint = Paint()..style = PaintingStyle.stroke;
  static final _gearToothPaint = Paint();
  static final _nodePaint = Paint();
  static final _innerBeamPaint = Paint()..style = PaintingStyle.stroke;
  static final _crossBeamPaint = Paint()..style = PaintingStyle.stroke;
  static final _coreGlowPaint = Paint();
  static final _coreFillPaint = Paint();
  static final _whiteCorePaint = Paint();
  static final _orbitPaint = Paint();
  static final _arcPaint = Paint()..style = PaintingStyle.stroke;

  @override
  void renderBoss(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final r = size.x / 2 * scale;

    // ─── REWIND ORBS (nuova meccanica) ─────────────────────────────
    // Orbit phase: orb arcobaleno attorno al boss.
    // Hazard phase: zona fissa con warning giallo → rosso letale.
    if (scale <= 1.01) {
      for (final orb in _rewindOrbs) {
        final offset = orb.position - position;
        final ox = cx + offset.x;
        final oy = cy + offset.y;
        if (!orb.isHazard) {
          final orbitPulse = 0.6 + math.sin(_phase * 3 + orb.orbitAngle) * 0.4;
          final hue = (_phase * 60 + orb.orbitAngle * 40) % 360;
          final orbColor = HSVColor.fromAHSV(1, hue, 0.8, 1).toColor();
          _orbGlowPaint.color =
              orbColor.withValues(alpha: 0.45 * orbitPulse);
          canvas.drawCircle(
              Offset(ox, oy), 14 * orbitPulse, _orbGlowPaint);
          _orbCorePaint.color =
              const Color(0xFFFFFFFF).withValues(alpha: orbitPulse);
          canvas.drawCircle(Offset(ox, oy), 5, _orbCorePaint);
        } else {
          final isGrace = orb.activationDelay > 0;
          final zoneColor = isGrace
              ? const Color(0xFFFFEE00)
              : const Color(0xFFFF2200);
          final strobe = isGrace
              ? 0.5 + math.sin(_phase * 14) * 0.3
              : 0.7 + math.sin(_phase * 20) * 0.3;
          _hazardFillPaint.color =
              zoneColor.withValues(alpha: 0.25 * strobe);
          canvas.drawCircle(
              Offset(ox, oy), _kRewindHazardRadius, _hazardFillPaint);
          _hazardBorderPaint.color =
              zoneColor.withValues(alpha: 0.8 * strobe);
          canvas.drawCircle(
              Offset(ox, oy), _kRewindHazardRadius, _hazardBorderPaint);
          // Quadrante temporale (orologio che gira) al centro.
          final clockAngle = (orb.hazardTimer / 2.0) * math.pi * 2;
          _clockPaint.color =
              const Color(0xFFFFFFFF).withValues(alpha: 0.9 * strobe);
          canvas.drawArc(
            Rect.fromCircle(center: Offset(ox, oy), radius: 8),
            -math.pi / 2,
            clockAngle,
            false,
            _clockPaint,
          );
        }
      }
    }

    // ─── CROSS ENERGY BEAMS (4 raggi cardinali pulsanti) ───
    if (scale <= 1.01) {
      _crossBeamPaint.strokeWidth = 1.2;
      for (int i = 0; i < 4; i++) {
        final beamAngle = _phase * 0.4 + i * math.pi / 2;
        final beamPulse = 0.5 + math.sin(_phase * 3 + i) * 0.4;
        _crossBeamPaint.color =
            _getPhaseColor(i).withValues(alpha: beamPulse * 0.6);
        canvas.drawLine(
          Offset(cx, cy),
          Offset(cx + math.cos(beamAngle) * r * 1.15,
              cy + math.sin(beamAngle) * r * 1.15),
          _crossBeamPaint,
        );
      }
    }

    // === ANELLO 1 ESTERNO ===
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(_ringRotation1);
    _drawRing(canvas, r * 0.9, _getPhaseColor(0), scale, 8);
    canvas.restore();

    // === ANELLO 2 MEDIO ===
    if (currentPhase >= 1) {
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(_ringRotation2);
      _drawRing(canvas, r * 0.65, _getPhaseColor(1), scale, 6);
      canvas.restore();
    }

    // === ANELLO 3 INTERNO ===
    if (currentPhase >= 2) {
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(_ringRotation3);
      _drawRing(canvas, r * 0.42, _getPhaseColor(2), scale, 4);
      canvas.restore();
    }

    // === NUCLEO QUANTISTICO multi-strato ===
    final coreColor = _getPhaseColor(3);
    _coreGlowPaint.color = coreColor.withValues(alpha: 0.22);
    canvas.drawCircle(Offset(cx, cy), r * 0.3, _coreGlowPaint);
    _coreFillPaint.color = coreColor;
    canvas.drawCircle(Offset(cx, cy), r * 0.18, _coreFillPaint);

    if (scale <= 1.01) {
      final pulse = 0.6 + math.sin(_phase * 2) * 0.3;
      _whiteCorePaint.color = Color.fromRGBO(255, 255, 255, pulse);
      canvas.drawCircle(Offset(cx, cy), r * 0.08 * (0.9 + pulse * 0.2),
          _whiteCorePaint);

      // Quantum orbit: 4 particelle con core bianco
      for (int i = 0; i < 4; i++) {
        final pAngle = _phase * 3 + i * math.pi / 2;
        final pR = r * 0.12;
        _orbitPaint.color = coreColor.withValues(alpha: 0.9);
        canvas.drawCircle(
            Offset(cx + pR * math.cos(pAngle), cy + pR * math.sin(pAngle)),
            2, _orbitPaint);
        _orbitPaint.color =
            const Color(0xFFFFFFFF).withValues(alpha: 0.8);
        canvas.drawCircle(
            Offset(cx + pR * math.cos(pAngle), cy + pR * math.sin(pAngle)),
            0.8, _orbitPaint);
      }

      // Indicatore fase
      _arcPaint.strokeWidth = 3;
      for (int i = 0; i <= currentPhase; i++) {
        final arcAngle = i * math.pi / 2;
        _arcPaint.color = _getPhaseColor(i).withValues(alpha: 0.55);
        canvas.drawArc(
          Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.95),
          arcAngle, 0.3, false, _arcPaint,
        );
      }
    }
  }

  void _drawRing(Canvas canvas, double radius, Color color, double scale,
      int segments) {
    _ringPaint.color = color.withValues(alpha: 0.55);
    _ringPaint.strokeWidth = 3 * scale;

    // Archi segmentati
    for (int i = 0; i < segments; i++) {
      final startAngle = i * math.pi * 2 / segments;
      final sweepAngle = math.pi * 2 / segments * 0.7;
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: radius),
        startAngle, sweepAngle, false, _ringPaint,
      );
    }

    if (scale <= 1.01) {
      // ─── GEAR TEETH sugli anelli (micro-triangoli radiali) ───
      _gearToothPaint.color = color.withValues(alpha: 0.75);
      for (int i = 0; i < segments; i++) {
        final angle = i * math.pi * 2 / segments;
        final tx = radius * math.cos(angle);
        final ty = radius * math.sin(angle);
        canvas.save();
        canvas.translate(tx, ty);
        canvas.rotate(angle);
        final toothPath = Path()
          ..moveTo(5, -2.5)
          ..lineTo(5, 2.5)
          ..lineTo(10, 0)
          ..close();
        canvas.drawPath(toothPath, _gearToothPaint);
        canvas.restore();
      }
      // Nodi luminosi bianchi sui vertici
      _nodePaint.color = const Color(0xFFFFFFFF).withValues(alpha: 0.85);
      for (int i = 0; i < segments; i++) {
        final angle = i * math.pi * 2 / segments;
        canvas.drawCircle(
          Offset(radius * math.cos(angle), radius * math.sin(angle)),
          2.2, _nodePaint,
        );
      }

      // Beam sottili tra segmenti consecutivi
      _innerBeamPaint.color = color.withValues(alpha: 0.25);
      _innerBeamPaint.strokeWidth = 0.8;
      for (int i = 0; i < segments; i++) {
        final a1 = i * math.pi * 2 / segments;
        final a2 = (i + 1) * math.pi * 2 / segments;
        canvas.drawLine(
          Offset(radius * math.cos(a1), radius * math.sin(a1)),
          Offset(radius * 0.85 * math.cos(a2), radius * 0.85 * math.sin(a2)),
          _innerBeamPaint,
        );
      }
    }
  }
}

class _EternityBullet extends PositionComponent with HasGameReference<GeometryFightGame> {
  final Vector2 direction;
  final Color color;
  final double speed;
  late Vector2 _velocity;
  double _lifetime = 4.0;

  _EternityBullet({required this.direction, required this.color, this.speed = 180})
      : super(size: Vector2(18, 18), anchor: Anchor.center);

  @override
  Future<void> onLoad() async { _velocity = direction.normalized() * speed; }

  @override
  void update(double dt) {
    super.update(dt);
    position += _velocity * dt;
    _lifetime -= dt;
    if (_lifetime <= 0) removeFromParent();
    if (position.distanceTo(game.player.position) < 14) {
      game.player.takeDamage();
      removeFromParent();
    }
  }

  static final _bulletPaint = Paint();
  static final _bulletCorePaint = Paint();

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    _bulletPaint.color = color.withValues(alpha: 0.3);
    canvas.drawCircle(Offset(cx, cy), 8, _bulletPaint);
    _bulletPaint.color = color;
    canvas.drawCircle(Offset(cx, cy), 6, _bulletPaint);
    _bulletCorePaint.color = const Color(0xFFFFFFFF).withValues(alpha: 0.7);
    canvas.drawCircle(Offset(cx, cy), 3, _bulletCorePaint);
  }
}

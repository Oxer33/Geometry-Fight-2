import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../../data/constants.dart';
import '../../../data/wave_configs.dart';
import 'boss_base.dart';
import '../projectiles.dart';

/// NEW BOSS: The Architect - builds geometric structures that attack
class TheArchitectBoss extends BossBase {
  double _buildTimer = 3;
  double _phase = 0;
  final List<_Structure> _structures = [];
  double _wallAttackTimer = 6;
  double _bossShootTimer = 0.6;
  // Shared rng — evita alloc in _buildStructure/_wallAttack.
  static final math.Random _rng = math.Random();

  TheArchitectBoss()
      : super(
          hp: 1500,
          bossName: 'THE ARCHITECT',
          pointValue: 15000,
          neonColor: NeonColors.electricBlue,
          size: Vector2(160, 160),
        );

  // TheArchitect è BLU ELETTRICO → mob blu/azzurri (tesla + glitch + laserTurret).
  // Esempio esplicitamente menzionato dall'utente.
  @override
  List<EnemyType> get colorMatchedMinions =>
      const [EnemyType.tesla, EnemyType.glitch, EnemyType.laserTurret];

  @override
  int getPhase() {
    if (healthPercent > 0.6) return 0;
    if (healthPercent > 0.3) return 1;
    return 2;
  }

  @override
  void updateBoss(double dt) {
    _phase += dt;

    // Orbital movement around arena center (or camera in tunnel mode)
    final center = game.isTunnelMode
        ? game.camera.viewfinder.position
        : Vector2(arenaWidth / 2, arenaHeight / 2);
    final centerX = center.x;
    final centerY = center.y;
    final orbitRadius = 300.0 - currentPhase * 50;
    position = Vector2(
      centerX + math.cos(_phase * 0.5) * orbitRadius,
      centerY + math.sin(_phase * 0.5) * orbitRadius,
    );

    // Build structures
    _buildTimer -= dt;
    if (_buildTimer <= 0) {
      _buildTimer = 3.0 - currentPhase * 0.8;
      _buildStructure();
    }

    // Update structures
    for (final structure in _structures.toList()) {
      structure.lifetime -= dt;
      structure.attackTimer -= dt;

      if (structure.lifetime <= 0) {
        _structures.remove(structure);
        continue;
      }

      // Structures shoot at player
      if (structure.attackTimer <= 0) {
        structure.attackTimer = 1.5;
        // NaN guard: se player coincide con struttura, skip shot.
        final delta = playerPosition - structure.position;
        if (delta.length >= 0.001) {
          final dir = delta.normalized();
          final bullet = EnemyBullet(
              direction: dir, speed: 220, color: NeonColors.electricBlue);
          bullet.position = structure.position.clone();
          game.world.add(bullet);
        }
      }
    }

    // Wall attack (phase 1+)
    if (currentPhase >= 1) {
      _wallAttackTimer -= dt;
      if (_wallAttackTimer <= 0) {
        _wallAttackTimer = 6.0;
        _wallAttack();
      }
    }

    // Phase 2: Structures shoot faster and boss shoots too
    if (currentPhase >= 2) {
      _bossShootTimer -= dt;
      if (_bossShootTimer <= 0) {
        _bossShootTimer = 0.6;
        // NaN guard: skip shoot se player coincide con boss.
        final delta = playerPosition - position;
        if (delta.length >= 0.001) {
          final dir = delta.normalized();
          final bullet = EnemyBullet(
              direction: dir, speed: 280, color: NeonColors.white);
          bullet.position = position.clone();
          game.world.add(bullet);
        }
      }
    }
  }

  void _buildStructure() {
    final angle = _rng.nextDouble() * math.pi * 2;
    final dist = 150 + _rng.nextDouble() * 200;
    final pos = position + Vector2(math.cos(angle) * dist, math.sin(angle) * dist);

    _structures.add(_Structure(
      position: pos,
      lifetime: 10.0 + currentPhase * 5,
      attackTimer: 1.5,
    ));

    // Spawn a mine near the structure
    if (currentPhase >= 1) {
      game.spawnEnemy(EnemyType.mine, pos + Vector2(30, 0));
    }
  }

  void _wallAttack() {
    // Create a wall of bullets
    final horizontal = _rng.nextBool();
    for (int i = 0; i < 15; i++) {
      Vector2 bulletPos;
      Vector2 bulletDir;
      if (horizontal) {
        bulletPos = Vector2(
          playerPosition.x - 400 + i * 53,
          playerPosition.y - 500,
        );
        bulletDir = Vector2(0, 1);
      } else {
        bulletPos = Vector2(
          playerPosition.x - 500,
          playerPosition.y - 400 + i * 53,
        );
        bulletDir = Vector2(1, 0);
      }

      // Leave gaps
      if (i == 5 || i == 9) continue;

      final bullet = EnemyBullet(
          direction: bulletDir, speed: 200, color: NeonColors.electricBlue);
      bullet.position = bulletPos;
      game.world.add(bullet);
    }
  }

  // Signature FX paints
  static final _blueprintPaint = Paint()..style = PaintingStyle.stroke;
  static final _constructionRingPaint = Paint()..style = PaintingStyle.stroke;
  static final _coreHaloPaint = Paint();
  static final _corePaint = Paint();
  static final _beamPaint = Paint()..style = PaintingStyle.stroke;
  static final _structureGlowPaint = Paint();
  static final _structureFillPaint = Paint();
  static final _structurePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;

  @override
  void renderBoss(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;

    // ─── BEAMS blueprint dal centro a ogni struttura ───
    if (scale <= 1.01) {
      for (final structure in _structures) {
        final sPos = structure.position - position;
        final beamAlpha =
            (structure.lifetime / 15).clamp(0.0, 1.0) * 0.5;
        _beamPaint.color = NeonColors.electricBlue.withValues(
            alpha: beamAlpha * (0.6 + math.sin(_phase * 4) * 0.4));
        _beamPaint.strokeWidth = 1.2;
        canvas.drawLine(
            Offset(cx, cy), Offset(cx + sPos.x, cy + sPos.y), _beamPaint);
      }
    }

    // ─── CORPO: struttura geometrica multi-strato ───
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(_phase * 0.3);

    final r = 65 * scale;

    // Blueprint grid (4 righe orizzontali + verticali)
    if (scale <= 1.01) {
      _blueprintPaint.color = NeonColors.electricBlue
          .withValues(alpha: 0.22 + math.sin(_phase * 1.5) * 0.1);
      _blueprintPaint.strokeWidth = 0.6;
      const gridN = 4;
      for (int i = 1; i < gridN; i++) {
        final off = -r + (r * 2 / gridN) * i;
        canvas.drawLine(Offset(-r, off), Offset(r, off), _blueprintPaint);
        canvas.drawLine(Offset(off, -r), Offset(off, r), _blueprintPaint);
      }
    }

    // Square esterno
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 3;
    canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: r * 2, height: r * 2),
        paint);

    // Square interno ruotato
    canvas.rotate(math.pi / 4);
    canvas.drawRect(
        Rect.fromCenter(
            center: Offset.zero, width: r * 1.4, height: r * 1.4),
        paint);
    canvas.rotate(-math.pi / 4);

    // Construction ring contro-rotante
    if (scale <= 1.01) {
      final ringPulse = 0.3 + math.sin(_phase * 2) * 0.2;
      _constructionRingPaint.color =
          NeonColors.electricBlue.withValues(alpha: ringPulse);
      _constructionRingPaint.strokeWidth = 1.2;
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: r * 1.15),
        _phase * -1.2, math.pi * 0.8, false, _constructionRingPaint,
      );
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: r * 1.15),
        _phase * -1.2 + math.pi, math.pi * 0.8, false, _constructionRingPaint,
      );
    }

    // Core: halo + fill + nucleo bianco pulsante
    paint.style = PaintingStyle.fill;
    if (scale <= 1.01) {
      _coreHaloPaint.color = NeonColors.electricBlue.withValues(alpha: 0.4);
      canvas.drawCircle(Offset.zero, 30 * scale, _coreHaloPaint);
    }
    canvas.drawCircle(Offset.zero, 20 * scale, paint);
    if (scale <= 1.01) {
      final corePulse = 0.7 + math.sin(_phase * 6) * 0.3;
      _corePaint.color = const Color(0xFFFFFFFF).withValues(alpha: corePulse);
      canvas.drawCircle(Offset.zero, 8 * scale * corePulse, _corePaint);
    }

    canvas.restore();

    // ─── STRUTTURE esagonali con glow/fill/core ───
    for (final structure in _structures) {
      final sPos = structure.position - position;
      final lifeT = (structure.lifetime / 15).clamp(0.0, 1.0);
      final pulse = 0.7 + math.sin(_phase * 3 + structure.position.x) * 0.3;

      _structureGlowPaint.color =
          NeonColors.electricBlue.withValues(alpha: 0.25 * lifeT * pulse);
      canvas.drawCircle(
          Offset(cx + sPos.x, cy + sPos.y), 18, _structureGlowPaint);

      final path = Path();
      for (int i = 0; i < 6; i++) {
        final angle = i * math.pi / 3;
        final x = cx + sPos.x + 12 * math.cos(angle);
        final y = cy + sPos.y + 12 * math.sin(angle);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();

      _structureFillPaint.color =
          NeonColors.electricBlue.withValues(alpha: 0.25 * lifeT);
      canvas.drawPath(path, _structureFillPaint);
      _structurePaint.color =
          NeonColors.electricBlue.withValues(alpha: lifeT);
      canvas.drawPath(path, _structurePaint);

      _structureFillPaint.color =
          const Color(0xFFFFFFFF).withValues(alpha: 0.8 * lifeT * pulse);
      canvas.drawCircle(
          Offset(cx + sPos.x, cy + sPos.y), 2.5, _structureFillPaint);
    }
  }
}

class _Structure {
  final Vector2 position;
  double lifetime;
  double attackTimer;

  _Structure({
    required this.position,
    required this.lifetime,
    required this.attackTimer,
  });
}

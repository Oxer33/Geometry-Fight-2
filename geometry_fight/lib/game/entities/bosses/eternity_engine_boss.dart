import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/painting.dart' show HSVColor;
import '../../../data/constants.dart';
import '../../../data/wave_configs.dart';
import '../../game_world.dart';
import 'boss_base.dart';

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

  EternityEngineBoss()
      : super(
          hp: 3500,
          bossName: 'ETERNITY ENGINE',
          pointValue: 12000,
          neonColor: const Color(0xFFFFFFFF),
          size: Vector2(130, 130),
        );

  @override
  int getPhase() {
    if (healthPercent > 0.75) return 0;
    if (healthPercent > 0.50) return 1;
    if (healthPercent > 0.25) return 2;
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
      final angle = math.Random().nextDouble() * math.pi * 2;
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

    // Attacco in base alla fase
    _attackTimer -= dt;
    if (_attackTimer <= 0) {
      _attackTimer = (1.8 - currentPhase * 0.3).clamp(0.5, 2.0);
      switch (currentPhase) {
        case 0: _attackSpiral(8);
        case 1: _attackSpiral(12); _attackRadial();
        case 2: _attackSpiral(16); _attackRadial(); _attackHoming();
        case 3: _attackSpiral(20); _attackRadial(); _attackHoming(); _attackWall();
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
    for (int i = 0; i < 6; i++) {
      final dir = (playerPosition - position).normalized();
      final angle = math.atan2(dir.y, dir.x) + (i - 2.5) * 0.15;
      final bulletDir = Vector2(math.cos(angle), math.sin(angle));
      final bullet = _EternityBullet(direction: bulletDir, color: _getPhaseColor(1), speed: 250);
      bullet.position = position.clone();
      game.world.add(bullet);
    }
  }

  void _attackHoming() {
    for (int i = 0; i < 2; i++) {
      game.spawnEnemy(EnemyType.swarmDrone, position + Vector2(
        (math.Random().nextDouble() - 0.5) * 100,
        (math.Random().nextDouble() - 0.5) * 100,
      ));
    }
  }

  void _attackWall() {
    // Muro di proiettili orizzontale o verticale
    final horizontal = math.Random().nextBool();
    for (int i = -5; i <= 5; i++) {
      final dir = horizontal
          ? Vector2(0, i > 0 ? 1 : -1)
          : Vector2(i > 0 ? 1 : -1, 0);
      final offset = horizontal
          ? Vector2(i * 40.0, 0)
          : Vector2(0, i * 40.0);
      final bullet = _EternityBullet(direction: dir, color: _getPhaseColor(3), speed: 150);
      bullet.position = position + offset;
      game.world.add(bullet);
    }
  }

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
      : super(size: Vector2(8, 8), anchor: Anchor.center);

  @override
  Future<void> onLoad() async { _velocity = direction.normalized() * speed; }

  @override
  void update(double dt) {
    super.update(dt);
    position += _velocity * dt;
    _lifetime -= dt;
    if (_lifetime <= 0) removeFromParent();
    if (position.distanceTo(game.player.position) < 10) {
      game.player.takeDamage();
      removeFromParent();
    }
  }

  static final _bulletPaint = Paint();
  static final _bulletCorePaint = Paint();

  @override
  void render(Canvas canvas) {
    _bulletPaint.color = color;
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), 3.5, _bulletPaint);
    _bulletCorePaint.color = const Color(0xFFFFFFFF).withValues(alpha: 0.7);
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), 1.5, _bulletCorePaint);
  }
}

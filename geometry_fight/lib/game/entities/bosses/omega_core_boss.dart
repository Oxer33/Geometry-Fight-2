import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/painting.dart' show HSVColor;
import '../../../data/constants.dart';
import '../../../data/wave_configs.dart';
import '../../game_world.dart';
import 'boss_base.dart';

/// OMEGA CORE - Boss finale supremo. Combina le meccaniche di tutti i boss.
/// Forma: sfera perfetta con anelli orbitanti e nucleo pulsante
/// Colore: bianco/arcobaleno (#FFFFFF con shift cromatico)
/// HP: 3000 · 4 fasi
/// Meccanica: ogni fase attiva una meccanica diversa dei boss precedenti.
/// Fase 1: proiettili spirali (The Grid), Fase 2: zone morte (Void Reaper),
/// Fase 3: fulmini (Tesla Lord), Fase 4: TUTTE le meccaniche insieme.
class OmegaCoreBoss extends BossBase {
  double _phase = 0;
  double _attackTimer = 2.0;
  double _spiralAngle = 0;
  double _specialTimer = 6.0;
  final List<_DeathZone> _deathZones = [];

  OmegaCoreBoss()
      : super(
          hp: 3000,
          bossName: 'OMEGA CORE',
          pointValue: 10000,
          neonColor: const Color(0xFFFFFFFF),
          size: Vector2(120, 120),
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
    game.triggerScreenShake(10, 0.5);
    if (!game.isTunnelMode) {
      game.grid.applyForce(position, 300, 1500);
    }
  }

  @override
  void updateBoss(double dt) {
    _phase += dt * 4;
    _spiralAngle += dt * 2;

    // Movimento: orbita lenta attorno al centro arena (o camera in tunnel mode)
    final center = game.isTunnelMode
        ? game.camera.viewfinder.position
        : Vector2(arenaWidth / 2, arenaHeight / 2);
    final centerX = center.x;
    final centerY = center.y;
    final orbitR = 300 + math.sin(_phase * 0.3) * 100;
    final targetPos = Vector2(
      centerX + math.cos(_phase * 0.15) * orbitR,
      centerY + math.sin(_phase * 0.15) * orbitR,
    );
    final toTarget = targetPos - position;
    if (toTarget.length > 5) {
      position += toTarget.normalized() * 80 * dt;
    }

    // Attacco base: proiettili spirali
    _attackTimer -= dt;
    if (_attackTimer <= 0) {
      _attackTimer = currentPhase == 3 ? 0.5 : 1.5 - currentPhase * 0.3;
      _shootSpiral();
    }

    // Meccanica speciale per fase
    _specialTimer -= dt;
    if (_specialTimer <= 0) {
      _specialTimer = currentPhase == 3 ? 3.0 : 5.0;
      switch (currentPhase) {
        case 0: _spawnMinions();
        case 1: _createDeathZone();
        case 2: _lightningStrike();
        case 3: // TUTTO INSIEME
          _spawnMinions();
          _createDeathZone();
          _lightningStrike();
      }
    }

    // Aggiorna zone di morte (con TTL)
    for (int i = _deathZones.length - 1; i >= 0; i--) {
      _deathZones[i].lifetime -= dt;
      if (_deathZones[i].lifetime <= 0) {
        _deathZones.removeAt(i);
        continue;
      }
      final dist = game.player.position.distanceTo(_deathZones[i].position);
      if (dist < 50) {
        game.player.takeDamage();
        _deathZones.removeAt(i);
      }
    }

    // Griglia deformazione costante
    if (!game.isTunnelMode) {
      game.grid.applyForce(position, 100, 100 * dt);
    }
  }

  void _shootSpiral() {
    final count = 4 + currentPhase * 2;
    for (int i = 0; i < count; i++) {
      final angle = _spiralAngle + i * math.pi * 2 / count;
      final dir = Vector2(math.cos(angle), math.sin(angle));
      final bullet = _OmegaBullet(direction: dir, color: _getCurrentColor());
      bullet.position = position.clone();
      game.world.add(bullet);
    }
  }

  void _spawnMinions() {
    for (int i = 0; i < 3 + currentPhase; i++) {
      game.spawnEnemy(EnemyType.drone, position + Vector2(
        (math.Random().nextDouble() - 0.5) * 200,
        (math.Random().nextDouble() - 0.5) * 200,
      ));
    }
  }

  void _createDeathZone() {
    final random = math.Random();
    _deathZones.add(_DeathZone(
      position: playerPosition + Vector2(
        (random.nextDouble() - 0.5) * 200,
        (random.nextDouble() - 0.5) * 200,
      ),
      lifetime: 8.0,
    ));
    if (_deathZones.length > 5) _deathZones.removeAt(0);
  }

  void _lightningStrike() {
    // Danno al player se vicino
    if (distanceToPlayer < 200) {
      game.player.takeDamage();
      game.triggerScreenShake(5, 0.2);
    }
    if (!game.isTunnelMode) {
      game.grid.applyForce(position, 200, 800);
    }
  }

  Color _getCurrentColor() {
    final hue = (_phase * 30) % 360;
    return HSVColor.fromAHSV(1.0, hue, 0.8, 1.0).toColor();
  }

  // Signature FX paints
  static final _zoneFillPaint = Paint();
  static final _zoneBorderPaint = Paint()..style = PaintingStyle.stroke;
  static final _ring1Paint = Paint()..style = PaintingStyle.stroke;
  static final _ring2Paint = Paint()..style = PaintingStyle.stroke;
  static final _prismBeamPaint = Paint()..style = PaintingStyle.stroke;
  static final _spherePaint = Paint();
  static final _coreHaloPaint = Paint();
  static final _coreWhitePaint = Paint();
  static final _particlePaint = Paint();
  static final _phaseDotPaint = Paint();

  @override
  void renderBoss(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final r = size.x / 2 * scale;
    final cur = _getCurrentColor();

    // Zone di morte (doppio layer)
    if (scale <= 1.01) {
      for (final zone in _deathZones) {
        final offset = zone.position - position;
        _zoneFillPaint.color =
            const Color(0xFFFF2200).withValues(alpha: 0.2);
        canvas.drawCircle(
            Offset(cx + offset.x, cy + offset.y), 50, _zoneFillPaint);
        _zoneBorderPaint.color =
            const Color(0xFFFF2200).withValues(alpha: 0.4);
        _zoneBorderPaint.strokeWidth = 1.2;
        canvas.drawCircle(
            Offset(cx + offset.x, cy + offset.y), 50, _zoneBorderPaint);
      }
    }

    // ─── PRISM BEAM SPIKES: 8 raggi cromatici dal centro (signature) ───
    if (scale <= 1.01) {
      _prismBeamPaint.strokeWidth = 1.5;
      for (int i = 0; i < 8; i++) {
        final bAngle = _phase * 0.7 + i * math.pi / 4;
        final bLen = r * (1.1 + math.sin(_phase * 2 + i) * 0.2);
        final hue = ((_phase * 30) + i * 45) % 360;
        _prismBeamPaint.color =
            HSVColor.fromAHSV(0.55, hue, 0.8, 1).toColor();
        canvas.drawLine(
          Offset(cx, cy),
          Offset(cx + math.cos(bAngle) * bLen,
              cy + math.sin(bAngle) * bLen),
          _prismBeamPaint,
        );
      }
    }

    // Anello esterno orbitante 1
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(_phase * 0.3);
    _ring1Paint.color =
        cur.withValues(alpha: scale <= 1.01 ? 0.4 : 0.2);
    _ring1Paint.strokeWidth = 3 * scale;
    canvas.drawCircle(Offset.zero, r * 0.85, _ring1Paint);
    canvas.restore();

    // Anello esterno 2 contro-rotante
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(-_phase * 0.2);
    _ring2Paint.color =
        cur.withValues(alpha: scale <= 1.01 ? 0.3 : 0.15);
    _ring2Paint.strokeWidth = 2 * scale;
    canvas.drawCircle(Offset.zero, r * 0.7, _ring2Paint);
    canvas.restore();

    // Sfera principale
    _spherePaint.color = scale <= 1.01 ? cur : paint.color;
    canvas.drawCircle(Offset(cx, cy), r * 0.5, _spherePaint);

    // Dettagli interni + core multi-strato
    if (scale <= 1.01) {
      final pulse = 0.5 + math.sin(_phase * 2) * 0.4;
      _coreHaloPaint.color =
          const Color(0xFFFFFFFF).withValues(alpha: pulse * 0.35);
      canvas.drawCircle(Offset(cx, cy), r * 0.42, _coreHaloPaint);
      _coreWhitePaint.color =
          const Color(0xFFFFFFFF).withValues(alpha: pulse);
      canvas.drawCircle(
          Offset(cx, cy), r * 0.25 * (0.9 + pulse * 0.2), _coreWhitePaint);
      _coreWhitePaint.color =
          const Color(0xFFFFFFFF).withValues(alpha: (pulse * 1.2).clamp(0, 1));
      canvas.drawCircle(Offset(cx, cy), r * 0.08, _coreWhitePaint);

      // Particelle orbitanti con core bianco
      for (int i = 0; i < 6; i++) {
        final pAngle = _phase * 1.5 + i * math.pi / 3;
        final pR = r * (0.63 + math.sin(_phase * 3 + i) * 0.06);
        final px = cx + pR * math.cos(pAngle);
        final py = cy + pR * math.sin(pAngle);
        _particlePaint.color = cur.withValues(alpha: 0.7);
        canvas.drawCircle(Offset(px, py), 3.5, _particlePaint);
        _particlePaint.color = const Color(0xFFFFFFFF).withValues(alpha: 0.7);
        canvas.drawCircle(Offset(px, py), 1.2, _particlePaint);
      }

      // Indicatore fase
      for (int i = 0; i <= currentPhase; i++) {
        final dotX = cx - 10 + i * 7.0;
        final dotY = cy + r * 0.5 + 10;
        _phaseDotPaint.color = cur;
        canvas.drawCircle(Offset(dotX, dotY), 2, _phaseDotPaint);
      }
    }
  }
}

class _OmegaBullet extends PositionComponent with HasGameReference<GeometryFightGame> {
  final Vector2 direction;
  final Color color;
  late Vector2 _velocity;
  double _lifetime = 4.0;

  _OmegaBullet({required this.direction, required this.color})
      : super(size: Vector2(8, 8), anchor: Anchor.center);

  @override
  Future<void> onLoad() async { _velocity = direction.normalized() * 180; }

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

class _DeathZone {
  final Vector2 position;
  double lifetime;

  _DeathZone({required this.position, required this.lifetime});
}

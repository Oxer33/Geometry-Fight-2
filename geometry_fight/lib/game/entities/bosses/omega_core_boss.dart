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
  final List<Vector2> _deathZones = [];

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
    game.grid.applyForce(position, 300, 1500);
  }

  @override
  void updateBoss(double dt) {
    _phase += dt * 4;
    _spiralAngle += dt * 2;

    // Movimento: orbita lenta attorno al centro arena
    final centerX = arenaWidth / 2;
    final centerY = arenaHeight / 2;
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

    // Aggiorna zone di morte
    for (int i = _deathZones.length - 1; i >= 0; i--) {
      final dist = game.player.position.distanceTo(_deathZones[i]);
      if (dist < 50) {
        game.player.takeDamage();
        _deathZones.removeAt(i);
      }
    }

    // Griglia deformazione costante
    game.grid.applyForce(position, 100, 100 * dt);
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
    _deathZones.add(playerPosition + Vector2(
      (random.nextDouble() - 0.5) * 200,
      (random.nextDouble() - 0.5) * 200,
    ));
    if (_deathZones.length > 5) _deathZones.removeAt(0);
  }

  void _lightningStrike() {
    // Danno al player se vicino
    if (distanceToPlayer < 200) {
      game.triggerScreenShake(5, 0.2);
    }
    game.grid.applyForce(position, 200, 800);
  }

  Color _getCurrentColor() {
    final hue = (_phase * 30) % 360;
    return HSVColor.fromAHSV(1.0, hue, 0.8, 1.0).toColor();
  }

  @override
  void renderBoss(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final r = size.x / 2 * scale;

    // Zone di morte visibili
    if (scale <= 1.01) {
      for (final zone in _deathZones) {
        final offset = zone - position;
        final zonePaint = Paint()
          ..color = const Color(0xFFFF2200).withValues(alpha: 0.2)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
        canvas.drawCircle(Offset(cx + offset.x, cy + offset.y), 50, zonePaint);
        final borderPaint = Paint()
          ..color = const Color(0xFFFF2200).withValues(alpha: 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;
        canvas.drawCircle(Offset(cx + offset.x, cy + offset.y), 50, borderPaint);
      }
    }

    // Anello esterno orbitante 1
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(_phase * 0.3);
    final ring1Paint = Paint()
      ..color = _getCurrentColor().withValues(alpha: scale <= 1.01 ? 0.4 : 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 * scale;
    canvas.drawCircle(Offset.zero, r * 0.85, ring1Paint);
    canvas.restore();

    // Anello esterno orbitante 2 (rotazione opposta)
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(-_phase * 0.2);
    final ring2Paint = Paint()
      ..color = _getCurrentColor().withValues(alpha: scale <= 1.01 ? 0.3 : 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * scale;
    canvas.drawCircle(Offset.zero, r * 0.7, ring2Paint);
    canvas.restore();

    // Sfera principale
    final sphereColor = scale <= 1.01 ? _getCurrentColor() : paint.color;
    final spherePaint = Paint()..color = sphereColor;
    canvas.drawCircle(Offset(cx, cy), r * 0.5, spherePaint);

    // Dettagli interni
    if (scale <= 1.01) {
      // Nucleo bianco pulsante
      final pulse = 0.5 + math.sin(_phase * 2) * 0.3;
      final corePaint = Paint()
        ..color = const Color(0xFFFFFFFF).withValues(alpha: pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawCircle(Offset(cx, cy), r * 0.25, corePaint);

      // Particelle orbitanti
      for (int i = 0; i < 6; i++) {
        final pAngle = _phase * 1.5 + i * math.pi / 3;
        final pR = r * 0.65;
        final px = cx + pR * math.cos(pAngle);
        final py = cy + pR * math.sin(pAngle);
        final pPaint = Paint()
          ..color = _getCurrentColor().withValues(alpha: 0.6)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
        canvas.drawCircle(Offset(px, py), 3, pPaint);
      }

      // Indicatore fase (punti luminosi)
      for (int i = 0; i <= currentPhase; i++) {
        final dotX = cx - 10 + i * 7.0;
        final dotY = cy + r * 0.5 + 10;
        canvas.drawCircle(Offset(dotX, dotY), 2, Paint()..color = _getCurrentColor());
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

  @override
  void render(Canvas canvas) {
    final p = Paint()..color = color..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), 4, p);
    p.maskFilter = null;
    p.color = const Color(0xFFFFFFFF).withValues(alpha: 0.8);
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), 2, p);
  }
}

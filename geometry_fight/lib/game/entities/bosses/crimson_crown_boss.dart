import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../../data/constants.dart';
import '../../../data/wave_configs.dart';
import 'boss_base.dart';
import '../projectiles.dart';

/// CRIMSON CROWN (wave 5 — primo boss).
///
/// Meccaniche uniche:
///   - 6 orbi di fuoco orbitano intorno al boss.
///   - Fase 1 (HP >50%): orbi sparano radiali a stella.
///   - Fase 2 (50%–25%): orbi sparano homing verso il player.
///   - Fase 3 (<25%): spawn "lava mines" sotto i piedi del player (burst radiale).
///
/// FX: corona 5 spike sopra il corpo, core magma pulsante, orbi orbitanti
/// con glow, danger ring rosso lampeggiante a bassa HP.
class CrimsonCrownBoss extends BossBase {
  double _phase = 0;
  double _orbShootTimer = 2.0;
  double _lavaMineTimer = 5.0;
  // Lava mine wind-up: spawna solo la FX di warning, dopo `_lavaMineWindUp`
  // secondi parte il burst di bullet. Permette al player di schivare.
  Vector2? _lavaMineTarget;
  double _lavaMineWindUp = 0;

  static final _orbPaint = Paint();
  static final _orbGlowPaint = Paint();
  static final _crownSpikePaint = Paint();
  static final _corePulsePaint = Paint();
  static final _lavaRingPaint = Paint()..style = PaintingStyle.stroke;

  CrimsonCrownBoss()
      : super(
          // +50% HP (era 400, ora 600) — richiesta utente:
          // "crimson crown deve avere il 50% in piu degli hp".
          hp: 600,
          bossName: 'CRIMSON CROWN',
          pointValue: 5000,
          neonColor: NeonColors.orange,
          size: Vector2(100, 100),
        );

  // CrimsonCrown è ARANCIONE/ROSSO → mob fuoco (kamikaze + swarmDrone + splitter).
  @override
  List<EnemyType> get colorMatchedMinions =>
      const [EnemyType.kamikaze, EnemyType.swarmDrone, EnemyType.splitter];

  // CrimsonCrown ha orbi orbitanti che estendono il visivo verso il bordo
  // bbox (size 100). Override 0.7 → 0.85 → bullet ricochet/homing
  // colpiscono il body senza "pass-through" sull'edge.
  @override
  double get hitboxRadiusFactor => 0.85;

  @override
  int getPhase() {
    if (healthPercent < 0.25) return 2;
    if (healthPercent < 0.50) return 1;
    return 0;
  }

  @override
  void updateBoss(double dt) {
    _phase += dt;
    // Wrap _phase per evitare float drift su fight lunghi.
    if (_phase > math.pi * 20) _phase -= math.pi * 20;

    final toPlayer = playerPosition - position;
    if (toPlayer.length > 180) {
      position += toPlayer.normalized() * 50 * dt;
    }

    _orbShootTimer -= dt;
    if (_orbShootTimer <= 0) {
      _orbShootTimer = currentPhase >= 1 ? 1.8 : 2.5;
      for (int i = 0; i < 6; i++) {
        final orbAngle = _phase * 0.8 + i * math.pi * 2 / 6;
        final orbPos = position +
            Vector2(math.cos(orbAngle) * 60, math.sin(orbAngle) * 60);
        // Homing (fase 1+): guard NaN se player esattamente su orb.
        Vector2 bdir;
        if (currentPhase >= 1) {
          final delta = playerPosition - orbPos;
          bdir = delta.length > 0.001
              ? delta.normalized()
              : Vector2(math.cos(orbAngle), math.sin(orbAngle));
        } else {
          bdir = Vector2(math.cos(orbAngle), math.sin(orbAngle));
        }
        final bullet = EnemyBullet(
            direction: bdir, speed: 260, color: NeonColors.orange);
        bullet.position = orbPos.clone();
        game.world.add(bullet);
      }
    }

    // Lava mine con wind-up di 0.6s: target viene marcato con explosion di
    // warning, poi parte il burst radiale — player ha tempo di schivare.
    if (currentPhase >= 2) {
      if (_lavaMineTarget == null) {
        _lavaMineTimer -= dt;
        if (_lavaMineTimer <= 0) {
          _lavaMineTimer = 3.0; // prossimo ciclo dopo detonation
          _lavaMineTarget = playerPosition.clone();
          _lavaMineWindUp = 0.6;
          // FX warning (piccolo — non danneggia).
          game.spawnExplosion(_lavaMineTarget!, NeonColors.red,
              radius: 20, particleCount: 5);
        }
      } else {
        _lavaMineWindUp -= dt;
        if (_lavaMineWindUp <= 0) {
          final minePos = _lavaMineTarget!;
          for (int i = 0; i < 8; i++) {
            final ang = i * math.pi / 4;
            final bullet = EnemyBullet(
                direction: Vector2(math.cos(ang), math.sin(ang)),
                speed: 90, // un po' più veloce visto il warning dato
                color: NeonColors.red);
            bullet.position = minePos.clone();
            game.world.add(bullet);
          }
          game.spawnExplosion(minePos, NeonColors.red, radius: 50);
          _lavaMineTarget = null;
        }
      }
    }
  }

  @override
  void renderBoss(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;

    final corePulse = 0.85 + math.sin(_phase * 4) * 0.15;
    _corePulsePaint.color = NeonColors.red
        .withValues(alpha: paint.color.a * 0.45 * corePulse);
    canvas.drawCircle(Offset(cx, cy), 35 * scale * corePulse, _corePulsePaint);
    canvas.drawCircle(Offset(cx, cy), 25 * scale, paint);
    _corePulsePaint.color = const Color(0xFFFFDD22)
        .withValues(alpha: paint.color.a * corePulse);
    canvas.drawCircle(Offset(cx, cy), 12 * scale * corePulse, _corePulsePaint);
    _corePulsePaint.color =
        const Color(0xFFFFFFFF).withValues(alpha: paint.color.a * 0.9);
    canvas.drawCircle(Offset(cx, cy), 4 * scale, _corePulsePaint);

    // Corona 5 spike sopra il corpo
    for (int i = 0; i < 5; i++) {
      final spikeAngle = -math.pi / 2 + (i - 2) * 0.35;
      final baseR = 28 * scale;
      final tipR = 46 * scale + math.sin(_phase * 3 + i) * 4 * scale;
      final bx1 = cx + math.cos(spikeAngle - 0.12) * baseR;
      final by1 = cy + math.sin(spikeAngle - 0.12) * baseR;
      final bx2 = cx + math.cos(spikeAngle + 0.12) * baseR;
      final by2 = cy + math.sin(spikeAngle + 0.12) * baseR;
      final tx = cx + math.cos(spikeAngle) * tipR;
      final ty = cy + math.sin(spikeAngle) * tipR;
      final path = Path()
        ..moveTo(bx1, by1)
        ..lineTo(tx, ty)
        ..lineTo(bx2, by2)
        ..close();
      _crownSpikePaint.color =
          const Color(0xFFFFAA22).withValues(alpha: paint.color.a);
      canvas.drawPath(path, _crownSpikePaint);
      _crownSpikePaint.color =
          const Color(0xFFFFFFFF).withValues(alpha: paint.color.a * 0.8);
      canvas.drawCircle(Offset(tx, ty), 2 * scale, _crownSpikePaint);
    }

    // 6 orbi orbitanti
    for (int i = 0; i < 6; i++) {
      final orbAngle = _phase * 0.8 + i * math.pi * 2 / 6;
      final ox = cx + math.cos(orbAngle) * 60 * scale;
      final oy = cy + math.sin(orbAngle) * 60 * scale;
      final orbPulse = 0.6 + math.sin(_phase * 5 + i) * 0.4;
      _orbGlowPaint.color = NeonColors.orange
          .withValues(alpha: paint.color.a * 0.4 * orbPulse);
      canvas.drawCircle(Offset(ox, oy), 10 * scale * orbPulse, _orbGlowPaint);
      _orbPaint.color =
          const Color(0xFFFF5522).withValues(alpha: paint.color.a);
      canvas.drawCircle(Offset(ox, oy), 5 * scale, _orbPaint);
      _orbPaint.color =
          const Color(0xFFFFFFFF).withValues(alpha: paint.color.a * orbPulse);
      canvas.drawCircle(Offset(ox, oy), 2 * scale, _orbPaint);
    }

    // Lava ring danger (fase 3)
    if (currentPhase >= 2) {
      final strobe = 0.4 + math.sin(_phase * 10) * 0.3;
      _lavaRingPaint.color =
          NeonColors.red.withValues(alpha: strobe * paint.color.a);
      _lavaRingPaint.strokeWidth = 2.5;
      canvas.drawCircle(Offset(cx, cy), 55 * scale, _lavaRingPaint);
      _lavaRingPaint.color = const Color(0xFFFFAA00)
          .withValues(alpha: strobe * 0.5 * paint.color.a);
      canvas.drawCircle(Offset(cx, cy), 70 * scale, _lavaRingPaint);
    }
  }
}

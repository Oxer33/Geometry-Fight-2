import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../../data/constants.dart';
import '../../../data/wave_configs.dart';
import 'boss_base.dart';
import '../projectiles.dart';

/// VOID KRAKEN (wave 25).
///
/// Meccaniche uniche:
///   - 6 tentacoli orbitanti + "gravity pull" che risucchia il player
///     entro un raggio di 280px (340 in fase rage).
///   - Fase 1: ink cloud 6 proiettili grossi lenti + pull base.
///   - Fase 2 (<60% HP): spawn 6 proton enemies dalla punta dei tentacoli
///     ogni 6s.
///   - Fase 3 (<25% HP): pull potenziato + burst radiale 10 proiettili ink.
///
/// FX: 6 tentacoli sinuosi animati con wobble, core con 2 occhi viola,
/// vortex ring pulsante al pericolo.
class VoidKrakenBoss extends BossBase {
  double _phase = 0;
  double _inkTimer = 1.5;
  double _protonTimer = 4.0;

  static final _tentaclePaint = Paint()..style = PaintingStyle.stroke;
  static final _tentacleGlowPaint = Paint()..style = PaintingStyle.stroke;
  static final _corePulsePaint = Paint();
  static final _vortexPaint = Paint()..style = PaintingStyle.stroke;
  static final _tentaclePath = Path();

  VoidKrakenBoss()
      : super(
          hp: 750,
          bossName: 'VOID KRAKEN',
          pointValue: 7500,
          neonColor: NeonColors.purple,
          size: Vector2(120, 120),
        );

  @override
  int getPhase() {
    if (healthPercent < 0.25) return 2;
    if (healthPercent < 0.60) return 1;
    return 0;
  }

  @override
  void updateBoss(double dt) {
    _phase += dt;

    final toPlayer = playerPosition - position;
    if (toPlayer.length > 260) {
      position += toPlayer.normalized() * 40 * dt;
    } else if (toPlayer.length < 180) {
      position -= toPlayer.normalized() * 30 * dt;
    }

    // Gravity pull sul player
    final pullRadius = currentPhase >= 2 ? 340.0 : 280.0;
    final pullForce = currentPhase >= 2 ? 120.0 : 80.0;
    final toBoss = position - playerPosition;
    if (toBoss.length < pullRadius && toBoss.length > 20) {
      game.player.position += toBoss.normalized() * pullForce * dt;
    }

    // Ink cloud
    _inkTimer -= dt;
    if (_inkTimer <= 0) {
      _inkTimer = currentPhase >= 2 ? 2.0 : 3.0;
      final count = currentPhase >= 2 ? 10 : 6;
      for (int i = 0; i < count; i++) {
        final ang = _phase * 0.5 + i * math.pi * 2 / count;
        final bullet = EnemyBullet(
            direction: Vector2(math.cos(ang), math.sin(ang)),
            speed: 130,
            color: NeonColors.purple);
        bullet.position = position.clone();
        game.world.add(bullet);
      }
    }

    // Proton spawn (fase 1+)
    if (currentPhase >= 1) {
      _protonTimer -= dt;
      if (_protonTimer <= 0) {
        _protonTimer = 6.0;
        for (int i = 0; i < 6; i++) {
          final ang = _phase * 0.8 + i * math.pi * 2 / 6;
          final tipPos = position +
              Vector2(math.cos(ang) * 90, math.sin(ang) * 90);
          game.spawnEnemy(EnemyType.proton, tipPos);
        }
      }
    }
  }

  @override
  void renderBoss(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final centerPoint = Offset(cx, cy);

    // 6 tentacoli sinuosi
    for (int i = 0; i < 6; i++) {
      final baseAngle = _phase * 0.4 + i * math.pi * 2 / 6;
      const segments = 5;
      _tentaclePath.reset();
      _tentaclePath.moveTo(cx, cy);
      for (int s = 1; s <= segments; s++) {
        final tFrac = s / segments;
        final wobble = math.sin(_phase * 3 + i + s * 0.6) * 14 * tFrac;
        final r = 90 * tFrac * scale;
        final perpAng = baseAngle + math.pi / 2;
        final sx = cx + math.cos(baseAngle) * r + math.cos(perpAng) * wobble;
        final sy = cy + math.sin(baseAngle) * r + math.sin(perpAng) * wobble;
        _tentaclePath.lineTo(sx, sy);
      }
      _tentacleGlowPaint.color =
          NeonColors.purple.withValues(alpha: paint.color.a * 0.35);
      _tentacleGlowPaint.strokeWidth = 10 * scale;
      canvas.drawPath(_tentaclePath, _tentacleGlowPaint);
      _tentaclePaint.color = paint.color;
      _tentaclePaint.strokeWidth = 3 * scale;
      canvas.drawPath(_tentaclePath, _tentaclePaint);
      final tipX = cx + math.cos(baseAngle) * 90 * scale;
      final tipY = cy + math.sin(baseAngle) * 90 * scale;
      _corePulsePaint.color =
          const Color(0xFFFFFFFF).withValues(alpha: paint.color.a * 0.8);
      canvas.drawCircle(Offset(tipX, tipY), 3 * scale, _corePulsePaint);
    }

    // Corpo centrale
    final corePulse = 0.85 + math.sin(_phase * 4) * 0.15;
    _corePulsePaint.color = NeonColors.purple
        .withValues(alpha: paint.color.a * 0.5 * corePulse);
    canvas.drawCircle(centerPoint, 35 * scale * corePulse, _corePulsePaint);
    canvas.drawCircle(centerPoint, 28 * scale, paint);
    _corePulsePaint.color =
        const Color(0xFF220044).withValues(alpha: paint.color.a);
    canvas.drawCircle(centerPoint, 18 * scale, _corePulsePaint);
    _corePulsePaint.color = const Color(0xFFFF22FF)
        .withValues(alpha: paint.color.a * corePulse);
    canvas.drawCircle(
        Offset(cx - 8 * scale, cy - 4 * scale), 3 * scale, _corePulsePaint);
    canvas.drawCircle(
        Offset(cx + 8 * scale, cy - 4 * scale), 3 * scale, _corePulsePaint);

    // Vortex danger
    if (currentPhase >= 2) {
      final strobe = 0.3 + math.sin(_phase * 8) * 0.2;
      _vortexPaint.color =
          NeonColors.purple.withValues(alpha: strobe * paint.color.a);
      _vortexPaint.strokeWidth = 2 * scale;
      canvas.drawCircle(centerPoint, 70 * scale, _vortexPaint);
      _vortexPaint.color =
          NeonColors.red.withValues(alpha: strobe * 0.4 * paint.color.a);
      canvas.drawCircle(centerPoint, 90 * scale, _vortexPaint);
    }
  }
}

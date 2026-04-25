import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../../data/constants.dart';
import '../../../data/wave_configs.dart';
import 'boss_base.dart';
import '../projectiles.dart';

/// PRISM HUNTER (wave 15).
///
/// Meccaniche uniche:
///   - Corpo triangolare (prisma) rotante che spara un laser "sweeping" continuo.
///   - Fase 1: sweeping laser a 360° (proiettili veloci in fila).
///   - Fase 2 (<60% HP): 3 raggi refratti simultanei (RGB split) verso il player.
///   - Fase 3 (<30% HP): bullet hell arcobaleno 7 colori × 7 angoli radiali.
///
/// FX: prisma cristallino con 3 vertici colorati R/G/B, raggio rotante
/// indicatore dello sweep, aura arcobaleno in fase 2.
// Costanti di tuning (tirate dopo caveman-review per budget bullet/s).
// Sweep a 0.14s = 7 bullet/s (era 0.08=12.5). In fase 2, sweep+refract+rainbow
// totale ≈ 20 bullet/s, gestibile su device medi.
// User "alcuni boss sparano troppi proiettili": era 0.14s (7 bullet/sec)
// → ora 0.35s (~3/sec), più gestibile.
const double _kSweepInterval = 0.35;
const double _kTriAngle1 = math.pi * 2 / 3; // 120°
const double _kTriAngle2 = math.pi * 4 / 3; // 240°

class PrismHunterBoss extends BossBase {
  double _phase = 0;
  double _sweepAngle = 0;
  double _sweepShootTimer = _kSweepInterval;
  double _refractTimer = 1.5;
  double _rainbowTimer = 0.3;

  static final _prismBodyPaint = Paint();
  static final _prismEdgePaint = Paint()..style = PaintingStyle.stroke;
  static final _refractRayPaint = Paint();
  static final _sweepLinePaint = Paint()..style = PaintingStyle.stroke;

  static const _rainbow = [
    Color(0xFFFF0000),
    Color(0xFFFF7700),
    Color(0xFFFFDD00),
    Color(0xFF00DD00),
    Color(0xFF00AAFF),
    Color(0xFF3322FF),
    Color(0xFFAA22FF),
  ];

  PrismHunterBoss()
      : super(
          hp: 600,
          bossName: 'PRISM HUNTER',
          pointValue: 6500,
          neonColor: NeonColors.cyan,
          size: Vector2(110, 110),
        );

  // PrismHunter è CIANO/PRISMATICO → mob ciano-arcobaleno (drone + orbiter + mirror).
  @override
  List<EnemyType> get colorMatchedMinions =>
      const [EnemyType.drone, EnemyType.orbiter, EnemyType.mirror];

  @override
  int getPhase() {
    if (healthPercent < 0.30) return 2;
    if (healthPercent < 0.60) return 1;
    return 0;
  }

  @override
  void updateBoss(double dt) {
    _phase += dt;
    _sweepAngle += dt * 1.2;

    final toPlayer = playerPosition - position;
    // NaN guard: se player coincide col boss, normalized() NaN. Skip.
    if (toPlayer.length > 220) {
      position += toPlayer.normalized() * 45 * dt;
    } else if (toPlayer.length > 0.001 && toPlayer.length < 160) {
      position -= toPlayer.normalized() * 30 * dt;
    }

    _sweepShootTimer -= dt;
    if (_sweepShootTimer <= 0) {
      _sweepShootTimer = _kSweepInterval;
      final bdir = Vector2(math.cos(_sweepAngle), math.sin(_sweepAngle));
      final bullet = EnemyBullet(
          direction: bdir, speed: 400, color: const Color(0xFF00FFFF));
      bullet.position = position.clone();
      game.world.add(bullet);
    }

    if (currentPhase >= 1) {
      _refractTimer -= dt;
      if (_refractTimer <= 0) {
        _refractTimer = 2.2;
        final baseAngle = math.atan2(
            playerPosition.y - position.y, playerPosition.x - position.x);
        const colors = [
          Color(0xFFFF2255),
          Color(0xFF22FF55),
          Color(0xFF2255FF)
        ];
        for (int i = 0; i < 3; i++) {
          final ang = baseAngle + (i - 1) * 0.35;
          for (int step = 0; step < 4; step++) {
            final bullet = EnemyBullet(
                direction: Vector2(math.cos(ang), math.sin(ang)),
                speed: 320 + step * 40.0,
                color: colors[i]);
            bullet.position = position.clone();
            game.world.add(bullet);
          }
        }
      }
    }

    if (currentPhase >= 2) {
      _rainbowTimer -= dt;
      if (_rainbowTimer <= 0) {
        _rainbowTimer = 0.45;
        for (int i = 0; i < 7; i++) {
          final ang = _phase * 0.7 + i * math.pi * 2 / 7;
          final bullet = EnemyBullet(
              direction: Vector2(math.cos(ang), math.sin(ang)),
              speed: 280,
              color: _rainbow[i]);
          bullet.position = position.clone();
          game.world.add(bullet);
        }
      }
    }
  }

  @override
  void renderBoss(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final rot = _phase * 0.5;

    final r = 28 * scale;
    final p1 = Offset(cx + math.cos(rot) * r, cy + math.sin(rot) * r);
    final p2 = Offset(cx + math.cos(rot + _kTriAngle1) * r,
        cy + math.sin(rot + _kTriAngle1) * r);
    final p3 = Offset(cx + math.cos(rot + _kTriAngle2) * r,
        cy + math.sin(rot + _kTriAngle2) * r);
    final path = Path()
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p3.dx, p3.dy)
      ..close();
    _prismBodyPaint.color = paint.color.withValues(alpha: paint.color.a * 0.5);
    canvas.drawPath(path, _prismBodyPaint);
    _prismEdgePaint.color = paint.color;
    _prismEdgePaint.strokeWidth = 2 * scale;
    canvas.drawPath(path, _prismEdgePaint);

    const refractColors = [
      Color(0xFFFF2255),
      Color(0xFF22FF55),
      Color(0xFF2255FF)
    ];
    for (int i = 0; i < 3; i++) {
      final vertex = [p1, p2, p3][i];
      final pulse = 0.6 + math.sin(_phase * 4 + i) * 0.4;
      _refractRayPaint.color =
          refractColors[i].withValues(alpha: paint.color.a * 0.6 * pulse);
      canvas.drawCircle(vertex, 8 * scale * pulse, _refractRayPaint);
      _refractRayPaint.color =
          const Color(0xFFFFFFFF).withValues(alpha: paint.color.a * pulse);
      canvas.drawCircle(vertex, 2 * scale, _refractRayPaint);
    }

    _prismBodyPaint.color =
        const Color(0xFFFFFFFF).withValues(alpha: paint.color.a * 0.9);
    canvas.drawCircle(Offset(cx, cy), 8 * scale, _prismBodyPaint);

    _sweepLinePaint.color =
        const Color(0xFF00FFFF).withValues(alpha: paint.color.a * 0.6);
    _sweepLinePaint.strokeWidth = 1.2 * scale;
    final bx = cx + math.cos(_sweepAngle) * 80 * scale;
    final by = cy + math.sin(_sweepAngle) * 80 * scale;
    canvas.drawLine(Offset(cx, cy), Offset(bx, by), _sweepLinePaint);

    if (currentPhase >= 2) {
      for (int i = 0; i < 7; i++) {
        final ang = _phase * 0.4 + i * math.pi * 2 / 7;
        final rx = cx + math.cos(ang) * 50 * scale;
        final ry = cy + math.sin(ang) * 50 * scale;
        _refractRayPaint.color =
            _rainbow[i].withValues(alpha: paint.color.a * 0.7);
        canvas.drawCircle(Offset(rx, ry), 3 * scale, _refractRayPaint);
      }
    }
  }
}

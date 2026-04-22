import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../game_world.dart';
import 'boss_base.dart';

/// TESLA LORD - Boss elettrico che crea campi di fulmini e scariche a catena.
/// Forma: ottagono grande con archi elettrici rotanti
/// Colore: giallo elettrico (#FFDD00)
/// HP: 2000 · 3 fasi
/// Meccanica: crea 4 torri tesla nell'arena che generano fulmini tra di loro.
/// Il player deve evitare i fulmini mentre combatte. Fase finale: tempesta elettrica.
class TeslaLordBoss extends BossBase {
  double _sparkPhase = 0;
  double _attackTimer = 2.0;
  double _towerSpawnTimer = 8.0;
  final List<Vector2> _towerPositions = [];

  TeslaLordBoss()
      : super(
          hp: 2000,
          bossName: 'TESLA LORD',
          pointValue: 4000,
          neonColor: const Color(0xFFFFDD00),
          size: Vector2(110, 110),
        );

  @override
  int getPhase() {
    if (healthPercent > 0.6) return 0;
    if (healthPercent > 0.25) return 1;
    return 2;
  }

  @override
  void onPhaseChange(int phase) {
    _spawnTowers(2 + phase);
  }

  void _spawnTowers(int count) {
    _towerPositions.clear();
    final random = math.Random();
    for (int i = 0; i < count; i++) {
      final angle = i * math.pi * 2 / count;
      final dist = 200 + random.nextDouble() * 150;
      _towerPositions.add(position + Vector2(
        math.cos(angle) * dist,
        math.sin(angle) * dist,
      ));
    }
  }

  @override
  void updateBoss(double dt) {
    _sparkPhase += dt * 10;

    // Movimento lento con orbita
    final orbitAngle = _sparkPhase * 0.05;
    final targetPos = playerPosition + Vector2(
      math.cos(orbitAngle) * 250,
      math.sin(orbitAngle) * 250,
    );
    final toTarget = targetPos - position;
    if (toTarget.length > 10) {
      position += toTarget.normalized() * 70 * dt;
    }

    // Spawn torri periodicamente
    _towerSpawnTimer -= dt;
    if (_towerSpawnTimer <= 0) {
      _towerSpawnTimer = currentPhase == 2 ? 5.0 : 8.0;
      _spawnTowers(3 + currentPhase);
    }

    // Attacco: proiettili
    _attackTimer -= dt;
    if (_attackTimer <= 0) {
      _attackTimer = currentPhase == 2 ? 0.8 : 1.5;
      _shootSpiral();
    }

    // Danno dai fulmini tra le torri
    if (_towerPositions.length >= 2) {
      for (int i = 0; i < _towerPositions.length; i++) {
        final next = _towerPositions[(i + 1) % _towerPositions.length];
        final playerDist = _distToSegment(game.player.position, _towerPositions[i], next);
        if (playerDist < 20) {
          game.player.takeDamage();
          break;
        }
      }
    }
  }

  double _distToSegment(Vector2 p, Vector2 a, Vector2 b) {
    final ab = b - a;
    final len = ab.length;
    if (len == 0) return p.distanceTo(a);
    final t = ((p - a).dot(ab) / (len * len)).clamp(0.0, 1.0);
    return p.distanceTo(a + ab * t);
  }

  void _shootSpiral() {
    final count = 6 + currentPhase * 2;
    for (int i = 0; i < count; i++) {
      final angle = i * math.pi * 2 / count + _sparkPhase * 0.05;
      final dir = Vector2(math.cos(angle), math.sin(angle));
      final bullet = _TeslaBullet(direction: dir, color: neonColor);
      bullet.position = position.clone();
      game.world.add(bullet);
    }
  }

  // Paint cache FX
  static final _towerGlowPaint = Paint();
  static final _towerCorePaint = Paint();
  static final _towerOutlinePaint = Paint()..style = PaintingStyle.stroke;
  static final _lightningOuterPaint = Paint()..style = PaintingStyle.stroke;
  static final _lightningCorePaint = Paint()..style = PaintingStyle.stroke;
  static final _arcPaint = Paint()..style = PaintingStyle.stroke;
  static final _coreHaloPaint = Paint();
  static final _corePaint = Paint();
  static final _sparkBoltPath = Path();

  @override
  void renderBoss(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final r = size.x / 2 * scale;

    // ─── TORRI TESLA + RETE DI FULMINI ───
    if (scale <= 1.01 && _towerPositions.length >= 2) {
      for (int i = 0; i < _towerPositions.length; i++) {
        final offset = _towerPositions[i] - position;
        final tCx = cx + offset.x;
        final tCy = cy + offset.y;
        final towerPulse = 0.7 + math.sin(_sparkPhase + i * 1.3) * 0.3;
        // Glow esterno (alone)
        _towerGlowPaint.color =
            neonColor.withValues(alpha: 0.25 * towerPulse);
        canvas.drawCircle(Offset(tCx, tCy), 18, _towerGlowPaint);
        // Core bianco pulsante
        _towerCorePaint.color = const Color(0xFFFFFFFF)
            .withValues(alpha: 0.85 * towerPulse);
        canvas.drawCircle(Offset(tCx, tCy), 5, _towerCorePaint);
        // Outline
        _towerOutlinePaint.color = neonColor;
        _towerOutlinePaint.strokeWidth = 1.5;
        canvas.drawCircle(Offset(tCx, tCy), 9, _towerOutlinePaint);

        // Fulmine perimetrale alla prossima torre
        final next = _towerPositions[(i + 1) % _towerPositions.length];
        final nextOffset = next - position;
        _drawLightning(
            canvas, tCx, tCy, cx + nextOffset.x, cy + nextOffset.y);
        // Fulmine centro-torre (rete densa)
        _drawLightning(canvas, cx, cy, tCx, tCy, intensity: 0.5);
      }
    }

    // ─── ELECTRIC FIELD attorno al boss ───
    if (scale <= 1.01) {
      final fieldPulse = 0.5 + math.sin(_sparkPhase * 1.2) * 0.5;
      _arcPaint.color =
          neonColor.withValues(alpha: 0.2 + fieldPulse * 0.2);
      _arcPaint.strokeWidth = 1.5;
      canvas.drawCircle(Offset(cx, cy), r * 1.3, _arcPaint);
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(-_sparkPhase * 0.4);
      _arcPaint.color =
          const Color(0xFFFFFFFF).withValues(alpha: 0.15 + fieldPulse * 0.15);
      _arcPaint.strokeWidth = 1;
      canvas.drawArc(
          Rect.fromCircle(center: Offset.zero, radius: r * 1.1),
          0, math.pi * 0.6, false, _arcPaint);
      canvas.drawArc(
          Rect.fromCircle(center: Offset.zero, radius: r * 1.1),
          math.pi, math.pi * 0.6, false, _arcPaint);
      canvas.restore();
    }

    // ─── OTTAGONO PRINCIPALE ───
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(_sparkPhase * 0.03);
    final path = Path();
    for (int i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      final x = r * 0.8 * math.cos(angle);
      final y = r * 0.8 * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);

    // ─── ARCHI ELETTRICI INTERNI (8 spokes) ───
    if (scale <= 1.01) {
      for (int i = 0; i < 8; i++) {
        final angle = i * math.pi / 4 + _sparkPhase * 0.1;
        final intensity = 0.5 + math.sin(_sparkPhase * 2 + i) * 0.5;
        _arcPaint.color = const Color(0xFFFFFFFF)
            .withValues(alpha: 0.25 + intensity * 0.4);
        _arcPaint.strokeWidth = 1.5;
        canvas.drawLine(Offset.zero,
            Offset(r * 0.6 * math.cos(angle), r * 0.6 * math.sin(angle)),
            _arcPaint);
      }

      // Nucleo (halo + core)
      final pulse = 0.6 + math.sin(_sparkPhase * 0.5) * 0.4;
      _coreHaloPaint.color =
          const Color(0xFFFFFFFF).withValues(alpha: pulse * 0.4);
      canvas.drawCircle(Offset.zero, r * 0.4, _coreHaloPaint);
      _corePaint.color = const Color(0xFFFFFFFF).withValues(alpha: pulse);
      canvas.drawCircle(Offset.zero, r * 0.2, _corePaint);
    }
    canvas.restore();
  }

  void _drawLightning(Canvas canvas, double x1, double y1, double x2, double y2,
      {double intensity = 1.0}) {
    // Seed include sia x1 che y1 così due torri con lo stesso x ma y diverso
    // (allineate verticalmente) producono jitter pattern diversi → fulmini
    // visivamente distinti anche quando paralleli.
    final random = math.Random(
        (_sparkPhase * 5).toInt() ^ x1.toInt() ^ (y1.toInt() << 8));
    _sparkBoltPath.reset();
    _sparkBoltPath.moveTo(x1, y1);
    const steps = 6;
    for (int i = 1; i < steps; i++) {
      final t = i / steps;
      _sparkBoltPath.lineTo(
        x1 + (x2 - x1) * t + (random.nextDouble() - 0.5) * 22,
        y1 + (y2 - y1) * t + (random.nextDouble() - 0.5) * 22,
      );
    }
    _sparkBoltPath.lineTo(x2, y2);

    // Glow esterno colorato
    _lightningOuterPaint.color =
        neonColor.withValues(alpha: 0.35 * intensity);
    _lightningOuterPaint.strokeWidth = 5;
    canvas.drawPath(_sparkBoltPath, _lightningOuterPaint);
    // Core bianco brillante
    _lightningCorePaint.color =
        const Color(0xFFFFFFFF).withValues(alpha: 0.95 * intensity);
    _lightningCorePaint.strokeWidth = 1.5;
    canvas.drawPath(_sparkBoltPath, _lightningCorePaint);
  }
}

class _TeslaBullet extends PositionComponent with HasGameReference<GeometryFightGame> {
  final Vector2 direction;
  final Color color;
  late Vector2 _velocity;
  double _lifetime = 3.0;

  _TeslaBullet({required this.direction, required this.color})
      : super(size: Vector2(6, 6), anchor: Anchor.center);

  @override
  Future<void> onLoad() async { _velocity = direction.normalized() * 220; }

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

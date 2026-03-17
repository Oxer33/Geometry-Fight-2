import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../../data/constants.dart';
import '../../../data/wave_configs.dart';
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

  @override
  void renderBoss(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final r = size.x / 2 * scale;

    // Torri tesla e fulmini
    if (scale <= 1.01 && _towerPositions.length >= 2) {
      for (int i = 0; i < _towerPositions.length; i++) {
        final offset = _towerPositions[i] - position;
        // Torre
        final towerPaint = Paint()
          ..color = neonColor.withValues(alpha: 0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawCircle(Offset(cx + offset.x, cy + offset.y), 8, towerPaint);

        // Fulmine alla torre successiva
        final next = _towerPositions[(i + 1) % _towerPositions.length];
        final nextOffset = next - position;
        _drawLightning(canvas, cx + offset.x, cy + offset.y, cx + nextOffset.x, cy + nextOffset.y);
      }
    }

    // Ottagono principale
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(_sparkPhase * 0.03);
    final path = Path();
    for (int i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      final x = r * 0.8 * math.cos(angle);
      final y = r * 0.8 * math.sin(angle);
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paint);

    // Archi elettrici interni
    if (scale <= 1.01) {
      for (int i = 0; i < 4; i++) {
        final angle = i * math.pi / 2 + _sparkPhase * 0.1;
        final lp = Paint()
          ..color = neonColor.withValues(alpha: 0.4)
          ..strokeWidth = 1.5
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
        canvas.drawLine(Offset.zero, Offset(r * 0.6 * math.cos(angle), r * 0.6 * math.sin(angle)), lp);
      }

      // Nucleo
      final pulse = 0.5 + math.sin(_sparkPhase * 0.5) * 0.3;
      final corePaint = Paint()
        ..color = const Color(0xFFFFFFFF).withValues(alpha: pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(Offset.zero, r * 0.2, corePaint);
    }
    canvas.restore();
  }

  void _drawLightning(Canvas canvas, double x1, double y1, double x2, double y2) {
    final random = math.Random((_sparkPhase * 5).toInt());
    final path = Path()..moveTo(x1, y1);
    final steps = 5;
    for (int i = 1; i < steps; i++) {
      final t = i / steps;
      path.lineTo(
        x1 + (x2 - x1) * t + (random.nextDouble() - 0.5) * 20,
        y1 + (y2 - y1) * t + (random.nextDouble() - 0.5) * 20,
      );
    }
    path.lineTo(x2, y2);

    final lp = Paint()
      ..color = neonColor.withValues(alpha: 0.5)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawPath(path, lp);
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

  @override
  void render(Canvas canvas) {
    final p = Paint()..color = color..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), 3, p);
  }
}

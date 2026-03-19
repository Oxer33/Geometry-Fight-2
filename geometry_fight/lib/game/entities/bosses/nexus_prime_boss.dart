import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../../data/constants.dart';
import '../../game_world.dart';
import 'boss_base.dart';

/// NEXUS PRIME - Boss che crea portali e si teletrasporta attraverso l'arena.
/// Forma: doppio esagono concentrico con nucleo energetico
/// Colore: ciano brillante (#00EEFF)
/// HP: 1600 · 3 fasi
/// Meccanica: crea 2-4 portali nell'arena. Si teletrasporta tra di essi.
/// I portali sparano proiettili. Fase finale: tutti i portali sparano simultaneamente.
class NexusPrimeBoss extends BossBase {
  double _attackTimer = 3.0;
  double _teleportTimer = 5.0;
  double _portalPhase = 0;
  final List<Vector2> _portalPositions = [];
  int _currentPortal = 0;

  NexusPrimeBoss()
      : super(
          hp: 1600,
          bossName: 'NEXUS PRIME',
          pointValue: 3000,
          neonColor: const Color(0xFF00EEFF),
          size: Vector2(90, 90),
        );

  @override
  int getPhase() {
    if (healthPercent > 0.6) return 0;
    if (healthPercent > 0.3) return 1;
    return 2;
  }

  @override
  void onPhaseChange(int phase) {
    // Aggiungi portali ad ogni fase
    _createPortals(2 + phase);
  }

  void _createPortals(int count) {
    _portalPositions.clear();
    final random = math.Random();
    for (int i = 0; i < count; i++) {
      _portalPositions.add(Vector2(
        300 + random.nextDouble() * (arenaWidth - 600),
        300 + random.nextDouble() * (arenaHeight - 600),
      ));
    }
  }

  @override
  void updateBoss(double dt) {
    _portalPhase += dt * 3;

    if (_portalPositions.isEmpty) {
      _createPortals(2);
    }

    // Movimento verso il player (lento)
    final toPlayer = (playerPosition - position);
    if (toPlayer.length > 200) {
      position += toPlayer.normalized() * 60 * dt;
    }

    // Teletrasporto periodico tra portali
    _teleportTimer -= dt;
    if (_teleportTimer <= 0 && _portalPositions.isNotEmpty) {
      _teleportTimer = currentPhase == 2 ? 2.0 : 4.0;
      _currentPortal = (_currentPortal + 1) % _portalPositions.length;
      position = _portalPositions[_currentPortal].clone();
      game.triggerScreenShake(3, 0.15);
      game.grid.applyForce(position, 100, 400);
    }

    // Attacco: spara proiettili radiali
    _attackTimer -= dt;
    if (_attackTimer <= 0) {
      _attackTimer = currentPhase == 2 ? 1.0 : 2.0;
      _shootRadial();
    }
  }

  void _shootRadial() {
    final count = 8 + currentPhase * 4;
    for (int i = 0; i < count; i++) {
      final angle = i * math.pi * 2 / count + _portalPhase * 0.1;
      final dir = Vector2(math.cos(angle), math.sin(angle));
      final bullet = _BossBullet(direction: dir, color: neonColor);
      bullet.position = position.clone();
      game.world.add(bullet);
    }
  }

  @override
  void renderBoss(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final r = size.x / 2 * scale;

    // Portali (cerchi luminosi nell'arena)
    if (scale <= 1.01) {
      for (int i = 0; i < _portalPositions.length; i++) {
        final offset = _portalPositions[i] - position;
        final portalAlpha = 0.2 + math.sin(_portalPhase + i * 2) * 0.1;
        final portalPaint = Paint()
          ..color = neonColor.withValues(alpha: portalAlpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawCircle(Offset(cx + offset.x, cy + offset.y), 20, portalPaint);
      }
    }

    // Esagono esterno
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(_portalPhase * 0.2);
    _drawHex(canvas, 0, 0, r * 0.9, paint);
    canvas.restore();

    // Esagono interno (rotazione opposta)
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(-_portalPhase * 0.3);
    final innerPaint = Paint()
      ..color = paint.color.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * scale;
    _drawHex(canvas, 0, 0, r * 0.55, innerPaint);
    canvas.restore();

    // Nucleo energetico
    if (scale <= 1.01) {
      final pulse = 0.5 + math.sin(_portalPhase * 2) * 0.3;
      final corePaint = Paint()
        ..color = const Color(0xFFFFFFFF).withValues(alpha: pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(Offset(cx, cy), r * 0.25, corePaint);
    }
  }

  void _drawHex(Canvas canvas, double cx, double cy, double r, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = i * math.pi / 3 - math.pi / 6;
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paint);
  }
}

/// Proiettile boss generico
class _BossBullet extends PositionComponent
    with HasGameReference<GeometryFightGame> {
  final Vector2 direction;
  final Color color;
  late Vector2 _velocity;
  double _lifetime = 4.0;

  _BossBullet({required this.direction, required this.color})
      : super(size: Vector2(8, 8), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    _velocity = direction.normalized() * 200;
  }

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
    final p = Paint()
      ..color = color
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), 4, p);
    p.maskFilter = null;
    p.color = const Color(0xFFFFFFFF).withValues(alpha: 0.7);
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), 2, p);
  }
}

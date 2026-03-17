import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../../data/constants.dart';
import '../../../data/wave_configs.dart';
import '../../game_world.dart';
import 'boss_base.dart';

/// PHANTOM KING - Boss che diventa invisibile e crea cloni di sé stesso.
/// Forma: corona geometrica (pentagono con punte)
/// Colore: blu fantasma (#4466FF)
/// HP: 1500 · 3 fasi
/// Meccanica: diventa invisibile per 3s, poi riappare e attacca.
/// Crea 2-4 cloni con 1 HP che confondono il player.
/// Solo il vero boss ha il glow più intenso.
class PhantomKingBoss extends BossBase {
  double _invisTimer = 0;
  bool _isInvisible = false;
  double _attackTimer = 2.0;
  double _cloneTimer = 8.0;
  double _crownPhase = 0;
  int _cloneCount = 0;

  PhantomKingBoss()
      : super(
          hp: 1500,
          bossName: 'PHANTOM KING',
          pointValue: 3200,
          neonColor: const Color(0xFF4466FF),
          size: Vector2(85, 85),
        );

  @override
  int getPhase() {
    if (healthPercent > 0.6) return 0;
    if (healthPercent > 0.3) return 1;
    return 2;
  }

  @override
  void updateBoss(double dt) {
    _crownPhase += dt * 2;

    // Invisibilità periodica
    if (_isInvisible) {
      _invisTimer -= dt;
      if (_invisTimer <= 0) {
        _isInvisible = false;
        // Attacco sorpresa al riapparire
        _shootBurst();
      }
    } else {
      _invisTimer -= dt;
      if (_invisTimer <= 0) {
        _isInvisible = true;
        _invisTimer = currentPhase == 2 ? 2.0 : 3.0;
        // Teletrasporto in posizione casuale vicino al player
        final angle = math.Random().nextDouble() * math.pi * 2;
        final dist = 150 + math.Random().nextDouble() * 200;
        position = playerPosition + Vector2(math.cos(angle) * dist, math.sin(angle) * dist);
        position.x = position.x.clamp(100, arenaWidth - 100);
        position.y = position.y.clamp(100, arenaHeight - 100);
      }
    }

    // Movimento (solo se visibile)
    if (!_isInvisible) {
      final toPlayer = (playerPosition - position);
      if (toPlayer.length > 150) {
        position += toPlayer.normalized() * 100 * dt;
      }
    }

    // Attacco periodico
    _attackTimer -= dt;
    if (_attackTimer <= 0 && !_isInvisible) {
      _attackTimer = currentPhase == 2 ? 1.0 : 2.0;
      _shootAtPlayer();
    }

    // Crea cloni periodicamente
    _cloneTimer -= dt;
    if (_cloneTimer <= 0 && _cloneCount < 3 + currentPhase) {
      _cloneTimer = currentPhase == 2 ? 5.0 : 8.0;
      _spawnClone();
    }
  }

  void _shootAtPlayer() {
    final dir = (playerPosition - position).normalized();
    for (int i = -1; i <= 1; i++) {
      final angle = math.atan2(dir.y, dir.x) + i * 0.2;
      final bulletDir = Vector2(math.cos(angle), math.sin(angle));
      final bullet = _PhantomBullet(direction: bulletDir, color: neonColor);
      bullet.position = position.clone();
      game.world.add(bullet);
    }
  }

  void _shootBurst() {
    for (int i = 0; i < 12; i++) {
      final angle = i * math.pi * 2 / 12;
      final dir = Vector2(math.cos(angle), math.sin(angle));
      final bullet = _PhantomBullet(direction: dir, color: neonColor);
      bullet.position = position.clone();
      game.world.add(bullet);
    }
    game.triggerScreenShake(4, 0.2);
  }

  void _spawnClone() {
    _cloneCount++;
    // Spawna un nemico drone colorato come il boss
    game.spawnEnemy(EnemyType.drone, position + Vector2(
      (math.Random().nextDouble() - 0.5) * 100,
      (math.Random().nextDouble() - 0.5) * 100,
    ));
  }

  @override
  void renderBoss(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final r = size.x / 2 * scale;

    // Invisibilità: quasi trasparente
    if (_isInvisible) {
      paint.color = paint.color.withValues(alpha: 0.08);
    }

    // Corona (pentagono con punte)
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(_crownPhase * 0.3);

    final crownPath = Path();
    for (int i = 0; i < 5; i++) {
      final outerAngle = i * math.pi * 2 / 5 - math.pi / 2;
      final innerAngle = (i + 0.5) * math.pi * 2 / 5 - math.pi / 2;
      final outerR = r * 0.9;
      final innerR = r * 0.55;
      if (i == 0) {
        crownPath.moveTo(outerR * math.cos(outerAngle), outerR * math.sin(outerAngle));
      } else {
        crownPath.lineTo(outerR * math.cos(outerAngle), outerR * math.sin(outerAngle));
      }
      crownPath.lineTo(innerR * math.cos(innerAngle), innerR * math.sin(innerAngle));
    }
    crownPath.close();
    canvas.drawPath(crownPath, paint);

    // Dettagli interni
    if (scale <= 1.01 && !_isInvisible) {
      // Cerchio interno
      final innerPaint = Paint()
        ..color = paint.color.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawCircle(Offset.zero, r * 0.35, innerPaint);

      // Occhio centrale
      final eyePaint = Paint()
        ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.6 + math.sin(_crownPhase * 3) * 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(Offset.zero, r * 0.15, eyePaint);
    }
    canvas.restore();
  }
}

class _PhantomBullet extends PositionComponent with HasGameReference<GeometryFightGame> {
  final Vector2 direction;
  final Color color;
  late Vector2 _velocity;
  double _lifetime = 3.5;

  _PhantomBullet({required this.direction, required this.color})
      : super(size: Vector2(7, 7), anchor: Anchor.center);

  @override
  Future<void> onLoad() async { _velocity = direction.normalized() * 230; }

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
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), 3.5, p);
  }
}

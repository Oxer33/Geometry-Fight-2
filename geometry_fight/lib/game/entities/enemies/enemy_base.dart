import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import '../../../data/constants.dart';
import '../../game_world.dart';
import '../player.dart';

abstract class EnemyBase extends PositionComponent
    with HasGameReference<GeometryFightGame>, CollisionCallbacks {
  double hp;
  double maxHp;
  double speed;
  int pointValue;
  int geomValue;
  Color neonColor;

  double _flashTimer = 0;
  double _spawnPulse = 0.4; // Pulse ring on spawn
  double _idlePhase = 0;

  EnemyBase({
    required this.hp,
    required this.speed,
    required this.pointValue,
    required this.geomValue,
    required this.neonColor,
    Vector2? size,
  })  : maxHp = hp,
        super(size: size != null ? size * 2 : Vector2(40, 40), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    add(CircleHitbox(radius: size.x / 2, anchor: Anchor.center)
      ..position = this.size / 2);
  }

  @override
  void update(double dt) {
    super.update(dt);

    _idlePhase += dt;
    if (_flashTimer > 0) _flashTimer -= dt;
    if (_spawnPulse > 0) _spawnPulse -= dt;

    // Clamp to arena (tunnel mode ha limiti Y diversi e NO limiti X)
    if (game.isTunnelMode) {
      final centerY = arenaHeight / 2;
      final halfH = game.tunnelHeight / 2;
      position.y = position.y.clamp(centerY - halfH + 5, centerY + halfH - 5);
      // NO clamp X nel tunnel (scroll infinito)
    } else {
      position.x = position.x.clamp(5, arenaWidth - 5);
      position.y = position.y.clamp(5, arenaHeight - 5);
    }

    updateBehavior(dt);
  }

  void updateBehavior(double dt);

  void takeDamage(double amount) {
    hp -= amount;
    _flashTimer = 0.1;

    if (hp <= 0) {
      onDeath();
    }
  }

  void onDeath() {
    game.onEnemyKilled(this);
    game.spawnExplosion(position, neonColor, radius: size.x, particleCount: 12);
    removeFromParent();
  }

  Vector2 get playerPosition => game.player.position;

  Vector2 seekPlayer(double maxSpeed) {
    final dir = (playerPosition - position);
    if (dir.length > 0) {
      dir.normalize();
      return dir * maxSpeed;
    }
    return Vector2.zero();
  }

  double get distanceToPlayer => position.distanceTo(playerPosition);

  double get idlePhase => _idlePhase;

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2;
    final cy = size.y / 2;

    // === SPAWN PULSE (doppio anello espansivo) ===
    if (_spawnPulse > 0) {
      final progress = 1 - _spawnPulse / 0.4;
      final alpha = _spawnPulse / 0.4;
      // Anello esterno
      final outerR = progress * 50;
      final outerPaint = Paint()
        ..color = neonColor.withValues(alpha: alpha * 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawCircle(Offset(cx, cy), outerR, outerPaint);
      // Anello interno più luminoso
      final innerR = progress * 30;
      final innerPaint = Paint()
        ..color = neonColor.withValues(alpha: alpha * 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(Offset(cx, cy), innerR, innerPaint);
    }

    // === GLOW ESTERNO SOFT (alone ampio) ===
    final softGlow = Paint()
      ..color = neonColor.withValues(alpha: 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    renderShape(canvas, softGlow, 1.6);

    // === GLOW INTERNO BRIGHT ===
    final brightGlow = Paint()
      ..color = neonColor.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    renderShape(canvas, brightGlow, 1.25);

    // === CORPO PRINCIPALE ===
    final isHit = _flashTimer > 0;
    final mainColor = isHit ? const Color(0xFFFFFFFF) : neonColor;
    final mainPaint = Paint()..color = mainColor;
    renderShape(canvas, mainPaint, 1.0);

    // === CHROMATIC ABERRATION SIMULATA (quando colpito) ===
    if (isHit) {
      final redShift = Paint()
        ..color = const Color(0xFFFF0000).withValues(alpha: 0.3);
      canvas.save();
      canvas.translate(1.5, 0);
      renderShape(canvas, redShift, 1.0);
      canvas.restore();
      final blueShift = Paint()
        ..color = const Color(0xFF0000FF).withValues(alpha: 0.3);
      canvas.save();
      canvas.translate(-1.5, 0);
      renderShape(canvas, blueShift, 1.0);
      canvas.restore();
    }

    // === MINI HP BAR (solo per nemici con più di 1 HP e non a vita piena) ===
    if (maxHp > 1 && hp < maxHp && hp > 0) {
      _renderMiniHpBar(canvas, cx, cy);
    }
  }

  /// Mini barra HP sotto il nemico
  void _renderMiniHpBar(Canvas canvas, double cx, double cy) {
    final barWidth = size.x * 1.2;
    final barHeight = 2.0;
    final barX = cx - barWidth / 2;
    final barY = cy + size.y / 2 + 4;
    final hpPercent = (hp / maxHp).clamp(0.0, 1.0);

    // Background
    canvas.drawRect(
      Rect.fromLTWH(barX, barY, barWidth, barHeight),
      Paint()..color = const Color(0x33FFFFFF),
    );
    // HP bar con colore dinamico
    final barColor = hpPercent > 0.5
        ? neonColor
        : hpPercent > 0.25
            ? const Color(0xFFFFAA00)
            : const Color(0xFFFF2200);
    canvas.drawRect(
      Rect.fromLTWH(barX, barY, barWidth * hpPercent, barHeight),
      Paint()..color = barColor,
    );
  }

  void renderShape(Canvas canvas, Paint paint, double scale);
}

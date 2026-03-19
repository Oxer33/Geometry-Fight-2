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
    // Particelle ridotte per performance (6 invece di 12)
    game.spawnExplosion(position, neonColor, radius: size.x * 0.6, particleCount: 6);
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

  // Paint cache riutilizzabili per evitare allocazioni ogni frame
  // (con 60 nemici x 60fps = migliaia di allocazioni risparmiate)
  static final _glowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
  static final _mainPaint = Paint();
  static final _pulsePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  static final _hpBgPaint = Paint()..color = const Color(0x33FFFFFF);
  static final _hpBarPaint = Paint();

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2;
    final cy = size.y / 2;

    // === SPAWN PULSE (singolo anello, ottimizzato) ===
    if (_spawnPulse > 0) {
      final progress = 1 - _spawnPulse / 0.4;
      final alpha = _spawnPulse / 0.4;
      _pulsePaint.color = neonColor.withValues(alpha: alpha * 0.5);
      canvas.drawCircle(Offset(cx, cy), progress * 35, _pulsePaint);
    }

    // === GLOW (singolo layer, blur 8 — rimosso il softGlow blur 16 per performance) ===
    _glowPaint.color = neonColor.withValues(alpha: 0.25);
    renderShape(canvas, _glowPaint, 1.3);

    // === CORPO PRINCIPALE ===
    final isHit = _flashTimer > 0;
    _mainPaint.color = isHit ? const Color(0xFFFFFFFF) : neonColor;
    _mainPaint.maskFilter = null;
    renderShape(canvas, _mainPaint, 1.0);

    // === MINI HP BAR (solo per nemici con più di 1 HP e non a vita piena) ===
    if (maxHp > 1 && hp < maxHp && hp > 0) {
      _renderMiniHpBar(canvas, cx, cy);
    }
  }

  /// Mini barra HP sotto il nemico (usa Paint cache)
  void _renderMiniHpBar(Canvas canvas, double cx, double cy) {
    final barWidth = size.x * 1.2;
    final barHeight = 2.0;
    final barX = cx - barWidth / 2;
    final barY = cy + size.y / 2 + 4;
    final hpPercent = (hp / maxHp).clamp(0.0, 1.0);

    canvas.drawRect(
      Rect.fromLTWH(barX, barY, barWidth, barHeight),
      _hpBgPaint,
    );
    _hpBarPaint.color = hpPercent > 0.5 ? neonColor
        : hpPercent > 0.25 ? const Color(0xFFFFAA00) : const Color(0xFFFF2200);
    canvas.drawRect(
      Rect.fromLTWH(barX, barY, barWidth * hpPercent, barHeight),
      _hpBarPaint,
    );
  }

  void renderShape(Canvas canvas, Paint paint, double scale);
}

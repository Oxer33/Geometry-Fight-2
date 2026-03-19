import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import '../../../data/constants.dart';
import '../../../data/wave_configs.dart';
import '../../game_world.dart';
import '../player.dart';

abstract class BossBase extends PositionComponent
    with HasGameReference<GeometryFightGame>, CollisionCallbacks {
  double hp;
  double maxHp;
  String bossName;
  int pointValue;
  Color neonColor;

  int currentPhase = 0;
  double _flashTimer = 0;

  // Sistema spawn nemici durante boss fight
  double _minionSpawnTimer = 2.0; // Timer iniziale prima del primo spawn
  static const double _minionSpawnInterval = 3.5; // Ogni 3.5 secondi (era 5)
  static final _bossRandom = math.Random();

  BossBase({
    required this.hp,
    required this.bossName,
    required this.pointValue,
    required this.neonColor,
    Vector2? size,
  })  : maxHp = hp,
        super(size: size ?? Vector2(100, 100), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    // Hitbox proporzionato alla dimensione visiva del boss (95%)
    // Usa il raggio più grande tra x e y per coprire tutta la forma
    final hitboxRadius = math.max(size.x, size.y) / 2 * 0.95;
    add(CircleHitbox(radius: hitboxRadius, anchor: Anchor.center)
      ..position = this.size / 2);
  }

  double get healthPercent => hp / maxHp;
  Vector2 get playerPosition => game.player.position;
  double get distanceToPlayer => position.distanceTo(playerPosition);

  @override
  void update(double dt) {
    super.update(dt);
    if (_flashTimer > 0) _flashTimer -= dt;

    // Determine phase
    final newPhase = getPhase();
    if (newPhase != currentPhase) {
      currentPhase = newPhase;
      onPhaseChange(currentPhase);
    }

    updateBoss(dt);

    // Spawn nemici a ondate regolari durante il boss fight
    _minionSpawnTimer -= dt;
    if (_minionSpawnTimer <= 0) {
      _minionSpawnTimer = _minionSpawnInterval - currentPhase * 0.8; // Più veloce nelle fasi avanzate
      _spawnMinions();
    }

    // Clamp to arena
    position.x = position.x.clamp(50, arenaWidth - 50);
    position.y = position.y.clamp(50, arenaHeight - 50);
  }

  int getPhase();
  void onPhaseChange(int phase) {}
  void updateBoss(double dt);

  void takeDamage(double amount) {
    hp -= amount;
    _flashTimer = 0.08;
    if (hp <= 0) {
      hp = 0;
      onDeath();
    }
  }

  /// Spawna nemici di supporto durante il boss fight.
  /// Rispetta il limite _maxActiveEnemies del game_world per evitare lag.
  void _spawnMinions() {
    // Controlla quanti nemici ci sono già — se troppi, non spawnare
    if (game.enemyCount >= 40) return; // Lascia spazio per altri spawn
    
    final baseCount = 3 + currentPhase * 2; // 3, 5, 7, 9 nemici per fase (ridotto per performance)
    
    final minionTypes = <List<EnemyType>>[
      [EnemyType.drone, EnemyType.drone, EnemyType.swarmDrone],
      [EnemyType.drone, EnemyType.kamikaze, EnemyType.weaver],
      [EnemyType.kamikaze, EnemyType.weaver, EnemyType.bouncer],
      [EnemyType.splitter, EnemyType.kamikaze, EnemyType.tesla],
    ];
    
    final types = minionTypes[currentPhase.clamp(0, minionTypes.length - 1)];
    
    for (int i = 0; i < baseCount; i++) {
      final type = types[_bossRandom.nextInt(types.length)];
      final angle = _bossRandom.nextDouble() * math.pi * 2;
      final dist = 100 + _bossRandom.nextDouble() * 150;
      final spawnPos = position + Vector2(
        math.cos(angle) * dist,
        math.sin(angle) * dist,
      );
      game.spawnEnemy(type, spawnPos);
    }
  }

  void onDeath() {
    game.onBossKilled(this);
    game.spawnExplosion(position, neonColor, radius: 200, particleCount: 60);
    game.triggerScreenShake(8, 0.5);
    removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    // Glow
    final glowPaint = Paint()
      ..color = neonColor.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    renderBoss(canvas, glowPaint, 1.2);

    // Main
    final color = _flashTimer > 0 ? const Color(0xFFFFFFFF) : neonColor;
    final paint = Paint()..color = color;
    renderBoss(canvas, paint, 1.0);

    // HP bar above boss
    _renderHpBar(canvas);
  }

  void _renderHpBar(Canvas canvas) {
    final barWidth = size.x * 1.2;
    final barHeight = 4.0;
    final barX = (size.x - barWidth) / 2;
    final barY = -15.0;

    // Background
    canvas.drawRect(
      Rect.fromLTWH(barX, barY, barWidth, barHeight),
      Paint()..color = const Color(0x44FFFFFF),
    );

    // HP
    final hpColor = healthPercent > 0.5
        ? NeonColors.green
        : healthPercent > 0.25
            ? NeonColors.yellow
            : NeonColors.red;
    canvas.drawRect(
      Rect.fromLTWH(barX, barY, barWidth * healthPercent, barHeight),
      Paint()..color = hpColor,
    );
  }

  void renderBoss(Canvas canvas, Paint paint, double scale);

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Player) {
      other.takeDamage();
    }
    super.onCollisionStart(intersectionPoints, other);
  }
}

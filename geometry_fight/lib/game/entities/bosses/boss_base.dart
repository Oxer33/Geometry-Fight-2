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
      _minionSpawnTimer = (_minionSpawnInterval - currentPhase * 0.8).clamp(1.0, _minionSpawnInterval);
      _spawnMinions();
    }

    // Clamp to arena
    if (game.isTunnelMode) {
      // TUNNEL BOSS: stile side-scroller — boss ancorato al lato destro dello schermo.
      // La X è forzata a seguire la camera (lato destro ~60% dello schermo).
      // Solo il movimento Y è libero (su/giù nel tunnel).
      final cam = game.camera.viewfinder.position;
      final halfW = game.size.x > 0 ? game.size.x / 2 : 400.0;
      final halfH = game.size.y > 0 ? game.size.y / 2 : 300.0;

      // X: ancorato al lato destro dello schermo (60% a destra dal centro)
      position.x = cam.x + halfW * 0.55;

      // Y: segue il player con smoothing + oscillazione sinusoidale per varietà
      final targetY = game.player.position.y;
      position.y += (targetY - position.y) * 1.5 * dt; // Insegue Y del player lentamente
      position.y += math.sin(_flashTimer * 10 + hp) * 30 * dt; // Micro-oscillazione

      // Clamp Y ai limiti del tunnel visibile
      position.y = position.y.clamp(
        cam.y - halfH + size.y / 2 + 20,
        cam.y + halfH - size.y / 2 - 20,
      );
    } else {
      position.x = position.x.clamp(50.0, arenaWidth - 50);
      position.y = position.y.clamp(50.0, arenaHeight - 50);
    }
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
    if (game.enemyCount >= 15) return; // Non spawnare se ci sono già 15+ nemici
    
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

  // Paint cache — boss è uno solo, ma evita allocazioni costanti
  static final _bossGlowPaint = Paint();
  static final _bossMainPaint = Paint();

  @override
  void render(Canvas canvas) {
    // Glow (senza blur — singolo boss, ma 16px blur è costoso)
    _bossGlowPaint.color = neonColor.withValues(alpha: 0.2);
    _bossGlowPaint.maskFilter = null;
    renderBoss(canvas, _bossGlowPaint, 1.2);

    // Main
    final color = _flashTimer > 0 ? const Color(0xFFFFFFFF) : neonColor;
    _bossMainPaint.color = color;
    _bossMainPaint.maskFilter = null;
    _bossMainPaint.style = PaintingStyle.fill;
    renderBoss(canvas, _bossMainPaint, 1.0);

    // NOTA: barra HP rimossa dalla testa del boss — la HUD ha già la barra in basso
  }

  // Barra HP rimossa dalla testa del boss — la HUD mostra la barra in basso

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

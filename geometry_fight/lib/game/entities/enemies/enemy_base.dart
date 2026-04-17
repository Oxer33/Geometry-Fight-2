import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import '../../../data/constants.dart';
import '../../game_world.dart';

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
  bool _isDead = false; // FIX C1: guard contro double-death

  // Spawn invulnerability (come GW:RE2 — nemici appaiono con effetto materializzazione)
  // 4s warning: nemico lampeggia, non si muove, non danneggia player, non subisce danno
  double _spawnInvulnTimer = 4.0;
  bool get isSpawnInvulnerable => _spawnInvulnTimer > 0;
  double get spawnInvulnTimer => _spawnInvulnTimer; // FIX H5: accesso da PhantomEnemy
  /// Azzera invulnerabilità spawn (per nemici generati in-game, non spawnati)
  void clearSpawnInvulnerability() => _spawnInvulnTimer = 0;

  // Fear mechanic (come GW:RE2 — nemici fuggono brevemente quando colpiti da proiettili vicini)
  double _fearTimer = 0;
  Vector2? _fearDirection;
  bool get canFearDodge => false;

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
      ..position = size / 2);
  }

  @override
  void update(double dt) {
    super.update(dt);

    _idlePhase += dt;
    if (_flashTimer > 0) _flashTimer -= dt;
    if (_spawnPulse > 0) _spawnPulse -= dt;
    if (_spawnInvulnTimer > 0) _spawnInvulnTimer -= dt;
    if (_fearTimer > 0) _fearTimer -= dt;

    // Tunnel mode: despawn nemici dietro la camera
    if (game.isTunnelMode) {
      final cameraLeft = game.camera.viewfinder.position.x - game.size.x / 2 - 200;
      if (position.x < cameraLeft) {
        removeFromParent();
        return;
      }
    }

    // Durante il warning di spawn (4s) il nemico sta fermo: niente fear, niente behavior
    if (_spawnInvulnTimer <= 0) {
      // Fear: fuggi nella direzione opposta brevemente
      if (_fearTimer > 0 && _fearDirection != null) {
        position += _fearDirection! * speed * 2.5 * dt;
      } else {
        updateBehavior(dt);
      }
    }

    // Clamp to arena DOPO il movimento (fear + updateBehavior) per evitare jitter
    if (game.isTunnelMode) {
      // Tunnel: clamp Y ai muri dinamici sinusoidali
      final (topWall, bottomWall) = game.tunnelWallsAtX(position.x);
      const margin = 6.0;
      position.y = position.y.clamp(topWall + margin, bottomWall - margin);
    } else {
      position.x = position.x.clamp(5, arenaWidth - 5);
      position.y = position.y.clamp(5, arenaHeight - 5);
    }
  }

  void updateBehavior(double dt);

  void takeDamage(double amount) {
    // Invulnerabile durante spawn (materializzazione come GW:RE2)
    if (_spawnInvulnTimer > 0) return;

    hp -= amount;
    _flashTimer = 0.1;

    if (hp <= 0) {
      onDeath();
    }
  }

  /// Fear: un proiettile passa vicino senza colpire — il nemico fugge brevemente.
  /// Chiamato dal sistema proiettili quando un bullet esplode nelle vicinanze.
  void applyFear(Vector2 bulletPos) {
    if (!canFearDodge) return;
    if (_fearTimer > 0) return; // Gi spaventato
    final away = position - bulletPos;
    if (away.length > 0) {
      _fearDirection = away.normalized();
      _fearTimer = 0.3; // Fugge per 0.3s
    }
  }

  void onDeath() {
    if (_isDead) return; // FIX C1: evita double-death (bullet + bomba nello stesso frame)
    _isDead = true;
    game.onEnemyKilled(this);
    // Esplosioni scalate per valore nemico: mob deboli piccole, nemici forti epic
    final isEpic = geomValue >= 4 || pointValue >= 10;
    final particles = geomValue <= 1 ? 8 : (isEpic ? 20 : 12);
    final explosionRadius = geomValue <= 1 ? size.x * 0.8 : size.x * 1.2;
    game.spawnExplosion(position, neonColor,
        radius: explosionRadius, particleCount: particles, epic: isEpic);
    removeFromParent();
  }

  /// Kill silenzioso: rimuove il nemico con esplosione visiva ma SENZA
  /// dare punti, geom, kill count o drop. Usato per la shockwave alla morte.
  void killSilently() {
    game.spawnExplosion(position, neonColor, radius: size.x * 0.5, particleCount: 3);
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

  // ══════════════════════════════════════════════════════════════
  // PERFORMANCE: LOD (Level of Detail) system
  // Quando ci sono molti nemici a schermo, skip dettagli costosi
  // (blur, particelle extra, linee decorative) per mantenere 60fps.
  // ══════════════════════════════════════════════════════════════

  /// true = pochi nemici → dettagli completi (blur, particelle, decorazioni)
  /// false = molti nemici → solo forma base senza blur
  bool get highDetail => game.enemyCount < 40;

  // Paint cache riutilizzabili per evitare allocazioni ogni frame
  // (con 60 nemici x 60fps = migliaia di allocazioni risparmiate)
  static final _glowPaint = Paint(); // NO MaskFilter.blur — troppo costoso su mobile!
  static final _mainPaint = Paint();
  static final _hpBgPaint = Paint()..color = const Color(0x33FFFFFF);
  static final _hpBarPaint = Paint();
  // Paint cache condiviso per dettagli (usabile da qualsiasi subclass)
  static final detailPaint = Paint();

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2;
    final cy = size.y / 2;

    // === SPAWN INVULNERABILITY — effetto materializzazione (come GW:RE2) ===
    // Skip rendering nei frame "off" del flash (NO saveLayer — troppo costoso con 100+ nemici)
    if (_spawnInvulnTimer > 0) {
      final flashOff = ((_spawnInvulnTimer * 6).toInt() % 2 == 0);
      if (flashOff) return; // Non renderizza questo frame → effetto flash
    }

    // === GLOW (senza blur per performance — solo colore più grande e trasparente) ===
    _glowPaint.color = neonColor.withValues(alpha: 0.2);
    _glowPaint.maskFilter = null;
    renderShape(canvas, _glowPaint, 1.3);

    // === CORPO PRINCIPALE (bordi neon con interno trasparente — stile Geometry Wars) ===
    final isHit = _flashTimer > 0;
    _mainPaint.color = isHit ? const Color(0xFFFFFFFF) : neonColor;
    _mainPaint.maskFilter = null;
    _mainPaint.style = PaintingStyle.stroke;
    _mainPaint.strokeWidth = 2.0;
    // LOD: quando ci sono 60+ nemici, usa scale 1.02 così tutti i check
    // "if (scale <= 1.01)" nei renderShape skippano automaticamente
    // blur, particelle e dettagli costosi → massima performance.
    final mainScale = highDetail ? 1.0 : 1.02;
    renderShape(canvas, _mainPaint, mainScale);
    _mainPaint.style = PaintingStyle.fill; // Reset per chi usa fill internamente

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

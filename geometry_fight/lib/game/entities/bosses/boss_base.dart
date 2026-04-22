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
  static const double _minionSpawnInterval = bossMinionSpawnInterval;
  static final _bossRandom = math.Random();

  // ═══════════════════════════════════════════════════════════════════════
  // FX STATE — aura, entry, phase burst, danger strobe, chromatic hit
  // ═══════════════════════════════════════════════════════════════════════

  /// Phase accumulator per animazioni sinusoidali e rotazioni.
  double _fxPhase = 0;

  /// Materializzazione iniziale: 1.0 → 0.0 nel primo 1s di vita del boss.
  /// Guida un ring radiale che "risucchia" energia verso il boss.
  double _entryTimer = 1.0;

  /// Burst al cambio fase: 0.6s. Un ring bianco si espande da `position`
  /// verso l'esterno, accompagnato da screen shake.
  double _phaseFlashTimer = 0;
  double _phaseFlashRadius = 0;

  /// Danger strobe: attivo sotto il 30% HP. Pulsazione rossa pericolosa.
  bool get _inDanger => healthPercent < 0.3 && healthPercent > 0;

  /// Hit timer — più lungo di `_flashTimer` (usato per chromatic splitting).
  double _chromaticHitTimer = 0;

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
      ..position = size / 2);
  }

  double get healthPercent => hp / maxHp;
  Vector2 get playerPosition => game.player.position;
  double get distanceToPlayer => position.distanceTo(playerPosition);

  @override
  void update(double dt) {
    // Il boss ignora il powerup TimeSlow: compensa il timeScale con realDt.
    // Durante un burst slow-mo (bomba/morte) senza powerup attivo, rallenta normalmente.
    final effectiveDt = (game.player.timeSlowTimer > 0 && game.timeScale > 0.01)
        ? dt / game.timeScale
        : dt;

    // super.update riceve il dt "scalato" normale (non il nostro effectiveDt):
    // i child components del boss (tweens, timers Flame) gestiscono da soli
    // la dilatazione globale. Prima passavamo effectiveDt a super → i children
    // avevano velocità incoerente con il resto del mondo.
    super.update(dt);
    if (_flashTimer > 0) _flashTimer -= effectiveDt;

    // FX timers. Wrap `_fxPhase` ogni ~62s (2π × 10) per evitare fp drift
    // su boss fight lunghi (sin/cos restano stabili a qualunque valore,
    // ma il wrapping tiene il range piccolo → aritmetica più precisa).
    _fxPhase += effectiveDt;
    if (_fxPhase > math.pi * 20) _fxPhase -= math.pi * 20;
    if (_entryTimer > 0) _entryTimer -= effectiveDt;
    if (_chromaticHitTimer > 0) _chromaticHitTimer -= effectiveDt;
    if (_phaseFlashTimer > 0) {
      _phaseFlashTimer -= effectiveDt;
      _phaseFlashRadius += effectiveDt * 800; // espansione 800 px/s
    }

    // Determine phase. `_phaseFlashTimer > 0` agisce da debounce: se due
    // soglie HP vengono attraversate nello stesso frame (bomba a HP bassa),
    // FX partono una volta sola; l'`onPhaseChange` della subclass continua
    // a essere chiamato per ogni transizione di fase (logica gameplay).
    final newPhase = getPhase();
    if (newPhase != currentPhase) {
      currentPhase = newPhase;
      if (_phaseFlashTimer <= 0) {
        _triggerPhaseFx();
      }
      onPhaseChange(currentPhase);
    }

    updateBoss(effectiveDt);

    // Spawn nemici a ondate regolari durante il boss fight
    _minionSpawnTimer -= effectiveDt;
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
      position.y += (targetY - position.y) * 1.5 * effectiveDt; // Insegue Y del player lentamente
      position.y += math.sin(_flashTimer * 10 + hp) * 30 * effectiveDt; // Micro-oscillazione

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

  /// [isArea] flag: allinea la signature a `EnemyBase.takeDamage` così che i
  /// call-site AoE (laser, plasma, homing, bomba) possano passare lo stesso
  /// named param a boss + nemici senza branching. Default false, retro-compat.
  void takeDamage(double amount, {bool isArea = false}) {
    hp -= amount;
    _flashTimer = 0.08;
    // Chromatic hit solo su danno sostanziale: sotto threshold non triggera
    // il triple-render cost. Il laser (damage~0.008/tick a 60Hz) NON attiva
    // il split. Bullet base (damage 1+) e plasma (3+) sì.
    if (amount >= 0.5) {
      _chromaticHitTimer = 0.12; // ridotto da 0.18 per contenere perf cost
    }
    if (hp <= 0) {
      hp = 0;
      onDeath();
    }
  }

  /// Trigger FX visivo al cambio fase: ring bianco espansivo + screen shake
  /// + mini slow-mo drammatico. Boss diventano momentaneamente intangibili
  /// all'occhio grazie al flash che copre il ridisegno.
  void _triggerPhaseFx() {
    _phaseFlashTimer = 0.6;
    _phaseFlashRadius = 0;
    game.triggerScreenShake(6, 0.3);
    // Burst di particelle colorate per segnalare la transizione
    game.spawnExplosion(position, neonColor,
        radius: size.x * 1.2, particleCount: 30);
    game.spawnExplosion(position, const Color(0xFFFFFFFF),
        radius: size.x * 0.7, particleCount: 15);
  }

  /// Spawna nemici di supporto durante il boss fight.
  /// Rispetta il limite bossMinionEnemyCap per evitare lag.
  void _spawnMinions() {
    // Controlla quanti nemici ci sono già — se troppi, non spawnare
    if (game.enemyCount >= bossMinionEnemyCap) return;
    
    final baseCount = 3 + currentPhase * 2; // 3, 5, 7, 9 nemici per fase (ridotto per performance)
    
    final minionTypes = <List<EnemyType>>[
      [EnemyType.drone, EnemyType.drone, EnemyType.swarmDrone],
      [EnemyType.drone, EnemyType.kamikaze, EnemyType.weaver],
      [EnemyType.kamikaze, EnemyType.weaver, EnemyType.swarmDrone],
      [EnemyType.splitter, EnemyType.kamikaze, EnemyType.tesla],
    ];
    
    final types = minionTypes[currentPhase.clamp(0, minionTypes.length - 1)];
    
    for (int i = 0; i < baseCount; i++) {
      final type = types[_bossRandom.nextInt(types.length)];
      final angle = _bossRandom.nextDouble() * math.pi * 2;
      final dist = 100 + _bossRandom.nextDouble() * 150;
      final rawPos = position + Vector2(
        math.cos(angle) * dist,
        math.sin(angle) * dist,
      );
      // Clamp alla arena in modalità non-tunnel: evita minion spawnati OOB
      // che verrebbero subito despawn. In tunnel mode la camera cull si
      // occupa già del culling, quindi non clamp-iamo X.
      final spawnPos = game.isTunnelMode
          ? rawPos
          : Vector2(
              rawPos.x.clamp(30.0, arenaWidth - 30.0),
              rawPos.y.clamp(30.0, arenaHeight - 30.0),
            );
      game.spawnEnemy(type, spawnPos);
    }
  }

  void onDeath() {
    game.onBossKilled(this);
    // Morte drammatica: slow-mo + 2 epic explosions (shake auto-triggered
    // dal game_world) + 1 non-epic per i dettagli colorati. Evita lo shake
    // esplicito: ogni `epic: true` aggiunge già shake(4, 0.15) nel game_world
    // → 2 epic + 1 esplicito = triple shake troppo violento su boss rush.
    game.activateSlowMo(0.5, 0.25);
    game.spawnExplosion(position, const Color(0xFFFFFFFF),
        radius: 320, particleCount: 40, epic: true);
    game.spawnExplosion(position, neonColor,
        radius: 260, particleCount: 50, epic: true);
    game.spawnExplosion(position, const Color(0xFFFF8800),
        radius: 180, particleCount: 30);
    // Un singolo shake forte "finale" — gli epic ne hanno già aggiunti 2
    // piccoli (4, 0.15 × 2), questo dà il "boom" culminante.
    game.triggerScreenShake(10, 0.5);
    removeFromParent();
  }

  // Paint cache — boss è uno solo, ma evita allocazioni costanti
  static final _bossGlowPaint = Paint();
  static final _bossMainPaint = Paint();
  // FX paints
  static final _fxAuraPaint = Paint();
  static final _fxRingPaint = Paint()..style = PaintingStyle.stroke;
  static final _fxParticlePaint = Paint();
  static final _fxPhaseFlashPaint = Paint()..style = PaintingStyle.stroke;
  static final _fxDangerPaint = Paint()..style = PaintingStyle.stroke;
  static final _fxEntryPaint = Paint()..style = PaintingStyle.stroke;
  static final _fxChromaticPaint = Paint();

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final bossR = math.max(size.x, size.y) / 2;

    // ─── 1. ENTRY MATERIALIZATION (primi 1s) ──────────────────────────────
    // Ring bianchi che si contraggono verso il boss — feeling "spawn epico".
    if (_entryTimer > 0) {
      final t = _entryTimer.clamp(0.0, 1.0); // 1 → 0
      for (int i = 0; i < 3; i++) {
        final layerT = (t - i * 0.15).clamp(0.0, 1.0);
        if (layerT <= 0) continue;
        final radius = bossR * 2.5 * layerT + bossR * 0.5;
        _fxEntryPaint.color = const Color(0xFFFFFFFF)
            .withValues(alpha: (1.0 - layerT) * 0.6);
        _fxEntryPaint.strokeWidth = 2.0 + (1 - layerT) * 3;
        canvas.drawCircle(Offset(cx, cy), radius, _fxEntryPaint);
      }
    }

    // ─── 2. AURA MULTI-STRATO (3 cerchi concentrici pulsanti) ─────────────
    // Ogni layer alpha pulsa con fase diversa → effetto "respira".
    final auraPulse = 0.5 + math.sin(_fxPhase * 2.5) * 0.5;
    for (int i = 0; i < 3; i++) {
      final layerRadius = bossR * (1.15 + i * 0.25);
      final layerAlpha = (0.20 - i * 0.05) * (0.6 + auraPulse * 0.4);
      _fxAuraPaint.color = neonColor.withValues(alpha: layerAlpha);
      canvas.drawCircle(Offset(cx, cy), layerRadius, _fxAuraPaint);
    }

    // ─── 3. ANELLO ORBITANTE DI PARTICELLE (12 punti luminosi) ────────────
    final particleOrbitR = bossR * 1.35;
    const particleCount = 12;
    for (int i = 0; i < particleCount; i++) {
      final angle = _fxPhase * 0.8 + i * math.pi * 2 / particleCount;
      final px = cx + math.cos(angle) * particleOrbitR;
      final py = cy + math.sin(angle) * particleOrbitR;
      final pPulse = 0.4 + math.sin(_fxPhase * 4 + i * 0.5) * 0.3;
      _fxParticlePaint.color = neonColor.withValues(alpha: pPulse);
      canvas.drawCircle(Offset(px, py), 2.5, _fxParticlePaint);
      // Scia interna
      _fxParticlePaint.color = const Color(0xFFFFFFFF).withValues(alpha: pPulse * 0.7);
      canvas.drawCircle(Offset(px, py), 1.2, _fxParticlePaint);
    }

    // ─── 4. ANELLO CONTRO-ROTANTE (fase + arco stroke) ────────────────────
    _fxRingPaint.color = neonColor.withValues(alpha: 0.35 + auraPulse * 0.2);
    _fxRingPaint.strokeWidth = 1.5;
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(-_fxPhase * 1.2);
    final ringRect = Rect.fromCircle(center: Offset.zero, radius: bossR * 1.55);
    // Due archi opposti (180° span each with gap)
    canvas.drawArc(ringRect, 0, math.pi * 0.75, false, _fxRingPaint);
    canvas.drawArc(ringRect, math.pi, math.pi * 0.75, false, _fxRingPaint);
    canvas.restore();

    // ─── 5. DANGER STROBE (sotto 30% HP) ──────────────────────────────────
    if (_inDanger) {
      final strobe = (math.sin(_fxPhase * 10) * 0.5 + 0.5);
      _fxDangerPaint.color = const Color(0xFFFF2200)
          .withValues(alpha: 0.3 + strobe * 0.4);
      _fxDangerPaint.strokeWidth = 2.5 + strobe * 2;
      canvas.drawCircle(Offset(cx, cy), bossR * 1.7, _fxDangerPaint);
    }

    // ─── 6. GLOW DEL CORPO (strato inferiore) ─────────────────────────────
    _bossGlowPaint.color = neonColor.withValues(alpha: 0.22);
    _bossGlowPaint.maskFilter = null;
    renderBoss(canvas, _bossGlowPaint, 1.3);

    // ─── 7. CORPO PRINCIPALE (col chromatic split su hit) ─────────────────
    final color = _flashTimer > 0 ? const Color(0xFFFFFFFF) : neonColor;
    _bossMainPaint.color = color;
    _bossMainPaint.maskFilter = null;
    _bossMainPaint.style = PaintingStyle.fill;

    if (_chromaticHitTimer > 0) {
      // RGB split: disegna 2 offsetted in cyan + magenta, poi il corpo sopra.
      final splitT = (_chromaticHitTimer / 0.18).clamp(0.0, 1.0);
      final offset = 3.5 * splitT;
      canvas.save();
      canvas.translate(-offset, 0);
      _fxChromaticPaint.color = const Color(0xFF00FFFF).withValues(alpha: 0.7 * splitT);
      renderBoss(canvas, _fxChromaticPaint, 1.0);
      canvas.restore();
      canvas.save();
      canvas.translate(offset, 0);
      _fxChromaticPaint.color = const Color(0xFFFF00FF).withValues(alpha: 0.7 * splitT);
      renderBoss(canvas, _fxChromaticPaint, 1.0);
      canvas.restore();
    }
    renderBoss(canvas, _bossMainPaint, 1.0);

    // ─── 8. PHASE FLASH (ring bianco espansivo) ───────────────────────────
    if (_phaseFlashTimer > 0) {
      final t = (_phaseFlashTimer / 0.6).clamp(0.0, 1.0);
      final alpha = t * 0.8;
      _fxPhaseFlashPaint.color = const Color(0xFFFFFFFF).withValues(alpha: alpha);
      _fxPhaseFlashPaint.strokeWidth = 3 + (1 - t) * 4;
      canvas.drawCircle(Offset(cx, cy), _phaseFlashRadius, _fxPhaseFlashPaint);
      // Secondo ring color-tinted dietro (offset ritardato)
      _fxPhaseFlashPaint.color = neonColor.withValues(alpha: alpha * 0.6);
      _fxPhaseFlashPaint.strokeWidth = 2;
      canvas.drawCircle(Offset(cx, cy),
          _phaseFlashRadius * 0.7, _fxPhaseFlashPaint);
    }
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

import 'dart:collection';
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

  // Sistema spawn nemici durante boss fight.
  // Timer iniziale = interval pieno → primo spawn DOPO 10s, coerente con
  // request "almeno 10s tra uno spawn e l'altro".
  double _minionSpawnTimer = bossMinionSpawnInterval;
  // Override-able per-boss (richiesta utente: variabile per balancing
  // per-singolo-boss in futuro). Default = bossMinionSpawnInterval (10s).
  double get minionSpawnInterval => bossMinionSpawnInterval;
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

  /// Guard contro double-death: se `takeDamage` porta hp<=0 due volte nello
  /// stesso frame (es. plasma AoE + bullet stesso tick), `onDeath` veniva
  /// chiamato due volte → score/audio/explosions duplicati.
  bool _onDeathFired = false;

  BossBase({
    required this.hp,
    required this.bossName,
    required this.pointValue,
    required this.neonColor,
    Vector2? size,
  })  : maxHp = hp,
        super(size: size ?? Vector2(100, 100), anchor: Anchor.center);

  /// Factor del raggio hitbox rispetto a `max(size)/2`. Default 0.7.
  ///
  /// Audit hitbox boss (richiesta utente "controllo approfondito"):
  /// PRIMA factor era 0.95 → hitbox quasi tangente al bbox del componente.
  /// Visivamente i boss hanno shape complessi (triangoli, hexagoni) con
  /// extent reale << bbox. Es. PrismHunter triangle vertici a r=28 ma
  /// hitbox r=52 (110/2×0.95) → "invisible damage" 24px oltre il visivo.
  ///
  /// 0.7 = compromise sicuro tra accuracy e generosità: copre il visivo
  /// medio dei boss square-bbox con shape inscritta senza essere troppo
  /// stretto (sotto 0.6 alcuni boss diventano "troppo piccoli da colpire").
  /// Boss con visivi più estesi (es. TheGrid 200×200, SwarmMother body
  /// largo) override il getter per allargare il hitbox al loro extent.
  double get hitboxRadiusFactor => 0.7;

  @override
  Future<void> onLoad() async {
    // Hitbox proporzionato al visivo del boss (vedi doc hitboxRadiusFactor).
    // Tutti i boss hanno bbox quadrato → size.x diretto (math.max ridondante).
    final hitboxRadius = size.x / 2 * hitboxRadiusFactor;
    add(CircleHitbox(radius: hitboxRadius, anchor: Anchor.center)
      ..position = size / 2);
    // Cache the arc rect used by the counter-rotating ring in render().
    // `size` is fixed at this point — avoids a Rect heap allocation every frame.
    final bossR = math.max(size.x, size.y) / 2;
    _ringArcRect = Rect.fromCircle(center: Offset.zero, radius: bossR * 1.55);
  }

  double get healthPercent => hp / maxHp;
  Vector2 get playerPosition => game.player.position;
  double get distanceToPlayer => position.distanceTo(playerPosition);

  @override
  void update(double dt) {
    if (_onDeathFired) return;
    // Il boss ignora il powerup TimeSlow: compensa il timeScale con realDt.
    // Durante un burst slow-mo (bomba/morte) senza powerup attivo, rallenta normalmente.
    // Threshold 0.2 (non 0.01) evita amplificazioni estreme: se timeScale=0.011
    // e dividiamo → boss salta di ~90×dt per frame (teleport visibile). A 0.2,
    // amplificazione max 5× dt — tollerabile. Sotto soglia, niente compensazione.
    final effectiveDt = (game.player.timeSlowTimer > 0 && game.timeScale > 0.2)
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
    // FX partono una volta sola; l'`onPhaseChange` della subclass viene
    // invocato per OGNI fase intermedia (bomba che salta fase 0→2 chiama
    // onPhaseChange(1) e onPhaseChange(2)) — altrimenti subclass perdono
    // setup di fase intermedia (spawn, pattern attacco, ecc).
    final newPhase = getPhase();
    if (newPhase != currentPhase) {
      _triggerPhaseFx();
      // Step through intermediate phases one at a time (supports both skip-up
      // e skip-down — es. heal powerup che ripristina HP potrebbe regredire).
      final step = newPhase > currentPhase ? 1 : -1;
      while (currentPhase != newPhase) {
        currentPhase += step;
        onPhaseChange(currentPhase);
      }
    }

    updateBoss(effectiveDt);

    // Spawn nemici a ondate regolari durante il boss fight.
    // Phase scaling proporzionale (10% riduzione/fase) → flessibile a
    // qualsiasi valore di `minionSpawnInterval` (per-boss override).
    _minionSpawnTimer -= effectiveDt;
    if (_minionSpawnTimer <= 0) {
      final iv = minionSpawnInterval;
      _minionSpawnTimer = (iv - currentPhase * iv * 0.1).clamp(iv * 0.6, iv);
      _spawnMinions();
    }

    // Big wave color-matched: carica queue ogni 15s, poi drena max 6/frame
    // per evitare frame hitch (50 mob in 1 frame = stutter visibile).
    _bigWaveTimer -= effectiveDt;
    if (_bigWaveTimer <= 0) {
      _bigWaveTimer = _kBigWaveInterval;
      _enqueueColorWave();
    }
    _drainWaveQueue();

    // Clamp to arena
    if (game.isTunnelMode) {
      // TUNNEL BOSS: side-scroller, ancorato al lato destro dello schermo.
      // Y libero. X lerp-ato verso target (richiesta utente: entrata smooth
      // da destra-fuori-schermo invece di snap istantaneo).
      final cam = game.camera.viewfinder.position;
      final halfW = game.size.x > 0 ? game.size.x / 2 : 400.0;
      final halfH = game.size.y > 0 ? game.size.y / 2 : 300.0;

      // X target: ancorato al lato destro (55% a destra dal centro).
      final targetX = cam.x + halfW * 0.55;
      // Lerp 3× per secondo (~smooth ~0.5s d'entrata dal bordo destro).
      position.x += (targetX - position.x) * 3.0 * effectiveDt;

      // Y: segue il player con smoothing + oscillazione sinusoidale per varietà
      final targetY = game.player.position.y;
      position.y += (targetY - position.y) * 1.5 * effectiveDt; // Insegue Y del player lentamente
      // Micro-oscillazione Y: usa `_fxPhase` (continuo) invece di `_flashTimer`
      // (a zero il 99% del tempo → sin(hp) costante, oscillazione morta).
      position.y += math.sin(_fxPhase * 3 + hp * 0.1) * 30 * effectiveDt;

      // Clamp Y ai limiti del tunnel visibile
      position.y = position.y.clamp(
        cam.y - halfH + size.y / 2 + 20,
        cam.y + halfH - size.y / 2 - 20,
      );
      // Muri rossi impenetrabili: teletrasporta al centro del TUNNEL (non
      // al centro viewport). Gli ostacoli possono attraversare cam.y se la
      // curva `tunnelCenterOffsetAt` porta il tunnel sopra/sotto il centro
      // schermo → teleport a cam.y potrebbe finire dentro un obstacle →
      // loop infinito di teleport. Usa midpoint dei walls come safe Y.
      if (game.hitsTunnelObstacle(position)) {
        final (topWall, bottomWall) = game.tunnelWallsAtX(position.x);
        position.y = (topWall + bottomWall) / 2;
      }
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
    // Guard: se onDeath già fired, AoE ticks successivi (plasma/laser che
    // continuano 1-2 frame prima che removeFromParent propaghi) triggeravano
    // flash bianco su boss morto + decremento HP negativo. Ignora.
    if (_onDeathFired) return;
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

  /// Hook per subclassi: se false disabilita lo spawn periodico di mob di
  /// supporto dal BossBase. Utile per fasi "rage" che già inondano lo
  /// schermo (es. HydraBoss rage mode).
  bool get allowMinionSpawn => true;

  /// Lista di EnemyType "dello stesso colore del boss" usata dal big-wave
  /// spawn (richiesta utente: "mob dello stesso colore del boss").
  /// Subclass override per restituire i mob color-matched; default drone.
  List<EnemyType> get colorMatchedMinions => const [EnemyType.drone];

  /// Timer per big wave color-matched: ogni 15s spawna 10/30/50 mob in base
  /// alla fase. Initial 5s (era 15): prima wave parte presto per feedback.
  double _bigWaveTimer = 5.0;
  static const double _kBigWaveInterval = 15.0;
  // Queue per spread dello spawn su più frame (evita hitch quando target=50).
  // ListQueue: removeFirst O(1) vs removeAt(0) O(N) per drain hot-path.
  final ListQueue<EnemyType> _bigWaveQueue = ListQueue<EnemyType>();
  static const int _kMaxSpawnPerFrame = 6;

  /// Banal mob multiplier (richiesta utente: "più sono mob banali e più ne
  /// devono spawnare"). 3=banal, 2=medium, 1=strong.
  static int _mobWeight(EnemyType type) {
    switch (type) {
      case EnemyType.drone:
      case EnemyType.swarmDrone:
      case EnemyType.kamikaze:
        return 3;
      case EnemyType.weaver:
      case EnemyType.mine:
      case EnemyType.snake:
      case EnemyType.pulsar:
      case EnemyType.splitter:
      case EnemyType.leech:
      case EnemyType.mirror:
      case EnemyType.orbiter:
      case EnemyType.decoy:
      case EnemyType.proton:
        return 2;
      default:
        return 1;
    }
  }

  /// Carica la big wave nella queue. `_drainWaveQueue` la processa su più
  /// frame evitando frame hitch (spawn di 50 mob in 1 frame = stutter).
  void _enqueueColorWave() {
    if (!allowMinionSpawn) return;
    final types = colorMatchedMinions;
    if (types.isEmpty) return;
    // Richiesta utente: dimezzato dal triplo (30/90/150 → 15/45/75).
    final baseCount = switch (currentPhase) {
      0 => 15,
      1 => 45,
      _ => 75,
    };
    // Scala count per weight medio (banal=3× → target più grosso).
    int totalWeight = 0;
    for (final t in types) {
      totalWeight += _mobWeight(t);
    }
    final avgWeight = totalWeight / types.length;
    final targetCount = (baseCount * avgWeight / 2.0).round();
    // Cap queue growth: se cap nemici blocca drain, next enqueue raddoppia
    // la queue ogni 15s → memory leak su fight prolungato. Skip se queue
    // già > 2× targetCount (abbondante).
    if (_bigWaveQueue.length > targetCount * 2) return;
    for (int i = 0; i < targetCount; i++) {
      _bigWaveQueue.add(types[_bossRandom.nextInt(types.length)]);
    }
  }

  /// Drena la queue: max `_kMaxSpawnPerFrame` mob per frame, rispetta cap.
  void _drainWaveQueue() {
    if (_bigWaveQueue.isEmpty) return;
    if (!allowMinionSpawn) {
      _bigWaveQueue.clear();
      return;
    }
    int spawned = 0;
    while (_bigWaveQueue.isNotEmpty && spawned < _kMaxSpawnPerFrame) {
      if (game.enemyCount >= bossBigWaveCap) return; // cap reached, resta in queue
      final type = _bigWaveQueue.removeFirst();
      final spawnPos = _colorWaveSpawnPos();
      if (spawnPos != null) {
        game.spawnEnemy(type, spawnPos);
      }
      spawned++;
    }
  }

  /// Calcola una posizione valida per uno spawn di color wave.
  /// Tunnel: viewport davanti al player. Normal: offset dal boss.
  /// Guard su tunnel walls troppo stretti (sinusoidale può collassare).
  Vector2? _colorWaveSpawnPos() {
    if (game.isTunnelMode) {
      final cameraX = game.camera.viewfinder.position.x;
      final halfW = game.size.x > 0 ? game.size.x / 2 : 400.0;
      final sx = cameraX + halfW + 50 + _bossRandom.nextDouble() * 400;
      final (topWall, bottomWall) = game.tunnelWallsAtX(sx);
      const margin = 20.0;
      final span = bottomWall - topWall - 2 * margin;
      final sy = span > 0
          ? topWall + margin + _bossRandom.nextDouble() * span
          : (topWall + bottomWall) / 2; // fallback center se walls stretti
      return Vector2(sx, sy);
    }
    // Cluster stretto attorno al boss (richiesta utente "molto vicini").
    final angle = _bossRandom.nextDouble() * math.pi * 2;
    final dist = 40 + _bossRandom.nextDouble() * 60;
    final raw = position +
        Vector2(math.cos(angle) * dist, math.sin(angle) * dist);
    return Vector2(
      raw.x.clamp(30.0, arenaWidth - 30.0),
      raw.y.clamp(30.0, arenaHeight - 30.0),
    );
  }

  /// Spawna nemici di supporto durante il boss fight.
  /// Rispetta il limite bossMinionEnemyCap per evitare lag.
  /// Fix (richiesta utente "mob dello stesso colore del boss"): non usa più
  /// liste hardcoded di tipi misti ma il `colorMatchedMinions` del boss.
  void _spawnMinions() {
    // Subclass può disabilitare (es. rage mode con fuoco già saturo).
    if (!allowMinionSpawn) return;
    // Controlla quanti nemici ci sono già — se troppi, non spawnare
    if (game.enemyCount >= bossMinionEnemyCap) return;

    // Dimezzato dal triplo (richiesta utente): 9/15/21/27 → 5/8/11/14.
    final baseCount = 5 + currentPhase * 3;
    final types = colorMatchedMinions;
    // Bias 70% verso mob VERAMENTE semplici (drone + swarmDrone) come
    // richiesto. 30% colorMatched specifico per identità del boss.
    // Kamikaze rimosso da simplePool (rush behavior, non "semplice").
    const simplePool = [
      EnemyType.drone,
      EnemyType.swarmDrone,
    ];
    // Se boss non ha colorMatchedMinions, fallback completo a simplePool
    // (prima return early → boss non spawnava nulla).

    for (int i = 0; i < baseCount; i++) {
      final isSimple = types.isEmpty || _bossRandom.nextDouble() < 0.7;
      final pool = isSimple ? simplePool : types;
      final type = pool[_bossRandom.nextInt(pool.length)];
      final angle = _bossRandom.nextDouble() * math.pi * 2;
      // Cluster stretto (richiesta utente "molto vicini al boss").
      final dist = 40 + _bossRandom.nextDouble() * 60;
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
    // Guard double-death: se takeDamage porta hp<=0 due volte nello stesso
    // frame (plasma AoE + bullet tick), onDeath veniva chiamato due volte
    // → duplicato score/audio/explosions/geom drops.
    if (_onDeathFired) return;
    _onDeathFired = true;

    game.onBossKilled(this);
    // Morte drammatica con budget particellare contenuto.
    // 20+25+15 = 60 particles (era 120 → lag visibile). Solo 1 explosion
    // `epic` (gli epic triggerano auto-shake(4, 0.15) + grid distortion).
    // Lo `triggerScreenShake(10, 0.5)` esplicito si SOMMA allo shake del
    // singolo epic → voluto, dà il "boom" culminante della morte.
    game.activateSlowMo(0.5, 0.25);
    game.spawnExplosion(position, const Color(0xFFFFFFFF),
        radius: 320, particleCount: 20, epic: true);
    game.spawnExplosion(position, neonColor,
        radius: 260, particleCount: 25);
    game.spawnExplosion(position, const Color(0xFFFF8800),
        radius: 180, particleCount: 15);
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

  /// Cached arc rect for the counter-rotating ring (section 4 in render).
  /// Depends only on `size`, which is fixed after construction — computed once
  /// in `onLoad` to avoid a per-frame `Rect.fromCircle` heap allocation.
  late Rect _ringArcRect;

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
    // Due archi opposti (180° span each with gap) — uses cached rect.
    canvas.drawArc(_ringArcRect, 0, math.pi * 0.75, false, _fxRingPaint);
    canvas.drawArc(_ringArcRect, math.pi, math.pi * 0.75, false, _fxRingPaint);
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
      // Divisore deve matchare il valore impostato in takeDamage (0.12),
      // altrimenti splitT max = 0.667 → effetto FX mai a intensità piena.
      final splitT = (_chromaticHitTimer / 0.12).clamp(0.0, 1.0);
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
    // Guard: boss morto (onDeath fired) resta attivo 1-2 frame prima che
    // removeFromParent propaghi. Collision callback fire-rebbe takeDamage
    // sul player → danno ingiusto da cadavere. Blocca.
    if (_onDeathFired) {
      super.onCollisionStart(intersectionPoints, other);
      return;
    }
    if (other is Player) {
      other.takeDamage();
    }
    super.onCollisionStart(intersectionPoints, other);
  }
}

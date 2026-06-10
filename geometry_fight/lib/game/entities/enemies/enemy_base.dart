import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
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
  // Tunnel mode: true appena il nemico entra nel viewport visibile.
  // Gate per right-escape: evita che mob freschi spawnati oltre dx vengano
  // immediatamente "killati" (con punti) prima che il player li veda.
  bool _hasBecomeVisible = false;

  // Spawn invulnerability (come GW:RE2 — nemici appaiono con effetto materializzazione)
  // 1.2s warning: nemico lampeggia, non si muove, non danneggia player, non subisce danno.
  // DEVE combaciare con `classicWaveGroupDelaySeconds` (constants.dart) — il blink
  // termina esattamente quando arriva il prossimo gruppo di spawn.
  double _spawnInvulnTimer = 1.2;
  // Durata iniziale dell'invuln di spawn: usata come denominatore nella curva di
  // accelerazione del blink (progress = 1 - remaining/initial). Aggiornata ogni
  // volta che setSpawnInvulnerability() è chiamata, così il denominatore è sempre
  // coerente con il timer effettivo (elimina il magic literal 1.2 nel blink code).
  double _spawnInvulnInitial = 1.2;
  // Fase accumulata per flash incrementale: avanza con freqHz*dt così la frequenza
  // può variare nel tempo (lento all'inizio, rapido verso la fine del warning)
  double _blinkPhase = 0;
  bool get isSpawnInvulnerable => _spawnInvulnTimer > 0;
  double get spawnInvulnTimer => _spawnInvulnTimer; // FIX H5: accesso da PhantomEnemy
  /// Azzera invulnerabilità spawn (per nemici generati in-game, non spawnati)
  void clearSpawnInvulnerability() => _spawnInvulnTimer = 0;
  /// Set breve invuln (es. 0.1s) per figli dei Splitter → protegge dalla
  /// cascata laser/plasma che investirebbe i figli nello stesso frame del
  /// padre. NON usa i 1.2s di default (evita che i figli restino fermi a
  /// lampeggiare — devono muoversi subito).
  void setSpawnInvulnerability(double seconds) {
    _spawnInvulnTimer = seconds;
    _spawnInvulnInitial = seconds;
  }

  // Fear mechanic (come GW:RE2 — nemici fuggono brevemente quando colpiti da proiettili vicini)
  double _fearTimer = 0;
  Vector2? _fearDirection;
  bool get canFearDodge => false;

  // Stun mechanic (EMP DRONE pet): mentre `_stunTimer > 0` il nemico
  // salta `updateBehavior` (resta fermo) ma può ancora subire danno.
  double _stunTimer = 0;
  bool get isStunned => _stunTimer > 0;

  /// Applica stun per `seconds` se il valore è maggiore del residuo corrente.
  /// Evita refresh "indebolente" se due EMP pulse si sovrappongono.
  void applyStun(double seconds) {
    if (seconds > _stunTimer) _stunTimer = seconds;
  }

  // Slow mechanic (SLOWER pet): mentre `_slowTimer > 0` il movimento del
  // nemico è scalato da `_slowFactor` (es. 0.45 = 45% velocità). Il campo del
  // pet ri-applica uno slow breve ogni frame finché il nemico resta dentro.
  double _slowTimer = 0;
  double _slowFactor = 1.0;
  bool get isSlowed => _slowTimer > 0;

  /// Applica un rallentamento: `factor` (0..1) scala la velocità, `seconds`
  /// la durata. Prende il factor più forte (minore) e la durata più lunga tra
  /// corrente e nuovo, così campi sovrapposti non si indeboliscono a vicenda.
  void applySlow(double seconds, double factor) {
    if (seconds > _slowTimer) _slowTimer = seconds;
    if (factor < _slowFactor) _slowFactor = factor;
  }

  /// Immunità danno ad area: bomba, plasma explosion, laser raycast, overdrive,
  /// shockwave morte player, buco nero. Usato dai Splitter per evitare cascata
  /// di divisioni simultanee che fa crashare il gioco.
  bool get isImmuneToAreaDamage => false;

  /// True se il contatto col player infligge danno. Override a false per nemici
  /// che NON devono uccidere al contatto (es. Leech: si aggancia e rallenta
  /// invece di danneggiare). Letto da `Player.onCollisionStart`.
  bool get damagesPlayerOnContact => true;

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
    if (_spawnInvulnTimer > 0) {
      // Flash frequency incrementale: 1 Hz all'inizio → 12 Hz a fine warning
      // Curva quadratica: accelera verso la fine per effetto "imminenza".
      // Usa `_spawnInvulnInitial` come denominatore (aggiornato da
      // setSpawnInvulnerability) così la curva è sempre corretta anche
      // se la durata varia (es. figli Splitter con 0.1s invece di 1.2s).
      // Prima era il magic literal 1.2: se il timer veniva impostato a un
      // valore diverso la curva non arrivava mai a 12 Hz (bug storico con 2.5s).
      final progress = _spawnInvulnInitial > 0
          ? (1.0 - (_spawnInvulnTimer / _spawnInvulnInitial)).clamp(0.0, 1.0)
          : 1.0;
      final freqHz = 1.0 + progress * progress * 11.0; // 1..12 Hz
      _blinkPhase += freqHz * dt;
      _spawnInvulnTimer -= dt;
    }
    if (_fearTimer > 0) _fearTimer -= dt;
    if (_stunTimer > 0) _stunTimer -= dt;
    if (_slowTimer > 0) {
      _slowTimer -= dt;
      if (_slowTimer <= 0) _slowFactor = 1.0; // reset quando il campo svanisce
    }

    // Tunnel mode: despawn dietro o oltre la camera.
    if (game.isTunnelMode) {
      final cameraX = game.camera.viewfinder.position.x;
      final halfW = game.size.x / 2;
      final cameraLeft = cameraX - halfW - 200;
      // Marca visibile se dentro viewport (offset 50px buffer).
      if (!_hasBecomeVisible && position.x < cameraX + halfW - 50) {
        _hasBecomeVisible = true;
      }
      // Dietro la camera (sx): rimozione silenziosa, nessun punto.
      if (position.x < cameraLeft) {
        removeFromParent();
        return;
      }
      // Oltre la camera (dx): mob sfuggito al player → come se killato.
      // Gate su `_hasBecomeVisible` → mob appena spawnati oltre dx che
      // non hanno MAI attraversato il viewport non ricevono punti.
      final cameraRightEscape = cameraX + halfW + 500;
      if (position.x > cameraRightEscape) {
        if (_hasBecomeVisible) {
          onDeath();
        } else {
          // Non mai stato visibile → despawn silenzioso, no reward.
          removeFromParent();
        }
        return;
      }
    }

    // Durante il warning di spawn (2.5s) il nemico sta fermo: niente fear, niente behavior
    if (_spawnInvulnTimer <= 0) {
      // Stun (EMP DRONE pet): blocca tutto il movimento, anche la fear.
      if (_stunTimer > 0) {
        // skip
      } else if (_fearTimer > 0 && _fearDirection != null) {
        // Fear: fuggi nella direzione opposta brevemente
        position += _fearDirection! * speed * 2.5 * dt;
      } else {
        // SLOWER pet: dt scalato → movimento e timer interni del nemico
        // rallentano in proporzione finché resta dentro al campo.
        // Modifier speed_demon (×1.5) / bullet_hell (×2) accelerano il behavior
        // (movimento + fuoco) — vedi game.enemyBehaviorScale. Si combinano
        // moltiplicando con lo slow del pet.
        final base = isSlowed ? dt * _slowFactor : dt;
        updateBehavior(base * game.enemyBehaviorScale);
      }
    }

    // Se updateBehavior ha auto-distrutto il nemico (es. Mutator a fine
    // mutazioni → onDeath/removeFromParent + _isDead=true), salta clamp/tunnel:
    // evita di operare su un componente già in coda di rimozione.
    if (_isDead) return;

    // Clamp to arena DOPO il movimento (fear + updateBehavior) per evitare jitter
    if (game.isTunnelMode) {
      // Tunnel: clamp Y ai muri dinamici sinusoidali
      final (topWall, bottomWall) = game.tunnelWallsAtX(position.x);
      const margin = 6.0;
      position.y = position.y.clamp(topWall + margin, bottomWall - margin);
      // Muri rossi tunnel impenetrabili: teletrasporta al centro tunnel
      // se dentro obstacle (4px push era insufficiente per obstacle profondi
      // → mob stuck dentro parete).
      if (game.hitsTunnelObstacle(position)) {
        position.y = (topWall + bottomWall) / 2;
      }
    } else {
      // Clamp con half-size: sprite intero dentro il bordo arena (richiesta
      // utente "bordo arena impenetrabile"). Prima `5` → mezzo mob usciva.
      final hx = size.x / 2;
      final hy = size.y / 2;
      // tiny_arena: clamp all'arena effettiva centrata (i mob restano nel box).
      position.x = position.x.clamp(game.arenaMinX + hx, game.arenaMaxX - hx);
      position.y = position.y.clamp(game.arenaMinY + hy, game.arenaMaxY - hy);
    }
  }

  void updateBehavior(double dt);

  /// ATTENZIONE per chi estende: SE si fa override di `takeDamage`,
  /// propagare SEMPRE `isArea` a `super.takeDamage(amount, isArea: isArea)`.
  /// Se si gestisce `hp` inline senza super, replicare il check:
  ///   `if (isArea && isImmuneToAreaDamage) return;`
  /// Altrimenti la cascata di split dei Splitter torna a crashare il gioco.
  void takeDamage(double amount, {bool isArea = false}) {
    // Invulnerabile durante spawn (materializzazione come GW:RE2)
    if (_spawnInvulnTimer > 0) return;
    // Immunità danno ad area (es. Splitter — evita cascata split simultanea)
    if (isArea && isImmuneToAreaDamage) return;

    // Modifier ONE SHOT: qualunque colpo uccide il nemico in un colpo
    // (richiesta utente: "tutti i nemici muoiono con 1 colpo. Ma anche tu").
    // DOPO i guard spawn-invuln/area-immunity → non rompe materializzazione né
    // la cascata Splitter. I boss (BossBase) hanno takeDamage separato → esenti.
    if (game.hasModifier('one_shot')) {
      hp = 0;
      _flashTimer = 0.1;
      onDeath();
      return;
    }

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
  /// Rispetta isImmuneToAreaDamage: Splitter sopravvivono alla shockwave.
  /// Guard su `_isDead`: se due sistemi invocano `killSilently` nello stesso
  /// frame (es. bomba + gate explosion), evita doppia esplosione visiva.
  ///
  /// `spawnPuff`: se false salta il puff di 3 particelle per-nemico. La
  /// shockwave di morte del player può uccidere centinaia di mob in un frame
  /// → 3 particelle × N intasa l'event-loop Dart e ritarda boom + cambio
  /// canzone. La mega-esplosione 600px copre già visivamente la "wave che
  /// distrugge i nemici". Default true: gli altri caller (black hole, ecc.)
  /// mantengono il puff.
  void killSilently({bool spawnPuff = true}) {
    if (isImmuneToAreaDamage) return;
    if (_isDead) return;
    _isDead = true;
    if (spawnPuff) {
      game.spawnExplosion(position, neonColor,
          radius: size.x * 0.5, particleCount: 3);
    }
    removeFromParent();
  }

  Vector2 get playerPosition {
    if (!game.player.isMounted) return position;
    return game.player.position;
  }

  Vector2 seekPlayer(double maxSpeed) {
    final dir = (playerPosition - position);
    // length² evita la sqrt di `.length` — threshold 0.0001 = 0.01px di distanza.
    if (dir.length2 > 0.0001) {
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
    // Frequenza del flash cresce 1→12 Hz lungo il warning (vedi update): _blinkPhase
    // accumula cicli, quindi floor()%2 alterna on/off con cadenza variabile.
    if (_spawnInvulnTimer > 0) {
      final showFrame = _blinkPhase.floor() % 2 == 0;
      if (!showFrame) return; // Non renderizza → frame "off" del flash
    }

    // Baseline condiviso: alcune subclass mutano `detailPaint` (style/maskFilter)
    // dentro renderShape e potrebbero non resettarlo uscendo da un branch early.
    // Reset qui garantisce stato pulito per ogni nemico → fix paint-state leak
    // cross-enemy (es. Healer lascia stroke → Proton trail reso come outline).
    detailPaint.style = PaintingStyle.fill;
    detailPaint.maskFilter = null;

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

import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/painting.dart' show HSVColor;
import '../../data/constants.dart';
import '../../data/difficulty.dart';
import '../effects/chain_lightning_effect.dart';
import '../game_world.dart';
import 'bosses/boss_base.dart';
import 'enemies/enemy_base.dart';
import 'pets/pet_base.dart';
import 'projectiles.dart';
import 'snake_trail.dart';

enum WeaponType {
  basic,
  spread,
  spreadFan,
  laser,
  plasma,
  ricochet,
  triple,
  overdrive,

  /// Iter 13 (utente): Gauss Cannon — colpo lento+forte + aspirazione
  /// nemici a corto raggio per 1s ad ogni colpo. Fire interval 0.7s.
  gauss,

  /// Iter 13 (utente): Chain Lightning — bolt rimbalza tra fino a 5
  /// nemici. Damage decade per jump. Shop-unlock.
  chainLightning,

  /// Shotgun — raffica a cono ravvicinata (8 pellet arancioni, corto raggio).
  shotgun,

  /// Railgun — colpo hitscan che perfora tutti i nemici in linea retta.
  railgun,

  /// Homing — DEVE restare ultima in elenco (richiesta utente).
  homing,
}

// Plasma: colpo lento con danni base * 3.9 (era 3.0, +30% richiesta utente).
const double kPlasmaDamageMultiplier = 3.9;

class Player extends PositionComponent
    with HasGameReference<GeometryFightGame>, CollisionCallbacks {
  int lives = playerStartLives;
  int bombs = playerStartBombs;
  double speed = playerSpeed;
  WeaponType currentWeapon = WeaponType.basic;
  WeaponType? temporaryWeapon;
  double weaponTimer = 0;

  double _fireTimer = 0;
  double _invincibleTimer = 0;
  bool get isInvincible => _invincibleTimer > 0;

  /// Controls inverted flag — settato dai GravityWellEnemy ogni frame mentre
  /// il player è dentro il loro raggio. Se true, `moveInput` viene negato in
  /// update() prima dell'integrazione della posizione. Reset a false ad ogni
  /// tick, quindi va settato continuativamente.
  bool controlsInverted = false;

  // Shield
  int shieldHits = 0;
  bool hasShield = false;
  double shieldTimer = 0;

  // Shake detection (richiesta utente): il wiggle rapido del joystick libera i
  // Leech agganciati. Accumula i reversal di direzione del movimento e decade
  // nel tempo; `isShaking` è true sopra la soglia.
  Vector2 _prevMoveInput = Vector2.zero();
  double _shakeMeter = 0;
  static const double _shakeThreshold = 3.0; // ~2 inversioni nette del joystick
  bool get isShaking => _shakeMeter >= _shakeThreshold;

  // CRIT talent: rng per il roll del colpo critico (per-salva).
  static final math.Random _critRng = math.Random();

  // DASH talent: scatto rapido con i-frame. `_dashTimer` attivo durante lo
  // scatto, `_dashCd` cooldown residuo, `_dashDir` direzione bloccata.
  double _dashTimer = 0;
  double _dashCd = 0;
  Vector2 _dashDir = Vector2(1, 0);
  static const double _dashDuration = 0.18;
  static const double _dashSpeed = 1400.0;
  bool get isDashing => _dashTimer > 0;

  // Power-up states
  double rapidFireTimer = 0;
  double overdriveTimer = 0;
  double magnetTimer = 0;
  double timeSlowTimer = 0;
  double firePowerTimer = 0;

  /// Iter 14: Gauss Cannon pull rifattorizzato. Il pull non è più
  /// player-centric: ogni proiettile Gauss spawna una `GaussImplosion` sul
  /// punto di impatto che gestisce pull + tick damage. Campo conservato
  /// (= 0 sempre) per compatibilità API esterna; setter no-op.
  double gaussPullTimer = 0;
  bool get hasRapidFire => rapidFireTimer > 0;
  bool get hasOverdrive => overdriveTimer > 0;
  bool get hasMagnet => magnetTimer > 0;
  bool get hasFirePower => firePowerTimer > 0;

  // Visual
  double _thrusterPhase = 0;
  double _rotation = 0;
  double _wingPulse = 0;
  double _energyPhase = 0;
  double _shieldPhase = 0;

  // Cache del colore crystal (HSV ciclante): ricomputato solo quando la hue
  // step avanza (intervalli di 5°) → da 60 HSV/sec per player a ~2/sec.
  int _crystalHueStep = -1;
  Color? _crystalColorCache;
  String? _crystalCachedSkin;

  // Trail di movimento (scia luminosa)
  final List<Vector2> _trail = [];
  static const int _maxTrailLength = 18;
  double _trailTimer = 0;

  // Snake mode: tick accumulator + tracked active segments per il cap recycle.
  // Ogni `_snakeTrailInterval` secondi spawna un `SnakeTrailSegment` come
  // child del world. Cap a `_snakeTrailMaxSegments`: oltre, il segment più
  // vecchio viene rimosso (recycle FIFO).
  double _snakeTrailTick = 0;
  static const double _snakeTrailInterval = 0.03;
  // Cap a 50 = 1/3 del precedente 150. A `_snakeTrailInterval` = 0.03s, il
  // FIFO recycle evicta segmenti più vecchi di ~1.5s (50 * 0.03), molto prima
  // del lifetime naturale di 4s definito in snake_trail.dart. Effetto: scia
  // visualmente più corta (~1.5s di movimento player) e leggermente più
  // economica da renderizzare.
  static const int _snakeTrailMaxSegments = 50;
  final List<SnakeTrailSegment> _snakeTrailSegments = <SnakeTrailSegment>[];
  // Posizione del frame precedente per interpolazione: se microlag fa
  // saltare il player più in là di un singolo segmento, lerp da prev→pos
  // e spawna segmenti lungo il path → no più gap visibili nella scia.
  Vector2? _snakePrevPos;
  // Offset back-along-velocity per spawnare il segmento subito DIETRO la
  // navicella invece che al centro: 16px ≈ raggio player (player size 30).
  static const double _snakeTrailBackOffset = 16.0;
  // Phase counter (incrementato ad ogni spawn) per dare un pulse cromatico
  // visualmente coerente lungo la scia.
  double _snakeTrailPhase = 0;

  // Knockback time-based (richiesta utente "pushback duri 1-1.5s, no
  // istantaneo"). Velocità decade linearmente da v0→0 sull'intera durata,
  // così la distanza integrata = v0 * duration / 2 = `distance` requested.
  Vector2 _knockbackVel = Vector2.zero();
  double _knockbackTimer = 0;
  double _knockbackDuration = 0;

  /// Applica un knockback animato over time. `dir` è la direzione (auto
  /// normalizzata), `distance` è la distanza totale da percorrere, `duration`
  /// è il tempo dell'animazione (default 1.2s = sweet spot fra istantaneo
  /// e troppo lento).
  ///
  /// Multiple call sovrascrivono il knockback in corso (no stacking) per
  /// evitare yo-yo se 2 black hole esplodono ravvicinati.
  void applyKnockback(Vector2 dir, double distance, {double duration = 1.2}) {
    if (dir.length2 < 1e-6 || distance <= 0 || duration <= 0) return;
    final v0 = 2 * distance / duration;
    _knockbackVel = dir.normalized() * v0;
    _knockbackTimer = duration;
    _knockbackDuration = duration;
  }

  Player() : super(size: Vector2(30, 34), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    add(
      CircleHitbox(radius: playerHurtboxRadius, anchor: Anchor.center)
        ..position = size / 2,
    );
  }

  /// Imposta l'arma equipaggiata a partire dall'id salvato (shop).
  /// Valori validi: 'basic', 'triple', 'spread', 'ricochet', 'homing', 'plasma', 'laser'.
  void setWeaponFromId(String id) {
    switch (id) {
      case 'triple':
        currentWeapon = WeaponType.triple;
      case 'spread':
        currentWeapon = WeaponType.spread;
      case 'ricochet':
        currentWeapon = WeaponType.ricochet;
      case 'homing':
        currentWeapon = WeaponType.homing;
      case 'plasma':
        currentWeapon = WeaponType.plasma;
      case 'laser':
        currentWeapon = WeaponType.laser;
      case 'gauss':
        currentWeapon = WeaponType.gauss;
      case 'chain':
        currentWeapon = WeaponType.chainLightning;
      case 'shotgun':
        currentWeapon = WeaponType.shotgun;
      case 'railgun':
        currentWeapon = WeaponType.railgun;
      case 'basic':
      default:
        currentWeapon = WeaponType.basic;
    }
  }

  @override
  void update(double dt) {
    // Il player NON è affetto dal slow-motion: compensa il timeScale.
    // Clamp divisore a 0.3 min: durante bomb-freeze (timeScale≈0.05) eviterebbe
    // realDt = 20× dt → step fisico ~333ms che teletrasporta il player fuori arena.
    final scaledDiv = game.timeScale.clamp(0.3, 1.0);
    final realDt = dt / scaledDiv;
    super.update(realDt);

    // Tunnel auto-scroll (richiesta utente): il player segue la camera di
    // default, così se non tocca lo stick resta al centro schermo invece
    // di restare indietro appiccicato al bordo sinistro.
    if (game.isTunnelMode) {
      position.x += game.tunnelScrollSpeed * realDt;
    }

    // Movement (usa realDt per non essere rallentato dallo slow-mo)
    // Se il player è dentro il raggio di un GravityWellEnemy, `controlsInverted`
    // viene settato true ogni frame dal nemico → nega moveInput per invertire
    // i controlli (meccanica GW). Flag resettato a fine tick.
    final moveDir = controlsInverted ? -game.moveInput : game.moveInput;
    if (moveDir.length2 > 0) {
      final actualSpeed =
          speed * (hasOverdrive ? 1.15 : 1.0) * game.saveData.speedMultiplier;
      position += moveDir * actualSpeed * realDt;
    }
    // Reset flag ad ogni tick — i GravityWell lo rialzano in updateBehavior
    // se il player resta nel raggio, altrimenti i controlli tornano normali.
    controlsInverted = false;

    // ── DASH (talent) ───────────────────────────────────────────────────
    // Trigger via game.dashPressed (bottone HUD). Scatto rapido in direzione
    // di movimento (o orientamento nave) con i-frame; cooldown da
    // saveData.dashCooldown. Integrato qui PRIMA del clamp → resta in arena.
    if (game.dashPressed) {
      game.dashPressed = false;
      _tryDash();
    }
    if (_dashCd > 0) _dashCd -= realDt;
    if (_dashTimer > 0) {
      _dashTimer -= realDt;
      position += _dashDir * _dashSpeed * realDt;
    }

    // ── KNOCKBACK time-based (es. esplosione black hole) ────────────────
    // Decadimento lineare velocità v(t) = v0 * (1 - t/T) → integrale =
    // v0*T/2 = distance richiesta in `applyKnockback`. Evita teletrasporto
    // istantaneo del player (richiesta utente: durata ~1.2s).
    if (_knockbackTimer > 0) {
      final progress = 1.0 - (_knockbackTimer / _knockbackDuration);
      final velFactor = (1.0 - progress).clamp(0.0, 1.0);
      position += _knockbackVel * velFactor * realDt;
      _knockbackTimer -= realDt;
      if (_knockbackTimer <= 0) {
        _knockbackVel.setZero();
      }
    }

    // Clamp to arena
    if (game.isTunnelMode) {
      // Tunnel side-scroller: il player si muove liberamente dentro lo schermo visibile.
      // La camera avanza da sola — il player NON può uscire dalla vista.
      // Guard: game.size potrebbe essere zero durante i primi frame
      final screenHalfW = game.size.x > 0 ? game.size.x / 2 : 400.0;
      final screenHalfH = game.size.y > 0 ? game.size.y / 2 : 300.0;
      final cameraX = game.camera.viewfinder.position.x;
      final cameraY = game.camera.viewfinder.position.y;
      // Clamp X: non può andare dietro al bordo sinistro né oltre il bordo destro
      position.x = position.x.clamp(
        cameraX - screenHalfW + 20,
        cameraX + screenHalfW - 20,
      );
      // Clamp Y: limitato dalla vista della camera (il tunnel renderer fa il clamp fine sui muri)
      position.y = position.y.clamp(
        cameraY - screenHalfH + 20,
        cameraY + screenHalfH - 20,
      );
    } else {
      // Modalità normali: limiti sia X che Y. Modifier tiny_arena → arena
      // effettiva centrata (meno spazio per schivare — richiesta utente).
      position.x = position.x.clamp(game.arenaMinX + 15, game.arenaMaxX - 15);
      position.y = position.y.clamp(game.arenaMinY + 15, game.arenaMaxY - 15);
    }

    // Aim direction.
    // Rotation logic (iter 4):
    //  - Se il player sta sparando (fire button OR aim stick attivo) E non è
    //    pacifist → la nave si gira verso lo shoot direction (aim stick).
    //  - Altrimenti → la nave si gira verso la direzione di movimento (riusa
    //    `moveDir` calcolato sopra, che considera già `controlsInverted`).
    //  - In idle (no input) → mantiene rotazione corrente.
    // Snake mode: non si spara mai → rotazione sempre verso il movimento.
    final aimDir = game.aimInput;
    final wantsToShoot =
        !game.isPacifistMode &&
        game.gameMode != GameMode.snake &&
        (game.isShooting || aimDir.length > 0.3);
    if (wantsToShoot && aimDir.length > 0) {
      _rotation = math.atan2(aimDir.y, aimDir.x) + math.pi / 2;
    } else if (moveDir.length2 > 0.01) {
      _rotation = math.atan2(moveDir.y, moveDir.x) + math.pi / 2;
    }

    // Shooting (usa realDt per non essere rallentato dallo slow-mo)
    _fireTimer -= realDt;
    // Snake mode: no spari (regola design — trail-kill puro).
    // Pacifism mode: shooting completamente bloccato (regola GW2 Pacifism).
    // Modifier infinite_bombs (BOMBER): "niente armi" → spari disabilitati,
    // resta solo la bomba infinita (richiesta utente: modifier non funzionava).
    final canShoot =
        !game.isPacifistMode &&
        game.gameMode != GameMode.snake &&
        !game.hasModifier('infinite_bombs');
    if (canShoot &&
        (game.isShooting || aimDir.length > 0.3) &&
        _fireTimer <= 0) {
      // Direction default: se il giocatore preme fire senza mirare, usa
      // l'orientamento della nave (_rotation) invece di hardcoded "su".
      // Prima: ship che guardava est sparava sempre a nord → disconnect
      // visivo. _rotation = atan2(aimY, aimX) + pi/2 → aimVector inverso:
      // (cos(_rotation - pi/2), sin(_rotation - pi/2)).
      final Vector2 shootDir;
      if (aimDir.length > 0.3) {
        shootDir = aimDir;
      } else {
        final a = _rotation - math.pi / 2;
        shootDir = Vector2(math.cos(a), math.sin(a));
      }
      _shoot(shootDir);
    }

    // Timers (tutti con realDt — il player non è affetto dal slow-mo)
    if (_invincibleTimer > 0) _invincibleTimer -= realDt;
    if (rapidFireTimer > 0) rapidFireTimer -= realDt;
    if (overdriveTimer > 0) overdriveTimer -= realDt;
    if (magnetTimer > 0) magnetTimer -= realDt;
    if (firePowerTimer > 0) firePowerTimer -= realDt;
    // Iter 14: gaussPullTimer rimosso. Il pull ora vive nell'impact-point
    // implosion (vedi GaussBullet → GaussImplosion).
    if (timeSlowTimer > 0) {
      timeSlowTimer -= realDt;
      if (timeSlowTimer <= 0) {
        // Non resettare timeScale se c'è un burst slow-mo attivo (bomba/morte)
        if (game.slowMoTimer <= 0) {
          game.timeScale = 1.0;
        }
      }
    }
    if (weaponTimer > 0) {
      weaponTimer -= realDt;
      if (weaponTimer <= 0) {
        temporaryWeapon = null;
      }
    }
    if (hasShield && shieldTimer > 0) {
      shieldTimer -= realDt;
      if (shieldTimer <= 0) {
        hasShield = false;
        shieldHits = 0;
      }
    }

    // Shake detection per liberare i Leech agganciati. Il vecchio metodo
    // sommava +1 solo nel singolo frame dell'inversione mentre decadeva a 2/s
    // → di fatto irraggiungibile (utente: "non si stacca anche se mi scuoto
    // moltissime volte"). Ora `_prevMoveInput` è la direzione di RIFERIMENTO
    // (ultima direzione stabile): ogni inversione netta del joystick rispetto
    // ad essa conta come 1 "scrollata" (+1.5) e aggiorna il riferimento →
    // bastano ~2-3 wiggle sx/dx per liberare il leech.
    final shakeInput = game.moveInput;
    if (shakeInput.length2 > 0.08) {
      final cur = shakeInput.normalized();
      if (_prevMoveInput.length2 > 0.5) {
        final d = cur.dot(_prevMoveInput);
        if (d < -0.3) {
          _shakeMeter += 1.5; // inversione netta → conta 1 scrollata
          _prevMoveInput = cur.clone();
        } else if (d > 0.5) {
          _prevMoveInput = cur.clone(); // stessa direzione: segue derive lente
        }
        // d in [-0.3, 0.5]: transizione ambigua → non aggiornare il riferimento
      } else {
        _prevMoveInput = cur.clone();
      }
    }
    _shakeMeter = (_shakeMeter - realDt * 1.0).clamp(0.0, 12.0);

    // Bomb
    if (game.bombPressed) {
      game.bombPressed = false;
      game.useBomb();
    }

    // Magnet - attract geoms
    if (hasMagnet || game.saveData.magnetRange > 0) {
      _attractGeoms();
    }

    // Animazioni visive
    _thrusterPhase += realDt * 15;
    _wingPulse += realDt * 4;
    _energyPhase += realDt * 8;
    _shieldPhase += realDt * 3;

    // Trail di movimento: registra posizione ogni 0.02s
    // Usa realDt: il trail non deve essere rallentato dal slow-mo.
    _trailTimer += realDt;
    if (_trailTimer >= 0.02 && moveDir.length2 > 0.01) {
      _trailTimer = 0;
      _trail.insert(0, position.clone());
      if (_trail.length > _maxTrailLength) _trail.removeLast();
    } else if (moveDir.length2 <= 0.01 && _trail.isNotEmpty) {
      // Dissolvenza trail quando fermi
      if (_trailTimer >= 0.05) {
        _trailTimer = 0;
        if (_trail.isNotEmpty) _trail.removeLast();
      }
    }

    // Snake mode: emit segmenti scia letale alle spalle della navicella.
    // Cap FIFO a `_snakeTrailMaxSegments` per perf + leggibilità. Cleanup
    // segmenti già rimossi (auto-removed dopo 4s) dalla nostra list di
    // tracking così il cap non conta zombie.
    if (game.gameMode == GameMode.snake) {
      // Hard stop su pause / gameOver: il game_world.update() ritorna early
      // con super.update(0) → realDt=0 e tick non avanza, ma teniamo un guard
      // esplicito così se in futuro cambia il flow il trail non spawna mai
      // più durante pause/death (richiesta utente: must stop on gameOver/pause).
      final gs = game.gameState;
      if (gs == GameState.playing) {
        // Prune stale refs OGNI frame (non solo allo spawn): i segmenti
        // self-remove a 4s, se prune solo allo spawn potremmo trattenere
        // refs morti fino al prossimo tick → memoria + cap conta zombie.
        _snakeTrailSegments.removeWhere((s) => s.isRemoved || !s.isMounted);

        _snakeTrailTick += realDt;
        // Interpolazione anti-microlag: se realDt è grande (frame drop),
        // il player può essere "saltato" più di un intervallo. Lerp da
        // _snakePrevPos → position e spawna multipli segmenti lungo il
        // path. Loop while finché _snakeTrailTick rientra sotto la soglia.
        final prev = _snakePrevPos ?? position;
        // Direzione back-along-velocity per offset dietro la nave.
        // Usa moveDir (locale a update()), fallback al vettore prev→position.
        Vector2 backVec;
        if (moveDir.length2 > 0.01) {
          backVec = -moveDir.normalized() * _snakeTrailBackOffset;
        } else {
          final delta = position - prev;
          if (delta.length2 > 0.01) {
            backVec = -delta.normalized() * _snakeTrailBackOffset;
          } else {
            // Fermo: usa la rotazione corrente (la prua è -π/2 dal _rotation)
            // → back = +cos/sin direction da _rotation - π/2 inverted.
            final ang = _rotation - math.pi / 2;
            backVec =
                Vector2(-math.cos(ang), -math.sin(ang)) * _snakeTrailBackOffset;
          }
        }
        while (_snakeTrailTick >= _snakeTrailInterval) {
          _snakeTrailTick -= _snakeTrailInterval;
          // t va da prev→position. Quando _snakeTrailTick scende sotto la
          // soglia dopo i decrementi, t finale ≈ realDt/totale → spawn più
          // vicino alla posizione corrente. Distribuzione uniforme nei
          // frame normali, lerp lineare nei frame con dt grande.
          final tRemain = realDt > 0
              ? (_snakeTrailTick / realDt).clamp(0.0, 1.0)
              : 0.0;
          final t = (1.0 - tRemain).clamp(0.0, 1.0);
          final spawnPos = Vector2(
            prev.x + (position.x - prev.x) * t,
            prev.y + (position.y - prev.y) * t,
          )..add(backVec);
          // Cap recycle: rimuovi il più vecchio finché non rientriamo.
          while (_snakeTrailSegments.length >= _snakeTrailMaxSegments) {
            final old = _snakeTrailSegments.removeAt(0);
            if (!old.isRemoved && old.isMounted) old.removeFromParent();
          }
          _snakeTrailPhase += 0.35;
          final seg = SnakeTrailSegment(
            spawnAt: spawnPos,
            phase: _snakeTrailPhase,
          );
          _snakeTrailSegments.add(seg);
          game.world.add(seg);
        }
        // Aggiorna prev per il prossimo frame DOPO i spawn (così la prossima
        // interpolazione parte dalla posizione corrente).
        _snakePrevPos = position.clone();
      }
    }
  }

  void _shoot(Vector2 direction) {
    final weapon = temporaryWeapon ?? currentWeapon;
    // Overdrive powerup: potenzia SOLO la velocità di movimento della nave
    // (vedi update() line 103). Non incrementa fire rate né danno né pierce
    // — era un effetto cumulativo che rendeva il powerup troppo forte.
    // Clamp a 0.01 min per evitare divisione per zero se un shop mult arriva
    // a 0 (bug upgrade tier o save file corrotto) → fire interval infinito,
    // il player non spara più per tutto il run. Safety net.
    final fireRateMultiplier =
        (game.saveData.fireRateMultiplier * (hasRapidFire ? 2.5 : 1.0)).clamp(
          0.01,
          double.infinity,
        );

    final double fireInterval = 1.0 / (baseFireRate * fireRateMultiplier);
    _fireTimer = fireInterval;

    final dir = direction.normalized();
    double damageMultiplier = game.saveData.damageMultiplier;
    if (hasFirePower) damageMultiplier *= 2.0;
    // Modifier glass_cannon: 3× danno (e 1 sola vita, applicata in
    // _applyModifiers). Wired qui per ogni weapon type.
    if (game.hasModifier('glass_cannon')) damageMultiplier *= 3.0;
    // CRIT talent: roll per-salva. Su critico moltiplica il danno (×2.2, vedi
    // SaveData.kCritMultiplier) e spawna una scintilla gialla di feedback.
    if (game.saveData.critChance > 0 &&
        _critRng.nextDouble() < game.saveData.critChance) {
      damageMultiplier *= 2.2;
      game.spawnExplosion(
        position,
        const Color(0xFFFFEE66),
        radius: 16,
        particleCount: 6,
      );
    }
    const pierce = false;
    final basicColor = hasFirePower
        ? const Color(0xFFFF3300)
        : NeonColors.bulletYellow;

    switch (weapon) {
      case WeaponType.basic:
        // Due file parallele di proiettili
        final perp = Vector2(-dir.y, dir.x) * 6; // 6px di distanza
        _spawnBullet(
          dir,
          damageMultiplier,
          basicColor,
          offset: perp,
          pierce: pierce,
          weaponType: WeaponType.basic,
        );
        _spawnBullet(
          dir,
          damageMultiplier,
          basicColor,
          offset: -perp,
          pierce: pierce,
          weaponType: WeaponType.basic,
        );
      case WeaponType.spread:
        // 5 proiettili a ventaglio (shop weapon)
        for (final angle in [-0.12, -0.06, 0.0, 0.06, 0.12]) {
          final rotDir = _rotateVector(dir, angle);
          _spawnBullet(
            rotDir,
            damageMultiplier * 0.85,
            NeonColors.spreadOrange,
            speed: bulletSpeed * 1.1,
            pierce: pierce,
            weaponType: WeaponType.spread,
          );
        }
      case WeaponType.spreadFan:
        // 9 proiettili con angolo totale 20° (±10°) — powerup drop
        for (final angle in [
          -0.175,
          -0.13125,
          -0.0875,
          -0.04375,
          0.0,
          0.04375,
          0.0875,
          0.13125,
          0.175,
        ]) {
          final rotDir = _rotateVector(dir, angle);
          _spawnBullet(
            rotDir,
            damageMultiplier * 0.7,
            NeonColors.spreadOrange,
            speed: bulletSpeed * 1.2,
            pierce: pierce,
            weaponType: WeaponType.spreadFan,
          );
        }
      case WeaponType.laser:
        _spawnLaser(dir, damageMultiplier);
      case WeaponType.plasma:
        _spawnPlasma(dir, damageMultiplier);
        // +50% fire rate: 0.4 → 0.267s tra i colpi. Anche scalato dagli
        // upgrade shop + rapidFire powerup (entrambi già in fireRateMultiplier).
        // Overdrive powerup NON accelera il fire rate (solo movimento).
        _fireTimer = (0.4 / 1.5) / fireRateMultiplier;
      case WeaponType.ricochet:
        // Ventaglio di 3 colpi che rimbalzano (richiesta utente).
        // Angoli: ~23° totali (-0.20, 0, +0.20 rad).
        // Danno per colpo: 0.825x (era 0.55, +50% richiesta utente).
        //   → DPS totale 3 × 0.825 = 2.475x per salvo.
        // maxBounces ridotto 3→2 (~30% meno range, richiesta utente):
        //   ogni rimbalzo estende la vita utile del colpo; meno rimbalzi
        //   → meno distanza totale prima del despawn.
        for (final angle in [-0.20, 0.0, 0.20]) {
          final rotDir = _rotateVector(dir, angle);
          _spawnBullet(
            rotDir,
            damageMultiplier * 0.825,
            NeonColors.ricochetGreen,
            maxBounces: 2,
            pierce: pierce,
            weaponType: WeaponType.ricochet,
          );
        }
      case WeaponType.homing:
        // Base 5 missili. Ventaglio di angoli per coprire più bersagli.
        // Ogni salva ha un volleyId unico: i missili della stessa salva
        // cercano bersagli DISTINTI tra loro (richiesta utente).
        //
        // Spawn: TUTTI dalla parte anteriore della navicella (stesso punto).
        // La divergenza avviene DOPO lo spawn grazie al ventaglio di angoli
        // + target distinti — i missili si allontanano naturalmente.
        //
        // Cap attivi: massimo 20 missili in volo simultanei. Con rapidFire
        // il cap sale a 30 (non 40: rapidFire deve essere meno efficace
        // su quest'arma del 50% — altrimenti troppi missili in scena).
        // Se la salva supera il cap, spawna solo quanti ne entrano.
        const homingCount = 5;
        final maxActive = hasRapidFire ? 30 : 20;
        final available = maxActive - HomingMissile.activeCount;
        final toSpawn = available.clamp(0, homingCount);
        if (toSpawn > 0) {
          final volleyId = HomingMissile.nextVolleyId();
          // Punto di spawn: naso della navicella = posizione player + offset
          // lungo la direzione di tiro. 22px = davanti al corpo del player
          // (player size ~30px, ship forward-tip a ~22 dal centro).
          final nose = position + dir.normalized() * 22;
          for (int i = 0; i < toSpawn; i++) {
            final spread = (i - (homingCount - 1) / 2) * 0.15;
            final rotatedDir = _rotateVector(dir, spread);
            _spawnHomingMissile(
              rotatedDir,
              damageMultiplier,
              volleyId: volleyId,
              spawnAt: nose,
            );
          }
        }
        // Fire rate rapidFire dimezzato in efficacia: normalmente rapidFire
        // dà 2.5x fire rate; qui 1.75x (boost ridotto del 50%: +150% → +75%)
        // → meno missili accumulati nel tempo, cap più facile da rispettare.
        // Overdrive powerup NON accelera il fire rate (solo movimento).
        // Calcolo custom: bypassa `fireRateMultiplier` che ha già 2.5x per
        // rapidFire, e applica 1.75x qui. Senza rapidFire usa il solo shop mult.
        final homingMult =
            game.saveData.fireRateMultiplier * (hasRapidFire ? 1.75 : 1.0);
        _fireTimer = 0.5 / homingMult;
      case WeaponType.triple:
        // Sparo triplo con angolo ristretto (~12° totali)
        for (final angle in [-0.105, 0.0, 0.105]) {
          final rotDir = _rotateVector(dir, angle);
          _spawnBullet(
            rotDir,
            damageMultiplier,
            NeonColors.white,
            pierce: pierce,
            weaponType: WeaponType.triple,
          );
        }
        _fireTimer = fireInterval * 0.5;
      case WeaponType.overdrive:
        _spawnOverdriveBeam(dir);
        _fireTimer = 3.0 / fireRateMultiplier;
      case WeaponType.gauss:
        // Iter 14 (utente): swirl bullet dedicato. All'impatto (enemy/boss
        // OR fine vita) spawna implosion 2s sul punto: pull + tick damage.
        // Damage diretto >= per-missile homing (~ damage*4.0 vs 2.25 homing).
        _spawnGaussBullet(dir, damageMultiplier * 4.0);
        // Fire interval 0.7s base, accelerato da fireRateMultiplier.
        _fireTimer = (0.7 / fireRateMultiplier).clamp(0.05, 5.0);
      case WeaponType.chainLightning:
        // Iter 13: bolt rimbalza fino a 5 nemici. Damage decade 0.85x per
        // jump. Range jump 200px. Visual: ChainLightningEffect.
        _castChainLightning(damageMultiplier);
        // Fire rate 0.55s base (più rapido di gauss ma più lento di basic).
        _fireTimer = (0.55 / fireRateMultiplier).clamp(0.05, 5.0);
      case WeaponType.shotgun:
        _spawnShotgun(dir, damageMultiplier);
        // Cadenza media 0.5s, scalata dagli upgrade fire-rate.
        _fireTimer = (0.5 / fireRateMultiplier).clamp(0.05, 5.0);
      case WeaponType.railgun:
        _fireRailgun(dir, damageMultiplier);
        // Colpo pesante hitscan → cadenza lenta 1.1s.
        _fireTimer = (1.1 / fireRateMultiplier).clamp(0.05, 5.0);
    }
  }

  /// Iter 14: Gauss pull rimosso (era player-centric). Il pull ora vive
  /// nell'impact-point `GaussImplosion` spawnata da `GaussBullet._explode`.

  /// Iter 13: Chain Lightning — trova fino a 5 bersagli in sequenza, ognuno
  /// nel raggio `chainRange` dal precedente. Applica damage decrescente
  /// (0.85x per jump). Spawna `ChainLightningEffect` come visual world-space.
  ///
  /// Caveman fix: pre-collect targets una volta (era 5× iterate world.children
  /// → con 200 children = 1000 walk; ora 1 walk + 5 list scan).
  void _castChainLightning(double damage) {
    const int maxJumps = 5;
    const double chainRange = 220.0;
    const double initialRange = 380.0;
    const double decay = 0.85;
    // Pre-collect potential targets (caveman fix perf).
    // Skip `isRemoved`: Flame può tenere il component morto in `children`
    // per un frame → un chain bolt non deve "jumpare" su un cadavere.
    final candidates = <PositionComponent>[];
    for (final child in game.world.children) {
      if (child.isRemoved) continue;
      if (child is EnemyBase && !child.isSpawnInvulnerable) {
        candidates.add(child);
      } else if (child is BossBase) {
        candidates.add(child);
      }
    }
    if (candidates.isEmpty) return;
    final hitTargets = <PositionComponent>{};
    final points = <Vector2>[position.clone()];
    double currentDamage = damage * 4.8;
    Vector2 currentPos = position;
    double currentRange = initialRange;

    for (int jump = 0; jump < maxJumps; jump++) {
      PositionComponent? target;
      double bestDist = currentRange;
      for (final cand in candidates) {
        if (hitTargets.contains(cand)) continue;
        final d = cand.position.distanceTo(currentPos);
        if (d < bestDist) {
          bestDist = d;
          target = cand;
        }
      }
      if (target == null) break;
      hitTargets.add(target);
      points.add(target.position.clone());
      if (target is EnemyBase) {
        target.takeDamage(currentDamage);
      } else if (target is BossBase) {
        target.takeDamage(currentDamage);
      }
      currentPos = target.position;
      currentDamage *= decay;
      currentRange = chainRange;
    }
    if (points.length >= 2) {
      final fx = ChainLightningEffect(points: points);
      game.world.add(fx);
    }
  }

  /// Shotgun: cono ravvicinato di 8 pellet arancioni. Spread ampio, velocità
  /// alta, range corto (`maxRange` 260px) → devastante da vicino, inutile da
  /// lontano. Muzzle-flash arancione per feedback "boom".
  void _spawnShotgun(Vector2 dir, double damageMultiplier) {
    const pelletCount = 8;
    final base = dir.normalized();
    for (int i = 0; i < pelletCount; i++) {
      final spread = (i - (pelletCount - 1) / 2) * 0.085;
      final rotDir = _rotateVector(base, spread);
      final pellet = PlayerBullet(
        direction: rotDir,
        weaponType: WeaponType.shotgun,
        speed: bulletSpeed * 1.35,
        damage: damageMultiplier * 0.6,
        color: NeonColors.spreadOrange,
        sizeMultiplier: hasFirePower ? 2.0 : 1.0,
        maxRange: 260,
      );
      pellet.position = position + base * 18;
      game.world.add(pellet);
    }
    game.spawnExplosion(
      position + base * 22,
      NeonColors.spreadOrange,
      radius: 26,
      particleCount: 6,
    );
  }

  /// Railgun: colpo hitscan istantaneo che perfora TUTTI i nemici/boss lungo
  /// la linea di tiro (corridoio 28px, fino a 1200px). Danno alto (pierce
  /// totale). Spawna `RailgunBeam` come visual world-space + screenshake.
  void _fireRailgun(Vector2 dir, double damageMultiplier) {
    final d = dir.normalized();
    const maxLen = 1200.0;
    const corridor = 28.0;
    final origin = position + d * 20;
    final dmg = damageMultiplier * 6.0;
    // Snapshot: takeDamage→onDeath può mutare world.children durante il loop.
    for (final child in game.world.children.toList()) {
      Vector2 cpos;
      if (child is EnemyBase) {
        if (child.isSpawnInvulnerable) continue;
        cpos = child.position;
      } else if (child is BossBase) {
        cpos = child.position;
      } else {
        continue;
      }
      final rel = cpos - origin;
      final along = rel.dot(d);
      if (along < 0 || along > maxLen) continue;
      final perp = (rel - d * along).length;
      if (perp > corridor) continue;
      if (child is EnemyBase) {
        child.takeDamage(dmg);
      } else if (child is BossBase) {
        child.takeDamage(dmg);
      }
    }
    game.world.add(
      RailgunBeam(origin: origin.clone(), direction: d, length: maxLen),
    );
    game.triggerScreenShake(5, 0.18);
  }

  void _spawnBullet(
    Vector2 dir,
    double damage,
    Color color, {
    double speed = bulletSpeed,
    int maxBounces = 0,
    Vector2? offset,
    bool pierce = false,
    WeaponType weaponType = WeaponType.basic,
  }) {
    // Modifier ricochet_world: tutti i bullet rimbalzano 5 volte (era 0-2).
    // Override `maxBounces` se attivo, indipendentemente dal weapon type.
    final effBounces = game.hasModifier('ricochet_world') ? 5 : maxBounces;
    final bullet = PlayerBullet(
      direction: dir,
      weaponType: weaponType,
      speed: speed,
      damage: damage,
      color: color,
      maxBounces: effBounces,
      pierce: pierce,
      sizeMultiplier: hasFirePower ? 2.0 : 1.0,
    );
    bullet.position = position + (offset ?? Vector2.zero());
    game.world.add(bullet);
  }

  void _spawnLaser(Vector2 dir, double damage) {
    final laser = LaserBeam(
      direction: dir,
      damage: damage * 0.5,
      sizeMultiplier: hasFirePower ? 2.0 : 1.0,
    );
    laser.position = position.clone();
    game.world.add(laser);
  }

  void _spawnPlasma(Vector2 dir, double damage) {
    final plasma = PlasmaBullet(
      direction: dir,
      damage: damage * kPlasmaDamageMultiplier,
      sizeMultiplier: hasFirePower ? 2.0 : 1.0,
    );
    plasma.position = position.clone();
    game.world.add(plasma);
  }

  /// Iter 14: spawn dedicato Gauss. Bullet con swirl visual + implosion
  /// post-impact gestita internamente dal GaussBullet stesso. Velocità
  /// ridotta (0.85x bulletSpeed) per dare tempo al player di vedere il
  /// swirl. Firepower scala size 2x come gli altri spawn.
  void _spawnGaussBullet(Vector2 dir, double damage) {
    final bullet = GaussBullet(
      direction: dir,
      damage: damage,
      speed: bulletSpeed * 0.85,
      sizeMultiplier: hasFirePower ? 2.0 : 1.0,
    );
    bullet.position = position.clone();
    game.world.add(bullet);
  }

  void _spawnHomingMissile(
    Vector2 dir,
    double damage, {
    required int volleyId,
    required Vector2 spawnAt,
  }) {
    // Damage base: damageMultiplier * 2.25 (era 1.5 → +50% richiesta utente).
    // 2.25 = 1.5 × 1.5 → i missili fanno il 50% in più rispetto al valore
    // precedente, come richiesto. AoE sempre attiva (logica nel missile).
    final missile = HomingMissile(
      direction: dir,
      damage: damage * 2.25,
      sizeMultiplier: hasFirePower ? 2.0 : 1.0,
      volleyId: volleyId,
    );
    missile.position = spawnAt.clone();
    game.world.add(missile);
  }

  void _spawnOverdriveBeam(Vector2 dir) {
    final beam = OverdriveBeam(direction: dir);
    beam.position = position.clone();
    game.world.add(beam);
  }

  Vector2 _rotateVector(Vector2 v, double angle) {
    final c = math.cos(angle);
    final s = math.sin(angle);
    return Vector2(v.x * c - v.y * s, v.x * s + v.y * c);
  }

  void _attractGeoms() {
    // L'attrazione dei geomi è gestita direttamente in Geom.update()
    // Questo metodo è mantenuto come hook per eventuali effetti visivi futuri
  }

  /// DASH talent: avvia lo scatto se sbloccato e fuori cooldown. Direzione =
  /// movimento corrente, fallback all'orientamento della nave. Concede i-frame
  /// per la durata dello scatto + un piccolo buffer (0.12s).
  void _tryDash() {
    if (!game.saveData.dashUnlocked) return;
    if (_dashCd > 0 || _dashTimer > 0) return;
    Vector2 dir = game.moveInput.clone();
    if (dir.length2 < 0.04) {
      final a = _rotation - math.pi / 2;
      dir = Vector2(math.cos(a), math.sin(a));
    }
    _dashDir = dir.normalized();
    _dashTimer = _dashDuration;
    _dashCd = game.saveData.dashCooldown;
    _invincibleTimer = math.max(_invincibleTimer, _dashDuration + 0.12);
    game.spawnExplosion(
      position,
      NeonColors.cyan,
      radius: 22,
      particleCount: 8,
    );
  }

  void takeDamage() {
    if (isInvincible) return;

    // Pacifist defensive cap (iter 6): regola GW2 = 1 vita fissa. Se per
    // qualunque path lives è stato bumped a >1 (powerup pickup non bloccato,
    // modifier edge case), normalizziamo PRIMA del decrement → primo hit
    // garantisce morte.
    if (game.isPacifistMode && lives > 1) {
      lives = 1;
    }

    if (hasShield) {
      shieldHits--;
      if (shieldHits <= 0) {
        // Reset completo dello stato scudo: shieldHits/hasShield/shieldTimer
        // devono essere sempre coerenti tra loro per evitare stati "zombie"
        // (hasShield=false ma shieldTimer>0 → un nuovo applyShield avrebbe
        // dovuto comunque sovrascrivere ma eliminiamo l'ambiguità qui).
        hasShield = false;
        shieldTimer = 0;
      }
      game.spawnExplosion(position, NeonColors.cyan, radius: 30);
      return;
    }

    // FIX race multi-hit stesso frame: più collision possono chiamare
    // takeDamage() nello stesso tick (es. due nemici sovrapposti). Impostare
    // _invincibleTimer PRIMA di decrementare lives rende la seconda chiamata
    // no-op via il guard `isInvincible` in cima → perdi 1 vita per hit, non N.
    _invincibleTimer = playerInvincibilityDuration;
    lives--;

    // Scudo post-morte dall'upgrade shop: compare solo dopo aver perso una vita
    final shieldDur = game.saveData.postDeathShieldDuration;
    if (shieldDur > 0 && lives > 0) {
      applyShield(999, duration: shieldDur);
    }

    game.onPlayerHit();

    if (lives <= 0) {
      // Phoenix pet hook: una volta per run consuma la carica e revive il
      // player ripristinando vite (formula identica a `_startRun`) + 2s di
      // invincibilità. Skip onPlayerDeath() per evitare game over.
      final pet = game.activePet;
      // Skip in zen/time-attack (già immortali): phoenix sarebbe sprecato e
      // bypasserebbe onPlayerDeath → romperebbe death-count zen / il restore.
      if (!game.isZenMode &&
          !game.isTimeAttackMode &&
          pet is PhoenixPet &&
          pet.tryConsumeRevive()) {
        lives =
            game.diffConfig.startingLives + (game.saveData.startingLives - 3);
        if (lives < 1) lives = 1;
        _invincibleTimer = 2.0;
        game.spawnExplosion(
          position,
          NeonColors.orange,
          radius: 120,
          particleCount: 30,
          epic: true,
        );
        return;
      }
      game.onPlayerDeath();
    }
  }

  void applyShield(int hits, {double duration = 60.0}) {
    hasShield = true;
    shieldHits = hits;
    shieldTimer = duration;
  }

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final paint = Paint();

    // === 1. TRAIL DI MOVIMENTO (scia luminosa dietro la nave) ===
    _renderTrail(canvas, cx, cy);

    // === 2. EFFETTO OVERDRIVE (alone arcobaleno) ===
    if (hasOverdrive) {
      _renderOverdriveAura(canvas, cx, cy);
    }

    // === 3. GLOW ESTERNO DELLA NAVE — senza blur ===
    // Colore base determinato dallo skin equipaggiato (shop). Overdrive
    // prevale con arcobaleno animato. `skinId` letto una volta e condiviso.
    final skinId = game.saveData.activeSkin;
    final skinColor = _getSkinColor();
    final baseColor = hasOverdrive ? _getRainbowColor(_energyPhase) : skinColor;
    final ghost = skinId == 'ghost';
    final glowAlpha = ghost ? 0.06 : 0.12;
    paint.color = baseColor.withValues(alpha: glowAlpha);
    paint.maskFilter = null;
    _drawShipBody(canvas, paint, 1.7);

    // === 4. THRUSTER (doppio motore con fiamme) ===
    _renderThrusters(canvas, cx, cy);

    // === 5. CORPO NAVE PRINCIPALE ===
    // Skin ghost: alpha ridotta (semi-trasparente). Stealth: fill quasi nero
    // con bordo rosso luminoso. Crystal: base bianca con leggero tint cromatico.
    paint.maskFilter = null;
    Color bodyColor = baseColor;
    if (skinId == 'ghost') {
      bodyColor = baseColor.withValues(alpha: 0.45);
    } else if (skinId == 'stealth') {
      bodyColor = const Color(0xFF0A0A0A);
    } else if (skinId == 'crystal') {
      // Tint cromatico leggero che cicla lento. `Color.lerp` su due non-null
      // è garantito non-null ma evitiamo il bang per robustezza.
      final hue = (_energyPhase * 10) % 360;
      bodyColor =
          Color.lerp(
            const Color(0xFFE8F8FF),
            HSVColor.fromAHSV(1, hue, 0.4, 1).toColor(),
            0.3,
          ) ??
          const Color(0xFFE8F8FF);
    } else if (skinId == 'voidwalker') {
      // Corpo viola scurissimo, glow viola ereditato da baseColor.
      bodyColor = const Color(0xFF14001F);
    } else if (skinId == 'tactical') {
      // Corpo acciaio scuro con tint blu — placche militari.
      bodyColor = const Color(0xFF334455);
    } else if (skinId == 'prism') {
      // Cristallo bianco-trasparente con tint colorato leggero.
      final hue = (_energyPhase * 30) % 360;
      bodyColor =
          Color.lerp(
            const Color(0xFFFFFFFF),
            HSVColor.fromAHSV(1, hue, 0.5, 1).toColor(),
            0.25,
          ) ??
          const Color(0xFFFFFFFF);
    } else if (skinId == 'aurora') {
      // Aurora: corpo brillante ma più chiaro del glow per leggibilità.
      bodyColor = baseColor.withValues(alpha: 0.85);
    } else if (skinId == 'tron') {
      // Body nero, glow ciano (baseColor) → effetto circuit.
      bodyColor = const Color(0xFF000A14);
    } else if (skinId == 'samurai') {
      // Corpo nero opaco, glow oro/rosso (baseColor + accenti).
      bodyColor = const Color(0xFF1A0A05);
    } else if (skinId == 'rosegold') {
      // Pink-gold body brillante, glow stesso colore.
      bodyColor = baseColor.withValues(alpha: 0.92);
    } else if (skinId == 'ninja') {
      // Body grigio scurissimo, glow grigio-blu sottile (baseColor).
      bodyColor = const Color(0xFF1A1F2A);
    } else if (skinId == 'glitch') {
      // Body bianco con glow RGB animato → effetto chromatic shift.
      bodyColor = const Color(0xFFEEEEEE);
    } else if (skinId == 'obsidian') {
      // Corpo nero ossidiana, glow viola ereditato da baseColor.
      bodyColor = const Color(0xFF0A0014);
    } else if (skinId == 'abyss') {
      // Corpo blu abissale scurissimo, glow ciano/blu cangiante.
      bodyColor = const Color(0xFF001022);
    }
    if (isInvincible) {
      final blink = ((_invincibleTimer * 12).toInt() % 2 == 0);
      paint.color = blink ? bodyColor : bodyColor.withValues(alpha: 0.2);
    } else {
      paint.color = bodyColor;
    }
    // Phoenix + glitch hanno render custom completo → skip lo standard
    // ship body. Match shop preview esatto.
    if (skinId != 'phoenix' && skinId != 'glitch') {
      _drawShipBody(canvas, paint, 1.0);
    }

    // Phoenix overlay completo (body central + wings + embers + glow).
    // Mirror di `_drawPhoenixShip` shop preview.
    if (skinId == 'phoenix') {
      _renderPhoenixOverlay(canvas, cx, cy);
    }
    // Glitch overlay: 3 copie body offset RGB chromatic aberration.
    // Mirror di `_drawGlitchShip` shop preview.
    if (skinId == 'glitch') {
      _renderGlitchOverlay(canvas, paint);
    }

    // Bordo rosso luminoso per stealth (si legge sulla fill quasi nera)
    if (skinId == 'stealth' && !isInvincible) {
      _drawShipBody(canvas, _stealthEdgePaint, 1.0);
    }

    // === 6. DETTAGLI INTERNI (cockpit, linee strutturali) ===
    _renderShipDetails(canvas, cx, cy, baseColor);

    // === 7. WING-TIP LIGHTS (luci sulle punte delle ali) ===
    _renderWingLights(canvas, cx, cy);

    // === 8. SCUDO FORCE FIELD ===
    if (hasShield) {
      _renderShield(canvas, cx, cy);
    }
  }

  static final _trailPaint = Paint();
  static final _detailPaint = Paint();
  static final _stealthEdgePaint = Paint()
    ..color = const Color(0xFFFF2244).withValues(alpha: 0.9)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.2;

  /// Scia luminosa dietro la nave durante il movimento.
  /// Colore deriva dal trail equipaggiato nello shop (activeTrail):
  /// normal=cyan, fire=arancio, ice=azzurro, plasma=viola, rainbow=HSV ciclico.
  // Trail size multiplier — iter 6 (utente "i trails devono essere grandi
  // la metà"): 2.0 → 1.0. Halve size, alpha boost preservato.
  static const double _trailSizeMultiplier = 1.0;

  void _renderTrail(Canvas canvas, double cx, double cy) {
    if (_trail.isEmpty) return;
    for (int i = 0; i < _trail.length; i++) {
      // Alpha curva sqrt → testa scia molto brillante, coda fade graduale
      // (più organico del lineare). Iter 6: multi-layer + sparkle.
      final t = (i / _maxTrailLength).clamp(0.0, 1.0);
      final fade = 1.0 - t;
      final alpha = (fade * fade * 0.95 + fade * 0.05).clamp(0.0, 0.95);
      final trailSize = fade * 3.5 * _trailSizeMultiplier;
      final offset = _trail[i] - position;
      final color = hasOverdrive
          ? _getRainbowColor(_energyPhase + i * 0.3)
          : _getTrailColor(i);
      final tx = cx + offset.x;
      final ty = cy + offset.y;

      // Layer 1: glow esterno ampio.
      _trailPaint.color = color.withValues(alpha: alpha * 0.5);
      _trailPaint.maskFilter = null;
      canvas.drawCircle(Offset(tx, ty), trailSize * 2.4, _trailPaint);
      // Layer 2: body principale.
      _trailPaint.color = color.withValues(alpha: alpha);
      canvas.drawCircle(Offset(tx, ty), trailSize * 1.1, _trailPaint);
      // Layer 3: nucleo bianco (solo testa scia, fade rapido).
      if (t < 0.5) {
        _trailPaint.color = const Color(
          0xFFFFFFFF,
        ).withValues(alpha: alpha * (0.6 - t));
        canvas.drawCircle(Offset(tx, ty), trailSize * 0.45, _trailPaint);
      }
      // Sparkle: dot offset deterministico via `_energyPhase` (monotonic
      // clock — `_trailTimer` veniva resettato a 0 ad ogni insert in update,
      // che dava sparkle scattering invece di rotazione fluida).
      if (i % 3 == 0 && fade > 0.25) {
        final sparkAng = _energyPhase * 4 + i * 1.3;
        final sx = tx + math.cos(sparkAng) * trailSize * 0.8;
        final sy = ty + math.sin(sparkAng) * trailSize * 0.8;
        _trailPaint.color = const Color(
          0xFFFFFFFF,
        ).withValues(alpha: alpha * 0.7);
        canvas.drawCircle(Offset(sx, sy), 1.2, _trailPaint);
      }
    }
  }

  /// Colore skin equipaggiato (shop). Overdrive prevale (arcobaleno).
  Color _getSkinColor() {
    switch (game.saveData.activeSkin) {
      case 'stealth':
        return const Color(0xFFFF2244);
      case 'crystal':
        // Crystal: ciclo cromatico lento → riflessi arcobaleno.
        // Cache su step di 5° → ricomputo ~72 volte/ciclo invece di 60 fps.
        final step = ((_energyPhase * 20) / 5).floor() % 72;
        if (_crystalCachedSkin != 'crystal') {
          _crystalColorCache = null;
        }
        if (_crystalHueStep != step || _crystalColorCache == null) {
          _crystalHueStep = step;
          _crystalColorCache = HSVColor.fromAHSV(
            1,
            step * 5.0,
            0.5,
            1,
          ).toColor();
          _crystalCachedSkin = 'crystal';
        }
        return _crystalColorCache!;
      case 'ghost':
        return const Color(0xFF8888CC);
      case 'omega':
        return const Color(0xFFFFD700);
      case 'phoenix':
        return const Color(0xFFFF5500);
      case 'cyber':
        return const Color(0xFF00FF66);
      case 'voidwalker':
        return const Color(0xFFAA44FF);
      case 'aurora':
        // Cycle ciano→rosa→verde, simile a crystal ma più saturato.
        final step = ((_energyPhase * 25) / 5).floor() % 72;
        if (_crystalCachedSkin != 'aurora') {
          _crystalColorCache = null;
        }
        if (_crystalHueStep != step || _crystalColorCache == null) {
          _crystalHueStep = step;
          _crystalColorCache = HSVColor.fromAHSV(
            1,
            (step * 5.0 + 120) % 360,
            0.7,
            1,
          ).toColor();
          _crystalCachedSkin = 'aurora';
        }
        return _crystalColorCache!;
      case 'tactical':
        return const Color(0xFF6688AA);
      // ─── NEW SKINS (iter 7) ──────────────────────────────────────
      case 'tron':
        // Bright cyan circuit lines su body nero.
        return const Color(0xFF00DDFF);
      case 'samurai':
        // Oro con accenti rossi.
        return const Color(0xFFFFAA00);
      case 'rosegold':
        // Pink/gold metallico.
        return const Color(0xFFFFAACC);
      case 'ninja':
        // Dark grey con bordi sottili.
        return const Color(0xFF445566);
      case 'glitch':
        // RGB shift animato — chromatic aberration glitchy.
        final gphase = (_energyPhase * 8).floor() % 3;
        if (gphase == 0) return const Color(0xFFFF0066);
        if (gphase == 1) return const Color(0xFF00FF66);
        return const Color(0xFF0066FF);
      case 'prism':
        // Rotazione hue veloce → bianco apparente con flash colorati.
        final step = ((_energyPhase * 40) / 5).floor() % 72;
        if (_crystalCachedSkin != 'prism') {
          _crystalColorCache = null;
        }
        if (_crystalHueStep != step || _crystalColorCache == null) {
          _crystalHueStep = step;
          _crystalColorCache = HSVColor.fromAHSV(
            1,
            step * 5.0,
            0.6,
            1,
          ).toColor();
          _crystalCachedSkin = 'prism';
        }
        return _crystalColorCache!;
      // ─── NEW SKINS (iter 22 — richiesta utente: +10 skin) ──────────────
      case 'magma':
        return const Color(0xFFFF5522);
      case 'frost':
        return const Color(0xFF99E6FF);
      case 'toxic':
        return const Color(0xFF88FF00);
      case 'obsidian':
        return const Color(0xFF9944FF);
      case 'solar':
        return const Color(0xFFFFCC00);
      case 'chrome':
        return const Color(0xFFCCDDEE);
      case 'emerald':
        return const Color(0xFF22FFAA);
      case 'abyss':
        // Cangiante blu↔ciano (oscilla nella banda ~165-225°).
        final step = ((_energyPhase * 15) / 5).floor() % 96;
        if (_crystalCachedSkin != 'abyss') _crystalColorCache = null;
        if (_crystalHueStep != step || _crystalColorCache == null) {
          _crystalHueStep = step;
          _crystalColorCache = HSVColor.fromAHSV(
            1,
            195 + math.sin(step * 0.13) * 30,
            0.85,
            1,
          ).toColor();
          _crystalCachedSkin = 'abyss';
        }
        return _crystalColorCache!;
      case 'cosmos':
        // Nebulosa viola↔rosa (oscilla ~260-330°).
        final step = ((_energyPhase * 16) / 5).floor() % 96;
        if (_crystalCachedSkin != 'cosmos') _crystalColorCache = null;
        if (_crystalHueStep != step || _crystalColorCache == null) {
          _crystalHueStep = step;
          _crystalColorCache = HSVColor.fromAHSV(
            1,
            (295 + math.sin(step * 0.13) * 35) % 360,
            0.7,
            1,
          ).toColor();
          _crystalCachedSkin = 'cosmos';
        }
        return _crystalColorCache!;
      case 'sunset':
        // Tramonto arancio↔magenta (oscilla attorno al rosso).
        final step = ((_energyPhase * 14) / 5).floor() % 96;
        if (_crystalCachedSkin != 'sunset') _crystalColorCache = null;
        if (_crystalHueStep != step || _crystalColorCache == null) {
          _crystalHueStep = step;
          _crystalColorCache = HSVColor.fromAHSV(
            1,
            (350 + math.sin(step * 0.13) * 40 + 360) % 360,
            0.85,
            1,
          ).toColor();
          _crystalCachedSkin = 'sunset';
        }
        return _crystalColorCache!;
      case 'classic':
      default:
        return NeonColors.cyan;
    }
  }

  /// Colore scia equipaggiata (shop).
  Color _getTrailColor(int index) {
    switch (game.saveData.activeTrail) {
      case 'fire':
        // Gradiente rosso→giallo lungo la scia
        final t = (index / _maxTrailLength).clamp(0.0, 1.0);
        return Color.lerp(const Color(0xFFFFDD00), const Color(0xFFFF2200), t)!;
      case 'ice':
        return const Color(0xFF88DDFF);
      case 'plasma':
        return const Color(0xFFCC00FF);
      case 'rainbow':
        return HSVColor.fromAHSV(
          1,
          ((_energyPhase * 60) + index * 25) % 360,
          1,
          1,
        ).toColor();
      case 'comet':
        // Testa bianca (vicino nave), coda arancio → nero.
        if (index < 3) return const Color(0xFFFFFFFF);
        final t = (index / _maxTrailLength).clamp(0.0, 1.0);
        return Color.lerp(const Color(0xFFFFCC66), const Color(0xFF441100), t)!;
      case 'inferno':
        // 3 layer fuoco alternati: rosso/arancio/giallo.
        final layer = index % 3;
        final hue = layer == 0 ? 0.0 : (layer == 1 ? 25.0 : 50.0);
        return HSVColor.fromAHSV(1, hue, 1, 1).toColor();
      case 'void':
        // Particelle scure + sparkle viola brillante ogni 5.
        return index % 5 == 0
            ? const Color(0xFFEE88FF)
            : const Color(0xFF330055);
      case 'quantum':
        // Coppie cyan/magenta alternate.
        return (index ~/ 2) % 2 == 0
            ? const Color(0xFF00FFCC)
            : const Color(0xFFFF00CC);
      case 'galaxy':
        // Hue shift cosmico viola→rosa.
        final ghue = (240 + index * 6) % 360;
        return HSVColor.fromAHSV(1, ghue.toDouble(), 0.6, 1).toColor();
      case 'lightning':
        return const Color(0xFFFFFF88);
      // ─── NEW TRAILS (iter 7) ──────────────────────────────────────
      case 'nebula':
        // Cloud cyan/magenta blend morbido — modulazione sinusoidale.
        final tn = (math.sin(_energyPhase * 1.5 + index * 0.4) * 0.5 + 0.5);
        return Color.lerp(
          const Color(0xFF00DDFF),
          const Color(0xFFFF44CC),
          tn,
        )!;
      case 'prism':
        // Spettro completo lento, colori saturi ben separati.
        final phue = ((_energyPhase * 30) + index * 18) % 360;
        return HSVColor.fromAHSV(1, phue.toDouble(), 0.95, 1).toColor();
      case 'hologram':
        // Chromatic aberration: alterna RGB tra punti scia.
        final ch = index % 3;
        if (ch == 0) return const Color(0xFFFF2244); // R
        if (ch == 1) return const Color(0xFF22FFAA); // G
        return const Color(0xFF2244FF); // B
      case 'biolume':
        // Bioluminescenza: ciano/verde con pulse.
        final pulse = (math.sin(_energyPhase * 3 + index * 0.6) * 0.4 + 0.6)
            .clamp(0.4, 1.0);
        return HSVColor.fromAHSV(
          pulse,
          160 + (index % 3) * 10.0,
          0.9,
          1,
        ).toColor();
      case 'neonpulse':
        // Anelli neon expanding: cyan-bianco con pulse rapido.
        final tp = (math.sin(_energyPhase * 5 + index * 0.5) * 0.5 + 0.5);
        return Color.lerp(
          const Color(0xFF00FFFF),
          const Color(0xFFFFFFFF),
          tp,
        )!;
      // ─── NEW TRAILS (iter 22 — richiesta utente: +10 trail) ────────────
      case 'ember':
        final t = (index / _maxTrailLength).clamp(0.0, 1.0);
        return Color.lerp(const Color(0xFFFF8800), const Color(0xFF991100), t)!;
      case 'frostbite':
        return const Color(0xFFAAEEFF);
      case 'venom':
        final t = (math.sin(_energyPhase * 5 + index * 0.4) * 0.5 + 0.5);
        return Color.lerp(const Color(0xFF55CC00), const Color(0xFFAAFF33), t)!;
      case 'shadow':
        return index % 4 == 0
            ? const Color(0xFFCC66FF)
            : const Color(0xFF220033);
      case 'solarflare':
        final t = (index / _maxTrailLength).clamp(0.0, 1.0);
        return Color.lerp(const Color(0xFFFFFFFF), const Color(0xFFFFAA00), t)!;
      case 'oceanic':
        final h = (190 + index * 5) % 360;
        return HSVColor.fromAHSV(1, h.toDouble(), 0.8, 1).toColor();
      case 'starfield':
        return index % 4 == 0
            ? const Color(0xFFFFFFFF)
            : const Color(0xFF223366);
      case 'chromatic':
        final h = ((_energyPhase * 120) + index * 30) % 360;
        return HSVColor.fromAHSV(1, h, 1, 1).toColor();
      case 'jade':
        return const Color(0xFF33FFAA);
      case 'dusk':
        final t = (index / _maxTrailLength).clamp(0.0, 1.0);
        return Color.lerp(const Color(0xFFFF8844), const Color(0xFFFF2299), t)!;
      case 'normal':
      default:
        return NeonColors.cyan;
    }
  }

  static final _auraPaint = Paint();

  /// Alone arcobaleno attorno alla nave durante overdrive — senza blur
  void _renderOverdriveAura(Canvas canvas, double cx, double cy) {
    for (int i = 0; i < 3; i++) {
      final hue = ((_energyPhase * 60 + i * 120) % 360);
      final color = HSVColor.fromAHSV(0.08 - i * 0.02, hue, 1, 1).toColor();
      _auraPaint.color = color;
      _auraPaint.maskFilter = null;
      canvas.drawCircle(Offset(cx, cy), 30 + i * 8.0, _auraPaint);
    }
  }

  /// Doppi thruster con fiamma animata e particelle
  void _renderThrusters(Canvas canvas, double cx, double cy) {
    final moveDir = game.moveInput;
    final isMoving = moveDir.length2 > 0.01;
    final flameLength = isMoving
        ? 10 + math.sin(_thrusterPhase) * 4
        : 4 + math.sin(_thrusterPhase * 0.5) * 1;
    final flameWidth = isMoving ? 4.0 : 2.0;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(_rotation);

    // Thruster sinistro
    _drawFlame(canvas, -5, 13, flameLength, flameWidth);
    // Thruster destro
    _drawFlame(canvas, 5, 13, flameLength, flameWidth);

    canvas.restore();
  }

  static final _flameCorePaint = Paint();
  static final _flameInnerPaint = Paint();
  static final _flameOuterPaint = Paint();

  /// Disegna una fiamma singola del thruster — senza blur
  void _drawFlame(
    Canvas canvas,
    double x,
    double y,
    double length,
    double width,
  ) {
    // Fiamma esterna (rosso/viola glow) — cerchio più grande, no blur
    _flameOuterPaint.color = const Color(0xFFFF2200).withValues(alpha: 0.15);
    _flameOuterPaint.maskFilter = null;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(x, y + length * 0.6),
        width: width * 2.2,
        height: length * 1.3,
      ),
      _flameOuterPaint,
    );

    // Fiamma interna (arancione brillante)
    _flameInnerPaint.color = const Color(0xFFFF6600).withValues(alpha: 0.7);
    _flameInnerPaint.maskFilter = null;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(x, y + length * 0.5),
        width: width,
        height: length * 0.7,
      ),
      _flameInnerPaint,
    );

    // Core bianco (centro fiamma)
    _flameCorePaint.color = const Color(0xFFFFFFFF).withValues(alpha: 0.9);
    _flameCorePaint.maskFilter = null;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(x, y + length * 0.3),
        width: width * 0.6,
        height: length * 0.5,
      ),
      _flameCorePaint,
    );
  }

  /// Dettagli interni della nave: cockpit luminoso e linee strutturali
  void _renderShipDetails(
    Canvas canvas,
    double cx,
    double cy,
    Color baseColor,
  ) {
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(_rotation);

    // Cockpit (cerchio luminoso al centro-alto della nave) — senza blur
    final cockpitGlow = 0.6 + math.sin(_energyPhase * 2) * 0.2;
    _detailPaint.color = const Color(
      0xFFFFFFFF,
    ).withValues(alpha: cockpitGlow * 0.5);
    _detailPaint.maskFilter = null;
    _detailPaint.style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(0, -4), 5, _detailPaint);
    _detailPaint.color = const Color(0xFFFFFFFF).withValues(alpha: cockpitGlow);
    canvas.drawCircle(const Offset(0, -4), 3, _detailPaint);
    _detailPaint.color = baseColor.withValues(alpha: 0.9);
    canvas.drawCircle(const Offset(0, -4), 2, _detailPaint);

    // Linee strutturali sulle ali
    _detailPaint.color = baseColor.withValues(alpha: 0.3);
    _detailPaint.strokeWidth = 0.5;
    _detailPaint.style = PaintingStyle.stroke;
    // Linea ala sinistra
    canvas.drawLine(const Offset(-2, 0), const Offset(-10, 10), _detailPaint);
    // Linea ala destra
    canvas.drawLine(const Offset(2, 0), const Offset(10, 10), _detailPaint);
    // Linea centrale
    canvas.drawLine(const Offset(0, -8), const Offset(0, 8), _detailPaint);

    canvas.restore();
  }

  static final _wingPaint = Paint();

  /// Luci sulle punte delle ali che pulsano — senza blur
  void _renderWingLights(Canvas canvas, double cx, double cy) {
    final pulse = 0.5 + math.sin(_wingPulse) * 0.5;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(_rotation);

    // Luce ala sinistra (rossa) — glow + core
    _wingPaint.maskFilter = null;
    _wingPaint.color = Color.fromRGBO(255, 50, 50, pulse * 0.3);
    canvas.drawCircle(const Offset(-12, 10), 4, _wingPaint);
    _wingPaint.color = Color.fromRGBO(255, 50, 50, pulse * 0.8);
    canvas.drawCircle(const Offset(-12, 10), 2, _wingPaint);

    // Luce ala destra (verde) — glow + core
    _wingPaint.color = Color.fromRGBO(50, 255, 100, pulse * 0.3);
    canvas.drawCircle(const Offset(12, 10), 4, _wingPaint);
    _wingPaint.color = Color.fromRGBO(50, 255, 100, pulse * 0.8);
    canvas.drawCircle(const Offset(12, 10), 2, _wingPaint);

    canvas.restore();
  }

  static final _shieldPaint = Paint();

  /// Scudo esagonale force field con animazione — senza blur
  void _renderShield(Canvas canvas, double cx, double cy) {
    final shieldAlpha = 0.2 + math.sin(_shieldPhase * 2) * 0.1;

    // Glow esterno — esagono più grande, alpha ridotta, no blur
    _shieldPaint.color = NeonColors.cyan.withValues(alpha: shieldAlpha * 0.25);
    _shieldPaint.style = PaintingStyle.fill;
    _shieldPaint.strokeWidth = 0;
    _shieldPaint.maskFilter = null;
    _drawHexagonAt(canvas, cx, cy, 28, _shieldPaint);

    // Bordo esagonale principale
    _shieldPaint.color = NeonColors.cyan.withValues(alpha: shieldAlpha + 0.2);
    _shieldPaint.style = PaintingStyle.stroke;
    _shieldPaint.strokeWidth = 1.5;
    _drawHexagonAt(canvas, cx, cy, 22, _shieldPaint);

    // Secondo esagono interno (ruotato)
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(_shieldPhase * 0.3);
    _shieldPaint.color = NeonColors.cyan.withValues(alpha: shieldAlpha * 0.4);
    _shieldPaint.strokeWidth = 0.5;
    _drawHexagonAt(canvas, 0, 0, 18, _shieldPaint);
    canvas.restore();

    // Punti energetici sui vertici — senza blur
    _shieldPaint.style = PaintingStyle.fill;
    for (int i = 0; i < 6; i++) {
      final angle = i * math.pi / 3 - math.pi / 6;
      final px = cx + 22 * math.cos(angle);
      final py = cy + 22 * math.sin(angle);
      final dotAlpha = 0.3 + math.sin(_shieldPhase * 3 + i) * 0.3;
      _shieldPaint.color = NeonColors.cyan.withValues(alpha: dotAlpha * 0.5);
      canvas.drawCircle(Offset(px, py), 3, _shieldPaint);
      _shieldPaint.color = NeonColors.cyan.withValues(alpha: dotAlpha);
      canvas.drawCircle(Offset(px, py), 1.5, _shieldPaint);
    }
  }

  // Path cache: ricostruiti solo se `scale` o skin cambia. Il player viene
  // renderizzato 3 volte per frame (glow + body + stealth-edge) → 3 alloc
  // Path × 60fps = 180 Path/sec evitate.
  double _cachedPathScale = -1;
  bool _cachedPathOmega = false;
  Path? _cachedShipPath;

  /// Phoenix overlay: ali infuocate + ember orbitanti, mirror dello
  /// `_drawPhoenixShip` dello shop preview. Renderizzato SOPRA al body
  /// standard per dare il "wings of fire" look promesso nello shop.
  ///
  /// Usa Paint() locali (non shared) → render path raro (skin-specifico)
  /// e i Paint sono leggeri.
  static final Paint _phoenixWingFill = Paint();
  static final Paint _phoenixWingStroke = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;
  static final Paint _phoenixEmber = Paint();
  // Glow con blur — match shop preview (`_gGlowBlur`).
  static final Paint _phoenixGlow = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

  void _renderPhoenixOverlay(Canvas canvas, double cx, double cy) {
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(_rotation);
    final wingPhase = math.sin(_energyPhase * 3) * 0.3 + 1.0;

    // Glow esterno fuoco arancione (blurred per match shop preview)
    _phoenixGlow.color = const Color(0xFFFF8800).withValues(alpha: 0.3);
    canvas.drawCircle(Offset.zero, 24 * wingPhase, _phoenixGlow);

    // Ali sinistra/destra (forma piuma con quadratic bezier)
    for (final side in [-1.0, 1.0]) {
      final wing = Path()
        ..moveTo(0, -10)
        ..quadraticBezierTo(side * 18 * wingPhase, -8, side * 22 * wingPhase, 4)
        ..quadraticBezierTo(side * 16 * wingPhase, 6, side * 8, 8)
        ..lineTo(0, 4)
        ..close();
      _phoenixWingFill.color = const Color(0xFFFF2200).withValues(alpha: 0.7);
      canvas.drawPath(wing, _phoenixWingFill);
      _phoenixWingStroke.color = const Color(0xFFFF8800).withValues(alpha: 0.5);
      canvas.drawPath(wing, _phoenixWingStroke);
    }

    // Body central dorato/rosso — mirror del body in `_drawPhoenixShip`
    // (shop_screen). Standalone (no fallback al ship body standard).
    final body = Path()
      ..moveTo(0, -16)
      ..lineTo(4, -2)
      ..lineTo(3, 10)
      ..lineTo(-3, 10)
      ..lineTo(-4, -2)
      ..close();
    _phoenixWingFill.color = const Color(0xFFFF5500);
    canvas.drawPath(body, _phoenixWingFill);
    _phoenixWingStroke.color = const Color(0xFFFFDD00).withValues(alpha: 0.8);
    canvas.drawPath(body, _phoenixWingStroke);

    // Embers orbitanti
    for (int i = 0; i < 8; i++) {
      final ang = i * math.pi / 4 + _energyPhase * 0.8;
      final dist = 18 + math.sin(_energyPhase * 2 + i) * 4;
      final ex = math.cos(ang) * dist;
      final ey = math.sin(ang) * dist;
      final emberPulse = (math.sin(_energyPhase * 4 + i) * 0.3 + 0.7).clamp(
        0.2,
        1.0,
      );
      _phoenixEmber.color = const Color(
        0xFFFFCC44,
      ).withValues(alpha: emberPulse);
      canvas.drawCircle(Offset(ex, ey), 1.4, _phoenixEmber);
    }

    canvas.restore();
  }

  /// Glitch overlay: 3 copie ship offset RGB. Mirror di `_drawGlitchShip`
  /// shop preview.
  static final Paint _glitchPaint = Paint();

  void _renderGlitchOverlay(Canvas canvas, Paint paint) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final glitchPhase = (_energyPhase * 8) % 1.0;
    final shift = (glitchPhase < 0.1) ? 3.0 : 1.5;

    // R copy left
    canvas.save();
    canvas.translate(-shift, 0);
    _glitchPaint.color = const Color(0xFFFF0066).withValues(alpha: 0.7);
    _drawShipBody(canvas, _glitchPaint, 1.0);
    canvas.restore();
    // Reset translate via additional save (Flame _drawShipBody handles its own)

    canvas.save();
    canvas.translate(shift, 0);
    _glitchPaint.color = const Color(0xFF00FF66).withValues(alpha: 0.7);
    _drawShipBody(canvas, _glitchPaint, 1.0);
    canvas.restore();

    // B body central
    _glitchPaint.color = const Color(0xFF0066FF).withValues(alpha: 0.85);
    _drawShipBody(canvas, _glitchPaint, 1.0);

    // Bordo bianco
    final stroke = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;
    _drawShipBody(canvas, stroke, 1.0);

    // Glitch scanline orizzontale random
    if (glitchPhase < 0.15) {
      final glitchY = (_energyPhase * 40) % 26 - 13;
      _glitchPaint.color = const Color(0xFFFFFFFF).withValues(alpha: 0.6);
      canvas.drawRect(
        Rect.fromLTWH(cx - 12, cy + glitchY, 24, 1.5),
        _glitchPaint,
      );
    }
  }

  /// Disegna il corpo della nave: forma a freccia dettagliata con ali.
  /// Omega skin usa una stella a 4 punte (forma unica descritta nello shop).
  void _drawShipBody(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(_rotation);

    final s = scale;
    final isOmega = game.saveData.activeSkin == 'omega';
    if (_cachedPathScale != s ||
        _cachedPathOmega != isOmega ||
        _cachedShipPath == null) {
      _cachedPathScale = s;
      _cachedPathOmega = isOmega;
      if (isOmega) {
        // Stella a 4 punte — punta lunga in avanti/dietro, punte corte ai lati
        _cachedShipPath = Path()
          ..moveTo(0, -15 * s)
          ..lineTo(4 * s, -3 * s)
          ..lineTo(13 * s, 0)
          ..lineTo(4 * s, 3 * s)
          ..lineTo(0, 15 * s)
          ..lineTo(-4 * s, 3 * s)
          ..lineTo(-13 * s, 0)
          ..lineTo(-4 * s, -3 * s)
          ..close();
      } else {
        // Forma nave standard: punta affilata in alto, ali laterali, coda
        _cachedShipPath = Path()
          ..moveTo(0, -14 * s)
          ..lineTo(4 * s, -6 * s)
          ..lineTo(13 * s, 10 * s)
          ..lineTo(8 * s, 8 * s)
          ..lineTo(5 * s, 14 * s)
          ..lineTo(0, 10 * s)
          ..lineTo(-5 * s, 14 * s)
          ..lineTo(-8 * s, 8 * s)
          ..lineTo(-13 * s, 10 * s)
          ..lineTo(-4 * s, -6 * s)
          ..close();
      }
    }
    canvas.drawPath(_cachedShipPath!, paint);

    canvas.restore();
  }

  // Cached hexagon paths keyed by radius to avoid per-frame Path allocations
  // in _renderShield (called 3× per frame when shield is active).
  // The hexagon shape is purely a function of radius; cx/cy are applied via
  // canvas.translate at the call site so origin-relative paths can be reused.
  final Map<double, Path> _hexPathCache = {};

  /// Esagono a posizione arbitraria
  void _drawHexagonAt(
    Canvas canvas,
    double cx,
    double cy,
    double radius,
    Paint paint,
  ) {
    Path? path = _hexPathCache[radius];
    if (path == null) {
      path = Path();
      for (int i = 0; i < 6; i++) {
        final angle = i * math.pi / 3 - math.pi / 6;
        if (i == 0) {
          path.moveTo(radius * math.cos(angle), radius * math.sin(angle));
        } else {
          path.lineTo(radius * math.cos(angle), radius * math.sin(angle));
        }
      }
      path.close();
      _hexPathCache[radius] = path;
    }
    canvas.save();
    canvas.translate(cx, cy);
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  /// Colore arcobaleno per overdrive
  Color _getRainbowColor(double phase) {
    final hue = (phase * 60) % 360;
    return HSVColor.fromAHSV(1.0, hue, 1.0, 1.0).toColor();
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    if (other is EnemyBase) {
      // GW:RE2: nemici in materializzazione sono incorporei — non danneggiano il player
      if (other.isSpawnInvulnerable) return;
      // Alcuni nemici non danneggiano al contatto (es. Leech: si aggancia e
      // rallenta invece di uccidere).
      if (!other.damagesPlayerOnContact) return;
      takeDamage();
    }
    super.onCollisionStart(intersectionPoints, other);
  }
}

import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import '../../../data/constants.dart';
import '../../game_world.dart';
import 'enemy_base.dart';
import '../bosses/boss_base.dart';
import '../projectiles.dart';

/// GATE - Due sfere connesse da una linea luminosa (stile Geometry Wars).
/// Il player NON può sparare ai Gate, ma può ATTRAVERSARLI.
/// Quando il player ci passa in mezzo, il Gate ESPLODE uccidendo tutti i nemici vicini.
/// Meccanica iconica di GW: Pacifism mode, risk/reward strategico.
///
/// Forma: due sfere (~30px distanza) + linea neon tra loro
/// Colore endpoint: arancio fosforescente (#FF6600), filo: bianco (#FFFFFF)
/// HP: infiniti (non danneggiabili dai proiettili)
/// Meccanica: si muove lentamente in una direzione, rimbalza sui muri.
///            Quando il player passa tra le due sfere, BOOM! Uccide tutto nel raggio.
///            I proiettili player vengono riflessi al contatto.
class GateEnemy extends PositionComponent
    with HasGameReference<GeometryFightGame>, CollisionCallbacks {
  double _phase = 0;
  late Vector2 _moveDir;
  // Target direction: si aggiorna istantaneamente al wall hit, _moveDir lerp
  // verso questo per simulare turn fisico di un grosso oggetto (no snap 180°).
  late Vector2 _targetDir;
  final double _speed = 60;
  // +50% iter 2 (richiesta utente "bilanciere 50% più grande"): era 75 →
  // ora 112.5. Bilanciere ancora più grande/leggibile + hitbox riallineati
  // al visivo (vedi onLoad e sphere/wire kill radius doc sotto).
  final double _gateWidth = 112.5;
  // Esplosione iter 6: -30% rispetto a iter 4 (richiesta utente "troppo
  // grande"). 182.25 × 0.7 = 127.575. Kill effettivo ≈ 191 px base,
  // ~478 px con combo Pacifism max (×2.5 AoE multiplier).
  final double _explosionRadius = 127.575;
  final Color neonColor = const Color(0xFFFF6600);

  // Endpoint kill radius: distanza player-sfera-centro che uccide il player.
  // OLD: 27 (≈3× visual sphere r=9 → death zone "invisibile" troppo ampia,
  //      utente percepiva "hitbox imperfetta delle estremità").
  // NEW: visual sphere r (14) + player hurtbox (8) = 22 → fair death zone
  //      che combacia col contorno visivo della sfera arancio.
  static const double _endpointKillRadius = 22.0;
  // Wire kill radius: distanza player-segmento per trigger esplosione gate.
  // Wire visual half-thickness (glow 13.5/2 ≈ 7) + player hurtbox 8 = 15.
  // Mantenuto a 15 perché coincide con la half-thickness del glow stroke +50%.
  static const double _wireKillRadius = 15.0;
  // Wire REFLECT radius (richiesta utente): distanza bullet→segmento entro cui
  // la LINEA bianca riflette i proiettili e blocca i missili Homing — prima
  // solo le sfere endpoint lo facevano. ≈ wire half-glow (8) + bullet r (3) +
  // 3 buffer = 14.
  static const double _wireReflectRadius = 14.0;
  // Visual sphere radius (cerchio arancio fluo). +50% iter 2: era 9 → 14.
  static const double _sphereVisualR = 14.0;
  // Sphere hitbox radius (per bullet reflect): visual r + small buffer per
  // non perdere riflessioni vicine al bordo visivo. OLD 15 (>>visual=9 → hitbox
  // 67% più grande del visivo, riflessi "magici" oltre il contorno). NEW 16
  // (visual+2). Hitbox quasi allineata al cerchio arancio = riflessione visuale
  // accurata. Risolve "hitbox imperfetta" segnalata dall'utente.
  static const double _sphereHitboxR = 16.0;

  // Cooldown anti-spam: impedisce trigger multipli ravvicinati
  double _cooldown = 4.0;
  // Gate non despawnano mai per timer (richiesta utente: "I gate non devono
  // mai despawnare in nessuna modalità"). L'unico despawn è via player
  // crossing → `_triggerExplosion` → `removeFromParent`. Tunnel mode:
  // despawn solo se dietro la camera (vedi update()).

  // Size component bbox +66% iter 2 (era 90×90 → 150×150). Necessario per
  // contenere _gateWidth=112.5 + 2×sphere visual r=14 = 140.5 con margine.
  // 150 dà ~9px buffer per pulse FX delle sfere.
  // Static RNG shared across all GateEnemy instances — avoids per-instance alloc.
  static final math.Random _rng = math.Random();

  GateEnemy() : super(size: Vector2(150, 150), anchor: Anchor.center) {
    final angle = _rng.nextDouble() * math.pi * 2;
    _moveDir = Vector2(math.cos(angle), math.sin(angle));
    _targetDir = _moveDir.clone();
  }

  // Hitbox solo sulle due sfere endpoint per reflect proiettili.
  // Il contatto player vs gate è gestito manualmente in update() con distanze
  // punto-segmento, così da distinguere endpoint (kill player) vs wire (kill gate).
  late CircleHitbox _sphereHitbox1;
  late CircleHitbox _sphereHitbox2;
  bool _exploded = false;

  @override
  Future<void> onLoad() async {
    // Hitbox sphere allineato a visual+2 buffer (vedi _sphereHitboxR doc).
    _sphereHitbox1 = CircleHitbox(radius: _sphereHitboxR, anchor: Anchor.center)
      ..position = size / 2;
    _sphereHitbox2 = CircleHitbox(radius: _sphereHitboxR, anchor: Anchor.center)
      ..position = size / 2;
    add(_sphereHitbox1);
    add(_sphereHitbox2);
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is PlayerBullet) {
      other.reflect();
    } else if (other is HomingMissile) {
      // Le sfere bloccano anche i missili Homing (richiesta utente).
      other.blockAtGate();
    }
  }

  /// Distanza punto-segmento (per check attraversamento wire).
  double _pointToSegmentDistance(Vector2 p, Vector2 a, Vector2 b) {
    final ab = b - a;
    final lenSq = ab.length2;
    if (lenSq < 1e-6) return p.distanceTo(a);
    final ap = p - a;
    final t = (ap.dot(ab) / lenSq).clamp(0.0, 1.0);
    final projection = a + ab * t;
    return p.distanceTo(projection);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _phase += dt * 4;
    if (_cooldown > 0) _cooldown -= dt;
    // Lifetime timer rimosso (richiesta utente). Gate persiste fino a
    // crossing player o despawn off-camera (tunnel mode).

    // Movimento
    position += _moveDir * _speed * dt;

    // Rimbalzo sui muri (smooth turn — iter 4).
    // _targetDir si flippa istantaneamente al hit, _moveDir lerp verso target
    // a rate ~5/s → turn naturale ~0.4s invece di snap 180°. Posizione clamp
    // mantenuta: durante turn il gate è "spinto" contro il muro mentre ruota.
    // Buffer = halfWidth (56.25) + sphere visual r (14) = 70.25, round up 71.
    const double kBounceBuffer = 71.0;
    if (game.isTunnelMode) {
      final camY = game.camera.viewfinder.position.y;
      final halfH = game.tunnelHeight / 2;
      // Flip target solo se ancora puntato VERSO il muro (evita ri-flip
      // continuo mentre gate ancora dentro buffer durante turn).
      if (position.y <= camY - halfH + kBounceBuffer && _targetDir.y < 0) {
        _targetDir.y = -_targetDir.y;
      } else if (position.y >= camY + halfH - kBounceBuffer &&
          _targetDir.y > 0) {
        _targetDir.y = -_targetDir.y;
      }
      position.y = position.y.clamp(
        camY - halfH + kBounceBuffer,
        camY + halfH - kBounceBuffer,
      );
      // Despawn se dietro la camera
      final cameraLeft =
          game.camera.viewfinder.position.x - game.size.x / 2 - 200;
      if (position.x < cameraLeft) {
        removeFromParent();
        return;
      }
    } else {
      if (position.x <= kBounceBuffer && _targetDir.x < 0) {
        _targetDir.x = -_targetDir.x;
      } else if (position.x >= arenaWidth - kBounceBuffer && _targetDir.x > 0) {
        _targetDir.x = -_targetDir.x;
      }
      position.x = position.x.clamp(kBounceBuffer, arenaWidth - kBounceBuffer);

      if (position.y <= kBounceBuffer && _targetDir.y < 0) {
        _targetDir.y = -_targetDir.y;
      } else if (position.y >= arenaHeight - kBounceBuffer &&
          _targetDir.y > 0) {
        _targetDir.y = -_targetDir.y;
      }
      position.y = position.y.clamp(kBounceBuffer, arenaHeight - kBounceBuffer);
    }

    // Lerp smooth: _moveDir ruota verso _targetDir a ~5/s. Quando target ==
    // current, lerp è no-op. Durante turn il gate decelera lateralmente e
    // accelera nella nuova direzione → effetto fisicamente plausibile.
    final lerpRate = (dt * 5).clamp(0.0, 1.0);
    _moveDir.x += (_targetDir.x - _moveDir.x) * lerpRate;
    _moveDir.y += (_targetDir.y - _moveDir.y) * lerpRate;
    if (_moveDir.length2 > 1e-4) {
      _moveDir.normalize();
    }

    // Aggiorna posizione hitbox sulle sfere (ogni frame, perché il gate ruota
    // in funzione del moveDir).
    final perpAngle = math.atan2(_moveDir.y, _moveDir.x) + math.pi / 2;
    final halfW = _gateWidth / 2;
    final sphereOffset1 = Vector2(
      math.cos(perpAngle) * halfW,
      math.sin(perpAngle) * halfW,
    );
    _sphereHitbox1.position = size / 2 + sphereOffset1;
    _sphereHitbox2.position = size / 2 - sphereOffset1;

    // ── WIRE REFLECT/BLOCK (richiesta utente): la LINEA bianca riflette i
    // proiettili e blocca i missili Homing, non solo le sfere. Check manuale
    // punto-segmento. Salta i bullet/missili vicini alle sfere (già gestiti
    // dalle hitbox sfera in onCollisionStart) per non interferire.
    // Singolo walk dei children (perf: prima erano 2 `whereType` = 2 passate
    // su tutti i figli ogni frame). Bullet vicini a una sfera sono saltati
    // (gestiti da onCollisionStart).
    final wireA = position + sphereOffset1;
    final wireB = position - sphereOffset1;
    for (final child in game.world.children) {
      final Vector2 cp;
      if (child is PlayerBullet) {
        cp = child.position;
      } else if (child is HomingMissile) {
        cp = child.position;
      } else {
        continue;
      }
      if (cp.distanceTo(wireA) < _sphereHitboxR ||
          cp.distanceTo(wireB) < _sphereHitboxR) {
        continue;
      }
      if (_pointToSegmentDistance(cp, wireA, wireB) < _wireReflectRadius) {
        if (child is PlayerBullet) {
          child.reflect();
        } else if (child is HomingMissile) {
          child.blockAtGate();
        }
      }
    }

    // Check interazione player con il Gate (solo se cooldown finito e non già esploso)
    if (_cooldown <= 0 && !_exploded && game.player.isMounted) {
      final sphere1 = position + sphereOffset1;
      final sphere2 = position - sphereOffset1;
      final playerPos = game.player.position;
      final d1 = playerPos.distanceTo(sphere1);
      final d2 = playerPos.distanceTo(sphere2);

      // ZONA 1 — Endpoint (sfere arancioni): player tocca → muore, gate sopravvive.
      // Raggio = visual sphere r + player hurtbox = 22 (vedi _endpointKillRadius).
      // OLD 27 era ~3× visual r=9 → death zone troppo ampia, "hitbox imperfetta".
      // NEW 22 = 14+8 → death zone visivamente onesta.
      if (d1 < _endpointKillRadius || d2 < _endpointKillRadius) {
        if (!game.player.isInvincible) {
          game.player.takeDamage();
        }
        _cooldown = 0.3; // anti-spam, gate sopravvive
        return;
      }

      // ZONA 2 — Wire bianco centrale: distanza punto-segmento piccola
      // (player è sulla linea tra le due sfere, lontano dagli endpoint).
      // Gate esplode, player illeso (reward del risk/reward).
      // Raggio = wire half-glow + player hurtbox = 15 (vedi _wireKillRadius).
      final distToWire = _pointToSegmentDistance(playerPos, sphere1, sphere2);
      if (distToWire < _wireKillRadius) {
        _triggerExplosion();
      }
    }
  }

  void _triggerExplosion() {
    if (_exploded) return;
    _exploded = true;

    // Calcola posizioni assolute delle due sfere endpoint (epicentri esplosioni).
    final perpAngle = math.atan2(_moveDir.y, _moveDir.x) + math.pi / 2;
    final halfW = _gateWidth / 2;
    final sphereOffset = Vector2(
      math.cos(perpAngle) * halfW,
      math.sin(perpAngle) * halfW,
    );
    final sphere1 = position + sphereOffset;
    final sphere2 = position - sphereOffset;

    // BOOM! Uccidi tutti i nemici nel raggio di UNA delle due esplosioni
    // (raggio ridotto di 1/3 rispetto a prima). Moltiplicatore separato
    // dal raggio visivo per calibrazione indipendente.
    // AoE combo multiplier: in Pacifism mode cresce con la combo (1.0-2.5×).
    // In altre modalità è sempre 1.0 (combo non si incrementa fuori pacifist).
    const killRadiusMultiplier = 1.5;
    final aoeMult = game.gateComboAoeMultiplier;
    final killRadius = _explosionRadius * killRadiusMultiplier * aoeMult;
    final enemies = game.world.children.whereType<EnemyBase>().toList();
    int killCount = 0;
    for (final enemy in enemies) {
      final d1 = enemy.position.distanceTo(sphere1);
      final d2 = enemy.position.distanceTo(sphere2);
      if (d1 < killRadius || d2 < killRadius) {
        enemy.takeDamage(
          999,
          isArea: true,
        ); // Gate explosion = danno area → splitter immuni
        killCount++;
      }
    }

    // Danneggia anche i boss
    final bosses = game.world.children.whereType<BossBase>().toList();
    for (final boss in bosses) {
      final d1 = boss.position.distanceTo(sphere1);
      final d2 = boss.position.distanceTo(sphere2);
      if (d1 < killRadius || d2 < killRadius) {
        boss.takeDamage(20);
      }
    }

    // Due esplosioni con epicentri sulle sfere endpoint (una per sponda).
    // Ciascuna è composta da 3 layer di colore per l'effetto "blooming".
    for (final epicenter in [sphere1, sphere2]) {
      game.spawnExplosion(
        epicenter,
        const Color(0xFFFFFFFF),
        radius: _explosionRadius * 2.2,
        particleCount: 30,
      );
      game.spawnExplosion(
        epicenter,
        neonColor,
        radius: _explosionRadius * 1.6,
        particleCount: 20,
      );
      game.spawnExplosion(
        epicenter,
        const Color(0xFFFF3030),
        radius: _explosionRadius * 1.1,
        particleCount: 14,
      );
    }

    // Shake ridotto (esplosione più piccola)
    game.triggerScreenShake(10, 0.5);
    if (!game.isTunnelMode) {
      // Forza grid spinta da entrambi gli epicentri
      game.grid.applyForce(sphere1, _explosionRadius * 3, 1500);
      game.grid.applyForce(sphere2, _explosionRadius * 3, 1500);
    }

    // Bonus punti per gate kill.
    // Pacifism mode: dispatch a `onGateExplosion` per applicare combo
    // multiplier + tracking timer. Altre modalità: scoring base diretto.
    if (game.isPacifistMode) {
      game.onGateExplosion(killCount, position);
    } else if (killCount > 0) {
      game.scoreSystem.addKill(killCount * 5, position);
    }

    removeFromParent();
  }

  // Paint cache (iter 6: refactor con più paints riusabili).
  static final _spherePaint = Paint();
  static final _linePaint = Paint();
  static final _glowPaint = Paint();
  static final _haloPaint = Paint();
  static final _arcPaint = Paint()..style = PaintingStyle.stroke;
  static final _sparkPaint = Paint();

  @override
  void render(Canvas canvas) {
    // Warning blink durante cooldown (spawn grace period)
    if (_cooldown > 0) {
      final flashOff = ((_cooldown * 6).toInt() % 2 == 0);
      if (flashOff) return;
    }
    final cx = size.x / 2;
    final cy = size.y / 2;
    final perpAngle = math.atan2(_moveDir.y, _moveDir.x) + math.pi / 2;
    final halfW = _gateWidth / 2;

    // Posizioni sfere (relative al centro del componente)
    final s1x = math.cos(perpAngle) * halfW;
    final s1y = math.sin(perpAngle) * halfW;
    final sphere1 = Offset(cx + s1x, cy + s1y);
    final sphere2 = Offset(cx - s1x, cy - s1y);

    final pulse = 0.4 + math.sin(_phase * 4) * 0.35;
    final fastPulse = 0.5 + math.sin(_phase * 8) * 0.5;

    // ── 1. HALO ESTERNO sfere (alone soft +50% raggio, gradient pulsante) ──
    _haloPaint.color = neonColor.withValues(alpha: 0.10 + pulse * 0.08);
    _haloPaint.maskFilter = null;
    canvas.drawCircle(sphere1, _sphereVisualR * 2.4, _haloPaint);
    canvas.drawCircle(sphere2, _sphereVisualR * 2.4, _haloPaint);

    // ── 2. WIRE GLOW (bianco soft sotto la linea principale) ──
    _glowPaint.color = const Color(
      0xFFFFFFFF,
    ).withValues(alpha: 0.25 + pulse * 0.15);
    _glowPaint.strokeWidth = 16.0;
    _glowPaint.style = PaintingStyle.stroke;
    canvas.drawLine(sphere1, sphere2, _glowPaint);

    // ── 3. WIRE color shift cyan → bianco (segmento gradient simulato) ──
    // 3 strati: ciano largo, bianco medio, core bianco brillante.
    _linePaint.style = PaintingStyle.stroke;
    _linePaint.color = const Color(0xFF66FFFF).withValues(alpha: 0.5);
    _linePaint.strokeWidth = 8.0;
    canvas.drawLine(sphere1, sphere2, _linePaint);
    _linePaint.color = const Color(0xFFFFFFFF).withValues(alpha: 0.85);
    _linePaint.strokeWidth = 4.5;
    canvas.drawLine(sphere1, sphere2, _linePaint);
    _linePaint.color = const Color(0xFFFFFFFF).withValues(alpha: 1.0);
    _linePaint.strokeWidth = 1.8;
    canvas.drawLine(sphere1, sphere2, _linePaint);

    // ── 4. ENERGY ARCS rotanti attorno alle sfere ──
    // Anelli orbitanti (piccoli archi che ruotano a velocità diverse).
    _arcPaint.color = neonColor.withValues(alpha: 0.6);
    _arcPaint.strokeWidth = 1.2;
    for (final centerPt in [sphere1, sphere2]) {
      final orbitR = _sphereVisualR * 1.5;
      final rect = Rect.fromCircle(center: centerPt, radius: orbitR);
      // Arco 1
      canvas.drawArc(rect, _phase * 1.5, math.pi * 0.6, false, _arcPaint);
      // Arco 2 contro-rotante
      canvas.drawArc(
        rect,
        -_phase * 2 + math.pi,
        math.pi * 0.5,
        false,
        _arcPaint,
      );
    }

    // ── 5. SFERE arancioni con pulsing ──
    _spherePaint.color = neonColor.withValues(alpha: pulse);
    _spherePaint.style = PaintingStyle.fill;
    canvas.drawCircle(sphere1, _sphereVisualR, _spherePaint);
    canvas.drawCircle(sphere2, _sphereVisualR, _spherePaint);

    // ── 6. NUCLEO bianco sfere ──
    _spherePaint.color = const Color(0xFFFFFFFF).withValues(alpha: 0.85);
    canvas.drawCircle(sphere1, 5.6, _spherePaint);
    canvas.drawCircle(sphere2, 5.6, _spherePaint);

    // ── 7. SPARK CRACKLES (microsparks animati attorno endpoint) ──
    _sparkPaint.color = const Color(
      0xFFFFFFFF,
    ).withValues(alpha: fastPulse * 0.7);
    for (int i = 0; i < 4; i++) {
      final sparkAng = _phase * 3 + i * math.pi / 2;
      final sparkDist = _sphereVisualR + 4 + math.sin(_phase * 5 + i) * 2;
      for (final centerPt in [sphere1, sphere2]) {
        final sx = centerPt.dx + math.cos(sparkAng) * sparkDist;
        final sy = centerPt.dy + math.sin(sparkAng) * sparkDist;
        canvas.drawCircle(Offset(sx, sy), 1.0, _sparkPaint);
      }
    }

    // ── 8. PARTICELLE lungo wire (3 in fase sfasata + scia bianca) ──
    _spherePaint.color = const Color(0xFFFFFFFF).withValues(alpha: 0.85);
    for (int i = 0; i < 3; i++) {
      final t = ((math.sin(_phase * 2 + i * 2.0) * 0.5 + 0.5));
      final pX = cx + s1x * (1 - 2 * t);
      final pY = cy + s1y * (1 - 2 * t);
      // Glow soft particella
      _spherePaint.color = const Color(0xFF66FFFF).withValues(alpha: 0.4);
      canvas.drawCircle(Offset(pX, pY), 5.5, _spherePaint);
      // Core bianca brillante
      _spherePaint.color = const Color(0xFFFFFFFF).withValues(alpha: 0.9);
      canvas.drawCircle(Offset(pX, pY), 2.5, _spherePaint);
    }
  }
}

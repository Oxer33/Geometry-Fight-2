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
  final double _speed = 60;
  // +50% iter 2 (richiesta utente "bilanciere 50% più grande"): era 75 →
  // ora 112.5. Bilanciere ancora più grande/leggibile + hitbox riallineati
  // al visivo (vedi onLoad e sphere/wire kill radius doc sotto).
  final double _gateWidth = 112.5;
  // Esplosione +50% iter 2 (era 40.5 → 60.75) per coerenza con scala globale.
  // killRadiusMultiplier 1.5 invariato → killRadius effettivo ≈ 91 px/sphere.
  final double _explosionRadius = 60.75;
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
  double _lifetime = 30.0;

  // Size component bbox +66% iter 2 (era 90×90 → 150×150). Necessario per
  // contenere _gateWidth=112.5 + 2×sphere visual r=14 = 140.5 con margine.
  // 150 dà ~9px buffer per pulse FX delle sfere.
  GateEnemy() : super(size: Vector2(150, 150), anchor: Anchor.center) {
    final r = math.Random();
    final angle = r.nextDouble() * math.pi * 2;
    _moveDir = Vector2(math.cos(angle), math.sin(angle));
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
    _sphereHitbox1 =
        CircleHitbox(radius: _sphereHitboxR, anchor: Anchor.center)
          ..position = size / 2;
    _sphereHitbox2 =
        CircleHitbox(radius: _sphereHitboxR, anchor: Anchor.center)
          ..position = size / 2;
    add(_sphereHitbox1);
    add(_sphereHitbox2);
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is PlayerBullet) {
      other.reflect();
    }
  }

  /// Distanza punto-segmento (per check attraversamento wire).
  double _pointToSegmentDistance(Vector2 p, Vector2 a, Vector2 b) {
    final ab = b - a;
    final lenSq = ab.length2;
    if (lenSq == 0) return p.distanceTo(a);
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
    _lifetime -= dt;
    if (_lifetime <= 0) {
      removeFromParent();
      return;
    }

    // Movimento
    position += _moveDir * _speed * dt;

    // Rimbalzo sui muri
    if (game.isTunnelMode) {
      final camY = game.camera.viewfinder.position.y;
      final halfH = game.tunnelHeight / 2;
      if (position.y <= camY - halfH + 20 || position.y >= camY + halfH - 20) {
        _moveDir.y = -_moveDir.y;
        position.y = position.y.clamp(camY - halfH + 20, camY + halfH - 20);
      }
      // Despawn se dietro la camera
      final cameraLeft = game.camera.viewfinder.position.x - game.size.x / 2 - 200;
      if (position.x < cameraLeft) {
        removeFromParent();
        return;
      }
    } else {
      if (position.x <= 20 || position.x >= arenaWidth - 20) {
        _moveDir.x = -_moveDir.x;
        position.x = position.x.clamp(20, arenaWidth - 20);
      }
      if (position.y <= 20 || position.y >= arenaHeight - 20) {
        _moveDir.y = -_moveDir.y;
        position.y = position.y.clamp(20, arenaHeight - 20);
      }
    }

    // Aggiorna posizione hitbox sulle sfere (ogni frame, perché il gate ruota
    // in funzione del moveDir).
    final perpAngle = math.atan2(_moveDir.y, _moveDir.x) + math.pi / 2;
    final halfW = _gateWidth / 2;
    final sphereOffset1 = Vector2(math.cos(perpAngle) * halfW, math.sin(perpAngle) * halfW);
    _sphereHitbox1.position = size / 2 + sphereOffset1;
    _sphereHitbox2.position = size / 2 - sphereOffset1;

    // Check interazione player con il Gate (solo se cooldown finito e non già esploso)
    if (_cooldown <= 0 && !_exploded) {
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
    final sphereOffset = Vector2(math.cos(perpAngle) * halfW, math.sin(perpAngle) * halfW);
    final sphere1 = position + sphereOffset;
    final sphere2 = position - sphereOffset;

    // BOOM! Uccidi tutti i nemici nel raggio di UNA delle due esplosioni
    // (raggio ridotto di 1/3 rispetto a prima). Moltiplicatore separato
    // dal raggio visivo per calibrazione indipendente.
    const killRadiusMultiplier = 1.5;
    final killRadius = _explosionRadius * killRadiusMultiplier; // ~60 px per sfera
    final enemies = game.world.children.whereType<EnemyBase>().toList();
    int killCount = 0;
    for (final enemy in enemies) {
      final d1 = enemy.position.distanceTo(sphere1);
      final d2 = enemy.position.distanceTo(sphere2);
      if (d1 < killRadius || d2 < killRadius) {
        enemy.takeDamage(999, isArea: true); // Gate explosion = danno area → splitter immuni
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
      game.spawnExplosion(epicenter, const Color(0xFFFFFFFF), radius: _explosionRadius * 2.2, particleCount: 30);
      game.spawnExplosion(epicenter, neonColor,              radius: _explosionRadius * 1.6, particleCount: 20);
      game.spawnExplosion(epicenter, const Color(0xFFFF3030), radius: _explosionRadius * 1.1, particleCount: 14);
    }

    // Shake ridotto (esplosione più piccola)
    game.triggerScreenShake(10, 0.5);
    if (!game.isTunnelMode) {
      // Forza grid spinta da entrambi gli epicentri
      game.grid.applyForce(sphere1, _explosionRadius * 3, 1500);
      game.grid.applyForce(sphere2, _explosionRadius * 3, 1500);
    }

    // Bonus punti per gate kill
    if (killCount > 0) {
      game.scoreSystem.addKill(killCount * 5, position);
    }

    removeFromParent();
  }

  // Paint cache
  static final _spherePaint = Paint();
  static final _linePaint = Paint();
  static final _glowPaint = Paint();

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

    // Glow linea: bianco con pulsing. Spessore +50% iter 2 (era 9 → 13.5).
    final pulse = 0.4 + math.sin(_phase * 4) * 0.35;
    _glowPaint.color = const Color(0xFFFFFFFF).withValues(alpha: 0.3);
    _glowPaint.strokeWidth = 13.5;
    _glowPaint.style = PaintingStyle.stroke;
    _glowPaint.maskFilter = null;
    canvas.drawLine(
      Offset(cx + s1x, cy + s1y),
      Offset(cx - s1x, cy - s1y),
      _glowPaint,
    );

    // Linea principale: bianco fluo. Spessore +50% iter 2 (era 3 → 4.5).
    _linePaint.color = const Color(0xFFFFFFFF).withValues(alpha: 0.8);
    _linePaint.strokeWidth = 4.5;
    _linePaint.style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(cx + s1x, cy + s1y),
      Offset(cx - s1x, cy - s1y),
      _linePaint,
    );

    // Sfera 1: arancio fosforescente con pulsing. Visual r 9 → 14 (+50%).
    _spherePaint.color = neonColor.withValues(alpha: pulse);
    _spherePaint.style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx + s1x, cy + s1y), _sphereVisualR, _spherePaint);

    // Sfera 2
    canvas.drawCircle(Offset(cx - s1x, cy - s1y), _sphereVisualR, _spherePaint);

    // Nucleo sfere (bianco, +50% raggio: 3.75 → 5.6).
    _spherePaint.color = const Color(0xFFFFFFFF).withValues(alpha: 0.7);
    canvas.drawCircle(Offset(cx + s1x, cy + s1y), 5.6, _spherePaint);
    canvas.drawCircle(Offset(cx - s1x, cy - s1y), 5.6, _spherePaint);

    // Particelle lungo la linea (energia, +50% raggio: 3 → 4.5).
    final particlePos = math.sin(_phase * 2) * 0.5 + 0.5;
    final px = cx + s1x * (1 - 2 * particlePos);
    final py = cy + s1y * (1 - 2 * particlePos);
    _spherePaint.color = const Color(0xFFFFFFFF).withValues(alpha: 0.6);
    canvas.drawCircle(Offset(px, py), 4.5, _spherePaint);
  }
}

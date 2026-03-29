import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../../data/constants.dart';
import '../../game_world.dart';
import 'enemy_base.dart';
import '../bosses/boss_base.dart';

/// GATE - Due sfere connesse da una linea luminosa (stile Geometry Wars).
/// Il player NON pu sparare ai Gate, ma pu ATTRAVERSARLI.
/// Quando il player ci passa in mezzo, il Gate ESPLODE uccidendo tutti i nemici vicini.
/// Meccanica iconica di GW: Pacifism mode, risk/reward strategico.
///
/// Forma: due sfere (~30px distanza) + linea neon tra loro
/// Colore: verde brillante (#00FF88)
/// HP: infiniti (non danneggiabili dai proiettili)
/// Meccanica: si muove lentamente in una direzione, rimbalza sui muri.
///            Quando il player passa tra le due sfere, BOOM! Uccide tutto nel raggio.
class GateEnemy extends PositionComponent
    with HasGameReference<GeometryFightGame> {
  double _phase = 0;
  late Vector2 _moveDir;
  final double _speed = 60;
  final double _gateWidth = 50.0; // Distanza tra le due sfere
  final double _explosionRadius = 180.0; // Raggio dell'esplosione
  final Color neonColor = const Color(0xFF00FF88);

  // Cooldown anti-spam: impedisce trigger multipli ravvicinati
  double _cooldown = 0.5; // Invulnerabile per 0.5s allo spawn
  double _lifetime = 30.0; // Auto-despawn dopo 30s per non bloccare nulla

  GateEnemy() : super(size: Vector2(60, 60), anchor: Anchor.center) {
    // Direzione casuale
    final r = math.Random();
    final angle = r.nextDouble() * math.pi * 2;
    _moveDir = Vector2(math.cos(angle), math.sin(angle));
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

    // Check interazione player con il Gate (solo se cooldown finito)
    if (_cooldown <= 0) {
      final perpAngle = math.atan2(_moveDir.y, _moveDir.x) + math.pi / 2;
      final halfW = _gateWidth / 2;
      final sphere1 = position + Vector2(math.cos(perpAngle) * halfW, math.sin(perpAngle) * halfW);
      final sphere2 = position - Vector2(math.cos(perpAngle) * halfW, math.sin(perpAngle) * halfW);
      final playerPos = game.player.position;
      final d1 = playerPos.distanceTo(sphere1);
      final d2 = playerPos.distanceTo(sphere2);

      // GW:RE2: se il player TOCCA una sfera → MUORE (risk!)
      if (d1 < 10 || d2 < 10) {
        game.player.takeDamage();
        removeFromParent();
        return;
      }

      // Se il player passa tra le due sfere → esplosione benefica (reward!)
      final distToCenter = playerPos.distanceTo(position);
      if (distToCenter < _gateWidth * 0.8 && d1 > 10 && d2 > 10) {
        _triggerExplosion();
      }
    }
  }

  void _triggerExplosion() {
    // BOOM! Uccidi tutti i nemici nel raggio
    final enemies = game.world.children.whereType<EnemyBase>().toList();
    int killCount = 0;
    for (final enemy in enemies) {
      final dist = enemy.position.distanceTo(position);
      if (dist < _explosionRadius) {
        enemy.takeDamage(999);
        killCount++;
      }
    }

    // Danneggia anche i boss
    final bosses = game.world.children.whereType<BossBase>().toList();
    for (final boss in bosses) {
      final dist = boss.position.distanceTo(position);
      if (dist < _explosionRadius) {
        boss.takeDamage(20);
      }
    }

    // Effetti visivi
    game.spawnExplosion(position, neonColor, radius: _explosionRadius, particleCount: 40);
    game.triggerScreenShake(6, 0.3);
    if (!game.isTunnelMode) {
      game.grid.applyForce(position, _explosionRadius * 1.5, 1500);
    }

    // Bonus punti per gate kill (come GW: il gate d molti punti)
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
    final cx = size.x / 2;
    final cy = size.y / 2;
    final perpAngle = math.atan2(_moveDir.y, _moveDir.x) + math.pi / 2;
    final halfW = _gateWidth / 2;

    // Posizioni sfere (relative al centro del componente)
    final s1x = math.cos(perpAngle) * halfW;
    final s1y = math.sin(perpAngle) * halfW;

    // Glow linea
    final pulse = 0.3 + math.sin(_phase) * 0.15;
    _glowPaint.color = neonColor.withValues(alpha: pulse);
    _glowPaint.strokeWidth = 6;
    _glowPaint.style = PaintingStyle.stroke;
    _glowPaint.maskFilter = null;
    canvas.drawLine(
      Offset(cx + s1x, cy + s1y),
      Offset(cx - s1x, cy - s1y),
      _glowPaint,
    );

    // Linea principale
    _linePaint.color = neonColor.withValues(alpha: 0.8);
    _linePaint.strokeWidth = 2;
    _linePaint.style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(cx + s1x, cy + s1y),
      Offset(cx - s1x, cy - s1y),
      _linePaint,
    );

    // Sfera 1
    _spherePaint.color = neonColor;
    _spherePaint.style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx + s1x, cy + s1y), 6, _spherePaint);

    // Sfera 2
    canvas.drawCircle(Offset(cx - s1x, cy - s1y), 6, _spherePaint);

    // Nucleo sfere (bianco)
    _spherePaint.color = const Color(0xFFFFFFFF).withValues(alpha: 0.7);
    canvas.drawCircle(Offset(cx + s1x, cy + s1y), 2.5, _spherePaint);
    canvas.drawCircle(Offset(cx - s1x, cy - s1y), 2.5, _spherePaint);

    // Particelle lungo la linea (energia)
    final particlePos = math.sin(_phase * 2) * 0.5 + 0.5; // 0..1
    final px = cx + s1x * (1 - 2 * particlePos);
    final py = cy + s1y * (1 - 2 * particlePos);
    _spherePaint.color = const Color(0xFFFFFFFF).withValues(alpha: 0.6);
    canvas.drawCircle(Offset(px, py), 2, _spherePaint);
  }
}

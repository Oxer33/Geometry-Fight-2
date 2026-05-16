import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../../data/constants.dart';
import 'enemy_base.dart';

/// PROTON - Mini nemico velocissimo generato dall'esplosione di un Gravity Well / Black Hole.
/// Come in Geometry Wars: quando un buco nero "mangia" troppi nemici, esplode
/// e rilascia una pioggia di Proton che si disperdono in tutte le direzioni.
/// Forma: cerchietto minuscolo con scia
/// Colore: rosso brillante (#FF2200)
/// HP: 1 · velocissimi · durata limitata (5s poi scompaiono)
class ProtonEnemy extends EnemyBase {
  late Vector2 _moveDir;
  double _lifetime = 5.0;

  // Paint cache: evita alloc per frame × N proton.
  static final Paint _streakPaint = Paint()..strokeWidth = 0.5;
  static final Paint _ringPaint = Paint()..style = PaintingStyle.stroke;
  // Random statico condiviso (evita alloc per ogni proton spawnato).
  static final math.Random _rng = math.Random();

  ProtonEnemy({Vector2? direction, super.speed = 280})
      : super(
          hp: 1,
          pointValue: 2,
          geomValue: 1,
          neonColor: const Color(0xFFFF2200),
          size: Vector2(8, 8),
        ) {
    if (direction != null) {
      _moveDir = direction.normalized();
    } else {
      final angle = _rng.nextDouble() * math.pi * 2;
      _moveDir = Vector2(math.cos(angle), math.sin(angle));
    }
    // Nessuna invulnerabilità spawn: i Proton sono generati in-game da esplosione,
    // non spawnati normalmente. Devono essere immediatamente killabili.
    clearSpawnInvulnerability();
  }

  @override
  void updateBehavior(double dt) {
    _lifetime -= dt;
    if (_lifetime <= 0) {
      removeFromParent();
      return;
    }

    // Movimento veloce nella direzione iniziale con leggero homing
    // (dopo 2s inizia a curvare verso il player, come in GW)
    if (_lifetime < 3.0) {
      final toPlayer = (playerPosition - position);
      if (toPlayer.length2 > 1e-6) {
        final desired = toPlayer.normalized();
        // NaN guard: `_moveDir + desired*0.02` può collassare a zero se
        // _moveDir è quasi opposto a desired (rara cancellazione).
        final sum = _moveDir + desired * 0.02;
        if (sum.length2 > 1e-6) {
          _moveDir = sum.normalized();
        }
      }
    }

    position += _moveDir * speed * dt;

    // Rimbalzo sui muri
    if (game.isTunnelMode) {
      final camY = game.camera.viewfinder.position.y;
      final halfH = game.tunnelHeight / 2;
      if (position.y <= camY - halfH + 5 || position.y >= camY + halfH - 5) {
        _moveDir.y = -_moveDir.y;
        position.y = position.y.clamp(camY - halfH + 5, camY + halfH - 5);
      }
    } else {
      if (position.x <= 5 || position.x >= arenaWidth - 5) {
        _moveDir.x = -_moveDir.x;
        position.x = position.x.clamp(5, arenaWidth - 5);
      }
      if (position.y <= 5 || position.y >= arenaHeight - 5) {
        _moveDir.y = -_moveDir.y;
        position.y = position.y.clamp(5, arenaHeight - 5);
      }
    }
  }

  @override
  void renderShape(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final r = size.x / 2 * scale;

    if (scale <= 1.01) {
      // Scia cometa allungata (5 segmenti sfumati)
      for (int i = 1; i <= 5; i++) {
        final trailAlpha = 0.25 - i * 0.04;
        final trailR = r * (1.0 - i * 0.15);
        if (trailAlpha > 0 && trailR > 0) {
          EnemyBase.detailPaint.color = neonColor.withValues(alpha: trailAlpha);
          canvas.drawCircle(
            Offset(cx - _moveDir.x * i * 3.5, cy - _moveDir.y * i * 3.5),
            trailR, EnemyBase.detailPaint,
          );
        }
      }

      // Linee di velocità laterali
      _streakPaint.color = neonColor.withValues(alpha: 0.15);
      final perpX = -_moveDir.y;
      final perpY = _moveDir.x;
      for (int side = -1; side <= 1; side += 2) {
        final sx = cx + perpX * r * 0.6 * side;
        final sy = cy + perpY * r * 0.6 * side;
        canvas.drawLine(
          Offset(sx, sy),
          Offset(sx - _moveDir.x * 8, sy - _moveDir.y * 8),
          _streakPaint,
        );
      }
    }

    // Corpo principale
    canvas.drawCircle(Offset(cx, cy), r, paint);

    if (scale <= 1.01) {
      // Anello orbitale rotante (paint cache: mutate color + strokeWidth only)
      _ringPaint.color = paint.color.withValues(alpha: 0.3);
      _ringPaint.strokeWidth = 0.5;
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(idlePhase * 8);
      canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: r * 2.2, height: r * 1.0), _ringPaint);
      canvas.restore();

      // Nucleo bianco brillante
      final pulse = 0.5 + math.sin(idlePhase * 8) * 0.3;
      EnemyBase.detailPaint.color = const Color(0xFFFFFFFF).withValues(alpha: pulse);
      canvas.drawCircle(Offset(cx, cy), r * 0.35, EnemyBase.detailPaint);
    }
  }
}

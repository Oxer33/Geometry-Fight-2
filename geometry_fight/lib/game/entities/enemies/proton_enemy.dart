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

  ProtonEnemy({Vector2? direction, double speed = 280})
      : super(
          hp: 1,
          speed: speed,
          pointValue: 2,
          geomValue: 1,
          neonColor: const Color(0xFFFF2200),
          size: Vector2(8, 8),
        ) {
    if (direction != null) {
      _moveDir = direction.normalized();
    } else {
      final angle = math.Random().nextDouble() * math.pi * 2;
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
      if (toPlayer.length > 0) {
        final desired = toPlayer.normalized();
        _moveDir = (_moveDir + desired * 0.02).normalized();
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

    // Scia (3 cerchietti dietro) - solo layer principale
    if (scale <= 1.01) {
      for (int i = 1; i <= 3; i++) {
        final trailAlpha = 0.3 - i * 0.08;
        final trailR = r * (1.0 - i * 0.2);
        if (trailAlpha > 0 && trailR > 0) {
          EnemyBase.detailPaint.color = neonColor.withValues(alpha: trailAlpha);
          canvas.drawCircle(
            Offset(cx - _moveDir.x * i * 4, cy - _moveDir.y * i * 4),
            trailR, EnemyBase.detailPaint,
          );
        }
      }
    }

    // Corpo principale
    canvas.drawCircle(Offset(cx, cy), r, paint);

    // Nucleo bianco
    if (scale <= 1.01) {
      EnemyBase.detailPaint.color = const Color(0xFFFFFFFF).withValues(alpha: 0.6);
      canvas.drawCircle(Offset(cx, cy), r * 0.4, EnemyBase.detailPaint);
    }
  }
}

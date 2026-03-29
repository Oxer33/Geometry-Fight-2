import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../../data/constants.dart';
import 'enemy_base.dart';

/// SWARM DRONE - Piccolo e debole ma spawna in gruppi enormi.
/// Forma: triangolino minuscolo
/// Colore: rosa caldo (#FF3388) → rosso quando enraged
/// Meccanica: si muovono in linea retta (dx/sx o su/giù) e rimbalzano sui muri.
/// Stile Geometry Wars "grunt": pattern a griglia, non inseguono il player.
/// Se uno viene ucciso gli altri accelerano per 1s ("furia").
class SwarmDroneEnemy extends EnemyBase {
  late Vector2 _moveDir;

  SwarmDroneEnemy()
      : super(
          hp: 1,
          speed: 120,
          pointValue: 1,
          geomValue: 1,
          neonColor: const Color(0xFFFF3388),
          size: Vector2(10, 10),
        ) {
    // Direzione iniziale casuale: uno dei 4 assi cardinali
    final r = math.Random();
    _moveDir = r.nextBool()
        ? Vector2(r.nextBool() ? 1 : -1, 0)  // orizzontale
        : Vector2(0, r.nextBool() ? 1 : -1);  // verticale
  }

  @override
  void updateBehavior(double dt) {
    final currentSpeed = isGloballyEnraged ? speed * 1.8 : speed;

    position += _moveDir * currentSpeed * dt;

    // Rimbalza sui muri cambiando asse (dx/sx ↔ su/giù)
    if (game.isTunnelMode) {
      final camY = game.camera.viewfinder.position.y;
      final halfH = game.tunnelHeight / 2;
      if (position.y <= camY - halfH + 10 || position.y >= camY + halfH - 10) {
        _moveDir.y = -_moveDir.y;
        // Se stava andando in verticale, cambia ad orizzontale
        if (_moveDir.x == 0) {
          _moveDir = Vector2(math.Random().nextBool() ? 1 : -1, _moveDir.y.sign * 0.3);
          _moveDir.normalize();
        }
        position.y = position.y.clamp(camY - halfH + 10, camY + halfH - 10);
      }
    } else {
      if (position.x <= 10 || position.x >= arenaWidth - 10) {
        _moveDir.x = -_moveDir.x;
        position.x = position.x.clamp(10, arenaWidth - 10);
      }
      if (position.y <= 10 || position.y >= arenaHeight - 10) {
        _moveDir.y = -_moveDir.y;
        position.y = position.y.clamp(10, arenaHeight - 10);
      }
    }
  }

  @override
  void onDeath() {
    // Enrage: tutti gli SwarmDrone si enragiano globalmente per 1.5s
    // (evita iterazione O(n²) che causa lag con 100+ nemici)
    _globalEnrageTimer = 1.5;
    super.onDeath();
  }

  // Timer globale condiviso: quando uno muore, tutti si enragiano
  static double _globalEnrageTimer = 0;
  static void updateGlobalEnrage(double dt) {
    if (_globalEnrageTimer > 0) _globalEnrageTimer -= dt;
  }
  static void resetGlobalEnrage() => _globalEnrageTimer = 0;
  bool get isGloballyEnraged => _globalEnrageTimer > 0;

  @override
  void renderShape(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final s = size.x / 2 * scale;

    // Triangolino piccolo
    canvas.save();
    canvas.translate(cx, cy);
    final angle = math.atan2(_moveDir.y, _moveDir.x) + math.pi / 2;
    canvas.rotate(angle);

    final color = isGloballyEnraged
        ? const Color(0xFFFF0000)
        : paint.color;
    final p = Paint()..color = color;

    final path = Path()
      ..moveTo(0, -s)
      ..lineTo(s * 0.7, s * 0.5)
      ..lineTo(-s * 0.7, s * 0.5)
      ..close();
    canvas.drawPath(path, p);

    // Nucleo quando enraged (senza blur per performance)
    if (isGloballyEnraged && scale <= 1.01) {
      final ragePaint = Paint()
        ..color = const Color(0xFFFF4400).withValues(alpha: 0.6);
      canvas.drawCircle(Offset.zero, s * 0.4, ragePaint);
    }

    canvas.restore();
  }
}

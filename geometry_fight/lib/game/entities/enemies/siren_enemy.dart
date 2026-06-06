import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import 'enemy_base.dart';
import '../projectiles.dart';

/// SIREN - Nemico che emette onde soniche che rallentano i proiettili del player.
/// Forma: pentagono con onde concentriche che si espandono
/// Colore: viola chiaro (#BB66FF)
/// Meccanica unica: crea un campo di interferenza che rallenta i proiettili del 50%
/// I proiettili nel suo raggio diventano più lenti e fanno meno danno.
class SirenEnemy extends EnemyBase {
  double _wavePhase = 0;
  double _slowTimer = 0;
  // +40% raggio (richiesta utente: support mob 2× più efficaci). Era 150.
  static const double _interferenceRadius = 210.0;
  // Throttle interval in seconds (~33ms ≈ every 2 frames at 60fps)
  static const double _slowInterval = 0.033;

  SirenEnemy()
      : super(
          hp: 5,
          speed: 80,
          pointValue: 15,
          geomValue: 4,
          neonColor: const Color(0xFFBB66FF),
          size: Vector2(22, 22),
        );

  @override
  void updateBehavior(double dt) {
    _wavePhase += dt * 3;

    // Movimento lento verso il player
    final velocity = seekPlayer(speed);
    position += velocity * dt;

    // Rallenta i proiettili del player nel raggio (throttled: ogni ~33ms)
    _slowTimer += dt;
    if (_slowTimer >= _slowInterval) {
      _slowTimer = 0;
      final radiusSq = _interferenceRadius * _interferenceRadius;
      for (final bullet in game.world.children.whereType<PlayerBullet>()) {
        final dx = bullet.position.x - position.x;
        final dy = bullet.position.y - position.y;
        final distSq = dx * dx + dy * dy;
        if (distSq < radiusSq) {
          final pushDir = bullet.position - position;
          if (pushDir.length2 > 1e-6) {
            pushDir.normalize();
            // Push 2× (richiesta utente: rallentamento più efficace). 120×dt
            // resta sotto il movimento per-frame del bullet (~10px/frame) →
            // frena di più senza invertirne la direzione visivamente.
            bullet.position -= pushDir * 120 * dt;
          }
        }
      }
    }
  }

  @override
  void renderShape(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final r = size.x / 2 * scale;

    // Onde concentriche di interferenza (solo layer principale)
    if (scale <= 1.01) {
      EnemyBase.detailPaint.style = PaintingStyle.stroke;
      EnemyBase.detailPaint.strokeWidth = 1;
      for (int i = 0; i < 3; i++) {
        final waveR = ((_wavePhase + i * 1.5) % 4) / 4 * _interferenceRadius * 0.5;
        final waveAlpha = (1 - waveR / (_interferenceRadius * 0.5)) * 0.2;
        if (waveAlpha > 0) {
          EnemyBase.detailPaint.color = neonColor.withValues(alpha: waveAlpha);
          canvas.drawCircle(Offset(cx, cy), waveR + r, EnemyBase.detailPaint);
        }
      }
      EnemyBase.detailPaint.style = PaintingStyle.fill;
    }

    // Pentagono
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(idlePhase * 0.5);
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final angle = i * math.pi * 2 / 5 - math.pi / 2;
      final x = r * math.cos(angle);
      final y = r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);

    if (scale <= 1.01) {
      // Pentagono interno contro-rotante
      final innerPentPath = Path();
      for (int i = 0; i < 5; i++) {
        final angle = i * math.pi * 2 / 5 - math.pi / 2 + math.pi / 5;
        final x = r * 0.55 * math.cos(angle);
        final y = r * 0.55 * math.sin(angle);
        if (i == 0) {
          innerPentPath.moveTo(x, y);
        } else {
          innerPentPath.lineTo(x, y);
        }
      }
      innerPentPath.close();
      EnemyBase.detailPaint.color = paint.color.withValues(alpha: 0.25);
      EnemyBase.detailPaint.style = PaintingStyle.stroke;
      EnemyBase.detailPaint.strokeWidth = 0.6;
      canvas.drawPath(innerPentPath, EnemyBase.detailPaint);

      // Linee di risonanza (connessioni vertice → centro)
      EnemyBase.detailPaint.color = paint.color.withValues(alpha: 0.15);
      EnemyBase.detailPaint.strokeWidth = 0.5;
      for (int i = 0; i < 5; i++) {
        final angle = i * math.pi * 2 / 5 - math.pi / 2;
        final x = r * 0.85 * math.cos(angle);
        final y = r * 0.85 * math.sin(angle);
        canvas.drawLine(Offset.zero, Offset(x, y), EnemyBase.detailPaint);
      }

      // Archi armonici rotanti (2 archi sfasati)
      EnemyBase.detailPaint.color = paint.color.withValues(alpha: 0.2);
      EnemyBase.detailPaint.strokeWidth = 0.7;
      final arcRect = Rect.fromCircle(center: Offset.zero, radius: r * 0.7);
      canvas.drawArc(arcRect, _wavePhase, math.pi * 0.6, false, EnemyBase.detailPaint);
      canvas.drawArc(arcRect, _wavePhase + math.pi, math.pi * 0.6, false, EnemyBase.detailPaint);
      EnemyBase.detailPaint.style = PaintingStyle.fill;

      // 5 nodi frequenza sui vertici (pulsano con la wave)
      for (int i = 0; i < 5; i++) {
        final angle = i * math.pi * 2 / 5 - math.pi / 2;
        final nx = r * 0.85 * math.cos(angle);
        final ny = r * 0.85 * math.sin(angle);
        final nodePulse = 0.3 + math.sin(_wavePhase * 3 + i * 1.2) * 0.3;
        EnemyBase.detailPaint.color = paint.color.withValues(alpha: nodePulse);
        canvas.drawCircle(Offset(nx, ny), 1.0, EnemyBase.detailPaint);
      }

      // Nucleo pulsante con anello
      final pulse = 0.5 + math.sin(_wavePhase * 2) * 0.3;
      EnemyBase.detailPaint.color = const Color(0xFFFFFFFF).withValues(alpha: pulse);
      canvas.drawCircle(Offset.zero, r * 0.15, EnemyBase.detailPaint);
    }
    canvas.restore();
  }
}

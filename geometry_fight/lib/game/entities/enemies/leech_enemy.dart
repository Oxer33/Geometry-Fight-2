import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../../data/constants.dart';
import 'enemy_base.dart';

/// LEECH - Nemico parassita che si aggancia al player e lo rallenta.
/// Forma: piccolo cerchio con tentacoli ondulanti
/// Colore: verde acido (#88FF00)
/// Comportamento: si avvicina rapidamente, quando è vicino "si aggancia" 
/// e drena velocità del player. Va ucciso in fretta!
/// Spawn: dal wave 12, in gruppi di 2-5
class LeechEnemy extends EnemyBase {
  bool _attached = false; // Se è agganciato al player
  double _tentaclePhase = 0;
  double _attachTimer = 0; // Durata dell'aggancio prima di staccarsi

  LeechEnemy()
      : super(
          hp: 2,
          speed: 250, // Veloce per raggiungere il player
          pointValue: 200,
          geomValue: 3,
          neonColor: const Color(0xFF88FF00), // Verde acido
          size: Vector2(14, 14),
        );

  @override
  void updateBehavior(double dt) {
    _tentaclePhase += dt * 8;

    if (_attached) {
      // Segui il player attaccato
      position = playerPosition + Vector2(
        math.cos(_tentaclePhase * 2) * 20,
        math.sin(_tentaclePhase * 2) * 20,
      );
      
      _attachTimer -= dt;
      // Dopo 5 secondi si stacca
      if (_attachTimer <= 0) {
        _attached = false;
      }
      return;
    }

    // Movimento: si avvicina rapidamente al player
    final dist = distanceToPlayer;
    if (dist < 25) {
      // Si aggancia!
      _attached = true;
      _attachTimer = 5.0;
    } else {
      // Seek veloce con zigzag
      final baseDir = seekPlayer(speed);
      final zigzag = Vector2(
        math.sin(_tentaclePhase * 3) * 50,
        math.cos(_tentaclePhase * 3) * 50,
      );
      position += (baseDir + zigzag * 0.3) * dt;
    }
  }

  @override
  void renderShape(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final r = size.x / 2 * scale;

    // Corpo centrale (cerchio)
    canvas.drawCircle(Offset(cx, cy), r * 0.6, paint);

    // Tentacoli ondulanti (4 tentacoli)
    final tentaclePaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * scale;

    for (int i = 0; i < 4; i++) {
      final baseAngle = i * math.pi / 2 + _tentaclePhase * 0.5;
      final path = Path();
      path.moveTo(cx, cy);

      // Curve sinuose per i tentacoli
      final endX = cx + math.cos(baseAngle) * r * 1.2 +
          math.sin(_tentaclePhase + i) * 3;
      final endY = cy + math.sin(baseAngle) * r * 1.2 +
          math.cos(_tentaclePhase + i) * 3;
      final ctrlX = cx + math.cos(baseAngle + 0.3) * r * 0.8;
      final ctrlY = cy + math.sin(baseAngle + 0.3) * r * 0.8;

      path.quadraticBezierTo(ctrlX, ctrlY, endX, endY);
      canvas.drawPath(path, tentaclePaint);
    }

    // Se agganciato, mostra indicatore rosso pulsante
    if (_attached) {
      final pulseAlpha = 0.5 + math.sin(_tentaclePhase * 4) * 0.3;
      final attachPaint = Paint()
        ..color = const Color(0xFFFF0000).withValues(alpha: pulseAlpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(Offset(cx, cy), r * 0.4, attachPaint);
    }
  }
}

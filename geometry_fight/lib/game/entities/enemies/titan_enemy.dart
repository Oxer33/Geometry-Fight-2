import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import 'enemy_base.dart';

/// TITAN - Nemico corazzato enorme, lento ma devastante.
/// Forma: grande esagono con armatura a strati e nucleo pulsante
/// Colore: bronzo/rame (#CC8844)
/// Comportamento: si muove lentamente verso il player, immune ai proiettili 
/// frontali (solo danno da dietro o area), emette onde d'urto periodiche
/// che spingono via il player e i proiettili.
/// Spawn: dal wave 14, massimo 2 per ondata
class TitanEnemy extends EnemyBase {
  double _shockwaveTimer = 4.0; // Timer onda d'urto
  double _shockwaveRadius = 0; // Raggio attuale dell'onda
  bool _shockwaveActive = false;
  double _armorPhase = 0;

  TitanEnemy()
      : super(
          hp: 25, // Molto resistente!
          speed: 60, // Molto lento
          pointValue: 800,
          geomValue: 8,
          neonColor: const Color(0xFFCC8844), // Bronzo/rame
          size: Vector2(40, 40), // Grande
        );

  @override
  void updateBehavior(double dt) {
    _armorPhase += dt * 2;

    // Movimento lento verso il player
    final velocity = seekPlayer(speed);
    position += velocity * dt;

    // Onda d'urto periodica
    _shockwaveTimer -= dt;
    if (_shockwaveTimer <= 0) {
      _shockwaveActive = true;
      _shockwaveRadius = 0;
      _shockwaveTimer = 5.0; // Reset timer
    }

    // Espandi onda d'urto
    if (_shockwaveActive) {
      _shockwaveRadius += 300 * dt;
      if (_shockwaveRadius > 150) {
        _shockwaveActive = false;
        _shockwaveRadius = 0;
      }

      // Spingi via il player se nel raggio
      final dist = distanceToPlayer;
      if (dist < _shockwaveRadius && dist > 0) {
        final pushDir = (playerPosition - position).normalized();
        game.player.position += pushDir * 200 * dt;
      }
    }
  }

  @override
  void takeDamage(double amount) {
    // Il Titan subisce danno ridotto (armatura)
    super.takeDamage(amount * 0.5);
  }

  @override
  void renderShape(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final r = size.x / 2 * scale;

    // Onda d'urto (se attiva)
    if (_shockwaveActive && _shockwaveRadius > 0) {
      final waveAlpha = 1.0 - (_shockwaveRadius / 150);
      final wavePaint = Paint()
        ..color = neonColor.withValues(alpha: waveAlpha * 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(Offset(cx, cy), _shockwaveRadius, wavePaint);
    }

    // Esagono esterno (armatura)
    final armorPath = Path();
    for (int i = 0; i < 6; i++) {
      final angle = i * math.pi / 3 - math.pi / 6 + _armorPhase * 0.1;
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      if (i == 0) {
        armorPath.moveTo(x, y);
      } else {
        armorPath.lineTo(x, y);
      }
    }
    armorPath.close();

    // Armatura con bordo spesso
    final armorBorderPaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 * scale;
    canvas.drawPath(armorPath, armorBorderPaint);

    // Riempimento semi-trasparente
    final fillPaint = Paint()
      ..color = paint.color.withValues(alpha: 0.3);
    canvas.drawPath(armorPath, fillPaint);

    // Nucleo interno pulsante
    final pulseR = r * 0.4 + math.sin(_armorPhase * 3) * 2;
    final corePaint = Paint()
      ..color = const Color(0xFFFFAA00).withValues(alpha: 0.8)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(Offset(cx, cy), pulseR, corePaint);

    // Croce interna (indicatore armatura)
    final crossPaint = Paint()
      ..color = paint.color.withValues(alpha: 0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(cx - r * 0.3, cy), Offset(cx + r * 0.3, cy), crossPaint);
    canvas.drawLine(
      Offset(cx, cy - r * 0.3), Offset(cx, cy + r * 0.3), crossPaint);
  }
}

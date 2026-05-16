import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import 'enemy_base.dart';

/// DECOY - Nemico esca che sembra un power-up ma esplode quando raccolto.
/// Forma: esagono che imita i power-up (pulsante, colorato)
/// Colore: verde ingannevole (#44FF88) che diventa rosso quando scoperto
/// Meccanica: stazionario, sembra un power-up. Se il player si avvicina entro 25px
/// esplode causando danno. Può essere "scoperto" sparandogli (diventa rosso).
/// Se il player lo distrugge da lontano, dropa geomi extra.
class DecoyEnemy extends EnemyBase {
  bool _discovered = false; // Se il player ha sparato e lo ha scoperto
  bool _exploded = false; // Guard contro doppia esplosione
  double _mimicPhase = 0;

  // Paint caches: evita alloc per frame × N decoy.
  static final Paint _whitePaint = Paint();
  static final Paint _sparklePaint = Paint();
  static final Paint _xPaint = Paint()
    ..color = const Color(0xFFFF0000)
    ..strokeWidth = 2
    ..style = PaintingStyle.stroke;
  static final Paint _dangerPaint = Paint();

  DecoyEnemy()
      : super(
          hp: 2,
          speed: 0, // Stazionario come un power-up
          pointValue: 5,
          geomValue: 3,
          neonColor: const Color(0xFF44FF88), // Verde ingannevole
          size: Vector2(22, 22),
        );

  @override
  void updateBehavior(double dt) {
    _mimicPhase += dt * 5;

    // Se il player si avvicina troppo e non è stato scoperto → esplosione trappola
    if (!_discovered && !_exploded && !isRemoving && distanceToPlayer < 30) {
      _trapExplode();
    }
  }

  @override
  void takeDamage(double amount, {bool isArea = false}) {
    if (!_discovered) {
      // Primo colpo: lo scopre, cambia colore
      _discovered = true;
      neonColor = const Color(0xFFFF2200); // Diventa rosso
    }
    super.takeDamage(amount, isArea: isArea);
  }

  void _trapExplode() {
    if (_exploded || isRemoving) return;
    _exploded = true;
    game.player.takeDamage();
    game.spawnExplosion(position, const Color(0xFFFF2200), radius: 60, particleCount: 20);
    game.triggerScreenShake(5, 0.2);
    removeFromParent();
  }

  @override
  void renderShape(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final r = size.x / 2 * scale;
    final pulse = 1.0 + math.sin(_mimicPhase) * 0.12;

    // Se non scoperto: imita un power-up (esagono pulsante verde)
    // Se scoperto: diventa rosso e più aggressivo

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(_mimicPhase * 0.5);

    // Esagono (come i power-up)
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = i * math.pi / 3;
      final pr = r * pulse;
      final x = pr * math.cos(angle);
      final y = pr * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);

    if (scale <= 1.01) {
      if (!_discovered) {
        // Imita power-up: punto bianco centrale (come i veri power-up)
        _whitePaint.color = const Color(0xFFFFFFFF).withValues(alpha: 0.7);
        canvas.drawCircle(Offset.zero, 3, _whitePaint);
        // Scintillio ingannevole
        final sparkle = 0.3 + math.sin(_mimicPhase * 3) * 0.3;
        _sparklePaint.color = paint.color.withValues(alpha: sparkle * 0.1);
        canvas.drawCircle(Offset.zero, r * 0.7, _sparklePaint);
      } else {
        // Scoperto: mostra teschio/pericolo
        canvas.drawLine(Offset(-r * 0.3, -r * 0.3), Offset(r * 0.3, r * 0.3), _xPaint);
        canvas.drawLine(Offset(r * 0.3, -r * 0.3), Offset(-r * 0.3, r * 0.3), _xPaint);
        // Glow rosso pulsante
        final dangerPulse = 0.3 + math.sin(_mimicPhase * 4) * 0.3;
        _dangerPaint.color = const Color(0xFFFF0000).withValues(alpha: dangerPulse * 0.5);
        canvas.drawCircle(Offset.zero, r * 0.9, _dangerPaint);
      }
    }
    canvas.restore();
  }
}

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
  double _mimicPhase = 0;

  DecoyEnemy()
      : super(
          hp: 2,
          speed: 0, // Stazionario come un power-up
          pointValue: 150,
          geomValue: 3,
          neonColor: const Color(0xFF44FF88), // Verde ingannevole
          size: Vector2(22, 22),
        );

  @override
  void updateBehavior(double dt) {
    _mimicPhase += dt * 5;

    // Se il player si avvicina troppo e non è stato scoperto → esplosione trappola
    if (!_discovered && distanceToPlayer < 30) {
      _trapExplode();
    }
  }

  @override
  void takeDamage(double amount) {
    if (!_discovered) {
      // Primo colpo: lo scopre, cambia colore
      _discovered = true;
      neonColor = const Color(0xFFFF2200); // Diventa rosso
    }
    super.takeDamage(amount);
  }

  @override
  void onDeath() {
    // Se scoperto e distrutto dal player: bonus geomi
    if (_discovered) {
      for (int i = 0; i < 5; i++) {
        game.spawnGeom(position + Vector2(
          (math.Random().nextDouble() - 0.5) * 20,
          (math.Random().nextDouble() - 0.5) * 20,
        ), 2);
      }
    }
    super.onDeath();
  }

  void _trapExplode() {
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
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paint);

    if (scale <= 1.01) {
      if (!_discovered) {
        // Imita power-up: punto bianco centrale (come i veri power-up)
        canvas.drawCircle(
          Offset.zero, 3,
          Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.7),
        );
        // Scintillio ingannevole
        final sparkle = 0.3 + math.sin(_mimicPhase * 3) * 0.3;
        canvas.drawCircle(
          Offset.zero, r * 0.5,
          Paint()..color = paint.color.withValues(alpha: sparkle * 0.2)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
      } else {
        // Scoperto: mostra teschio/pericolo
        // X rossa al centro
        final xPaint = Paint()
          ..color = const Color(0xFFFF0000)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;
        canvas.drawLine(Offset(-r * 0.3, -r * 0.3), Offset(r * 0.3, r * 0.3), xPaint);
        canvas.drawLine(Offset(r * 0.3, -r * 0.3), Offset(-r * 0.3, r * 0.3), xPaint);
        // Glow rosso pulsante
        final dangerPulse = 0.3 + math.sin(_mimicPhase * 4) * 0.3;
        canvas.drawCircle(
          Offset.zero, r * 0.6,
          Paint()..color = const Color(0xFFFF0000).withValues(alpha: dangerPulse)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
      }
    }
    canvas.restore();
  }
}

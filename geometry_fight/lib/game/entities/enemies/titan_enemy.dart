import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../../data/constants.dart';
import 'enemy_base.dart';

// Paint cache riutilizzato da tutti i Titan a schermo. Risparmia 4 alloc/frame
// × N titan.
final Paint _titanWavePaint = Paint()
  ..style = PaintingStyle.stroke
  ..strokeWidth = 3;
final Paint _titanArmorBorderPaint = Paint()..style = PaintingStyle.stroke;
final Paint _titanFillPaint = Paint();
final Paint _titanCrossPaint = Paint()
  ..strokeWidth = 1.5
  ..style = PaintingStyle.stroke;

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
  bool _shockwavePushed = false; // Impedisce push multipli per onda
  double _armorPhase = 0;

  TitanEnemy()
    : super(
        hp: 25, // Molto resistente!
        speed: 60, // Molto lento
        pointValue: 25,
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
      _shockwavePushed = false;
      _shockwaveTimer = 5.0; // Reset timer
    }

    // Espandi onda d'urto
    if (_shockwaveActive) {
      _shockwaveRadius += 300 * dt;
      if (_shockwaveRadius > 150) {
        _shockwaveActive = false;
        _shockwaveRadius = 0;
      }

      // Spingi via il player una sola volta quando l'onda lo raggiunge
      final dist = distanceToPlayer;
      if (!_shockwavePushed && dist < _shockwaveRadius && dist > 0.001) {
        final pushVec = playerPosition - position;
        if (pushVec.length2 < 1e-6) return;
        _shockwavePushed = true;
        final pushDir = pushVec.normalized();
        game.player.position += pushDir * 80; // Impulso singolo
        // Clamp post-push: evita di spingere il player fuori arena/tunnel.
        if (game.isTunnelMode) {
          final camY = game.camera.viewfinder.position.y;
          final halfH = game.tunnelHeight / 2;
          game.player.position.y = game.player.position.y.clamp(
            camY - halfH + 10,
            camY + halfH - 10,
          );
        } else {
          game.player.position.x = game.player.position.x.clamp(
            10.0,
            arenaWidth - 10,
          );
          game.player.position.y = game.player.position.y.clamp(
            10.0,
            arenaHeight - 10,
          );
        }
      }
    }
  }

  @override
  void takeDamage(double amount, {bool isArea = false}) {
    // Il Titan subisce danno ridotto SOLO da colpi diretti (armatura frontale).
    // Bomba/laser/area passano normali — l'armatura non protegge da onde d'urto.
    final scaled = isArea ? amount : amount * 0.5;
    super.takeDamage(scaled, isArea: isArea);
  }

  @override
  void renderShape(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final r = size.x / 2 * scale;

    // Onda d'urto (se attiva)
    if (_shockwaveActive && _shockwaveRadius > 0) {
      final waveAlpha = 1.0 - (_shockwaveRadius / 150);
      _titanWavePaint.color = neonColor.withValues(alpha: waveAlpha * 0.4);
      canvas.drawCircle(Offset(cx, cy), _shockwaveRadius, _titanWavePaint);
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
    _titanArmorBorderPaint.color = paint.color;
    _titanArmorBorderPaint.strokeWidth = 3 * scale;
    canvas.drawPath(armorPath, _titanArmorBorderPaint);

    // Riempimento semi-trasparente
    _titanFillPaint.color = paint.color.withValues(alpha: 0.3);
    canvas.drawPath(armorPath, _titanFillPaint);

    // Nucleo interno pulsante
    final pulseR = r * 0.4 + math.sin(_armorPhase * 3) * 2;
    EnemyBase.detailPaint.color = const Color(
      0xFFFFAA00,
    ).withValues(alpha: 0.35);
    canvas.drawCircle(Offset(cx, cy), pulseR * 1.5, EnemyBase.detailPaint);
    EnemyBase.detailPaint.color = const Color(
      0xFFFFAA00,
    ).withValues(alpha: 0.8);
    canvas.drawCircle(Offset(cx, cy), pulseR, EnemyBase.detailPaint);

    // Croce interna (indicatore armatura)
    _titanCrossPaint.color = paint.color.withValues(alpha: 0.5);
    canvas.drawLine(
      Offset(cx - r * 0.3, cy),
      Offset(cx + r * 0.3, cy),
      _titanCrossPaint,
    );
    canvas.drawLine(
      Offset(cx, cy - r * 0.3),
      Offset(cx, cy + r * 0.3),
      _titanCrossPaint,
    );
  }
}

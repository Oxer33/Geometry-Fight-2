import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
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

  // Paint caches: evita alloc per frame × N leech.
  static final Paint _tentaclePaint = Paint()
    ..style = PaintingStyle.stroke;
  static final Paint _ringPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.6;
  static final Paint _attachPaint = Paint();
  static final Paint _veinPaint = Paint()
    ..strokeWidth = 0.8
    ..style = PaintingStyle.stroke;

  // Contatore globale leeches agganciati: applica slow solo quando > 0
  static int _attachedCount = 0;
  static double? _savedPlayerSpeed;
  static void resetAttachedCount() {
    _attachedCount = 0;
    _savedPlayerSpeed = null;
  }

  /// Alias esplicito: resetta tutto lo stato statico globale dei leech.
  /// Da chiamare su game-over / restart / scene transition per evitare
  /// che lo speed multiplier del player resti agganciato a un riferimento stale.
  static void resetAllAttachedState() {
    _attachedCount = 0;
    _savedPlayerSpeed = null;
  }

  @override
  void onDeath() {
    if (_attached) {
      _detach();
    }
    super.onDeath();
  }

  @override
  void onRemove() {
    // FIX H6: ripristina velocità player se rimosso senza passare da onDeath()
    // (es. killSilently(), despawn tunnel, o altri percorsi che bypassano onDeath)
    if (_attached) {
      _detach();
    }
    super.onRemove();
  }

  void _detach() {
    _attached = false;
    _attachedCount = (_attachedCount - 1).clamp(0, 100);
    // Ripristina la velocità precedente solo quando nessun leech è agganciato.
    // Guard isMounted: il player potrebbe essere morto/rimosso quando il leech
    // si sgancia (timer scaduto dopo game-over).
    if (_attachedCount == 0 && _savedPlayerSpeed != null) {
      if (game.player.isMounted) {
        game.player.speed = _savedPlayerSpeed!;
      }
      _savedPlayerSpeed = null;
    }
  }

  LeechEnemy()
      : super(
          hp: 2,
          speed: 250, // Veloce per raggiungere il player
          pointValue: 7,
          geomValue: 3,
          neonColor: const Color(0xFF88FF00), // Verde acido
          size: Vector2(14, 14),
        );

  @override
  void updateBehavior(double dt) {
    _tentaclePhase += dt * 8;

    if (_attached) {
      // Se il player è morto/rimosso, sgancia subito per evitare drift.
      if (!game.player.isMounted) {
        _detach();
        return;
      }
      // Segui il player attaccato (orbita attorno a lui)
      position = playerPosition + Vector2(
        math.cos(_tentaclePhase * 2) * 20,
        math.sin(_tentaclePhase * 2) * 20,
      );

      _attachTimer -= dt;
      if (_attachTimer <= 0) {
        _detach();
      }
      return;
    }

    // Movimento: si avvicina rapidamente al player
    final dist = distanceToPlayer;
    if (dist < 25) {
      // Si aggancia!
      _attached = true;
      _attachTimer = 5.0;
      // Applica slow solo al primo leech agganciato, preservando la velocità attuale
      // (upgrade/modificatori già applicati).
      // Guard isMounted: non applicare slow se il player è già morto/rimosso.
      if (_attachedCount == 0 && game.player.isMounted) {
        _savedPlayerSpeed = game.player.speed;
        game.player.speed = game.player.speed * 0.7;
      }
      _attachedCount++;
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

    // 6 tentacoli ondulanti con punte luminose
    _tentaclePaint.color = paint.color;
    _tentaclePaint.strokeWidth = 1.2 * scale;

    for (int i = 0; i < 6; i++) {
      final baseAngle = i * math.pi / 3 + _tentaclePhase * 0.5;
      final wobble1 = math.sin(_tentaclePhase * 1.5 + i * 1.1) * 4;
      final wobble2 = math.cos(_tentaclePhase * 1.2 + i * 0.8) * 3;
      final path = Path();
      path.moveTo(cx, cy);

      final midX = cx + math.cos(baseAngle + 0.2) * r * 0.7 + wobble1;
      final midY = cy + math.sin(baseAngle + 0.2) * r * 0.7 + wobble2;
      final endX = cx + math.cos(baseAngle) * r * 1.3 + wobble2;
      final endY = cy + math.sin(baseAngle) * r * 1.3 + wobble1;

      path.quadraticBezierTo(midX, midY, endX, endY);
      canvas.drawPath(path, _tentaclePaint);

      // Punte luminose sui tentacoli
      if (scale <= 1.01) {
        final tipPulse = 0.3 + math.sin(_tentaclePhase * 3 + i * 1.0) * 0.3;
        EnemyBase.detailPaint.color = paint.color.withValues(alpha: tipPulse);
        canvas.drawCircle(Offset(endX, endY), 1.0, EnemyBase.detailPaint);
      }
    }

    // Corpo centrale (cerchio)
    canvas.drawCircle(Offset(cx, cy), r * 0.55, paint);

    if (scale <= 1.01) {
      // Anello interno (membrana)
      _ringPaint.color = paint.color.withValues(alpha: 0.3);
      canvas.drawCircle(Offset(cx, cy), r * 0.35, _ringPaint);

      // 3 sacche bio-luminose rotanti attorno al corpo
      for (int i = 0; i < 3; i++) {
        final sacAngle = _tentaclePhase * 2 + i * math.pi * 2 / 3;
        final sx = cx + math.cos(sacAngle) * r * 0.3;
        final sy = cy + math.sin(sacAngle) * r * 0.3;
        final sacPulse = 0.25 + math.sin(_tentaclePhase * 4 + i * 2) * 0.2;
        EnemyBase.detailPaint.color = const Color(0xFFCCFF00).withValues(alpha: sacPulse);
        canvas.drawCircle(Offset(sx, sy), 1.0, EnemyBase.detailPaint);
      }

      // Nucleo pulsante
      final corePulse = 0.4 + math.sin(_tentaclePhase * 3) * 0.3;
      EnemyBase.detailPaint.color = const Color(0xFFFFFFFF).withValues(alpha: corePulse);
      canvas.drawCircle(Offset(cx, cy), r * 0.15, EnemyBase.detailPaint);
    }

    // Se agganciato: indicatore rosso + vene di assorbimento
    if (_attached && scale <= 1.01) {
      final pulseAlpha = 0.5 + math.sin(_tentaclePhase * 4) * 0.3;
      _attachPaint.color = const Color(0xFFFF0000).withValues(alpha: pulseAlpha);
      canvas.drawCircle(Offset(cx, cy), r * 0.4, _attachPaint);

      // Vene rosse pulsanti verso l'esterno
      _veinPaint.color = const Color(0xFFFF0000).withValues(alpha: 0.3);
      for (int i = 0; i < 4; i++) {
        final vAngle = i * math.pi / 2 + _tentaclePhase;
        canvas.drawLine(
          Offset(cx, cy),
          Offset(cx + math.cos(vAngle) * r * 0.5, cy + math.sin(vAngle) * r * 0.5),
          _veinPaint,
        );
      }
    }
  }
}

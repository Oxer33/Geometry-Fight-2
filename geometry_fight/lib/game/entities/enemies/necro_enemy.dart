import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../../data/constants.dart';
import '../../../data/wave_configs.dart';
import 'enemy_base.dart';

/// NECRO - Nemico necromante che resuscita i nemici morti vicini.
/// Forma: teschio stilizzato (cerchio con orbite oculari)
/// Colore: viola scuro (#8800AA)
/// Meccanica unica: quando un nemico muore nel suo raggio (200px),
/// dopo 3 secondi ne spawna uno nuovo dello stesso tipo ma con HP ridotti.
/// Va ucciso prima degli altri per evitare resurrezioni infinite!
class NecroEnemy extends EnemyBase {
  double _ritualPhase = 0;
  final List<_PendingResurrection> _pendingRes = [];
  static const double _resurrectionRadius = 200.0;

  NecroEnemy()
      : super(
          hp: 6,
          speed: 70,
          pointValue: 600,
          geomValue: 6,
          neonColor: const Color(0xFF8800AA),
          size: Vector2(24, 24),
        );

  @override
  void updateBehavior(double dt) {
    _ritualPhase += dt * 2;

    // Movimento lento - si mantiene a media distanza
    final dist = distanceToPlayer;
    if (dist > 350) {
      position += seekPlayer(speed) * dt;
    } else if (dist < 200) {
      final awayDir = (position - playerPosition).normalized();
      position += awayDir * speed * 0.5 * dt;
    }

    // Processa resurrezioni pending
    for (int i = _pendingRes.length - 1; i >= 0; i--) {
      _pendingRes[i].timer -= dt;
      if (_pendingRes[i].timer <= 0) {
        // Resuscita il nemico
        game.spawnEnemy(_pendingRes[i].type, _pendingRes[i].position);
        _pendingRes.removeAt(i);
      }
    }

    // Controlla nemici morti vicini (tramite il game world)
    // Questo viene gestito dal game_world.onEnemyKilled chiamando notifyNecros
  }

  /// Chiamato quando un nemico muore vicino al necro
  void onNearbyEnemyDeath(EnemyType type, Vector2 deathPos) {
    final dist = position.distanceTo(deathPos);
    if (dist < _resurrectionRadius && _pendingRes.length < 3) {
      _pendingRes.add(_PendingResurrection(
        type: type,
        position: deathPos,
        timer: 3.0,
      ));
    }
  }

  @override
  void renderShape(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final r = size.x / 2 * scale;

    // Cerchio ritualistico esterno (solo principale)
    if (scale <= 1.01) {
      final ritualPaint = Paint()
        ..color = neonColor.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5;
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(_ritualPhase * 0.3);
      // Cerchio con simboli
      canvas.drawCircle(Offset.zero, r * 1.5, ritualPaint);
      // Punti cardinali
      for (int i = 0; i < 4; i++) {
        final angle = i * math.pi / 2;
        final px = r * 1.5 * math.cos(angle);
        final py = r * 1.5 * math.sin(angle);
        canvas.drawCircle(Offset(px, py), 1.5, Paint()..color = neonColor.withValues(alpha: 0.3));
      }
      canvas.restore();

      // Indicatori resurrezioni pending
      for (int i = 0; i < _pendingRes.length; i++) {
        final resPaint = Paint()
          ..color = neonColor.withValues(alpha: 0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        final offset = _pendingRes[i].position - position;
        canvas.drawCircle(Offset(cx + offset.x, cy + offset.y), 5, resPaint);
      }
    }

    // Teschio: cerchio principale
    canvas.drawCircle(Offset(cx, cy), r * 0.7, paint);

    // Dettagli teschio (solo layer principale)
    if (scale <= 1.01) {
      final eyePaint = Paint()..color = const Color(0xFF000000);
      // Occhi
      canvas.drawCircle(Offset(cx - r * 0.25, cy - r * 0.1), r * 0.15, eyePaint);
      canvas.drawCircle(Offset(cx + r * 0.25, cy - r * 0.1), r * 0.15, eyePaint);
      // Pupille luminose
      final pupilGlow = 0.5 + math.sin(_ritualPhase * 3) * 0.5;
      final pupilPaint = Paint()
        ..color = neonColor.withValues(alpha: pupilGlow)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawCircle(Offset(cx - r * 0.25, cy - r * 0.1), r * 0.08, pupilPaint);
      canvas.drawCircle(Offset(cx + r * 0.25, cy - r * 0.1), r * 0.08, pupilPaint);
      // Bocca (linea)
      final mouthPaint = Paint()
        ..color = const Color(0xFF000000)
        ..strokeWidth = 1;
      canvas.drawLine(Offset(cx - r * 0.2, cy + r * 0.25), Offset(cx + r * 0.2, cy + r * 0.25), mouthPaint);
    }
  }
}

class _PendingResurrection {
  final EnemyType type;
  final Vector2 position;
  double timer;

  _PendingResurrection({
    required this.type,
    required this.position,
    required this.timer,
  });
}

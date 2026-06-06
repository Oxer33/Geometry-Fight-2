import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import 'enemy_base.dart';

/// HEALER - Nemico supporto che cura gli altri nemici vicini.
/// Forma: croce medica verde brillante con anello di cura pulsante
/// Colore: verde smeraldo (#00FF88)
/// Comportamento: si mantiene a distanza dal player (250px),
/// ogni 2s emette un'onda di cura che rigenera 1 HP a tutti i nemici nel raggio.
/// Priorità alta: va ucciso subito!
/// Spawn: dal wave 18, max 2 per wave
class HealerEnemy extends EnemyBase {
  double _healTimer = 2.0;
  double _healPulseRadius = 0;
  bool _healPulseActive = false;
  // +30% raggio (richiesta utente: support mob più efficaci). Era 200.
  static const double _healRadius = 260.0;
  static const double _keepDistance = 250.0;

  // Paint cache: evita alloc per frame × N healers.
  static final Paint _rangePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.5;

  HealerEnemy()
      : super(
          hp: 4,
          speed: 130,
          pointValue: 18,
          geomValue: 5,
          neonColor: const Color(0xFF00FF88),
          size: Vector2(22, 22),
        );

  @override
  void updateBehavior(double dt) {
    // Mantieni distanza dal player (non troppo vicino, non troppo lontano)
    final dist = distanceToPlayer;
    // NaN guard: se coincide col player, skip movement (evita NaN
    // normalize/atan2 → posizione +Inf → crash renderer).
    if (dist > 0.001) {
      if (dist < _keepDistance - 50) {
        // Troppo vicino, allontanati
        final awayDir = (position - playerPosition).normalized();
        position += awayDir * speed * dt;
      } else if (dist > _keepDistance + 100) {
        // Troppo lontano, avvicinati
        final velocity = seekPlayer(speed * 0.6);
        position += velocity * dt;
      } else {
        // Orbita lentamente attorno al player
        final angle = math.atan2(position.y - playerPosition.y, position.x - playerPosition.x);
        final orbitAngle = angle + dt * 0.5;
        position = playerPosition + Vector2(math.cos(orbitAngle), math.sin(orbitAngle)) * dist;
      }
    }

    // Timer cura
    _healTimer -= dt;
    if (_healTimer <= 0) {
      _healTimer = 2.5;
      _healNearbyEnemies();
      _healPulseActive = true;
      _healPulseRadius = 0;
    }

    // Animazione onda di cura
    if (_healPulseActive) {
      _healPulseRadius += 300 * dt;
      if (_healPulseRadius > _healRadius) {
        _healPulseActive = false;
      }
    }
  }

  void _healNearbyEnemies() {
    final radiusSq = _healRadius * _healRadius;
    for (final child in game.world.children.whereType<EnemyBase>()) {
      if (child == this) continue;
      // Skip dead-or-dying enemies: hp <= 0 means onDeath() was already called
      // (pending removal). Healing them would corrupt the dying state.
      if (child.hp <= 0) continue;
      if (child.hp >= child.maxHp) continue;
      final dx = child.position.x - position.x;
      final dy = child.position.y - position.y;
      if (dx * dx + dy * dy < radiusSq) {
        // +2 HP per pulse (era +1): cura 2× più efficace (richiesta utente).
        child.hp = (child.hp + 2).clamp(0, child.maxHp);
      }
    }
  }

  @override
  void renderShape(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final s = size.x / 2 * scale;

    // Onda di cura espansiva (no blur per performance)
    if (_healPulseActive && scale <= 1.01) {
      final alpha = (1 - _healPulseRadius / _healRadius) * 0.4;
      EnemyBase.detailPaint.color = neonColor.withValues(alpha: alpha);
      EnemyBase.detailPaint.style = PaintingStyle.stroke;
      EnemyBase.detailPaint.strokeWidth = 2;
      canvas.drawCircle(Offset(cx, cy), _healPulseRadius, EnemyBase.detailPaint);
    }
    // Always reset shared detailPaint style to fill so subsequent renderShape
    // calls on other enemies receive a consistent fill state.
    EnemyBase.detailPaint.style = PaintingStyle.fill;

    // Croce medica
    final crossW = s * 0.35;
    final crossH = s * 0.9;
    // Verticale
    canvas.drawRect(
      Rect.fromCenter(center: Offset(cx, cy), width: crossW, height: crossH),
      paint,
    );
    // Orizzontale
    canvas.drawRect(
      Rect.fromCenter(center: Offset(cx, cy), width: crossH, height: crossW),
      paint,
    );

    // Dettagli interni
    if (scale <= 1.01) {
      // Nucleo pulsante (no blur)
      final pulse = 0.5 + math.sin(idlePhase * 4) * 0.3;
      EnemyBase.detailPaint.color = const Color(0xFFFFFFFF).withValues(alpha: pulse);
      canvas.drawCircle(Offset(cx, cy), s * 0.2, EnemyBase.detailPaint);

      // Cerchio indicatore raggio cura
      _rangePaint.color = neonColor.withValues(alpha: 0.08);
      canvas.drawCircle(Offset(cx, cy), s * 2, _rangePaint);
    }
  }
}

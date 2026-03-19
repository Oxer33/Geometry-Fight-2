import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import 'boss_base.dart';

/// VOID REAPER - Boss che crea zone di morte nell'arena.
/// Forma: falce stilizzata (arco con punta) con alone viola scuro
/// Colore: viola morte (#6600AA)
/// HP: 1800 · 3 fasi
/// Meccanica: piazza "zone di morte" circolari nell'arena che danneggiano il player.
/// Fase 2: le zone si espandono. Fase 3: insegue il player velocemente.
class VoidReaperBoss extends BossBase {
  double _attackTimer = 4.0;
  double _movePhase = 0;
  final List<_DeathZone> _deathZones = [];
  static const int _maxZones = 6;

  VoidReaperBoss()
      : super(
          hp: 1800,
          bossName: 'VOID REAPER',
          pointValue: 3500,
          neonColor: const Color(0xFF6600AA),
          size: Vector2(100, 100),
        );

  @override
  int getPhase() {
    if (healthPercent > 0.6) return 0;
    if (healthPercent > 0.25) return 1;
    return 2;
  }

  @override
  void updateBoss(double dt) {
    _movePhase += dt * 2;

    // Movimento: insegue il player, più veloce in fase finale
    final speed = currentPhase == 2 ? 180.0 : 80.0;
    final toPlayer = (playerPosition - position);
    if (toPlayer.length > 50) {
      position += toPlayer.normalized() * speed * dt;
    }

    // Crea zone di morte periodicamente
    _attackTimer -= dt;
    if (_attackTimer <= 0) {
      _attackTimer = currentPhase == 2 ? 2.0 : 3.5;
      _createDeathZone();
    }

    // Aggiorna zone di morte
    for (int i = _deathZones.length - 1; i >= 0; i--) {
      _deathZones[i].lifetime -= dt;
      _deathZones[i].phase += dt * 3;
      // Espansione in fase 1+
      if (currentPhase >= 1) {
        _deathZones[i].radius += 5 * dt;
      }
      // Danno al player
      final dist = game.player.position.distanceTo(_deathZones[i].position);
      if (dist < _deathZones[i].radius) {
        _deathZones[i].damageTimer -= dt;
        if (_deathZones[i].damageTimer <= 0) {
          game.player.takeDamage();
          _deathZones[i].damageTimer = 1.0;
        }
      }
      if (_deathZones[i].lifetime <= 0) {
        _deathZones.removeAt(i);
      }
    }
  }

  void _createDeathZone() {
    if (_deathZones.length >= _maxZones) {
      _deathZones.removeAt(0);
    }
    // Piazza la zona vicino al player
    final random = math.Random();
    final offset = Vector2(
      (random.nextDouble() - 0.5) * 300,
      (random.nextDouble() - 0.5) * 300,
    );
    _deathZones.add(_DeathZone(
      position: playerPosition + offset,
      radius: 60 + currentPhase * 20.0,
      lifetime: 8.0,
    ));
    game.grid.applyForce(playerPosition + offset, 80, 300);
  }

  @override
  void renderBoss(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final r = size.x / 2 * scale;

    // Zone di morte (cerchi viola pulsanti)
    if (scale <= 1.01) {
      for (final zone in _deathZones) {
        final offset = zone.position - position;
        final zAlpha = (zone.lifetime / 8.0).clamp(0.0, 1.0) * 0.3;
        final pulse = 1.0 + math.sin(zone.phase) * 0.1;
        // Riempimento
        final fillPaint = Paint()
          ..color = neonColor.withValues(alpha: zAlpha * 0.3);
        canvas.drawCircle(Offset(cx + offset.x, cy + offset.y), zone.radius * pulse, fillPaint);
        // Bordo
        final borderPaint = Paint()
          ..color = neonColor.withValues(alpha: zAlpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        canvas.drawCircle(Offset(cx + offset.x, cy + offset.y), zone.radius * pulse, borderPaint);
      }
    }

    // Corpo: arco/falce stilizzata
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(_movePhase * 0.5);

    // Arco principale
    final arcPaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8 * scale;
    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: r * 0.7),
      -math.pi * 0.8, math.pi * 1.2, false, arcPaint,
    );

    // Punta della falce
    final tipPath = Path()
      ..moveTo(r * 0.7 * math.cos(-math.pi * 0.8), r * 0.7 * math.sin(-math.pi * 0.8))
      ..lineTo(r * 0.9 * math.cos(-math.pi * 0.9), r * 0.9 * math.sin(-math.pi * 0.9))
      ..lineTo(r * 0.5 * math.cos(-math.pi * 0.7), r * 0.5 * math.sin(-math.pi * 0.7))
      ..close();
    canvas.drawPath(tipPath, Paint()..color = paint.color);

    canvas.restore();

    // Nucleo
    if (scale <= 1.01) {
      final pulse = 0.4 + math.sin(_movePhase * 3) * 0.3;
      final corePaint = Paint()
        ..color = const Color(0xFFCC44FF).withValues(alpha: pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawCircle(Offset(cx, cy), r * 0.25, corePaint);
    }
  }
}

class _DeathZone {
  Vector2 position;
  double radius;
  double lifetime;
  double phase = 0;
  double damageTimer = 0.5;

  _DeathZone({
    required this.position,
    required this.radius,
    required this.lifetime,
  });
}

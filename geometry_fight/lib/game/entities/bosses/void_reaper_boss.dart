import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../../data/wave_configs.dart';
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

  // VoidReaper è VIOLA SCURO → mob viola (phantom + mirror + proton).
  @override
  List<EnemyType> get colorMatchedMinions =>
      const [EnemyType.phantom, EnemyType.mirror, EnemyType.proton];

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
      } else {
        // Reset cooldown quando il player è fuori: evita hit istantaneo
        // alla ri-entrata se l'ultimo tick aveva damageTimer ≈ 0.
        _deathZones[i].damageTimer = 1.0;
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
    if (!game.isTunnelMode) {
      game.grid.applyForce(playerPosition + offset, 80, 300);
    }
  }

  // Paint cache FX
  static final _zoneFillPaint = Paint();
  static final _zoneBorderPaint = Paint()..style = PaintingStyle.stroke;
  static final _zoneVortexPaint = Paint()..style = PaintingStyle.stroke;
  static final _arcPaint = Paint()..style = PaintingStyle.stroke;
  static final _tipPaint = Paint();
  static final _coreHaloPaint = Paint();
  static final _corePaint = Paint();
  static final _voidParticlePaint = Paint();

  @override
  void renderBoss(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final r = size.x / 2 * scale;

    // ─── DEATH ZONES (vortex viola con spirali interne) ───
    if (scale <= 1.01) {
      for (final zone in _deathZones) {
        final offset = zone.position - position;
        final zAlpha = (zone.lifetime / 8.0).clamp(0.0, 1.0);
        final pulse = 1.0 + math.sin(zone.phase) * 0.1;
        final zCx = cx + offset.x;
        final zCy = cy + offset.y;
        _zoneFillPaint.color = neonColor.withValues(alpha: zAlpha * 0.25);
        canvas.drawCircle(
            Offset(zCx, zCy), zone.radius * pulse, _zoneFillPaint);
        _zoneBorderPaint.color = neonColor.withValues(alpha: zAlpha * 0.7);
        _zoneBorderPaint.strokeWidth = 2;
        canvas.drawCircle(
            Offset(zCx, zCy), zone.radius * pulse, _zoneBorderPaint);
        // Vortex interno: 3 archi rotanti
        _zoneVortexPaint.color =
            const Color(0xFFCC44FF).withValues(alpha: zAlpha * 0.5);
        _zoneVortexPaint.strokeWidth = 1.2;
        canvas.save();
        canvas.translate(zCx, zCy);
        canvas.rotate(zone.phase * 1.5);
        for (int v = 0; v < 3; v++) {
          final vr = zone.radius * (0.3 + v * 0.25) * pulse;
          canvas.drawArc(
              Rect.fromCircle(center: Offset.zero, radius: vr),
              v * math.pi * 0.7, math.pi * 0.9, false, _zoneVortexPaint);
        }
        canvas.restore();
      }
    }

    // ─── VOID PARTICLES (fumo attorno al corpo) ───
    if (scale <= 1.01) {
      for (int i = 0; i < 8; i++) {
        final vp = _movePhase * 0.7 + i * 0.9;
        final vAngle = vp % (math.pi * 2);
        final vDist = r * (1.0 + ((vp * 0.4) % 1.0) * 0.8);
        final vAlpha = (1.0 - ((vp * 0.4) % 1.0)) * 0.7;
        _voidParticlePaint.color =
            const Color(0xFFCC44FF).withValues(alpha: vAlpha);
        canvas.drawCircle(
          Offset(cx + math.cos(vAngle) * vDist,
              cy + math.sin(vAngle) * vDist),
          2 + (i % 3) * 0.8,
          _voidParticlePaint,
        );
      }
    }

    // ─── CORPO: FALCE ───
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(_movePhase * 0.5);
    _arcPaint.color = paint.color;
    _arcPaint.strokeWidth = 8 * scale;
    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: r * 0.7),
      -math.pi * 0.8, math.pi * 1.2, false, _arcPaint,
    );
    final tipPath = Path()
      ..moveTo(r * 0.7 * math.cos(-math.pi * 0.8),
          r * 0.7 * math.sin(-math.pi * 0.8))
      ..lineTo(r * 0.9 * math.cos(-math.pi * 0.9),
          r * 0.9 * math.sin(-math.pi * 0.9))
      ..lineTo(r * 0.5 * math.cos(-math.pi * 0.7),
          r * 0.5 * math.sin(-math.pi * 0.7))
      ..close();
    _tipPaint.color = paint.color;
    canvas.drawPath(tipPath, _tipPaint);
    canvas.restore();

    // ─── NUCLEO CROMATICO (halo + occhio viola + pupilla bianca) ───
    if (scale <= 1.01) {
      final pulse = 0.5 + math.sin(_movePhase * 3) * 0.4;
      _coreHaloPaint.color =
          const Color(0xFFCC44FF).withValues(alpha: pulse * 0.4);
      canvas.drawCircle(Offset(cx, cy), r * 0.45, _coreHaloPaint);
      _corePaint.color = const Color(0xFFCC44FF).withValues(alpha: pulse);
      canvas.drawCircle(Offset(cx, cy), r * 0.25, _corePaint);
      _corePaint.color = const Color(0xFFFFFFFF).withValues(alpha: pulse);
      canvas.drawCircle(Offset(cx, cy), r * 0.08, _corePaint);
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

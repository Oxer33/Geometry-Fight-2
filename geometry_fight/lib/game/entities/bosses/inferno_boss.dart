import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../../data/wave_configs.dart';
import '../../game_world.dart';
import 'boss_base.dart';

/// INFERNO - Boss di fuoco che lascia scie infuocate e crea muri di fiamma.
/// Forma: stella a 5 punte con fiamme animate
/// Colore: arancione/rosso fuoco (#FF4400)
/// HP: 1900 · 3 fasi
/// Meccanica: si muove velocemente lasciando scie di fuoco che danneggiano.
/// Crea muri di fiamma lineari nell'arena.
class InfernoBoss extends BossBase {
  double _flamePhase = 0;
  double _attackTimer = 3.0;
  double _moveAngle = 0;
  final List<_FlameTrail> _trails = [];
  // Cooldown boss-level: 60 trails sovrapposti sul player non devono
  // causare 60 takeDamage nello stesso frame (oltre iframe player).
  double _anyTrailHitTimer = 0;

  InfernoBoss()
      : super(
          hp: 1900,
          bossName: 'INFERNO',
          pointValue: 3800,
          neonColor: const Color(0xFFFF4400),
          size: Vector2(90, 90),
        );

  // Inferno è ROSSO FUOCO → mob rossi/fuoco (kamikaze + timeBomb + proton).
  @override
  List<EnemyType> get colorMatchedMinions =>
      const [EnemyType.kamikaze, EnemyType.timeBomb, EnemyType.proton];

  @override
  int getPhase() {
    if (healthPercent > 0.7) return 0;
    if (healthPercent > 0.4) return 1;
    return 2;
  }

  @override
  void updateBoss(double dt) {
    _flamePhase += dt * 8;
    _moveAngle += dt * (1.5 + currentPhase * 0.5);

    // Movimento veloce in pattern circolare
    final speed = 120.0 + currentPhase * 40;
    final targetPos = playerPosition + Vector2(
      math.cos(_moveAngle) * (200 - currentPhase * 30),
      math.sin(_moveAngle) * (200 - currentPhase * 30),
    );
    final toTarget = targetPos - position;
    if (toTarget.length > 5) {
      position += toTarget.normalized() * speed * dt;
    }

    // Lascia scia di fuoco
    _trails.add(_FlameTrail(position: position.clone(), lifetime: 3.0));
    // Boss-level cooldown decrement.
    if (_anyTrailHitTimer > 0) _anyTrailHitTimer -= dt;
    // Aggiorna e rimuovi trails
    for (int i = _trails.length - 1; i >= 0; i--) {
      final trail = _trails[i];
      trail.lifetime -= dt;
      if (trail.lifetime <= 0) {
        _trails.removeAt(i);
      } else if (_anyTrailHitTimer <= 0) {
        // Cooldown BOSS-level: se ANY trail hit, skip altri per 0.5s.
        // Evita che 60 trail sovrapposti causino 60 takeDamage in un frame.
        final dist = game.player.position.distanceTo(trail.position);
        if (dist < 15) {
          game.player.takeDamage();
          _anyTrailHitTimer = 0.5;
          break;
        }
      }
    }
    // Limita trails
    while (_trails.length > 60) {
      _trails.removeAt(0);
    }

    // Attacco: proiettili di fuoco
    _attackTimer -= dt;
    if (_attackTimer <= 0) {
      _attackTimer = 2.0 - currentPhase * 0.4;
      _fireAttack();
    }
  }

  void _fireAttack() {
    final count = 5 + currentPhase * 3;
    for (int i = 0; i < count; i++) {
      final angle = i * math.pi * 2 / count + _flamePhase * 0.05;
      final dir = Vector2(math.cos(angle), math.sin(angle));
      final bullet = _FireBullet(direction: dir);
      bullet.position = position.clone();
      game.world.add(bullet);
    }
  }

  // Cache paints — evita alloc/frame sui trail (60 elementi) + FX
  static final _trailOuterPaint = Paint();
  static final _trailCorePaint = Paint();
  static final _heatRingPaint = Paint()..style = PaintingStyle.stroke;
  static final _coreGlowPaint = Paint();
  static final _corePaint = Paint();
  static final _coreWhitePaint = Paint();
  static final _emberPaint = Paint();

  @override
  void renderBoss(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final r = size.x / 2 * scale;

    // ─── SCIE DI FUOCO (esterno arancione + core giallo) ───
    if (scale <= 1.01) {
      for (final trail in _trails) {
        final offset = trail.position - position;
        final lifeT = (trail.lifetime / 3.0).clamp(0.0, 1.0);
        final trailR = 7 * lifeT;
        final centerOff = Offset(cx + offset.x, cy + offset.y);
        _trailOuterPaint.color = neonColor.withValues(alpha: lifeT * 0.35);
        canvas.drawCircle(centerOff, trailR * 1.4, _trailOuterPaint);
        _trailCorePaint.color =
            const Color(0xFFFFDD00).withValues(alpha: lifeT * 0.65);
        canvas.drawCircle(centerOff, trailR * 0.7, _trailCorePaint);
      }
    }

    // ─── HEAT DISTORTION RINGS (onde calore pulsanti) ───
    if (scale <= 1.01) {
      final heatPulse = 0.5 + math.sin(_flamePhase * 0.4) * 0.5;
      for (int i = 0; i < 3; i++) {
        final ringR = r * (1.3 + i * 0.3 + heatPulse * 0.15);
        _heatRingPaint.color = const Color(0xFFFF6600)
            .withValues(alpha: (0.18 - i * 0.05) * heatPulse);
        _heatRingPaint.strokeWidth = 1.5;
        canvas.drawCircle(Offset(cx, cy), ringR, _heatRingPaint);
      }
    }

    // ─── EMBER PARTICELLE (braci che salgono attorno) ───
    if (scale <= 1.01) {
      for (int i = 0; i < 10; i++) {
        final ePhase = _flamePhase * 0.6 + i * 0.7;
        final eAngle = ePhase % (math.pi * 2);
        final eDist = r * (1.15 + ((ePhase * 0.3) % 1.0) * 0.6);
        final eAlpha = (1.0 - ((ePhase * 0.3) % 1.0)) * 0.9;
        _emberPaint.color = const Color(0xFFFFAA00).withValues(alpha: eAlpha);
        canvas.drawCircle(
          Offset(cx + math.cos(eAngle) * eDist,
              cy + math.sin(eAngle) * eDist),
          1.5 + (i % 3) * 0.5,
          _emberPaint,
        );
      }
    }

    // ─── STELLA A 5 PUNTE CON FIAMME ───
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(_flamePhase * 0.1);

    final starPath = Path();
    for (int i = 0; i < 10; i++) {
      final angle = i * math.pi / 5 - math.pi / 2;
      final flameWobble = i % 2 == 0 ? math.sin(_flamePhase + i) * 3 : 0.0;
      final starR = i % 2 == 0 ? r * 0.85 + flameWobble : r * 0.4;
      final x = starR * math.cos(angle);
      final y = starR * math.sin(angle);
      if (i == 0) {
        starPath.moveTo(x, y);
      } else {
        starPath.lineTo(x, y);
      }
    }
    starPath.close();
    canvas.drawPath(starPath, paint);

    if (scale <= 1.01) {
      // Nucleo incandescente a 3 strati (fuoco vero)
      final pulse = 0.7 + math.sin(_flamePhase * 0.5) * 0.3;
      _coreGlowPaint.color =
          const Color(0xFFFF8800).withValues(alpha: pulse * 0.6);
      canvas.drawCircle(Offset.zero, r * 0.38, _coreGlowPaint);
      _corePaint.color = const Color(0xFFFFDD00).withValues(alpha: pulse);
      canvas.drawCircle(Offset.zero, r * 0.25, _corePaint);
      _coreWhitePaint.color =
          const Color(0xFFFFFFFF).withValues(alpha: 0.85 * pulse);
      canvas.drawCircle(Offset.zero, r * 0.11, _coreWhitePaint);
    }
    canvas.restore();
  }
}

class _FlameTrail {
  Vector2 position;
  double lifetime;
  double damageTimer = 0; // FIX H9: cooldown per evitare 60 hit/sec
  _FlameTrail({required this.position, required this.lifetime});
}

class _FireBullet extends PositionComponent with HasGameReference<GeometryFightGame> {
  final Vector2 direction;
  late Vector2 _velocity;
  double _lifetime = 3.0;

  _FireBullet({required this.direction})
      : super(size: Vector2(18, 18), anchor: Anchor.center);

  @override
  Future<void> onLoad() async { _velocity = direction.normalized() * 200; }

  @override
  void update(double dt) {
    super.update(dt);
    position += _velocity * dt;
    _lifetime -= dt;
    if (_lifetime <= 0) removeFromParent();
    if (position.distanceTo(game.player.position) < 14) {
      game.player.takeDamage();
      removeFromParent();
    }
  }

  static final _bulletPaint = Paint();
  static final _bulletCorePaint = Paint();

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    _bulletPaint.color = const Color(0xFFFF6600).withValues(alpha: 0.3);
    canvas.drawCircle(Offset(cx, cy), 8, _bulletPaint);
    _bulletPaint.color = const Color(0xFFFF6600);
    canvas.drawCircle(Offset(cx, cy), 6, _bulletPaint);
    _bulletCorePaint.color = const Color(0xFFFFFFFF).withValues(alpha: 0.7);
    canvas.drawCircle(Offset(cx, cy), 3, _bulletCorePaint);
  }
}

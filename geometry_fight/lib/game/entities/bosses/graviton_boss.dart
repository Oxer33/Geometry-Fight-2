import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../../data/constants.dart';
import '../../../data/wave_configs.dart';
import '../../game_world.dart';
import 'boss_base.dart';

/// GRAVITON - Boss che manipola la gravità, attira e respinge tutto.
/// Forma: sfera nera con anelli gravitazionali multipli e particelle aspirate
/// Colore: viola scuro con bordo dorato (#220044 + #FFD700)
/// HP: 2200 · 3 fasi
/// Meccanica: alterna tra fase PULL (aspira player e proiettili) e PUSH (respinge tutto).
class GravitonBoss extends BossBase {
  double _gravPhase = 0;
  double _pullPushTimer = 4.0;
  bool _isPulling = true;
  double _attackTimer = 2.0;
  static const double _gravityRadius = 350.0;

  // Cached paints — avoid per-frame allocations in renderBoss
  static final _fieldPaint = Paint();
  static final _particlePaint = Paint();
  static final _ringPaint = Paint()..style = PaintingStyle.stroke;
  static final _spherePaint = Paint();
  static final _borderPaint = Paint()..style = PaintingStyle.stroke;
  static final _corePaint = Paint();
  static final _indicatorPaint = Paint();
  // Signature FX paints
  static final _lensingPaint = Paint()..style = PaintingStyle.stroke;
  static final _filamentPaint = Paint()..style = PaintingStyle.stroke;
  static final _horizonHaloPaint = Paint();
  static final _coreGlowPaint = Paint();

  GravitonBoss()
      : super(
          hp: 2200,
          bossName: 'GRAVITON',
          pointValue: 4500,
          neonColor: const Color(0xFF220044),
          size: Vector2(100, 100),
        );

  // Graviton è VIOLA GRAVITÀ → mob orbitali (orbiter + proton + gravityWell).
  @override
  List<EnemyType> get colorMatchedMinions =>
      const [EnemyType.orbiter, EnemyType.proton, EnemyType.gravityWell];

  @override
  int getPhase() {
    if (healthPercent > 0.6) return 0;
    if (healthPercent > 0.3) return 1;
    return 2;
  }

  @override
  void updateBoss(double dt) {
    _gravPhase += dt * 3;

    // Alterna pull/push
    _pullPushTimer -= dt;
    if (_pullPushTimer <= 0) {
      _isPulling = !_isPulling;
      _pullPushTimer = _isPulling ? 4.0 : 2.5;
      game.triggerScreenShake(3, 0.15);
    }

    // Applica gravità al player
    final toPlayer = playerPosition - position;
    final dist = toPlayer.length;
    if (dist < _gravityRadius && dist > 10) {
      final strength = 120 * dt * (1 - dist / _gravityRadius);
      // Pull: muove il player VERSO il boss (direzione opposta a toPlayer)
      // Push: muove il player LONTANO dal boss (stessa direzione di toPlayer)
      final dir = _isPulling ? -1.0 : 1.0;
      game.player.position += toPlayer.normalized() * strength * dir;
    }

    // Distorci griglia
    if (!game.isTunnelMode) {
      if (_isPulling) {
        game.grid.applyAttraction(position, _gravityRadius * 0.5, 200 * dt);
      } else {
        game.grid.applyForce(position, _gravityRadius * 0.5, 200 * dt);
      }
    }

    // Movimento lento verso centro arena (o camera in tunnel mode)
    final center = game.isTunnelMode
        ? game.camera.viewfinder.position
        : Vector2(arenaWidth / 2, arenaHeight / 2);
    final toCenter = center - position;
    if (toCenter.length > 100) {
      position += toCenter.normalized() * 30 * dt;
    }

    // Attacco
    _attackTimer -= dt;
    if (_attackTimer <= 0) {
      _attackTimer = 2.0 - currentPhase * 0.3;
      _shootGravityBurst();
    }
  }

  void _shootGravityBurst() {
    final count = 8 + currentPhase * 4;
    for (int i = 0; i < count; i++) {
      final angle = i * math.pi * 2 / count + _gravPhase * 0.1;
      final dir = Vector2(math.cos(angle), math.sin(angle));
      final bullet = _GravBullet(direction: dir, color: const Color(0xFFFFD700));
      bullet.position = position.clone();
      game.world.add(bullet);
    }
  }

  @override
  void renderBoss(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final r = size.x / 2 * scale;

    // Campo gravitazionale visibile
    if (scale <= 1.01) {
      _fieldPaint.color = _isPulling
          ? const Color(0xFF4400AA).withValues(alpha: 0.08)
          : const Color(0xFFFFD700).withValues(alpha: 0.06);
      canvas.drawCircle(Offset(cx, cy), _gravityRadius * 0.4, _fieldPaint);

      // Particelle aspirate/respinte
      for (int i = 0; i < 12; i++) {
        final pAngle = _gravPhase * (_isPulling ? 1.5 : -1.5) + i * math.pi / 6;
        final pProgress = (_gravPhase * 0.5 + i * 0.2) % 1.0;
        final pDist = _isPulling
            ? r * 2 * (1 - pProgress) // Verso il centro
            : r * 0.5 + r * 2 * pProgress; // Dal centro
        final px = cx + pDist * math.cos(pAngle);
        final py = cy + pDist * math.sin(pAngle);
        final pAlpha = _isPulling ? pProgress * 0.3 : (1 - pProgress) * 0.3;
        _particlePaint.color = const Color(0xFFFFD700).withValues(alpha: pAlpha);
        canvas.drawCircle(Offset(px, py), 1.5, _particlePaint);
      }
    }

    // Anelli gravitazionali rotanti
    for (int ring = 0; ring < 3; ring++) {
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(_gravPhase * (0.3 + ring * 0.2) * (_isPulling ? 1 : -1));
      _ringPaint.color = const Color(0xFFFFD700).withValues(alpha: 0.3 - ring * 0.08);
      _ringPaint.strokeWidth = (2 - ring * 0.5) * scale;
      canvas.drawCircle(Offset.zero, r * (0.6 + ring * 0.15), _ringPaint);
      canvas.restore();
    }

    // ─── LENSING RINGS: 4 cerchi stroke oro esterni (distorsione spazio) ───
    if (scale <= 1.01) {
      for (int i = 0; i < 4; i++) {
        final ringR = r * (1.3 + i * 0.22);
        _lensingPaint.color = const Color(0xFFFFD700)
            .withValues(alpha: (0.2 - i * 0.04) * (0.7 + math.sin(_gravPhase + i) * 0.3));
        _lensingPaint.strokeWidth = 1;
        canvas.drawCircle(Offset(cx, cy), ringR, _lensingPaint);
      }
    }

    // ─── FILAMENT BEAMS (8 raggi dorati dalla sfera verso l'esterno) ───
    if (scale <= 1.01) {
      _filamentPaint.strokeWidth = 1.2;
      for (int i = 0; i < 8; i++) {
        final fAngle = _gravPhase * (_isPulling ? 0.8 : -0.8) + i * math.pi / 4;
        final fPulse = 0.4 + math.sin(_gravPhase * 3 + i * 0.5) * 0.4;
        final fLen = r * (0.55 + fPulse * 0.6);
        _filamentPaint.color = const Color(0xFFFFD700)
            .withValues(alpha: fPulse);
        canvas.drawLine(
          Offset(cx + math.cos(fAngle) * r * 0.42,
              cy + math.sin(fAngle) * r * 0.42),
          Offset(cx + math.cos(fAngle) * fLen,
              cy + math.sin(fAngle) * fLen),
          _filamentPaint,
        );
      }
    }

    // ─── HORIZON HALO: alone dorato/viola dietro la sfera ───
    if (scale <= 1.01) {
      _horizonHaloPaint.color = _isPulling
          ? const Color(0xFF6611CC).withValues(alpha: 0.45)
          : const Color(0xFFFFD700).withValues(alpha: 0.45);
      canvas.drawCircle(Offset(cx, cy), r * 0.55, _horizonHaloPaint);
    }

    // Sfera nera centrale (event horizon)
    _spherePaint.color = const Color(0xFF000011);
    canvas.drawCircle(Offset(cx, cy), r * 0.4, _spherePaint);
    // Bordo dorato
    _borderPaint.color = const Color(0xFFFFD700).withValues(alpha: 0.75);
    _borderPaint.strokeWidth = 2 * scale;
    canvas.drawCircle(Offset(cx, cy), r * 0.4, _borderPaint);

    // ─── CORE multi-strato (glow + core + pupilla) ───
    if (scale <= 1.01) {
      final pulse = (_isPulling ? 0.7 : 0.4) +
          math.sin(_gravPhase * 4) * 0.2;
      _coreGlowPaint.color =
          const Color(0xFFFFD700).withValues(alpha: pulse * 0.5);
      canvas.drawCircle(Offset(cx, cy), r * 0.25, _coreGlowPaint);
      _corePaint.color =
          const Color(0xFFFFD700).withValues(alpha: pulse);
      canvas.drawCircle(Offset(cx, cy), r * 0.15 * pulse, _corePaint);
      // Pupilla bianca
      _corePaint.color =
          const Color(0xFFFFFFFF).withValues(alpha: pulse);
      canvas.drawCircle(Offset(cx, cy), r * 0.06, _corePaint);

      // Indicatore pull/push
      final indicatorColor = _isPulling
          ? const Color(0xFF6611CC)
          : const Color(0xFFFFD700);
      _indicatorPaint.color = indicatorColor;
      canvas.drawCircle(Offset(cx, cy - r * 0.55), 3, _indicatorPaint);
    }
  }
}

class _GravBullet extends PositionComponent with HasGameReference<GeometryFightGame> {
  final Vector2 direction;
  final Color color;
  late Vector2 _velocity;
  double _lifetime = 4.0;

  _GravBullet({required this.direction, required this.color})
      : super(size: Vector2(7, 7), anchor: Anchor.center);

  @override
  Future<void> onLoad() async { _velocity = direction.normalized() * 180; }

  @override
  void update(double dt) {
    super.update(dt);
    position += _velocity * dt;
    _lifetime -= dt;
    if (_lifetime <= 0) removeFromParent();
    if (position.distanceTo(game.player.position) < 10) {
      game.player.takeDamage();
      removeFromParent();
    }
  }

  static final _bulletPaint = Paint();
  static final _bulletCorePaint = Paint();

  @override
  void render(Canvas canvas) {
    _bulletPaint.color = color;
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), 3.5, _bulletPaint);
    _bulletCorePaint.color = const Color(0xFFFFFFFF).withValues(alpha: 0.7);
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), 1.5, _bulletCorePaint);
  }
}

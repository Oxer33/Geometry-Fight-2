import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import '../../../data/constants.dart';
import '../../../data/wave_configs.dart';
import 'boss_base.dart';
import '../projectiles.dart';

// Hitbox raggio unificato: copre corpo (size 120 → radius 60) + orbita teste
// (80px offset + 12px testa). 100 = corpo + metà orbita → colpi teste contano.
const double _kHitboxRadius = 100;

// Rage mode: fire rate radiale. 3 bullet × 1/0.18s ≈ 16.6/s. Non scendere
// sotto 0.18 senza cap a livello di game (saturerebbe canvas).
const double _kRageShootInterval = 0.18;

// Random statico condiviso — evita `math.Random()` allocato per head e per
// attack tick (perf).
final math.Random _hydraRng = math.Random();

class _HydraHead {
  Vector2 position;
  double attackTimer;
  int attackType;

  _HydraHead()
      : position = Vector2.zero(),
        attackTimer = 2.0 + _hydraRng.nextDouble() * 2,
        attackType = _hydraRng.nextInt(4);
}

/// HYDRA (rework richiesta utente):
///   - Parte con 1 testa.
///   - Ogni 25% di HP persa spawna una nuova testa (max 3).
///   - Teste posizionate a 120° l'una dall'altra (orbita intorno al corpo).
///   - Ultimo 25% di HP: teste eliminate + enrage mode (fuoco continuo rosso).
///   - Hitbox unificato: colpire le teste o il corpo è equivalente (stesso HP).
///
/// Distribuzione HP → teste:
///   100%–75% → 1 testa
///    75%–50% → 2 teste
///    50%–25% → 3 teste
///     <25%   → 0 teste + enrage
class HydraBoss extends BossBase {
  final List<_HydraHead> _heads = [];
  int _headCount = 1; // parte con 1 testa (richiesta utente)
  double _ragePhase = 0;
  bool _rageMode = false;
  double _rageShootTimer = 0;

  // Cached Paint objects to avoid per-frame allocations
  static final _tentaclePaint = Paint()..style = PaintingStyle.stroke;
  static final _tentacleGlowPaint = Paint()..style = PaintingStyle.stroke;
  static final _tentacleShimmerPaint = Paint();
  static final _ragePaint = Paint();
  static final _headGlowPaint = Paint();
  static final _headIrisPaint = Paint();
  static final _headFangPaint = Paint()..style = PaintingStyle.stroke;
  static final _corePulsePaint = Paint();
  static final _tentaclePath = Path();

  HydraBoss()
      : super(
          // HP unificato 1000 — tutti gli hit (teste o corpo) convergono qui.
          // Fight lineare, niente HP separato per testa.
          hp: 1000,
          bossName: 'HYDRA',
          pointValue: 8000,
          neonColor: NeonColors.green,
          size: Vector2(120, 120),
        );

  @override
  Future<void> onLoad() async {
    // Chiamo super.onLoad() per non perdere eventuali side-effects futuri
    // di BossBase.onLoad, poi rimuovo l'hitbox standard e ne aggiungo uno
    // più grande che copre anche l'orbita delle teste.
    await super.onLoad();
    children.whereType<CircleHitbox>().toList().forEach((h) => h.removeFromParent());
    add(CircleHitbox(radius: _kHitboxRadius, anchor: Anchor.center)
      ..position = size / 2);
    // Parte con 1 testa.
    _syncHeads();
  }

  // Disabilita minion spawn in rage mode: il boss già spara 16 bullet/s
  // radiali, aggiungere mob saturerebbe il canvas e lagga device medi.
  @override
  bool get allowMinionSpawn => !_rageMode;

  /// Allinea il numero di teste concrete a `_headCount`.
  void _syncHeads() {
    while (_heads.length < _headCount) {
      _heads.add(_HydraHead());
    }
    if (_heads.length > _headCount) {
      _heads.removeRange(_headCount, _heads.length);
    }
  }

  /// Calcola quante teste dovrebbero esistere data la % HP attuale.
  int _computeHeadCount() {
    final p = healthPercent;
    if (p <= 0.25) return 0; // rage mode
    if (p <= 0.50) return 3;
    if (p <= 0.75) return 2;
    return 1;
  }

  @override
  int getPhase() {
    if (_rageMode) return 3;
    if (healthPercent < 0.50) return 2;
    if (healthPercent < 0.75) return 1;
    return 0;
  }

  @override
  void updateBoss(double dt) {
    _ragePhase += dt;

    // ─── GESTIONE TESTE IN BASE AD HP ──────────────────────────────────
    final targetCount = _computeHeadCount();
    if (targetCount != _headCount) {
      if (targetCount == 0) {
        // Transizione a rage: esplodi le teste rimaste con FX drammatico.
        for (final h in _heads) {
          game.spawnExplosion(position + h.position, NeonColors.red,
              radius: 50, particleCount: 12);
        }
        _heads.clear();
        _headCount = 0;
        _rageMode = true;
        game.triggerScreenShake(8, 0.4);
      } else if (targetCount > _headCount) {
        // Nuova testa: FX di materializzazione.
        _headCount = targetCount;
        _syncHeads();
        game.spawnExplosion(position, NeonColors.green,
            radius: 70, particleCount: 15);
        game.triggerScreenShake(5, 0.25);
      }
      // Caso "diminuzione non-rage" omesso: HP è monotono decrescente,
      // targetCount < _headCount senza rage non può accadere.
    }

    // ─── MOVIMENTO CORPO ───────────────────────────────────────────────
    final dir = (playerPosition - position);
    if (dir.length > 200) {
      position += dir.normalized() * 40 * dt;
    }

    // ─── ORBITA TESTE + ATTACCO ────────────────────────────────────────
    // Angoli equispaziati: 360°/N → 120° per 3 teste, 180° per 2, 1 per 1.
    for (int i = 0; i < _heads.length; i++) {
      final head = _heads[i];
      final stepAngle = math.pi * 2 / _heads.length;
      final baseAngle = i * stepAngle + _ragePhase * 0.5;
      final wobble = math.sin(_ragePhase * 2 + i * 1.5) * 15;
      head.position = Vector2(
        math.cos(baseAngle) * (80 + wobble),
        math.sin(baseAngle) * (80 + wobble),
      );

      head.attackTimer -= dt;
      if (head.attackTimer <= 0) {
        head.attackTimer = 2.0 + _hydraRng.nextDouble() * 1.5;
        _headAttack(head, i);
      }
    }

    // ─── RAGE MODE: FUOCO CONTINUO ─────────────────────────────────────
    if (_rageMode) {
      _rageShootTimer -= dt;
      if (_rageShootTimer <= 0) {
        _rageShootTimer = _kRageShootInterval;
        // 3 raffiche radiali simultanee (tri-stella rotante).
        for (int i = 0; i < 3; i++) {
          final angle = _ragePhase * 5 + i * (math.pi * 2 / 3);
          final bdir = Vector2(math.cos(angle), math.sin(angle));
          final bullet = EnemyBullet(
              direction: bdir, speed: 320, color: NeonColors.red);
          bullet.position = position.clone();
          game.world.add(bullet);
        }
      }
    }
  }

  void _headAttack(_HydraHead head, int index) {
    final headWorldPos = position + head.position;

    switch (head.attackType) {
      case 0: // Radial burst
        for (int i = 0; i < 8; i++) {
          final angle = i * math.pi / 4;
          final bdir = Vector2(math.cos(angle), math.sin(angle));
          final bullet = EnemyBullet(
              direction: bdir, speed: 200, color: NeonColors.green);
          bullet.position = headWorldPos.clone();
          game.world.add(bullet);
        }
      case 1: // Tracking burst
        final toPlayer = (playerPosition - headWorldPos).normalized();
        for (int i = 0; i < 5; i++) {
          final bullet = EnemyBullet(
            direction: toPlayer,
            speed: 250 + i * 30.0,
            color: NeonColors.green,
          );
          bullet.position = headWorldPos.clone();
          game.world.add(bullet);
        }
      case 2: // Spawn snakes
        for (int i = 0; i < 2; i++) {
          game.spawnEnemy(
              EnemyType.snake,
              headWorldPos +
                  Vector2(
                    (_hydraRng.nextDouble() - 0.5) * 40,
                    (_hydraRng.nextDouble() - 0.5) * 40,
                  ));
        }
      case 3: // Tracking fan: 3 bullet verso il player
        final baseAngle = math.atan2(playerPosition.y - headWorldPos.y,
            playerPosition.x - headWorldPos.x);
        for (final offset in [-0.12, 0.0, 0.12]) {
          final angle = baseAngle + offset;
          final bdir = Vector2(math.cos(angle), math.sin(angle));
          final bullet = EnemyBullet(
              direction: bdir, speed: 350, color: NeonColors.cyan);
          bullet.position = headWorldPos.clone();
          game.world.add(bullet);
        }
    }
  }

  // takeDamage NON viene sovrascritto: tutti gli hit passano dall'hitbox
  // unificato → BossBase.takeDamage → hp. Nessuna differenza testa vs corpo.

  @override
  void renderBoss(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final centerPoint = Offset(cx, cy);

    // ─── TENTACOLI + TESTE ───────────────────────────────────────────
    for (int i = 0; i < _heads.length; i++) {
      final head = _heads[i];

      final endPoint = Offset(cx + head.position.x, cy + head.position.y);
      final controlPoint = Offset(
        (centerPoint.dx + endPoint.dx) / 2 +
            math.sin(_ragePhase * 3 + i) * 20,
        (centerPoint.dy + endPoint.dy) / 2 +
            math.cos(_ragePhase * 3 + i) * 20,
      );

      _tentaclePath.reset();
      _tentaclePath.moveTo(centerPoint.dx, centerPoint.dy);
      _tentaclePath.quadraticBezierTo(
          controlPoint.dx, controlPoint.dy, endPoint.dx, endPoint.dy);

      // Glow esterno tentacolo
      _tentacleGlowPaint.color =
          neonColor.withValues(alpha: paint.color.a * 0.35);
      _tentacleGlowPaint.strokeWidth = 9 * scale;
      canvas.drawPath(_tentaclePath, _tentacleGlowPaint);

      // Tentacolo principale
      _tentaclePaint.color = neonColor.withValues(alpha: paint.color.a);
      _tentaclePaint.strokeWidth = 3 * scale;
      canvas.drawPath(_tentaclePath, _tentaclePaint);

      // Shimmer bianco che viaggia lungo il tentacolo.
      final shimmerT = (_ragePhase * 1.8 + i * 0.4) % 1.0;
      final shimmerPoint = _pointOnQuadBezier(
          centerPoint, controlPoint, endPoint, shimmerT);
      _tentacleShimmerPaint.color =
          const Color(0xFFFFFFFF).withValues(alpha: 0.7 * paint.color.a);
      canvas.drawCircle(shimmerPoint, 3 * scale, _tentacleShimmerPaint);

      // ─── TESTA ──────────────────────────────────────────────────
      final headPulse = 0.7 + math.sin(_ragePhase * 4 + i * 1.3) * 0.3;
      _headGlowPaint.color =
          neonColor.withValues(alpha: paint.color.a * 0.35 * headPulse);
      canvas.drawCircle(endPoint, 20 * scale, _headGlowPaint);
      canvas.drawCircle(endPoint, 12 * scale, paint);
      _headIrisPaint.color = const Color(0xFFFF6622)
          .withValues(alpha: paint.color.a * 0.85);
      canvas.drawCircle(endPoint, 5 * scale * headPulse, _headIrisPaint);
      _headIrisPaint.color =
          const Color(0xFFFFFFFF).withValues(alpha: paint.color.a);
      canvas.drawCircle(endPoint, 2 * scale, _headIrisPaint);

      _headFangPaint.color = paint.color;
      _headFangPaint.strokeWidth = 1.2 * scale;
      final fangBase = endPoint.dy + 10 * scale;
      canvas.drawLine(
          Offset(endPoint.dx - 4 * scale, fangBase),
          Offset(endPoint.dx - 2 * scale, fangBase + 6 * scale),
          _headFangPaint);
      canvas.drawLine(
          Offset(endPoint.dx + 4 * scale, fangBase),
          Offset(endPoint.dx + 2 * scale, fangBase + 6 * scale),
          _headFangPaint);
    }

    // ─── NUCLEO CENTRALE ─────────────────────────────────────────────
    final corePulse = 0.85 + math.sin(_ragePhase * 5) * 0.15;
    _corePulsePaint.color =
        neonColor.withValues(alpha: paint.color.a * 0.4 * corePulse);
    canvas.drawCircle(centerPoint, 35 * scale * corePulse, _corePulsePaint);
    canvas.drawCircle(centerPoint, 25 * scale, paint);
    _corePulsePaint.color =
        const Color(0xFFFFFFFF).withValues(alpha: paint.color.a * corePulse);
    canvas.drawCircle(centerPoint, 10 * scale * corePulse, _corePulsePaint);

    // ─── RAGE MODE: corona rossa + spike pulsanti ────────────────────
    if (_rageMode) {
      final rageStrobe = 0.25 + math.sin(_ragePhase * 12) * 0.15;
      _ragePaint.color =
          NeonColors.red.withValues(alpha: rageStrobe * paint.color.a);
      canvas.drawCircle(centerPoint, 50 * scale, _ragePaint);
      for (int s = 0; s < 8; s++) {
        final angle = s * math.pi / 4 + _ragePhase * 0.5;
        final len = 48 * scale + math.sin(_ragePhase * 6 + s) * 8 * scale;
        _ragePaint.color = NeonColors.red
            .withValues(alpha: (0.4 + rageStrobe) * paint.color.a);
        canvas.drawCircle(
          Offset(centerPoint.dx + math.cos(angle) * len,
              centerPoint.dy + math.sin(angle) * len),
          2.5 * scale,
          _ragePaint,
        );
      }
    }
  }

  /// Punto lungo una curva Bezier quadratica a parametro `t` (0..1).
  static Offset _pointOnQuadBezier(Offset p0, Offset p1, Offset p2, double t) {
    final u = 1 - t;
    return Offset(
      u * u * p0.dx + 2 * u * t * p1.dx + t * t * p2.dx,
      u * u * p0.dy + 2 * u * t * p1.dy + t * t * p2.dy,
    );
  }
}

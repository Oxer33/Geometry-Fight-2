import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../../data/constants.dart';
import '../../../data/wave_configs.dart';
import 'boss_base.dart';
import '../projectiles.dart';

// Random statico condiviso — evita `math.Random()` allocato per head e per
// attack tick (perf: hydra spara 4 attacchi/sec × 4 teste).
final math.Random _hydraRng = math.Random();

class _HydraHead {
  Vector2 position;
  double hp;
  final double maxHp;
  double attackTimer;
  bool alive;
  double deathTime;
  int attackType;

  // HP per testa ridotto da 150 a 80 → boss #2 più gestibile (era ~1400 HP
  // effettivi tra corpo 800 + 4 teste x 150; ora corpo 500 + 4 teste x 80 =
  // 820 HP totali, ~40% in meno).
  _HydraHead({required this.position, this.hp = 80})
      : maxHp = hp,
        attackTimer = 2.0 + _hydraRng.nextDouble() * 2,
        alive = true,
        deathTime = 0,
        attackType = _hydraRng.nextInt(4);
}

class HydraBoss extends BossBase {
  final List<_HydraHead> _heads = [];
  double _ragePhase = 0;
  bool _rageMode = false;
  double _rageShootTimer = 0;

  // Cached Paint objects to avoid per-frame allocations
  static final _tentaclePaint = Paint()..style = PaintingStyle.stroke;
  static final _tentacleGlowPaint = Paint()..style = PaintingStyle.stroke;
  // `_tentacleShimmerPaint` renderizza SOLO `drawCircle` (fill) → style stroke
  // era inutile (strokeWidth su drawCircle non è usato). Default fill.
  static final _tentacleShimmerPaint = Paint();
  static final _ragePaint = Paint();
  static final _headGlowPaint = Paint();
  static final _headIrisPaint = Paint();
  static final _headFangPaint = Paint()..style = PaintingStyle.stroke;
  static final _corePulsePaint = Paint();
  // Path condiviso per i tentacoli (4 teste → 4 Path/frame risparmiati).
  // `reset()` prima di ogni uso.
  static final _tentaclePath = Path();

  HydraBoss()
      : super(
          // hp: 600 body + 4×80 teste = 920 HP totali. No regen (vedi sotto),
          // fight progredisce lineare invece di stallare.
          hp: 600,
          bossName: 'HYDRA',
          pointValue: 8000,
          neonColor: NeonColors.green,
          size: Vector2(120, 120),
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Create 4 heads
    for (int i = 0; i < 4; i++) {
      final angle = i * math.pi / 2;
      _heads.add(_HydraHead(
        position: Vector2(math.cos(angle) * 80, math.sin(angle) * 80),
      ));
    }
  }

  @override
  int getPhase() {
    final aliveHeads = _heads.where((h) => h.alive).length;
    if (aliveHeads == 0) return 2; // Rage mode
    if (healthPercent < 0.4) return 1;
    return 0;
  }

  @override
  void onPhaseChange(int phase) {
    if (phase == 2) {
      _rageMode = true;
    }
  }

  @override
  void updateBoss(double dt) {
    _ragePhase += dt;

    // Move slowly
    final dir = (playerPosition - position);
    if (dir.length > 200) {
      position += dir.normalized() * 40 * dt;
    }

    // Update heads — regen rimosso: teste morte restano morte. Prima con
    // regen 5s il fight stallava se il player non killava tutte le teste
    // entro la finestra. Ora progresso garantito lineare.
    for (int i = 0; i < _heads.length; i++) {
      final head = _heads[i];
      if (!head.alive) {
        continue;
      }

      // Animate head position (tentacle movement)
      final baseAngle = i * math.pi / 2 + _ragePhase * 0.5;
      final wobble = math.sin(_ragePhase * 2 + i * 1.5) * 15;
      head.position = Vector2(
        math.cos(baseAngle) * (80 + wobble),
        math.sin(baseAngle) * (80 + wobble),
      );

      // Attack
      head.attackTimer -= dt;
      if (head.attackTimer <= 0) {
        head.attackTimer = 2.0 + _hydraRng.nextDouble() * 1.5;
        _headAttack(head, i);
      }
    }

    // Check if all heads died within 3s of each other
    // (simplified: just check if all are dead)
    final deadHeads = _heads.where((h) => !h.alive).toList();
    if (deadHeads.length == 4) {
      // All dead - prevent regen, go to rage mode
      _rageMode = true;
    }

    // Rage mode — rate 0.25s (4 bullet/sec invece di 10) per contenere lag
    // + leggibilità. Sparo a spirale pseudo-casuale attorno al boss.
    if (_rageMode) {
      _rageShootTimer -= dt;
      if (_rageShootTimer <= 0) {
        _rageShootTimer = 0.25;
        final angle = _ragePhase * 5;
        final dir = Vector2(math.cos(angle), math.sin(angle));
        final bullet = EnemyBullet(direction: dir, speed: 300, color: NeonColors.green);
        bullet.position = position.clone();
        game.world.add(bullet);
      }
    }
  }

  void _headAttack(_HydraHead head, int index) {
    final headWorldPos = position + head.position;

    switch (head.attackType) {
      case 0: // Radial burst
        for (int i = 0; i < 8; i++) {
          final angle = i * math.pi / 4;
          final dir = Vector2(math.cos(angle), math.sin(angle));
          final bullet = EnemyBullet(direction: dir, speed: 200, color: NeonColors.green);
          bullet.position = headWorldPos.clone();
          game.world.add(bullet);
        }
      case 1: // Tracking laser-like burst
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
          game.spawnEnemy(EnemyType.snake, headWorldPos + Vector2(
            (_hydraRng.nextDouble() - 0.5) * 40,
            (_hydraRng.nextDouble() - 0.5) * 40,
          ));
        }
      case 3: // Tracking fan: 3 bullet spread verso il player
        final baseAngle = math.atan2(
            playerPosition.y - headWorldPos.y,
            playerPosition.x - headWorldPos.x);
        for (final offset in [-0.12, 0.0, 0.12]) {
          final angle = baseAngle + offset;
          final dir = Vector2(math.cos(angle), math.sin(angle));
          final bullet = EnemyBullet(
              direction: dir, speed: 350, color: NeonColors.cyan);
          bullet.position = headWorldPos.clone();
          game.world.add(bullet);
        }
    }
  }

  @override
  void takeDamage(double amount, {bool isArea = false}) {
    // Distribuisce il danno alla prima testa viva
    bool hitHead = false;
    for (final head in _heads) {
      if (!head.alive) continue;
      final headWorldPos = position + head.position;
      head.hp -= amount;
      if (head.hp <= 0) {
        head.alive = false;
        head.deathTime = 0;
        game.spawnExplosion(headWorldPos, NeonColors.green, radius: 30);
      }
      hitHead = true;
      break; // Solo la prima testa prende danno
    }

    // Se nessuna testa viva, danno pieno al corpo; altrimenti ridotto
    super.takeDamage(hitHead ? amount * 0.15 : amount, isArea: isArea);
  }

  @override
  void renderBoss(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final centerPoint = Offset(cx, cy);

    // ─── TENTACOLI + TESTE ───────────────────────────────────────────
    for (int i = 0; i < _heads.length; i++) {
      final head = _heads[i];
      if (!head.alive) continue;

      final endPoint = Offset(cx + head.position.x, cy + head.position.y);
      final controlPoint = Offset(
        (centerPoint.dx + endPoint.dx) / 2 +
            math.sin(_ragePhase * 3 + i) * 20,
        (centerPoint.dy + endPoint.dy) / 2 +
            math.cos(_ragePhase * 3 + i) * 20,
      );

      // Path condiviso: reset + refill invece di alloc. Risparmia 4 Path/frame
      // (uno per testa viva) × 60fps = 240 Path/sec.
      _tentaclePath.reset();
      _tentaclePath.moveTo(centerPoint.dx, centerPoint.dy);
      _tentaclePath.quadraticBezierTo(
          controlPoint.dx, controlPoint.dy, endPoint.dx, endPoint.dy);

      // Glow esterno tentacolo (spesso + alpha basso)
      _tentacleGlowPaint.color =
          neonColor.withValues(alpha: paint.color.a * 0.35);
      _tentacleGlowPaint.strokeWidth = 9 * scale;
      canvas.drawPath(_tentaclePath, _tentacleGlowPaint);

      // Tentacolo principale
      _tentaclePaint.color = neonColor.withValues(alpha: paint.color.a);
      _tentaclePaint.strokeWidth = 3 * scale;
      canvas.drawPath(_tentaclePath, _tentaclePaint);

      // Shimmer bianco che viaggia lungo il tentacolo (pulse animato).
      final shimmerT = (_ragePhase * 1.8 + i * 0.4) % 1.0;
      final shimmerPoint = _pointOnQuadBezier(
          centerPoint, controlPoint, endPoint, shimmerT);
      _tentacleShimmerPaint.color =
          const Color(0xFFFFFFFF).withValues(alpha: 0.7 * paint.color.a);
      canvas.drawCircle(shimmerPoint, 3 * scale, _tentacleShimmerPaint);

      // ─── TESTA: glow + iris + fangs ─────────────────────────────
      final headPulse = 0.7 + math.sin(_ragePhase * 4 + i * 1.3) * 0.3;
      // Glow esterno (senza blur)
      _headGlowPaint.color =
          neonColor.withValues(alpha: paint.color.a * 0.35 * headPulse);
      canvas.drawCircle(endPoint, 20 * scale, _headGlowPaint);
      // Corpo testa
      canvas.drawCircle(endPoint, 12 * scale, paint);
      // Iris minaccioso rosso al centro (pupilla)
      _headIrisPaint.color = _rageMode
          ? const Color(0xFFFF2200).withValues(alpha: paint.color.a)
          : const Color(0xFFFF6622).withValues(alpha: paint.color.a * 0.85);
      canvas.drawCircle(endPoint, 5 * scale * headPulse, _headIrisPaint);
      _headIrisPaint.color =
          const Color(0xFFFFFFFF).withValues(alpha: paint.color.a);
      canvas.drawCircle(endPoint, 2 * scale, _headIrisPaint);

      // Zanne: 2 tratti triangolari sotto la testa (versione semplice)
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

    // ─── NUCLEO CENTRALE (pulsante) ──────────────────────────────────
    final corePulse = 0.85 + math.sin(_ragePhase * 5) * 0.15;
    // Halo cromatico dietro al core
    _corePulsePaint.color =
        neonColor.withValues(alpha: paint.color.a * 0.4 * corePulse);
    canvas.drawCircle(centerPoint, 35 * scale * corePulse, _corePulsePaint);
    canvas.drawCircle(centerPoint, 25 * scale, paint);
    // Nucleo interno bianco pulsante
    _corePulsePaint.color =
        const Color(0xFFFFFFFF).withValues(alpha: paint.color.a * corePulse);
    canvas.drawCircle(centerPoint, 10 * scale * corePulse, _corePulsePaint);

    // ─── RAGE MODE CORONA ────────────────────────────────────────────
    if (_rageMode) {
      final rageStrobe = 0.25 + math.sin(_ragePhase * 12) * 0.15;
      _ragePaint.color = NeonColors.red
          .withValues(alpha: rageStrobe * paint.color.a);
      canvas.drawCircle(centerPoint, 50 * scale, _ragePaint);
      // Spike corona: 8 raggi che pulsano
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

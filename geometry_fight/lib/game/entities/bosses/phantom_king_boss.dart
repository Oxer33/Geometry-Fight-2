import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../../data/constants.dart';
import '../../../data/wave_configs.dart';
import '../../game_world.dart';
import 'boss_base.dart';

/// PHANTOM KING - Boss che diventa invisibile e crea cloni di sé stesso.
/// Forma: corona geometrica (pentagono con punte)
/// Colore: blu fantasma (#4466FF)
/// HP: 1500 · 3 fasi
/// Meccanica: diventa invisibile per 3s, poi riappare e attacca.
/// Crea 2-4 cloni con 1 HP che confondono il player.
/// Solo il vero boss ha il glow più intenso.
class PhantomKingBoss extends BossBase {
  double _invisTimer = 5.0; // Inizia visibile per 5s
  bool _isInvisible = false;
  double _attackTimer = 2.0;
  double _cloneTimer = 8.0;
  double _crownPhase = 0;
  // Shared rng — evita alloc in teleport/clone spawn.
  static final math.Random _rng = math.Random();

  // Mirror shadow clone (nuova meccanica richiesta utente):
  // una silhouette fantasma all'opposto del player rispetto al boss, che
  // spara indipendentemente → player gestisce 2 bersagli simmetrici.
  Vector2 _shadowPos = Vector2.zero();
  double _shadowAttackTimer = 2.5;

  PhantomKingBoss()
      : super(
          hp: 1500,
          bossName: 'PHANTOM KING',
          pointValue: 3200,
          neonColor: const Color(0xFF4466FF),
          size: Vector2(85, 85),
        );

  // PhantomKing è BLU/VIOLA SPETTRO → mob phantom/glitch/decoy.
  @override
  List<EnemyType> get colorMatchedMinions =>
      const [EnemyType.phantom, EnemyType.glitch, EnemyType.decoy];

  @override
  int getPhase() {
    if (healthPercent > 0.7) return 0;
    if (healthPercent > 0.4) return 1;
    return 2;
  }

  @override
  void updateBoss(double dt) {
    _crownPhase += dt * 2;

    // Invisibilità periodica
    if (_isInvisible) {
      _invisTimer -= dt;
      if (_invisTimer <= 0) {
        _isInvisible = false;
        _invisTimer = currentPhase == 2 ? 3.0 : 5.0; // Durata fase visibile
        // Attacco sorpresa al riapparire
        _shootBurst();
        // Reset attackTimer: l'_attackTimer accumulato durante invisibilità
        // scatterebbe subito → doppio volley (burst + shoot) stesso frame.
        _attackTimer = currentPhase == 2 ? 1.0 : 2.0;
      }
    } else {
      _invisTimer -= dt;
      if (_invisTimer <= 0) {
        _isInvisible = true;
        _invisTimer = currentPhase == 2 ? 2.0 : 3.0;
        // Teletrasporto in posizione casuale vicino al player
        final angle = _rng.nextDouble() * math.pi * 2;
        final dist = 150 + _rng.nextDouble() * 200;
        position = playerPosition + Vector2(math.cos(angle) * dist, math.sin(angle) * dist);
        if (game.isTunnelMode) {
          final cam = game.camera.viewfinder.position;
          final halfW = game.size.x > 0 ? game.size.x / 2 : 400.0;
          final halfH = game.size.y > 0 ? game.size.y / 2 : 300.0;
          position.x = position.x.clamp(cam.x - halfW + 50, cam.x + halfW - 50);
          position.y = position.y.clamp(cam.y - halfH + 50, cam.y + halfH - 50);
        } else {
          position.x = position.x.clamp(100, arenaWidth - 100);
          position.y = position.y.clamp(100, arenaHeight - 100);
        }
      }
    }

    // Movimento (solo se visibile)
    if (!_isInvisible) {
      final toPlayer = (playerPosition - position);
      if (toPlayer.length > 150) {
        position += toPlayer.normalized() * 100 * dt;
      }
    }

    // Attacco periodico
    _attackTimer -= dt;
    if (_attackTimer <= 0 && !_isInvisible) {
      _attackTimer = currentPhase == 2 ? 1.0 : 2.0;
      _shootAtPlayer();
    }

    // Crea cloni periodicamente
    _cloneTimer -= dt;
    if (_cloneTimer <= 0) {
      _cloneTimer = currentPhase == 2 ? 5.0 : 8.0;
      _spawnClone();
    }

    // ─── MIRROR SHADOW CLONE ──────────────────────────────────────
    // Posizione: riflesso del player attorno al boss (centro simmetria).
    // Clampata a arena bounds così lo shadow resta sempre visibile.
    // Vector2 supporta solo `vec * scalar`, non `scalar * vec` → uso `* 2`.
    _shadowPos = position * 2 - playerPosition;
    if (!game.isTunnelMode) {
      _shadowPos.x = _shadowPos.x.clamp(30.0, arenaWidth - 30.0);
      _shadowPos.y = _shadowPos.y.clamp(30.0, arenaHeight - 30.0);
    }
    _shadowAttackTimer -= dt;
    if (_shadowAttackTimer <= 0 && !_isInvisible) {
      _shadowAttackTimer = currentPhase == 2 ? 1.8 : 2.8;
      _shadowShoot();
    }
  }

  void _shadowShoot() {
    // Shadow spara 3 bullet verso il player, fan stretto.
    final dir = (playerPosition - _shadowPos);
    if (dir.length < 0.001) return;
    final base = math.atan2(dir.y, dir.x);
    for (int i = -1; i <= 1; i++) {
      final ang = base + i * 0.15;
      final bulletDir = Vector2(math.cos(ang), math.sin(ang));
      final bullet = _PhantomBullet(
          direction: bulletDir, color: const Color(0xFF8877FF));
      bullet.position = _shadowPos.clone();
      game.world.add(bullet);
    }
  }

  void _shootAtPlayer() {
    final delta = playerPosition - position;
    // Guard: if player is exactly at boss position, skip to avoid NaN from
    // normalizing a zero-length vector.
    if (delta.length < 0.001) return;
    final dir = delta.normalized();
    for (int i = -1; i <= 1; i++) {
      final angle = math.atan2(dir.y, dir.x) + i * 0.2;
      final bulletDir = Vector2(math.cos(angle), math.sin(angle));
      final bullet = _PhantomBullet(direction: bulletDir, color: neonColor);
      bullet.position = position.clone();
      game.world.add(bullet);
    }
  }

  void _shootBurst() {
    for (int i = 0; i < 12; i++) {
      final angle = i * math.pi * 2 / 12;
      final dir = Vector2(math.cos(angle), math.sin(angle));
      final bullet = _PhantomBullet(direction: dir, color: neonColor);
      bullet.position = position.clone();
      game.world.add(bullet);
    }
    game.triggerScreenShake(4, 0.2);
  }

  void _spawnClone() {
    // Spawna un nemico drone colorato come il boss
    game.spawnEnemy(EnemyType.drone, position + Vector2(
      (_rng.nextDouble() - 0.5) * 100,
      (_rng.nextDouble() - 0.5) * 100,
    ));
  }

  // Signature FX paints
  static final _ectoplasmPaint = Paint();
  static final _jewelGlowPaint = Paint();
  static final _jewelCorePaint = Paint();
  static final _innerRingPaint = Paint()..style = PaintingStyle.stroke;
  static final _eyeHaloPaint = Paint();
  static final _eyePupilPaint = Paint();
  static final _invisShimmerPaint = Paint()..style = PaintingStyle.stroke;
  // Shadow clone (cached paints — evita alloc/frame).
  static final _shadowBodyPaint = Paint();
  static final _shadowGlowPaint = Paint();
  static final _shadowEyePaint = Paint();

  @override
  void renderBoss(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final r = size.x / 2 * scale;

    if (_isInvisible) {
      paint.color = paint.color.withValues(alpha: 0.08);
      // Shimmer etereo visibile anche in invisibilità
      if (scale <= 1.01) {
        final shimmer = (math.sin(_crownPhase * 4) * 0.5 + 0.5);
        _invisShimmerPaint.color =
            neonColor.withValues(alpha: 0.08 + shimmer * 0.12);
        _invisShimmerPaint.strokeWidth = 1;
        canvas.drawCircle(Offset(cx, cy), r * 1.1, _invisShimmerPaint);
      }
    }

    // ─── ECTOPLASM wisps attorno al boss ───
    if (scale <= 1.01 && !_isInvisible) {
      for (int i = 0; i < 6; i++) {
        final wp = _crownPhase * 0.9 + i * 1.1;
        final wAngle = wp;
        final wDist = r * (1.1 + ((wp * 0.3) % 1.0) * 0.5);
        final wAlpha = (1.0 - ((wp * 0.3) % 1.0)) * 0.55;
        _ectoplasmPaint.color =
            const Color(0xFF88AAFF).withValues(alpha: wAlpha);
        canvas.drawCircle(
          Offset(cx + math.cos(wAngle) * wDist,
              cy + math.sin(wAngle) * wDist),
          2.5 + (i % 3) * 0.6,
          _ectoplasmPaint,
        );
      }
    }

    // Corona (pentagono a punte)
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(_crownPhase * 0.3);

    final crownPath = Path();
    for (int i = 0; i < 5; i++) {
      final outerAngle = i * math.pi * 2 / 5 - math.pi / 2;
      final innerAngle = (i + 0.5) * math.pi * 2 / 5 - math.pi / 2;
      final outerR = r * 0.9;
      final innerR = r * 0.55;
      if (i == 0) {
        crownPath.moveTo(outerR * math.cos(outerAngle), outerR * math.sin(outerAngle));
      } else {
        crownPath.lineTo(outerR * math.cos(outerAngle), outerR * math.sin(outerAngle));
      }
      crownPath.lineTo(innerR * math.cos(innerAngle), innerR * math.sin(innerAngle));
    }
    crownPath.close();
    canvas.drawPath(crownPath, paint);

    // ─── JEWELS sulle 5 punte ───
    if (scale <= 1.01 && !_isInvisible) {
      for (int i = 0; i < 5; i++) {
        final tipAngle = i * math.pi * 2 / 5 - math.pi / 2;
        final tipR = r * 0.9;
        final tipX = tipR * math.cos(tipAngle);
        final tipY = tipR * math.sin(tipAngle);
        final jewelPulse = 0.6 + math.sin(_crownPhase * 4 + i * 1.2) * 0.4;
        _jewelGlowPaint.color =
            const Color(0xFF00FFFF).withValues(alpha: jewelPulse * 0.4);
        canvas.drawCircle(Offset(tipX, tipY), 5.5, _jewelGlowPaint);
        _jewelCorePaint.color =
            const Color(0xFFFFFFFF).withValues(alpha: jewelPulse);
        canvas.drawCircle(Offset(tipX, tipY), 2, _jewelCorePaint);
      }
    }

    // Dettagli interni + occhio a 3 strati
    if (scale <= 1.01 && !_isInvisible) {
      _innerRingPaint.color = paint.color.withValues(alpha: 0.3);
      _innerRingPaint.strokeWidth = 1;
      canvas.drawCircle(Offset.zero, r * 0.35, _innerRingPaint);

      final eyePulse = 0.6 + math.sin(_crownPhase * 3) * 0.3;
      _eyeHaloPaint.color =
          const Color(0xFFFFFFFF).withValues(alpha: 0.25 * eyePulse);
      canvas.drawCircle(Offset.zero, r * 0.28, _eyeHaloPaint);
      _eyeHaloPaint.color =
          const Color(0xFF4466FF).withValues(alpha: eyePulse);
      canvas.drawCircle(Offset.zero, r * 0.18, _eyeHaloPaint);
      _eyePupilPaint.color =
          const Color(0xFFFFFFFF).withValues(alpha: eyePulse);
      canvas.drawCircle(Offset.zero, r * 0.08 * eyePulse, _eyePupilPaint);
    }
    canvas.restore();

    // ─── MIRROR SHADOW CLONE ─────────────────────────────────────
    // Silhouette fantasma semi-trasparente al mirror del player. Stessa
    // forma crown del boss, più piccola e blu-viola fosca.
    if (scale <= 1.01 && !_isInvisible) {
      final sOffset = _shadowPos - position;
      final sx = cx + sOffset.x;
      final sy = cy + sOffset.y;
      final sr = r * 0.65;
      final shadowPulse = 0.4 + math.sin(_crownPhase * 4) * 0.2;
      canvas.save();
      canvas.translate(sx, sy);
      canvas.rotate(-_crownPhase * 0.3);
      final shadowPath = Path();
      for (int i = 0; i < 5; i++) {
        final outerAngle = i * math.pi * 2 / 5 - math.pi / 2;
        final innerAngle = (i + 0.5) * math.pi * 2 / 5 - math.pi / 2;
        final outerR = sr * 0.9;
        final innerR = sr * 0.55;
        if (i == 0) {
          shadowPath.moveTo(
              outerR * math.cos(outerAngle), outerR * math.sin(outerAngle));
        } else {
          shadowPath.lineTo(
              outerR * math.cos(outerAngle), outerR * math.sin(outerAngle));
        }
        shadowPath.lineTo(
            innerR * math.cos(innerAngle), innerR * math.sin(innerAngle));
      }
      shadowPath.close();
      _shadowBodyPaint.color =
          const Color(0xFF6644AA).withValues(alpha: shadowPulse);
      canvas.drawPath(shadowPath, _shadowBodyPaint);
      _shadowGlowPaint.color =
          const Color(0xFF8877FF).withValues(alpha: shadowPulse * 0.5);
      canvas.drawCircle(Offset.zero, sr * 0.5, _shadowGlowPaint);
      _shadowEyePaint.color = const Color(0xFFFFFFFF)
          .withValues(alpha: 0.7 + math.sin(_crownPhase * 6) * 0.3);
      canvas.drawCircle(Offset.zero, sr * 0.1, _shadowEyePaint);
      canvas.restore();
    }
  }
}

class _PhantomBullet extends PositionComponent with HasGameReference<GeometryFightGame> {
  final Vector2 direction;
  final Color color;
  late Vector2 _velocity;
  double _lifetime = 3.5;

  _PhantomBullet({required this.direction, required this.color})
      : super(size: Vector2(18, 18), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    // Guard against a zero-length direction producing NaN velocity.
    _velocity = direction.length > 0.001
        ? direction.normalized() * 230
        : Vector2(1, 0) * 230;
  }

  @override
  void update(double dt) {
    super.update(dt);
    position += _velocity * dt;
    _lifetime -= dt;
    if (_lifetime <= 0) {
      removeFromParent();
      return; // expired bullet must not deal damage after lifetime ends
    }
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
    _bulletPaint.color = color.withValues(alpha: 0.3);
    canvas.drawCircle(Offset(cx, cy), 8, _bulletPaint);
    _bulletPaint.color = color;
    canvas.drawCircle(Offset(cx, cy), 6, _bulletPaint);
    _bulletCorePaint.color = const Color(0xFFFFFFFF).withValues(alpha: 0.7);
    canvas.drawCircle(Offset(cx, cy), 3, _bulletCorePaint);
  }
}

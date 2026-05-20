import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../../data/constants.dart';
import '../../../data/wave_configs.dart';
import '../../game_world.dart';
import '../projectiles.dart';
import 'boss_base.dart';

/// Specchio fisico sul pavimento (nuova meccanica richiesta utente).
/// Riflette i proiettili del player verso di lui. Distruttibile — HP visibile.
class _FloorMirror {
  Vector2 position = Vector2.zero();
  double angle = 0;
  double hp = 25;
  final double maxHp = 25;
  bool alive = true;
}

/// MIRROR MASTER - Boss che riflette i proiettili del player contro di lui.
/// Forma: ottagono con specchi rotanti sulle facce
/// Colore: argento (#CCDDEE)
/// HP: 1400 · 3 fasi
/// Meccanica: ha facce riflettenti che rimbalzano i proiettili.
/// Solo i colpi da dietro o area danneggiano. Crea cloni-specchio.
class MirrorMasterBoss extends BossBase {
  double _mirrorAngle = 0;
  double _attackTimer = 2.5;
  // Floor mirrors (nuova meccanica richiesta utente): 3 specchi riflettono
  // i proiettili del player. Distruttibili, HP 25 ciascuno.
  final List<_FloorMirror> _mirrors = [];
  bool _mirrorsSpawned = false;
  // Respawn timer: appena tutti gli specchi muoiono, parte countdown 8s
  // → respawn 3 nuovi specchi. Senza questo il boss restava nudo dopo
  // che il player rompeva gli specchi → meccanica "morta" mid-fight.
  double _mirrorRespawnTimer = 0;
  // Mirror-side attack: ogni specchio spara un _MirrorBullet verso il
  // player ogni `_mirrorShootInterval` secondi. Visualmente "attivi"
  // invece di solo riflettori passivi (user feedback).
  double _mirrorShootTimer = 3.0;
  static const double _mirrorShootInterval = 2.5;

  MirrorMasterBoss()
      : super(
          hp: 1400,
          bossName: 'MIRROR MASTER',
          pointValue: 2800,
          neonColor: const Color(0xFFCCDDEE),
          size: Vector2(95, 95),
        );

  void _spawnMirrors() {
    _mirrors.clear();
    final cx = game.isTunnelMode
        ? game.camera.viewfinder.position.x
        : arenaWidth / 2;
    final cy = game.isTunnelMode
        ? game.camera.viewfinder.position.y
        : arenaHeight / 2;
    // Triangolo: 3 specchi ai vertici di un triangolo equilatero attorno al centro.
    const r = 180.0;
    final yMin = game.camera.viewfinder.position.y - 200;
    final yMax = game.camera.viewfinder.position.y + 200;
    for (int i = 0; i < 3; i++) {
      final ang = i * math.pi * 2 / 3 - math.pi / 2;
      final mx = cx + math.cos(ang) * r;
      var my = cy + math.sin(ang) * r;
      if (game.isTunnelMode) {
        my = my.clamp(yMin, yMax);
      }
      _mirrors.add(_FloorMirror()
        ..position = Vector2(mx, my)
        ..angle = ang + math.pi / 2);
    }
    _mirrorsSpawned = true;
  }

  // MirrorMaster è ARGENTO/CIANO → mob riflettenti (mirror + glitch + orbiter).
  @override
  List<EnemyType> get colorMatchedMinions =>
      const [EnemyType.mirror, EnemyType.glitch, EnemyType.orbiter];

  @override
  int getPhase() {
    if (healthPercent > 0.7) return 0;
    if (healthPercent > 0.4) return 1;
    return 2;
  }

  @override
  void updateBoss(double dt) {
    _mirrorAngle += dt * (1.0 + currentPhase * 0.5);

    // Lazy spawn mirrors al primo frame (game.size non disponibile in ctor).
    if (!_mirrorsSpawned) _spawnMirrors();

    // Respawn check: tutti gli specchi morti → countdown 8s → respawn 3.
    final aliveCount = _mirrors.where((m) => m.alive).length;
    if (aliveCount == 0) {
      _mirrorRespawnTimer -= dt;
      if (_mirrorRespawnTimer <= 0) {
        _spawnMirrors();
        _mirrorRespawnTimer = 8.0; // reset for next cycle
      }
    } else {
      _mirrorRespawnTimer = 8.0;
    }

    // Orbita attorno al player. Velocità più alta (180px/s) per stare
    // dietro al player in tunnel mode (player può andare a 400+px/s).
    // Tunnel mode: usa camera-front come orbit center così il boss
    // resta sempre in vista invece di "fisso a destra" dietro al player.
    final orbitDist = 250 - currentPhase * 40;
    final orbitCenter = game.isTunnelMode
        ? Vector2(
            game.camera.viewfinder.position.x + 80,
            playerPosition.y,
          )
        : playerPosition;
    final targetPos = orbitCenter + Vector2(
      math.cos(_mirrorAngle * 0.3) * orbitDist,
      math.sin(_mirrorAngle * 0.3) * orbitDist,
    );
    final toTarget = targetPos - position;
    final followSpeed = game.isTunnelMode ? 280.0 : 90.0;
    if (toTarget.length > 5) {
      position += toTarget.normalized() * followSpeed * dt;
    }

    // ─── MIRRORS: reflect PlayerBullet + phase 2 drift verso player ──
    for (final m in _mirrors) {
      if (!m.alive) continue;
      // Fase 2+: specchi convergono lentamente sul player.
      if (currentPhase >= 1) {
        final toPlayer = (playerPosition - m.position);
        if (toPlayer.length > 40) {
          m.position += toPlayer.normalized() * 25 * dt;
          m.angle = math.atan2(toPlayer.y, toPlayer.x) + math.pi / 2;
        }
      }
    }

    // Intercetta PlayerBullet entro 22px → riflette come EnemyBullet
    // + danno 3 allo specchio. Bullet ad alto damage (plasma) romperà
    // lo specchio in 3 hit.
    //
    // BUG FIX: `removeFromParent()` di Flame è async (processato a fine
    // frame). Senza flag, un PlayerBullet fermo sullo specchio veniva
    // "reflected" ogni frame fino alla rimozione effettiva → rain di
    // _MirrorBullet. `wasReflected` + `isRemoved` guard + snapshot list
    // (niente concurrent modification su game.world.children).
    final bullets = game.world.children.whereType<PlayerBullet>().toList();
    for (final child in bullets) {
      if (child.wasReflected || child.isRemoved) continue;
      for (final m in _mirrors) {
        if (!m.alive) continue;
        if (child.position.distanceTo(m.position) < 22) {
          m.hp -= 3;
          if (m.hp <= 0) {
            m.alive = false;
            game.spawnExplosion(m.position, const Color(0xFFCCDDFF),
                radius: 40, particleCount: 12);
            game.triggerScreenShake(3, 0.15);
          }
          // Reflect verso player — EnemyBullet veloce.
          final dir = (playerPosition - m.position);
          if (dir.length > 0.001) {
            final reflected = _MirrorBullet(
                direction: dir.normalized(),
                color: const Color(0xFFFF88FF));
            reflected.position = m.position.clone();
            game.world.add(reflected);
          }
          child.wasReflected = true;
          child.removeFromParent();
          break;
        }
      }
    }

    // Attacco
    _attackTimer -= dt;
    if (_attackTimer <= 0) {
      _attackTimer = 2.0 - currentPhase * 0.4;
      _shootMirrorBurst();
    }

    // Mirror-side attack: ogni specchio vivo spara un bullet al player
    // ogni _mirrorShootInterval secondi → specchi "attivi" anziché
    // solo riflettori passivi.
    _mirrorShootTimer -= dt;
    if (_mirrorShootTimer <= 0) {
      _mirrorShootTimer = _mirrorShootInterval;
      for (final m in _mirrors) {
        if (!m.alive) continue;
        final dir = playerPosition - m.position;
        if (dir.length < 0.001) continue;
        final bullet = _MirrorBullet(
          direction: dir.normalized(),
          color: const Color(0xFFFF88FF),
        );
        bullet.position = m.position.clone();
        game.world.add(bullet);
      }
    }
  }

  void _shootMirrorBurst() {
    final count = 6 + currentPhase * 3;
    for (int i = 0; i < count; i++) {
      final angle = _mirrorAngle + i * math.pi * 2 / count;
      final dir = Vector2(math.cos(angle), math.sin(angle));
      final bullet = _MirrorBullet(direction: dir, color: neonColor);
      bullet.position = position.clone();
      game.world.add(bullet);
    }
  }

  // Signature FX paints
  static final _shardPaint = Paint();
  static final _shardStrokePaint = Paint()..style = PaintingStyle.stroke;
  static final _facePaint = Paint()
    ..strokeWidth = 2
    ..style = PaintingStyle.stroke;
  static final _innerOctPaint = Paint()..style = PaintingStyle.stroke;
  static final _coreHaloPaint = Paint();
  static final _coreWhitePaint = Paint();
  static final _prismaticPaint = Paint()..style = PaintingStyle.stroke;
  // Floor mirrors (cached paints — evita alloc/frame × N specchi).
  static final _mirrorGlowPaint = Paint();
  static final _mirrorBodyPaint = Paint();
  static final _mirrorBorderPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;

  @override
  void renderBoss(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final r = size.x / 2 * scale;

    // ─── PRISMATIC SHARDS ORBITANTI (6 frammenti) ───
    if (scale <= 1.01) {
      for (int i = 0; i < 6; i++) {
        final sAngle = _mirrorAngle * 0.6 + i * math.pi / 3;
        final sDist = r * 1.35;
        final sx = cx + math.cos(sAngle) * sDist;
        final sy = cy + math.sin(sAngle) * sDist;
        final shardPulse = 0.6 + math.sin(_mirrorAngle * 3 + i * 1.1) * 0.4;
        canvas.save();
        canvas.translate(sx, sy);
        canvas.rotate(_mirrorAngle * 2 + i);
        final shardPath = Path()
          ..moveTo(0, -4)
          ..lineTo(3, 0)
          ..lineTo(0, 4)
          ..lineTo(-3, 0)
          ..close();
        _shardPaint.color = const Color(0xFFCCDDFF)
            .withValues(alpha: 0.5 * shardPulse);
        canvas.drawPath(shardPath, _shardPaint);
        _shardStrokePaint.color =
            const Color(0xFFFFFFFF).withValues(alpha: shardPulse);
        _shardStrokePaint.strokeWidth = 1;
        canvas.drawPath(shardPath, _shardStrokePaint);
        canvas.restore();
      }
    }

    // Ottagono principale
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(_mirrorAngle * 0.2);

    final path = Path();
    for (int i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      final x = r * 0.85 * math.cos(angle);
      final y = r * 0.85 * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);

    if (scale <= 1.01) {
      // Shimmer sulle 8 facce
      for (int i = 0; i < 8; i++) {
        final a1 = i * math.pi / 4;
        final a2 = (i + 1) * math.pi / 4;
        final shimmer = 0.3 + math.sin(_mirrorAngle * 3 + i * 0.8) * 0.3;
        _facePaint.color =
            const Color(0xFFFFFFFF).withValues(alpha: shimmer);
        canvas.drawLine(
          Offset(r * 0.85 * math.cos(a1), r * 0.85 * math.sin(a1)),
          Offset(r * 0.85 * math.cos(a2), r * 0.85 * math.sin(a2)),
          _facePaint,
        );
      }

      // ─── 3 RAGGI CROMATICI dal centro ───
      for (int p = 0; p < 3; p++) {
        final pAngle = _mirrorAngle * 2 + p * math.pi * 2 / 3;
        _prismaticPaint.color = [
          const Color(0xFFFF4488),
          const Color(0xFF44FFDD),
          const Color(0xFFFFDD44),
        ][p].withValues(alpha: 0.5);
        _prismaticPaint.strokeWidth = 1.2;
        canvas.drawLine(
          Offset.zero,
          Offset(math.cos(pAngle) * r * 0.75,
              math.sin(pAngle) * r * 0.75),
          _prismaticPaint,
        );
      }

      // Ottagono interno contro-rotante
      canvas.rotate(-_mirrorAngle * 0.5);
      _innerOctPaint.color =
          const Color(0xFFFFFFFF).withValues(alpha: 0.4);
      _innerOctPaint.strokeWidth = 1;
      final innerPath = Path();
      for (int i = 0; i < 8; i++) {
        final a = i * math.pi / 4 + math.pi / 8;
        final x = r * 0.45 * math.cos(a);
        final y = r * 0.45 * math.sin(a);
        if (i == 0) {
          innerPath.moveTo(x, y);
        } else {
          innerPath.lineTo(x, y);
        }
      }
      innerPath.close();
      canvas.drawPath(innerPath, _innerOctPaint);
      canvas.rotate(_mirrorAngle * 0.5);

      // Core halo + bianco pulsante
      final pulse = 0.5 + math.sin(_mirrorAngle * 2) * 0.4;
      _coreHaloPaint.color =
          const Color(0xFFCCDDFF).withValues(alpha: pulse * 0.5);
      canvas.drawCircle(Offset.zero, r * 0.32, _coreHaloPaint);
      _coreWhitePaint.color =
          const Color(0xFFFFFFFF).withValues(alpha: pulse);
      canvas.drawCircle(
          Offset.zero, r * 0.18 * (0.85 + pulse * 0.2), _coreWhitePaint);
    }
    canvas.restore();

    // ─── FLOOR MIRRORS ───────────────────────────────────────────
    // Render in world coords (offset da boss center).
    if (scale <= 1.01) {
      for (final m in _mirrors) {
        if (!m.alive) continue;
        final offset = m.position - position;
        final mx = cx + offset.x;
        final my = cy + offset.y;
        final hpRatio = (m.hp / m.maxHp).clamp(0.0, 1.0);
        canvas.save();
        canvas.translate(mx, my);
        canvas.rotate(m.angle);
        _mirrorGlowPaint.color =
            const Color(0xFFFF88FF).withValues(alpha: 0.3 + hpRatio * 0.3);
        canvas.drawRect(
            const Rect.fromLTWH(-34, -8, 68, 16), _mirrorGlowPaint);
        _mirrorBodyPaint.color = Color.lerp(const Color(0xFF886699),
            const Color(0xFFCCDDFF), hpRatio)!;
        canvas.drawRect(
            const Rect.fromLTWH(-30, -5, 60, 10), _mirrorBodyPaint);
        _mirrorBorderPaint.color =
            const Color(0xFFFFFFFF).withValues(alpha: 0.9);
        canvas.drawRect(
            const Rect.fromLTWH(-30, -5, 60, 10), _mirrorBorderPaint);
        canvas.restore();
      }
    }
  }
}

class _MirrorBullet extends PositionComponent with HasGameReference<GeometryFightGame> {
  final Vector2 direction;
  final Color color;
  late Vector2 _velocity;
  double _lifetime = 3.5;

  _MirrorBullet({required this.direction, required this.color})
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
      if (!game.player.isInvincible) game.player.takeDamage();
      removeFromParent();
    }
  }

  static final _bulletPaint = Paint();
  static final _bulletCorePaint = Paint();

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    // Bullet grandi come EnemyBullet (hydra/grid): glow 8 + body 6 + core 3.
    _bulletPaint.color = color.withValues(alpha: 0.3);
    canvas.drawCircle(Offset(cx, cy), 8, _bulletPaint);
    _bulletPaint.color = color;
    canvas.drawCircle(Offset(cx, cy), 6, _bulletPaint);
    _bulletCorePaint.color = const Color(0xFFFFFFFF).withValues(alpha: 0.7);
    canvas.drawCircle(Offset(cx, cy), 3, _bulletCorePaint);
  }
}

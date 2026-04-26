import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../../data/constants.dart';
import '../../../data/wave_configs.dart';
import '../../game_world.dart';
import '../projectiles.dart';
import 'boss_base.dart';

/// Satellite core che orbita attorno al NexusPrime bloccando i colpi player.
/// Nuova meccanica (richiesta utente): boss invulnerabile finché i 4 satelliti
/// sono vivi — player deve prima distruggerli per colpire il core.
class _NexusSatellite {
  Vector2 offset = Vector2.zero();
  bool alive = true;
  double deathPulse = 0;
  // HP per satellite. Iter: 20 → 8 (utente: shield troppo tanky, sembrava
  // boss invuln). 4 sat × 8 hp = 32 hit basic con damage 1 → ~4s a fire
  // rate 8/s = break sostenibile.
  double hp = 8;
}

/// NEXUS PRIME - Boss che crea portali e si teletrasporta attraverso l'arena.
/// Forma: doppio esagono concentrico con nucleo energetico
/// Colore: ciano brillante (#00EEFF)
/// HP: 1600 · 3 fasi
/// Meccanica: crea 2-4 portali nell'arena. Si teletrasporta tra di essi.
/// I portali sparano proiettili. Fase finale: tutti i portali sparano simultaneamente.
class NexusPrimeBoss extends BossBase {
  double _attackTimer = 3.0;
  double _teleportTimer = 5.0;
  double _portalPhase = 0;
  final List<Vector2> _portalPositions = [];
  int _currentPortal = 0;

  // Shield satellites (nuova meccanica richiesta utente).
  final List<_NexusSatellite> _satellites = [];
  static const double _satelliteRadius = 80;
  static const double _satelliteHitR = 18;
  // Beam convergente fase 2: i satelliti sparano tutti verso il player insieme.
  double _convergentTimer = 3.0;
  double _convergentWindUp = 0;

  NexusPrimeBoss()
      : super(
          hp: 1600,
          bossName: 'NEXUS PRIME',
          pointValue: 3000,
          neonColor: const Color(0xFF00EEFF),
          size: Vector2(90, 90),
        );

  // NexusPrime è CIANO → mob cyan (drone + orbiter + decoy).
  @override
  List<EnemyType> get colorMatchedMinions =>
      const [EnemyType.drone, EnemyType.orbiter, EnemyType.decoy];

  @override
  int getPhase() {
    if (healthPercent > 0.6) return 0;
    if (healthPercent > 0.3) return 1;
    return 2;
  }

  @override
  void onPhaseChange(int phase) {
    // Aggiungi portali ad ogni fase
    _createPortals(2 + phase);
    // Respawn satelliti ad ogni cambio fase (rigenera lo scudo).
    _spawnSatellites();
  }

  /// Crea/resetta 4 satelliti orbitanti (tutti alive).
  void _spawnSatellites() {
    _satellites.clear();
    for (int i = 0; i < 4; i++) {
      final ang = i * math.pi / 2;
      _satellites.add(_NexusSatellite()
        ..offset = Vector2(
          math.cos(ang) * _satelliteRadius,
          math.sin(ang) * _satelliteRadius,
        ));
    }
  }

  int get _aliveSatellites => _satellites.where((s) => s.alive).length;

  @override
  void takeDamage(double amount, {bool isArea = false}) {
    // Logica scudo semplificata (utente: "non prende danno ne da bombe ne
    // dalle armi"):
    //
    // 1. Bullet che ARRIVANO QUI sono già passati l'intercept satellitare in
    //    updateBoss (raggio _satelliteHitR=18px). Se siamo qui, hanno
    //    bypassato lo scudo → danno applicato pieno al boss.
    // 2. AoE (laser/plasma/bomba) → danno pieno al boss + chip ai satelliti
    //    vivi (l'esplosione tocca anche lo scudo).
    //
    // Prima: !isArea + sat_alive → return early → nessun bullet poteva mai
    // colpire il core (anche quelli che mancavano i satelliti). Bug fixed.
    super.takeDamage(amount, isArea: isArea);
    if (isArea && _aliveSatellites > 0) {
      final alive = _satellites.where((s) => s.alive).toList();
      if (alive.isNotEmpty) {
        final perSat = amount / alive.length;
        for (final s in alive) {
          s.hp -= perSat;
          if (s.hp <= 0) _killSatellite(s);
        }
      }
    }
  }

  void _killSatellite(_NexusSatellite s) {
    if (!s.alive) return;
    s.alive = false;
    s.deathPulse = 0.6;
    final worldPos = position + s.offset;
    game.spawnExplosion(worldPos, neonColor, radius: 35, particleCount: 10);
    game.triggerScreenShake(3, 0.15);
  }

  void _createPortals(int count) {
    _portalPositions.clear();
    final random = math.Random();
    if (game.isTunnelMode) {
      final cam = game.camera.viewfinder.position;
      final halfW = game.size.x > 0 ? game.size.x / 2 : 400.0;
      final halfH = game.size.y > 0 ? game.size.y / 2 : 300.0;
      for (int i = 0; i < count; i++) {
        _portalPositions.add(Vector2(
          cam.x - halfW + 100 + random.nextDouble() * (halfW * 2 - 200),
          cam.y - halfH + 100 + random.nextDouble() * (halfH * 2 - 200),
        ));
      }
    } else {
      for (int i = 0; i < count; i++) {
        _portalPositions.add(Vector2(
          300 + random.nextDouble() * (arenaWidth - 600),
          300 + random.nextDouble() * (arenaHeight - 600),
        ));
      }
    }
  }

  @override
  void updateBoss(double dt) {
    _portalPhase += dt * 3;

    if (_portalPositions.isEmpty) {
      _createPortals(2);
    }

    // Lazy init satelliti al primo frame utile.
    if (_satellites.isEmpty) _spawnSatellites();

    // Satelliti orbitano intorno al boss (rotazione lenta opposta al portale).
    const satAngularSpeed = 1.2;
    for (int i = 0; i < _satellites.length; i++) {
      final s = _satellites[i];
      if (!s.alive) {
        if (s.deathPulse > 0) s.deathPulse -= dt;
        continue;
      }
      final baseAngle = _portalPhase * satAngularSpeed + i * math.pi / 2;
      s.offset = Vector2(
        math.cos(baseAngle) * _satelliteRadius,
        math.sin(baseAngle) * _satelliteRadius,
      );
    }

    // Intercetta PlayerBullet entro _satelliteHitR di ogni satellite vivo.
    // Il satellite assorbe il bullet e prende damage — richiede più hit per
    // rompersi (era 1-hit kill, ora HP-based).
    // BUG FIX: iterare game.world.children mentre si chiama removeFromParent
    // può causare ConcurrentModificationError (Flame rimuove fine frame ma la
    // collection interna può mutare). Snapshot + isRemoved guard.
    final nexusChildrenSnapshot = game.world.children.toList(growable: false);
    for (final child in nexusChildrenSnapshot) {
      if (child is! PlayerBullet) continue;
      if (child.isRemoved) continue;
      for (final s in _satellites) {
        if (!s.alive) continue;
        final worldPos = position + s.offset;
        if (child.position.distanceTo(worldPos) < _satelliteHitR) {
          // Guard difensivo: damage NaN/non-positivo → fallback 1.
          final dmg = child.damage.isFinite && child.damage > 0
              ? child.damage
              : 1.0;
          s.hp -= dmg;
          if (s.hp <= 0) _killSatellite(s);
          child.removeFromParent();
          break;
        }
      }
    }

    // Movimento verso il player (lento)
    final toPlayer = (playerPosition - position);
    if (toPlayer.length > 200) {
      position += toPlayer.normalized() * 60 * dt;
    }

    // Teletrasporto periodico tra portali
    _teleportTimer -= dt;
    if (_teleportTimer <= 0 && _portalPositions.isNotEmpty) {
      _teleportTimer = currentPhase == 2 ? 2.0 : 4.0;
      _currentPortal = (_currentPortal + 1) % _portalPositions.length;
      position = _portalPositions[_currentPortal].clone();
      game.triggerScreenShake(3, 0.15);
      if (!game.isTunnelMode) {
        game.grid.applyForce(position, 100, 400);
      }
    }

    // Attacco: spara proiettili radiali
    _attackTimer -= dt;
    if (_attackTimer <= 0) {
      _attackTimer = currentPhase == 2 ? 1.0 : 2.0;
      _shootRadial();
    }

    // Fase 2+: beam convergenti dai satelliti verso il player (se almeno 2 vivi).
    if (currentPhase >= 1 && _aliveSatellites >= 2) {
      if (_convergentWindUp > 0) {
        _convergentWindUp -= dt;
        if (_convergentWindUp <= 0) {
          _fireConvergentBeams();
        }
      } else {
        _convergentTimer -= dt;
        if (_convergentTimer <= 0) {
          _convergentTimer = currentPhase == 2 ? 4.0 : 6.0;
          _convergentWindUp = 1.0; // telegraph 1s
        }
      }
    }
  }

  void _fireConvergentBeams() {
    final pPos = playerPosition;
    for (final s in _satellites) {
      if (!s.alive) continue;
      final worldPos = position + s.offset;
      final dir = (pPos - worldPos);
      if (dir.length < 0.001) continue;
      final bullet = _BossBullet(
          direction: dir.normalized(), color: const Color(0xFFFF44FF));
      bullet.position = worldPos.clone();
      game.world.add(bullet);
    }
  }

  void _shootRadial() {
    final count = 8 + currentPhase * 4;
    for (int i = 0; i < count; i++) {
      final angle = i * math.pi * 2 / count + _portalPhase * 0.1;
      final dir = Vector2(math.cos(angle), math.sin(angle));
      final bullet = _BossBullet(direction: dir, color: neonColor);
      bullet.position = position.clone();
      game.world.add(bullet);
    }
  }

  // Signature FX paints
  static final _portalOuterPaint = Paint()..style = PaintingStyle.stroke;
  static final _portalInnerPaint = Paint()..style = PaintingStyle.stroke;
  static final _portalSwirlPaint = Paint()..style = PaintingStyle.stroke;
  static final _portalCorePaint = Paint();
  static final _warpLinePaint = Paint()..style = PaintingStyle.stroke;
  static final _innerHexPaint = Paint()..style = PaintingStyle.stroke;
  static final _coreHaloPaint = Paint();
  static final _corePaint = Paint();

  @override
  void renderBoss(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final r = size.x / 2 * scale;

    // ─── PORTALI: ring + inner ring + swirl + core + warp line attivo ───
    if (scale <= 1.01) {
      for (int i = 0; i < _portalPositions.length; i++) {
        final offset = _portalPositions[i] - position;
        final pCx = cx + offset.x;
        final pCy = cy + offset.y;
        final isActive = i == _currentPortal;
        final portalPulse = 0.6 + math.sin(_portalPhase + i * 2) * 0.4;

        _portalOuterPaint.color = neonColor
            .withValues(alpha: (isActive ? 0.7 : 0.35) * portalPulse);
        _portalOuterPaint.strokeWidth = isActive ? 3 : 2;
        canvas.drawCircle(Offset(pCx, pCy), 24, _portalOuterPaint);

        _portalInnerPaint.color = const Color(0xFFFFFFFF)
            .withValues(alpha: (isActive ? 0.55 : 0.25) * portalPulse);
        _portalInnerPaint.strokeWidth = 1.2;
        canvas.drawCircle(Offset(pCx, pCy), 14, _portalInnerPaint);

        _portalSwirlPaint.color =
            neonColor.withValues(alpha: 0.45 * portalPulse);
        _portalSwirlPaint.strokeWidth = 1.2;
        canvas.save();
        canvas.translate(pCx, pCy);
        canvas.rotate(_portalPhase * 2 + i);
        for (int a = 0; a < 3; a++) {
          canvas.drawArc(
            Rect.fromCircle(center: Offset.zero, radius: 18),
            a * math.pi * 2 / 3, math.pi * 0.5, false, _portalSwirlPaint,
          );
        }
        canvas.restore();

        _portalCorePaint.color =
            const Color(0xFFFFFFFF).withValues(alpha: portalPulse);
        canvas.drawCircle(Offset(pCx, pCy), 3, _portalCorePaint);

        // Warp line dal boss al portale attivo
        if (isActive) {
          _warpLinePaint.color = neonColor
              .withValues(alpha: 0.3 + math.sin(_portalPhase * 4) * 0.2);
          _warpLinePaint.strokeWidth = 0.8;
          canvas.drawLine(Offset(cx, cy), Offset(pCx, pCy), _warpLinePaint);
        }
      }
    }

    // Esagono esterno rotante
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(_portalPhase * 0.2);
    _drawHex(canvas, 0, 0, r * 0.9, paint);
    canvas.restore();

    // Esagono interno contro-rotante
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(-_portalPhase * 0.3);
    _innerHexPaint.color = paint.color.withValues(alpha: 0.5);
    _innerHexPaint.strokeWidth = 2 * scale;
    _drawHex(canvas, 0, 0, r * 0.55, _innerHexPaint);
    canvas.restore();

    // Terzo esagono piccolo (triple-layer nexus)
    if (scale <= 1.01) {
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(_portalPhase * 0.5);
      _innerHexPaint.color = neonColor.withValues(alpha: 0.7);
      _innerHexPaint.strokeWidth = 1.5;
      _drawHex(canvas, 0, 0, r * 0.32, _innerHexPaint);
      canvas.restore();
    }

    // Nucleo energetico: halo + core bianco triple-strato
    if (scale <= 1.01) {
      final pulse = 0.6 + math.sin(_portalPhase * 2) * 0.4;
      _coreHaloPaint.color = neonColor.withValues(alpha: pulse * 0.5);
      canvas.drawCircle(Offset(cx, cy), r * 0.45, _coreHaloPaint);
      _corePaint.color =
          const Color(0xFFFFFFFF).withValues(alpha: pulse * 0.7);
      canvas.drawCircle(Offset(cx, cy), r * 0.28, _corePaint);
      _corePaint.color =
          const Color(0xFFFFFFFF).withValues(alpha: pulse);
      canvas.drawCircle(Offset(cx, cy), r * 0.12 * pulse, _corePaint);
    }

    // ─── SHIELD RING (se almeno 1 satellite vivo) ─────────────────
    if (scale <= 1.01 && _aliveSatellites > 0) {
      final shieldAlpha = 0.10 + _aliveSatellites * 0.05;
      _portalOuterPaint.color =
          const Color(0xFF00FFFF).withValues(alpha: shieldAlpha);
      _portalOuterPaint.strokeWidth = 1.5;
      canvas.drawCircle(Offset(cx, cy), _satelliteRadius, _portalOuterPaint);
    }

    // ─── SATELLITI ORBITANTI ───────────────────────────────────────
    if (scale <= 1.01) {
      for (int i = 0; i < _satellites.length; i++) {
        final s = _satellites[i];
        final sx = cx + s.offset.x;
        final sy = cy + s.offset.y;
        if (s.alive) {
          final satPulse = 0.7 + math.sin(_portalPhase * 3 + i) * 0.3;
          _coreHaloPaint.color = const Color(0xFF00FFFF)
              .withValues(alpha: 0.45 * satPulse);
          canvas.drawCircle(Offset(sx, sy), 14, _coreHaloPaint);
          _corePaint.color = const Color(0xFFFFFFFF).withValues(alpha: 0.9);
          canvas.drawCircle(Offset(sx, sy), 8, _corePaint);
          _corePaint.color = const Color(0xFF00FFFF);
          canvas.drawCircle(Offset(sx, sy), 4, _corePaint);
        } else if (s.deathPulse > 0) {
          // Afterglow esplosione
          final a = s.deathPulse / 0.6;
          _coreHaloPaint.color =
              const Color(0xFFFF4400).withValues(alpha: a * 0.5);
          canvas.drawCircle(Offset(sx, sy), 18 * (1 + (1 - a) * 0.5),
              _coreHaloPaint);
        }
      }
    }

    // ─── CONVERGENT BEAM TELEGRAPH (fase 2) ───────────────────────
    if (scale <= 1.01 && _convergentWindUp > 0) {
      final blinkPhase = (_convergentWindUp * 4) % 1.0;
      final blinkAlpha = blinkPhase < 0.5 ? 0.7 : 0.25;
      _warpLinePaint.color =
          const Color(0xFFFF44FF).withValues(alpha: blinkAlpha);
      _warpLinePaint.strokeWidth = 1.2;
      final pPos = playerPosition - position;
      for (final s in _satellites) {
        if (!s.alive) continue;
        canvas.drawLine(
          Offset(cx + s.offset.x, cy + s.offset.y),
          Offset(cx + pPos.x, cy + pPos.y),
          _warpLinePaint,
        );
      }
    }
  }

  void _drawHex(Canvas canvas, double cx, double cy, double r, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = i * math.pi / 3 - math.pi / 6;
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }
}

/// Proiettile boss generico
class _BossBullet extends PositionComponent
    with HasGameReference<GeometryFightGame> {
  final Vector2 direction;
  final Color color;
  late Vector2 _velocity;
  double _lifetime = 4.0;

  _BossBullet({required this.direction, required this.color})
      : super(size: Vector2(18, 18), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    _velocity = direction.normalized() * 200;
  }

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
    _bulletPaint.color = color.withValues(alpha: 0.3);
    canvas.drawCircle(Offset(cx, cy), 8, _bulletPaint);
    _bulletPaint.color = color;
    canvas.drawCircle(Offset(cx, cy), 6, _bulletPaint);
    _bulletCorePaint.color = const Color(0xFFFFFFFF).withValues(alpha: 0.7);
    canvas.drawCircle(Offset(cx, cy), 3, _bulletCorePaint);
  }
}

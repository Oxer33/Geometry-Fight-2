import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../data/constants.dart';
import '../game_world.dart';

/// Componente visivo che renderizza i muri del tunnel e gli ostacoli.
/// Il tunnel è un corridoio orizzontale con muri superiore e inferiore
/// che ondeggiano sinusoidalmente, creando curve. Gli ostacoli sono
/// barriere laser che appaiono periodicamente.
class TunnelRenderer extends PositionComponent
    with HasGameReference<GeometryFightGame> {
  final List<_TunnelObstacle> _obstacles = [];
  double _obstacleSpawnTimer = 5.0;
  // Post-boss cooldown (richiesta utente): 15s senza spawn muri dopo la
  // sconfitta di un boss, per dare respiro al player.
  double _postBossCooldown = 0;
  int _prevBossCount = 0;
  static const double _kPostBossCooldown = 15.0;
  static final _random = math.Random();

  // Cached static Paints — muri tunnel bianco fluo (spessore dimezzato rispetto pre)
  static final _wallGlowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 20;
  static final _wallMainPaint = Paint()
    ..color = const Color(0xFFFFFFFF)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 5;
  static final _wallInnerPaint = Paint()
    ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.85)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  static final _obsGlowPaint = Paint();
  static final _obsBarrierPaint = Paint();
  static final _obsBorderPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  static final _speedLinePaint = Paint()
    ..color = const Color(0xFF0044AA).withValues(alpha: 0.06)
    ..strokeWidth = 0.5;

  TunnelRenderer() : super(priority: -5); // Sopra sfondo, sotto entità

  /// Altezza del tunnel dal game_world
  double get tunnelH => game.tunnelHeight;

  /// Centro Y dell'arena
  double get centerY => arenaHeight / 2;

  double get _screenHalfW => game.size.x > 0 ? game.size.x / 2 : 400.0;

  _TunnelBounds _boundsAtX(double x) {
    final offset = game.tunnelCenterOffsetAt(x);
    final halfH = game.tunnelHalfHeightAt(x);
    return _TunnelBounds(
      top: centerY + offset - halfH,
      bottom: centerY + offset + halfH,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!game.isTunnelMode) return;

    // Clamp player ai muri del tunnel — ERA dentro render() (violava
    // update/render split → jitter + race con update del player). Ora
    // in update() dove è lecito mutare lo stato di gioco.
    _checkWallCollision();

    // Tracking transizione boss → no-boss per attivare cooldown 15s.
    if (_prevBossCount > 0 && game.bossCount == 0) {
      _postBossCooldown = _kPostBossCooldown;
    }
    _prevBossCount = game.bossCount;
    if (_postBossCooldown > 0) _postBossCooldown -= dt;

    // Spawn ostacoli periodicamente.
    // Skip spawn: durante boss fight OR nei 15s successivi alla sconfitta.
    _obstacleSpawnTimer -= dt;
    if (_obstacleSpawnTimer <= 0 &&
        game.bossCount == 0 &&
        _postBossCooldown <= 0) {
      _obstacleSpawnTimer = 3.0 + _random.nextDouble() * 4.0;
      _spawnObstacle();
    }

    // Aggiorna ostacoli
    final cameraLeft = game.camera.viewfinder.position.x - _screenHalfW - 100;
    for (int i = _obstacles.length - 1; i >= 0; i--) {
      _obstacles[i].lifetime -= dt;
      _obstacles[i].phase += dt * 3;
      // Rimuovi ostacoli scaduti o passati dietro la camera
      if (_obstacles[i].lifetime <= 0 || _obstacles[i].x < cameraLeft) {
        _obstacles.removeAt(i);
        continue;
      }

      // Danno al player se tocca l'ostacolo
      final obs = _obstacles[i];
      final playerPos = game.player.position;
      final dx = (playerPos.x - obs.x).abs();
      if (dx < obs.width / 2) {
        // Il player è nella colonna dell'ostacolo
        final bounds = _boundsAtX(obs.x);
        final topWall = bounds.top;
        final bottomWall = bounds.bottom;
        if (obs.isTop) {
          // Ostacolo dal muro superiore
          if (playerPos.y < topWall + obs.height) {
            game.player.takeDamage();
            _obstacles.removeAt(i);
          }
        } else {
          // Ostacolo dal muro inferiore
          if (playerPos.y > bottomWall - obs.height) {
            game.player.takeDamage();
            _obstacles.removeAt(i);
          }
        }
      }
    }

    // Limita ostacoli
    while (_obstacles.length > 15) {
      _obstacles.removeAt(0);
    }
  }

  void _spawnObstacle() {
    // Spawna un ostacolo avanti alla camera (fuori schermo a destra)
    final cameraX = game.camera.viewfinder.position.x;
    final aheadX = cameraX + _screenHalfW + 100 + _random.nextDouble() * 300;
    final bounds = _boundsAtX(aheadX);
    final tunnelSpan = bounds.bottom - bounds.top;
    // Base 20% dello span + 3% per boss ucciso (da `game.tunnelObstacleScale`).
    // Jitter ±3% per variazione; cap hard a 45% span per non chiudere tunnel.
    final baseScale = game.tunnelObstacleScale;
    final obsHeight =
        (tunnelSpan * (baseScale + (_random.nextDouble() - 0.5) * 0.06))
            .clamp(25.0, tunnelSpan * 0.45);
    // Se un ostacolo esiste già a X ravvicinato, forza stesso lato:
    // garantisce un passaggio libero sul lato opposto.
    const sameSideRange = 160.0;
    bool? forcedSide;
    for (final existing in _obstacles) {
      if ((existing.x - aheadX).abs() < sameSideRange) {
        forcedSide = existing.isTop;
        break;
      }
    }
    _obstacles.add(_TunnelObstacle(
      x: aheadX,
      isTop: forcedSide ?? _random.nextBool(),
      width: 30 + _random.nextDouble() * 40,
      height: obsHeight,
      lifetime: 12.0,
    ));
  }

  // Scrolling particle bg (stile splash screen): parallax + strie.
  // Count dimezzato + size ridotto rispetto a splash per non affollare.
  // Pattern deterministico via seed costanti dentro `_renderScrollingBg`.
  static final Paint _bgStarPaint = Paint();
  static final Paint _bgStriePaint = Paint()..strokeCap = StrokeCap.round;

  @override
  void render(Canvas canvas) {
    if (!game.isTunnelMode) return;

    // Usa la posizione della camera per il viewport (non il player!)
    final cameraX = game.camera.viewfinder.position.x;
    final viewWidth = _screenHalfW + 100; // Larghezza visibile + margine
    final startX = cameraX - viewWidth;
    final endX = cameraX + viewWidth;

    final topWallY = centerY - tunnelH / 2;
    final bottomWallY = centerY + tunnelH / 2;

    // === PARTICELLE BG SCROLLING (stile splash screen) ===
    _renderScrollingBg(canvas, cameraX, viewWidth);

    // === MURI DEL TUNNEL (ondeggianti) ===
    _renderTunnelWalls(canvas, startX, endX, topWallY, bottomWallY);

    // === OSTACOLI ===
    _renderObstacles(canvas);

    // === LINEE GUIDA (effetto velocità) ===
    _renderSpeedLines(canvas, startX, endX, topWallY, bottomWallY);
  }

  /// Particelle bg stile splash: strie + stelle parallax scorrevoli.
  /// Count dimezzato (splash: 180+36 strie + 240+90+24 stelle → qui ~50 tot)
  /// e size ridotto per non distrarre dal gameplay.
  void _renderScrollingBg(Canvas canvas, double cameraX, double viewWidth) {
    final sizeY = game.size.y > 0 ? game.size.y : 600;
    final cameraY = game.camera.viewfinder.position.y;
    final topY = cameraY - sizeY / 2;
    // Uso `cameraX` come "scroll" globale: le particelle scorrono verso sx
    // mentre la camera avanza verso dx.

    // ─── STRIE (20 strie orizzontali a velocità variate) ───
    final strieRng = math.Random(77);
    for (int i = 0; i < 20; i++) {
      final yOffset = strieRng.nextDouble() * sizeY;
      final baseLen = 15.0 + strieRng.nextDouble() * 60;
      final speedMul = 0.8 + strieRng.nextDouble() * 2.0;
      final baseWorldX = strieRng.nextDouble() * viewWidth * 3;
      // Posizione in world: baseWorldX spostata a sx di cameraX * speedMul.
      final period = viewWidth * 2 + baseLen;
      final worldX = ((baseWorldX - cameraX * speedMul) % period + period) % period;
      final screenX = cameraX - viewWidth + worldX;
      final alpha = 0.04 + strieRng.nextDouble() * 0.06;
      _bgStriePaint.color = Color.fromRGBO(180, 210, 255, alpha);
      _bgStriePaint.strokeWidth = 0.3 + strieRng.nextDouble() * 0.4;
      canvas.drawLine(
        Offset(screenX, topY + yOffset),
        Offset(screenX + baseLen, topY + yOffset),
        _bgStriePaint,
      );
    }

    // ─── STELLE (25 totali, 3 layer profondità) ───
    final starRng = math.Random(42);
    for (int i = 0; i < 25; i++) {
      final baseWorldX = starRng.nextDouble() * viewWidth * 3;
      final yOffset = starRng.nextDouble() * sizeY;
      // Layer profondità: determina velocità + size + alpha
      final layer = i % 3; // 0=lontano, 1=medio, 2=vicino
      final speedMul = [0.3, 0.7, 1.4][layer];
      final starSize = [0.4, 0.7, 1.1][layer];
      final alpha = [0.25, 0.45, 0.65][layer];

      final period = viewWidth * 2 + 10;
      final worldX = ((baseWorldX - cameraX * speedMul) % period + period) % period;
      final screenX = cameraX - viewWidth + worldX;

      _bgStarPaint.color = Color.fromRGBO(200, 220, 255, alpha);
      canvas.drawCircle(Offset(screenX, topY + yOffset), starSize, _bgStarPaint);
    }
  }

  // Path cache riutilizzati: 4 Path × 60fps = 240 alloc/sec risparmiate.
  static final Path _topWallPath = Path();
  static final Path _bottomWallPath = Path();
  static final Path _topInnerPath = Path();
  static final Path _bottomInnerPath = Path();

  void _renderTunnelWalls(Canvas canvas, double startX, double endX,
      double topY, double bottomY) {
    final topPath = _topWallPath..reset();
    final bottomPath = _bottomWallPath..reset();
    bool firstTop = true, firstBottom = true;

    for (double x = startX; x <= endX; x += 6) {
      final offset = game.tunnelCenterOffsetAt(x);
      final halfH = game.tunnelHalfHeightAt(x);

      final ty = centerY + offset - halfH;
      final by = centerY + offset + halfH;

      if (firstTop) { topPath.moveTo(x, ty); firstTop = false; }
      else { topPath.lineTo(x, ty); }
      if (firstBottom) { bottomPath.moveTo(x, by); firstBottom = false; }
      else { bottomPath.lineTo(x, by); }
    }

    // Glow esterno dei muri — bianco fluo spesso
    _wallGlowPaint.color = const Color(0xFFFFFFFF).withValues(alpha: 0.15);
    canvas.drawPath(topPath, _wallGlowPaint);
    canvas.drawPath(bottomPath, _wallGlowPaint);

    // Muri principali
    canvas.drawPath(topPath, _wallMainPaint);
    canvas.drawPath(bottomPath, _wallMainPaint);

    // Seconda linea parallasse (interna)
    final topInner = _topInnerPath..reset();
    final bottomInner = _bottomInnerPath..reset();
    bool ft = true, fb = true;
    for (double x = startX; x <= endX; x += 10) {
      final offset = game.tunnelCenterOffsetAt(x);
      final halfH = game.tunnelHalfHeightAt(x);
      final ty = centerY + offset - halfH + 15;
      final by = centerY + offset + halfH - 15;
      if (ft) { topInner.moveTo(x, ty); ft = false; }
      else { topInner.lineTo(x, ty); }
      if (fb) { bottomInner.moveTo(x, by); fb = false; }
      else { bottomInner.lineTo(x, by); }
    }
    canvas.drawPath(topInner, _wallInnerPaint);
    canvas.drawPath(bottomInner, _wallInnerPaint);
    // NOTA: il wall clamp del player è ora in update() per rispettare lo
    // split update/render e evitare jitter.
  }

  /// Controlla se il player tocca i muri del tunnel e causa danno
  void _checkWallCollision() {
    final px = game.player.position.x;
    final py = game.player.position.y;
    final offset = game.tunnelCenterOffsetAt(px);
    final halfH = game.tunnelHalfHeightAt(px);
    final topWall = centerY + offset - halfH;
    final bottomWall = centerY + offset + halfH;

    // Clamp player dentro il tunnel (segue le curve!)
    if (py < topWall + 15) {
      game.player.position.y = topWall + 15;
    }
    if (py > bottomWall - 15) {
      game.player.position.y = bottomWall - 15;
    }
  }

  void _renderObstacles(Canvas canvas) {
    for (final obs in _obstacles) {
      final alpha = (obs.lifetime / 12.0).clamp(0.0, 1.0);
      final pulse = 0.7 + math.sin(obs.phase) * 0.3;

      final bounds = _boundsAtX(obs.x);
      final topY = bounds.top;
      final bottomY = bounds.bottom;
      final baseY = obs.isTop ? topY : bottomY;
      final endY = obs.isTop ? topY + obs.height : bottomY - obs.height;
      final rectTop = math.min(baseY, endY);
      final rectBottom = math.max(baseY, endY);
      final obsRect = Rect.fromLTRB(
        obs.x - obs.width / 2,
        rectTop,
        obs.x + obs.width / 2,
        rectBottom,
      );

      // Glow esterno (rosso scuro diffuso).
      _obsGlowPaint.color =
          const Color(0xFFFF0022).withValues(alpha: alpha * 0.18 * pulse);
      _obsGlowPaint.maskFilter = null;
      canvas.drawRect(obsRect.inflate(6), _obsGlowPaint);

      // ─── RED WAVE SEGMENTS (richiesta utente) ────────────────────
      // Divido l'altezza in 6 segmenti: ogni segmento ha intensità rossa
      // variabile con sin(phase + segIdx * k) → onda che viaggia lungo
      // l'ostacolo dall'alto verso il basso.
      const segments = 6;
      final totalH = rectBottom - rectTop;
      final segH = totalH / segments;
      // Direzione onda: verso l'interno del tunnel (dall'attacco al "punto").
      final waveDir = obs.isTop ? 1.0 : -1.0;
      for (int s = 0; s < segments; s++) {
        final segIdx = obs.isTop ? s : (segments - 1 - s);
        // wavePos viaggia 0→1 nel tempo, shiftata per segmento.
        final wavePhase = obs.phase * 1.6 + segIdx * 0.7 * waveDir;
        final wave = 0.5 + 0.5 * math.sin(wavePhase);
        // Interpola rosso scuro → rosso brillante → bianco caldo.
        final r = 255;
        final g = (wave * 90).round().clamp(0, 160);
        final b = (wave * 30).round().clamp(0, 60);
        final segAlpha = (alpha * (0.55 + wave * 0.35) * pulse).clamp(0.0, 1.0);
        _obsBarrierPaint.color = Color.fromRGBO(r, g, b, segAlpha);
        final segRect = Rect.fromLTRB(
          obsRect.left,
          rectTop + s * segH,
          obsRect.right,
          rectTop + (s + 1) * segH + 0.5, // +0.5 per coprire gap antialias
        );
        canvas.drawRect(segRect, _obsBarrierPaint);
      }

      // Highlight cresta onda: striscia bianca che scorre con la phase.
      final crestPos = (obs.phase * 0.25) % 1.0;
      final crestY = rectTop + crestPos * totalH;
      _obsBorderPaint.color = const Color(0xFFFFFFFF)
          .withValues(alpha: alpha * 0.45 * pulse);
      _obsBorderPaint.style = PaintingStyle.fill;
      canvas.drawRect(
        Rect.fromLTRB(obsRect.left, crestY - 1, obsRect.right, crestY + 1),
        _obsBorderPaint,
      );

      // Bordo luminoso esterno.
      _obsBorderPaint.style = PaintingStyle.stroke;
      _obsBorderPaint.color =
          const Color(0xFFFF2244).withValues(alpha: alpha * 0.85);
      canvas.drawRect(obsRect, _obsBorderPaint);
    }
  }

  void _renderSpeedLines(Canvas canvas, double startX, double endX,
      double topY, double bottomY) {
    final midY = (topY + bottomY) / 2;
    final halfH = (bottomY - topY) / 2;
    for (int i = 0; i < 8; i++) {
      final yOffset = (i - 3.5) / 4 * halfH * 0.8;
      canvas.drawLine(
        Offset(startX, midY + yOffset),
        Offset(endX, midY + yOffset),
        _speedLinePaint,
      );
    }
  }
}

/// Ostacolo nel tunnel (barriera laser)
class _TunnelObstacle {
  double x;
  bool isTop; // Dal muro superiore o inferiore
  double width;
  double height;
  double lifetime;
  double phase = 0;

  _TunnelObstacle({
    required this.x,
    required this.isTop,
    required this.width,
    required this.height,
    required this.lifetime,
  });
}

class _TunnelBounds {
  final double top;
  final double bottom;

  const _TunnelBounds({required this.top, required this.bottom});
}

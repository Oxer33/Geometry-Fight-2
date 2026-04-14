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
  static final _random = math.Random();

  // Cached static Paints
  static final _wallGlowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 10;
  static final _wallMainPaint = Paint()
    ..color = const Color(0xFF00FFFF).withValues(alpha: 0.6)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.5;
  static final _wallInnerPaint = Paint()
    ..color = const Color(0xFF0088AA).withValues(alpha: 0.15)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
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

  @override
  void update(double dt) {
    super.update(dt);
    if (!game.isTunnelMode) return;

    // Spawn ostacoli periodicamente
    _obstacleSpawnTimer -= dt;
    if (_obstacleSpawnTimer <= 0 && game.bossCount == 0) {
      _obstacleSpawnTimer = 3.0 + _random.nextDouble() * 4.0;
      _spawnObstacle();
    }

    // Aggiorna ostacoli
    final cameraLeft = game.camera.viewfinder.position.x - game.size.x / 2 - 100;
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
        final topWall = centerY - tunnelH / 2;
        final bottomWall = centerY + tunnelH / 2;
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
    final screenHalfW = game.size.x / 2;
    final aheadX = cameraX + screenHalfW + 100 + _random.nextDouble() * 300;
    _obstacles.add(_TunnelObstacle(
      x: aheadX,
      isTop: _random.nextBool(),
      width: 30 + _random.nextDouble() * 40,
      height: tunnelH * (0.2 + _random.nextDouble() * 0.25),
      lifetime: 12.0,
    ));
  }

  @override
  void render(Canvas canvas) {
    if (!game.isTunnelMode) return;

    // Usa la posizione della camera per il viewport (non il player!)
    final cameraX = game.camera.viewfinder.position.x;
    final viewWidth = game.size.x / 2 + 100; // Larghezza visibile + margine
    final startX = cameraX - viewWidth;
    final endX = cameraX + viewWidth;

    final topWallY = centerY - tunnelH / 2;
    final bottomWallY = centerY + tunnelH / 2;

    // === MURI DEL TUNNEL (ondeggianti) ===
    _renderTunnelWalls(canvas, startX, endX, topWallY, bottomWallY);

    // === OSTACOLI ===
    _renderObstacles(canvas, topWallY, bottomWallY);

    // === LINEE GUIDA (effetto velocità) ===
    _renderSpeedLines(canvas, startX, endX, topWallY, bottomWallY);
  }

  /// Calcola l'offset Y del centro del tunnel a una data posizione X.
  /// Usa noise multi-ottava per curve complesse e variabili.
  double _tunnelCenterOffset(double x) {
    // Seed deterministico basato su X per coerenza
    // Combina più frequenze per curve ampie, medie e strette
    final slow = math.sin(x * 0.0008) * 120; // Curve ampie e lente
    final med = math.sin(x * 0.003 + 1.7) * 60; // Curve medie
    final fast = math.sin(x * 0.008 + 3.1) * 25; // Oscillazioni rapide
    final sharp = math.sin(x * 0.015 + 0.5) * 15; // Micro-variazioni
    // Curve a S improvvise (usando atan per appiattimento)
    final sCurve = math.atan(math.sin(x * 0.002 + 2.3) * 3) * 50;
    return slow + med + fast + sharp + sCurve;
  }

  /// Calcola la metà altezza del tunnel a una data posizione X.
  /// Varia per creare strozzature e allargamenti.
  double _tunnelHalfHeight(double x) {
    final base = tunnelH / 2;
    // Variazioni di larghezza: strozzature e allargamenti
    final narrow = math.sin(x * 0.004 + 0.8) * base * 0.15;
    final wide = math.sin(x * 0.001 + 2.0) * base * 0.1;
    return (base + narrow + wide).clamp(base * 0.5, base * 1.3);
  }

  void _renderTunnelWalls(Canvas canvas, double startX, double endX,
      double topY, double bottomY) {
    final topPath = Path();
    final bottomPath = Path();
    bool firstTop = true, firstBottom = true;

    for (double x = startX; x <= endX; x += 6) {
      final offset = _tunnelCenterOffset(x);
      final halfH = _tunnelHalfHeight(x);

      final ty = centerY + offset - halfH;
      final by = centerY + offset + halfH;

      if (firstTop) { topPath.moveTo(x, ty); firstTop = false; }
      else { topPath.lineTo(x, ty); }
      if (firstBottom) { bottomPath.moveTo(x, by); firstBottom = false; }
      else { bottomPath.lineTo(x, by); }
    }

    // Glow esterno dei muri — senza blur, linea più spessa con alpha bassa
    _wallGlowPaint.color = const Color(0xFF00FFFF).withValues(alpha: 0.12);
    canvas.drawPath(topPath, _wallGlowPaint);
    canvas.drawPath(bottomPath, _wallGlowPaint);

    // Muri principali
    canvas.drawPath(topPath, _wallMainPaint);
    canvas.drawPath(bottomPath, _wallMainPaint);

    // Seconda linea parallasse (interna)
    final topInner = Path();
    final bottomInner = Path();
    bool ft = true, fb = true;
    for (double x = startX; x <= endX; x += 10) {
      final offset = _tunnelCenterOffset(x);
      final halfH = _tunnelHalfHeight(x);
      final ty = centerY + offset - halfH + 15;
      final by = centerY + offset + halfH - 15;
      if (ft) { topInner.moveTo(x, ty); ft = false; }
      else { topInner.lineTo(x, ty); }
      if (fb) { bottomInner.moveTo(x, by); fb = false; }
      else { bottomInner.lineTo(x, by); }
    }
    canvas.drawPath(topInner, _wallInnerPaint);
    canvas.drawPath(bottomInner, _wallInnerPaint);

    // Check collisione player con muri del tunnel
    _checkWallCollision();
  }

  /// Controlla se il player tocca i muri del tunnel e causa danno
  void _checkWallCollision() {
    final px = game.player.position.x;
    final py = game.player.position.y;
    final offset = _tunnelCenterOffset(px);
    final halfH = _tunnelHalfHeight(px);
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

  void _renderObstacles(Canvas canvas, double topY, double bottomY) {
    for (final obs in _obstacles) {
      final alpha = (obs.lifetime / 12.0).clamp(0.0, 1.0);
      final pulse = 0.7 + math.sin(obs.phase) * 0.3;

      // Barriera laser
      final baseY = obs.isTop ? topY : bottomY;
      final endY = obs.isTop ? topY + obs.height : bottomY - obs.height;
      final obsRect = Rect.fromLTRB(
        obs.x - obs.width / 2, math.min(baseY, endY),
        obs.x + obs.width / 2, math.max(baseY, endY),
      );

      // Glow — senza blur, rettangolo inflated
      _obsGlowPaint.color = const Color(0xFFFF2200).withValues(alpha: alpha * 0.15 * pulse);
      _obsGlowPaint.maskFilter = null;
      canvas.drawRect(obsRect.inflate(4), _obsGlowPaint);

      // Barriera principale
      _obsBarrierPaint.color = const Color(0xFFFF4400).withValues(alpha: alpha * 0.6 * pulse);
      canvas.drawRect(obsRect, _obsBarrierPaint);

      // Bordo luminoso
      _obsBorderPaint.color = const Color(0xFFFF6600).withValues(alpha: alpha * 0.8);
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

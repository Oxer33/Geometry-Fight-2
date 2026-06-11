import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/painting.dart' show RadialGradient, Alignment;
import '../../data/constants.dart';
import '../game_world.dart';

/// Stella singola nello sfondo spaziale
class _Star {
  double x, y;
  double size;
  double brightness;
  double twinkleSpeed;
  double twinklePhase;
  Color color;
  int layer; // 0 = lontano (lento), 1 = medio, 2 = vicino (veloce)

  _Star({
    required this.x,
    required this.y,
    required this.size,
    required this.brightness,
    required this.twinkleSpeed,
    required this.twinklePhase,
    required this.color,
    required this.layer,
  });
}

/// Nebulosa: alone colorato sfumato nello sfondo
class _Nebula {
  double x, y;
  double radius;
  Color color;
  double alpha;
  double rotationSpeed;
  double phase;

  _Nebula({
    required this.x,
    required this.y,
    required this.radius,
    required this.color,
    required this.alpha,
    required this.rotationSpeed,
    required this.phase,
  });
}

/// Sfondo spaziale con stelle parallax, nebulose e dust particles.
/// Dà sensazione di profondità e movimento quando il player si sposta.
class SpaceBackground extends PositionComponent
    with HasGameReference<GeometryFightGame> {
  final List<_Star> _stars = [];
  final List<_Nebula> _nebulae = [];
  final List<_DustParticle> _dust = [];

  static final _random = math.Random();

  // Numero di stelle per layer (lontano, medio, vicino)
  static const int _farStars = 200;
  static const int _midStars = 120;
  static const int _nearStars = 60;
  static const int _nebulaCount = 8;
  static const int _dustCount = 80;

  double _time = 0;

  // Colori delle stelle per varietà
  static const List<Color> _starColors = [
    Color(0xFFFFFFFF), // bianco
    Color(0xFFCCDDFF), // bianco-azzurro
    Color(0xFFAABBFF), // azzurro chiaro
    Color(0xFFFFDDAA), // giallo caldo
    Color(0xFFFFAABB), // rosa pallido
    Color(0xFF88CCFF), // blu cielo
  ];

  // Colori delle nebulose
  static const List<Color> _nebulaColors = [
    Color(0xFF1A0033), // viola scuro
    Color(0xFF001A33), // blu scuro
    Color(0xFF0D1A2E), // blu notte
    Color(0xFF1A0A2E), // indaco
    Color(0xFF0A1A1A), // teal scuro
    Color(0xFF200A1A), // magenta scuro
    Color(0xFF002222), // acquamarina scuro
    Color(0xFF1A1A00), // giallo-verde scuro
  ];

  SpaceBackground() : super(priority: -20); // Sotto la griglia (-10)

  @override
  Future<void> onLoad() async {
    // Genera stelle lontane (piccole, lente)
    for (int i = 0; i < _farStars; i++) {
      _stars.add(_generateStar(0));
    }
    // Stelle medie
    for (int i = 0; i < _midStars; i++) {
      _stars.add(_generateStar(1));
    }
    // Stelle vicine (grandi, veloci)
    for (int i = 0; i < _nearStars; i++) {
      _stars.add(_generateStar(2));
    }

    // Genera nebulose
    for (int i = 0; i < _nebulaCount; i++) {
      _nebulae.add(
        _Nebula(
          x: _random.nextDouble() * arenaWidth,
          y: _random.nextDouble() * arenaHeight,
          radius: 200 + _random.nextDouble() * 400,
          color: _nebulaColors[_random.nextInt(_nebulaColors.length)],
          alpha: 0.15 + _random.nextDouble() * 0.2,
          rotationSpeed: (_random.nextDouble() - 0.5) * 0.1,
          phase: _random.nextDouble() * math.pi * 2,
        ),
      );
    }

    // Genera particelle di polvere cosmica
    for (int i = 0; i < _dustCount; i++) {
      _dust.add(
        _DustParticle(
          x: _random.nextDouble() * arenaWidth,
          y: _random.nextDouble() * arenaHeight,
          size: 1 + _random.nextDouble() * 2,
          speed: 5 + _random.nextDouble() * 15,
          angle: _random.nextDouble() * math.pi * 2,
          alpha: 0.1 + _random.nextDouble() * 0.2,
          color: _starColors[_random.nextInt(_starColors.length)],
        ),
      );
    }
  }

  _Star _generateStar(int layer) {
    // Dimensione e luminosità in base al layer
    double minSize, maxSize, minBright, maxBright;
    switch (layer) {
      case 0: // lontano
        minSize = 0.3;
        maxSize = 1.2;
        minBright = 0.2;
        maxBright = 0.5;
      case 1: // medio
        minSize = 0.8;
        maxSize = 2.0;
        minBright = 0.4;
        maxBright = 0.7;
      default: // vicino
        minSize = 1.5;
        maxSize = 3.5;
        minBright = 0.6;
        maxBright = 1.0;
    }

    return _Star(
      x: _random.nextDouble() * arenaWidth,
      y: _random.nextDouble() * arenaHeight,
      size: minSize + _random.nextDouble() * (maxSize - minSize),
      brightness: minBright + _random.nextDouble() * (maxBright - minBright),
      twinkleSpeed: 1 + _random.nextDouble() * 4,
      twinklePhase: _random.nextDouble() * math.pi * 2,
      color: _starColors[_random.nextInt(_starColors.length)],
      layer: layer,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;

    // Aggiorna particelle di polvere cosmica (drift lento)
    for (final d in _dust) {
      d.x += math.cos(d.angle) * d.speed * dt;
      d.y += math.sin(d.angle) * d.speed * dt;

      // Wrap around nell'arena
      if (d.x < 0) d.x += arenaWidth;
      if (d.x > arenaWidth) d.x -= arenaWidth;
      if (d.y < 0) d.y += arenaHeight;
      if (d.y > arenaHeight) d.y -= arenaHeight;

      // Leggera oscillazione dell'angolo
      d.angle += (math.sin(_time * 0.5 + d.x * 0.01) * 0.01);
    }
  }

  @override
  void render(Canvas canvas) {
    // === 1. SFONDO GRADIENTE SCURO (non nero piatto!) ===
    _renderDeepSpaceGradient(canvas);

    // === 2. NEBULOSE (alone colorato sfumato) ===
    _renderNebulae(canvas);

    // === 3. STELLE con twinkle ===
    _renderStars(canvas);

    // === 4. POLVERE COSMICA ===
    _renderDust(canvas);
  }

  static final _bgPaint = Paint();
  // Static: arena dimensions are compile-time constants (arenaWidth/arenaHeight
  // never change at runtime), so the background shader can be safely shared
  // across all SpaceBackground instances. If arena sizing becomes dynamic,
  // promote this to an instance field.
  static Shader? _bgShader;

  void _renderDeepSpaceGradient(Canvas canvas) {
    final rect = const Rect.fromLTWH(0, 0, arenaWidth, arenaHeight);
    // Cache del gradiente statico (non cambia mai)
    _bgShader ??= const RadialGradient(
      center: Alignment.center,
      radius: 0.8,
      colors: [
        Color(0xFF0A0E1A),
        Color(0xFF060A14),
        Color(0xFF030508),
        Color(0xFF010203),
      ],
      stops: [0.0, 0.3, 0.6, 1.0],
    ).createShader(rect);

    _bgPaint.shader = _bgShader;
    canvas.drawRect(rect, _bgPaint);
  }

  static final _nebulaPaint = Paint();

  // Cache degli shader per nebula — evita 480 alloc/sec (8 nebule × 60fps)
  final Map<int, Shader> _nebulaShaderCache = {};

  void _renderNebulae(Canvas canvas) {
    for (int i = 0; i < _nebulae.length; i++) {
      final nebula = _nebulae[i];
      // Pulsazione lenta della nebulosa
      final pulse = 1.0 + math.sin(_time * 0.3 + nebula.phase) * 0.1;
      final currentRadius = nebula.radius * pulse;
      final currentAlpha =
          nebula.alpha * (0.8 + math.sin(_time * 0.2 + nebula.phase * 2) * 0.2);

      final nebulaRect = Rect.fromCircle(
        center: Offset(nebula.x, nebula.y),
        radius: currentRadius,
      );

      // Quantizza alpha e radius per chiave cache (riduce variazioni continue)
      final quantizedAlpha = (currentAlpha * 20).round();
      final quantizedRadius = (currentRadius / 5).round() * 5;
      final cacheKey = i * 10000 + quantizedAlpha * 100 + quantizedRadius;

      Shader shader;
      if (_nebulaShaderCache.containsKey(cacheKey)) {
        shader = _nebulaShaderCache[cacheKey]!;
      } else {
        shader = RadialGradient(
          colors: [
            nebula.color.withValues(alpha: currentAlpha),
            nebula.color.withValues(alpha: currentAlpha * 0.5),
            nebula.color.withValues(alpha: 0),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(nebulaRect);
        _nebulaShaderCache[cacheKey] = shader;
        // Eviction FIFO parziale (era `.clear()` che causava GPU stutter
        // visibile: 200 shader dumped in un frame → spike).
        if (_nebulaShaderCache.length > 200) {
          final toEvict = _nebulaShaderCache.keys.take(100).toList();
          for (final k in toEvict) {
            _nebulaShaderCache[k]?.dispose();
            _nebulaShaderCache.remove(k);
          }
        }
      }

      _nebulaPaint.shader = shader;
      canvas.drawCircle(
        Offset(nebula.x, nebula.y),
        currentRadius,
        _nebulaPaint,
      );
    }
  }

  static final _starPaint = Paint();

  void _renderStars(Canvas canvas) {
    for (final star in _stars) {
      // Calcola twinkle (scintillio)
      final twinkle =
          0.5 + 0.5 * math.sin(_time * star.twinkleSpeed + star.twinklePhase);
      final alpha = star.brightness * twinkle;

      // Glow esterno (solo stelle grandi) — senza blur, cerchio più grande con alpha bassa
      if (star.size > 1.5) {
        _starPaint.color = star.color.withValues(alpha: alpha * 0.15);
        _starPaint.maskFilter = null;
        canvas.drawCircle(Offset(star.x, star.y), star.size * 2.5, _starPaint);
      }

      // Corpo della stella
      _starPaint.color = star.color.withValues(alpha: alpha);
      canvas.drawCircle(Offset(star.x, star.y), star.size, _starPaint);

      // Centro luminoso per stelle grandi
      if (star.size > 2.0) {
        _starPaint.color = const Color(
          0xFFFFFFFF,
        ).withValues(alpha: alpha * 0.8);
        canvas.drawCircle(Offset(star.x, star.y), star.size * 0.4, _starPaint);
      }
    }
  }

  static final _dustPaint = Paint();

  void _renderDust(Canvas canvas) {
    for (final d in _dust) {
      // Pulsazione lenta dell'alpha
      final pulse = 0.7 + 0.3 * math.sin(_time * 1.5 + d.x * 0.01);
      _dustPaint.color = d.color.withValues(alpha: d.alpha * pulse);
      _dustPaint.maskFilter = null;
      // Cerchio leggermente più grande al posto del blur per effetto morbido
      canvas.drawCircle(Offset(d.x, d.y), d.size * 1.5, _dustPaint);
    }
  }

  @override
  void onRemove() {
    // Dispose tutti gli Shader cached della nebula per evitare leak GPU
    // quando lo sfondo è rimosso (restart, change scene, dispose).
    // Il `_bgShader` è static e condiviso → NON dispose qui (vive col process).
    for (final shader in _nebulaShaderCache.values) {
      shader.dispose();
    }
    _nebulaShaderCache.clear();
    super.onRemove();
  }
}

/// Particella di polvere cosmica che fluttua lentamente
class _DustParticle {
  double x, y;
  double size;
  double speed;
  double angle;
  double alpha;
  Color color;

  _DustParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.angle,
    required this.alpha,
    required this.color,
  });
}

/// Bordo dell'arena classica: rettangolo 4x più spesso + bianco fluo.
/// Mountato in game_world con priority basso per non coprire entità.
/// In tunnel mode non disegna nulla (il tunnel ha i suoi muri).
class ArenaBorder extends PositionComponent
    with HasGameReference<GeometryFightGame> {
  // Bordo arena bianco fluo — spessore dimezzato rispetto prima (era 32/12/4)
  static final _borderGlowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 16
    ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.15);
  static final _borderMainPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 6
    ..color = const Color(0xFFFFFFFF);
  static final _borderInnerPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.85);

  // priority -5 = sopra background/grid ma SOTTO entità (player/nemici default 0)
  ArenaBorder() : super(priority: -5);

  @override
  void render(Canvas canvas) {
    // Non disegnare il bordo in tunnel mode (il tunnel ha i suoi muri)
    if (game.isTunnelMode) return;
    // Modifier tiny_arena: bordo dell'arena effettiva centrata (non più full).
    final rect = Rect.fromLTRB(
      game.arenaMinX,
      game.arenaMinY,
      game.arenaMaxX,
      game.arenaMaxY,
    );
    canvas.drawRect(rect, _borderGlowPaint);
    canvas.drawRect(rect, _borderMainPaint);
    canvas.drawRect(rect, _borderInnerPaint);
  }
}

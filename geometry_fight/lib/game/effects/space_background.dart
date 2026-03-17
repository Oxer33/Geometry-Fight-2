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
      _nebulae.add(_Nebula(
        x: _random.nextDouble() * arenaWidth,
        y: _random.nextDouble() * arenaHeight,
        radius: 200 + _random.nextDouble() * 400,
        color: _nebulaColors[_random.nextInt(_nebulaColors.length)],
        alpha: 0.15 + _random.nextDouble() * 0.2,
        rotationSpeed: (_random.nextDouble() - 0.5) * 0.1,
        phase: _random.nextDouble() * math.pi * 2,
      ));
    }

    // Genera particelle di polvere cosmica
    for (int i = 0; i < _dustCount; i++) {
      _dust.add(_DustParticle(
        x: _random.nextDouble() * arenaWidth,
        y: _random.nextDouble() * arenaHeight,
        size: 1 + _random.nextDouble() * 2,
        speed: 5 + _random.nextDouble() * 15,
        angle: _random.nextDouble() * math.pi * 2,
        alpha: 0.1 + _random.nextDouble() * 0.2,
        color: _starColors[_random.nextInt(_starColors.length)],
      ));
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

  void _renderDeepSpaceGradient(Canvas canvas) {
    // Gradiente radiale dal centro dell'arena: blu notte -> nero
    final gradient = RadialGradient(
      center: Alignment.center,
      radius: 0.8,
      colors: const [
        Color(0xFF0A0E1A), // Blu notte profondo al centro
        Color(0xFF060A14), // Blu scurissimo
        Color(0xFF030508), // Quasi nero
        Color(0xFF010203), // Nero profondo ai bordi
      ],
      stops: const [0.0, 0.3, 0.6, 1.0],
    );

    final rect = Rect.fromLTWH(0, 0, arenaWidth, arenaHeight);
    final paint = Paint()
      ..shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);
  }

  void _renderNebulae(Canvas canvas) {
    for (final nebula in _nebulae) {
      // Pulsazione lenta della nebulosa
      final pulse = 1.0 + math.sin(_time * 0.3 + nebula.phase) * 0.1;
      final currentRadius = nebula.radius * pulse;
      final currentAlpha = nebula.alpha *
          (0.8 + math.sin(_time * 0.2 + nebula.phase * 2) * 0.2);

      // Gradiente radiale per ogni nebulosa
      final nebulaGradient = RadialGradient(
        colors: [
          nebula.color.withValues(alpha: currentAlpha),
          nebula.color.withValues(alpha: currentAlpha * 0.5),
          nebula.color.withValues(alpha: 0),
        ],
        stops: const [0.0, 0.5, 1.0],
      );

      final nebulaRect = Rect.fromCircle(
        center: Offset(nebula.x, nebula.y),
        radius: currentRadius,
      );

      final paint = Paint()
        ..shader = nebulaGradient.createShader(nebulaRect);
      canvas.drawCircle(Offset(nebula.x, nebula.y), currentRadius, paint);
    }
  }

  void _renderStars(Canvas canvas) {
    final paint = Paint();

    for (final star in _stars) {
      // Calcola twinkle (scintillio)
      final twinkle = 0.5 +
          0.5 * math.sin(_time * star.twinkleSpeed + star.twinklePhase);
      final alpha = star.brightness * twinkle;

      // Glow esterno (solo stelle grandi)
      if (star.size > 1.5) {
        paint
          ..color = star.color.withValues(alpha: alpha * 0.3)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, star.size * 3);
        canvas.drawCircle(Offset(star.x, star.y), star.size * 2, paint);
      }

      // Corpo della stella
      paint
        ..color = star.color.withValues(alpha: alpha)
        ..maskFilter = null;
      canvas.drawCircle(Offset(star.x, star.y), star.size, paint);

      // Centro luminoso per stelle grandi
      if (star.size > 2.0) {
        paint.color = const Color(0xFFFFFFFF).withValues(alpha: alpha * 0.8);
        canvas.drawCircle(Offset(star.x, star.y), star.size * 0.4, paint);
      }
    }
  }

  void _renderDust(Canvas canvas) {
    final paint = Paint();

    for (final d in _dust) {
      // Pulsazione lenta dell'alpha
      final pulse = 0.7 + 0.3 * math.sin(_time * 1.5 + d.x * 0.01);
      paint
        ..color = d.color.withValues(alpha: d.alpha * pulse)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, d.size);
      canvas.drawCircle(Offset(d.x, d.y), d.size, paint);
    }
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

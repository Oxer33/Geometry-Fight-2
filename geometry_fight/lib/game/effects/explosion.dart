import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/painting.dart' show TextPainter, TextSpan, TextStyle, FontWeight;
import 'package:flame/components.dart';

class _Particle {
  Vector2 position;
  Vector2 velocity;
  double lifetime;
  double maxLifetime;
  double size;
  Color color;

  _Particle({
    required this.position,
    required this.velocity,
    required this.lifetime,
    required this.size,
    required this.color,
  }) : maxLifetime = lifetime;

  double get progress => 1.0 - (lifetime / maxLifetime);
}

class ExplosionEffect extends PositionComponent {
  final Color color;
  final double radius;
  final int particleCount;
  final bool epic; // Esplosioni speciali con anelli e glow extra
  final List<_Particle> _particles = [];
  double _flashTimer = 0.12;
  double _ringTimer = 0;
  double _age = 0;

  static final _random = math.Random();
  static final _flashPaint = Paint();
  static final _particlePaint = Paint();
  static final _ringPaint = Paint()..style = PaintingStyle.stroke;

  ExplosionEffect({
    required this.color,
    this.radius = 50,
    this.particleCount = 20,
    this.epic = false,
  }) : super(size: Vector2.all(radius * 3), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    final count = epic ? particleCount * 2 : particleCount;
    for (int i = 0; i < count; i++) {
      final angle = _random.nextDouble() * math.pi * 2;
      final speed = 50 + _random.nextDouble() * radius * 3;

      // Mix di colori: colore base + bianco + variazione
      Color pColor;
      final roll = _random.nextDouble();
      if (roll < 0.5) {
        pColor = color;
      } else if (roll < 0.75) {
        pColor = const Color(0xFFFFFFFF); // Scintille bianche
      } else {
        // Colore leggermente diverso (shift hue)
        final r = ((color.r * 255).round() + _random.nextInt(60) - 30)
            .clamp(0, 255)
            .toInt();
        final g = ((color.g * 255).round() + _random.nextInt(60) - 30)
            .clamp(0, 255)
            .toInt();
        final b = ((color.b * 255).round() + _random.nextInt(60) - 30)
            .clamp(0, 255)
            .toInt();
        pColor = Color.fromARGB(255, r, g, b);
      }

      _particles.add(_Particle(
        position: Vector2.zero(),
        velocity: Vector2(math.cos(angle) * speed, math.sin(angle) * speed),
        lifetime: 0.3 + _random.nextDouble() * 0.6,
        size: epic ? 2.5 + _random.nextDouble() * 5 : 2 + _random.nextDouble() * 4,
        color: pColor,
      ));
    }
    // Se epic, aggiungi particelle lente per scia persistente
    if (epic) {
      for (int i = 0; i < 8; i++) {
        final angle = _random.nextDouble() * math.pi * 2;
        final speed = 20 + _random.nextDouble() * 40;
        _particles.add(_Particle(
          position: Vector2.zero(),
          velocity: Vector2(math.cos(angle) * speed, math.sin(angle) * speed),
          lifetime: 0.6 + _random.nextDouble() * 0.4,
          size: 4 + _random.nextDouble() * 3,
          color: color,
        ));
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _flashTimer -= dt;
    _age += dt;
    if (epic) _ringTimer = _age;

    bool allDead = true;
    for (final p in _particles) {
      p.lifetime -= dt;
      if (p.lifetime > 0) {
        allDead = false;
        p.position += p.velocity * dt;
        p.velocity *= epic ? 0.93 : 0.95;
      }
    }

    final ringsDone = !epic || _ringTimer > 0.6;
    if (allDead && ringsDone) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2;
    final cy = size.y / 2;

    // === SHOCKWAVE RINGS (solo epic) ===
    if (epic && _ringTimer < 0.5) {
      for (int i = 0; i < 3; i++) {
        final delay = i * 0.06;
        final t = (_ringTimer - delay).clamp(0.0, 0.5);
        if (t <= 0) continue;
        final ringR = t / 0.5 * radius * 1.8;
        final ringAlpha = (1.0 - t / 0.5) * 0.6;
        _ringPaint.color = color.withValues(alpha: ringAlpha);
        _ringPaint.strokeWidth = (3.0 - i * 0.8).clamp(0.5, 3.0);
        _ringPaint.maskFilter = null;
        canvas.drawCircle(Offset(cx, cy), ringR, _ringPaint);
      }
    }

    // === FLASH CENTRALE ===
    if (_flashTimer > 0) {
      final flashAlpha = (_flashTimer / 0.12).clamp(0.0, 1.0);
      // Glow colorato — senza blur, cerchio più grande con alpha bassa
      _flashPaint.color = color.withValues(alpha: flashAlpha * 0.25);
      _flashPaint.maskFilter = null;
      canvas.drawCircle(Offset(cx, cy), radius * (epic ? 1.2 : 0.8), _flashPaint);
      // Core colorato
      _flashPaint.color = color.withValues(alpha: flashAlpha * 0.5);
      canvas.drawCircle(Offset(cx, cy), radius * (epic ? 0.8 : 0.5), _flashPaint);
      // Core bianco
      _flashPaint.color = const Color(0xFFFFFFFF).withValues(alpha: flashAlpha * 0.8);
      canvas.drawCircle(Offset(cx, cy), radius * (epic ? 0.4 : 0.25), _flashPaint);
    }

    // === PARTICELLE ===
    for (final p in _particles) {
      if (p.lifetime <= 0) continue;
      final alpha = (p.lifetime / p.maxLifetime).clamp(0.0, 1.0);
      final pSize = p.size * alpha;

      // Glow per particelle grandi (epic) — senza blur
      if (epic && p.size > 4) {
        _particlePaint.color = p.color.withValues(alpha: alpha * 0.2);
        _particlePaint.maskFilter = null;
        canvas.drawCircle(
          Offset(cx + p.position.x, cy + p.position.y),
          pSize * 2,
          _particlePaint,
        );
      }

      // Particella principale
      _particlePaint.color = p.color.withValues(alpha: alpha);
      canvas.drawCircle(
        Offset(cx + p.position.x, cy + p.position.y),
        pSize,
        _particlePaint,
      );
    }
  }
}

class FloatingText extends PositionComponent {
  final String text;
  final Color color;
  double _lifetime = 1.0;
  double _velocity = -80;

  TextPainter? _cachedPainter;
  double _lastAlpha = -1;

  FloatingText({required this.text, required this.color})
      : super(anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    _lifetime -= dt;
    position.y += _velocity * dt;
    _velocity *= 0.95;
    if (_lifetime <= 0) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final alpha = _lifetime.clamp(0.0, 1.0);
    final quantizedAlpha = (alpha * 10).roundToDouble() / 10;
    if (_cachedPainter == null || quantizedAlpha != _lastAlpha) {
      _lastAlpha = quantizedAlpha;
      _cachedPainter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: color.withValues(alpha: quantizedAlpha),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
    }
    _cachedPainter!.paint(canvas, Offset(-_cachedPainter!.width / 2, -_cachedPainter!.height / 2));
  }
}

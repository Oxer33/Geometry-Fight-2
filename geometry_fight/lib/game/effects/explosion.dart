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
  final List<_Particle> _particles = [];
  double _flashTimer = 0.1;

  static final _random = math.Random();
  // Paint cache — riutilizzato per TUTTE le esplosioni, evita 40+ allocazioni/frame
  static final _flashPaint = Paint();
  static final _particlePaint = Paint();

  ExplosionEffect({
    required this.color,
    this.radius = 50,
    this.particleCount = 20,
  }) : super(size: Vector2.all(radius * 2), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    for (int i = 0; i < particleCount; i++) {
      final angle = _random.nextDouble() * math.pi * 2;
      final speed = 50 + _random.nextDouble() * radius * 3;
      _particles.add(_Particle(
        position: Vector2.zero(),
        velocity: Vector2(math.cos(angle) * speed, math.sin(angle) * speed),
        lifetime: 0.3 + _random.nextDouble() * 0.5,
        size: 2 + _random.nextDouble() * 4,
        color: color,
      ));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _flashTimer -= dt;

    bool allDead = true;
    for (final p in _particles) {
      p.lifetime -= dt;
      if (p.lifetime > 0) {
        allDead = false;
        p.position += p.velocity * dt;
        p.velocity *= 0.95; // Friction
      }
    }

    if (allDead) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2;
    final cy = size.y / 2;

    // Flash (senza blur — troppo costoso con esplosioni multiple)
    if (_flashTimer > 0) {
      _flashPaint.color = const Color(0xFFFFFFFF).withValues(alpha: _flashTimer * 10);
      _flashPaint.maskFilter = null;
      canvas.drawCircle(Offset(cx, cy), radius * 0.5, _flashPaint);
    }

    // Particles (senza blur — risparmia 20+ blur pass per esplosione)
    _particlePaint.maskFilter = null;
    for (final p in _particles) {
      if (p.lifetime <= 0) continue;
      final alpha = (p.lifetime / p.maxLifetime).clamp(0.0, 1.0);
      _particlePaint.color = p.color.withValues(alpha: alpha);
      canvas.drawCircle(
        Offset(cx + p.position.x, cy + p.position.y),
        p.size * alpha,
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

  // Cache TextPainter — creato una volta, non ogni frame
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
    // Rigenera TextPainter solo se alpha è cambiato significativamente
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

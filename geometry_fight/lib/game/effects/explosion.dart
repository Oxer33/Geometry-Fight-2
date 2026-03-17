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

    // Flash
    if (_flashTimer > 0) {
      final flashPaint = Paint()
        ..color = const Color(0xFFFFFFFF).withValues(alpha: _flashTimer * 10)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
      canvas.drawCircle(Offset(cx, cy), radius * 0.5, flashPaint);
    }

    // Particles
    for (final p in _particles) {
      if (p.lifetime <= 0) continue;
      final alpha = (p.lifetime / p.maxLifetime).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = p.color.withValues(alpha: alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(
        Offset(cx + p.position.x, cy + p.position.y),
        p.size * alpha,
        paint,
      );
    }
  }
}

class FloatingText extends PositionComponent {
  final String text;
  final Color color;
  double _lifetime = 1.0;
  double _velocity = -80;

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
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color.withValues(alpha: alpha),
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
  }
}

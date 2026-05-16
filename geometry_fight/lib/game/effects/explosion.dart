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
  final Paint _flashPaint = Paint();
  final Paint _particlePaint = Paint();
  final Paint _ringPaint = Paint()..style = PaintingStyle.stroke;

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

  // Durata totale dei tre shockwave ring (tutti — epic e standard)
  static const double _ringDuration = 0.45;
  // Colore rosso fluo fisso per i ring (indipendente dal colore dell'esplosione)
  static const Color _ringColor = Color(0xFFFF0040);

  @override
  void update(double dt) {
    super.update(dt);
    _flashTimer -= dt;
    _age += dt;
    _ringTimer = _age;

    bool allDead = true;
    // Frame-rate-independent damping: pow(factor, dt*60) normalizza
    // su 60Hz, evita particles che si fermano 2× più veloci a 120Hz.
    final dampFactor = math.pow(epic ? 0.93 : 0.95, dt * 60.0).toDouble();
    for (final p in _particles) {
      p.lifetime -= dt;
      if (p.lifetime > 0) {
        allDead = false;
        p.position += p.velocity * dt;
        p.velocity *= dampFactor;
      }
    }

    final ringsDone = _ringTimer > _ringDuration + 0.15;
    if (allDead && ringsDone) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2;
    final cy = size.y / 2;

    // === 3 SHOCKWAVE RING ROSSO FLUO — si espandono rapidamente, no fill ===
    // Leggermente sfasati tra loro per effetto "onda multipla".
    if (_ringTimer < _ringDuration + 0.1) {
      final maxR = radius * (epic ? 2.0 : 1.6);
      _ringPaint.style = PaintingStyle.stroke;
      _ringPaint.maskFilter = null;
      for (int i = 0; i < 3; i++) {
        final delay = i * 0.05;
        final t = (_ringTimer - delay).clamp(0.0, _ringDuration);
        if (t <= 0) continue;
        final progress = t / _ringDuration;
        // Scala raggio diverso per ogni ring così sono leggermente distanti tra loro
        final ringR = progress * maxR * (1.0 - i * 0.12);
        final ringAlpha = (1.0 - progress).clamp(0.0, 1.0);
        _ringPaint.color = _ringColor.withValues(alpha: ringAlpha);
        _ringPaint.strokeWidth = (5.0 - i * 0.8).clamp(2.0, 5.0);
        canvas.drawCircle(Offset(cx, cy), ringR, _ringPaint);
      }
    }

    // === FLASH CENTRALE (solo epic — mantiene l'impatto dei boss) ===
    if (epic && _flashTimer > 0) {
      final flashAlpha = (_flashTimer / 0.12).clamp(0.0, 1.0);
      _flashPaint.color = color.withValues(alpha: flashAlpha * 0.25);
      _flashPaint.maskFilter = null;
      canvas.drawCircle(Offset(cx, cy), radius * 1.2, _flashPaint);
      _flashPaint.color = color.withValues(alpha: flashAlpha * 0.5);
      canvas.drawCircle(Offset(cx, cy), radius * 0.8, _flashPaint);
      _flashPaint.color = const Color(0xFFFFFFFF).withValues(alpha: flashAlpha * 0.8);
      canvas.drawCircle(Offset(cx, cy), radius * 0.4, _flashPaint);
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
    // Frame-rate-independent damping.
    _velocity *= math.pow(0.95, dt * 60.0).toDouble();
    if (_lifetime <= 0) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final alpha = _lifetime.clamp(0.0, 1.0);
    final quantizedAlpha = (alpha * 10).roundToDouble() / 10;
    if (_cachedPainter == null || quantizedAlpha != _lastAlpha) {
      _lastAlpha = quantizedAlpha;
      _cachedPainter?.dispose();
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

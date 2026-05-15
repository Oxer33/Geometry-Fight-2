import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';

/// Effetto visivo Chain Lightning: arco neon zigzag che collega N punti
/// (player → enemy1 → enemy2 → ...). Auto-rimozione dopo `_duration`s.
/// Spawnato come component world-space con position zero — coordinate
/// `_points` sono assolute nel world. Niente damage (gestito da chiamante).
class ChainLightningEffect extends PositionComponent {
  final List<Vector2> _points;
  final Color color;
  final Color coreColor;
  double _age = 0;
  static const double _duration = 0.35;
  static final _rng = math.Random();
  // Iter 13 (caveman): instance Paints (no static) per evitare shared
  // state corruption se più effect render contemporaneamente. Allocate
  // 3 Paint per effect — accettabile dato che vivono solo 0.35s.
  final Paint _glowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 6
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
  final Paint _bodyPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.5;
  final Paint _corePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;

  ChainLightningEffect({
    required List<Vector2> points,
    this.color = const Color(0xFFFFFF44),
    this.coreColor = const Color(0xFFFFFFFF),
  }) : _points = points;

  @override
  void update(double dt) {
    _age += dt;
    if (_age >= _duration) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    if (_points.length < 2) return;
    final t = (_age / _duration).clamp(0.0, 1.0);
    final alpha = (1 - t).clamp(0.0, 1.0);
    _glowPaint.color = color.withValues(alpha: 0.6 * alpha);
    _bodyPaint.color = color.withValues(alpha: 0.95 * alpha);
    _corePaint.color = coreColor.withValues(alpha: alpha);

    for (int i = 0; i < _points.length - 1; i++) {
      _drawJaggedSegment(canvas, _points[i], _points[i + 1]);
    }
  }

  void _drawJaggedSegment(Canvas canvas, Vector2 a, Vector2 b) {
    final dist = (b - a).length;
    final steps = (dist / 18).clamp(2, 12).toInt();
    final dir = (b - a) / steps.toDouble();
    final perp = Vector2(-dir.y, dir.x).normalized();
    final path = Path()..moveTo(a.x, a.y);
    for (int s = 1; s < steps; s++) {
      final base = a + dir * s.toDouble();
      final jitter = (_rng.nextDouble() - 0.5) * 12;
      final p = base + perp * jitter;
      path.lineTo(p.x, p.y);
    }
    path.lineTo(b.x, b.y);
    canvas.drawPath(path, _glowPaint);
    canvas.drawPath(path, _bodyPaint);
    canvas.drawPath(path, _corePaint);
  }
}

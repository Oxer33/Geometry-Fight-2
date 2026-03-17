import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../../../data/constants.dart';
import 'enemy_base.dart';

class SnakeEnemy extends EnemyBase {
  final int segmentCount;
  final List<Vector2> _segments = [];
  final List<Vector2> _segmentVelocities = [];
  final bool isFragment;

  SnakeEnemy({this.segmentCount = 8, this.isFragment = false})
      : super(
          hp: 1,
          speed: 120,
          pointValue: 100,
          geomValue: 2,
          neonColor: NeonColors.green,
          size: Vector2(12, 12),
        ) {
    hp = segmentCount.toDouble();
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _segments.clear();
    for (int i = 0; i < segmentCount; i++) {
      _segments.add(position - Vector2(0, i * 14.0));
      _segmentVelocities.add(Vector2.zero());
    }
  }

  @override
  void updateBehavior(double dt) {
    // Head follows player
    final dir = seekPlayer(speed);
    position += dir * dt;

    // Update segment positions (follow the leader)
    if (_segments.isNotEmpty) {
      _segments[0] = position.clone();
      for (int i = 1; i < _segments.length; i++) {
        final target = _segments[i - 1];
        final current = _segments[i];
        final toTarget = target - current;
        if (toTarget.length > 14) {
          _segments[i] = current + toTarget.normalized() * (toTarget.length - 14);
        }
      }
    }
  }

  @override
  void takeDamage(double amount) {
    hp -= amount;
    if (hp <= 0) {
      onDeath();
    } else if (_segments.length > 2 && hp <= _segments.length / 2) {
      // Split into two snakes
      _split();
    }
  }

  void _split() {
    if (_segments.length < 4) return;

    final midPoint = _segments.length ~/ 2;

    // Create a new snake from the tail half
    final tailSnake = SnakeEnemy(
        segmentCount: _segments.length - midPoint, isFragment: true);
    tailSnake.position = _segments[midPoint].clone();
    tailSnake.hp = (_segments.length - midPoint).toDouble();
    game.world.add(tailSnake);

    // Trim current snake
    while (_segments.length > midPoint) {
      _segments.removeLast();
    }
    hp = _segments.length.toDouble();
  }

  @override
  void renderShape(Canvas canvas, Paint paint, double scale) {
    final cx = size.x / 2;
    final cy = size.y / 2;

    if (_segments.isEmpty) {
      canvas.drawCircle(Offset(cx, cy), 6 * scale, paint);
      return;
    }

    // === CONNESSIONI LUMINOSE TRA SEGMENTI ===
    if (scale <= 1.01 && _segments.length > 1) {
      for (int i = 0; i < _segments.length - 1; i++) {
        final seg1 = _segments[i] - position;
        final seg2 = _segments[i + 1] - position;
        final lineAlpha = (1.0 - i / _segments.length) * 0.3;
        final linePaint = Paint()
          ..color = paint.color.withValues(alpha: lineAlpha)
          ..strokeWidth = (2.5 - i * 0.2).clamp(0.5, 2.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
        canvas.drawLine(
          Offset(cx + seg1.x, cy + seg1.y),
          Offset(cx + seg2.x, cy + seg2.y),
          linePaint,
        );
      }
    }

    // === SEGMENTI con gradiente colore ===
    for (int i = _segments.length - 1; i >= 0; i--) {
      final seg = _segments[i] - position;
      final progress = i / _segments.length; // 0=testa, 1=coda
      final radius = (6 - i * 0.3).clamp(3.0, 6.0) * scale;
      final segAlpha = (1.0 - progress * 0.5);

      // Segmento con colore che sfuma verso il turchese
      final segColor = Color.lerp(
        paint.color,
        paint.color.withValues(alpha: 0.4),
        progress,
      ) ?? paint.color;
      final segPaint = Paint()..color = segColor.withValues(alpha: segAlpha);
      canvas.drawCircle(Offset(cx + seg.x, cy + seg.y), radius, segPaint);

      // Nucleo pulsante per ogni segmento (solo layer principale)
      if (scale <= 1.01 && i % 2 == 0) {
        final pulse = 0.3 + math.sin(idlePhase * 4 + i * 0.5) * 0.2;
        final corePaint = Paint()
          ..color = const Color(0xFFFFFFFF).withValues(alpha: pulse)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
        canvas.drawCircle(Offset(cx + seg.x, cy + seg.y), radius * 0.35, corePaint);
      }
    }

    // === TESTA: più grande con occhi ===
    if (scale <= 1.01 && _segments.isNotEmpty) {
      final head = _segments[0] - position;
      final headR = 6.0 * scale;
      // Occhi (nella direzione di movimento)
      final moveDir = _segments.length > 1
          ? (_segments[0] - _segments[1]).normalized()
          : Vector2(0, -1);
      final eyeOffset = 2.5;
      final perpDir = Vector2(-moveDir.y, moveDir.x);

      final eyeL = Offset(
        cx + head.x + perpDir.x * eyeOffset + moveDir.x * 2,
        cy + head.y + perpDir.y * eyeOffset + moveDir.y * 2,
      );
      final eyeR = Offset(
        cx + head.x - perpDir.x * eyeOffset + moveDir.x * 2,
        cy + head.y - perpDir.y * eyeOffset + moveDir.y * 2,
      );
      final eyePaint = Paint()
        ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.8);
      canvas.drawCircle(eyeL, 1.2, eyePaint);
      canvas.drawCircle(eyeR, 1.2, eyePaint);
    }
  }
}

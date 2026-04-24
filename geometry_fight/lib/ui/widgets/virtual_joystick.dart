import 'package:flutter/material.dart';
import 'animated_builder_widget.dart';

/// Joystick virtuale visibile con estetica neon.
/// Mostra un cerchio base semi-trasparente e un thumb che segue il dito.
class VirtualJoystick extends StatefulWidget {
  /// Callback chiamato quando il joystick si muove.
  /// Riceve un Offset normalizzato (-1 a 1) per x e y.
  final void Function(Offset direction) onMove;

  /// Callback quando il joystick viene rilasciato
  final VoidCallback? onRelease;

  /// Callback quando il joystick viene toccato
  final VoidCallback? onStart;

  /// Colore neon del joystick
  final Color color;

  /// Etichetta mostrata sotto il joystick (es: "MOVE", "AIM")
  final String? label;

  /// Raggio massimo del joystick
  final double radius;

  const VirtualJoystick({
    super.key,
    required this.onMove,
    this.onRelease,
    this.onStart,
    this.color = const Color(0xFF00FFFF),
    this.label,
    this.radius = 55,
  });

  @override
  State<VirtualJoystick> createState() => _VirtualJoystickState();
}

class _VirtualJoystickState extends State<VirtualJoystick>
    with SingleTickerProviderStateMixin {
  Offset? _center; // Centro del joystick (dove il dito ha toccato)
  Offset _thumbOffset = Offset.zero; // Offset del thumb dal centro
  bool _isActive = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    // Animazione di pulsazione quando il joystick è attivo
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanStart: (details) {
        setState(() {
          _center = details.localPosition;
          _isActive = true;
        });
        widget.onStart?.call();
      },
      onPanUpdate: (details) {
        if (_center != null) {
          final delta = details.localPosition - _center!;
          final dist = delta.distance;
          final maxDist = widget.radius;

          // Clamp al raggio massimo
          final clamped = dist > maxDist
              ? Offset(
                  delta.dx / dist * maxDist,
                  delta.dy / dist * maxDist,
                )
              : delta;

          setState(() {
            _thumbOffset = clamped;
          });

          // Normalizza e invia il callback
          final normalized = Offset(
            clamped.dx / maxDist,
            clamped.dy / maxDist,
          );
          widget.onMove(normalized);
        }
      },
      onPanEnd: (_) {
        setState(() {
          _isActive = false;
          _thumbOffset = Offset.zero;
          _center = null;
        });
        widget.onRelease?.call();
      },
      child: Stack(
        children: [
          // Area trasparente per catturare i tocchi
          Container(color: Colors.transparent),

          // Joystick visuale (appare dove il dito tocca)
          if (_isActive && _center != null)
            Positioned(
              left: _center!.dx - widget.radius,
              top: _center!.dy - widget.radius,
              child: NeonAnimatedBuilder(
                animation: _pulseController,
                builder: (context, _) {
                  return CustomPaint(
                    size: Size(widget.radius * 2, widget.radius * 2),
                    painter: _JoystickPainter(
                      color: widget.color,
                      thumbOffset: _thumbOffset,
                      radius: widget.radius,
                      pulseValue: _pulseController.value,
                    ),
                  );
                },
              ),
            ),

          // Label fisso in basso
          if (widget.label != null)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  widget.label!,
                  style: TextStyle(
                    color: widget.color.withValues(alpha: _isActive ? 0.6 : 0.2),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    letterSpacing: 3,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Painter custom per disegnare il joystick con effetti neon
class _JoystickPainter extends CustomPainter {
  final Color color;
  final Offset thumbOffset;
  final double radius;
  final double pulseValue;

  // Cached static Paints — riusati tra frame per evitare allocazioni
  static final _baseGlowPaint = Paint();
  static final _baseBorderPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;
  static final _linePaint = Paint()
    ..strokeWidth = 1.5
    ..style = PaintingStyle.stroke;
  static final _midPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.5;
  static final _thumbGlowPaint = Paint();
  static final _thumbBorderPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  static final _thumbCenterPaint = Paint();
  static final _dotPaint = Paint();
  static final _crossPaint = Paint()..strokeWidth = 0.5;

  _JoystickPainter({
    required this.color,
    required this.thumbOffset,
    required this.radius,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final thumbCenter = center + thumbOffset;

    // === Cerchio base esterno (glow) — senza blur ===
    _baseGlowPaint.color = color.withValues(alpha: 0.08 + pulseValue * 0.04);
    canvas.drawCircle(center, radius * 1.1, _baseGlowPaint);

    // === Cerchio base (bordo) ===
    _baseBorderPaint.color = color.withValues(alpha: 0.15 + pulseValue * 0.05);
    canvas.drawCircle(center, radius, _baseBorderPaint);

    // === Linea direzionale dal centro al thumb ===
    if (thumbOffset.distance > 5) {
      _linePaint.color = color.withValues(alpha: 0.2);
      canvas.drawLine(center, thumbCenter, _linePaint);

      // Cerchi concentrici intermedi per profondità
      _midPaint.color = color.withValues(alpha: 0.06);
      canvas.drawCircle(center, radius * 0.5, _midPaint);
      canvas.drawCircle(center, radius * 0.75, _midPaint);
    }

    // === Thumb (pallino mobile) - glow esterno — senza blur ===
    _thumbGlowPaint.color = color.withValues(alpha: 0.15);
    canvas.drawCircle(thumbCenter, 22, _thumbGlowPaint);

    // === Thumb - bordo ===
    _thumbBorderPaint.color = color.withValues(alpha: 0.6);
    canvas.drawCircle(thumbCenter, 14, _thumbBorderPaint);

    // === Thumb - centro luminoso ===
    _thumbCenterPaint.color = color.withValues(alpha: 0.4 + pulseValue * 0.2);
    canvas.drawCircle(thumbCenter, 8, _thumbCenterPaint);

    // === Thumb - punto bianco centrale ===
    _dotPaint.color = Colors.white.withValues(alpha: 0.7);
    canvas.drawCircle(thumbCenter, 3, _dotPaint);

    // === Croce al centro del joystick (indicatore) ===
    _crossPaint.color = color.withValues(alpha: 0.1);
    canvas.drawLine(
      Offset(center.dx - 8, center.dy),
      Offset(center.dx + 8, center.dy),
      _crossPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - 8),
      Offset(center.dx, center.dy + 8),
      _crossPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _JoystickPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.thumbOffset != thumbOffset ||
      oldDelegate.radius != radius ||
      oldDelegate.pulseValue != pulseValue;
}

// NeonAnimatedBuilder è importato da animated_builder_widget.dart

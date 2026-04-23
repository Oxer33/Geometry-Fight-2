import 'package:flutter/material.dart';

class ScanlinePainter extends CustomPainter {
  // Paint cache: evita alloc per paint (3 screen × repaint potenziali).
  static final Paint _paint = Paint()
    ..color = Colors.white.withValues(alpha: 0.15);

  @override
  void paint(Canvas canvas, Size size) {
    for (double y = 0; y < size.height; y += 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), _paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

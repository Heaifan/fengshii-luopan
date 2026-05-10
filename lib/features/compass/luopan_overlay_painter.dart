import 'package:flutter/material.dart';

/// Fixed overlay: crosshair, needle, pivot, top triangle marker.
/// Never rotates — drawn on top of the rotating disc.
class LuopanFixedOverlayPainter extends CustomPainter {
  final double scale;
  static const double baseSize = 1000.0;

  LuopanFixedOverlayPainter({required this.scale});

  @override
  void paint(Canvas canvas, Size size) {
    final s = scale;
    final cx = size.width / 2;
    final cy = size.height / 2;

    canvas.save();
    canvas.translate(cx, cy);

    _drawCrosshair(canvas, s);
    _drawTriangle(canvas, s);

    canvas.restore();
  }

  void _drawCrosshair(Canvas canvas, double s) {
    final paint = Paint()
      ..color = const Color(0x99D00000)
      ..strokeWidth = 1.2 * s;

    canvas.drawLine(Offset(0, -510 * s), Offset(0, 510 * s), paint);
    canvas.drawLine(Offset(-510 * s, 0), Offset(510 * s, 0), paint);
  }

  void _drawTriangle(Canvas canvas, double s) {
    // Fixed triangle at the very top of the dial, pointing down toward center
    final paint = Paint()
      ..color = const Color(0xFFb8860b)
      ..style = PaintingStyle.fill;

    const triH = 18.0;
    const triW = 16.0;
    final topY = -510 * s;
    final path = Path()
      ..moveTo(0, topY) // tip at top
      ..lineTo(-triW * s, topY - triH * s) // bottom-left
      ..lineTo(triW * s, topY - triH * s) // bottom-right
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant LuopanFixedOverlayPainter oldDelegate) {
    return oldDelegate.scale != scale;
  }
}

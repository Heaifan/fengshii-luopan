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
    _drawNeedle(canvas, s);
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

  void _drawNeedle(Canvas canvas, double s) {
    // Needle within the inner pool (radius 110), pointing to 午 (top).
    // South-pointing half is longer, north-pointing half is shorter.
    final needlePaint = Paint()
      ..color = const Color(0xFF1a1a1a)
      ..strokeWidth = 2.5 * s
      ..strokeCap = StrokeCap.round;

    // Pointing to 午: top half longer (south), bottom half shorter (north)
    canvas.drawLine(Offset(0, 20 * s), Offset(0, -100 * s), needlePaint);
    canvas.drawLine(Offset(0, -20 * s), Offset(0, 50 * s), needlePaint);

    // Double red dots (south end)
    final dotPaint = Paint()..color = const Color(0xFFd00000);
    canvas.drawCircle(Offset(-6 * s, -92 * s), 3.5 * s, dotPaint);
    canvas.drawCircle(Offset(6 * s, -92 * s), 3.5 * s, dotPaint);

    // Center pivot
    canvas.drawCircle(
        Offset.zero, 7 * s, Paint()..color = const Color(0xFF444444));
    canvas.drawCircle(
        Offset.zero, 5 * s, Paint()..color = const Color(0xFF222222));
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

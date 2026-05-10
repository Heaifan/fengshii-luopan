import 'package:flutter/material.dart';

/// Rotating needle that follows the disc to always point at 午 mountain.
class LuopanNeedlePainter extends CustomPainter {
  final double scale;
  static const double baseSize = 1000.0;

  LuopanNeedlePainter({required this.scale});

  @override
  void paint(Canvas canvas, Size size) {
    final s = scale;
    final cx = size.width / 2;
    final cy = size.height / 2;

    canvas.save();
    canvas.translate(cx, cy);

    final needlePaint = Paint()
      ..color = const Color(0xFF1a1a1a)
      ..strokeWidth = 2.5 * s
      ..strokeCap = StrokeCap.round;

    // Pointing to 午 (top of disc): south end longer, north end shorter
    canvas.drawLine(Offset(0, 20 * s), Offset(0, -100 * s), needlePaint);
    canvas.drawLine(Offset(0, -20 * s), Offset(0, 50 * s), needlePaint);

    // Double red dots near south end
    final dotPaint = Paint()..color = const Color(0xFFd00000);
    canvas.drawCircle(Offset(-6 * s, -92 * s), 3.5 * s, dotPaint);
    canvas.drawCircle(Offset(6 * s, -92 * s), 3.5 * s, dotPaint);

    // Center pivot
    canvas.drawCircle(
        Offset.zero, 7 * s, Paint()..color = const Color(0xFF444444));
    canvas.drawCircle(
        Offset.zero, 5 * s, Paint()..color = const Color(0xFF222222));

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant LuopanNeedlePainter oldDelegate) {
    return oldDelegate.scale != scale;
  }
}

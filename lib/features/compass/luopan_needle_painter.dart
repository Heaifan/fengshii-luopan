import 'package:flutter/material.dart';

class LuopanNeedlePainter extends CustomPainter {
  final double scale;

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

    // Head points to 午 (top of disc), tail at bottom, one continuous line
    final head = Offset(0, -100 * s);
    final tail = Offset(0, 55 * s);
    canvas.drawLine(tail, head, needlePaint);

    // Center pivot
    canvas.drawCircle(
        Offset.zero, 7 * s, Paint()..color = const Color(0xFF444444));
    canvas.drawCircle(
        Offset.zero, 5 * s, Paint()..color = const Color(0xFF222222));

    // Double red dots at tail (bottom end)
    final dotPaint = Paint()..color = const Color(0xFFd00000);
    canvas.drawCircle(Offset(-6 * s, 48 * s), 3.5 * s, dotPaint);
    canvas.drawCircle(Offset(6 * s, 48 * s), 3.5 * s, dotPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant LuopanNeedlePainter oldDelegate) {
    return oldDelegate.scale != scale;
  }
}

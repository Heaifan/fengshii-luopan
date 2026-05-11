import 'dart:math' as math;
import 'package:flutter/material.dart';

class LTypeLevelIndicator extends StatelessWidget {
  final double horizontalAngle;
  final double verticalAngle;
  final bool hasData;

  const LTypeLevelIndicator({
    super.key,
    required this.horizontalAngle,
    required this.verticalAngle,
    this.hasData = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 135,
      height: 135,
      child: CustomPaint(
        size: const Size(135, 135),
        painter: _LTypeLevelPainter(
          horizontalAngle: horizontalAngle,
          verticalAngle: verticalAngle,
          hasData: hasData,
        ),
      ),
    );
  }
}

class _LTypeLevelPainter extends CustomPainter {
  final double horizontalAngle;
  final double verticalAngle;
  final bool hasData;

  _LTypeLevelPainter({
    required this.horizontalAngle,
    required this.verticalAngle,
    required this.hasData,
  });

  // L-shape geometry
  static const double armThick = 36;
  static const double vertH = 108;
  static const double horizW = 108;
  static const double total = 135;
  static const double endCap = 7;

  // Bubble movement range
  static const double maxAngle = 8;
  static const double maxBubbleOffset = 12;

  @override
  void paint(Canvas canvas, Size size) {
    _drawCorner(canvas);
    _drawVerticalArm(canvas);
    _drawHorizontalArm(canvas);
    _drawVerticalVial(canvas);
    _drawHorizontalVial(canvas);
  }

  void _drawCorner(Canvas canvas) {
    final rect = Rect.fromLTWH(0, vertH - armThick, armThick, armThick);
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF5d7068), Color(0xFF45524d), Color(0xFF35423d)],
      ).createShader(rect);
    canvas.drawRect(rect, paint);

    // Corner border
    final borderPaint = Paint()
      ..color = const Color(0x6B373E3E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRect(rect, borderPaint);
  }

  void _drawVerticalArm(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, armThick, vertH - armThick);
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: const [
          Color(0xFF4f5f59),
          Color(0xFF7f9188),
          Color(0xFF5d6e67),
        ],
      ).createShader(rect);
    final rrect = RRect.fromRectAndCorners(
      rect,
      topLeft: const Radius.circular(4),
      topRight: const Radius.circular(4),
    );
    canvas.drawRRect(rrect, paint);

    // Border
    final borderPaint = Paint()
      ..color = const Color(0x6B373E3E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(rrect, borderPaint);

    // Highlight line
    final hlPaint = Paint()
      ..color = const Color(0x47FFFFFF)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(2, 4),
      Offset(2, vertH - armThick - 4),
      hlPaint,
    );

    // Top end cap
    final capRect = Rect.fromLTWH(0, 0, armThick, endCap);
    final capPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: const [Color(0xFF1a1f1d), Color(0xFF3a4540), Color(0xFF1a1f1d)],
      ).createShader(capRect);
    canvas.drawRect(capRect, capPaint);
  }

  void _drawHorizontalArm(Canvas canvas) {
    final armTop = vertH - armThick;
    final rect = Rect.fromLTWH(armThick, armTop, horizW - armThick, armThick);
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [
          Color(0xFF4f5f59),
          Color(0xFF7f9188),
          Color(0xFF5d6e67),
        ],
      ).createShader(rect);
    final rrect = RRect.fromRectAndCorners(
      rect,
      bottomLeft: const Radius.circular(4),
      bottomRight: const Radius.circular(4),
    );
    canvas.drawRRect(rrect, paint);

    // Border
    final borderPaint = Paint()
      ..color = const Color(0x6B373E3E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(rrect, borderPaint);

    // Highlight line
    final hlPaint = Paint()
      ..color = const Color(0x47FFFFFF)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(armThick + 4, armTop + 2),
      Offset(horizW - 4, armTop + 2),
      hlPaint,
    );

    // Right end cap
    final capRect = Rect.fromLTWH(horizW - endCap, armTop, endCap, armThick);
    final capPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [Color(0xFF1a1f1d), Color(0xFF3a4540), Color(0xFF1a1f1d)],
      ).createShader(capRect);
    canvas.drawRect(capRect, capPaint);
  }

  void _drawVerticalVial(Canvas canvas) {
    const cx = armThick / 2;
    const vialW = 10.0;
    const vialH = 54.0;
    const vialTop = endCap + 10;
    final vialRect = Rect.fromLTWH(
      cx - vialW / 2,
      vialTop,
      vialW,
      vialH,
    );
    final rrect =
        RRect.fromRectAndRadius(vialRect, const Radius.circular(5));

    // Recessed slot
    final slotRect = Rect.fromLTWH(
      cx - vialW / 2 - 2,
      vialTop - 2,
      vialW + 4,
      vialH + 4,
    );
    final slotRRect =
        RRect.fromRectAndRadius(slotRect, const Radius.circular(6));
    final slotPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: const [
          Color(0xFF35423d),
          Color(0xFF5d7068),
          Color(0xFF7f9188),
        ],
      ).createShader(slotRect);
    canvas.drawRRect(slotRRect, slotPaint);
    final slotBorder = Paint()
      ..color = const Color(0x8A2A332F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(slotRRect, slotBorder);

    // Glass tube
    final glassPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [
          Color(0xB8F5FAF4),
          Color(0x6BC6DACD),
          Color(0x47789184),
        ],
      ).createShader(vialRect);
    canvas.drawRRect(rrect, glassPaint);
    final glassBorder = Paint()
      ..color = const Color(0x80373E3E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawRRect(rrect, glassBorder);

    // Scale marks
    final markPaint = Paint()
      ..color = const Color(0x9E44524C)
      ..strokeWidth = 1.2;
    final markY1 = vialTop + vialH * 0.25;
    final markY2 = vialTop + vialH * 0.75;
    canvas.drawLine(
      Offset(cx - vialW / 2 + 2, markY1),
      Offset(cx + vialW / 2 - 2, markY1),
      markPaint,
    );
    canvas.drawLine(
      Offset(cx - vialW / 2 + 2, markY2),
      Offset(cx + vialW / 2 - 2, markY2),
      markPaint,
    );

    // Bubble
    if (hasData) {
      final clamped = verticalAngle.clamp(-maxAngle, maxAngle);
      final ratio = clamped / maxAngle;
      final centerY = vialTop + vialH / 2;
      final bubbleY = centerY + ratio * maxBubbleOffset;
      const bubbleR = 4.2;
      const bubbleH = 7.0;

      final bubbleRect = Rect.fromCenter(
        center: Offset(cx, bubbleY),
        width: bubbleR * 2,
        height: bubbleH,
      );
      final bubbleRRect =
          RRect.fromRectAndRadius(bubbleRect, const Radius.circular(bubbleR));

      final bubblePaint = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.3),
          colors: const [
            Color(0xFFfbfff8),
            Color(0xFFa8e8a0),
            Color(0xFF5cb85c),
          ],
        ).createShader(bubbleRect);
      canvas.drawRRect(bubbleRRect, bubblePaint);

      final bubbleGlow = Paint()
        ..color = const Color(0x3300ff00)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawRRect(bubbleRRect, bubbleGlow);
    }
  }

  void _drawHorizontalVial(Canvas canvas) {
    final armTop = vertH - armThick;
    const cy = armThick / 2;
    const vialH = 10.0;
    const vialW = 54.0;
    final vialLeft = armThick + 10;
    final vialRect = Rect.fromLTWH(
      vialLeft,
      armTop + cy - vialH / 2,
      vialW,
      vialH,
    );
    final rrect =
        RRect.fromRectAndRadius(vialRect, const Radius.circular(5));

    // Recessed slot
    final slotRect = Rect.fromLTWH(
      vialLeft - 2,
      armTop + cy - vialH / 2 - 2,
      vialW + 4,
      vialH + 4,
    );
    final slotRRect =
        RRect.fromRectAndRadius(slotRect, const Radius.circular(6));
    final slotPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: const [
          Color(0xFF35423d),
          Color(0xFF5d7068),
          Color(0xFF7f9188),
        ],
      ).createShader(slotRect);
    canvas.drawRRect(slotRRect, slotPaint);
    final slotBorder = Paint()
      ..color = const Color(0x8A2A332F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(slotRRect, slotBorder);

    // Glass tube
    final glassPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: const [
          Color(0xB8F5FAF4),
          Color(0x6BC6DACD),
          Color(0x47789184),
        ],
      ).createShader(vialRect);
    canvas.drawRRect(rrect, glassPaint);
    final glassBorder = Paint()
      ..color = const Color(0x80373E3E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawRRect(rrect, glassBorder);

    // Scale marks
    final markPaint = Paint()
      ..color = const Color(0x9E44524C)
      ..strokeWidth = 1.2;
    final cx = vialLeft + vialW / 2;
    final markX1 = vialLeft + vialW * 0.25;
    final markX2 = vialLeft + vialW * 0.75;
    canvas.drawLine(
      Offset(markX1, armTop + cy - vialH / 2 + 2),
      Offset(markX1, armTop + cy + vialH / 2 - 2),
      markPaint,
    );
    canvas.drawLine(
      Offset(markX2, armTop + cy - vialH / 2 + 2),
      Offset(markX2, armTop + cy + vialH / 2 - 2),
      markPaint,
    );

    // Bubble
    if (hasData) {
      final clamped = horizontalAngle.clamp(-maxAngle, maxAngle);
      final ratio = clamped / maxAngle;
      final bubbleX = cx + ratio * maxBubbleOffset;
      const bubbleR = 4.2;
      const bubbleW = 7.0;

      final bubbleRect = Rect.fromCenter(
        center: Offset(bubbleX, armTop + cy),
        width: bubbleW,
        height: bubbleR * 2,
      );
      final bubbleRRect =
          RRect.fromRectAndRadius(bubbleRect, const Radius.circular(bubbleR));

      final bubblePaint = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.3),
          colors: const [
            Color(0xFFfbfff8),
            Color(0xFFa8e8a0),
            Color(0xFF5cb85c),
          ],
        ).createShader(bubbleRect);
      canvas.drawRRect(bubbleRRect, bubblePaint);

      final bubbleGlow = Paint()
        ..color = const Color(0x3300ff00)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawRRect(bubbleRRect, bubbleGlow);
    }
  }

  @override
  bool shouldRepaint(covariant _LTypeLevelPainter oldDelegate) {
    return oldDelegate.horizontalAngle != horizontalAngle ||
        oldDelegate.verticalAngle != verticalAngle ||
        oldDelegate.hasData != hasData;
  }
}

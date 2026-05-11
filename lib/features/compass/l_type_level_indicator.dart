import 'package:flutter/material.dart';

class LTypeLevelIndicator extends StatelessWidget {
  final double horizontalAngle;
  final double verticalAngle;
  final bool hasData;
  final double size;

  const LTypeLevelIndicator({
    super.key,
    required this.horizontalAngle,
    required this.verticalAngle,
    this.hasData = true,
    this.size = 78,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.94,
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          size: Size(size, size),
          painter: _LTypeLevelPainter(
            horizontalAngle: horizontalAngle,
            verticalAngle: verticalAngle,
            hasData: hasData,
            sz: size,
          ),
        ),
      ),
    );
  }
}

class _LTypeLevelPainter extends CustomPainter {
  final double horizontalAngle;
  final double verticalAngle;
  final bool hasData;
  final double sz;

  _LTypeLevelPainter({
    required this.horizontalAngle,
    required this.verticalAngle,
    required this.hasData,
    required this.sz,
  });

  late final double arm = sz * 0.30;
  late final double span = sz * 0.70;
  late final double endCap = sz * 0.05;
  late final double cornerR = sz * 0.03;

  static const double maxAngle = 8;

  @override
  void paint(Canvas canvas, Size size) {
    _drawCorner(canvas);
    _drawVerticalArm(canvas);
    _drawHorizontalArm(canvas);
    _drawVerticalVial(canvas);
    _drawHorizontalVial(canvas);
  }

  void _drawCorner(Canvas canvas) {
    final rect = Rect.fromLTWH(0, span, arm, arm);
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: const [
          Color(0xFF5d7068),
          Color(0xFF45524d),
          Color(0xFF35423d),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, paint);

    final borderPaint = Paint()
      ..color = const Color(0x6B373E3E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;
    canvas.drawRect(rect, borderPaint);
  }

  void _drawVerticalArm(Canvas canvas) {
    final armLen = span;
    final rect = Rect.fromLTWH(0, 0, arm, armLen);
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
    final r = cornerR;
    final rrect = RRect.fromRectAndCorners(
      rect,
      topLeft: Radius.circular(r),
      topRight: Radius.circular(r),
    );
    canvas.drawRRect(rrect, paint);

    final borderPaint = Paint()
      ..color = const Color(0x6B373E3E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;
    canvas.drawRRect(rrect, borderPaint);

    // Highlight
    final hlPaint = Paint()
      ..color = const Color(0x47FFFFFF)
      ..strokeWidth = 0.6;
    canvas.drawLine(
      Offset(arm * 0.06, r),
      Offset(arm * 0.06, armLen - r),
      hlPaint,
    );

    // Top end cap
    final capRect = Rect.fromLTWH(0, 0, arm, endCap);
    final capPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: const [
          Color(0xFF1a1f1d),
          Color(0xFF3a4540),
          Color(0xFF1a1f1d),
        ],
      ).createShader(capRect);
    canvas.drawRect(capRect, capPaint);
  }

  void _drawHorizontalArm(Canvas canvas) {
    final armTop = span;
    final armLen = span;
    final rect = Rect.fromLTWH(arm, armTop, armLen, arm);
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
    final r = cornerR;
    final rrect = RRect.fromRectAndCorners(
      rect,
      bottomLeft: Radius.circular(r),
      bottomRight: Radius.circular(r),
    );
    canvas.drawRRect(rrect, paint);

    final borderPaint = Paint()
      ..color = const Color(0x6B373E3E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;
    canvas.drawRRect(rrect, borderPaint);

    // Highlight
    final hlPaint = Paint()
      ..color = const Color(0x47FFFFFF)
      ..strokeWidth = 0.6;
    canvas.drawLine(
      Offset(arm + armLen * 0.05, armTop + arm * 0.06),
      Offset(arm + armLen - armLen * 0.05, armTop + arm * 0.06),
      hlPaint,
    );

    // Right end cap
    final capRect =
        Rect.fromLTWH(arm + armLen - endCap, armTop, endCap, arm);
    final capPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [
          Color(0xFF1a1f1d),
          Color(0xFF3a4540),
          Color(0xFF1a1f1d),
        ],
      ).createShader(capRect);
    canvas.drawRect(capRect, capPaint);
  }

  void _drawVerticalVial(Canvas canvas) {
    final cx = arm / 2;
    final vialW = arm * 0.36;
    final vialH = span * 0.70;
    final vialTop = endCap + span * 0.10;
    final vialRect = Rect.fromLTWH(cx - vialW / 2, vialTop, vialW, vialH);
    final rrect =
        RRect.fromRectAndRadius(vialRect, Radius.circular(vialW / 2));

    // Recessed slot
    final gap = sz * 0.015;
    final slotRect = Rect.fromLTWH(
      cx - vialW / 2 - gap,
      vialTop - gap,
      vialW + gap * 2,
      vialH + gap * 2,
    );
    final slotRRect = RRect.fromRectAndRadius(
        slotRect, Radius.circular(vialW / 2 + gap));
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
      ..strokeWidth = 0.6;
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
      ..strokeWidth = 0.5;
    canvas.drawRRect(rrect, glassBorder);

    // Scale marks
    final markPaint = Paint()
      ..color = const Color(0x9E44524C)
      ..strokeWidth = 0.8;
    final markY1 = vialTop + vialH * 0.25;
    final markY2 = vialTop + vialH * 0.75;
    final markMargin = vialW * 0.2;
    canvas.drawLine(
      Offset(cx - vialW / 2 + markMargin, markY1),
      Offset(cx + vialW / 2 - markMargin, markY1),
      markPaint,
    );
    canvas.drawLine(
      Offset(cx - vialW / 2 + markMargin, markY2),
      Offset(cx + vialW / 2 - markMargin, markY2),
      markPaint,
    );

    // Bubble
    if (hasData) {
      final maxOffset = vialH * 0.22;
      final clamped = verticalAngle.clamp(-maxAngle, maxAngle);
      final ratio = clamped / maxAngle;
      final centerY = vialTop + vialH / 2;
      final bubbleY = centerY + ratio * maxOffset;
      final bubbleR = vialW * 0.42;
      final bubbleH = vialW * 0.68;

      final bubbleRect = Rect.fromCenter(
        center: Offset(cx, bubbleY),
        width: bubbleR * 2,
        height: bubbleH,
      );
      final bubbleRRect =
          RRect.fromRectAndRadius(bubbleRect, Radius.circular(bubbleR));

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
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, sz * 0.022);
      canvas.drawRRect(bubbleRRect, bubbleGlow);
    }
  }

  void _drawHorizontalVial(Canvas canvas) {
    final armTop = span;
    final cy = arm / 2;
    final vialH = arm * 0.36;
    final vialW = span * 0.70;
    final vialLeft = arm + span * 0.10;
    final vialRect =
        Rect.fromLTWH(vialLeft, armTop + cy - vialH / 2, vialW, vialH);
    final rrect =
        RRect.fromRectAndRadius(vialRect, Radius.circular(vialH / 2));

    // Recessed slot
    final gap = sz * 0.015;
    final slotRect = Rect.fromLTWH(
      vialLeft - gap,
      armTop + cy - vialH / 2 - gap,
      vialW + gap * 2,
      vialH + gap * 2,
    );
    final slotRRect = RRect.fromRectAndRadius(
        slotRect, Radius.circular(vialH / 2 + gap));
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
      ..strokeWidth = 0.6;
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
      ..strokeWidth = 0.5;
    canvas.drawRRect(rrect, glassBorder);

    // Scale marks
    final markPaint = Paint()
      ..color = const Color(0x9E44524C)
      ..strokeWidth = 0.8;
    final cx = vialLeft + vialW / 2;
    final markX1 = vialLeft + vialW * 0.25;
    final markX2 = vialLeft + vialW * 0.75;
    final markMargin = vialH * 0.2;
    canvas.drawLine(
      Offset(markX1, armTop + cy - vialH / 2 + markMargin),
      Offset(markX1, armTop + cy + vialH / 2 - markMargin),
      markPaint,
    );
    canvas.drawLine(
      Offset(markX2, armTop + cy - vialH / 2 + markMargin),
      Offset(markX2, armTop + cy + vialH / 2 - markMargin),
      markPaint,
    );

    // Bubble
    if (hasData) {
      final maxOffset = vialW * 0.22;
      final clamped = horizontalAngle.clamp(-maxAngle, maxAngle);
      final ratio = clamped / maxAngle;
      final bubbleX = cx + ratio * maxOffset;
      final bubbleR = vialH * 0.42;
      final bubbleW = vialH * 0.68;

      final bubbleRect = Rect.fromCenter(
        center: Offset(bubbleX, armTop + cy),
        width: bubbleW,
        height: bubbleR * 2,
      );
      final bubbleRRect =
          RRect.fromRectAndRadius(bubbleRect, Radius.circular(bubbleR));

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
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, sz * 0.022);
      canvas.drawRRect(bubbleRRect, bubbleGlow);
    }
  }

  @override
  bool shouldRepaint(covariant _LTypeLevelPainter oldDelegate) {
    return oldDelegate.horizontalAngle != horizontalAngle ||
        oldDelegate.verticalAngle != verticalAngle ||
        oldDelegate.hasData != hasData ||
        oldDelegate.sz != sz;
  }
}

import 'package:flutter/material.dart';

enum TiltStatus { good, warning, bad }

TiltStatus tiltStatus(double angle) {
  final a = angle.abs();
  if (a <= 2) return TiltStatus.good;
  if (a <= 5) return TiltStatus.warning;
  return TiltStatus.bad;
}

Color tiltColor(TiltStatus status) {
  switch (status) {
    case TiltStatus.good:
      return const Color(0xFF4CAF50);
    case TiltStatus.warning:
      return const Color(0xFFFFC107);
    case TiltStatus.bad:
      return const Color(0xFFEF5350);
  }
}

String tiltLabel(TiltStatus status) {
  switch (status) {
    case TiltStatus.good:
      return '良好';
    case TiltStatus.warning:
      return '微调';
    case TiltStatus.bad:
      return '倾斜';
  }
}

class BubbleIndicator extends StatelessWidget {
  final String label;
  final double angle; // degrees
  final double maxAngle; // scale range

  const BubbleIndicator({
    super.key,
    required this.label,
    required this.angle,
    this.maxAngle = 10.0,
  });

  @override
  Widget build(BuildContext context) {
    final status = tiltStatus(angle);
    final color = tiltColor(status);
    final statusLabel = tiltLabel(status);

    return SizedBox(
      height: 22,
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(label,
                style: const TextStyle(fontSize: 12, color: Color(0xFF7A6040))),
          ),
          Expanded(
            child: CustomPaint(
              size: const Size(double.infinity, 22),
              painter: _BubblePainter(
                  angle: angle, maxAngle: maxAngle, color: color),
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 48,
            child: Text(
              '${angle.abs().toStringAsFixed(1)}°',
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 11, color: color),
            ),
          ),
          const SizedBox(width: 4),
          Container(
            width: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(statusLabel,
                style: TextStyle(fontSize: 10, color: color)),
          ),
        ],
      ),
    );
  }
}

class _BubblePainter extends CustomPainter {
  final double angle;
  final double maxAngle;
  final Color color;

  _BubblePainter(
      {required this.angle, required this.maxAngle, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final w = size.width;
    final cy = h / 2;

    // Track
    final trackPaint = Paint()
      ..color = const Color(0xFFC8B898)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(8, cy), Offset(w - 8, cy), trackPaint);

    // Center mark
    final centerPaint = Paint()
      ..color = const Color(0xFFB99A61)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(w / 2, cy - 6), Offset(w / 2, cy + 6), centerPaint);

    // Bubble position: clamped, linear scale
    final clamped =
        angle.clamp(-maxAngle.toDouble(), maxAngle.toDouble());
    final ratio = clamped / maxAngle; // -1..1
    final bx = w / 2 + ratio * (w / 2 - 12);

    // Green safe zone
    final safeW = (2.0 / maxAngle) * (w / 2 - 12);
    final safePaint = Paint()..color = const Color(0x334CAF50);
    canvas.drawRect(
        Rect.fromCenter(
            center: Offset(w / 2, cy), width: safeW * 2, height: h - 2),
        safePaint);

    // Bubble dot
    canvas.drawCircle(
        Offset(bx, cy), 5, Paint()..color = color.withAlpha(200));
    canvas.drawCircle(Offset(bx, cy), 5,
        Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 1.5);
  }

  @override
  bool shouldRepaint(covariant _BubblePainter oldDelegate) {
    return oldDelegate.angle != angle || oldDelegate.color != color;
  }
}

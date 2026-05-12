import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../../../data/models/compass_record.dart';
import '../painters/tiandiren_vent_painter.dart';

class TiandirenVentWidget extends StatelessWidget {
  final List<CompassRecord> records;

  const TiandirenVentWidget({
    super.key,
    required this.records,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(constraints.maxWidth, 320.0);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: size,
              height: size,
              child: CustomPaint(
                painter: TiandirenVentPainter(records: records),
                size: Size(size, size),
              ),
            ),
            const SizedBox(height: 8),
            _buildLegend(),
          ],
        );
      },
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: AppTheme.cardBorder.withValues(alpha: 0.7)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _dot('天元龙', const Color(0xFF3B8C6E)),
          const SizedBox(width: 20),
          _dot('地元龙', const Color(0xFF9A5A3A)),
          const SizedBox(width: 20),
          _dot('人元龙', const Color(0xFFC8922E)),
        ],
      ),
    );
  }

  Widget _dot(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary)),
      ],
    );
  }
}

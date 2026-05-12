import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../data/models/compass_record.dart';
import '../../../fengshui/mountain_24.dart';
import '../../../fengshui/measure_type_meaning.dart';

/// Maps each of the 24 mountains to an (innerRow, innerCol) in a 7x7 inner grid.
/// innerRow/innerCol range 1..7 (0 and 8 are the border ring).
const _mountainGridPos = <String, ({int r, int c})>{
  // Top row (innerRow=1)
  '巽': (r: 1, c: 2), '巳': (r: 1, c: 3),
  '丙': (r: 1, c: 4), '午': (r: 1, c: 5), '丁': (r: 1, c: 6),
  // Bottom row (innerRow=7)
  '癸': (r: 7, c: 2), '子': (r: 7, c: 3),
  '壬': (r: 7, c: 4), '亥': (r: 7, c: 5), '乾': (r: 7, c: 6),
  // Left column (innerCol=1)
  '乙': (r: 2, c: 1), '卯': (r: 3, c: 1),
  '甲': (r: 4, c: 1), '寅': (r: 5, c: 1), '艮': (r: 6, c: 1),
  // Right column (innerCol=7)
  '坤': (r: 2, c: 7), '申': (r: 3, c: 7),
  '庚': (r: 4, c: 7), '酉': (r: 5, c: 7), '辛': (r: 6, c: 7),
  // Corners
  '辰': (r: 1, c: 1), '未': (r: 1, c: 7),
  '戌': (r: 7, c: 7), '丑': (r: 7, c: 1),
};

// Border mountain layout: top row, right col, bottom row, left col
const _borderMountains = <String>[
  '辰', '巽', '巳', '丙', '午', '丁', '未',
  '未', '坤', '申', '庚', '酉', '辛', '戌',
  '戌', '乾', '亥', '壬', '子', '癸', '丑',
  '丑', '艮', '寅', '甲', '卯', '乙', '辰',
];

({int r, int c})? _mountainInnerPos(String mountain) {
  return _mountainGridPos[mountain];
}

class TiandirenVentPainter extends CustomPainter {
  final List<CompassRecord> records;

  TiandirenVentPainter({required this.records});

  @override
  void paint(Canvas canvas, Size size) {
    final R = math.min(size.width, size.height) / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final s = R / 150;

    _drawBackground(canvas, center, R, s);
    _drawBorderMountains(canvas, center, R, s);
    _drawInnerGrid(canvas, center, R, s);
    _drawPoints(canvas, center, R, s);
    _drawLegend(canvas, center, R, s);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;

  // =============================================
  // Background
  // =============================================

  void _drawBackground(Canvas canvas, Offset center, double R, double s) {
    final halfSide = R;
    final rect = Rect.fromLTWH(
        center.dx - halfSide, center.dy - halfSide, R * 2, R * 2);
    canvas.drawRect(rect, Paint()..color = const Color(0xFFFFFCF3));
    canvas.drawRect(
        rect,
        Paint()
          ..color = const Color(0xFFC9A96A).withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
  }

  // =============================================
  // Border mountains (9 positions per side, 4 sides)
  // =============================================

  void _drawBorderMountains(
      Canvas canvas, Offset center, double R, double s) {
    final halfSide = R;
    final cellSize = 2 * halfSide / 8; // 8 cells (7 inner + 2 border halves)

    // Draw mountain text on all 4 sides
    for (int i = 0; i < 28; i++) {
      final mountain = _borderMountains[i];
      // Determine which side and position
      final side = i ~/ 7; // 0=top, 1=right, 2=bottom, 3=left
      final pos = i % 7; // 0..6 within the side

      double x, y;
      if (side == 0) {
        // top
        x = center.dx - halfSide + (pos + 1) * cellSize;
        y = center.dy - halfSide + cellSize * 0.5;
      } else if (side == 1) {
        // right
        x = center.dx + halfSide - cellSize * 0.5;
        y = center.dy - halfSide + (pos + 1) * cellSize;
      } else if (side == 2) {
        // bottom
        x = center.dx - halfSide + (7 - pos) * cellSize;
        y = center.dy + halfSide - cellSize * 0.5;
      } else {
        // left
        x = center.dx - halfSide + cellSize * 0.5;
        y = center.dy - halfSide + (7 - pos) * cellSize;
      }

      _drawText(canvas, mountain, Offset(x, y), 12 * s,
          FontWeight.w500, const Color(0xFF4F351F));
    }
  }

  // =============================================
  // Inner grid (7x7)
  // =============================================

  void _drawInnerGrid(
      Canvas canvas, Offset center, double R, double s) {
    final halfSide = R;
    final cellSize = 2 * halfSide / 8;
    final gridLeft = center.dx - halfSide + cellSize;
    final gridTop = center.dy - halfSide + cellSize;
    final gridSize = cellSize * 7;

    // Background for inner grid
    canvas.drawRect(
      Rect.fromLTWH(gridLeft, gridTop, gridSize, gridSize),
      Paint()..color = const Color(0xFFFFF8E8),
    );

    // Grid lines
    final linePaint = Paint()
      ..color = const Color(0xFFC9A96A).withValues(alpha: 0.25)
      ..strokeWidth = 0.8;

    for (int i = 0; i <= 7; i++) {
      // Horizontal
      final y = gridTop + i * cellSize;
      canvas.drawLine(Offset(gridLeft, y),
          Offset(gridLeft + gridSize, y), linePaint);
      // Vertical
      final x = gridLeft + i * cellSize;
      canvas.drawLine(Offset(x, gridTop),
          Offset(x, gridTop + gridSize), linePaint);
    }

    // Outer border of inner grid
    canvas.drawRect(
      Rect.fromLTWH(gridLeft, gridTop, gridSize, gridSize),
      Paint()
        ..color = const Color(0xFFC9A96A).withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  // =============================================
  // Point markers
  // =============================================

  void _drawPoints(
      Canvas canvas, Offset center, double R, double s) {
    final halfSide = R;
    final cellSize = 2 * halfSide / 8;
    final gridLeft = center.dx - halfSide + cellSize;
    final gridTop = center.dy - halfSide + cellSize;

    for (final record in records) {
      final mountain = Mountain24Calculator.fromDegree(record.heading).mountain;
      final pos = _mountainInnerPos(mountain);
      if (pos == null) continue;

      // Place point at center of the cell
      final px = gridLeft + (pos.c - 0.5) * cellSize;
      final py = gridTop + (pos.r - 0.5) * cellSize;
      final pointCenter = Offset(px, py);

      final label = MeasureTypeMeaning.pointShortLabel(
        type: record.measureType,
        measureName: record.measureName,
      );
      final dotColor = _pointColor(record.measureType);

      // Dot
      canvas.drawCircle(pointCenter, 10 * s,
          Paint()..color = dotColor);

      // Label
      _drawCenteredText(canvas, label, pointCenter, 10 * s,
          FontWeight.bold, Colors.white);
    }
  }

  Color _pointColor(String type) {
    switch (type) {
      case 'door':
        return const Color(0xFF8A3A2B); // 红棕
      case 'bed':
        return const Color(0xFF3B7A4F); // 青绿
      case 'stove':
        return const Color(0xFFC8922E); // 金橙
      case 'altar':
        return const Color(0xFF6B4A7A); // 紫
      case 'desk':
        return const Color(0xFF3A6B8A); // 蓝
      case 'livingRoom':
        return const Color(0xFF7A6B3A); // 黄褐
      case 'balcony':
        return const Color(0xFF4A8A7A); // 青
      case 'window':
        return const Color(0xFF5A7A8A); // 灰蓝
      default:
        return const Color(0xFF6B5A45); // 褐
    }
  }

  // =============================================
  // Legend
  // =============================================

  void _drawLegend(
      Canvas canvas, Offset center, double R, double s) {
    final y = center.dy + R * 0.82;
    final labels = ['天元龙', '地元龙', '人元龙'];
    final colors = [
      const Color(0xFF3B8C6E),
      const Color(0xFF9A5A3A),
      const Color(0xFFC8922E),
    ];
    double x = center.dx - R * 0.50;
    for (int i = 0; i < 3; i++) {
      canvas.drawCircle(
          Offset(x, y), 5 * s, Paint()..color = colors[i]);
      _drawText(canvas, labels[i], Offset(x + 12 * s, y), 10 * s,
          FontWeight.w500, const Color(0xFF5F4630));
      x += R * 0.28;
    }
  }

  // =============================================
  // Helpers
  // =============================================

  void _drawText(Canvas canvas, String text, Offset pos,
      double size, FontWeight weight, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
            color: color,
            fontSize: size,
            fontWeight: weight,
            fontFamily: 'serif'),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
  }

  void _drawCenteredText(Canvas canvas, String text, Offset ctr,
      double size, FontWeight weight, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
            color: color,
            fontSize: size,
            fontWeight: weight,
            fontFamily: 'serif'),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, ctr - Offset(tp.width / 2, tp.height / 2));
  }
}

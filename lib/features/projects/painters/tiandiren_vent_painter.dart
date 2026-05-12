import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../data/models/compass_record.dart';
import '../../../fengshui/mountain_24.dart';
import '../../../fengshui/measure_type_meaning.dart';

/// Maps each of the 24 mountains to an (innerRow, innerCol) in a 7x7 inner grid.
const _mountainGridPos = <String, ({int r, int c})>{
  '巽': (r: 1, c: 2), '巳': (r: 1, c: 3),
  '丙': (r: 1, c: 4), '午': (r: 1, c: 5), '丁': (r: 1, c: 6),
  '癸': (r: 7, c: 2), '子': (r: 7, c: 3),
  '壬': (r: 7, c: 4), '亥': (r: 7, c: 5), '乾': (r: 7, c: 6),
  '乙': (r: 2, c: 1), '卯': (r: 3, c: 1),
  '甲': (r: 4, c: 1), '寅': (r: 5, c: 1), '艮': (r: 6, c: 1),
  '坤': (r: 2, c: 7), '申': (r: 3, c: 7),
  '庚': (r: 4, c: 7), '酉': (r: 5, c: 7), '辛': (r: 6, c: 7),
  '辰': (r: 1, c: 1), '未': (r: 1, c: 7),
  '戌': (r: 7, c: 7), '丑': (r: 7, c: 1),
};

const _borderMountains = <String>[
  '辰', '巽', '巳', '丙', '午', '丁', '未',
  '未', '坤', '申', '庚', '酉', '辛', '戌',
  '戌', '乾', '亥', '壬', '子', '癸', '丑',
  '丑', '艮', '寅', '甲', '卯', '乙', '辰',
];

({int r, int c})? _mountainInnerPos(String mountain) =>
    _mountainGridPos[mountain];

class TiandirenVentPainter extends CustomPainter {
  final List<CompassRecord> records;

  TiandirenVentPainter({required this.records});

  @override
  void paint(Canvas canvas, Size size) {
    final side = math.min(size.width, size.height);
    final outerPadding = side * 0.04;
    final chartSide = side - outerPadding * 2;
    final labelBand = chartSide * 0.13;
    final gridSide = chartSide - labelBand * 2;

    final chartLeft = (size.width - chartSide) / 2;
    final chartTop = (size.height - chartSide) / 2;

    final gridRect = Rect.fromLTWH(
      chartLeft + labelBand,
      chartTop + labelBand,
      gridSide,
      gridSide,
    );

    final cellW = gridRect.width / 7;
    final cellH = gridRect.height / 7;
    final s = side / 300; // scale factor

    _drawBackground(canvas, chartLeft, chartTop, chartSide, s);
    _drawBorderMountains(
        canvas, chartLeft, chartTop, chartSide, labelBand, s);
    _drawInnerGrid(canvas, gridRect, cellW, cellH, s);
    _drawPoints(canvas, gridRect, cellW, cellH, s);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;

  // =============================================
  // Background
  // =============================================

  void _drawBackground(Canvas canvas, double left, double top,
      double side, double s) {
    final rect = Rect.fromLTWH(left, top, side, side);
    canvas.drawRect(rect, Paint()..color = const Color(0xFFFFFCF3));
    canvas.drawRect(
        rect,
        Paint()
          ..color = const Color(0xFFC9A96A).withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
  }

  // =============================================
  // Border mountains
  // =============================================

  void _drawBorderMountains(Canvas canvas, double left, double top,
      double chartSide, double labelBand, double s) {
    final cellSize = chartSide / 8;

    for (int i = 0; i < 28; i++) {
      final mountain = _borderMountains[i];
      final side = i ~/ 7;
      final pos = i % 7;

      double x, y;
      if (side == 0) {
        x = left + (pos + 1) * cellSize;
        y = top + cellSize * 0.5;
      } else if (side == 1) {
        x = left + chartSide - cellSize * 0.5;
        y = top + (pos + 1) * cellSize;
      } else if (side == 2) {
        x = left + (7 - pos) * cellSize;
        y = top + chartSide - cellSize * 0.5;
      } else {
        x = left + cellSize * 0.5;
        y = top + (7 - pos) * cellSize;
      }

      _drawText(canvas, mountain, Offset(x, y), 11 * s,
          FontWeight.w500, const Color(0xFF4F351F));
    }
  }

  // =============================================
  // Inner grid (7x7)
  // =============================================

  void _drawInnerGrid(Canvas canvas, Rect gridRect, double cellW,
      double cellH, double s) {
    canvas.drawRect(gridRect,
        Paint()..color = const Color(0xFFFFF8E8));

    final linePaint = Paint()
      ..color = const Color(0xFFC9A96A).withValues(alpha: 0.25)
      ..strokeWidth = 0.8;

    for (int i = 0; i <= 7; i++) {
      final y = gridRect.top + i * cellH;
      canvas.drawLine(Offset(gridRect.left, y),
          Offset(gridRect.right, y), linePaint);
      final x = gridRect.left + i * cellW;
      canvas.drawLine(Offset(x, gridRect.top),
          Offset(x, gridRect.bottom), linePaint);
    }

    canvas.drawRect(
        gridRect,
        Paint()
          ..color = const Color(0xFFC9A96A).withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2);
  }

  // =============================================
  // Point markers — inside grid only
  // =============================================

  void _drawPoints(Canvas canvas, Rect gridRect, double cellW,
      double cellH, double s) {
    for (final record in records) {
      final mountain =
          Mountain24Calculator.fromDegree(record.heading).mountain;
      final pos = _mountainInnerPos(mountain);
      if (pos == null) continue;

      final px = gridRect.left + (pos.c - 0.5) * cellW;
      final py = gridRect.top + (pos.r - 0.5) * cellH;
      final center = Offset(px, py);

      final label = MeasureTypeMeaning.pointShortLabel(
        type: record.measureType,
        measureName: record.measureName,
      );
      final color = _pointColor(record.measureType);

      canvas.drawCircle(center, 9 * s, Paint()..color = color);
      _drawCenteredText(canvas, label, center, 9 * s,
          FontWeight.bold, Colors.white);
    }
  }

  Color _pointColor(String type) {
    switch (type) {
      case 'door':
        return const Color(0xFF8A3A2B);
      case 'bed':
        return const Color(0xFF3B7A4F);
      case 'stove':
        return const Color(0xFFC8922E);
      case 'altar':
        return const Color(0xFF6B4A7A);
      case 'desk':
        return const Color(0xFF3A6B8A);
      case 'livingRoom':
        return const Color(0xFF7A6B3A);
      case 'balcony':
        return const Color(0xFF4A8A7A);
      case 'window':
        return const Color(0xFF5A7A8A);
      default:
        return const Color(0xFF6B5A45);
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

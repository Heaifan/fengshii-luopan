import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../data/models/compass_record.dart';
import '../../../fengshui/mountain_24.dart';
import '../../../fengshui/mountain_24_info.dart';
import '../../../fengshui/measure_type_meaning.dart';

// Border mountain arrays (4 sides, corners repeat for visual continuity)
const _topMountains = ['辰', '巽', '巳', '丙', '午', '丁', '未'];
const _bottomMountains = ['丑', '癸', '子', '壬', '亥', '乾', '戌'];
const _leftMountains = ['辰', '乙', '卯', '甲', '寅', '艮', '丑'];
const _rightMountains = ['未', '坤', '申', '庚', '酉', '辛', '戌'];

/// Maps mountain → (row, col) in 0..6 range.
/// Corners use a single position each.
({int r, int c})? _mountainPos(String mountain) {
  const map = <String, ({int r, int c})>{
    // Top row (row 0)
    '辰': (r: 0, c: 0), '巽': (r: 0, c: 1), '巳': (r: 0, c: 2),
    '丙': (r: 0, c: 3), '午': (r: 0, c: 4), '丁': (r: 0, c: 5),
    '未': (r: 0, c: 6),
    // Left col (col 0)
    '乙': (r: 1, c: 0), '卯': (r: 2, c: 0), '甲': (r: 3, c: 0),
    '寅': (r: 4, c: 0), '艮': (r: 5, c: 0), '丑': (r: 6, c: 0),
    // Right col (col 6)
    '坤': (r: 1, c: 6), '申': (r: 2, c: 6), '庚': (r: 3, c: 6),
    '酉': (r: 4, c: 6), '辛': (r: 5, c: 6), '戌': (r: 6, c: 6),
    // Bottom row (row 6)
    '癸': (r: 6, c: 1), '子': (r: 6, c: 2), '壬': (r: 6, c: 3),
    '亥': (r: 6, c: 4), '乾': (r: 6, c: 5),
  };
  return map[mountain];
}

/// Sanyuan color by mountain character.
Color _sanyuanColorByMountain(String mountain) {
  final info = Mountain24InfoTable.fromMountain(mountain);
  switch (info.yuanLong) {
    case '天':
      return const Color(0xFF3B8C6E); // 玉青绿
    case '地':
      return const Color(0xFF9A5A3A); // 朱砂棕
    case '人':
      return const Color(0xFFC8922E); // 金橙
    default:
      return const Color(0xFF6B5A45);
  }
}

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
    final s = side / 300;

    _drawBackground(canvas, chartLeft, chartTop, chartSide, s);
    _drawBorderMountains(canvas, gridRect, labelBand, cellW, cellH, s);
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
  // Border mountains — each centred on a grid column/row
  // =============================================

  void _drawBorderMountains(Canvas canvas, Rect gridRect,
      double labelBand, double cellW, double cellH, double s) {
    final style = TextStyle(
      color: const Color(0xFF4F351F),
      fontSize: 12.5 * s,
      fontWeight: FontWeight.w500,
      fontFamily: 'serif',
    );

    final topY = gridRect.top - labelBand * 0.52;
    final bottomY = gridRect.bottom + labelBand * 0.52;
    final leftX = gridRect.left - labelBand * 0.52;
    final rightX = gridRect.right + labelBand * 0.52;

    // Top and bottom — align to column centres
    for (int i = 0; i < 7; i++) {
      final x = gridRect.left + cellW * (i + 0.5);
      _drawStyledText(canvas, _topMountains[i], Offset(x, topY), style);
      _drawStyledText(
          canvas, _bottomMountains[i], Offset(x, bottomY), style);
    }

    // Left and right — align to row centres
    for (int i = 0; i < 7; i++) {
      final y = gridRect.top + cellH * (i + 0.5);
      _drawStyledText(
          canvas, _leftMountains[i], Offset(leftX, y), style);
      _drawStyledText(
          canvas, _rightMountains[i], Offset(rightX, y), style);
    }
  }

  // =============================================
  // Inner grid (7×7) — drawn inside gridRect
  // =============================================

  void _drawInnerGrid(Canvas canvas, Rect gridRect, double cellW,
      double cellH, double s) {
    canvas.drawRect(gridRect,
        Paint()..color = const Color(0xFFFFF4DC));

    final linePaint = Paint()
      ..color = const Color(0xFFC9A96A).withValues(alpha: 0.35)
      ..strokeWidth = 0.8;

    for (int i = 0; i <= 7; i++) {
      final x = gridRect.left + cellW * i;
      canvas.drawLine(
          Offset(x, gridRect.top), Offset(x, gridRect.bottom), linePaint);
      final y = gridRect.top + cellH * i;
      canvas.drawLine(
          Offset(gridRect.left, y), Offset(gridRect.right, y), linePaint);
    }

    canvas.drawRect(
        gridRect,
        Paint()
          ..color = const Color(0xFFC9A96A).withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2);
  }

  // =============================================
  // Points — coloured by sanyuan, labelled by type
  // =============================================

  void _drawPoints(Canvas canvas, Rect gridRect, double cellW,
      double cellH, double s) {
    for (final record in records) {
      final mountain =
          Mountain24Calculator.fromDegree(record.heading).mountain;
      final pos = _mountainPos(mountain);
      if (pos == null) continue;

      final px = gridRect.left + cellW * (pos.c + 0.5);
      final py = gridRect.top + cellH * (pos.r + 0.5);
      final center = Offset(px, py);

      final label = MeasureTypeMeaning.pointShortLabel(
        type: record.measureType,
        measureName: record.measureName,
      );
      final color = _sanyuanColorByMountain(mountain);

      canvas.drawCircle(center, 9 * s, Paint()..color = color);
      _drawCenteredText(canvas, label, center, 9 * s,
          FontWeight.bold, Colors.white);
    }
  }

  // =============================================
  // Helpers
  // =============================================

  void _drawStyledText(
      Canvas canvas, String text, Offset center, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();
    tp.paint(canvas,
        Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
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

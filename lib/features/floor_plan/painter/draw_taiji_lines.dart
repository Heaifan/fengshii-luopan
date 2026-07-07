import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../fengshui/bagua.dart';
import '../math/mountain_parser.dart';
import 'draw_floor_plan_mountains.dart';
import 'floor_plan_draw_context.dart';

/// 山盘模式下绘制太极点与四条八宫分界线：
/// - 太极点位于宅盘几何中心
/// - 根据 7×7 外圈二十四山格的卦宫交界，找出 8 个精确交界点
/// - 绘制 4 条对穿线并延伸至宅盘外边界：
///   1) 乙辰交点 ↔ 辛戌交点
///   2) 巳丙交点 ↔ 亥壬交点
///   3) 丁未交点 ↔ 丑癸交点
///   4) 甲寅交点 ↔ 申庚交点
/// - 在各卦宫外圈山格区域内部标注「卦宫-星名 rank」
void drawTaijiLines(Canvas canvas, FloorPlanDrawContext ctx) {
  if (!ctx.data.overlays.showTaijiLines) return;
  if (ctx.data.gridMode != 'grid7' ||
      ctx.data.sittingMountain == null ||
      ctx.data.facingMountain == null) {
    return;
  }

  final sides = getMountainsAroundRect(ctx.data);
  if (sides.length != 4) return;

  final rect = ctx.floorRect;
  if (rect.width <= 0 || rect.height <= 0) return;

  final cells = buildMountainCells(rect, sides);
  final center = rect.center;

  final junctions = _findJunctions(cells, rect);

  // 山盘太极线使用山盘八宫（以坐山卦宫为伏位），与宫盘（以门定向）独立
  final results = calculateMountainPalaces(ctx.data);

  final linePaint = Paint()
    ..color = const Color(0xFFC43C32)
    ..strokeWidth = 2.5
    ..style = PaintingStyle.stroke;

  final centerPaint = Paint()
    ..color = const Color(0xFFC43C32)
    ..style = PaintingStyle.fill;

  // 中心太极点
  canvas.drawCircle(center, 5.0, centerPaint);

  // 四条对穿线：按固定的 4 对山名连接外侧交点
  if (junctions.containsKey('乙辰') && junctions.containsKey('辛戌')) {
    canvas.drawLine(junctions['乙辰']!, junctions['辛戌']!, linePaint);
  }
  if (junctions.containsKey('巳丙') && junctions.containsKey('亥壬')) {
    canvas.drawLine(junctions['巳丙']!, junctions['亥壬']!, linePaint);
  }
  if (junctions.containsKey('丁未') && junctions.containsKey('丑癸')) {
    canvas.drawLine(junctions['丁未']!, junctions['丑癸']!, linePaint);
  }
  if (junctions.containsKey('甲寅') && junctions.containsKey('申庚')) {
    canvas.drawLine(junctions['甲寅']!, junctions['申庚']!, linePaint);
  }

  // 标注各卦宫文字
  _drawGuaLabels(canvas, rect, cells, results);
}

/// 找出 8 个精确交界点（外侧顶点）
/// 不依赖山格顺序，直接按山名查找相邻山格的公共边界上、落在宅盘外框上的顶点
Map<String, Offset> _findJunctions(List<MountainCell> cells, Rect houseRect) {
  final junctions = <String, Offset>{};

  for (var i = 0; i < cells.length; i++) {
    for (var j = i + 1; j < cells.length; j++) {
      final a = cells[i], b = cells[j];
      final key = _junctionKey(a.mountain, b.mountain);
      if (key == null) continue;
      final p = _junctionPoint(a.rect, b.rect, houseRect);
      if (p != null) junctions[key] = p;
    }
  }

  return junctions;
}

/// 目标交界山名对
String? _junctionKey(String a, String b) {
  const pairs = {
    '乙辰', '巳丙', '丁未', '辛戌', '亥壬', '丑癸', '甲寅', '申庚',
  };
  final key = a + b;
  final reverse = b + a;
  if (pairs.contains(key)) return key;
  if (pairs.contains(reverse)) return reverse;
  return null;
}

/// 计算两个相邻山格的外侧交点：
/// - 若共享一条边，返回该边位于宅盘外框上的端点
/// - 若仅在角上相邻，返回该角点
Offset? _junctionPoint(Rect a, Rect b, Rect houseRect) {
  final eps = 0.001;

  // 垂直公共边
  if ((a.right - b.left).abs() < eps || (a.left - b.right).abs() < eps) {
    final x = (a.right - b.left).abs() < eps ? a.right : a.left;
    final top = math.max(a.top, b.top);
    final bottom = math.min(a.bottom, b.bottom);
    if (bottom > top) {
      final p1 = Offset(x, top);
      final p2 = Offset(x, bottom);
      if (_onHousePerimeter(p1, houseRect)) return p1;
      if (_onHousePerimeter(p2, houseRect)) return p2;
    }
  }

  // 水平公共边
  if ((a.bottom - b.top).abs() < eps || (a.top - b.bottom).abs() < eps) {
    final y = (a.bottom - b.top).abs() < eps ? a.bottom : a.top;
    final left = math.max(a.left, b.left);
    final right = math.min(a.right, b.right);
    if (right > left) {
      final p1 = Offset(left, y);
      final p2 = Offset(right, y);
      if (_onHousePerimeter(p1, houseRect)) return p1;
      if (_onHousePerimeter(p2, houseRect)) return p2;
    }
  }

  // 角相邻：仅共享一个顶点
  final cornersA = [a.topLeft, a.topRight, a.bottomLeft, a.bottomRight];
  final cornersB = [b.topLeft, b.topRight, b.bottomLeft, b.bottomRight];
  for (final ca in cornersA) {
    for (final cb in cornersB) {
      if ((ca.dx - cb.dx).abs() < eps && (ca.dy - cb.dy).abs() < eps) {
        return ca;
      }
    }
  }

  return null;
}

bool _onHousePerimeter(Offset p, Rect r) {
  final eps = 0.001;
  return (p.dx - r.left).abs() < eps ||
      (p.dx - r.right).abs() < eps ||
      (p.dy - r.top).abs() < eps ||
      (p.dy - r.bottom).abs() < eps;
}

/// 在各卦宫外圈山格区域内部写「卦宫-星名 rank」
void _drawGuaLabels(
  Canvas canvas,
  Rect rect,
  List<MountainCell> cells,
  Map<String, PalaceResult> results,
) {
  final guaCells = <String, List<MountainCell>>{};
  for (final cell in cells) {
    final g = BaguaCalculator.fromMountain(cell.mountain);
    guaCells.putIfAbsent(g, () => []).add(cell);
  }

  const guaOrder = ['乾', '兑', '艮', '坤', '坎', '震', '巽', '离'];
  for (final gua in guaOrder) {
    final list = guaCells[gua];
    if (list == null || list.isEmpty) continue;

    final union = list.map((c) => c.rect).reduce((a, b) => a.expandToInclude(b));
    final textPos = _shiftTowardsCenter(union.center, rect.center, 0.35);

    final palace = results[gua];
    final label = palace != null
        ? '$gua-${palace.star}${palace.rank.isNotEmpty ? ' ${palace.rank}' : ''}'
        : '$gua宫';

    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Color(0xFF4A3A12),
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(
      canvas,
      Offset(textPos.dx - tp.width / 2, textPos.dy - tp.height / 2),
    );
  }
}

/// 把 point 向 center 方向移动 factor 比例
Offset _shiftTowardsCenter(Offset point, Offset center, double factor) {
  return Offset(
    point.dx + (center.dx - point.dx) * factor,
    point.dy + (center.dy - point.dy) * factor,
  );
}

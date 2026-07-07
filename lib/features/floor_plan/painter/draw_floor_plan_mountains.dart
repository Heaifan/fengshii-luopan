import 'package:flutter/material.dart';
import '../../../data/models/floor_plan_data.dart';
import '../math/mountain_parser.dart';
import 'floor_plan_draw_context.dart';

/// 二十四山到八卦宫的映射
const _mountainToGua = <String, String>{
  '壬': '坎', '子': '坎', '癸': '坎',
  '丑': '艮', '艮': '艮', '寅': '艮',
  '甲': '震', '卯': '震', '乙': '震',
  '辰': '巽', '巽': '巽', '巳': '巽',
  '丙': '离', '午': '离', '丁': '离',
  '未': '坤', '坤': '坤', '申': '坤',
  '庚': '兑', '酉': '兑', '辛': '兑',
  '戌': '乾', '乾': '乾', '亥': '乾',
};

/// 在宅盘 7×7 外圈格子内部中心绘制二十四山
void drawFloorPlanMountains(Canvas canvas, FloorPlanDrawContext ctx) {
  if (!ctx.data.overlays.showTwentyFourMountains) return;

  // 仅在 7×7 网格且已设置坐向时绘制二十四山
  if (ctx.data.gridMode != 'grid7' ||
      ctx.data.sittingMountain == null ||
      ctx.data.facingMountain == null) {
    return;
  }

  final sides = getMountainsAroundRect(ctx.data);
  if (sides.length != 4) return;

  final rect = ctx.floorRect;
  if (rect.width <= 0 || rect.height <= 0) return;

  final cw = rect.width / 7, ch = rect.height / 7;
  final fs = (cw < ch ? cw : ch) * 0.5;

  // 顶行 7 个山
  for (var i = 0; i < sides[0].length; i++) {
    _drawMountain(canvas, sides[0][i], rect.left + cw * (i + 0.5),
        rect.top + ch * 0.5, fs, ctx.data);
  }

  // 右列 5 个山
  for (var i = 0; i < sides[1].length; i++) {
    _drawMountain(canvas, sides[1][i], rect.right - cw * 0.5,
        rect.top + ch * (i + 1.5), fs, ctx.data);
  }

  // 底行 7 个山（从左到右）
  for (var i = 0; i < sides[2].length; i++) {
    _drawMountain(canvas, sides[2][i], rect.left + cw * (i + 0.5),
        rect.bottom - ch * 0.5, fs, ctx.data);
  }

  // 左列 5 个山（从上到下）
  for (var i = 0; i < sides[3].length; i++) {
    _drawMountain(canvas, sides[3][i], rect.left + cw * 0.5,
        rect.top + ch * (i + 1.5), fs, ctx.data);
  }
}

void _drawMountain(Canvas canvas, String m, double cx, double cy,
    double fontSize, FloorPlanData data) {
  final color3 = kSanyuanColor[m] ?? Color3.red;
  final baseColor = color3Value(color3);
  final isHL = m == data.sittingMountain || m == data.facingMountain;

  // 坐山向首淡红底
  if (isHL) {
    final r = fontSize * 0.6;
    canvas.drawRect(Rect.fromCenter(
        center: Offset(cx, cy), width: r * 2, height: r * 1.6),
        Paint()..color = const Color(0x20C62828));
  }

  final tp = TextPainter(
    text: TextSpan(
      text: m,
      style: TextStyle(
        color: Color(baseColor),
        fontSize: fontSize,
        fontWeight: isHL ? FontWeight.w900 : FontWeight.w700,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
}

/// 山盘模式下的单个山命中检测：返回山名及其格子矩形
MountainCell? hitTestMountain(Offset point, FloorPlanData data, Rect floorRect) {
  if (data.gridMode != 'grid7' ||
      data.sittingMountain == null ||
      data.facingMountain == null) {
    return null;
  }

  final sides = getMountainsAroundRect(data);
  if (sides.length != 4) return null;

  final cells = buildMountainCells(floorRect, sides);
  for (final cell in cells) {
    if (cell.rect.contains(point)) {
      return cell;
    }
  }
  return null;
}

/// 山盘模式下的宫位命中检测：返回点击位置对应的宫位结果及其外接矩形
PalaceHitInfo? hitTestMountainPalace(Offset point, FloorPlanData data, Rect floorRect) {
  if (data.gridMode != 'grid7' ||
      data.sittingMountain == null ||
      data.facingMountain == null) {
    return null;
  }

  // 山盘模式下的宫位详情与宫盘统一：以门所在卦宫为伏位
  final results = calculateEightPalaces(data);
  if (results.isEmpty) return null;

  final sides = getMountainsAroundRect(data);
  if (sides.length != 4) return null;

  final cells = buildMountainCells(floorRect, sides);
  String? hitGua;
  for (final cell in cells) {
    if (cell.rect.contains(point)) {
      hitGua = _mountainToGua[cell.mountain];
      break;
    }
  }
  if (hitGua == null) return null;

  final p = results[hitGua];
  if (p == null) return null;

  // 合并同宫所有山格子的外接矩形
  final sameGuaRects = cells
      .where((c) => _mountainToGua[c.mountain] == hitGua)
      .map((c) => c.rect);
  final rect = sameGuaRects.reduce((a, b) => a.expandToInclude(b));

  return PalaceHitInfo(palace: p, rect: rect);
}

List<MountainCell> buildMountainCells(Rect rect, List<List<String>> sides) {
  final cw = rect.width / 7, ch = rect.height / 7;
  final cells = <MountainCell>[];

  // top 7
  for (var i = 0; i < sides[0].length; i++) {
    cells.add(MountainCell(
      sides[0][i],
      Rect.fromLTWH(rect.left + cw * i, rect.top, cw, ch),
    ));
  }

  // right 5
  for (var i = 0; i < sides[1].length; i++) {
    cells.add(MountainCell(
      sides[1][i],
      Rect.fromLTWH(rect.left + cw * 6, rect.top + ch * (i + 1), cw, ch),
    ));
  }

  // bottom 7
  for (var i = 0; i < sides[2].length; i++) {
    cells.add(MountainCell(
      sides[2][i],
      Rect.fromLTWH(rect.left + cw * i, rect.top + ch * 6, cw, ch),
    ));
  }

  // left 5
  for (var i = 0; i < sides[3].length; i++) {
    cells.add(MountainCell(
      sides[3][i],
      Rect.fromLTWH(rect.left, rect.top + ch * (i + 1), cw, ch),
    ));
  }

  return cells;
}

class MountainCell {
  final String mountain;
  final Rect rect;
  const MountainCell(this.mountain, this.rect);
}

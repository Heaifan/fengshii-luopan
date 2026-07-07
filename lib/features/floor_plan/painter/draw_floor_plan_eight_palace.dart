import 'package:flutter/material.dart';
import '../../../data/models/floor_plan_data.dart';
import '../../../fengshui/bazhai_you_nian_table.dart';
import '../math/mountain_parser.dart';
import 'floor_plan_draw_context.dart';

/// 八宫在 4×4 网格下的绘制：
/// - 中宫 2×2 留空
/// - 四正（离/坎/震/兑）各占 2 格
/// - 四隅（巽/坤/艮/乾）各占 1 格
/// - 背景按五行颜色淡铺，星名下方用方框标 rank（如一吉、二凶）
void drawEightPalace(Canvas canvas, FloorPlanDrawContext ctx) {
  if (ctx.data.gridMode != 'grid4') return;

  final results = calculateEightPalaces(ctx.data);
  if (results.isEmpty) return;

  final rect = ctx.floorRect;
  if (rect.width <= 0 || rect.height <= 0) return;

  final cells = _buildPalaceCells(rect);
  final baseUnit = rect.width < rect.height ? rect.width / 4 : rect.height / 4;

  for (final cell in cells) {
    final p = results[cell.gua];
    if (p == null) continue;

    final meta = bazhaiStarMetaMap[p.star];
    final baseColor = meta?.color ?? (p.isAuspicious ? const Color(0xFF2E7D32) : const Color(0xFF8A6D3B));

    // 背景淡铺
    canvas.drawRect(
      cell.rect,
      Paint()..color = baseColor.withOpacity(0.10),
    );

    // 绘制宫名 + 方框 rank
    _drawPalaceText(canvas, cell.rect, p, baseUnit);
  }
}

/// 根据宅盘矩形构建八宫区域，用于绘制和点击命中检测
List<_PalaceCell> buildPalaceCells(Rect rect) => _buildPalaceCells(rect);

List<_PalaceCell> _buildPalaceCells(Rect rect) {
  final cellW = rect.width / 4;
  final cellH = rect.height / 4;

  return [
    // 四隅 1 格
    _PalaceCell('巽', Rect.fromLTWH(rect.left, rect.top, cellW, cellH)),           // 东南/上左
    _PalaceCell('坤', Rect.fromLTWH(rect.left + cellW * 3, rect.top, cellW, cellH)), // 西南/上右
    _PalaceCell('艮', Rect.fromLTWH(rect.left, rect.top + cellH * 3, cellW, cellH)), // 东北/下左
    _PalaceCell('乾', Rect.fromLTWH(rect.left + cellW * 3, rect.top + cellH * 3, cellW, cellH)), // 西北/下右
    // 四正 2 格
    _PalaceCell('离', Rect.fromLTWH(rect.left + cellW, rect.top, cellW * 2, cellH)),           // 南/上中
    _PalaceCell('坎', Rect.fromLTWH(rect.left + cellW, rect.top + cellH * 3, cellW * 2, cellH)), // 北/下中
    _PalaceCell('震', Rect.fromLTWH(rect.left, rect.top + cellH, cellW, cellH * 2)),           // 东/左中
    _PalaceCell('兑', Rect.fromLTWH(rect.left + cellW * 3, rect.top + cellH, cellW, cellH * 2)), // 西/右中
  ];
}

/// 命中检测：返回点击位置对应的八宫结果及其外接矩形，未命中返回 null
PalaceHitInfo? hitTestEightPalace(Offset point, FloorPlanData data, Rect floorRect) {
  if (data.gridMode != 'grid4') return null;
  final results = calculateEightPalaces(data);
  if (results.isEmpty) return null;

  for (final cell in buildPalaceCells(floorRect)) {
    if (cell.rect.contains(point)) {
      final p = results[cell.gua];
      if (p == null) return null;
      return PalaceHitInfo(palace: p, rect: cell.rect);
    }
  }
  return null;
}

class _PalaceCell {
  final String gua;
  final Rect rect;
  const _PalaceCell(this.gua, this.rect);
}

void _drawPalaceText(Canvas canvas, Rect rect, PalaceResult p, double baseUnit) {
  final starSize = baseUnit * 0.22;
  final rankSize = baseUnit * 0.13;
  final gap = baseUnit * 0.06;

  final meta = bazhaiStarMetaMap[p.star];
  final starColor = meta?.color ?? (p.isAuspicious ? const Color(0xFF2E7D32) : const Color(0xFF8A6D3B));
  final rankColor = p.isAuspicious ? const Color(0xFF2E7D32) : const Color(0xFFC43C32);

  final starTp = TextPainter(
    text: TextSpan(
      text: p.star,
      style: TextStyle(
        color: starColor,
        fontSize: starSize,
        fontWeight: FontWeight.w800,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  TextPainter? rankTp;
  if (p.rank.isNotEmpty) {
    rankTp = TextPainter(
      text: TextSpan(
        text: p.rank,
        style: TextStyle(
          color: rankColor,
          fontSize: rankSize,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  final totalH = starTp.height + gap + (rankTp?.height ?? 0);
  final totalW = starTp.width > (rankTp?.width ?? 0) ? starTp.width : (rankTp?.width ?? 0);

  final startX = rect.left + (rect.width - totalW) / 2;
  final startY = rect.top + (rect.height - totalH) / 2;

  // 星名居中
  starTp.paint(
    canvas,
    Offset(startX + (totalW - starTp.width) / 2, startY),
  );

  // rank 方框
  if (rankTp != null) {
    final boxPad = rankSize * 0.35;
    final boxW = rankTp.width + boxPad * 2;
    final boxH = rankTp.height + boxPad * 0.8;
    final boxX = rect.left + (rect.width - boxW) / 2;
    final boxY = startY + starTp.height + gap;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(boxX, boxY, boxW, boxH),
      Radius.circular(baseUnit * 0.04),
    );

    // 方框背景（淡）
    canvas.drawRRect(
      rrect,
      Paint()..color = rankColor.withOpacity(0.08),
    );
    // 方框边框
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = rankColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = baseUnit * 0.008,
    );

    rankTp.paint(
      canvas,
      Offset(boxX + boxPad, boxY + (boxH - rankTp.height) / 2),
    );
  }
}

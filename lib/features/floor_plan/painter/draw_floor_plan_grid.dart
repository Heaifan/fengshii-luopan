import 'package:flutter/material.dart';
import 'floor_plan_draw_context.dart';

/// 绘制 4×4 / 7×7 辅助网格
void drawFloorPlanGrid(Canvas canvas, FloorPlanDrawContext ctx) {
  if (!ctx.data.overlays.showGrid) return;

  final rect = ctx.floorRect;
  final cols = ctx.gridCols;
  final rows = ctx.gridRows;

  final paint = Paint()
    ..color = const Color(0xFFBCAA8A).withAlpha(120)
    ..strokeWidth = 0.8;

  // 竖线
  for (var i = 1; i < cols; i++) {
    final x = rect.left + rect.width * i / cols;
    canvas.drawLine(Offset(x, rect.top), Offset(x, rect.bottom), paint);
  }

  // 横线
  for (var i = 1; i < rows; i++) {
    final y = rect.top + rect.height * i / rows;
    canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), paint);
  }
}

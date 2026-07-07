import 'package:flutter/material.dart';
import '../../../data/models/floor_plan_data.dart';
import 'floor_plan_draw_context.dart';
import 'draw_floor_plan_rect.dart';
import 'draw_floor_plan_grid.dart';
import 'draw_floor_plan_mountains.dart';
import 'draw_floor_plan_door.dart';
import 'draw_floor_plan_eight_palace.dart';
import 'draw_taiji_lines.dart';

/// 宅盘图主绘制器 — 统一入口，按图层顺序分派
class FloorPlanPainter extends CustomPainter {
  final FloorPlanData data;

  FloorPlanPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    final ctx = FloorPlanDrawContext(data: data, canvasSize: size);
    if (ctx.floorRect.isEmpty || ctx.floorRect.width <= 0) return;

    drawFloorPlanRect(canvas, ctx);
    drawFloorPlanGrid(canvas, ctx);
    drawFloorPlanMountains(canvas, ctx);  // 二十四山先画
    drawTaijiLines(canvas, ctx);          // 太极点与八宫辐射线
    drawEightPalace(canvas, ctx);         // 八宫后画，但文字限制在 5×5 内部
    drawFloorPlanDoor(canvas, ctx);       // 门最后画，确保在最上层
  }

  @override
  bool shouldRepaint(covariant FloorPlanPainter oldDelegate) {
    return oldDelegate.data != data;
  }
}

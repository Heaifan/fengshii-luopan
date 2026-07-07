import 'package:flutter/material.dart';
import 'floor_plan_draw_context.dart';

/// 绘制宅盘矩形底座
void drawFloorPlanRect(Canvas canvas, FloorPlanDrawContext ctx) {
  final rect = ctx.floorRect;

  // 底座背景
  canvas.drawRect(
    rect,
    Paint()..color = const Color(0xFFF7F0DF),
  );

  // 底座边框
  canvas.drawRect(
    rect,
    Paint()
      ..color = const Color(0xFF9A7A3D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2,
  );
}

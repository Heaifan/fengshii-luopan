import 'package:flutter/material.dart';
import 'floor_plan_draw_context.dart';

/// 绘制主门跨在宅盘边线上
void drawFloorPlanDoor(Canvas canvas, FloorPlanDrawContext ctx) {
  final door = ctx.data.mainDoor;
  if (door == null) return;

  final rect = ctx.floorRect;
  final thick = rect.shortestSide * 0.025;
  final half = thick / 2;

  // 直接计算比例，不依赖 calcDoorSegment
  final isHoriz = door.wall == 'top' || door.wall == 'bottom';
  final wallLen = isHoriz ? ctx.data.widthCm : ctx.data.heightCm;
  final pxLen = isHoriz ? rect.width : rect.height;

  // offsetCm 是门距基准角的距离，需根据 offsetFrom 换算成门起点
  double startCm = door.offsetCm;
  if (door.offsetFrom == 'right' || door.offsetFrom == 'bottom') {
    startCm = wallLen - door.offsetCm - door.widthCm;
  }

  // 门起点比例和长度比例
  final startRatio = startCm / wallLen;
  final lenRatio = door.widthCm / wallLen;

  // clamp 保证不越界
  final sr = startRatio.clamp(0.0, 1.0 - lenRatio);

  final startPx = sr * pxLen;
  final wPx = lenRatio * pxLen;

  final paint = Paint()..color = const Color(0xFF5A4724);
  final borderPaint = Paint()
    ..color = const Color(0xFF3A2710)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;

  late Rect doorRect;
  switch (door.wall) {
    case 'top':
      doorRect = Rect.fromLTWH(rect.left + startPx, rect.top - half, wPx, thick);
      break;
    case 'bottom':
      doorRect = Rect.fromLTWH(rect.left + startPx, rect.bottom - half, wPx, thick);
      break;
    case 'left':
      doorRect = Rect.fromLTWH(rect.left - half, rect.top + startPx, thick, wPx);
      break;
    case 'right':
      doorRect = Rect.fromLTWH(rect.right - half, rect.top + startPx, thick, wPx);
      break;
    default:
      return;
  }

  canvas.drawRect(doorRect, paint);
  canvas.drawRect(doorRect, borderPaint);

  // 门标签
  final label = door.label.isNotEmpty ? door.label : '门';
  final tp = TextPainter(
    text: TextSpan(
      text: label,
      style: const TextStyle(
        color: Color(0xFFFFF9F0), fontSize: 11, fontWeight: FontWeight.w700),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  Offset labelPos;
  switch (door.wall) {
    case 'top': labelPos = Offset(rect.left + startPx + wPx / 2 - tp.width / 2, rect.top - half - tp.height - 2); break;
    case 'bottom': labelPos = Offset(rect.left + startPx + wPx / 2 - tp.width / 2, rect.bottom + half + 2); break;
    case 'left': labelPos = Offset(rect.left - half - tp.width - 2, rect.top + startPx + wPx / 2 - tp.height / 2); break;
    case 'right': labelPos = Offset(rect.right + half + 2, rect.top + startPx + wPx / 2 - tp.height / 2); break;
    default: labelPos = Offset.zero;
  }

  final bgRect = Rect.fromCenter(
    center: Offset(labelPos.dx + tp.width / 2, labelPos.dy + tp.height / 2),
    width: tp.width + 6, height: tp.height + 4,
  );
  canvas.drawRRect(RRect.fromRectAndRadius(bgRect, const Radius.circular(3)),
      Paint()..color = const Color(0xCC5A4724));
  tp.paint(canvas, labelPos + const Offset(3, 2));
}

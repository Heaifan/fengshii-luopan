import 'package:flutter/material.dart';
import '../../../data/models/floor_plan_data.dart';

/// 宅盘画布坐标计算上下文
class FloorPlanDrawContext {
  final FloorPlanData data;
  final Size canvasSize;
  final double padding;

  FloorPlanDrawContext({
    required this.data,
    required this.canvasSize,
    this.padding = 40,
  });

  late final Rect floorRect = _calcFloorRect();

  Rect _calcFloorRect() {
    final innerW = canvasSize.width - padding * 2;
    final innerH = canvasSize.height - padding * 2;
    if (innerW <= 0 || innerH <= 0) return Rect.zero;
    final aspect = data.widthCm / data.heightCm;
    double w, h;
    if (innerW / innerH > aspect) {
      h = innerH;
      w = h * aspect;
    } else {
      w = innerW;
      h = w / aspect;
    }
    final dx = (canvasSize.width - w) / 2;
    final dy = (canvasSize.height - h) / 2;
    return Offset(dx, dy) & Size(w, h);
  }

  double cmToX(double cm) {
    return floorRect.left + (cm / data.widthCm) * floorRect.width;
  }

  double cmToY(double cm) {
    return floorRect.top + (cm / data.heightCm) * floorRect.height;
  }

  /// 沿指定边的 cm → canvas 坐标
  double cmToEdge(double cm, String wall) {
    switch (wall) {
      case 'top': return floorRect.left + (cm / data.widthCm) * floorRect.width;
      case 'bottom': return floorRect.left + (cm / data.widthCm) * floorRect.width;
      case 'left': return floorRect.top + (cm / data.heightCm) * floorRect.height;
      case 'right': return floorRect.top + (cm / data.heightCm) * floorRect.height;
      default: return floorRect.left;
    }
  }

  /// 网格行列数
  int get gridCols => data.gridMode == 'grid7' ? 7 : 4;
  int get gridRows => data.gridMode == 'grid7' ? 7 : 4;

  /// 山名字号
  double get mountainFontSize => floorRect.shortestSide * 0.032;
}

import '../../../data/models/floor_plan_data.dart';

/// 门在边上的线段 [startCm, endCm] 和中心点
class DoorSegment {
  final double startCm;
  final double endCm;
  final double centerCm;
  final double wallLength;

  const DoorSegment({
    required this.startCm,
    required this.endCm,
    required this.centerCm,
    required this.wallLength,
  });
}

/// 计算门在墙上的线段
DoorSegment calcDoorSegment(FloorPlanData data, FloorPlanDoor door) {
  final wallLength = doorWallLength(data, door.wall);
  var start = door.offsetCm;
  if (door.offsetFrom == 'right' || door.offsetFrom == 'bottom') {
    start = wallLength - door.offsetCm - door.widthCm;
  }
  final end = start + door.widthCm;
  final center = start + door.widthCm / 2;
  return DoorSegment(
    startCm: start,
    endCm: end,
    centerCm: center,
    wallLength: wallLength,
  );
}

/// 获取某条边的总长度
double doorWallLength(FloorPlanData data, String wall) {
  if (wall == 'top' || wall == 'bottom') return data.widthCm;
  return data.heightCm;
}

/// 获取门的默认基准角
String defaultOffsetFrom(String wall) {
  switch (wall) {
    case 'top': return 'left';
    case 'bottom': return 'left';
    case 'left': return 'top';
    case 'right': return 'top';
    default: return 'left';
  }
}

/// 计算门居中时的 offsetCm
double centeredOffset(FloorPlanData data, String wall, double doorWidth) {
  final len = doorWallLength(data, wall);
  return (len - doorWidth) / 2;
}

/// 检测最近边（基于 canvas 坐标归一化到 0..1）
String snapWall(double nx, double ny) {
  // nx, ny 是门中心点在宅盘矩形中的位置比例 (0..1)
  final distTop = ny;
  final distBottom = (1 - ny);
  final distLeft = nx;
  final distRight = (1 - nx);

  double minDist = 1.0;
  String nearest = 'bottom';

  void check(String wall, double d) {
    if (d < minDist) {
      minDist = d;
      nearest = wall;
    }
  }

  check('top', distTop);
  check('bottom', distBottom);
  check('left', distLeft);
  check('right', distRight);

  return nearest;
}

/// 根据边和比例位置计算 offsetCm
double offsetFromRatio(FloorPlanData data, String wall, double ratio) {
  final len = doorWallLength(data, wall);
  return ratio * len;
}

/// 根据 canvas 坐标归一化到宅盘比例
double normalizeCoord(double canvasPos, double rectStart, double rectLen) {
  if (rectLen <= 0) return 0;
  return (canvasPos - rectStart) / rectLen;
}

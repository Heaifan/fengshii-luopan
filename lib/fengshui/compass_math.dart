double normalizeDegree(double degree) {
  final result = degree % 360;
  return result < 0 ? result + 360 : result;
}

double oppositeDegree(double degree) {
  return normalizeDegree(degree + 180);
}

double applyCalibration(double rawHeading, double offset) {
  return normalizeDegree(rawHeading - offset);
}

double smoothDegree({
  required double previous,
  required double current,
  double factor = 0.15,
}) {
  var diff = current - previous;

  if (diff > 180) diff -= 360;
  if (diff < -180) diff += 360;

  return normalizeDegree(previous + diff * factor);
}

String compassDirectionName(double degree) {
  final d = normalizeDegree(degree);
  const dirs = [
    '北', '东北', '东', '东南', '南', '西南', '西', '西北',
  ];
  // Each direction spans 45°, centered at 0°, 45°, 90°, ...
  final idx = ((d + 22.5) ~/ 45) % 8;
  return dirs[idx];
}

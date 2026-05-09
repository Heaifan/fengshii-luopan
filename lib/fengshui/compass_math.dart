double normalizeDegree(double degree) {
  final result = degree % 360;
  return result < 0 ? result + 360 : result;
}

double oppositeDegree(double degree) {
  return normalizeDegree(degree + 180);
}

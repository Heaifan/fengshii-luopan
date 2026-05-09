import 'fengshui_point.dart';

class HouseRecord {
  final String id;
  final String name;
  final String houseGua;
  final String lifeGua;
  final List<FengShuiPoint> points;
  final DateTime createdAt;

  const HouseRecord({
    required this.id,
    required this.name,
    required this.houseGua,
    required this.lifeGua,
    required this.points,
    required this.createdAt,
  });
}

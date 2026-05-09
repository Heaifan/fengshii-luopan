import '../../fengshui/sanyuan_dragon.dart';

class FengShuiPoint {
  final String type;
  final double degree;
  final String mountain;
  final String gua;
  final String bazhaiStar;
  final bool isAuspicious;
  final SanyuanType sanyuanType;
  final DateTime createdAt;

  const FengShuiPoint({
    required this.type,
    required this.degree,
    required this.mountain,
    required this.gua,
    required this.bazhaiStar,
    required this.isAuspicious,
    required this.sanyuanType,
    required this.createdAt,
  });
}

import 'bazhai_you_nian_table.dart';

class BazhaiResult {
  final String star;
  final String rank;
  final bool isAuspicious;

  const BazhaiResult({
    required this.star,
    required this.rank,
    required this.isAuspicious,
  });
}

class BazhaiCalculator {
  BazhaiCalculator._();

  static const List<String> guas = [
    '坎', '坤', '震', '巽', '乾', '兑', '艮', '离',
  ];

  static BazhaiResult getStar({
    required String houseGua,
    required String targetGua,
  }) {
    final star = getBazhaiStar(houseGua: houseGua, palaceGua: targetGua);
    if (star.isEmpty) {
      return const BazhaiResult(star: '未知', rank: '', isAuspicious: false);
    }
    final meta = bazhaiStarMetaMap[star];
    final rank = getBazhaiStarRank(houseGua: houseGua, starName: star);
    return BazhaiResult(
      star: star,
      rank: rank,
      isAuspicious: meta?.isGood ?? false,
    );
  }
}

import 'compass_math.dart';
import 'mountain_24.dart';
import 'bagua.dart';
import 'bazhai.dart';
import 'sanyuan_dragon.dart';

class CompassReading {
  final double facingDegree;
  final double sittingDegree;
  final String facingMountain;
  final String sittingMountain;
  final String facingGua;
  final String sittingGua;
  final String sanyuanType;
  final String bazhaiStar;
  final String bazhaiRank;
  final bool isAuspicious;
  final String sittingFacingText;

  const CompassReading({
    required this.facingDegree,
    required this.sittingDegree,
    required this.facingMountain,
    required this.sittingMountain,
    required this.facingGua,
    required this.sittingGua,
    required this.sanyuanType,
    required this.bazhaiStar,
    required this.bazhaiRank,
    required this.isAuspicious,
    required this.sittingFacingText,
  });
}

class CompassReadingBuilder {
  CompassReadingBuilder._();

  static CompassReading build({
    required double degree,
    required String houseGua,
  }) {
    final facing = Mountain24Calculator.fromDegree(degree);
    final sittingDegree = oppositeDegree(degree);
    final sitting = Mountain24Calculator.fromDegree(sittingDegree);

    final facingGua = BaguaCalculator.fromMountain(facing.mountain);
    final sittingGua = BaguaCalculator.fromMountain(sitting.mountain);

    final sanyuan = SanyuanDragonCalculator.fromMountain(facing.mountain);

    final bazhai = BazhaiCalculator.getStar(
      houseGua: houseGua,
      targetGua: facingGua,
    );

    return CompassReading(
      facingDegree: normalizeDegree(degree),
      sittingDegree: normalizeDegree(sittingDegree),
      facingMountain: facing.mountain,
      sittingMountain: sitting.mountain,
      facingGua: facingGua,
      sittingGua: sittingGua,
      sanyuanType: sanyuan.label,
      bazhaiStar: bazhai.star,
      bazhaiRank: bazhai.rank,
      isAuspicious: bazhai.isAuspicious,
      sittingFacingText: '坐${sitting.mountain}向${facing.mountain}',
    );
  }
}

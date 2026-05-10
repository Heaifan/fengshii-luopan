import 'compass_math.dart';

class Mountain24Result {
  final String mountain;
  final int index;
  final double centerDegree;
  final double startDegree;
  final double endDegree;

  const Mountain24Result({
    required this.mountain,
    required this.index,
    required this.centerDegree,
    required this.startDegree,
    required this.endDegree,
  });
}

class Mountain24Calculator {
  Mountain24Calculator._();

  static const List<String> mountains = [
    '子', '癸', '丑', '艮', '寅', '甲',
    '卯', '乙', '辰', '巽', '巳', '丙',
    '午', '丁', '未', '坤', '申', '庚',
    '酉', '辛', '戌', '乾', '亥', '壬',
  ];

  // 五行, indexed same as mountains
  static const List<String> elements = [
    '水', '水', '土', '土', '土', '木',
    '木', '木', '木', '木', '木', '火',
    '火', '火', '土', '土', '金', '金',
    '金', '金', '土', '金', '水', '水',
  ];

  static String elementOf(String mountain) {
    final i = mountains.indexOf(mountain);
    return i >= 0 ? elements[i] : '';
  }

  static Mountain24Result fromDegree(double degree) {
    final d = normalizeDegree(degree);
    final index = ((d + 7.5) ~/ 15) % 24;
    final center = index * 15.0;

    return Mountain24Result(
      mountain: mountains[index],
      index: index,
      centerDegree: center,
      startDegree: normalizeDegree(center - 7.5),
      endDegree: normalizeDegree(center + 7.5),
    );
  }
}

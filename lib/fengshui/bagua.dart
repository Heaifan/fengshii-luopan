class BaguaCalculator {
  BaguaCalculator._();

  static const Map<String, String> mountainToGua = {
    '壬': '坎', '子': '坎', '癸': '坎',
    '丑': '艮', '艮': '艮', '寅': '艮',
    '甲': '震', '卯': '震', '乙': '震',
    '辰': '巽', '巽': '巽', '巳': '巽',
    '丙': '离', '午': '离', '丁': '离',
    '未': '坤', '坤': '坤', '申': '坤',
    '庚': '兑', '酉': '兑', '辛': '兑',
    '戌': '乾', '乾': '乾', '亥': '乾',
  };

  static String fromMountain(String mountain) {
    return mountainToGua[mountain] ?? '未知';
  }
}

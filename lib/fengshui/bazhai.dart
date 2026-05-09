class BazhaiResult {
  final String star;
  final bool isAuspicious;

  const BazhaiResult({
    required this.star,
    required this.isAuspicious,
  });
}

class BazhaiCalculator {
  BazhaiCalculator._();

  static const List<String> guas = [
    '坎', '坤', '震', '巽', '乾', '兑', '艮', '离',
  ];

  static const Set<String> goodStars = {
    '生气', '天医', '延年', '伏位',
  };

  static const Map<String, Map<String, String>> table = {
    '坎': {
      '坎': '伏位', '震': '天医', '巽': '生气', '离': '延年',
      '坤': '绝命', '兑': '祸害', '艮': '五鬼', '乾': '六煞',
    },
    '坤': {
      '坤': '伏位', '兑': '天医', '艮': '生气', '乾': '延年',
      '坎': '绝命', '震': '祸害', '巽': '五鬼', '离': '六煞',
    },
    '震': {
      '震': '伏位', '坎': '天医', '离': '生气', '巽': '延年',
      '兑': '绝命', '坤': '祸害', '乾': '五鬼', '艮': '六煞',
    },
    '巽': {
      '巽': '伏位', '离': '天医', '坎': '生气', '震': '延年',
      '艮': '绝命', '乾': '祸害', '坤': '五鬼', '兑': '六煞',
    },
    '乾': {
      '乾': '伏位', '艮': '天医', '兑': '生气', '坤': '延年',
      '离': '绝命', '巽': '祸害', '震': '五鬼', '坎': '六煞',
    },
    '兑': {
      '兑': '伏位', '坤': '天医', '乾': '生气', '艮': '延年',
      '震': '绝命', '坎': '祸害', '离': '五鬼', '巽': '六煞',
    },
    '艮': {
      '艮': '伏位', '乾': '天医', '坤': '生气', '兑': '延年',
      '巽': '绝命', '离': '祸害', '坎': '五鬼', '震': '六煞',
    },
    '离': {
      '离': '伏位', '巽': '天医', '震': '生气', '坎': '延年',
      '乾': '绝命', '艮': '祸害', '兑': '五鬼', '坤': '六煞',
    },
  };

  static BazhaiResult getStar({
    required String houseGua,
    required String targetGua,
  }) {
    final star = table[houseGua]?[targetGua] ?? '未知';
    return BazhaiResult(
      star: star,
      isAuspicious: goodStars.contains(star),
    );
  }
}

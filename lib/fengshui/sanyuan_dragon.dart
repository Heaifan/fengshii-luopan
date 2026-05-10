enum SanyuanType {
  heaven,
  human,
  earth,
}

extension SanyuanTypeText on SanyuanType {
  String get label {
    switch (this) {
      case SanyuanType.heaven:
        return '天位';
      case SanyuanType.human:
        return '人位';
      case SanyuanType.earth:
        return '地位';
    }
  }

  String get shortLabel {
    switch (this) {
      case SanyuanType.heaven:
        return '天';
      case SanyuanType.human:
        return '人';
      case SanyuanType.earth:
        return '地';
    }
  }
}

class SanyuanDragonCalculator {
  SanyuanDragonCalculator._();

  static const Set<String> heaven = {
    '子', '午', '卯', '酉', '乾', '坤', '艮', '巽',
  };

  static const Set<String> human = {
    '癸', '丁', '乙', '辛', '亥', '巳', '寅', '申',
  };

  static const Set<String> earth = {
    '壬', '丙', '甲', '庚', '辰', '戌', '丑', '未',
  };

  static SanyuanType fromMountain(String mountain) {
    if (heaven.contains(mountain)) return SanyuanType.heaven;
    if (human.contains(mountain)) return SanyuanType.human;
    if (earth.contains(mountain)) return SanyuanType.earth;
    throw ArgumentError('Unknown mountain: $mountain');
  }
}

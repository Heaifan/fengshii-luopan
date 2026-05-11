class Mountain24Info {
  final String name;
  final String yuanLong;
  final String element;

  const Mountain24Info({
    required this.name,
    required this.yuanLong,
    required this.element,
  });

  String get fullLabel => '$name$yuanLong$element';
  String get mountainLabel => '$name山';
  String get yuanLongLabel => '$yuanLong元龙';
}

class Mountain24InfoTable {
  static const Map<String, Mountain24Info> table = {
    '子': Mountain24Info(name: '子', yuanLong: '天', element: '水'),
    '癸': Mountain24Info(name: '癸', yuanLong: '人', element: '水'),
    '丑': Mountain24Info(name: '丑', yuanLong: '地', element: '土'),
    '艮': Mountain24Info(name: '艮', yuanLong: '天', element: '土'),
    '寅': Mountain24Info(name: '寅', yuanLong: '人', element: '木'),
    '甲': Mountain24Info(name: '甲', yuanLong: '地', element: '木'),

    '卯': Mountain24Info(name: '卯', yuanLong: '天', element: '木'),
    '乙': Mountain24Info(name: '乙', yuanLong: '人', element: '木'),
    '辰': Mountain24Info(name: '辰', yuanLong: '地', element: '土'),
    '巽': Mountain24Info(name: '巽', yuanLong: '天', element: '木'),
    '巳': Mountain24Info(name: '巳', yuanLong: '人', element: '火'),
    '丙': Mountain24Info(name: '丙', yuanLong: '地', element: '火'),

    '午': Mountain24Info(name: '午', yuanLong: '天', element: '火'),
    '丁': Mountain24Info(name: '丁', yuanLong: '人', element: '火'),
    '未': Mountain24Info(name: '未', yuanLong: '地', element: '土'),
    '坤': Mountain24Info(name: '坤', yuanLong: '天', element: '土'),
    '申': Mountain24Info(name: '申', yuanLong: '人', element: '金'),
    '庚': Mountain24Info(name: '庚', yuanLong: '地', element: '金'),

    '酉': Mountain24Info(name: '酉', yuanLong: '天', element: '金'),
    '辛': Mountain24Info(name: '辛', yuanLong: '人', element: '金'),
    '戌': Mountain24Info(name: '戌', yuanLong: '地', element: '土'),
    '乾': Mountain24Info(name: '乾', yuanLong: '天', element: '金'),
    '亥': Mountain24Info(name: '亥', yuanLong: '人', element: '水'),
    '壬': Mountain24Info(name: '壬', yuanLong: '地', element: '水'),
  };

  static Mountain24Info fromMountain(String mountain) {
    return table[mountain] ??
        Mountain24Info(name: mountain, yuanLong: '未知', element: '未知');
  }
}

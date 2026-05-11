class MeasureTypeMeaning {
  static String humanMeaning(String type) {
    switch (type) {
      case 'door':
        return '门主纳气、出入';
      case 'balcony':
        return '阳台主采光、纳气';
      case 'window':
        return '窗主采光、通风、纳气';
      case 'livingRoom':
        return '客厅主活动、会客';
      case 'bed':
        return '床主睡眠、休养';
      case 'stove':
        return '灶主饮食、火气';
      case 'desk':
        return '桌主工作、学习';
      case 'altar':
        return '供主敬奉、精神';
      default:
        return '自定义测点用途';
    }
  }

  static String shortLabel(String type) {
    switch (type) {
      case 'door':
        return '门';
      case 'balcony':
        return '阳';
      case 'window':
        return '窗';
      case 'livingRoom':
        return '客';
      case 'bed':
        return '床';
      case 'stove':
        return '灶';
      case 'desk':
        return '桌';
      case 'altar':
        return '供';
      default:
        return '点';
    }
  }
}

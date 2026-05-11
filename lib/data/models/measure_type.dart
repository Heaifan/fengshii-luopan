class MeasureTypes {
  MeasureTypes._();

  static const door = 'door';
  static const balcony = 'balcony';
  static const window = 'window';
  static const livingRoom = 'livingRoom';
  static const bed = 'bed';
  static const stove = 'stove';
  static const desk = 'desk';
  static const altar = 'altar';
  static const other = 'other';

  static const all = [
    door,
    balcony,
    window,
    livingRoom,
    bed,
    stove,
    desk,
    altar,
    other,
  ];

  static String label(String type) {
    switch (type) {
      case door:
        return '门';
      case balcony:
        return '阳台';
      case window:
        return '窗';
      case livingRoom:
        return '客厅';
      case bed:
        return '床';
      case stove:
        return '灶';
      case desk:
        return '桌';
      case altar:
        return '供';
      default:
        return '其他';
    }
  }
}

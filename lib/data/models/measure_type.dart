class MeasureTypes {
  MeasureTypes._();

  // Original door (kept for backwards compatibility)
  static const door = 'door';
  // New specific door types
  static const entranceDoor = 'entranceDoor';
  static const roomDoor = 'roomDoor';

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
    entranceDoor,
    roomDoor,
    balcony,
    window,
    livingRoom,
    bed,
    stove,
    desk,
    altar,
    other,
  ];

  /// Check if a type is any kind of door.
  static bool isDoor(String type) {
    return type == door || type == entranceDoor || type == roomDoor;
  }

  static String label(String type) {
    switch (type) {
      case door:
        return '门';
      case entranceDoor:
        return '入户门';
      case roomDoor:
        return '房门';
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

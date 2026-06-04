/// Measurement guidance hints for each point type.
/// Principle: 空间中心 → 目标中心
class MeasureHints {
  static const _principle = '测量口径：站在空间中心，对准目标中心';

  /// General principle shown on camera page.
  static String get principle => _principle;

  /// Specific guidance for a given measure type.
  static String hintFor(String type) {
    switch (type) {
      case 'entranceDoor':
        return '请站在屋内中心或主要空间中心，面对入户门中心拍摄。\n此测点可作为门位起伏位的伏位来源。';
      case 'roomDoor':
        return '请站在当前房间中心，面对房门中心拍摄。\n用于判断房门位于本房间的哪个方位。';
      case 'balcony':
        return '请站在空间中心，面对阳台中心拍摄。';
      case 'window':
        return '请站在空间中心，面对窗或阳台中心拍摄。';
      case 'bed':
        return '请站在床位参考点，面对床头或床中心拍摄。';
      case 'stove':
        return '请站在灶位前方适当距离，面对灶中心拍摄。';
      case 'desk':
        return '请站在桌位参考点，面对桌面中心拍摄。';
      case 'altar':
        return '请站在供桌前适当距离，面对供桌中心拍摄。';
      case 'livingRoom':
        return '请站在客厅中心，对准主要活动区域方向拍摄。';
      default:
        return '请站在当前空间中心，对准目标中心拍摄。';
    }
  }

  /// Short label for the current measurement type context.
  static String shortContext(String type) {
    switch (type) {
      case 'entranceDoor':
        return '入户门测量';
      case 'roomDoor':
        return '房门测量';
      case 'balcony':
        return '阳台测量';
      case 'window':
        return '窗测量';
      case 'bed':
        return '床测量';
      case 'stove':
        return '灶测量';
      case 'desk':
        return '桌测量';
      case 'altar':
        return '供测量';
      case 'livingRoom':
        return '客厅测量';
      default:
        return '测点测量';
    }
  }
}

import 'mountain_24.dart';
import 'mountain_24_info.dart';
import 'compass_math.dart';

class DirectionSector {
  static String sector8FromHeading(double heading) {
    final h = normalizeDegree(heading);
    if (h >= 337.5 || h < 22.5) return 'north';
    if (h < 67.5) return 'northEast';
    if (h < 112.5) return 'east';
    if (h < 157.5) return 'southEast';
    if (h < 202.5) return 'south';
    if (h < 247.5) return 'southWest';
    if (h < 292.5) return 'west';
    return 'northWest';
  }

  static String sector8Label(String sector) {
    switch (sector) {
      case 'north':
        return '北宫';
      case 'northEast':
        return '东北宫';
      case 'east':
        return '东宫';
      case 'southEast':
        return '东南宫';
      case 'south':
        return '南宫';
      case 'southWest':
        return '西南宫';
      case 'west':
        return '西宫';
      case 'northWest':
        return '西北宫';
      default:
        return '未知';
    }
  }

  static String sectorToGua(String sector) {
    switch (sector) {
      case 'north':
        return '坎';
      case 'northEast':
        return '艮';
      case 'east':
        return '震';
      case 'southEast':
        return '巽';
      case 'south':
        return '离';
      case 'southWest':
        return '坤';
      case 'west':
        return '兑';
      case 'northWest':
        return '乾';
      default:
        return '';
    }
  }

  /// Short label like "北", "东北", "东".
  static String shortSector8Label(String sector) {
    switch (sector) {
      case 'north':
        return '北';
      case 'northEast':
        return '东北';
      case 'east':
        return '东';
      case 'southEast':
        return '东南';
      case 'south':
        return '南';
      case 'southWest':
        return '西南';
      case 'west':
        return '西';
      case 'northWest':
        return '西北';
      default:
        return '未知';
    }
  }

  /// Returns the trigram palace label, e.g. "坎宫", "离宫".
  static String sectorGuaPalaceLabel(String sector) {
    final gua = sectorToGua(sector);
    if (gua.isEmpty) return '未知';
    return '$gua宫';
  }

  /// Get the 24-shan mountain character for a heading (delegates to Mountain24Calculator).
  static String mountainFromHeading(double heading) {
    return Mountain24Calculator.fromDegree(heading).mountain;
  }

  static String mountainLabelFromHeading(double heading) {
    return '${mountainFromHeading(heading)}山';
  }

  static Mountain24Info mountainInfoFromHeading(double heading) {
    final mountain = mountainFromHeading(heading);
    return Mountain24InfoTable.fromMountain(mountain);
  }

  static Map<String, String> eightGridLabels() {
    return {
      'southEast': '东南',
      'south': '南',
      'southWest': '西南',
      'east': '东',
      'center': '中',
      'west': '西',
      'northEast': '东北',
      'north': '北',
      'northWest': '西北',
    };
  }

  static Map<String, String> eightGridSectors() {
    return {
      'southEast': 'southEast',
      'south': 'south',
      'southWest': 'southWest',
      'east': 'east',
      'center': 'center',
      'west': 'west',
      'northEast': 'northEast',
      'north': 'north',
      'northWest': 'northWest',
    };
  }
}

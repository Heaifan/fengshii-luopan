import 'package:flutter/material.dart';

class PalaceElementTheme {
  static String elementForSector(String sector) {
    switch (sector) {
      case 'east': // 震
      case 'southEast': // 巽
        return '木';
      case 'south': // 离
        return '火';
      case 'north': // 坎
        return '水';
      case 'west': // 兑
      case 'northWest': // 乾
        return '金';
      case 'northEast': // 艮
      case 'southWest': // 坤
      case 'center':
        return '土';
      default:
        return '土';
    }
  }

  static Color colorForElement(String element) {
    switch (element) {
      case '木':
        return const Color(0xFFDCEFE1); // 清新青绿
      case '火':
        return const Color(0xFFF8DDD8); // 淡粉橙
      case '土':
        return const Color(0xFFF3E8CC); // 浅米
      case '金':
        return const Color(0xFFF1EADF); // 淡灰金
      case '水':
        return const Color(0xFFDDEBF3); // 浅蓝灰
      default:
        return const Color(0xFFF7F0DD);
    }
  }
}

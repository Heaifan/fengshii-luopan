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
        return const Color(0xFFCFF2D6); // 清亮绿
      case '火':
        return const Color(0xFFFFD4CC); // 浅珊瑚红
      case '土':
        return const Color(0xFFFFE8A8); // 明亮黄
      case '金':
        return const Color(0xFFFFF5D6); // 浅金白
      case '水':
        return const Color(0xFFCFEAFF); // 明确蓝色
      default:
        return const Color(0xFFFFF8E8);
    }
  }
}

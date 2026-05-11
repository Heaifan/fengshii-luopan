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
        return const Color(0xFFE1F4E5); // 清新浅绿
      case '火':
        return const Color(0xFFFFE2DC); // 清透浅珊瑚
      case '土':
        return const Color(0xFFFFF0CC); // 明亮浅米黄
      case '金':
        return const Color(0xFFF7F1DF); // 清浅米金
      case '水':
        return const Color(0xFFE0F0FA); // 清浅天蓝
      default:
        return const Color(0xFFFFF8E8);
    }
  }
}

import 'package:flutter/material.dart';

class PalaceElementTheme {
  static String elementForSector(String sector) {
    switch (sector) {
      case 'east':      return '木';
      case 'southEast': return '木';
      case 'south':     return '火';
      case 'north':     return '水';
      case 'west':      return '金';
      case 'northWest': return '金';
      case 'northEast': return '土';
      case 'southWest': return '土';
      case 'center':    return '土';
      default:          return '土';
    }
  }

  static Color colorForElement(String element) {
    switch (element) {
      case '木': return const Color(0xFFDDEEDB); // 浅玉绿
      case '火': return const Color(0xFFF6DDD8); // 柔珊瑚
      case '土': return const Color(0xFFF2E8D7); // 米杏沙
      case '金': return const Color(0xFFEEF0EB); // 灰白银
      case '水': return const Color(0xFFDCEAF3); // 淡雾蓝
      default:   return const Color(0xFFFFF8E8);
    }
  }

  static Color accentForElement(String element) {
    switch (element) {
      case '木': return const Color(0xFF77A56F);
      case '火': return const Color(0xFFD98274);
      case '土': return const Color(0xFFC7A46C);
      case '金': return const Color(0xFFA9B0A3);
      case '水': return const Color(0xFF6F98B8);
      default:   return const Color(0xFF7A6243);
    }
  }

  static Color textForElement(String element) {
    switch (element) {
      case '木': return const Color(0xFF3F6B44);
      case '火': return const Color(0xFF8E4C43);
      case '土': return const Color(0xFF7A6243);
      case '金': return const Color(0xFF596056);
      case '水': return const Color(0xFF365A73);
      default:   return const Color(0xFF4A3A12);
    }
  }
}

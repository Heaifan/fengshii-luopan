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
      case '木': return const Color(0xFFE6F4E6); // 清亮木绿
      case '火': return const Color(0xFFFCE6E0); // 清透火珊瑚
      case '土': return const Color(0xFFF6EBD7); // 明亮土米杏
      case '金': return const Color(0xFFF4F5EF); // 清浅金白
      case '水': return const Color(0xFFE4F1FA); // 清透水蓝
      default:   return const Color(0xFFFFF8E8);
    }
  }
}

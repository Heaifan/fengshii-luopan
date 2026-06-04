import 'package:flutter/material.dart';

/// 国画正色版——五行宫格配色
/// 木：石绿 / 火：朱砂 / 土：藤黄 / 金：月白灰 / 水：石青
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

  // -- 国画正色：宫格底色 --
  static Color colorForElement(String element) {
    switch (element) {
      case '木': return const Color(0xFFE4F1E5); // 石绿
      case '火': return const Color(0xFFF9E1DA); // 朱砂
      case '土': return const Color(0xFFF8ECCC); // 藤黄
      case '金': return const Color(0xFFF0F0EC); // 月白灰
      case '水': return const Color(0xFFDFEBF7); // 石青
      default:   return const Color(0xFFF8ECCC);
    }
  }

  // -- 国画正色：宫格强调色 --
  static Color accentForElement(String element) {
    switch (element) {
      case '木': return const Color(0xFF2F8F57);
      case '火': return const Color(0xFFC53A2F);
      case '土': return const Color(0xFFC79A1B);
      case '金': return const Color(0xFF8F9189);
      case '水': return const Color(0xFF2F6FB3);
      default:   return const Color(0xFFC79A1B);
    }
  }

  // -- 国画正色：宫格深文字色 --
  static Color textForElement(String element) {
    switch (element) {
      case '木': return const Color(0xFF1F5B38);
      case '火': return const Color(0xFF7A251F);
      case '土': return const Color(0xFF7A5A12);
      case '金': return const Color(0xFF50524B);
      case '水': return const Color(0xFF214A77);
      default:   return const Color(0xFF7A5A12);
    }
  }
}

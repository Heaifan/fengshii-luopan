import 'package:flutter/material.dart';

/// 高亮五行色——九宫宫格配色
/// 木：草绿 / 火：橙红 / 土：藤黄 / 金：月灰 / 水：天蓝
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

  // -- 高亮五行色：宫格底色 --
  static const Color woodBg = Color(0xFFB9F28E);
  static const Color fireBg = Color(0xFFFFB0A8);
  static const Color earthBg = Color(0xFFFFE680);
  static const Color metalBg = Color(0xFFECECEC);
  static const Color waterBg = Color(0xFFA9D4FF);

  static Color colorForElement(String element) {
    switch (element) {
      case '木': return woodBg;
      case '火': return fireBg;
      case '土': return earthBg;
      case '金': return metalBg;
      case '水': return waterBg;
      default:   return earthBg;
    }
  }

  // -- 高亮五行色：强调色 --
  static const Color woodAccent = Color(0xFF4CAF1D);
  static const Color fireAccent = Color(0xFFE53935);
  static const Color earthAccent = Color(0xFFD4A000);
  static const Color metalAccent = Color(0xFF8C8C8C);
  static const Color waterAccent = Color(0xFF2F7FD9);

  static Color accentForElement(String element) {
    switch (element) {
      case '木': return woodAccent;
      case '火': return fireAccent;
      case '土': return earthAccent;
      case '金': return metalAccent;
      case '水': return waterAccent;
      default:   return earthAccent;
    }
  }

  // -- 高亮五行色：深文字色 --
  static const Color woodText = Color(0xFF1B4F10);
  static const Color fireText = Color(0xFF7A1C19);
  static const Color earthText = Color(0xFF6B5400);
  static const Color metalText = Color(0xFF424242);
  static const Color waterText = Color(0xFF124C82);

  static Color textForElement(String element) {
    switch (element) {
      case '木': return woodText;
      case '火': return fireText;
      case '土': return earthText;
      case '金': return metalText;
      case '水': return waterText;
      default:   return earthText;
    }
  }
}

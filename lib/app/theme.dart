import 'package:flutter/material.dart';

/// 国画正色版——全局 UI 色彩系统
class AppTheme {
  AppTheme._();

  // ===== 国画正色：页面环境色 =====
  static const Color pageBg = Color(0xFFF7F2E8);
  static const Color cardBg = Color(0xFFFBF8F1);
  static const Color appBarBg = Color(0xFFD8C8A8);
  static const Color cardBorder = Color(0xFFB8945A);
  static const Color selectedBorder = Color(0xFFA97222);
  static const Color divider = Color(0xFFDCCFB6);

  // ===== 国画正色：字体色 =====
  static const Color titleText = Color(0xFF2B2218);
  static const Color bodyText = Color(0xFF4C3D2B);
  static const Color subText = Color(0xFF6A5842);
  static const Color hintText = Color(0xFF8C7B68);
  static const Color inverseText = Color(0xFFFFF9F0);

  // ===== 国画正色：吉凶色 =====
  static const Color goodText = Color(0xFF2E7D43);
  static const Color badText = Color(0xFFB13A2D);
  static const Color neutralText = Color(0xFF8A6E42);
  static const Color pendingText = Color(0xFF8C7B68);

  // ===== 国画正色：测点标签色 =====
  static const Color pointTagBg = Color(0xFF5A4422);
  static const Color pointTagText = Color(0xFFFFF9F0);

  // ===== 国画正色：门图标色 =====
  static const Color entranceDoorIcon = Color(0xFF7A541D);
  static const Color roomDoorIcon = Color(0xFF6A4A1E);

  // ----- 旧字段别名（兼容） -----
  static const Color auspiciousColor = goodText;
  static const Color inauspiciousColor = badText;
  static const Color highlightColor = Color(0xFFC8922E);
  static const Color textPrimary = bodyText;
  static const Color textTitle = titleText;
  static const Color textLabel = subText;
  static const Color textSecondary = subText;
  static const Color textHint = hintText;
  static const Color borderColor = cardBorder;
}

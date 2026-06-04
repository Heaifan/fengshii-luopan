import 'package:flutter/material.dart';

/// 高亮版——全局 UI 色彩系统
class AppTheme {
  AppTheme._();

  // ===== 页面环境色 =====
  static const Color pageBg = Color(0xFFFAFAF7);
  static const Color cardBg = Color(0xFFFFFDF8);
  static const Color appBarBg = Color(0xFFE6DDC8);
  static const Color cardBorder = Color(0xFFB08A3C);
  static const Color selectedBorder = Color(0xFFC58A00);
  static const Color divider = Color(0xFFDCCFB6);

  // ===== 字体色 =====
  static const Color titleText = Color(0xFF2B2218);
  static const Color bodyText = Color(0xFF4C3D2B);
  static const Color subText = Color(0xFF6A5842);
  static const Color hintText = Color(0xFF8C7B68);
  static const Color inverseText = Color(0xFFFFF9F0);

  // ===== 吉凶色 =====
  static const Color goodText = Color(0xFF1E8E3E);
  static const Color badText = Color(0xFFC62828);
  static const Color neutralText = Color(0xFF8A6D3B);
  static const Color pendingText = Color(0xFF8C7B68);

  // ===== 测点标签色 =====
  static const Color pointTagBg = Color(0xFF5A4422);
  static const Color pointTagText = Color(0xFFFFF9F0);

  // ===== 门图标色 =====
  static const Color entranceDoorBg = Color(0xFFC62828);
  static const Color entranceDoorIcon = Color(0xFFFFFFFF);
  static const Color entranceDoorSelectedBorder = Color(0xFFD32F2F);

  static const Color roomDoorBg = Color(0xFF5A4422);
  static const Color roomDoorIcon = Color(0xFFFFFFFF);
  static const Color roomDoorSelectedBorder = Color(0xFFC58A00);

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

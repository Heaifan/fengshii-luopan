import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'luopan_disc_painter.dart';
import 'luopan_overlay_painter.dart';

/// 传统罗盘视觉偏移：盘面静态上方 = 南/午，规则层 0° = 北/子
const double luopanVisualOffset = 180.0;

/// Stack: rotating disc + fixed overlay. Handles layout sizing.
class LuopanDial extends StatelessWidget {
  final double heading;
  final String houseGua;

  const LuopanDial({
    super.key,
    required this.heading,
    required this.houseGua,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size =
            math.min(constraints.maxWidth, constraints.maxHeight);
        final scale = size / LuopanDiscPainter.baseSize;

        // discRotation: bring the mountain at the reading position to the top.
        // heading 0°=North, disc has South/午 at top(0°), so offset by 180°.
        final discRotationDeg = luopanVisualOffset - heading;
        final discRotation = discRotationDeg * math.pi / 180;

        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // --- Rotating disc ---
              Transform.rotate(
                angle: discRotation,
                child: CustomPaint(
                  size: Size(size, size),
                  painter: LuopanDiscPainter(
                    houseGua: houseGua,
                    scale: scale,
                  ),
                ),
              ),
              // --- Fixed overlay ---
              CustomPaint(
                size: Size(size, size),
                painter: LuopanFixedOverlayPainter(scale: scale),
              ),
            ],
          ),
        );
      },
    );
  }
}

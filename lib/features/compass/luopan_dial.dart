import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'luopan_disc_painter.dart';
import 'luopan_needle_painter.dart';
import 'luopan_overlay_painter.dart';

/// Visual offset: static disc has 午/South at top (0°).
/// Rule layer: 0° = North. Disc needs to rotate to bring the
/// correct mountain under the reading marker.
///
/// Verified mapping (manual mode):
///   heading=0°   → 子 at top  (子 at visual 180°)
///   heading=90°  → 卯 at top  (卯 at visual 270°)
///   heading=180° → 午 at top  (午 at visual 0°)
///   heading=270° → 酉 at top  (酉 at visual 90°)
///
/// Formula: discRotationDeg = -(heading + 180)
const double luopanVisualOffset = 180.0;

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

        // discRotation brings the heading-corresponding mountain to the
        // reading marker (top). Sign: Flutter Transform.rotate is CCW.
        final discRotationDeg = -(heading + luopanVisualOffset);
        final discRotation = discRotationDeg * math.pi / 180;

        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // ---- Layer 1: rotating disc ----
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
              // ---- Layer 2: rotating needle (follows disc, points to 午) ----
              Transform.rotate(
                angle: discRotation,
                child: CustomPaint(
                  size: Size(size, size),
                  painter: LuopanNeedlePainter(scale: scale),
                ),
              ),
              // ---- Layer 3: fixed crosshair + triangle ----
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

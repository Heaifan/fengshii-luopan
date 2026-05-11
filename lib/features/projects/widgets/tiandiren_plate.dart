import 'package:flutter/material.dart';
import '../../../data/models/compass_record.dart';
import '../painters/tiandiren_plate_painter.dart';

class TiandirenPlate extends StatelessWidget {
  final List<CompassRecord> records;
  final String houseGua;
  final CompassRecord? selectedRecord;
  final ValueChanged<CompassRecord> onRecordSelected;
  final ValueChanged<CompassRecord>? onPointLongPress;
  final ValueChanged<String>? onPalaceTap;
  final VoidCallback? onCenterTap;

  const TiandirenPlate({
    super.key,
    required this.records,
    required this.houseGua,
    required this.selectedRecord,
    required this.onRecordSelected,
    this.onPointLongPress,
    this.onPalaceTap,
    this.onCenterTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth;
        final center = Offset(size / 2, size / 2);
        final R = size / 2;
        final halfSide = R * 0.62;
        final cellSize = 2 * halfSide / 3;

        // Precompute palace rects
        const gridLayout = [
          ['northWest', 'north', 'northEast'],
          ['west', 'center', 'east'],
          ['southWest', 'south', 'southEast'],
        ];
        final palaceRects = <String, Rect>{};
        for (int row = 0; row < 3; row++) {
          for (int col = 0; col < 3; col++) {
            final sector = gridLayout[row][col];
            palaceRects[sector] = Rect.fromLTWH(
              center.dx - halfSide + col * cellSize,
              center.dy - halfSide + row * cellSize,
              cellSize,
              cellSize,
            );
          }
        }

        return SizedBox(
          width: size,
          height: size,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(size / 2),
            child: GestureDetector(
              onTapUp: (details) {
                final tap = details.localPosition;
                final painter = TiandirenPlatePainter(
                  records: records,
                  houseGua: houseGua,
                  selectedRecord: selectedRecord,
                );
                final positions = painter.anchorPositions(
                    Size(size, size), records);

                // 1) hit test points
                CompassRecord? best;
                double bestDist = 30;
                for (final entry in positions) {
                  final dist = (tap - entry.value).distance;
                  if (dist < bestDist) {
                    bestDist = dist;
                    best = entry.key;
                  }
                }
                if (best != null) {
                  onRecordSelected(best);
                  return;
                }

                // 2) hit test center
                if (palaceRects['center']!.contains(tap)) {
                  onCenterTap?.call();
                  return;
                }

                // 3) hit test palaces
                for (final entry in palaceRects.entries) {
                  if (entry.key == 'center') continue;
                  if (entry.value.contains(tap)) {
                    onPalaceTap?.call(entry.key);
                    return;
                  }
                }
              },
              onLongPressStart: (details) {
                if (onPointLongPress == null) return;
                final painter = TiandirenPlatePainter(
                  records: records,
                  houseGua: houseGua,
                  selectedRecord: selectedRecord,
                );
                final positions = painter.anchorPositions(
                    Size(size, size), records);
                final tap = details.localPosition;
                CompassRecord? best;
                double bestDist = 30;
                for (final entry in positions) {
                  final dist = (tap - entry.value).distance;
                  if (dist < bestDist) {
                    bestDist = dist;
                    best = entry.key;
                  }
                }
                if (best != null) {
                  onPointLongPress?.call(best);
                }
              },
              child: CustomPaint(
                painter: TiandirenPlatePainter(
                  records: records,
                  houseGua: houseGua,
                  selectedRecord: selectedRecord,
                ),
                size: Size(size, size),
              ),
            ),
          ),
        );
      },
    );
  }
}

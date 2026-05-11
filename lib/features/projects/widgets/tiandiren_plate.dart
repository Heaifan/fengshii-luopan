import 'package:flutter/material.dart';
import '../../../data/models/compass_record.dart';
import '../painters/tiandiren_plate_painter.dart';

class TiandirenPlate extends StatelessWidget {
  final List<CompassRecord> records;
  final String houseGua;
  final CompassRecord? selectedRecord;
  final ValueChanged<CompassRecord> onRecordSelected;

  const TiandirenPlate({
    super.key,
    required this.records,
    required this.houseGua,
    required this.selectedRecord,
    required this.onRecordSelected,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth;

        return SizedBox(
          width: size,
          height: size,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(size / 2),
            child: GestureDetector(
              onTapUp: (details) {
                final painter = TiandirenPlatePainter(
                  records: records,
                  houseGua: houseGua,
                  selectedRecord: selectedRecord,
                );
                final positions = painter.anchorPositions(
                    Size(size, size), records);

                final tap = details.localPosition;
                CompassRecord? best;
                double bestDist = 30; // hit radius
                for (final entry in positions) {
                  final dist = (tap - entry.value).distance;
                  if (dist < bestDist) {
                    bestDist = dist;
                    best = entry.key;
                  }
                }
                if (best != null) {
                  onRecordSelected(best);
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

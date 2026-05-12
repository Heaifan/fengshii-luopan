import 'package:flutter/material.dart';
import '../../../data/models/compass_record.dart';
import '../painters/tiandiren_vent_painter.dart';

class TiandirenVentWidget extends StatelessWidget {
  final List<CompassRecord> records;

  const TiandirenVentWidget({
    super.key,
    required this.records,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth;
        return SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: TiandirenVentPainter(records: records),
            size: Size(size, size),
          ),
        );
      },
    );
  }
}

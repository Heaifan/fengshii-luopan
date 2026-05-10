import 'dart:async';
import 'dart:math' as math;
import 'package:sensors_plus/sensors_plus.dart';

class TiltData {
  final double horizontalAngle;
  final double verticalAngle;

  const TiltData({
    required this.horizontalAngle,
    required this.verticalAngle,
  });
}

class TiltService {
  static const double _smoothFactor = 0.12;

  Stream<TiltData> get tiltStream {
    double? prevH;
    double? prevV;

    return accelerometerEventStream().map((event) {
      final rawH = math.atan2(event.x, event.z) * 180 / math.pi;
      final rawV = math.atan2(event.y, event.z) * 180 / math.pi;

      if (prevH == null) {
        prevH = rawH;
        prevV = rawV;
      } else {
        prevH = prevH! * (1 - _smoothFactor) + rawH * _smoothFactor;
        prevV = prevV! * (1 - _smoothFactor) + rawV * _smoothFactor;
      }

      return TiltData(horizontalAngle: prevH!, verticalAngle: prevV!);
    });
  }
}

import 'dart:async';
import 'dart:math' as math;
import 'package:sensors_plus/sensors_plus.dart';

class TiltData {
  final double horizontalAngle; // left-right tilt, degrees
  final double verticalAngle; // forward-back tilt, degrees

  const TiltData({
    required this.horizontalAngle,
    required this.verticalAngle,
  });
}

class TiltService {
  Stream<TiltData> get tiltStream {
    return accelerometerEventStream().map((event) {
      final x = event.x;
      final y = event.y;
      final z = event.z;

      // Phone held vertically: compute tilt from gravity vector
      // Horizontal (roll): tilt left(-)/right(+)
      final horizontal =
          math.atan2(x, z) * 180 / math.pi;

      // Vertical (pitch): tilt forward(+)/back(-)
      final vertical =
          math.atan2(y, z) * 180 / math.pi;

      return TiltData(
        horizontalAngle: horizontal,
        verticalAngle: vertical,
      );
    });
  }
}

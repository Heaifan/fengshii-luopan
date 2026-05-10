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
  static const double _smoothFactor = 0.15;
  static const double _deadZone = 0.2;
  static const Duration _throttle = Duration(milliseconds: 100);

  Stream<TiltData> get tiltStream {
    double? prevH;
    double? prevV;
    DateTime? lastEmit;

    return accelerometerEventStream().map((event) {
      final x = event.x;
      final y = event.y;
      final z = event.z;

      final rawH = math.atan2(x, z) * 180 / math.pi;
      final rawV = math.atan2(y, z) * 180 / math.pi;

      // Low-pass filter
      if (prevH == null) {
        prevH = rawH;
        prevV = rawV;
      } else {
        prevH = prevH! * (1 - _smoothFactor) + rawH * _smoothFactor;
        prevV = prevV! * (1 - _smoothFactor) + rawV * _smoothFactor;
      }

      return TiltData(horizontalAngle: prevH!, verticalAngle: prevV!);
    }).where((data) {
      // Dead zone: skip small changes
      if (prevH == null || prevV == null) return true;
      final dh = (data.horizontalAngle - prevH!).abs();
      final dv = (data.verticalAngle - prevV!).abs();
      if (dh < _deadZone && dv < _deadZone) return false;
      // Throttle
      final now = DateTime.now();
      if (lastEmit != null && now.difference(lastEmit!) < _throttle) {
        return false;
      }
      lastEmit = now;
      prevH = data.horizontalAngle;
      prevV = data.verticalAngle;
      return true;
    });
  }
}

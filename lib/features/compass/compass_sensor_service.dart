import 'dart:async';
import 'package:flutter_compass/flutter_compass.dart';

class CompassSensorService {
  const CompassSensorService();

  Stream<double?> get headingStream {
    final events = FlutterCompass.events;
    if (events == null) {
      return const Stream.empty();
    }
    return events.map((event) => event.heading);
  }
}

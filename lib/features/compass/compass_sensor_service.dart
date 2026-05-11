import 'dart:async';
import 'package:flutter_compass/flutter_compass.dart';

class CompassSensorReading {
  final double? heading;
  final double? accuracy;

  const CompassSensorReading({
    required this.heading,
    required this.accuracy,
  });
}

class CompassSensorService {
  const CompassSensorService();

  Stream<CompassSensorReading> get readingStream {
    final events = FlutterCompass.events;
    if (events == null) {
      return const Stream.empty();
    }

    return events.map(
      (event) => CompassSensorReading(
        heading: event.heading,
        accuracy: event.accuracy,
      ),
    );
  }
}

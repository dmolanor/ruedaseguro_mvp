// Accelerometer stream provider for crash detection demo.
//
// Reads from sensors_plus and computes G-force magnitude.
// On devices without a physical accelerometer (Windows desktop, most web),
// the stream emits nothing — the screen falls back to "Simulador" mode.

import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart';

class AccelerometerReading {
  const AccelerometerReading({
    required this.x,
    required this.y,
    required this.z,
    required this.gForce,
    required this.timestamp,
  });

  /// Raw accelerometer axes in m/s².
  final double x;
  final double y;
  final double z;

  /// Magnitude normalised to Earth gravity (1 G = 9.81 m/s²).
  /// At rest the phone reads ~1.0 G (gravity vector).
  final double gForce;

  final DateTime timestamp;
}

/// User-adjustable crash threshold in G-force (default 2.5 G).
/// Typical fall: 2–4 G; severe crash: 5–10 G.
class CrashThresholdNotifier extends Notifier<double> {
  @override
  double build() => 2.5;

  void update(double value) => state = value;
}

final crashThresholdProvider = NotifierProvider<CrashThresholdNotifier, double>(
  CrashThresholdNotifier.new,
);

/// Live accelerometer stream.  autoDispose stops the sensor when the screen
/// is not visible, saving battery.
final accelerometerProvider = StreamProvider.autoDispose<AccelerometerReading>((
  ref,
) {
  return accelerometerEventStream(
    samplingPeriod: SensorInterval.gameInterval, // ~20 ms / 50 Hz
  ).map((event) {
    final magnitude = sqrt(
      event.x * event.x + event.y * event.y + event.z * event.z,
    );
    return AccelerometerReading(
      x: event.x,
      y: event.y,
      z: event.z,
      gForce: magnitude / 9.81,
      timestamp: DateTime.now(),
    );
  });
});

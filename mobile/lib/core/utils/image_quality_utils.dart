import 'dart:io';
import 'dart:typed_data';

import 'package:ruedaseguro/core/constants/app_constants.dart';

class ImageQualityResult {
  final double sharpness;
  final bool isScreenPhoto;
  final int brightness;
  final bool passed;

  const ImageQualityResult({
    required this.sharpness,
    required this.isScreenPhoto,
    required this.brightness,
    required this.passed,
  });
}

class ImageQualityUtils {
  ImageQualityUtils._();

  /// Calculates image sharpness using Laplacian variance approximation.
  /// Higher values indicate sharper images.
  /// Full implementation requires image processing — this is a stub that
  /// will be backed by platform channel or native code in Sprint 1.
  static Future<double> calculateSharpness(File image) async {
    final bytes = await image.readAsBytes();
    // Simplified variance calculation on raw byte values
    // Real implementation will use Laplacian kernel convolution
    if (bytes.length < 100) return 0;
    final sample = bytes.sublist(0, (bytes.length * 0.1).toInt());
    final mean = sample.reduce((a, b) => a + b) / sample.length;
    final variance = sample
        .map((b) => (b - mean) * (b - mean))
        .reduce((a, b) => a + b) / sample.length;
    return variance;
  }

  /// Detects if the image is a photo of a screen (moiré patterns).
  /// Stub implementation — full FFT-based detection in Sprint 1.
  static Future<bool> isScreenPhoto(File image) async {
    // Placeholder: will use FFT to detect periodic moiré patterns
    return false;
  }

  /// Calculates average brightness of an image (0-255).
  static Future<int> calculateBrightness(Uint8List bytes) async {
    if (bytes.isEmpty) return 0;
    final sampleSize = (bytes.length * 0.05).toInt().clamp(100, 10000);
    final step = bytes.length ~/ sampleSize;
    var sum = 0;
    var count = 0;
    for (var i = 0; i < bytes.length; i += step) {
      sum += bytes[i];
      count++;
    }
    return count > 0 ? sum ~/ count : 0;
  }

  /// Validates image quality: sharpness, screen-photo detection, brightness.
  static Future<ImageQualityResult> validateImage(File image) async {
    final sharpness = await calculateSharpness(image);
    final screenPhoto = await isScreenPhoto(image);
    final bytes = await image.readAsBytes();
    final brightness = await calculateBrightness(bytes);

    final passed = sharpness >= AppConstants.sharpnessThreshold &&
        !screenPhoto &&
        brightness >= 40 &&
        brightness <= 250;

    return ImageQualityResult(
      sharpness: sharpness,
      isScreenPhoto: screenPhoto,
      brightness: brightness,
      passed: passed,
    );
  }
}

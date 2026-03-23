import 'dart:io';

import 'package:ruedaseguro/core/utils/image_quality_utils.dart';

class ImageQualityResult {
  final double sharpnessScore;
  final bool isSharp;
  final bool isScreenPhoto;
  final bool brightnessOk;
  final bool overallPass;
  final String? failureReason;

  const ImageQualityResult({
    required this.sharpnessScore,
    required this.isSharp,
    required this.isScreenPhoto,
    required this.brightnessOk,
    required this.overallPass,
    this.failureReason,
  });
}

class ImageValidator {
  ImageValidator._();

  static Future<ImageQualityResult> validate(File image) async {
    final result = await ImageQualityUtils.validateImage(image);

    final isSharp = result.passed || result.sharpness >= 100;
    final brightnessOk = result.brightness >= 40 && result.brightness <= 250;
    final isScreenPhoto = result.isScreenPhoto;

    String? failureReason;
    bool overallPass = true;

    if (isScreenPhoto) {
      failureReason = 'Parece una foto de una pantalla. Usa el documento original.';
      overallPass = false;
    } else if (!isSharp) {
      failureReason = 'La imagen está borrosa. Intenta con mejor enfoque.';
      overallPass = false;
    } else if (result.brightness < 40) {
      failureReason = 'La imagen está muy oscura. Busca mejor iluminación.';
      overallPass = false;
    } else if (result.brightness > 250) {
      failureReason = 'La imagen está sobreexpuesta. Evita la luz directa.';
      overallPass = false;
    }

    return ImageQualityResult(
      sharpnessScore: result.sharpness,
      isSharp: isSharp,
      isScreenPhoto: isScreenPhoto,
      brightnessOk: brightnessOk,
      overallPass: overallPass,
      failureReason: failureReason,
    );
  }
}

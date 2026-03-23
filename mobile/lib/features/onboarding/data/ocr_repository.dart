import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:ruedaseguro/features/onboarding/domain/ocr_result.dart';

class OcrRepository {
  OcrRepository._();
  static final instance = OcrRepository._();

  final TextRecognizer _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<OcrResult> extractText(File imageFile) async {
    final stopwatch = Stopwatch()..start();
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognized = await _recognizer.processImage(inputImage);
      stopwatch.stop();

      final rawText = recognized.text;
      final blocks = recognized.blocks;

      // Estimate overall confidence from block-level confidences
      double confidence = 0.0;
      if (blocks.isNotEmpty) {
        double total = 0;
        int count = 0;
        for (final block in blocks) {
          for (final line in block.lines) {
            for (final element in line.elements) {
              final conf = element.confidence;
              if (conf != null) {
                total += conf;
                count++;
              }
            }
          }
        }
        confidence = count > 0 ? total / count : 0.5;
      }

      return OcrResult(
        rawText: rawText,
        textBlocks: blocks,
        confidence: confidence,
        processingTimeMs: stopwatch.elapsedMilliseconds,
      );
    } on Exception {
      stopwatch.stop();
      return OcrResult.empty();
    }
  }

  void dispose() {
    _recognizer.close();
  }
}

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrResult {
  final String rawText;
  final List<TextBlock> textBlocks;
  final double confidence;
  final int processingTimeMs;

  const OcrResult({
    required this.rawText,
    required this.textBlocks,
    required this.confidence,
    required this.processingTimeMs,
  });

  bool get isEmpty => rawText.trim().isEmpty;

  factory OcrResult.empty() => const OcrResult(
        rawText: '',
        textBlocks: [],
        confidence: 0.0,
        processingTimeMs: 0,
      );
}

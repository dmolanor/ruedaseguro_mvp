import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';

import 'package:ruedaseguro/core/theme/colors.dart';
import 'package:ruedaseguro/core/theme/spacing.dart';
import 'package:ruedaseguro/core/theme/typography.dart';
import 'package:ruedaseguro/features/onboarding/data/ocr_repository.dart';
import 'package:ruedaseguro/features/onboarding/domain/certificado_circulacion_parser.dart';
import 'package:ruedaseguro/features/onboarding/domain/cross_validator.dart';
import 'package:ruedaseguro/features/onboarding/domain/image_validator.dart';
import 'package:ruedaseguro/features/onboarding/domain/onboarding_state.dart';
import 'package:ruedaseguro/shared/widgets/document_scanner.dart';

/// RS-074/076/080/082 — Step 2 of 2: Scan or upload the Certificado de Circulación.
///
/// Sources supported (RS-080):
///   - Camera (DocumentScanner)
///   - Gallery photo (ImagePicker)
///   - File upload: PDF, JPG, PNG (FilePicker)
///
/// When OCR confidence < 0.60, shows a retry guidance sheet (RS-082).
class CertificadoScanScreen extends ConsumerStatefulWidget {
  const CertificadoScanScreen({super.key});

  @override
  ConsumerState<CertificadoScanScreen> createState() =>
      _CertificadoScanScreenState();
}

class _CertificadoScanScreenState extends ConsumerState<CertificadoScanScreen> {
  bool _isProcessing = false;
  String? _errorMessage;
  Timer? _errorTimer;
  final _picker = ImagePicker();

  @override
  void dispose() {
    _errorTimer?.cancel();
    super.dispose();
  }

  void _showError(String message) {
    _errorTimer?.cancel();
    setState(() => _errorMessage = message);
    _errorTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => _errorMessage = null);
    });
  }

  // ------------------------------------------------------------------
  // Processing pipeline (shared by all capture sources)
  // ------------------------------------------------------------------

  Future<void> _processFile(File file) async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    // 1. Image quality check (skip for PDF — no pixel validation)
    final isPdf = file.path.toLowerCase().endsWith('.pdf');
    if (!isPdf) {
      final quality = await ImageValidator.validate(file);
      if (!quality.overallPass) {
        if (mounted) {
          setState(() => _isProcessing = false);
          _showError(quality.failureReason ??
              'La foto no es legible. Asegúrate de buena iluminación y sin reflejos.');
        }
        return;
      }
    }

    // 2. OCR
    final ocr = await OcrRepository.instance.extractText(file);

    if (ocr.isEmpty || ocr.confidence < 0.3) {
      if (mounted) {
        setState(() => _isProcessing = false);
        _showError(
            'No pudimos leer el certificado. Intenta con mejor iluminación o sube un archivo.');
      }
      return;
    }

    // 3. Parse
    final parsed =
        CertificadoCirculacionParser.parse(ocr.rawText, ocr.textBlocks);

    // 4. Cross-validate with cédula
    final cedulaData = ref.read(onboardingProvider).cedulaOcr;
    CrossValidationResult? crossResult;
    if (cedulaData != null) {
      crossResult = CrossValidator.validate(cedulaData, parsed);
    }

    // 5. Update state
    ref.read(onboardingProvider.notifier).updateCertificado(parsed, file);
    if (crossResult != null) {
      ref.read(onboardingProvider.notifier).confirmVehicle(
            plate: parsed.plate ?? '',
            brand: parsed.brand ?? '',
            model: parsed.model ?? '',
            year: parsed.year ?? DateTime.now().year,
            vehicleType: parsed.vehicleType,
            vehicleBodyType: parsed.vehicleBodyType,
            vehicleUse: (parsed.vehicleType?.contains('CARGA') ?? false)
                ? 'cargo'
                : 'particular',
            serialNiv: parsed.serialNiv,
            serialMotor: parsed.serialMotor,
            seats: parsed.seats,
            crossValidation: crossResult,
          );
    }

    if (!mounted) return;
    setState(() => _isProcessing = false);

    // 6. RS-082: Low confidence → show retry guidance sheet
    if (parsed.confidence < 0.60) {
      _showLowConfidenceSheet(parsed.confidence);
    } else {
      unawaited(context.push('/onboarding/certificado/confirm'));
    }
  }

  // ------------------------------------------------------------------
  // File sources (RS-080)
  // ------------------------------------------------------------------

  Future<void> _pickFromGallery() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (picked == null) return;
    await _processFile(File(picked.path));
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result == null || result.files.single.path == null) return;
    await _processFile(File(result.files.single.path!));
  }

  // ------------------------------------------------------------------
  // RS-082: Low-confidence retry guidance sheet
  // ------------------------------------------------------------------

  void _showLowConfidenceSheet(double confidence) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: RSColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(RSRadius.xl)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(RSSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: RSColors.warning, size: 48),
            const SizedBox(height: RSSpacing.md),
            Text(
              'Lectura poco clara',
              style: RSTypography.titleLarge
                  .copyWith(color: RSColors.primary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: RSSpacing.sm),
            Text(
              'El certificado se leyó con ${(confidence * 100).toStringAsFixed(0)}% de confianza. '
              'Puede haber errores. Te recomendamos volver a intentarlo.',
              style: RSTypography.bodyMedium
                  .copyWith(color: RSColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: RSSpacing.lg),
            // Tips
            _TipItem(
              icon: Icons.wb_sunny_outlined,
              text: 'Buena iluminación, sin sombras sobre el documento',
            ),
            _TipItem(
              icon: Icons.crop_free,
              text: 'El documento debe ocupar todo el recuadro',
            ),
            _TipItem(
              icon: Icons.do_not_disturb_on_outlined,
              text: 'Sin reflejos ni dobleces en el papel',
            ),
            _TipItem(
              icon: Icons.rotate_left,
              text: 'Asegúrate de que el texto esté derecho (no inclinado)',
            ),
            const SizedBox(height: RSSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      unawaited(
                          context.push('/onboarding/certificado/confirm'));
                    },
                    child: const Text('Continuar igual'),
                  ),
                ),
                const SizedBox(width: RSSpacing.md),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: RSColors.primary),
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Intentar de nuevo'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: RSSpacing.lg),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // Build
  // ------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        DocumentScanner(
          instruction:
              'Coloca el Certificado de Circulación dentro del recuadro\n'
              'Asegúrate de que el texto sea legible',
          onCapture: _processFile,
          onCancel: () => context.pop(),
        ),

        // Step indicator
        SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 72),
              child: _StepIndicator(
                currentStep: 2,
                totalSteps: 2,
                label: 'Certificado de Circulación',
              ),
            ),
          ),
        ),

        // RS-080: File upload options button (bottom overlay)
        if (!_isProcessing)
          Positioned(
            bottom: 200,
            left: RSSpacing.lg,
            right: RSSpacing.lg,
            child: _UploadOptions(
              onGallery: _pickFromGallery,
              onFile: _pickFile,
            ),
          ),

        // Processing overlay
        if (_isProcessing)
          Container(
            color: Colors.black54,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Shimmer.fromColors(
                    baseColor: Colors.white24,
                    highlightColor: Colors.white54,
                    child: const Icon(Icons.document_scanner,
                        color: Colors.white, size: 64),
                  ),
                  const SizedBox(height: RSSpacing.lg),
                  Text(
                    'Leyendo certificado...',
                    style:
                        RSTypography.titleMedium.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),

        // Error banner
        if (_errorMessage != null && !_isProcessing)
          Positioned(
            bottom: 180,
            left: RSSpacing.lg,
            right: RSSpacing.lg,
            child: GestureDetector(
              onTap: () => setState(() => _errorMessage = null),
              child: Container(
                padding: const EdgeInsets.all(RSSpacing.md),
                decoration: BoxDecoration(
                  color: RSColors.error,
                  borderRadius: BorderRadius.circular(RSRadius.md),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white),
                    const SizedBox(width: RSSpacing.sm),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: RSTypography.bodyMedium
                            .copyWith(color: Colors.white),
                      ),
                    ),
                    const Icon(Icons.close, color: Colors.white70, size: 18),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Local widgets

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({
    required this.currentStep,
    required this.totalSteps,
    required this.label,
  });

  final int currentStep;
  final int totalSteps;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: RSSpacing.md, vertical: RSSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(RSRadius.xl),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...List.generate(totalSteps, (i) {
            final active = i + 1 <= currentStep;
            return Container(
              width: active ? 24 : 8,
              height: 8,
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: active ? RSColors.accent : Colors.white38,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
          const SizedBox(width: 8),
          Text('$currentStep/$totalSteps — $label',
              style: RSTypography.caption.copyWith(color: Colors.white)),
        ],
      ),
    );
  }
}

/// RS-080: Two upload alternatives: gallery photo or file.
class _UploadOptions extends StatelessWidget {
  const _UploadOptions({
    required this.onGallery,
    required this.onFile,
  });

  final VoidCallback onGallery;
  final VoidCallback onFile;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _UploadChip(
          icon: Icons.photo_library_outlined,
          label: 'Galería',
          onTap: onGallery,
        ),
        const SizedBox(width: RSSpacing.md),
        _UploadChip(
          icon: Icons.upload_file_outlined,
          label: 'Subir archivo',
          onTap: onFile,
        ),
      ],
    );
  }
}

class _UploadChip extends StatelessWidget {
  const _UploadChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: RSSpacing.md, vertical: RSSpacing.sm),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(RSRadius.xl),
          border: Border.all(color: Colors.white30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 6),
            Text(label,
                style:
                    RSTypography.bodyMedium.copyWith(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

class _TipItem extends StatelessWidget {
  const _TipItem({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: RSColors.primary, size: 20),
          const SizedBox(width: RSSpacing.sm),
          Expanded(
            child: Text(text,
                style: RSTypography.bodyMedium
                    .copyWith(color: RSColors.textSecondary)),
          ),
        ],
      ),
    );
  }
}

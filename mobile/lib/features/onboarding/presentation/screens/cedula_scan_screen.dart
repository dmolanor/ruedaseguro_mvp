import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import 'package:ruedaseguro/core/theme/colors.dart';
import 'package:ruedaseguro/core/theme/spacing.dart';
import 'package:ruedaseguro/core/theme/typography.dart';
import 'package:ruedaseguro/features/onboarding/data/ocr_repository.dart';
import 'package:ruedaseguro/features/onboarding/domain/cedula_parser.dart';
import 'package:ruedaseguro/features/onboarding/domain/image_validator.dart';
import 'package:ruedaseguro/features/onboarding/domain/onboarding_state.dart';
import 'package:ruedaseguro/shared/widgets/document_scanner.dart';

class CedulaScanScreen extends ConsumerStatefulWidget {
  const CedulaScanScreen({super.key});

  @override
  ConsumerState<CedulaScanScreen> createState() => _CedulaScanScreenState();
}

class _CedulaScanScreenState extends ConsumerState<CedulaScanScreen> {
  bool _isProcessing = false;
  String? _errorMessage;
  Timer? _errorTimer;

  @override
  void dispose() {
    _errorTimer?.cancel();
    super.dispose();
  }

  void _showError(String message) {
    _errorTimer?.cancel();
    setState(() => _errorMessage = message);
    _errorTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _errorMessage = null);
    });
  }

  Future<void> _handleCapture(File file) async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    // 1. Image quality check
    final quality = await ImageValidator.validate(file);
    if (!quality.overallPass) {
      if (mounted) {
        setState(() => _isProcessing = false);
        _showError(quality.failureReason ??
            'La foto no es legible. Asegúrate de buena iluminación y sin reflejos.');
      }
      return;
    }

    // 2. OCR
    final ocr = await OcrRepository.instance.extractText(file);

    if (ocr.isEmpty || ocr.confidence < 0.3) {
      if (mounted) {
        setState(() => _isProcessing = false);
        _showError('No pudimos leer tu cédula. Intenta con mejor iluminación.');
      }
      return;
    }

    // 3. Parse
    final parsed = CedulaParser.parse(ocr.rawText, ocr.textBlocks);

    // 4. Save to onboarding state and navigate
    ref.read(onboardingProvider.notifier).updateCedula(parsed, file);

    if (mounted) {
      setState(() => _isProcessing = false);
      unawaited(context.push('/onboarding/cedula/confirm'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        DocumentScanner(
          instruction:
              'Coloca el frente de tu cédula dentro del recuadro\nBuena iluminación, sin reflejos, bordes completos',
          onCapture: _handleCapture,
          onCancel: () => context.go('/welcome'),
        ),

        // Progress indicator overlay
        SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 72),
              child: _StepIndicator(
                currentStep: 1,
                totalSteps: 4,
                label: 'Cédula de identidad',
              ),
            ),
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
                    'Leyendo documento...',
                    style: RSTypography.titleMedium.copyWith(color: Colors.white),
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

// Reusable scan step indicator — also used by carnet/vehicle screens
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
        horizontal: RSSpacing.md,
        vertical: RSSpacing.sm,
      ),
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
          Text(
            '$currentStep/$totalSteps — $label',
            style: RSTypography.caption.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

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
import 'package:ruedaseguro/features/onboarding/domain/carnet_parser.dart';
import 'package:ruedaseguro/features/onboarding/domain/cross_validator.dart';
import 'package:ruedaseguro/features/onboarding/domain/image_validator.dart';
import 'package:ruedaseguro/features/onboarding/domain/onboarding_state.dart';
import 'package:ruedaseguro/shared/widgets/document_scanner.dart';

class CarnetScanScreen extends ConsumerStatefulWidget {
  const CarnetScanScreen({super.key});

  @override
  ConsumerState<CarnetScanScreen> createState() => _CarnetScanScreenState();
}

class _CarnetScanScreenState extends ConsumerState<CarnetScanScreen> {
  bool _isProcessing = false;
  String? _errorMessage;

  Future<void> _handleCapture(File file) async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    // 1. Image quality check
    final quality = await ImageValidator.validate(file);
    if (!quality.overallPass) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _errorMessage = quality.failureReason ??
              'La foto no es legible. Asegúrate de buena iluminación y sin reflejos.';
        });
      }
      return;
    }

    // 2. OCR
    final ocr = await OcrRepository.instance.extractText(file);

    if (ocr.isEmpty || ocr.confidence < 0.3) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _errorMessage =
              'No pudimos leer el certificado. Intenta con mejor iluminación.';
        });
      }
      return;
    }

    // 3. Parse
    final parsed = CarnetParser.parse(ocr.rawText, ocr.textBlocks);

    // 4. Cross-validate with cédula data
    final cedulaData = ref.read(onboardingProvider).cedulaOcr;
    CrossValidationResult? crossResult;
    if (cedulaData != null) {
      crossResult = CrossValidator.validate(cedulaData, parsed);
    }

    // 5. Save and navigate
    ref.read(onboardingProvider.notifier).updateCarnet(parsed, file);
    if (crossResult != null) {
      ref.read(onboardingProvider.notifier).confirmVehicle(
        plate: parsed.plate ?? '',
        brand: parsed.brand ?? '',
        model: parsed.model ?? '',
        year: parsed.year ?? DateTime.now().year,
        color: parsed.color,
        vehicleUse: parsed.vehicleUse ?? 'particular',
        serialMotor: parsed.serialMotor,
        serialCarroceria: parsed.serialCarroceria,
        crossValidation: crossResult,
      );
    }

    if (mounted) {
      setState(() => _isProcessing = false);
      unawaited(context.push('/onboarding/vehicle/confirm'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        DocumentScanner(
          instruction: 'Coloca tu certificado de registro de vehículo dentro del recuadro',
          onCapture: _handleCapture,
          onCancel: () => context.pop(),
        ),

        SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 72),
              child: _StepIndicator(
                currentStep: 3,
                totalSteps: 4,
                label: 'Registro de vehículo',
              ),
            ),
          ),
        ),

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
                    child: const Icon(Icons.directions_car,
                        color: Colors.white, size: 64),
                  ),
                  const SizedBox(height: RSSpacing.lg),
                  Text(
                    'Leyendo certificado...',
                    style: RSTypography.titleMedium.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),

        if (_errorMessage != null && !_isProcessing)
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(RSSpacing.lg),
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
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

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

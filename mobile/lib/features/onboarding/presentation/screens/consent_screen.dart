import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ruedaseguro/core/data/mock_data.dart';
import 'package:ruedaseguro/core/theme/colors.dart';
import 'package:ruedaseguro/core/theme/spacing.dart';
import 'package:ruedaseguro/core/theme/typography.dart';
import 'package:ruedaseguro/features/onboarding/data/onboarding_repository.dart';
import 'package:ruedaseguro/features/onboarding/domain/onboarding_state.dart';
import 'package:ruedaseguro/shared/providers/auth_provider.dart';
import 'package:ruedaseguro/shared/widgets/rs_button.dart';
import 'package:ruedaseguro/shared/widgets/rs_consent_checkbox.dart';

class ConsentScreen extends ConsumerStatefulWidget {
  const ConsentScreen({super.key});

  @override
  ConsumerState<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends ConsumerState<ConsentScreen> {
  bool _isSaving = false;
  String? _errorMessage;

  // Resolve the plan chosen during onboarding from its stored code ('basica', etc.)
  InsurancePlan _resolvePlan(String? planCode) {
    if (planCode == null) return MockPlans.plus;
    return MockPlans.all.firstWhere(
      (p) => p.id == planCode || p.tier == planCode,
      orElse: () => MockPlans.plus,
    );
  }

  Future<void> _finalize() async {
    final data = ref.read(onboardingProvider);
    if (!data.allConsentsGiven) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    // Stamp consent timestamp
    ref
        .read(onboardingProvider.notifier)
        .updateConsents(
          rcv: data.consentRcv,
          veracidad: data.consentVeracidad,
          antifraude: data.consentAntifraude,
          privacidad: data.consentPrivacidad,
        );

    try {
      await OnboardingRepository.instance.saveOnboardingData(
        ref.read(onboardingProvider),
      );

      if (mounted) {
        final plan = _resolvePlan(ref.read(onboardingProvider).selectedPlan);
        // Navigate first so the router sees /policy/quote (not the onboarding
        // route) when markProfileCreated fires its redirect evaluation.
        context.go(
          '/policy/quote',
          extra: {'plan': plan, 'fromOnboarding': true},
        );
        ref.read(authProvider.notifier).markProfileCreated();
      }
    } catch (e, st) {
      debugPrint('❌ saveOnboardingData failed: $e');
      debugPrint('$st');
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage =
              'Error al guardar. Verifica tu conexión y vuelve a intentarlo.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(onboardingProvider);

    return Scaffold(
      backgroundColor: RSColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: RSColors.primary,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Términos y condiciones',
          style: RSTypography.titleLarge.copyWith(color: RSColors.primary),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(RSSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Para emitir tu póliza necesitamos tu consentimiento',
              style: RSTypography.bodyLarge.copyWith(
                color: RSColors.textSecondary,
              ),
            ),
            const SizedBox(height: RSSpacing.xl),

            Expanded(
              child: ListView(
                children: [
                  RSConsentCheckbox(
                    label: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Acepto las ',
                            style: RSTypography.bodyMedium,
                          ),
                          TextSpan(
                            text: 'Condiciones Generales del RCV',
                            style: RSTypography.bodyMedium.copyWith(
                              color: RSColors.primary,
                              decoration: TextDecoration.underline,
                              decorationColor: RSColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    value: data.consentRcv,
                    onChanged: (v) => ref
                        .read(onboardingProvider.notifier)
                        .updateConsents(rcv: v),
                  ),
                  const SizedBox(height: RSSpacing.lg),
                  RSConsentCheckbox(
                    label: Text(
                      'Declaro la veracidad de los datos suministrados',
                      style: RSTypography.bodyMedium,
                    ),
                    value: data.consentVeracidad,
                    onChanged: (v) => ref
                        .read(onboardingProvider.notifier)
                        .updateConsents(veracidad: v),
                  ),
                  const SizedBox(height: RSSpacing.lg),
                  RSConsentCheckbox(
                    label: Text(
                      'Autorizo la consulta y verificación antifraude (SAIME/INTT)',
                      style: RSTypography.bodyMedium,
                    ),
                    value: data.consentAntifraude,
                    onChanged: (v) => ref
                        .read(onboardingProvider.notifier)
                        .updateConsents(antifraude: v),
                  ),
                  const SizedBox(height: RSSpacing.lg),
                  RSConsentCheckbox(
                    label: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Acepto la ',
                            style: RSTypography.bodyMedium,
                          ),
                          TextSpan(
                            text: 'Política de Privacidad',
                            style: RSTypography.bodyMedium.copyWith(
                              color: RSColors.primary,
                              decoration: TextDecoration.underline,
                              decorationColor: RSColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    value: data.consentPrivacidad,
                    onChanged: (v) => ref
                        .read(onboardingProvider.notifier)
                        .updateConsents(privacidad: v),
                  ),
                ],
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: RSSpacing.md),
              Container(
                padding: const EdgeInsets.all(RSSpacing.md),
                decoration: BoxDecoration(
                  color: RSColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(RSRadius.md),
                  border: Border.all(color: RSColors.error),
                ),
                child: Text(
                  _errorMessage!,
                  style: RSTypography.bodyMedium.copyWith(
                    color: RSColors.error,
                  ),
                ),
              ),
            ],

            const SizedBox(height: RSSpacing.lg),
            RSButton(
              label: 'Finalizar registro',
              onPressed: data.allConsentsGiven && !_isSaving ? _finalize : null,
              isLoading: _isSaving,
            ),
            if (kDebugMode) ...[
              const SizedBox(height: RSSpacing.sm),
              Center(
                child: TextButton(
                  onPressed: () {
                    context.go(
                      '/policy/quote',
                      extra: {'plan': MockPlans.plus, 'fromOnboarding': true},
                    );
                    ref.read(authProvider.notifier).markProfileCreated();
                  },
                  child: const Text('[DEV] Omitir a Cotización'),
                ),
              ),
            ],
            const SizedBox(height: RSSpacing.xl),
          ],
        ),
      ),
    );
  }
}

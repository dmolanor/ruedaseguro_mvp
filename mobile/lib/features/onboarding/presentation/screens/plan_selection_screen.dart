import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ruedaseguro/core/data/mock_data.dart';
import 'package:ruedaseguro/core/theme/colors.dart';
import 'package:ruedaseguro/core/theme/spacing.dart';
import 'package:ruedaseguro/core/theme/typography.dart';
import 'package:ruedaseguro/features/onboarding/domain/onboarding_state.dart';
import 'package:ruedaseguro/shared/widgets/rs_button.dart';

class PlanSelectionScreen extends ConsumerWidget {
  const PlanSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plans = MockPlans.all;

    return Scaffold(
      backgroundColor: RSColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: RSSpacing.lg),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: RSSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Protege tu moto',
                    style: RSTypography.displayLarge.copyWith(
                      color: RSColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: RSSpacing.xs),
                  Text(
                    'Elige el plan que mejor se adapte a ti.',
                    style: RSTypography.bodyLarge.copyWith(
                      color: RSColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: RSSpacing.lg),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: RSSpacing.lg),
                itemCount: plans.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: RSSpacing.md),
                itemBuilder: (_, i) {
                  final plan = plans[i];
                  final nextPlan = i + 1 < plans.length ? plans[i + 1] : null;
                  return _OnboardingPlanCard(
                        plan: plan,
                        upsellPlan: nextPlan,
                        onSelect: () {
                          ref
                              .read(onboardingProvider.notifier)
                              .selectPlan(plan.id, plan.priceUsd);
                          context.push('/onboarding/cedula');
                        },
                      )
                      .animate(delay: (150 * i).ms)
                      .fadeIn(duration: 500.ms)
                      .slideY(begin: 0.05);
                },
              ),
            ),
            const SizedBox(height: RSSpacing.lg),
            if (kDebugMode)
              Center(
                child: TextButton(
                  onPressed: () {
                    ref
                        .read(onboardingProvider.notifier)
                        .selectPlan('plan_basico', 35);
                    context.push('/onboarding/cedula');
                  },
                  child: const Text('[DEV] Omitir (Plan Básico)'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Onboarding plan card ──────────────────────────────────────────
class _OnboardingPlanCard extends StatelessWidget {
  const _OnboardingPlanCard({
    required this.plan,
    required this.onSelect,
    this.upsellPlan,
  });

  final InsurancePlan plan;
  final InsurancePlan? upsellPlan;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: RSColors.surface,
        borderRadius: BorderRadius.circular(RSRadius.lg),
        border: Border.all(
          color: plan.isRecommended ? plan.accentColor : RSColors.border,
          width: plan.isRecommended ? 2 : 1,
        ),
        boxShadow: plan.isRecommended
            ? [
                BoxShadow(
                  color: plan.accentColor.withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(RSSpacing.md),
            decoration: BoxDecoration(
              color: plan.accentColor.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(RSRadius.lg - 1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: plan.accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(plan.icon, color: plan.accentColor, size: 24),
                ),
                const SizedBox(width: RSSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              plan.name,
                              overflow: TextOverflow.ellipsis,
                              style: RSTypography.titleLarge.copyWith(
                                color: RSColors.textPrimary,
                              ),
                            ),
                          ),
                          if (plan.isRecommended) ...[
                            const SizedBox(width: RSSpacing.sm),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: plan.accentColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Recomendado',
                                style: RSTypography.caption.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        plan.targetMarket,
                        style: RSTypography.caption.copyWith(
                          color: RSColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(RSSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Price
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${plan.priceUsd.toStringAsFixed(0)}',
                      style: RSTypography.displayLarge.copyWith(
                        color: plan.accentColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 32,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        'USD/año',
                        style: RSTypography.bodyMedium.copyWith(
                          color: RSColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: RSSpacing.md),
                const Divider(height: 1),
                const SizedBox(height: RSSpacing.md),
                // Coverages (max 4 shown in onboarding for brevity)
                ...plan.coverages
                    .take(4)
                    .map(
                      (c) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              color: plan.accentColor,
                              size: 18,
                            ),
                            const SizedBox(width: RSSpacing.sm),
                            Expanded(
                              child: Text(
                                c,
                                style: RSTypography.bodyMedium.copyWith(
                                  color: RSColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                const SizedBox(height: RSSpacing.md),
                RSButton(
                  label: 'Elegir ${plan.shortName}',
                  variant: plan.isRecommended
                      ? RSButtonVariant.primary
                      : RSButtonVariant.secondary,
                  onPressed: onSelect,
                ),
                // Upsell hint for non-top-tier plans
                if (upsellPlan != null) ...[
                  const SizedBox(height: RSSpacing.sm),
                  _UpsellHint(
                    currentPrice: plan.priceUsd,
                    nextPlan: upsellPlan!,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Upsell hint ──────────────────────────────────────────────────
class _UpsellHint extends StatelessWidget {
  const _UpsellHint({required this.currentPrice, required this.nextPlan});
  final double currentPrice;
  final InsurancePlan nextPlan;

  @override
  Widget build(BuildContext context) {
    final diff = (nextPlan.priceUsd - currentPrice).toStringAsFixed(0);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: RSSpacing.sm,
        vertical: RSSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: nextPlan.accentColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(RSRadius.sm),
        border: Border.all(
          color: nextPlan.accentColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.arrow_upward_rounded,
            color: nextPlan.accentColor,
            size: 14,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              'Por \$$diff más al año: ${nextPlan.name}',
              style: RSTypography.caption.copyWith(
                color: nextPlan.accentColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

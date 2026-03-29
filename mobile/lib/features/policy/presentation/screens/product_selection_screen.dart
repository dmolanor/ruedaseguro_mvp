import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import 'package:ruedaseguro/core/data/mock_data.dart';
import 'package:ruedaseguro/core/theme/colors.dart';
import 'package:ruedaseguro/core/theme/spacing.dart';
import 'package:ruedaseguro/core/theme/typography.dart';
import 'package:ruedaseguro/features/policy/providers/policy_providers.dart';
import 'package:ruedaseguro/shared/providers/auth_provider.dart';
import 'package:ruedaseguro/shared/providers/bcv_rate_provider.dart';
import 'package:ruedaseguro/shared/widgets/rs_button.dart';

class ProductSelectionScreen extends ConsumerWidget {
  const ProductSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final policyTypesAsync = ref.watch(policyTypesProvider);
    final bcvRateAsync = ref.watch(bcvRateProvider);
    final isDemoMode = ref.watch(authProvider).user == null;

    // Resolve plans: DB data → mapped InsurancePlans, fallback to mock
    final plans = policyTypesAsync.when(
      data: (types) => types.map((t) => t.toInsurancePlan()).toList(),
      error: (_, __) => MockPlans.all,
      loading: () => null, // null → show shimmer
    );

    final rateLabel = bcvRateAsync.when(
      data: (r) => '1 USD = ${r.rate.toStringAsFixed(2)} VES${r.stale ? ' (aprox.)' : ''}',
      error: (_, __) => '1 USD = ${MockPlans.exchangeRate.toStringAsFixed(2)} VES (aprox.)',
      loading: () => '...',
    );

    return Scaffold(
      backgroundColor: RSColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: RSColors.primary),
          onPressed: () => context.pop(),
        ),
        title: Text('Selecciona tu plan',
            style: RSTypography.titleLarge.copyWith(color: RSColors.primary)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: RSSpacing.lg),
            child: Column(
              children: [
                const SizedBox(height: RSSpacing.sm),
                if (!isDemoMode)
                  _VehicleBadge()
                else
                  Row(
                    children: [
                      const Icon(Icons.two_wheeler_rounded,
                          color: RSColors.textSecondary, size: 20),
                      const SizedBox(width: RSSpacing.sm),
                      Text(
                        '${MockVehicle.brand} ${MockVehicle.model} ${MockVehicle.year}',
                        style: RSTypography.bodyMedium
                            .copyWith(color: RSColors.textSecondary),
                      ),
                      const SizedBox(width: RSSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: RSColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(MockVehicle.plate,
                            style: RSTypography.mono.copyWith(
                              fontSize: 11,
                              color: RSColors.textSecondary,
                            )),
                      ),
                    ],
                  ),
                const SizedBox(height: RSSpacing.lg),
              ],
            ),
          ),
          Expanded(
            child: plans == null
                ? _PlanShimmer()
                : ListView.separated(
                    padding:
                        const EdgeInsets.symmetric(horizontal: RSSpacing.lg),
                    itemCount: plans.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: RSSpacing.md),
                    itemBuilder: (_, i) {
                      return _PlanCard(plan: plans[i])
                          .animate(delay: (150 * i).ms)
                          .fadeIn(duration: 500.ms)
                          .slideX(begin: 0.05);
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(RSSpacing.lg),
            child: Text(
              'Tasa BCV: $rateLabel',
              style: RSTypography.caption
                  .copyWith(color: RSColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Vehicle badge (real data) ─────────────────────────────────────
class _VehicleBadge extends ConsumerWidget {
  const _VehicleBadge();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO RS-056: fetch vehicle from DB using vehicleProvider
    return Row(
      children: [
        const Icon(Icons.two_wheeler_rounded,
            color: RSColors.textSecondary, size: 20),
        const SizedBox(width: RSSpacing.sm),
        Text(
          '${MockVehicle.brand} ${MockVehicle.model} ${MockVehicle.year}',
          style:
              RSTypography.bodyMedium.copyWith(color: RSColors.textSecondary),
        ),
      ],
    );
  }
}

// ─── Loading shimmer ───────────────────────────────────────────────
class _PlanShimmer extends StatelessWidget {
  const _PlanShimmer();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: RSSpacing.lg),
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(height: RSSpacing.md),
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: RSColors.surface,
        highlightColor: RSColors.surfaceVariant,
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            color: RSColors.surface,
            borderRadius: BorderRadius.circular(RSRadius.lg),
          ),
        ),
      ),
    );
  }
}

// ─── Plan card ─────────────────────────────────────────────────────
class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan});
  final InsurancePlan plan;

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
                          Text(plan.name,
                              style: RSTypography.titleLarge.copyWith(
                                  color: RSColors.textPrimary)),
                          if (plan.isRecommended) ...[
                            const SizedBox(width: RSSpacing.sm),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: plan.accentColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text('Recomendado',
                                  style: RSTypography.caption.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 10,
                                  )),
                            ),
                          ],
                        ],
                      ),
                      Text(plan.targetMarket,
                          style: RSTypography.caption
                              .copyWith(color: RSColors.textSecondary)),
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
                // Price row
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
                      child: Text('USD/año',
                          style: RSTypography.bodyMedium
                              .copyWith(color: RSColors.textSecondary)),
                    ),
                  ],
                ),
                const SizedBox(height: RSSpacing.md),
                const Divider(height: 1),
                const SizedBox(height: RSSpacing.md),
                // Coverages
                ...plan.coverages.map((c) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.check_circle_rounded,
                              color: plan.accentColor, size: 18),
                          const SizedBox(width: RSSpacing.sm),
                          Expanded(
                              child: Text(c,
                                  style: RSTypography.bodyMedium.copyWith(
                                      color: RSColors.textPrimary))),
                        ],
                      ),
                    )),
                // Excluded
                ...plan.excluded.map((c) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.cancel_rounded,
                              color: RSColors.textSecondary
                                  .withValues(alpha: 0.4),
                              size: 18),
                          const SizedBox(width: RSSpacing.sm),
                          Expanded(
                              child: Text(c,
                                  style: RSTypography.bodyMedium.copyWith(
                                      color: RSColors.textSecondary
                                          .withValues(alpha: 0.6)))),
                        ],
                      ),
                    )),
                const SizedBox(height: RSSpacing.md),
                RSButton(
                  label: 'Seleccionar ${plan.shortName}',
                  variant: plan.isRecommended
                      ? RSButtonVariant.primary
                      : RSButtonVariant.secondary,
                  onPressed: () =>
                      context.push('/policy/quote', extra: plan),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

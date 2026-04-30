import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ruedaseguro/core/theme/colors.dart';
import 'package:ruedaseguro/core/theme/spacing.dart';
import 'package:ruedaseguro/core/theme/typography.dart';
import 'package:ruedaseguro/core/data/mock_data.dart';
import 'package:ruedaseguro/core/services/supabase_service.dart';
import 'package:ruedaseguro/features/onboarding/domain/onboarding_state.dart';
import 'package:ruedaseguro/features/policy/providers/policy_providers.dart';
import 'package:ruedaseguro/shared/providers/auth_provider.dart';
import 'package:ruedaseguro/shared/providers/bcv_rate_provider.dart';
import 'package:ruedaseguro/shared/providers/profile_provider.dart';
import 'package:ruedaseguro/shared/widgets/rs_button.dart';
import 'package:ruedaseguro/shared/widgets/rs_card.dart';

class QuoteSummaryScreen extends ConsumerStatefulWidget {
  const QuoteSummaryScreen({super.key, this.plan, this.fromOnboarding = false});

  final InsurancePlan? plan;
  final bool fromOnboarding;

  @override
  ConsumerState<QuoteSummaryScreen> createState() => _QuoteSummaryScreenState();
}

class _QuoteSummaryScreenState extends ConsumerState<QuoteSummaryScreen> {
  bool _isMonthly = false;

  InsurancePlan get _plan => widget.plan ?? MockPlans.plus;

  double get _displayPrice =>
      _isMonthly ? _plan.priceMonthlyUsd : _plan.priceUsd;

  String get _periodLabel => _isMonthly ? '/mes' : '/año';

  @override
  Widget build(BuildContext context) {
    final bcvRate = ref
        .watch(bcvRateProvider)
        .when(
          data: (r) => r,
          error: (_, __) => BcvRate.fallback,
          loading: () => BcvRate.fallback,
        );
    final vesPrice = bcvRate.toVes(_displayPrice);
    final isStale = bcvRate.stale;

    // Next tier upsell — uses tier field, works for both mock and DB plans
    final policyTypes = ref.watch(policyTypesProvider).asData?.value;
    InsurancePlan? upsellPlan;
    if (policyTypes != null) {
      final nextTier = _plan.tier == 'basica'
          ? 'plus'
          : _plan.tier == 'plus'
          ? 'ampliada'
          : null;
      if (nextTier != null) {
        final match = policyTypes
            .where((t) => t.tier == nextTier)
            .map((t) => t.toInsurancePlan())
            .firstOrNull;
        upsellPlan = match;
      }
    } else {
      upsellPlan = _plan.tier == 'basica'
          ? MockPlans.plus
          : _plan.tier == 'plus'
          ? MockPlans.ampliada
          : null;
    }

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
          onPressed: () =>
              widget.fromOnboarding ? context.go('/home') : context.pop(),
        ),
        title: Text(
          widget.fromOnboarding
              ? 'Activa tu cobertura'
              : 'Resumen de cotización',
          style: RSTypography.titleLarge.copyWith(color: RSColors.primary),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(RSSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Plan header + frequency toggle (hidden during onboarding — annual only)
            _PlanHeaderCard(
              plan: _plan,
              displayPrice: _displayPrice,
              vesPrice: vesPrice,
              periodLabel: _periodLabel,
              isMonthly: _isMonthly,
              onToggle: (v) => setState(() => _isMonthly = v),
              showToggle: !widget.fromOnboarding,
            ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.05),

            const SizedBox(height: RSSpacing.lg),

            // Vehicle info
            _SectionTitle(
              title: 'Vehículo a asegurar',
            ).animate(delay: 100.ms).fadeIn(duration: 400.ms),
            const SizedBox(height: RSSpacing.sm),
            _VehicleCard(
              fromOnboarding: widget.fromOnboarding,
            ).animate(delay: 150.ms).fadeIn(duration: 400.ms),

            const SizedBox(height: RSSpacing.lg),

            // Holder info
            _SectionTitle(
              title: 'Titular de la póliza',
            ).animate(delay: 200.ms).fadeIn(duration: 400.ms),
            const SizedBox(height: RSSpacing.sm),
            _HolderCard(
              fromOnboarding: widget.fromOnboarding,
            ).animate(delay: 250.ms).fadeIn(duration: 400.ms),

            const SizedBox(height: RSSpacing.lg),

            // Coverage SA table
            _SectionTitle(
              title: 'Tabla de coberturas',
            ).animate(delay: 300.ms).fadeIn(duration: 400.ms),
            const SizedBox(height: RSSpacing.sm),
            _CoverageSATable(
              plan: _plan,
            ).animate(delay: 350.ms).fadeIn(duration: 400.ms),

            const SizedBox(height: RSSpacing.lg),

            // Price breakdown
            _SectionTitle(
              title: 'Desglose de pago',
            ).animate(delay: 400.ms).fadeIn(duration: 400.ms),
            const SizedBox(height: RSSpacing.sm),
            _PriceBreakdown(
              plan: _plan,
              displayPrice: _displayPrice,
              vesPrice: vesPrice,
              isMonthly: _isMonthly,
              bcvRate: bcvRate,
              isStale: isStale,
              carrierName: _plan.carrierName ?? MockPolicy.carrier,
            ).animate(delay: 450.ms).fadeIn(duration: 400.ms),

            // Upsell banner — not shown during onboarding (plan already chosen)
            if (upsellPlan != null && !widget.fromOnboarding) ...[
              const SizedBox(height: RSSpacing.lg),
              _UpsellBanner(upsellPlan: upsellPlan, currentPlan: _plan)
                  .animate(delay: 500.ms)
                  .fadeIn(duration: 400.ms)
                  .slideX(begin: 0.05),
            ],

            const SizedBox(height: RSSpacing.xl),

            // CTA
            RSButton(
                  label: widget.fromOnboarding
                      ? 'Proceder al pago'
                      : 'Solicitar emisión',
                  onPressed: () {
                    final extra = widget.fromOnboarding
                        ? {'plan': _plan, 'fromOnboarding': true}
                        : _plan as Object;
                    context.push('/payment/method', extra: extra);
                  },
                )
                .animate(delay: 550.ms)
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.2),

            const SizedBox(height: RSSpacing.md),

            Center(
              child: Text(
                'Al continuar aceptas las Condiciones Generales del RCV y\nautorizas la emisión ante ${_plan.carrierName ?? MockPolicy.carrier}.',
                style: RSTypography.caption.copyWith(
                  color: RSColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: RSSpacing.xl),
          ],
        ),
      ),
    );
  }
}

// ─── Section Title ────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: RSTypography.titleLarge.copyWith(color: RSColors.textPrimary),
    );
  }
}

// ─── Plan Header Card with Frequency Toggle ───────────────────────
class _PlanHeaderCard extends StatelessWidget {
  const _PlanHeaderCard({
    required this.plan,
    required this.displayPrice,
    required this.vesPrice,
    required this.periodLabel,
    required this.isMonthly,
    required this.onToggle,
    this.showToggle = true,
  });

  final InsurancePlan plan;
  final double displayPrice;
  final double vesPrice;
  final String periodLabel;
  final bool isMonthly;
  final ValueChanged<bool> onToggle;
  final bool showToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(RSSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [plan.accentColor, plan.accentColor.withValues(alpha: 0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(RSRadius.lg),
        boxShadow: [
          BoxShadow(
            color: plan.accentColor.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(plan.icon, color: Colors.white, size: 26),
              ),
              const SizedBox(width: RSSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.name,
                      style: RSTypography.titleLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      plan.targetMarket,
                      style: RSTypography.caption.copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              if (plan.isRecommended)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '★ Popular',
                    style: RSTypography.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          if (showToggle) ...[
            const SizedBox(height: RSSpacing.md),
            // Annual / monthly frequency toggle
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(RSRadius.md),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => onToggle(false),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: !isMonthly ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(RSRadius.md),
                        ),
                        child: Text(
                          'Anual',
                          style: RSTypography.bodyMedium.copyWith(
                            color: !isMonthly ? plan.accentColor : Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => onToggle(true),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isMonthly ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(RSRadius.md),
                        ),
                        child: Text(
                          'Mensual',
                          style: RSTypography.bodyMedium.copyWith(
                            color: isMonthly ? plan.accentColor : Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: RSSpacing.md),
          // Price display
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, anim) =>
                FadeTransition(opacity: anim, child: child),
            child: Column(
              key: ValueKey(isMonthly),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$ ${displayPrice.toStringAsFixed(isMonthly ? 2 : 0)}',
                      style: RSTypography.displayLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 38,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6, left: 4),
                      child: Text(
                        'USD$periodLabel',
                        style: RSTypography.bodyMedium.copyWith(
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  'Bs. ${vesPrice.toStringAsFixed(0)} $periodLabel',
                  style: RSTypography.bodyMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Vehicle Card ─────────────────────────────────────────────────
class _VehicleCard extends ConsumerWidget {
  const _VehicleCard({this.fromOnboarding = false});
  final bool fromOnboarding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (fromOnboarding) {
      final ob = ref.watch(onboardingProvider);
      return RSCard(
        child: Column(
          children: [
            _InfoRow(
              label: 'Marca / Modelo',
              value: '${ob.brand ?? '-'} ${ob.model ?? '-'}',
            ),
            const Divider(height: RSSpacing.lg),
            _InfoRow(label: 'Año', value: '${ob.year ?? '-'}'),
            const Divider(height: RSSpacing.lg),
            _InfoRow(label: 'Placa', value: ob.plate ?? '-', isMono: true),
            const Divider(height: RSSpacing.lg),
            _InfoRow(
              label: 'Uso',
              value: ob.vehicleUse == 'cargo' ? 'Carga' : 'Particular',
            ),
          ],
        ),
      );
    }

    final isDemoMode = ref.watch(authProvider).user == null;

    if (isDemoMode) {
      return RSCard(
        child: Column(
          children: [
            _InfoRow(
              label: 'Marca / Modelo',
              value: '${MockVehicle.brand} ${MockVehicle.model}',
            ),
            const Divider(height: RSSpacing.lg),
            _InfoRow(label: 'Año', value: '${MockVehicle.year}'),
            const Divider(height: RSSpacing.lg),
            _InfoRow(label: 'Placa', value: MockVehicle.plate, isMono: true),
            const Divider(height: RSSpacing.lg),
            _InfoRow(label: 'Color', value: MockVehicle.color),
            const Divider(height: RSSpacing.lg),
            _InfoRow(label: 'Uso', value: MockVehicle.use),
          ],
        ),
      );
    }

    return ref
        .watch(vehicleProvider)
        .when(
          loading: () => const RSCard(
            child: Padding(
              padding: EdgeInsets.all(RSSpacing.lg),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          ),
          error: (_, __) => const RSCard(
            child: Padding(
              padding: EdgeInsets.all(RSSpacing.md),
              child: Text('No se pudo cargar el vehículo'),
            ),
          ),
          data: (vehicle) {
            if (vehicle == null) {
              return const RSCard(
                child: Padding(
                  padding: EdgeInsets.all(RSSpacing.md),
                  child: Text('No tienes un vehículo registrado'),
                ),
              );
            }
            return RSCard(
              child: Column(
                children: [
                  _InfoRow(
                    label: 'Marca / Modelo',
                    value: '${vehicle.brand} ${vehicle.model}',
                  ),
                  const Divider(height: RSSpacing.lg),
                  _InfoRow(label: 'Año', value: '${vehicle.year}'),
                  const Divider(height: RSSpacing.lg),
                  _InfoRow(label: 'Placa', value: vehicle.plate, isMono: true),
                  const Divider(height: RSSpacing.lg),
                  _InfoRow(label: 'Color', value: vehicle.color),
                ],
              ),
            );
          },
        );
  }
}

// ─── Holder Card ──────────────────────────────────────────────────
class _HolderCard extends ConsumerWidget {
  const _HolderCard({this.fromOnboarding = false});
  final bool fromOnboarding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (fromOnboarding) {
      final ob = ref.watch(onboardingProvider);
      final phone = SupabaseService.auth.currentUser?.phone ?? '';
      return RSCard(
        child: Column(
          children: [
            _InfoRow(
              label: 'Nombre',
              value: '${ob.firstName ?? ''} ${ob.lastName ?? ''}'.trim(),
            ),
            const Divider(height: RSSpacing.lg),
            _InfoRow(
              label: 'Cédula',
              value: '${ob.idType ?? 'V'}-${ob.idNumber ?? ''}',
              isMono: true,
            ),
            const Divider(height: RSSpacing.lg),
            _InfoRow(label: 'Teléfono', value: phone),
          ],
        ),
      );
    }

    final isDemoMode = ref.watch(authProvider).user == null;

    if (isDemoMode) {
      return RSCard(
        child: Column(
          children: [
            _InfoRow(label: 'Nombre', value: MockRider.fullName),
            const Divider(height: RSSpacing.lg),
            _InfoRow(
              label: 'Cédula',
              value: '${MockRider.idType}-${MockRider.idNumber}',
              isMono: true,
            ),
            const Divider(height: RSSpacing.lg),
            _InfoRow(label: 'Teléfono', value: MockRider.phone),
          ],
        ),
      );
    }

    return ref
        .watch(profileProvider)
        .when(
          loading: () => const RSCard(
            child: Padding(
              padding: EdgeInsets.all(RSSpacing.lg),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          ),
          error: (_, __) => const RSCard(
            child: Padding(
              padding: EdgeInsets.all(RSSpacing.md),
              child: Text('No se pudo cargar el perfil'),
            ),
          ),
          data: (profile) {
            if (profile == null) {
              return const RSCard(
                child: Padding(
                  padding: EdgeInsets.all(RSSpacing.md),
                  child: Text('No tienes un perfil registrado'),
                ),
              );
            }
            return RSCard(
              child: Column(
                children: [
                  _InfoRow(label: 'Nombre', value: profile.fullName),
                  const Divider(height: RSSpacing.lg),
                  _InfoRow(
                    label: 'Cédula',
                    value: '${profile.idType}-${profile.idNumber}',
                    isMono: true,
                  ),
                  const Divider(height: RSSpacing.lg),
                  _InfoRow(label: 'Teléfono', value: profile.phone),
                ],
              ),
            );
          },
        );
  }
}

// ─── Coverage SA Table ────────────────────────────────────────────
class _CoverageSATable extends StatelessWidget {
  const _CoverageSATable({required this.plan});
  final InsurancePlan plan;

  @override
  Widget build(BuildContext context) {
    return RSCard(
      child: Column(
        children: [
          // Table header
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  'Cobertura',
                  style: RSTypography.caption.copyWith(
                    color: RSColors.textSecondary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Text(
                'Suma asegurada',
                style: RSTypography.caption.copyWith(
                  color: RSColors.textSecondary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: RSSpacing.sm),
          const Divider(height: 1),
          const SizedBox(height: RSSpacing.sm),
          ...plan.coverageItems.map((item) {
            final isIncluded = item.sa != 'No incluido';
            return Padding(
              padding: const EdgeInsets.only(bottom: RSSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    isIncluded
                        ? Icons.check_circle_rounded
                        : Icons.remove_circle_outline_rounded,
                    size: 16,
                    color: isIncluded
                        ? RSColors.success
                        : RSColors.textSecondary.withValues(alpha: 0.4),
                  ),
                  const SizedBox(width: RSSpacing.sm),
                  Expanded(
                    flex: 3,
                    child: Text(
                      item.name,
                      style: RSTypography.bodyMedium.copyWith(
                        color: isIncluded
                            ? RSColors.textPrimary
                            : RSColors.textSecondary.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  Text(
                    item.sa,
                    style: RSTypography.mono.copyWith(
                      fontSize: 12,
                      color: isIncluded
                          ? (item.sa == 'Incluida'
                                ? RSColors.success
                                : RSColors.primary)
                          : RSColors.textSecondary.withValues(alpha: 0.4),
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── Price Breakdown ──────────────────────────────────────────────
class _PriceBreakdown extends StatelessWidget {
  const _PriceBreakdown({
    required this.plan,
    required this.displayPrice,
    required this.vesPrice,
    required this.isMonthly,
    required this.bcvRate,
    required this.isStale,
    required this.carrierName,
  });

  final InsurancePlan plan;
  final double displayPrice;
  final double vesPrice;
  final bool isMonthly;
  final BcvRate bcvRate;
  final bool isStale;
  final String carrierName;

  @override
  Widget build(BuildContext context) {
    return RSCard(
      child: Column(
        children: [
          _InfoRow(
            label: isMonthly ? 'Prima mensual' : 'Prima anual',
            value: '\$ ${displayPrice.toStringAsFixed(2)} USD',
          ),
          const Divider(height: RSSpacing.lg),
          _InfoRow(
            label: 'En bolívares',
            value: 'Bs. ${vesPrice.toStringAsFixed(0)}',
            isMono: true,
          ),
          const Divider(height: RSSpacing.lg),
          _InfoRow(
            label: isStale ? 'Tasa BCV (aprox.)' : 'Tasa BCV',
            value: '1 USD = ${bcvRate.rate.toStringAsFixed(2)} VES',
            isStale: isStale,
          ),
          const Divider(height: RSSpacing.lg),
          _InfoRow(
            label: 'Vigencia',
            value: isMonthly ? '1 mes (30 días)' : '1 año (365 días)',
          ),
          const Divider(height: RSSpacing.lg),
          _InfoRow(label: 'Aseguradora', value: carrierName),
          const SizedBox(height: RSSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(RSSpacing.md),
            decoration: BoxDecoration(
              color: RSColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(RSRadius.md),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total a pagar',
                  style: RSTypography.titleMedium.copyWith(
                    color: RSColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '\$ ${displayPrice.toStringAsFixed(2)} USD',
                  style: RSTypography.displayMedium.copyWith(
                    color: RSColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Upsell Banner ────────────────────────────────────────────────
class _UpsellBanner extends StatelessWidget {
  const _UpsellBanner({required this.upsellPlan, required this.currentPlan});
  final InsurancePlan upsellPlan;
  final InsurancePlan currentPlan;

  @override
  Widget build(BuildContext context) {
    final extraItems =
        upsellPlan.coverageItems.length -
        currentPlan.coverageItems.where((c) => c.sa != 'No incluido').length;
    return GestureDetector(
      onTap: () => context.push('/policy/quote', extra: upsellPlan),
      child: Container(
        padding: const EdgeInsets.all(RSSpacing.md),
        decoration: BoxDecoration(
          color: upsellPlan.accentColor.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(RSRadius.md),
          border: Border.all(
            color: upsellPlan.accentColor.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: upsellPlan.accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                upsellPlan.icon,
                color: upsellPlan.accentColor,
                size: 20,
              ),
            ),
            const SizedBox(width: RSSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '¿Sabías que ${upsellPlan.name} incluye $extraItems coberturas más?',
                    style: RSTypography.bodyMedium.copyWith(
                      color: RSColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Solo \$ ${(upsellPlan.priceUsd - currentPlan.priceUsd).toStringAsFixed(0)} USD más al año',
                    style: RSTypography.caption.copyWith(
                      color: RSColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: upsellPlan.accentColor),
          ],
        ),
      ),
    );
  }
}

// ─── Info Row ─────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.isMono = false,
    this.isStale = false,
  });

  final String label;
  final String value;
  final bool isMono;
  final bool isStale;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              label,
              style: RSTypography.bodyMedium.copyWith(
                color: RSColors.textSecondary,
              ),
            ),
            if (isStale) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: RSColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'aprox.',
                  style: RSTypography.caption.copyWith(
                    color: RSColors.warning,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
        Text(
          value,
          style: isMono
              ? RSTypography.mono.copyWith(
                  fontSize: 14,
                  color: RSColors.textPrimary,
                )
              : RSTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isStale ? RSColors.warning : RSColors.textPrimary,
                ),
        ),
      ],
    );
  }
}

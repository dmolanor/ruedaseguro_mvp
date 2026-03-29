import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import 'package:ruedaseguro/core/theme/colors.dart';
import 'package:ruedaseguro/core/theme/spacing.dart';
import 'package:ruedaseguro/core/theme/typography.dart';
import 'package:ruedaseguro/core/data/mock_data.dart';
import 'package:ruedaseguro/shared/widgets/rs_button.dart';

class PaymentSuccessScreen extends StatelessWidget {
  const PaymentSuccessScreen({super.key, this.plan});

  final InsurancePlan? plan;

  @override
  Widget build(BuildContext context) {
    final selectedPlan = plan ?? MockPlans.plus;

    return Scaffold(
      backgroundColor: RSColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(RSSpacing.lg),
          child: Column(
            children: [
              const SizedBox(height: RSSpacing.xxl),

              // Success icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1B5E20), Color(0xFF43A047)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2E7D32).withValues(alpha: 0.35),
                      blurRadius: 28,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.shield_rounded,
                  color: Colors.white,
                  size: 58,
                ),
              )
                  .animate()
                  .scale(
                    begin: const Offset(0.4, 0.4),
                    duration: 700.ms,
                    curve: Curves.elasticOut,
                  )
                  .fadeIn(duration: 300.ms),

              const SizedBox(height: RSSpacing.xl),

              Text(
                '¡Tu póliza RCV\nestá activa!',
                style: RSTypography.displayLarge.copyWith(
                  color: RSColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              )
                  .animate(delay: 300.ms)
                  .fadeIn(duration: 500.ms)
                  .slideY(begin: 0.2),

              const SizedBox(height: RSSpacing.md),

              Text(
                'Tu cobertura comienza ahora mismo.\nPuedes circular con toda la tranquilidad.',
                style: RSTypography.bodyLarge.copyWith(
                  color: RSColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ).animate(delay: 400.ms).fadeIn(duration: 500.ms),

              const SizedBox(height: RSSpacing.xl),

              // Summary card
              _SummaryCard(plan: selectedPlan)
                  .animate(delay: 500.ms)
                  .fadeIn(duration: 500.ms)
                  .slideY(begin: 0.1),

              const SizedBox(height: RSSpacing.xl),

              // Primary action — download certificate
              _ActionButton(
                icon: Icons.download_rounded,
                label: 'Descargar Certificado RCV',
                color: RSColors.success,
                onTap: () {},
              ).animate(delay: 650.ms).fadeIn(duration: 400.ms).slideY(begin: 0.2),

              const SizedBox(height: RSSpacing.sm),

              // Share
              _ActionButton(
                icon: Icons.share_rounded,
                label: 'Enviar por WhatsApp / Correo',
                color: RSColors.primary,
                onTap: () {},
                outlined: true,
              ).animate(delay: 730.ms).fadeIn(duration: 400.ms),

              const SizedBox(height: RSSpacing.lg),

              const Divider(),

              const SizedBox(height: RSSpacing.md),

              RSButton(
                label: 'Ver mi póliza',
                onPressed: () => context.go('/home'),
              )
                  .animate(delay: 800.ms)
                  .fadeIn(duration: 400.ms),

              const SizedBox(height: RSSpacing.md),

              RSButton(
                label: 'Volver al inicio',
                variant: RSButtonVariant.secondary,
                onPressed: () => context.go('/home'),
              ).animate(delay: 880.ms).fadeIn(duration: 400.ms),

              const SizedBox(height: RSSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Summary Card ─────────────────────────────────────────────────
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.plan});
  final InsurancePlan plan;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(RSSpacing.lg),
      decoration: BoxDecoration(
        color: RSColors.surface,
        borderRadius: BorderRadius.circular(RSRadius.lg),
        border: Border.all(color: RSColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: RSColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.receipt_long_rounded,
                    color: RSColors.success, size: 22),
              ),
              const SizedBox(width: RSSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Referencia de pago',
                        style: RSTypography.caption
                            .copyWith(color: RSColors.textSecondary)),
                    Text(
                      MockPayments.history.first.reference,
                      style: RSTypography.mono.copyWith(
                        fontWeight: FontWeight.w700,
                        color: RSColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: RSColors.success,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '✓ Activa',
                  style: RSTypography.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: RSSpacing.xl),
          _Row(label: 'Plan', value: plan.name),
          const SizedBox(height: RSSpacing.sm),
          _Row(
            label: 'Prima',
            value: '\$ ${plan.priceUsd.toStringAsFixed(2)} USD / año',
          ),
          const SizedBox(height: RSSpacing.sm),
          _Row(label: 'Método', value: 'Pago Móvil'),
          const SizedBox(height: RSSpacing.sm),
          _Row(label: 'Fecha de emisión', value: MockPolicy.issueDate),
          const SizedBox(height: RSSpacing.sm),
          _Row(
            label: 'Vigencia',
            value: '${MockPolicy.issueDate} – ${MockPolicy.expiryDate}',
          ),
          const SizedBox(height: RSSpacing.sm),
          _Row(label: 'Nº Póliza', value: MockPolicy.number),
        ],
      ),
    );
  }
}

// ─── Action Button (Download / Share) ────────────────────────────
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.outlined = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
            vertical: RSSpacing.md, horizontal: RSSpacing.lg),
        decoration: BoxDecoration(
          color: outlined ? Colors.transparent : color,
          borderRadius: BorderRadius.circular(RSRadius.md),
          border: Border.all(
            color: color,
            width: outlined ? 1.5 : 0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: outlined ? color : Colors.white, size: 20),
            const SizedBox(width: RSSpacing.sm),
            Text(
              label,
              style: RSTypography.titleMedium.copyWith(
                color: outlined ? color : Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: RSTypography.bodyMedium
                .copyWith(color: RSColors.textSecondary)),
        Flexible(
          child: Text(
            value,
            style: RSTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: RSColors.textPrimary,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

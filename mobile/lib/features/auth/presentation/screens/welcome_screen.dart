import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import 'package:ruedaseguro/core/theme/colors.dart';
import 'package:ruedaseguro/core/theme/spacing.dart';
import 'package:ruedaseguro/core/theme/typography.dart';
import 'package:ruedaseguro/shared/widgets/rs_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RSColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: RSSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),

              // Brand mark
              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: RSColors.primary,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.shield_rounded,
                    color: Colors.white,
                    size: 56,
                  ),
                )
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .scale(begin: const Offset(0.8, 0.8)),
              ),
              const SizedBox(height: RSSpacing.xl),

              // Headline
              Text(
                'Asegura tu vehículo\nen minutos',
                textAlign: TextAlign.center,
                style: RSTypography.displayLarge.copyWith(
                  color: RSColors.primary,
                ),
              )
                  .animate(delay: 200.ms)
                  .fadeIn(duration: 500.ms)
                  .slideY(begin: 0.2, end: 0),

              const SizedBox(height: RSSpacing.md),

              Text(
                'Si te caes, no estás solo.',
                textAlign: TextAlign.center,
                style: RSTypography.titleMedium.copyWith(
                  color: RSColors.textSecondary,
                ),
              )
                  .animate(delay: 350.ms)
                  .fadeIn(duration: 500.ms),

              const Spacer(flex: 2),

              // Feature highlights
              _FeatureRow(
                icon: Icons.flash_on_rounded,
                text: 'Registro en 5 minutos con tu cédula',
              ).animate(delay: 500.ms).fadeIn(duration: 400.ms).slideX(begin: -0.1),
              const SizedBox(height: RSSpacing.md),
              _FeatureRow(
                icon: Icons.security_rounded,
                text: 'RCV aprobado por SUDEASEG',
              ).animate(delay: 600.ms).fadeIn(duration: 400.ms).slideX(begin: -0.1),
              const SizedBox(height: RSSpacing.md),
              _FeatureRow(
                icon: Icons.payments_rounded,
                text: 'Paga en bolívares o dólares',
              ).animate(delay: 700.ms).fadeIn(duration: 400.ms).slideX(begin: -0.1),

              const Spacer(flex: 1),

              // CTAs
              RSButton(
                label: 'Crear cuenta',
                onPressed: () => context.push('/login'),
              ).animate(delay: 800.ms).fadeIn(duration: 400.ms).slideY(begin: 0.2),

              const SizedBox(height: RSSpacing.md),

              Center(
                child: TextButton(
                  onPressed: () => context.push('/login'),
                  child: Text(
                    'Ya tengo cuenta — Ingresar',
                    style: RSTypography.bodyMedium.copyWith(
                      color: RSColors.primary,
                      decoration: TextDecoration.underline,
                      decorationColor: RSColors.primary,
                    ),
                  ),
                ),
              ).animate(delay: 900.ms).fadeIn(duration: 400.ms),

              const SizedBox(height: RSSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: RSColors.accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: RSColors.accent, size: 22),
        ),
        const SizedBox(width: RSSpacing.md),
        Expanded(
          child: Text(
            text,
            style: RSTypography.bodyLarge.copyWith(color: RSColors.textPrimary),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ruedaseguro/core/theme/colors.dart';
import 'package:ruedaseguro/core/theme/spacing.dart';
import 'package:ruedaseguro/core/theme/typography.dart';
import 'package:ruedaseguro/features/onboarding/domain/onboarding_state.dart';

/// Shown when the cross-validation between the user's cédula and the
/// certificado de circulación detects an ownership mismatch.
///
/// Presents two clear paths:
///  - Path A "Soy el dueño" → the mismatch is a document error; continue to address.
///  - Path B "Soy conductor habitual" → the vehicle belongs to someone else;
///    scan the owner's cédula before continuing.
///
/// RS-090: Replaces the simple "legal rep" checkbox on CertificadoConfirmScreen.
class PropertyValidationScreen extends ConsumerWidget {
  const PropertyValidationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(onboardingProvider);
    final ownerName = data.certificadoOcr?.ownerName ?? '';

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
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: RSSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: RSSpacing.md),
              // Warning icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: RSColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.info_outline_rounded,
                  color: RSColors.warning,
                  size: 30,
                ),
              ),
              const SizedBox(height: RSSpacing.md),
              Text(
                'La moto está a nombre\nde otra persona',
                style: RSTypography.displayLarge.copyWith(
                  color: RSColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: RSSpacing.sm),
              if (ownerName.isNotEmpty)
                Text(
                  'El certificado indica: $ownerName',
                  style: RSTypography.bodyMedium.copyWith(
                    color: RSColors.textSecondary,
                  ),
                )
              else
                Text(
                  'El nombre del propietario no coincide con tu cédula.',
                  style: RSTypography.bodyMedium.copyWith(
                    color: RSColors.textSecondary,
                  ),
                ),
              const SizedBox(height: RSSpacing.xl),
              Text(
                '¿Cuál es tu relación con este vehículo?',
                style: RSTypography.titleMedium.copyWith(
                  color: RSColors.textPrimary,
                ),
              ),
              const SizedBox(height: RSSpacing.md),
              // Path A — Owner
              _ChoiceCard(
                    icon: Icons.key_rounded,
                    iconColor: RSColors.primary,
                    title: 'Soy el dueño',
                    subtitle: 'El certificado puede tener un error de datos.',
                    onTap: () {
                      ref.read(onboardingProvider.notifier).setAsOwner();
                      context.push('/onboarding/address');
                    },
                  )
                  .animate(delay: 100.ms)
                  .fadeIn(duration: 400.ms)
                  .slideX(begin: 0.05),
              const SizedBox(height: RSSpacing.md),
              // Path B — Habitual driver
              _ChoiceCard(
                icon: Icons.directions_bike_rounded,
                iconColor: RSColors.accent,
                title: 'Soy conductor habitual',
                subtitle:
                    'La moto pertenece a otra persona. Necesitaremos su cédula.',
                onTap: () => _confirmHabitualDriver(context),
              ).animate(delay: 200.ms).fadeIn(duration: 400.ms).slideX(begin: 0.05),
              if (kDebugMode) ...[
                const SizedBox(height: RSSpacing.xl),
                Center(
                  child: TextButton(
                    onPressed: () => context.push('/onboarding/address'),
                    child: const Text('[DEV] Omitir a Dirección'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _confirmHabitualDriver(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _HabitualDriverSheet(),
    );
  }
}

// ─── Bottom sheet explaining conductor habitual ────────────────────
class _HabitualDriverSheet extends StatelessWidget {
  const _HabitualDriverSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(RSSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Qué significa esto para tu póliza?',
              style: RSTypography.titleLarge.copyWith(
                color: RSColors.textPrimary,
              ),
            ),
            const SizedBox(height: RSSpacing.md),
            _BulletRow(
              icon: Icons.shield_rounded,
              color: RSColors.primary,
              text:
                  'La cobertura RCV (Responsabilidad Civil Vehicular) quedará a nombre del dueño de la moto.',
            ),
            const SizedBox(height: RSSpacing.sm),
            _BulletRow(
              icon: Icons.medical_services_rounded,
              color: RSColors.accent,
              text:
                  'La cobertura de accidentes personales es para ti como conductor habitual.',
            ),
            const SizedBox(height: RSSpacing.xl),
            Text(
              'Para continuar, necesitamos escanear la cédula del dueño de la moto.',
              style: RSTypography.bodyMedium.copyWith(
                color: RSColors.textSecondary,
              ),
            ),
            const SizedBox(height: RSSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.document_scanner_rounded),
                label: const Text('Escanear cédula del dueño'),
                onPressed: () {
                  Navigator.of(context).pop();
                  context.push('/onboarding/cedula?ownerMode=true');
                },
              ),
            ),
            const SizedBox(height: RSSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Choice card ──────────────────────────────────────────────────
class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: RSColors.surface,
      borderRadius: BorderRadius.circular(RSRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(RSRadius.lg),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(RSSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(RSRadius.lg),
            border: Border.all(color: RSColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              const SizedBox(width: RSSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: RSTypography.titleMedium.copyWith(
                        color: RSColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: RSTypography.caption.copyWith(
                        color: RSColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: RSColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Bullet row ──────────────────────────────────────────────────
class _BulletRow extends StatelessWidget {
  const _BulletRow({
    required this.icon,
    required this.color,
    required this.text,
  });
  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: RSSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: RSTypography.bodyMedium.copyWith(
              color: RSColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

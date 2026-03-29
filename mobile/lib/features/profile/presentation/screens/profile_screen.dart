import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ruedaseguro/core/theme/colors.dart';
import 'package:ruedaseguro/core/theme/spacing.dart';
import 'package:ruedaseguro/core/theme/typography.dart';
import 'package:ruedaseguro/core/data/mock_data.dart';
import 'package:ruedaseguro/shared/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(RSSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: RSSpacing.sm),

            // Avatar + name header
            _ProfileHeader()
                .animate()
                .fadeIn(duration: 500.ms)
                .slideY(begin: -0.05),

            const SizedBox(height: RSSpacing.lg),

            // Active policy card
            _ActivePolicySummary()
                .animate(delay: 150.ms)
                .fadeIn(duration: 400.ms),

            const SizedBox(height: RSSpacing.lg),

            // Personal info
            _SectionHeader(title: 'Datos personales'),
            const SizedBox(height: RSSpacing.sm),
            _InfoSection(
              items: [
                _InfoItem(Icons.person_rounded, 'Nombre', MockRider.fullName),
                _InfoItem(Icons.badge_rounded, 'Cédula',
                    '${MockRider.idType}-${MockRider.idNumber}'),
                _InfoItem(Icons.phone_rounded, 'Teléfono', MockRider.phone),
                _InfoItem(Icons.cake_rounded, 'Nacimiento',
                    '${MockRider.dateOfBirth} (${MockRider.age} años)'),
                _InfoItem(Icons.location_on_rounded, 'Ciudad',
                    '${MockRider.city}, ${MockRider.state}'),
              ],
            ).animate(delay: 200.ms).fadeIn(duration: 400.ms),

            const SizedBox(height: RSSpacing.lg),

            // Vehicle info
            _SectionHeader(title: 'Mi vehículo'),
            const SizedBox(height: RSSpacing.sm),
            _InfoSection(
              items: [
                _InfoItem(Icons.two_wheeler_rounded, 'Marca / Modelo',
                    '${MockVehicle.brand} ${MockVehicle.model}'),
                _InfoItem(
                    Icons.calendar_today_rounded, 'Año', '${MockVehicle.year}'),
                _InfoItem(Icons.pin_rounded, 'Placa', MockVehicle.plate),
                _InfoItem(Icons.color_lens_rounded, 'Color', MockVehicle.color),
                _InfoItem(Icons.confirmation_number_rounded, 'N° Motor',
                    MockVehicle.serialMotor),
              ],
            ).animate(delay: 300.ms).fadeIn(duration: 400.ms),

            const SizedBox(height: RSSpacing.lg),

            // Emergency contact
            _SectionHeader(title: 'Contacto de emergencia'),
            const SizedBox(height: RSSpacing.sm),
            _InfoSection(
              items: [
                _InfoItem(Icons.people_rounded, 'Nombre',
                    MockRider.emergencyContact),
                _InfoItem(Icons.phone_rounded, 'Teléfono', MockRider.emergencyPhone),
                _InfoItem(Icons.family_restroom_rounded, 'Relación',
                    MockRider.emergencyRelation),
              ],
            ).animate(delay: 400.ms).fadeIn(duration: 400.ms),

            const SizedBox(height: RSSpacing.lg),

            // Payment history
            _SectionHeader(title: 'Historial de pagos'),
            const SizedBox(height: RSSpacing.sm),
            _PaymentHistory()
                .animate(delay: 500.ms)
                .fadeIn(duration: 400.ms),

            const SizedBox(height: RSSpacing.lg),

            // Settings
            _SectionHeader(title: 'Configuración'),
            const SizedBox(height: RSSpacing.sm),
            _SettingsSection()
                .animate(delay: 600.ms)
                .fadeIn(duration: 400.ms),

            const SizedBox(height: RSSpacing.xl),

            // Sign out
            _SignOutButton(ref: ref)
                .animate(delay: 700.ms)
                .fadeIn(duration: 400.ms),

            const SizedBox(height: RSSpacing.md),

            Center(
              child: Text(
                'RuedaSeguro v1.0.0 · SUDEASEG Certificado',
                style: RSTypography.caption
                    .copyWith(color: RSColors.textSecondary),
              ),
            ),

            const SizedBox(height: RSSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

// ─── Profile Header ──────────────────────────────────────────────
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Stack(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [RSColors.primary, RSColors.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: RSColors.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'JC',
                  style: RSTypography.displayMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 2,
              right: 2,
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: RSColors.success,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    color: Colors.white, size: 12),
              ),
            ),
          ],
        ),
        const SizedBox(width: RSSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(MockRider.fullName,
                  style: RSTypography.displayMedium.copyWith(
                    color: RSColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  )),
              Text(MockRider.phone,
                  style: RSTypography.bodyMedium.copyWith(
                    color: RSColors.textSecondary,
                  )),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: RSColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: RSColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text('Asegurado activo',
                        style: RSTypography.caption.copyWith(
                          color: RSColors.success,
                          fontWeight: FontWeight.w600,
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.edit_outlined, color: RSColors.primary),
        ),
      ],
    );
  }
}

// ─── Active Policy Summary ────────────────────────────────────────
class _ActivePolicySummary extends StatelessWidget {
  const _ActivePolicySummary();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(RSSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            RSColors.primary.withValues(alpha: 0.08),
            RSColors.primary.withValues(alpha: 0.03),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(RSRadius.md),
        border: Border.all(color: RSColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_user_rounded, color: RSColors.primary, size: 24),
          const SizedBox(width: RSSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(MockPolicy.type,
                    style: RSTypography.titleMedium.copyWith(
                      color: RSColors.primary,
                      fontWeight: FontWeight.w700,
                    )),
                Text(
                  '${MockPolicy.number} · Vence ${MockPolicy.expiryDate}',
                  style: RSTypography.caption.copyWith(color: RSColors.textSecondary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: RSColors.success,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('Activa',
                style: RSTypography.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                )),
          ),
        ],
      ),
    );
  }
}

// ─── Section Header ──────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: RSTypography.titleLarge.copyWith(color: RSColors.textPrimary));
  }
}

// ─── Info Section ────────────────────────────────────────────────
class _InfoItem {
  final IconData icon;
  final String label;
  final String value;
  const _InfoItem(this.icon, this.label, this.value);
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.items});
  final List<_InfoItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: RSColors.surface,
        borderRadius: BorderRadius.circular(RSRadius.md),
        border: Border.all(color: RSColors.border, width: 0.5),
      ),
      child: Column(
        children: items.asMap().entries.map((e) {
          final item = e.value;
          final isLast = e.key == items.length - 1;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: RSSpacing.md, vertical: 12),
                child: Row(
                  children: [
                    Icon(item.icon, color: RSColors.primary, size: 18),
                    const SizedBox(width: RSSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.label,
                              style: RSTypography.caption.copyWith(
                                color: RSColors.textSecondary,
                              )),
                          Text(item.value,
                              style: RSTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast) const Divider(height: 1, indent: 52),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ─── Payment History ─────────────────────────────────────────────
class _PaymentHistory extends StatelessWidget {
  const _PaymentHistory();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: RSColors.surface,
        borderRadius: BorderRadius.circular(RSRadius.md),
        border: Border.all(color: RSColors.border, width: 0.5),
      ),
      child: Column(
        children: MockPayments.history.asMap().entries.map((e) {
          final payment = e.value;
          final isLast = e.key == MockPayments.history.length - 1;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: RSSpacing.md, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: RSColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.check_circle_rounded,
                          color: RSColors.success, size: 18),
                    ),
                    const SizedBox(width: RSSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(payment.method,
                              style: RSTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              )),
                          Text('${payment.reference} · ${payment.date}',
                              style: RSTypography.caption.copyWith(
                                color: RSColors.textSecondary,
                              )),
                        ],
                      ),
                    ),
                    Text(
                      '\$ ${payment.amountUsd.toStringAsFixed(2)}',
                      style: RSTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: RSColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast) const Divider(height: 1, indent: 64),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ─── Settings Section ────────────────────────────────────────────
class _SettingsSection extends StatefulWidget {
  const _SettingsSection();

  @override
  State<_SettingsSection> createState() => _SettingsSectionState();
}

class _SettingsSectionState extends State<_SettingsSection> {
  bool _notificaciones = true;
  bool _biometrico = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: RSColors.surface,
        borderRadius: BorderRadius.circular(RSRadius.md),
        border: Border.all(color: RSColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          _SwitchItem(
            icon: Icons.notifications_rounded,
            label: 'Notificaciones push',
            subtitle: 'Alertas de póliza y siniestros',
            value: _notificaciones,
            onChanged: (v) => setState(() => _notificaciones = v),
          ),
          const Divider(height: 1, indent: 52),
          _SwitchItem(
            icon: Icons.fingerprint_rounded,
            label: 'Biometría',
            subtitle: 'Ingreso con huella dactilar',
            value: _biometrico,
            onChanged: (v) => setState(() => _biometrico = v),
          ),
          const Divider(height: 1, indent: 52),
          _TapItem(
            icon: Icons.help_outline_rounded,
            label: 'Centro de ayuda',
            onTap: () {},
          ),
          const Divider(height: 1, indent: 52),
          _TapItem(
            icon: Icons.privacy_tip_outlined,
            label: 'Política de privacidad',
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _SwitchItem extends StatelessWidget {
  const _SwitchItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: RSSpacing.md, vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: RSColors.primary, size: 18),
          const SizedBox(width: RSSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: RSTypography.bodyMedium
                        .copyWith(fontWeight: FontWeight.w600)),
                Text(subtitle,
                    style: RSTypography.caption
                        .copyWith(color: RSColors.textSecondary)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: RSColors.primary,
          ),
        ],
      ),
    );
  }
}

class _TapItem extends StatelessWidget {
  const _TapItem({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: RSSpacing.md, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: RSColors.primary, size: 18),
            const SizedBox(width: RSSpacing.md),
            Expanded(
              child: Text(label,
                  style: RSTypography.bodyMedium
                      .copyWith(fontWeight: FontWeight.w600)),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: RSColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─── Sign Out Button ─────────────────────────────────────────────
class _SignOutButton extends StatelessWidget {
  const _SignOutButton({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text('Cerrar sesión',
                style: RSTypography.titleLarge),
            content: Text(
              '¿Estás seguro que deseas cerrar sesión?',
              style: RSTypography.bodyMedium,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Cerrar sesión',
                    style: TextStyle(color: RSColors.error)),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          await ref.read(authProvider.notifier).signOut();
          if (context.mounted) context.go('/welcome');
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(RSSpacing.md),
        decoration: BoxDecoration(
          color: RSColors.error.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(RSRadius.md),
          border: Border.all(color: RSColors.error.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout_rounded, color: RSColors.error, size: 20),
            const SizedBox(width: RSSpacing.md),
            Text('Cerrar sesión',
                style: RSTypography.titleMedium.copyWith(
                  color: RSColors.error,
                  fontWeight: FontWeight.w600,
                )),
          ],
        ),
      ),
    );
  }
}

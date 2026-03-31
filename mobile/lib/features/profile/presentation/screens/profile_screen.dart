import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:ruedaseguro/core/theme/colors.dart';
import 'package:ruedaseguro/core/theme/spacing.dart';
import 'package:ruedaseguro/core/theme/typography.dart';
import 'package:ruedaseguro/core/data/mock_data.dart';
import 'package:ruedaseguro/features/policy/providers/policy_providers.dart';
import 'package:ruedaseguro/shared/providers/auth_provider.dart';
import 'package:ruedaseguro/shared/providers/profile_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final vehicleAsync = ref.watch(vehicleProvider);
    final profile = profileAsync.asData?.value;
    final vehicle = vehicleAsync.asData?.value;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(RSSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: RSSpacing.sm),

            _ProfileHeader(profile: profile)
                .animate()
                .fadeIn(duration: 500.ms)
                .slideY(begin: -0.05),

            const SizedBox(height: RSSpacing.lg),

            _ActivePolicySummary()
                .animate(delay: 150.ms)
                .fadeIn(duration: 400.ms),

            const SizedBox(height: RSSpacing.lg),

            _SectionHeader(title: 'Datos personales'),
            const SizedBox(height: RSSpacing.sm),
            _PersonalInfoSection(profile: profile)
                .animate(delay: 200.ms)
                .fadeIn(duration: 400.ms),

            const SizedBox(height: RSSpacing.lg),

            _SectionHeader(title: 'Mi vehículo'),
            const SizedBox(height: RSSpacing.sm),
            _VehicleSection(vehicle: vehicle)
                .animate(delay: 300.ms)
                .fadeIn(duration: 400.ms),

            const SizedBox(height: RSSpacing.lg),

            _SectionHeader(title: 'Contacto de emergencia'),
            const SizedBox(height: RSSpacing.sm),
            _EmergencySection(profile: profile)
                .animate(delay: 400.ms)
                .fadeIn(duration: 400.ms),

            const SizedBox(height: RSSpacing.lg),

            _SectionHeader(title: 'Historial de pagos'),
            const SizedBox(height: RSSpacing.sm),
            _PaymentHistory()
                .animate(delay: 500.ms)
                .fadeIn(duration: 400.ms),

            const SizedBox(height: RSSpacing.lg),

            _SectionHeader(title: 'Configuración'),
            const SizedBox(height: RSSpacing.sm),
            _SettingsSection()
                .animate(delay: 600.ms)
                .fadeIn(duration: 400.ms),

            const SizedBox(height: RSSpacing.xl),

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
  const _ProfileHeader({required this.profile});
  final ProfileSummary? profile;

  @override
  Widget build(BuildContext context) {
    final initials = profile?.initials ?? 'RS';
    final fullName = profile?.fullName ?? '...';
    final phone = profile?.phone ?? '';

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
                  initials,
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
              Text(fullName,
                  style: RSTypography.displayMedium.copyWith(
                    color: RSColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  )),
              if (phone.isNotEmpty)
                Text(phone,
                    style: RSTypography.bodyMedium.copyWith(
                      color: RSColors.textSecondary,
                    )),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
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
class _ActivePolicySummary extends ConsumerWidget {
  const _ActivePolicySummary();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final policyAsync = ref.watch(activePolicySummaryProvider);
    final policy = policyAsync.asData?.value;

    final planName = policy?.planName ?? MockPolicy.type;
    final displayNumber = policy?.displayNumber ?? MockPolicy.number;
    final expiryLabel = policy?.formattedEndDate ?? MockPolicy.expiryDate;

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
          const Icon(Icons.verified_user_rounded,
              color: RSColors.primary, size: 24),
          const SizedBox(width: RSSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(planName,
                    style: RSTypography.titleMedium.copyWith(
                      color: RSColors.primary,
                      fontWeight: FontWeight.w700,
                    )),
                Text(
                  '$displayNumber · Vence $expiryLabel',
                  style: RSTypography.caption
                      .copyWith(color: RSColors.textSecondary),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: RSColors.success,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              policy?.isProvisional == true ? 'Provisional' : 'Activa',
              style: RSTypography.caption.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Personal Info Section ────────────────────────────────────────
class _PersonalInfoSection extends StatelessWidget {
  const _PersonalInfoSection({required this.profile});
  final ProfileSummary? profile;

  static String _formatDob(String? dob) {
    if (dob == null) return '';
    try {
      final dt = DateTime.parse(dob);
      final age = DateTime.now().year - dt.year;
      return '${DateFormat('dd/MM/yyyy').format(dt)} ($age años)';
    } catch (_) {
      return dob;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = profile;
    return _InfoSection(
      items: [
        _InfoItem(Icons.person_rounded, 'Nombre',
            p?.fullName ?? MockRider.fullName),
        _InfoItem(Icons.badge_rounded, 'Cédula',
            p != null
                ? '${p.idType}-${p.idNumber}'
                : '${MockRider.idType}-${MockRider.idNumber}'),
        _InfoItem(Icons.phone_rounded, 'Teléfono',
            p?.phone ?? MockRider.phone),
        _InfoItem(Icons.cake_rounded, 'Nacimiento',
            p?.dateOfBirth != null
                ? _formatDob(p!.dateOfBirth)
                : '${MockRider.dateOfBirth} (${MockRider.age} años)'),
        _InfoItem(Icons.location_on_rounded, 'Ciudad',
            p?.ciudad != null
                ? '${p!.ciudad}${p.estado != null ? ', ${p.estado}' : ''}'
                : '${MockRider.city}, ${MockRider.state}'),
      ],
    );
  }
}

// ─── Vehicle Section ─────────────────────────────────────────────
class _VehicleSection extends StatelessWidget {
  const _VehicleSection({required this.vehicle});
  final VehicleSummary? vehicle;

  @override
  Widget build(BuildContext context) {
    final v = vehicle;
    return _InfoSection(
      items: [
        _InfoItem(Icons.two_wheeler_rounded, 'Marca / Modelo',
            v != null
                ? '${v.brand} ${v.model}'
                : '${MockVehicle.brand} ${MockVehicle.model}'),
        _InfoItem(Icons.calendar_today_rounded, 'Año',
            v != null ? '${v.year}' : '${MockVehicle.year}'),
        _InfoItem(Icons.pin_rounded, 'Placa',
            v?.plate ?? MockVehicle.plate),
        _InfoItem(Icons.color_lens_rounded, 'Color',
            v?.color ?? MockVehicle.color),
        _InfoItem(Icons.confirmation_number_rounded, 'N° Motor',
            v?.serialMotor ?? MockVehicle.serialMotor),
      ],
    );
  }
}

// ─── Emergency Section ───────────────────────────────────────────
class _EmergencySection extends StatelessWidget {
  const _EmergencySection({required this.profile});
  final ProfileSummary? profile;

  @override
  Widget build(BuildContext context) {
    final p = profile;
    return _InfoSection(
      items: [
        _InfoItem(Icons.people_rounded, 'Nombre',
            p?.emergencyName ?? MockRider.emergencyContact),
        _InfoItem(Icons.phone_rounded, 'Teléfono',
            p?.emergencyPhone ?? MockRider.emergencyPhone),
        _InfoItem(Icons.family_restroom_rounded, 'Relación',
            p?.emergencyRelation ?? MockRider.emergencyRelation),
      ],
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
class _PaymentHistory extends ConsumerWidget {
  const _PaymentHistory();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDemoMode = ref.watch(authProvider).user == null;

    if (isDemoMode) {
      return _PaymentHistoryList(payments: MockPayments.history);
    }

    // Real mode: payments table is empty for now — show empty state
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(RSSpacing.lg),
      decoration: BoxDecoration(
        color: RSColors.surface,
        borderRadius: BorderRadius.circular(RSRadius.md),
        border: Border.all(color: RSColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          const Icon(Icons.receipt_long_outlined,
              color: RSColors.textSecondary, size: 32),
          const SizedBox(height: RSSpacing.sm),
          Text('Sin pagos registrados',
              style: RSTypography.bodyMedium
                  .copyWith(color: RSColors.textSecondary)),
        ],
      ),
    );
  }
}

class _PaymentHistoryList extends StatelessWidget {
  const _PaymentHistoryList({required this.payments});
  final List<dynamic> payments;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: RSColors.surface,
        borderRadius: BorderRadius.circular(RSRadius.md),
        border: Border.all(color: RSColors.border, width: 0.5),
      ),
      child: Column(
        children: payments.asMap().entries.map((e) {
          final payment = e.value;
          final isLast = e.key == payments.length - 1;
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
  const _TapItem(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: RSSpacing.md, vertical: 14),
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
            title: Text('Cerrar sesión', style: RSTypography.titleLarge),
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
            Icon(Icons.logout_rounded, color: RSColors.error, size: 20),
            const SizedBox(width: RSSpacing.sm),
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

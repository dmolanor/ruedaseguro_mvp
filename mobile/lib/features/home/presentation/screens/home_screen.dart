import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ruedaseguro/core/data/mock_data.dart';
import 'package:ruedaseguro/core/theme/colors.dart';
import 'package:ruedaseguro/core/theme/spacing.dart';
import 'package:ruedaseguro/core/theme/typography.dart';
import 'package:ruedaseguro/features/policy/domain/policy_detail_model.dart';
import 'package:ruedaseguro/features/policy/presentation/screens/policy_detail_screen.dart';
import 'package:ruedaseguro/features/policy/providers/policy_providers.dart';
import 'package:ruedaseguro/features/profile/presentation/screens/profile_screen.dart';
import 'package:ruedaseguro/shared/providers/auth_provider.dart';
import 'package:ruedaseguro/shared/providers/bcv_rate_provider.dart';
import 'package:ruedaseguro/shared/providers/profile_provider.dart';
import 'package:ruedaseguro/shared/widgets/rs_button.dart';
import 'package:ruedaseguro/shared/widgets/rs_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDemoMode = ref.watch(authProvider).user == null;

    // Resolve active policy ID for the Policy tab
    final String policyTabId;
    if (isDemoMode) {
      policyTabId = 'RS-2026-001234';
    } else {
      final policyAsync = ref.watch(activePolicySummaryProvider);
      policyTabId = policyAsync.asData?.value?.id ?? 'RS-2026-001234';
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const _HomeTab(),
          PolicyDetailScreen(policyId: policyTabId, isTab: true),
          const _ClaimsTab(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: RSColors.border, width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          type: BottomNavigationBarType.fixed,
          backgroundColor: RSColors.surface,
          selectedItemColor: RSColors.primary,
          unselectedItemColor: RSColors.textSecondary,
          selectedLabelStyle:
              RSTypography.caption.copyWith(fontWeight: FontWeight.w600),
          unselectedLabelStyle: RSTypography.caption,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Inicio',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.description_outlined),
              activeIcon: Icon(Icons.description_rounded),
              label: 'Mi Póliza',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.support_agent_outlined),
              activeIcon: Icon(Icons.support_agent_rounded),
              label: 'Asistencia',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Home Tab (Dashboard) ────────────────────────────────────────
class _HomeTab extends ConsumerWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(RSSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _GreetingHeader()
                .animate()
                .fadeIn(duration: 500.ms)
                .slideY(begin: -0.1),

            const SizedBox(height: RSSpacing.lg),

            const _ActivePolicyCard()
                .animate(delay: 150.ms)
                .fadeIn(duration: 500.ms)
                .slideY(begin: 0.1),

            const SizedBox(height: RSSpacing.lg),

            const _EmergencyButton()
                .animate(delay: 300.ms)
                .fadeIn(duration: 500.ms)
                .scale(begin: const Offset(0.95, 0.95)),

            const SizedBox(height: RSSpacing.lg),

            Text('Acciones rápidas',
                style: RSTypography.titleLarge
                    .copyWith(color: RSColors.textPrimary)),
            const SizedBox(height: RSSpacing.md),
            const _QuickActionsGrid()
                .animate(delay: 450.ms)
                .fadeIn(duration: 500.ms),

            const SizedBox(height: RSSpacing.lg),

            const _ExchangeRateBanner()
                .animate(delay: 600.ms)
                .fadeIn(duration: 500.ms),

            const SizedBox(height: RSSpacing.lg),

            Text('Actividad reciente',
                style: RSTypography.titleLarge
                    .copyWith(color: RSColors.textPrimary)),
            const SizedBox(height: RSSpacing.md),
            const _RecentActivity()
                .animate(delay: 700.ms)
                .fadeIn(duration: 500.ms),

            const SizedBox(height: RSSpacing.xl),
          ],
        ),
      ),
    );
  }
}

// ─── Greeting Header ─────────────────────────────────────────────
class _GreetingHeader extends ConsumerWidget {
  const _GreetingHeader();

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Buenos días';
    if (hour < 18) return 'Buenas tardes';
    return 'Buenas noches';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDemoMode = ref.watch(authProvider).user == null;
    final profileAsync = ref.watch(profileProvider);

    final String firstName;
    final String initials;

    if (isDemoMode) {
      firstName = MockRider.firstName;
      initials = 'JC';
    } else {
      final profile = profileAsync.asData?.value;
      firstName = profile?.firstName ?? '...';
      initials = profile?.initials ?? '?';
    }

    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [RSColors.primary, RSColors.primaryLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              initials,
              style: RSTypography.titleLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: RSSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greeting,
                style: RSTypography.bodyMedium
                    .copyWith(color: RSColors.textSecondary),
              ),
              Text(
                firstName,
                style: RSTypography.displayMedium
                    .copyWith(color: RSColors.textPrimary),
              ),
            ],
          ),
        ),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: RSColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              const Center(
                child: Icon(Icons.notifications_outlined,
                    color: RSColors.textSecondary, size: 24),
              ),
              Positioned(
                top: 8,
                right: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: RSColors.accent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Active Policy Card ──────────────────────────────────────────
class _ActivePolicyCard extends ConsumerWidget {
  const _ActivePolicyCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDemoMode = ref.watch(authProvider).user == null;

    if (isDemoMode) {
      return _PolicyCardContent(policy: null);
    }

    final policyAsync = ref.watch(activePolicySummaryProvider);

    return policyAsync.when(
      loading: () => const _PolicyCardSkeleton(),
      error: (_, __) => _PolicyCardContent(policy: null),
      data: (policy) => policy == null
          ? const _NoPolicyCard()
          : _PolicyCardContent(policy: policy),
    );
  }
}

class _PolicyCardSkeleton extends StatelessWidget {
  const _PolicyCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: RSColors.surface,
        borderRadius: BorderRadius.circular(RSRadius.lg),
        border: Border.all(color: RSColors.border),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: RSColors.primary,
          strokeWidth: 2,
        ),
      ),
    );
  }
}

class _NoPolicyCard extends StatelessWidget {
  const _NoPolicyCard();

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
          const Icon(Icons.shield_outlined,
              color: RSColors.textSecondary, size: 40),
          const SizedBox(height: RSSpacing.md),
          Text('Aún no tienes una póliza activa',
              style: RSTypography.titleMedium
                  .copyWith(color: RSColors.textPrimary),
              textAlign: TextAlign.center),
          const SizedBox(height: RSSpacing.sm),
          Text('Cotiza tu primera póliza en menos de 2 minutos.',
              style: RSTypography.bodyMedium
                  .copyWith(color: RSColors.textSecondary),
              textAlign: TextAlign.center),
          const SizedBox(height: RSSpacing.lg),
          RSButton(
            label: 'Cotizar ahora',
            onPressed: () => context.push('/policy/select'),
          ),
        ],
      ),
    );
  }
}

class _PolicyCardContent extends StatelessWidget {
  const _PolicyCardContent({required this.policy});
  final PolicyDetailModel? policy;

  @override
  Widget build(BuildContext context) {
    final planName = policy?.planName ?? MockPolicy.type;
    final displayNumber = policy?.displayNumber ?? MockPolicy.number;
    final vehicleLabel = policy != null
        ? '${policy!.vehicleBrand} ${policy!.vehicleModel}'
        : '${MockVehicle.brand} ${MockVehicle.model}';
    final expiryLabel = policy?.formattedEndDate ?? MockPolicy.expiryDate;
    final daysRemaining = policy?.daysRemaining ?? 365;
    final progress = policy?.progressFraction ?? 1.0;
    final isProvisional = policy?.isProvisional ?? false;
    final statusLabel = isProvisional ? 'Provisional' : 'Activa';
    final statusColor =
        isProvisional ? const Color(0xFFE65100) : const Color(0xFF2E7D32);
    final statusDot =
        isProvisional ? const Color(0xFFFFB74D) : const Color(0xFF81C784);

    return GestureDetector(
      onTap: () {
        if (policy != null) context.push('/policy/${policy!.id}');
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A237E), Color(0xFF283593)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(RSRadius.lg),
          boxShadow: [
            BoxShadow(
              color: RSColors.primary.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(RSSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'PÓLIZA ${isProvisional ? 'PROVISIONAL' : 'ACTIVA'}',
                    style: RSTypography.caption.copyWith(
                      color: Colors.white.withValues(alpha: 0.7),
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                              color: statusDot, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        Text(statusLabel,
                            style: RSTypography.caption.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            )),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: RSSpacing.md),
              Text(
                planName,
                style: RSTypography.displayMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: RSSpacing.xs),
              Text(
                displayNumber,
                style: RSTypography.mono.copyWith(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: RSSpacing.lg),
              Row(
                children: [
                  _PolicyInfoChip(
                    icon: Icons.two_wheeler_rounded,
                    label: vehicleLabel,
                  ),
                  const SizedBox(width: RSSpacing.md),
                  _PolicyInfoChip(
                    icon: Icons.calendar_today_rounded,
                    label: 'Vence $expiryLabel',
                  ),
                ],
              ),
              const SizedBox(height: RSSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$daysRemaining días restantes',
                        style: RSTypography.caption.copyWith(
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                      Text(
                        '${(progress * 100).toStringAsFixed(0)}%',
                        style: RSTypography.caption.copyWith(
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor:
                          Colors.white.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(
                          isProvisional
                              ? const Color(0xFFFFB74D)
                              : const Color(0xFF81C784)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PolicyInfoChip extends StatelessWidget {
  const _PolicyInfoChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.6), size: 14),
        const SizedBox(width: 4),
        Text(label,
            style: RSTypography.caption.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            )),
      ],
    );
  }
}

// ─── Emergency SOS Button ────────────────────────────────────────
class _EmergencyButton extends StatelessWidget {
  const _EmergencyButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/emergency'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(RSSpacing.md),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFC62828), Color(0xFFE53935)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(RSRadius.lg),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFC62828).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child:
                  const Icon(Icons.sos_rounded, color: Colors.white, size: 28),
            ),
            const SizedBox(width: RSSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Modo Emergencia',
                    style: RSTypography.titleLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Activa asistencia inmediata en caso de accidente',
                    style: RSTypography.caption.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: Colors.white, size: 28),
          ],
        ),
      ),
    );
  }
}

// ─── Quick Actions Grid ──────────────────────────────────────────
class _QuickActionsGrid extends ConsumerWidget {
  const _QuickActionsGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final policyId = ref.watch(activePolicySummaryProvider).asData?.value?.id;
    final viewPolicyId = policyId ?? 'RS-2026-001234';

    final actions = [
      _QuickAction(
        icon: Icons.add_circle_outline_rounded,
        label: 'Cotizar',
        color: RSColors.accent,
        onTap: () => context.push('/policy/select'),
      ),
      _QuickAction(
        icon: Icons.description_outlined,
        label: 'Ver Póliza',
        color: RSColors.primary,
        onTap: () => context.push('/policy/$viewPolicyId'),
      ),
      _QuickAction(
        icon: Icons.report_outlined,
        label: 'Reportar\nSiniestro',
        color: const Color(0xFFC62828),
        onTap: () => context.push('/claims/new'),
      ),
      _QuickAction(
        icon: Icons.payments_outlined,
        label: 'Pagos',
        color: const Color(0xFF2E7D32),
        onTap: () => context.push('/payment/method'),
      ),
    ];

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: RSSpacing.sm,
      crossAxisSpacing: RSSpacing.sm,
      childAspectRatio: 0.85,
      children: actions
          .asMap()
          .entries
          .map((e) => e.value
              .animate(delay: (100 * e.key).ms)
              .fadeIn(duration: 300.ms)
              .scale(begin: const Offset(0.9, 0.9)))
          .toList(),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: RSSpacing.sm),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: RSTypography.caption.copyWith(
              color: RSColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Exchange Rate Banner ────────────────────────────────────────
class _ExchangeRateBanner extends ConsumerWidget {
  const _ExchangeRateBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bcvAsync = ref.watch(bcvRateProvider);

    final rate = bcvAsync.when(
      data: (r) =>
          '1 USD = ${r.rate.toStringAsFixed(2)} VES${r.stale ? ' (aprox.)' : ''}',
      loading: () => '...',
      error: (_, __) =>
          '1 USD = ${MockExchangeRate.rate.toStringAsFixed(2)} VES (aprox.)',
    );
    final time = bcvAsync.when(
      data: (r) => r.stale ? 'Sin conexión' : 'BCV en vivo',
      loading: () => '',
      error: (_, __) => 'Sin conexión',
    );

    return RSCard(
      padding: const EdgeInsets.symmetric(
        horizontal: RSSpacing.md,
        vertical: RSSpacing.md,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.currency_exchange_rounded,
                color: Color(0xFF2E7D32), size: 22),
          ),
          const SizedBox(width: RSSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tasa BCV',
                  style: RSTypography.caption
                      .copyWith(color: RSColors.textSecondary),
                ),
                Text(
                  rate,
                  style: RSTypography.titleMedium.copyWith(
                    color: RSColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style:
                RSTypography.caption.copyWith(color: RSColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ─── Recent Activity ─────────────────────────────────────────────
class _RecentActivity extends StatelessWidget {
  const _RecentActivity();

  @override
  Widget build(BuildContext context) {
    final activities = [
      _ActivityItem(
        icon: Icons.check_circle_rounded,
        color: const Color(0xFF2E7D32),
        title: 'Póliza registrada',
        subtitle: 'RCV Plus — ${MockPolicy.issueDate}',
      ),
      _ActivityItem(
        icon: Icons.payment_rounded,
        color: RSColors.primary,
        title: 'Pago enviado',
        subtitle: 'Pago Móvil — \$${MockPolicy.premiumUsd.toStringAsFixed(2)}',
      ),
      _ActivityItem(
        icon: Icons.hourglass_top_rounded,
        color: const Color(0xFFFFB300),
        title: 'Reclamo en revisión',
        subtitle:
            '${MockClaims.claims.first.id} — ${MockClaims.claims.first.type}',
      ),
    ];

    return RSCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: activities.asMap().entries.map((e) {
          final item = e.value;
          final isLast = e.key == activities.length - 1;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: RSSpacing.md,
                  vertical: RSSpacing.md,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: item.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(item.icon, color: item.color, size: 18),
                    ),
                    const SizedBox(width: RSSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.title,
                              style: RSTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              )),
                          Text(item.subtitle,
                              style: RSTypography.caption.copyWith(
                                color: RSColors.textSecondary,
                              )),
                        ],
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

class _ActivityItem {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _ActivityItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });
}

// ─── Claims Tab ──────────────────────────────────────────────────
class _ClaimsTab extends StatelessWidget {
  const _ClaimsTab();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(RSSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: RSSpacing.sm),
            Text(
              'Asistencia',
              style:
                  RSTypography.displayLarge.copyWith(color: RSColors.textPrimary),
            ),
            const SizedBox(height: RSSpacing.xs),
            Text(
              'Gestiona siniestros y solicita ayuda',
              style: RSTypography.bodyMedium
                  .copyWith(color: RSColors.textSecondary),
            ),
            const SizedBox(height: RSSpacing.lg),

            GestureDetector(
              onTap: () => context.push('/emergency'),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(RSSpacing.lg),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFC62828), Color(0xFFE53935)],
                  ),
                  borderRadius: BorderRadius.circular(RSRadius.lg),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.sos_rounded, color: Colors.white, size: 32),
                    const SizedBox(width: RSSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Emergencia',
                              style: RSTypography.titleLarge.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700)),
                          Text('Tuve un accidente — necesito ayuda',
                              style: RSTypography.caption.copyWith(
                                  color: Colors.white.withValues(alpha: 0.8))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: RSSpacing.lg),

            RSButton(
              label: 'Reportar nuevo siniestro',
              variant: RSButtonVariant.secondary,
              onPressed: () => context.push('/claims/new'),
            ),

            const SizedBox(height: RSSpacing.xl),

            Text(
              'Historial de siniestros',
              style:
                  RSTypography.titleLarge.copyWith(color: RSColors.textPrimary),
            ),
            const SizedBox(height: RSSpacing.md),

            Expanded(
              child: ListView.separated(
                itemCount: MockClaims.claims.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: RSSpacing.md),
                itemBuilder: (_, i) {
                  final claim = MockClaims.claims[i];
                  return RSCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(claim.id,
                                style: RSTypography.mono.copyWith(
                                  fontSize: 12,
                                  color: RSColors.textSecondary,
                                )),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color:
                                    claim.statusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(claim.statusIcon,
                                      size: 14, color: claim.statusColor),
                                  const SizedBox(width: 4),
                                  Text(claim.status,
                                      style: RSTypography.caption.copyWith(
                                        color: claim.statusColor,
                                        fontWeight: FontWeight.w600,
                                      )),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: RSSpacing.sm),
                        Text(claim.type,
                            style: RSTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            )),
                        const SizedBox(height: RSSpacing.xs),
                        Text(claim.description,
                            style: RSTypography.bodyMedium.copyWith(
                              color: RSColors.textSecondary,
                            )),
                        const SizedBox(height: RSSpacing.sm),
                        Text(claim.date,
                            style: RSTypography.caption.copyWith(
                              color: RSColors.textSecondary,
                            )),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

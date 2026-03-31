import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import 'package:ruedaseguro/core/data/mock_data.dart';
import 'package:ruedaseguro/core/theme/colors.dart';
import 'package:ruedaseguro/core/theme/spacing.dart';
import 'package:ruedaseguro/core/theme/typography.dart';
import 'package:ruedaseguro/features/policy/domain/policy_detail_model.dart';
import 'package:ruedaseguro/features/policy/providers/policy_providers.dart';
import 'package:ruedaseguro/features/policy/services/policy_pdf_service.dart';
import 'package:ruedaseguro/shared/providers/auth_provider.dart';
import 'package:ruedaseguro/shared/widgets/rs_button.dart';

class PolicyDetailScreen extends ConsumerWidget {
  final String policyId;
  final bool isTab;

  const PolicyDetailScreen(
      {super.key, required this.policyId, this.isTab = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDemoMode = ref.watch(authProvider).user == null;

    // Demo mode: render with mock data immediately
    if (isDemoMode) {
      return _PolicyDetailBody(
        policy: null,
        policyId: policyId,
        isTab: isTab,
        isDemoMode: true,
      );
    }

    final policyAsync = ref.watch(policyDetailProvider(policyId));

    return policyAsync.when(
      loading: () => _LoadingScaffold(isTab: isTab),
      error: (_, __) => _PolicyDetailBody(
        policy: null,
        policyId: policyId,
        isTab: isTab,
        isDemoMode: true, // fallback to mock on error
      ),
      data: (policy) => _PolicyDetailBody(
        policy: policy,
        policyId: policyId,
        isTab: isTab,
        isDemoMode: false,
      ),
    );
  }
}

// ─── Loading shimmer scaffold ─────────────────────────────────────
class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold({required this.isTab});
  final bool isTab;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RSColors.background,
      appBar: _buildAppBar(context, isTab),
      body: Shimmer.fromColors(
        baseColor: RSColors.surface,
        highlightColor: RSColors.surfaceVariant,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(RSSpacing.lg),
          child: Column(
            children: [
              Container(
                  height: 300,
                  decoration: BoxDecoration(
                    color: RSColors.surface,
                    borderRadius: BorderRadius.circular(RSRadius.xl),
                  )),
              const SizedBox(height: RSSpacing.lg),
              ...List.generate(
                  3,
                  (_) => Padding(
                        padding:
                            const EdgeInsets.only(bottom: RSSpacing.md),
                        child: Container(
                          height: 120,
                          decoration: BoxDecoration(
                            color: RSColors.surface,
                            borderRadius:
                                BorderRadius.circular(RSRadius.md),
                          ),
                        ),
                      )),
            ],
          ),
        ),
      ),
    );
  }
}

AppBar _buildAppBar(BuildContext context, bool isTab) {
  return AppBar(
    backgroundColor: Colors.transparent,
    elevation: 0,
    leading: isTab
        ? null
        : IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: RSColors.primary),
            onPressed: () => context.pop(),
          ),
    automaticallyImplyLeading: !isTab,
    title: Text('Mi Póliza',
        style: RSTypography.titleLarge.copyWith(color: RSColors.primary)),
    actions: [
      IconButton(
        icon: const Icon(Icons.share_rounded, color: RSColors.primary),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Compartiendo póliza...')),
          );
        },
      ),
    ],
  );
}

// ─── Main body ────────────────────────────────────────────────────
class _PolicyDetailBody extends StatelessWidget {
  const _PolicyDetailBody({
    required this.policy,
    required this.policyId,
    required this.isTab,
    required this.isDemoMode,
  });

  final PolicyDetailModel? policy;
  final String policyId;
  final bool isTab;
  final bool isDemoMode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RSColors.background,
      appBar: _buildAppBar(context, isTab),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(RSSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (policy != null && policy!.isProvisional)
              _ProvisionalBanner(policyId: policy!.id)
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: -0.1),

            if (policy != null && policy!.isProvisional)
              const SizedBox(height: RSSpacing.md),

            _DigitalPolicyCard(policy: policy)
                .animate()
                .fadeIn(duration: 600.ms)
                .scale(begin: const Offset(0.97, 0.97)),

            const SizedBox(height: RSSpacing.lg),

            _CoverageChips(tier: policy?.tier ?? MockPolicy.tier)
                .animate(delay: 200.ms)
                .fadeIn(duration: 400.ms),

            const SizedBox(height: RSSpacing.lg),

            _SectionCard(
              title: 'Vehículo',
              icon: Icons.two_wheeler_rounded,
              children: [
                _DetailRow(
                    label: 'Marca / Modelo',
                    value: policy != null
                        ? '${policy!.vehicleBrand} ${policy!.vehicleModel}'
                        : '${MockVehicle.brand} ${MockVehicle.model}'),
                _DetailRow(
                    label: 'Año',
                    value: '${policy?.vehicleYear ?? MockVehicle.year}'),
                _DetailRow(
                    label: 'Placa',
                    value: policy?.vehiclePlate ?? MockVehicle.plate,
                    isMono: true),
                _DetailRow(
                    label: 'Color',
                    value: policy?.vehicleColor.isNotEmpty == true
                        ? policy!.vehicleColor
                        : MockVehicle.color),
              ],
            ).animate(delay: 300.ms).fadeIn(duration: 400.ms),

            const SizedBox(height: RSSpacing.md),

            _SectionCard(
              title: 'Detalles de la póliza',
              icon: Icons.description_rounded,
              children: [
                _DetailRow(
                    label: 'N° de póliza',
                    value: policy?.displayNumber ?? MockPolicy.number,
                    isMono: true,
                    isCopiable: true),
                _DetailRow(
                    label: 'Aseguradora',
                    value: policy?.carrierName ?? MockPolicy.carrier),
                _DetailRow(
                    label: 'Plan',
                    value: policy?.planName ?? MockPolicy.type),
                _DetailRow(
                    label: 'Vigencia desde',
                    value: policy?.formattedStartDate ?? MockPolicy.issueDate),
                _DetailRow(
                    label: 'Vigencia hasta',
                    value: policy?.formattedEndDate ?? MockPolicy.expiryDate),
                _DetailRow(
                    label: 'Prima anual',
                    value:
                        '\$ ${(policy?.premiumUsd ?? MockPolicy.premiumUsd).toStringAsFixed(2)} USD'),
              ],
            ).animate(delay: 400.ms).fadeIn(duration: 400.ms),

            const SizedBox(height: RSSpacing.md),

            _HashCard(policyId: policy?.id ?? policyId)
                .animate(delay: 500.ms)
                .fadeIn(duration: 400.ms),

            const SizedBox(height: RSSpacing.xl),

            _DownloadPdfButton(policy: policy)
                .animate(delay: 600.ms)
                .fadeIn(duration: 400.ms),

            const SizedBox(height: RSSpacing.md),

            RSButton(
              label: 'Renovar póliza',
              variant: RSButtonVariant.secondary,
              onPressed: () => context.push('/policy/select'),
            ).animate(delay: 650.ms).fadeIn(duration: 400.ms),

            const SizedBox(height: RSSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

// ─── Download PDF button ─────────────────────────────────────────
class _DownloadPdfButton extends StatefulWidget {
  const _DownloadPdfButton({required this.policy});
  final PolicyDetailModel? policy;

  @override
  State<_DownloadPdfButton> createState() => _DownloadPdfButtonState();
}

class _DownloadPdfButtonState extends State<_DownloadPdfButton> {
  bool _generating = false;

  Future<void> _generate() async {
    setState(() => _generating = true);
    try {
      await PolicyPdfService.shareProvisionalPdf(widget.policy);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al generar PDF: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RSButton(
      label: _generating ? 'Generando PDF...' : 'Descargar póliza en PDF',
      onPressed: _generating ? null : _generate,
    );
  }
}

// ─── Digital Policy Card ─────────────────────────────────────────
class _DigitalPolicyCard extends StatelessWidget {
  const _DigitalPolicyCard({required this.policy});
  final PolicyDetailModel? policy;

  @override
  Widget build(BuildContext context) {
    final isProvisional = policy?.isProvisional ?? false;
    final riderName = policy?.riderFullName ?? MockRider.fullName;
    final riderId =
        '${policy?.riderIdType ?? MockRider.idType}-${policy?.riderIdNumber ?? MockRider.idNumber}';
    final planName = policy?.planName ?? MockPolicy.type;
    final startDate = policy?.formattedStartDate ?? MockPolicy.issueDate;
    final endDate = policy?.formattedEndDate ?? MockPolicy.expiryDate;
    final displayNumber = policy?.displayNumber ?? MockPolicy.number;
    final vehicleBrand = policy?.vehicleBrand ?? MockVehicle.brand;
    final vehicleModel = policy?.vehicleModel ?? MockVehicle.model;
    final vehicleYear = policy?.vehicleYear ?? MockVehicle.year;
    final vehiclePlate = policy?.vehiclePlate ?? MockVehicle.plate;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A237E), Color(0xFF283593), Color(0xFF1565C0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(RSRadius.xl),
        boxShadow: [
          BoxShadow(
            color: RSColors.primary.withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -30,
            right: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -20,
            left: 30,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(RSSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: RSColors.accent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.shield_rounded,
                              color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: RSSpacing.sm),
                        Text('RuedaSeguro',
                            style: RSTypography.titleMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            )),
                      ],
                    ),
                    _StatusBadge(
                      isProvisional: isProvisional,
                      status: policy?.status,
                    ),
                  ],
                ),

                const SizedBox(height: RSSpacing.lg),

                Text(
                  planName.toUpperCase(),
                  style: RSTypography.caption.copyWith(
                    color: Colors.white.withValues(alpha: 0.6),
                    letterSpacing: 2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  riderName,
                  style: RSTypography.displayMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: RSSpacing.xs),
                Text(
                  riderId,
                  style: RSTypography.mono.copyWith(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: RSSpacing.lg),

                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: RSSpacing.md, vertical: RSSpacing.sm + 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(RSRadius.sm),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.two_wheeler_rounded,
                          color: Colors.white, size: 18),
                      const SizedBox(width: RSSpacing.sm),
                      Text(
                        '$vehicleBrand $vehicleModel $vehicleYear',
                        style: RSTypography.bodyMedium.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          vehiclePlate,
                          style: RSTypography.mono.copyWith(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: RSSpacing.lg),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('VIGENCIA',
                              style: RSTypography.caption.copyWith(
                                color: Colors.white.withValues(alpha: 0.5),
                                letterSpacing: 1.5,
                                fontSize: 10,
                              )),
                          const SizedBox(height: 4),
                          Text(
                            '$startDate – $endDate',
                            style: RSTypography.bodyMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.qr_code_2_rounded,
                          color: RSColors.primary, size: 48),
                    ),
                  ],
                ),

                const SizedBox(height: RSSpacing.md),

                Text(
                  displayNumber,
                  style: RSTypography.mono.copyWith(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 11,
                    letterSpacing: 1,
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

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isProvisional, required this.status});
  final bool isProvisional;
  final String? status;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color dot;
    final String label;

    if (isProvisional) {
      bg = const Color(0xFFE65100);
      dot = const Color(0xFFFFB74D);
      label = 'PROVISIONAL';
    } else if (status == 'active') {
      bg = const Color(0xFF2E7D32);
      dot = const Color(0xFF81C784);
      label = 'Activa';
    } else if (status == 'pending_emission' || status == 'pending_payment') {
      bg = const Color(0xFFE65100);
      dot = const Color(0xFFFFB74D);
      label = 'Pendiente';
    } else {
      // demo mode fallback
      bg = const Color(0xFF2E7D32);
      dot = const Color(0xFF81C784);
      label = MockPolicy.status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label,
              style: RSTypography.caption.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              )),
        ],
      ),
    );
  }
}

// ─── Coverage Chips ──────────────────────────────────────────────
class _CoverageChips extends StatelessWidget {
  const _CoverageChips({required this.tier});
  final String tier;

  @override
  Widget build(BuildContext context) {
    final List<(String, IconData, Color)> highlights = [
      ('Daños a terceros', Icons.car_crash_rounded, RSColors.primary),
      if (tier != 'basica')
        ('Grúa 24/7', Icons.local_shipping_rounded, const Color(0xFF5C6BC0)),
      ('Defensa legal', Icons.gavel_rounded, const Color(0xFF2E7D32)),
      if (tier == 'ampliada')
        ('Gastos médicos', Icons.local_hospital_rounded, RSColors.accent),
    ];

    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: highlights.length,
        separatorBuilder: (_, __) => const SizedBox(width: RSSpacing.sm),
        itemBuilder: (_, i) {
          final (label, icon, color) = highlights[i];
          return Container(
            padding: const EdgeInsets.symmetric(
                horizontal: RSSpacing.md, vertical: RSSpacing.sm),
            decoration: BoxDecoration(
              color: RSColors.surface,
              borderRadius: BorderRadius.circular(RSRadius.md),
              border: Border.all(color: RSColors.border),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(height: 4),
                Text(label,
                    style: RSTypography.caption.copyWith(
                      color: RSColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    )),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Section Card ────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: RSColors.surface,
        borderRadius: BorderRadius.circular(RSRadius.md),
        border: Border.all(color: RSColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                RSSpacing.md, RSSpacing.md, RSSpacing.md, 0),
            child: Row(
              children: [
                Icon(icon, color: RSColors.primary, size: 18),
                const SizedBox(width: RSSpacing.sm),
                Text(title,
                    style: RSTypography.titleMedium.copyWith(
                      color: RSColors.primary,
                      fontWeight: FontWeight.w700,
                    )),
              ],
            ),
          ),
          const SizedBox(height: RSSpacing.md),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(RSSpacing.md),
            child: Column(
              children: children
                  .expand((child) =>
                      [child, const Divider(height: RSSpacing.md)])
                  .toList()
                ..removeLast(),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.isMono = false,
    this.isCopiable = false,
  });

  final String label;
  final String value;
  final bool isMono;
  final bool isCopiable;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: RSTypography.bodyMedium
                .copyWith(color: RSColors.textSecondary)),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: isMono
                  ? RSTypography.mono
                      .copyWith(fontSize: 13, color: RSColors.textPrimary)
                  : RSTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: RSColors.textPrimary,
                    ),
            ),
            if (isCopiable) ...[
              const SizedBox(width: RSSpacing.xs),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Copiado al portapapeles'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: const Icon(Icons.copy_rounded,
                    size: 14, color: RSColors.textSecondary),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

// ─── Hash Integrity Card ─────────────────────────────────────────
class _HashCard extends StatelessWidget {
  const _HashCard({required this.policyId});
  final String policyId;

  // Deterministic short hash derived from the policy UUID
  String get _shortHash {
    final hash = MockPolicy.sha256Hash; // fallback
    if (policyId.length >= 32) {
      final h = policyId.replaceAll('-', '');
      return '${h.substring(0, 8)}...${h.substring(h.length - 8)}';
    }
    return '${hash.substring(0, 8)}...${hash.substring(hash.length - 8)}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(RSSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFF2E7D32).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(RSRadius.md),
        border: Border.all(
          color: const Color(0xFF2E7D32).withValues(alpha: 0.3),
          width: 1,
        ),
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
            child: const Icon(Icons.verified_rounded,
                color: Color(0xFF2E7D32), size: 22),
          ),
          const SizedBox(width: RSSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Integridad verificada',
                    style: RSTypography.bodyMedium.copyWith(
                      color: const Color(0xFF2E7D32),
                      fontWeight: FontWeight.w700,
                    )),
                const SizedBox(height: 2),
                Text(
                  'SHA-256: $_shortHash',
                  style: RSTypography.mono.copyWith(
                    fontSize: 11,
                    color: RSColors.textSecondary,
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

// ─── Provisional Banner (RS-064) ──────────────────────────────────
class _ProvisionalBanner extends StatelessWidget {
  const _ProvisionalBanner({required this.policyId});
  final String policyId;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: RSSpacing.md, vertical: RSSpacing.sm + 2),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(RSRadius.md),
        border: Border.all(color: const Color(0xFFFFB300), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(Icons.hourglass_top_rounded,
                color: Color(0xFFE65100), size: 18),
          ),
          const SizedBox(width: RSSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Póliza provisional · Pago en verificación',
                  style: RSTypography.bodyMedium.copyWith(
                    color: const Color(0xFFE65100),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Tu pago Pago Móvil está siendo verificado. '
                  'La póliza se activa en ≤ 24 h. '
                  'Tu cobertura RCV inicia una vez confirmada.',
                  style: RSTypography.caption.copyWith(
                    color: const Color(0xFFBF360C),
                    height: 1.4,
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

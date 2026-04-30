import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import 'package:ruedaseguro/core/data/mock_data.dart';
import 'package:ruedaseguro/core/theme/colors.dart';
import 'package:ruedaseguro/core/theme/spacing.dart';
import 'package:ruedaseguro/core/theme/typography.dart';
import 'package:ruedaseguro/features/policy/domain/policy_detail_model.dart';
import 'package:ruedaseguro/features/policy/providers/policy_providers.dart';
import 'package:ruedaseguro/features/policy/services/policy_card_service.dart';
import 'package:ruedaseguro/shared/providers/auth_provider.dart';

/// RS-101: Digital policy carnet with QR code.
///
/// [extra] may contain pre-resolved fields (e.g. from the emission success view)
/// to avoid an extra DB round-trip.
class PolicyCarnetScreen extends ConsumerWidget {
  const PolicyCarnetScreen({super.key, required this.policyId, this.extra});

  final String policyId;

  /// Optional pre-resolved data: 'policyNumber', 'plate', 'holderName',
  /// 'tier', 'expiryIso'. Falls back to DB fetch if missing.
  final Map<String, dynamic>? extra;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDemoMode = ref.watch(authProvider).user == null;

    if (isDemoMode || policyId == 'demo') {
      return _CarnetBody(
        policyNumber: MockPolicy.number,
        plate: MockVehicle.plate,
        holderName: MockRider.fullName,
        idLabel: '${MockRider.idType}-${MockRider.idNumber}',
        vehicleLabel:
            '${MockVehicle.brand} ${MockVehicle.model} ${MockVehicle.year}',
        tier: MockPolicy.tier,
        carrierName: MockPolicy.carrier,
        expiryLabel: MockPolicy.expiryDate,
        isProvisional: false,
      );
    }

    final policyAsync = ref.watch(policyDetailProvider(policyId));

    return policyAsync.when(
      loading: () => Scaffold(
        backgroundColor: RSColors.background,
        appBar: _buildAppBar(context),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Scaffold(
        backgroundColor: RSColors.background,
        appBar: _buildAppBar(context),
        body: Center(
          child: Text(
            'Error al cargar la póliza',
            style: RSTypography.bodyMedium.copyWith(
              color: RSColors.textSecondary,
            ),
          ),
        ),
      ),
      data: (policy) {
        if (policy == null) {
          return Scaffold(
            backgroundColor: RSColors.background,
            appBar: _buildAppBar(context),
            body: Center(
              child: Text(
                'Póliza no encontrada',
                style: RSTypography.bodyMedium.copyWith(
                  color: RSColors.textSecondary,
                ),
              ),
            ),
          );
        }
        return _CarnetBody(
          policyNumber: policy.displayNumber,
          plate: policy.vehiclePlate,
          holderName: policy.riderFullName,
          idLabel: '${policy.riderIdType}-${policy.riderIdNumber}',
          vehicleLabel:
              '${policy.vehicleBrand} ${policy.vehicleModel} ${policy.vehicleYear}',
          tier: policy.tier,
          carrierName: policy.carrierName,
          expiryLabel: policy.formattedEndDate,
          isProvisional: policy.isProvisional,
          policyId: policy.id,
          expiryIso: policy.endDate,
        );
      },
    );
  }

  AppBar _buildAppBar(BuildContext context) => AppBar(
    backgroundColor: Colors.transparent,
    elevation: 0,
    leading: IconButton(
      icon: const Icon(
        Icons.arrow_back_ios_new_rounded,
        color: RSColors.primary,
      ),
      onPressed: () => Navigator.of(context).pop(),
    ),
    title: Text(
      'Carnet Digital',
      style: RSTypography.titleLarge.copyWith(color: RSColors.primary),
    ),
  );
}

// ─── Carnet Body ──────────────────────────────────────────────────

class _CarnetBody extends StatelessWidget {
  const _CarnetBody({
    required this.policyNumber,
    required this.plate,
    required this.holderName,
    required this.idLabel,
    required this.vehicleLabel,
    required this.tier,
    required this.carrierName,
    required this.expiryLabel,
    required this.isProvisional,
    this.policyId,
    this.expiryIso,
  });

  final String policyNumber;
  final String plate;
  final String holderName;
  final String idLabel;
  final String vehicleLabel;
  final String tier;
  final String carrierName;
  final String expiryLabel;
  final bool isProvisional;
  final String? policyId;
  final String? expiryIso;

  String get _qrData => PolicyCardService.instance.generateQrData(
    policyId: policyId ?? policyNumber,
    policyNumber: policyNumber,
    plate: plate,
    holderName: holderName,
    tier: tier,
    expiryIso: expiryIso ?? expiryLabel,
  );

  void _share() {
    final text =
        '''
🛡️ Póliza RCV – RuedaSeguro
━━━━━━━━━━━━━━━━━━━━━━━
N° de póliza: $policyNumber
Titular: $holderName ($idLabel)
Vehículo: $vehicleLabel
Placa: $plate
Plan: ${PolicyCardService.tierLabel(tier)}
Aseguradora: $carrierName
Vigente hasta: $expiryLabel
━━━━━━━━━━━━━━━━━━━━━━━
Verificado por RuedaSeguro · SUDEASEG
''';
    SharePlus.instance.share(ShareParams(text: text));
  }

  @override
  Widget build(BuildContext context) {
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
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Carnet Digital',
          style: RSTypography.titleLarge.copyWith(color: RSColors.primary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: RSColors.primary),
            onPressed: _share,
            tooltip: 'Compartir',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(RSSpacing.lg),
        child: Column(
          children: [
            // ── Digital card visual ───────────────────────────────
            _CarnetCard(
                  policyNumber: policyNumber,
                  plate: plate,
                  holderName: holderName,
                  idLabel: idLabel,
                  vehicleLabel: vehicleLabel,
                  tier: tier,
                  carrierName: carrierName,
                  expiryLabel: expiryLabel,
                  isProvisional: isProvisional,
                  qrData: _qrData,
                )
                .animate()
                .fadeIn(duration: 500.ms)
                .scale(begin: const Offset(0.97, 0.97), curve: Curves.easeOut),

            const SizedBox(height: RSSpacing.lg),

            // ── Instructions ──────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(RSSpacing.md),
              decoration: BoxDecoration(
                color: RSColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(RSRadius.md),
                border: Border.all(
                  color: RSColors.primary.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: RSColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: RSSpacing.sm),
                  Expanded(
                    child: Text(
                      'Muestra este QR al funcionario de tránsito. '
                      'También puedes compartir el carnet por WhatsApp o guardarlo.',
                      style: RSTypography.bodyMedium.copyWith(
                        color: RSColors.primary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate(delay: 200.ms).fadeIn(duration: 400.ms),

            const SizedBox(height: RSSpacing.lg),

            // ── Actions ──────────────────────────────────────────
            _ActionButton(
              icon: Icons.share_rounded,
              label: 'Compartir por WhatsApp / mensaje',
              onTap: _share,
            ).animate(delay: 300.ms).fadeIn(duration: 400.ms),

            const SizedBox(height: RSSpacing.sm),

            _ActionButton(
              icon: Icons.copy_rounded,
              label: 'Copiar número de póliza',
              onTap: () {
                Clipboard.setData(ClipboardData(text: policyNumber));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Número de póliza copiado al portapapeles'),
                  ),
                );
              },
            ).animate(delay: 350.ms).fadeIn(duration: 400.ms),

            const SizedBox(height: RSSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

// ─── Digital Card Visual ──────────────────────────────────────────

class _CarnetCard extends StatelessWidget {
  const _CarnetCard({
    required this.policyNumber,
    required this.plate,
    required this.holderName,
    required this.idLabel,
    required this.vehicleLabel,
    required this.tier,
    required this.carrierName,
    required this.expiryLabel,
    required this.isProvisional,
    required this.qrData,
  });

  final String policyNumber;
  final String plate;
  final String holderName;
  final String idLabel;
  final String vehicleLabel;
  final String tier;
  final String carrierName;
  final String expiryLabel;
  final bool isProvisional;
  final String qrData;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0A1B2A), Color(0xFF1A3A5C), Color(0xFF254F72)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(RSRadius.xl),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0A1B2A).withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(
              RSSpacing.lg,
              RSSpacing.lg,
              RSSpacing.lg,
              RSSpacing.md,
            ),
            child: Row(
              children: [
                // Logo area
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.shield_rounded,
                        color: Color(0xFFFF6A1A),
                        size: 16,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'RuedaSeguro',
                        style: RSTypography.bodyMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (isProvisional)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB300),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'PROVISIONAL',
                      style: RSTypography.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 9,
                        letterSpacing: 0.5,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: RSColors.success,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'ACTIVA',
                      style: RSTypography.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 9,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Plate — large centered
          Container(
            margin: const EdgeInsets.symmetric(horizontal: RSSpacing.lg),
            padding: const EdgeInsets.symmetric(vertical: RSSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(RSRadius.md),
            ),
            child: Center(
              child: Text(
                plate,
                style: RSTypography.mono.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0A1B2A),
                  letterSpacing: 4,
                ),
              ),
            ),
          ),

          const SizedBox(height: RSSpacing.md),

          // Info rows + QR side by side
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: RSSpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CarnetField(label: 'TITULAR', value: holderName),
                      const SizedBox(height: RSSpacing.sm),
                      _CarnetField(label: 'CÉDULA', value: idLabel),
                      const SizedBox(height: RSSpacing.sm),
                      _CarnetField(label: 'VEHÍCULO', value: vehicleLabel),
                      const SizedBox(height: RSSpacing.sm),
                      _CarnetField(
                        label: 'PLAN',
                        value: PolicyCardService.tierLabel(tier),
                      ),
                      const SizedBox(height: RSSpacing.sm),
                      _CarnetField(label: 'ASEGURADORA', value: carrierName),
                    ],
                  ),
                ),

                const SizedBox(width: RSSpacing.md),

                // Right: QR
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(RSRadius.sm),
                      ),
                      child: QrImageView(
                        data: qrData,
                        version: QrVersions.auto,
                        size: 110,
                        backgroundColor: Colors.white,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: Color(0xFF0A1B2A),
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: Color(0xFF0A1B2A),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Escanear para\nverificar',
                      style: RSTypography.caption.copyWith(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 9,
                        height: 1.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Footer
          Padding(
            padding: const EdgeInsets.all(RSSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'N° PÓLIZA',
                        style: RSTypography.caption.copyWith(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 9,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Text(
                        policyNumber,
                        style: RSTypography.mono.copyWith(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'VENCE',
                      style: RSTypography.caption.copyWith(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 9,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Text(
                      expiryLabel,
                      style: RSTypography.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CarnetField extends StatelessWidget {
  const _CarnetField({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: RSTypography.caption.copyWith(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 9,
            letterSpacing: 0.8,
          ),
        ),
        Text(
          value,
          style: RSTypography.bodyMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 12,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}

// ─── Action Button ────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(RSRadius.md),
      child: Container(
        padding: const EdgeInsets.all(RSSpacing.md),
        decoration: BoxDecoration(
          color: RSColors.surface,
          borderRadius: BorderRadius.circular(RSRadius.md),
          border: Border.all(color: RSColors.border, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: RSColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: RSColors.primary, size: 20),
            ),
            const SizedBox(width: RSSpacing.md),
            Expanded(
              child: Text(
                label,
                style: RSTypography.bodyMedium.copyWith(
                  color: RSColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: RSColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import 'package:ruedaseguro/core/data/mock_data.dart';
import 'package:ruedaseguro/core/services/supabase_service.dart';
import 'package:ruedaseguro/core/theme/colors.dart';
import 'package:ruedaseguro/core/theme/spacing.dart';
import 'package:ruedaseguro/core/theme/typography.dart';
import 'package:ruedaseguro/features/audit/data/audit_repository.dart';
import 'package:ruedaseguro/features/payment/data/payment_repository.dart';
import 'package:ruedaseguro/features/policy/data/carrier_api_client.dart';
import 'package:ruedaseguro/features/policy/data/policy_issuance_service.dart';
import 'package:ruedaseguro/features/policy/data/policy_repository.dart';
import 'package:ruedaseguro/shared/widgets/rs_button.dart';

enum _EmissionState { loading, success, confirmed, observed, rejected }

class EmissionScreen extends StatefulWidget {
  const EmissionScreen({super.key, this.payload});

  /// Keys expected in payload:
  ///   'plan'                — InsurancePlan
  ///   'paymentMethod'       — 'pago_movil_p2p' | 'bank_transfer'
  ///   'pagoMovilReference'  — String
  ///   'pagoMovilBankCode'   — String?
  ///   'amountUsd'           — double
  ///   'amountVes'           — double
  ///   'exchangeRate'        — double
  final Map<String, dynamic>? payload;

  @override
  State<EmissionScreen> createState() => _EmissionScreenState();
}

class _EmissionScreenState extends State<EmissionScreen> {
  _EmissionState _state = _EmissionState.loading;
  String? _policyId;
  String? _errorMessage;

  InsurancePlan get _plan =>
      (widget.payload?['plan'] as InsurancePlan?) ?? MockPlans.plus;

  @override
  void initState() {
    super.initState();
    _emit();
  }

  Future<void> _emit() async {
    final user = SupabaseService.auth.currentUser;

    // Demo mode — no real session
    if (user == null || widget.payload == null) {
      await Future.delayed(const Duration(milliseconds: 2800));
      if (mounted) setState(() => _state = _EmissionState.success);
      return;
    }

    try {
      final profileId = user.id;
      final amountUsd =
          (widget.payload!['amountUsd'] as num?)?.toDouble() ??
              _plan.priceUsd;
      final amountVes =
          (widget.payload!['amountVes'] as num?)?.toDouble() ?? 0.0;
      final exchangeRate =
          (widget.payload!['exchangeRate'] as num?)?.toDouble() ?? 0.0;
      final paymentMethod =
          widget.payload!['paymentMethod'] as String? ?? 'pago_movil_p2p';
      final reference =
          widget.payload!['pagoMovilReference'] as String?;
      final bankCode =
          widget.payload!['pagoMovilBankCode'] as String?;

      // Fetch vehicle
      final vehicleId =
          await PolicyRepository.instance.fetchVehicleId(profileId);
      if (vehicleId == null) throw Exception('Vehículo no registrado');
      final vehiclePlate =
          await PolicyRepository.instance.fetchVehiclePlate(vehicleId) ?? '';

      // Determine carrier — use plan.carrierId or fallback to seed carrier
      final carrierId = _plan.carrierId ??
          '11111111-1111-1111-1111-111111111111'; // Seguros Pirámide seed
      final policyTypeId = _plan.policyTypeId ?? _plan.id;

      // Create provisional policy (RS-054)
      final policyId = await PolicyRepository.instance.createPolicyRecord(
        profileId: profileId,
        vehicleId: vehicleId,
        carrierId: carrierId,
        policyTypeId: policyTypeId,
        priceUsd: amountUsd,
        priceVes: amountVes,
        exchangeRate: exchangeRate,
      );

      // Create payment record (RS-052)
      final paymentId = await PaymentRepository.instance.createPaymentRecord(
        policyId: policyId,
        profileId: profileId,
        amountUsd: amountUsd,
        amountVes: amountVes,
        exchangeRate: exchangeRate,
        method: paymentMethod,
        pagoMovilReference: reference,
        pagoMovilBankCode: bankCode,
      );

      // Emit audit events (RS-058)
      await AuditRepository.instance.logEvent(
        actorId: profileId,
        eventType: 'policy.provisional_created',
        targetId: policyId,
        targetTable: 'policies',
        payload: {'tier': _plan.tier, 'premium_usd': amountUsd},
      );
      await AuditRepository.instance.logEvent(
        actorId: profileId,
        eventType: 'payment.submitted',
        targetId: paymentId,
        targetTable: 'payments',
        payload: {
          'policy_id': policyId,
          'method': paymentMethod,
          'amount_usd': amountUsd,
        },
      );

      // RS-061: Attempt carrier API issuance (15 s budget; stays provisional on failure)
      final issuancePayload = CarrierSubmissionPayload(
        policyId: policyId,
        riderCedula: profileId, // real cedula fetched by service in Phase 1.5
        riderIdType: 'V',
        riderFullName: '',
        riderPhone: '',
        vehiclePlate: vehiclePlate,
        vehicleBrand: '',
        vehicleModel: '',
        vehicleYear: DateTime.now().year,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 365)),
        premiumUsd: amountUsd,
        productCode: _plan.tier,
      );

      final issuance = await PolicyIssuanceService.instance
          .attemptIssuance(
            policyId: policyId,
            profileId: profileId,
            payload: issuancePayload,
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => IssuanceResult.provisional(reason: 'timeout'),
          );

      if (mounted) {
        setState(() {
          _policyId = policyId;
          _state = issuance.isConfirmed
              ? _EmissionState.confirmed
              : _EmissionState.success;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _state = _EmissionState.rejected;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RSColors.background,
      appBar: _state == _EmissionState.loading
          ? null
          : AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: _state != _EmissionState.success
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: RSColors.primary),
                      onPressed: () => context.pop(),
                    )
                  : null,
              title: Text(
                _state == _EmissionState.confirmed
                    ? 'Póliza confirmada'
                    : _state == _EmissionState.success
                        ? 'Póliza registrada'
                        : _state == _EmissionState.observed
                            ? 'Requiere corrección'
                            : 'Error de emisión',
                style: RSTypography.titleLarge.copyWith(
                  color: (_state == _EmissionState.success ||
                          _state == _EmissionState.confirmed)
                      ? RSColors.success
                      : _state == _EmissionState.observed
                          ? const Color(0xFFE65100)
                          : RSColors.error,
                ),
              ),
            ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: switch (_state) {
          _EmissionState.loading =>
            _LoadingView(key: const ValueKey('loading'), plan: _plan),
          _EmissionState.confirmed => _SuccessView(
              key: const ValueKey('confirmed'),
              plan: _plan,
              policyId: _policyId,
              isConfirmed: true,
            ),
          _EmissionState.success => _SuccessView(
              key: const ValueKey('success'),
              plan: _plan,
              policyId: _policyId,
              isConfirmed: false,
            ),
          _EmissionState.observed =>
            _ObservedView(key: const ValueKey('observed')),
          _EmissionState.rejected => _RejectedView(
              key: const ValueKey('rejected'),
              errorMessage: _errorMessage,
            ),
        },
      ),
    );
  }
}

// ─── Loading View ─────────────────────────────────────────────────
class _LoadingView extends StatelessWidget {
  const _LoadingView({super.key, required this.plan});
  final InsurancePlan plan;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(RSSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: RSColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.description_outlined,
                color: RSColors.primary,
                size: 44,
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .fadeIn(duration: 600.ms)
                .then()
                .scaleXY(
                    end: 1.08,
                    duration: 800.ms,
                    curve: Curves.easeInOut),

            const SizedBox(height: RSSpacing.xl),

            Text(
              'Registrando tu póliza...',
              style: RSTypography.displayMedium.copyWith(
                color: RSColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ).animate(delay: 200.ms).fadeIn(duration: 400.ms),

            const SizedBox(height: RSSpacing.md),

            Text(
              'Estamos registrando tu solicitud de ${plan.name}.\nEsto toma unos segundos.',
              style: RSTypography.bodyLarge.copyWith(
                color: RSColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ).animate(delay: 400.ms).fadeIn(duration: 400.ms),

            const SizedBox(height: RSSpacing.xl),

            ...([
              'Verificando datos del vehículo',
              'Registrando póliza provisional',
              'Guardando referencia de pago',
              'Contactando a la aseguradora...',
            ]
                .asMap()
                .entries
                .map((e) => _StepRow(
                      label: e.value,
                      delay: Duration(milliseconds: 600 + e.key * 400),
                    ))),
          ],
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.label, required this.delay});
  final String label;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: RSSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: RSColors.primary,
            ),
          ),
          const SizedBox(width: RSSpacing.sm),
          Text(
            label,
            style:
                RSTypography.bodyMedium.copyWith(color: RSColors.textSecondary),
          ),
        ],
      ),
    ).animate(delay: delay).fadeIn(duration: 400.ms).slideX(begin: 0.1);
  }
}

// ─── Success View ─────────────────────────────────────────────────
class _SuccessView extends StatelessWidget {
  const _SuccessView({
    super.key,
    required this.plan,
    required this.policyId,
    this.isConfirmed = false,
  });
  final InsurancePlan plan;
  final String? policyId;
  final bool isConfirmed;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(RSSpacing.lg),
      child: Column(
        children: [
          const SizedBox(height: RSSpacing.xl),

          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2E7D32).withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Icons.verified_rounded,
                color: Colors.white, size: 48),
          )
              .animate()
              .scale(
                begin: const Offset(0.5, 0.5),
                duration: 600.ms,
                curve: Curves.elasticOut,
              )
              .fadeIn(duration: 300.ms),

          const SizedBox(height: RSSpacing.lg),

          Text(
            isConfirmed ? '¡Póliza confirmada!' : '¡Solicitud registrada!',
            style: RSTypography.displayLarge.copyWith(
              color: RSColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ).animate(delay: 300.ms).fadeIn(duration: 400.ms).slideY(begin: 0.2),

          const SizedBox(height: RSSpacing.sm),

          Text(
            isConfirmed
                ? 'Tu póliza fue registrada y confirmada por la aseguradora.\nYa tienes cobertura RCV activa.'
                : 'Tu póliza provisional está registrada.\nVerificaremos tu pago en menos de 24 horas y la activaremos.',
            style: RSTypography.bodyLarge.copyWith(
              color: RSColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ).animate(delay: 400.ms).fadeIn(duration: 400.ms),

          const SizedBox(height: RSSpacing.xl),

          _PolicyPreviewCard(plan: plan)
              .animate(delay: 500.ms)
              .fadeIn(duration: 500.ms)
              .slideY(begin: 0.1),

          const SizedBox(height: RSSpacing.xl),

          RSButton(
            label: 'Ver mi póliza',
            onPressed: () {
              if (policyId != null) {
                context.go('/policy/$policyId');
              } else {
                context.go('/home');
              }
            },
          ).animate(delay: 700.ms).fadeIn(duration: 400.ms).slideY(begin: 0.2),

          const SizedBox(height: RSSpacing.md),

          RSButton(
            label: 'Ir al inicio',
            variant: RSButtonVariant.secondary,
            onPressed: () => context.go('/home'),
          ).animate(delay: 800.ms).fadeIn(duration: 400.ms),

          const SizedBox(height: RSSpacing.xxl),
        ],
      ),
    );
  }
}

class _PolicyPreviewCard extends StatelessWidget {
  const _PolicyPreviewCard({required this.plan});
  final InsurancePlan plan;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(RSSpacing.lg),
      decoration: BoxDecoration(
        color: RSColors.primary,
        borderRadius: BorderRadius.circular(RSRadius.lg),
        boxShadow: [
          BoxShadow(
            color: RSColors.primary.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB300),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.hourglass_top_rounded,
                        color: Colors.white, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      'PROVISIONAL',
                      style: RSTypography.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                'Pago en verificación',
                style: RSTypography.caption.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: RSSpacing.md),
          Text(
            plan.name,
            style: RSTypography.titleLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '\$ ${plan.priceUsd.toStringAsFixed(2)} USD / año',
            style: RSTypography.mono.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: RSSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(RSSpacing.sm),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(RSRadius.sm),
            ),
            child: Text(
              'Activación en ≤ 24 h tras verificación del pago',
              style: RSTypography.caption.copyWith(
                color: Colors.white.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Observed View ────────────────────────────────────────────────
class _ObservedView extends StatelessWidget {
  const _ObservedView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(RSSpacing.lg),
      child: Column(
        children: [
          const SizedBox(height: RSSpacing.xl),
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: const Color(0xFFFFB300).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.warning_amber_rounded,
                color: Color(0xFFFFB300), size: 48),
          ).animate().scale(
                begin: const Offset(0.5, 0.5),
                duration: 500.ms,
                curve: Curves.elasticOut,
              ),
          const SizedBox(height: RSSpacing.lg),
          Text('Póliza observada',
                  style: RSTypography.displayMedium.copyWith(
                    color: RSColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center)
              .animate(delay: 200.ms)
              .fadeIn(),
          const SizedBox(height: RSSpacing.sm),
          Text(
            'La aseguradora requiere información adicional para completar la emisión.',
            style: RSTypography.bodyLarge.copyWith(
                color: RSColors.textSecondary, height: 1.5),
            textAlign: TextAlign.center,
          ).animate(delay: 300.ms).fadeIn(),
          const SizedBox(height: RSSpacing.xl),
          RSButton(
            label: 'Contactar soporte',
            onPressed: () {},
          ).animate(delay: 500.ms).fadeIn().slideY(begin: 0.2),
          const SizedBox(height: RSSpacing.xxl),
        ],
      ),
    );
  }
}

// ─── Rejected View ────────────────────────────────────────────────
class _RejectedView extends StatelessWidget {
  const _RejectedView({super.key, this.errorMessage});
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(RSSpacing.lg),
      child: Column(
        children: [
          const SizedBox(height: RSSpacing.xl),
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: RSColors.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.cancel_rounded, color: RSColors.error, size: 48),
          ).animate().scale(
                begin: const Offset(0.5, 0.5),
                duration: 500.ms,
                curve: Curves.elasticOut,
              ),
          const SizedBox(height: RSSpacing.lg),
          Text('Error al registrar',
                  style: RSTypography.displayMedium.copyWith(
                    color: RSColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center)
              .animate(delay: 200.ms)
              .fadeIn(),
          const SizedBox(height: RSSpacing.sm),
          Text(
            errorMessage ??
                'No pudimos registrar tu solicitud. Por favor intenta nuevamente.',
            style: RSTypography.bodyLarge.copyWith(
                color: RSColors.textSecondary, height: 1.5),
            textAlign: TextAlign.center,
          ).animate(delay: 300.ms).fadeIn(),
          const SizedBox(height: RSSpacing.xxl),
          RSButton(
            label: 'Intentar de nuevo',
            onPressed: () => context.pop(),
          ).animate(delay: 500.ms).fadeIn().slideY(begin: 0.2),
          const SizedBox(height: RSSpacing.md),
          RSButton(
            label: 'Hablar con soporte',
            variant: RSButtonVariant.secondary,
            onPressed: () {},
          ).animate(delay: 600.ms).fadeIn(),
          const SizedBox(height: RSSpacing.xxl),
        ],
      ),
    );
  }
}

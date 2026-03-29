import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ruedaseguro/core/data/mock_data.dart';
import 'package:ruedaseguro/core/theme/colors.dart';
import 'package:ruedaseguro/core/theme/spacing.dart';
import 'package:ruedaseguro/core/theme/typography.dart';
import 'package:ruedaseguro/shared/providers/bcv_rate_provider.dart';
import 'package:ruedaseguro/shared/widgets/rs_button.dart';
import 'package:ruedaseguro/shared/widgets/rs_card.dart';
import 'package:ruedaseguro/shared/widgets/rs_text_field.dart';

// Venezuelan banks for Pago Móvil
const _kBanks = [
  _Bank('0102', 'Banco de Venezuela'),
  _Bank('0104', 'Venezolano de Crédito'),
  _Bank('0105', 'Mercantil'),
  _Bank('0108', 'Banco Provincial'),
  _Bank('0114', 'Bancaribe'),
  _Bank('0115', 'Exterior'),
  _Bank('0128', 'Banco Caroní'),
  _Bank('0134', 'Banesco'),
  _Bank('0137', 'Sofitasa'),
  _Bank('0138', 'Banco Plaza'),
  _Bank('0146', 'Bangente'),
  _Bank('0151', 'BFC Banco Fondo Común'),
  _Bank('0156', '100% Banco'),
  _Bank('0157', 'DELSUR'),
  _Bank('0163', 'Banco del Tesoro'),
  _Bank('0166', 'Banco Agrícola de Venezuela'),
  _Bank('0168', 'Bancrecer'),
  _Bank('0169', 'Mi Banco'),
  _Bank('0171', 'Activo'),
  _Bank('0172', 'Bancamiga'),
  _Bank('0174', 'Banplus'),
  _Bank('0175', 'Bicentenario del Pueblo'),
  _Bank('0177', 'Banfanb'),
  _Bank('0191', 'BNC Nacional de Crédito'),
];

class _Bank {
  const _Bank(this.code, this.name);
  final String code;
  final String name;
}

class PaymentMethodScreen extends ConsumerStatefulWidget {
  const PaymentMethodScreen({super.key, this.plan});

  final InsurancePlan? plan;

  @override
  ConsumerState<PaymentMethodScreen> createState() =>
      _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends ConsumerState<PaymentMethodScreen> {
  int _selectedMethod = 0; // 0: Pago Móvil, 1: Transferencia
  _Bank? _selectedBank;
  final _referenceCtrl = TextEditingController();
  bool _isSubmitting = false;

  InsurancePlan get _plan => widget.plan ?? MockPlans.plus;

  @override
  void dispose() {
    _referenceCtrl.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    if (_selectedMethod == 0) {
      return _selectedBank != null && _referenceCtrl.text.trim().length >= 6;
    }
    return _referenceCtrl.text.trim().length >= 6;
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() => _isSubmitting = true);

    final bcvRate = ref.read(bcvRateProvider).when(
          data: (r) => r,
          error: (_, __) => BcvRate.fallback,
          loading: () => BcvRate.fallback,
        );

    final extra = {
      'plan': _plan,
      'paymentMethod':
          _selectedMethod == 0 ? 'pago_movil_p2p' : 'bank_transfer',
      'pagoMovilReference': _referenceCtrl.text.trim(),
      'pagoMovilBankCode': _selectedBank?.code,
      'amountUsd': _plan.priceUsd,
      'amountVes': bcvRate.toVes(_plan.priceUsd),
      'exchangeRate': bcvRate.rate,
    };

    if (mounted) {
      context.push('/policy/emission', extra: extra);
    }
    setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final bcvRate = ref.watch(bcvRateProvider).when(
          data: (r) => r,
          error: (_, __) => BcvRate.fallback,
          loading: () => BcvRate.fallback,
        );
    final vesPrice = bcvRate.toVes(_plan.priceUsd);

    return Scaffold(
      backgroundColor: RSColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: RSColors.primary),
          onPressed: () => context.pop(),
        ),
        title: Text('Método de pago',
            style:
                RSTypography.titleLarge.copyWith(color: RSColors.primary)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(RSSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AmountSummary(
              plan: _plan,
              vesPrice: vesPrice,
              isStale: bcvRate.stale,
            ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.05),

            const SizedBox(height: RSSpacing.lg),

            Text('Selecciona el método de pago',
                    style: RSTypography.titleLarge
                        .copyWith(color: RSColors.textPrimary))
                .animate(delay: 100.ms)
                .fadeIn(duration: 400.ms),
            const SizedBox(height: RSSpacing.md),

            _MethodOption(
              index: 0,
              selectedIndex: _selectedMethod,
              icon: Icons.phone_android_rounded,
              title: 'Pago Móvil',
              subtitle: 'Transferencia inmediata desde tu banco',
              onTap: () => setState(() => _selectedMethod = 0),
            ).animate(delay: 150.ms).fadeIn(duration: 400.ms),

            const SizedBox(height: RSSpacing.sm),

            _MethodOption(
              index: 1,
              selectedIndex: _selectedMethod,
              icon: Icons.account_balance_rounded,
              title: 'Transferencia bancaria',
              subtitle: 'Depósito o transferencia a cuenta bancaria',
              onTap: () => setState(() => _selectedMethod = 1),
            ).animate(delay: 200.ms).fadeIn(duration: 400.ms),

            const SizedBox(height: RSSpacing.lg),

            // Method-specific details + form
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _selectedMethod == 0
                  ? _PagoMovilSection(
                      key: const ValueKey(0),
                      selectedBank: _selectedBank,
                      onBankChanged: (b) =>
                          setState(() => _selectedBank = b),
                      referenceCtrl: _referenceCtrl,
                      onReferenceChanged: (_) => setState(() {}),
                    )
                  : _BankTransferSection(
                      key: const ValueKey(1),
                      referenceCtrl: _referenceCtrl,
                      onReferenceChanged: (_) => setState(() {}),
                    ),
            ).animate(delay: 250.ms).fadeIn(duration: 400.ms),

            const SizedBox(height: RSSpacing.xl),

            RSButton(
              label: 'Confirmar pago',
              isLoading: _isSubmitting,
              onPressed: _canSubmit && !_isSubmitting ? _submit : null,
            ).animate(delay: 400.ms).fadeIn(duration: 400.ms).slideY(begin: 0.2),

            const SizedBox(height: RSSpacing.md),

            Center(
              child: Text(
                'Tu pago será verificado en menos de 24 horas',
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

// ─── Amount Summary ──────────────────────────────────────────────
class _AmountSummary extends StatelessWidget {
  const _AmountSummary({
    required this.plan,
    required this.vesPrice,
    required this.isStale,
  });
  final InsurancePlan plan;
  final double vesPrice;
  final bool isStale;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(RSSpacing.lg),
      decoration: BoxDecoration(
        color: RSColors.primary,
        borderRadius: BorderRadius.circular(RSRadius.lg),
      ),
      child: Column(
        children: [
          Text('Total a pagar',
              style: RSTypography.bodyMedium.copyWith(
                color: Colors.white.withValues(alpha: 0.7),
              )),
          const SizedBox(height: RSSpacing.sm),
          Text(
            '\$ ${plan.priceUsd.toStringAsFixed(2)} USD',
            style: RSTypography.displayLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 36,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Bs. ${vesPrice.toStringAsFixed(2)} (Tasa BCV${isStale ? ' aprox.' : ''})',
                style: RSTypography.bodyMedium.copyWith(
                  color: Colors.white.withValues(alpha: isStale ? 0.5 : 0.6),
                ),
              ),
              if (isStale) ...[
                const SizedBox(width: 4),
                Icon(Icons.info_outline_rounded,
                    size: 14,
                    color: Colors.white.withValues(alpha: 0.5)),
              ],
            ],
          ),
          const SizedBox(height: RSSpacing.md),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              plan.name,
              style: RSTypography.bodyMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Method Option ───────────────────────────────────────────────
class _MethodOption extends StatelessWidget {
  const _MethodOption({
    required this.index,
    required this.selectedIndex,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final int index;
  final int selectedIndex;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  bool get _isSelected => index == selectedIndex;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(RSSpacing.md),
        decoration: BoxDecoration(
          color: _isSelected
              ? RSColors.primary.withValues(alpha: 0.05)
              : RSColors.surface,
          borderRadius: BorderRadius.circular(RSRadius.md),
          border: Border.all(
            color: _isSelected ? RSColors.primary : RSColors.border,
            width: _isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _isSelected
                    ? RSColors.primary.withValues(alpha: 0.1)
                    : RSColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon,
                  color:
                      _isSelected ? RSColors.primary : RSColors.textSecondary,
                  size: 22),
            ),
            const SizedBox(width: RSSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: RSTypography.titleMedium.copyWith(
                          color: RSColors.textPrimary,
                          fontWeight: FontWeight.w600)),
                  Text(subtitle,
                      style: RSTypography.caption
                          .copyWith(color: RSColors.textSecondary)),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _isSelected ? RSColors.primary : RSColors.border,
                  width: 2,
                ),
                color:
                    _isSelected ? RSColors.primary : Colors.transparent,
              ),
              child: _isSelected
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 14)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Pago Móvil section ──────────────────────────────────────────
class _PagoMovilSection extends StatelessWidget {
  const _PagoMovilSection({
    super.key,
    required this.selectedBank,
    required this.onBankChanged,
    required this.referenceCtrl,
    required this.onReferenceChanged,
  });

  final _Bank? selectedBank;
  final ValueChanged<_Bank?> onBankChanged;
  final TextEditingController referenceCtrl;
  final ValueChanged<String> onReferenceChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RSCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Datos para Pago Móvil',
                  style: RSTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: RSColors.textPrimary,
                  )),
              const SizedBox(height: RSSpacing.md),
              _BankDataRow(label: 'Teléfono', value: '0424-1234567'),
              const Divider(height: RSSpacing.lg),
              _BankDataRow(label: 'Banco', value: 'Banesco'),
              const Divider(height: RSSpacing.lg),
              _BankDataRow(label: 'RIF / Cédula', value: 'J-40123456-7'),
              const Divider(height: RSSpacing.lg),
              _BankDataRow(label: 'Concepto', value: 'RUEDASEGURO-RCV'),
              const SizedBox(height: RSSpacing.sm),
              Container(
                padding: const EdgeInsets.all(RSSpacing.sm),
                decoration: BoxDecoration(
                  color: RSColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(RSRadius.sm),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outlined,
                        color: RSColors.warning, size: 16),
                    const SizedBox(width: RSSpacing.sm),
                    Expanded(
                      child: Text(
                        'Incluye "RUEDASEGURO-RCV" como concepto del pago',
                        style: RSTypography.caption
                            .copyWith(color: RSColors.warning),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: RSSpacing.lg),
        Text('Confirma tu pago',
            style: RSTypography.titleLarge
                .copyWith(color: RSColors.textPrimary)),
        const SizedBox(height: RSSpacing.md),
        // Bank selector
        Container(
          decoration: BoxDecoration(
            color: RSColors.surface,
            borderRadius: BorderRadius.circular(RSRadius.md),
            border: Border.all(color: RSColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<_Bank>(
              value: selectedBank,
              isExpanded: true,
              hint: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: RSSpacing.md),
                child: Text('Selecciona tu banco',
                    style: RSTypography.bodyMedium
                        .copyWith(color: RSColors.textSecondary)),
              ),
              dropdownColor: RSColors.surface,
              items: _kBanks
                  .map((b) => DropdownMenuItem(
                        value: b,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: RSSpacing.md),
                          child: Text('${b.code} — ${b.name}',
                              style: RSTypography.bodyMedium
                                  .copyWith(color: RSColors.textPrimary)),
                        ),
                      ))
                  .toList(),
              onChanged: onBankChanged,
            ),
          ),
        ),
        const SizedBox(height: RSSpacing.md),
        RSTextField(
          label: 'Número de referencia',
          hint: 'Ej: 00123456789',
          controller: referenceCtrl,
          onChanged: onReferenceChanged,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
      ],
    );
  }
}

// ─── Bank Transfer section ───────────────────────────────────────
class _BankTransferSection extends StatelessWidget {
  const _BankTransferSection({
    super.key,
    required this.referenceCtrl,
    required this.onReferenceChanged,
  });

  final TextEditingController referenceCtrl;
  final ValueChanged<String> onReferenceChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RSCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Datos de cuenta bancaria',
                  style: RSTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: RSColors.textPrimary,
                  )),
              const SizedBox(height: RSSpacing.md),
              _BankDataRow(label: 'Banco', value: 'Banco Provincial'),
              const Divider(height: RSSpacing.lg),
              _BankDataRow(
                  label: 'Cuenta corriente',
                  value: '0108-0000-12-0012345678'),
              const Divider(height: RSSpacing.lg),
              _BankDataRow(label: 'Beneficiario', value: 'AZ Capital C.A.'),
              const Divider(height: RSSpacing.lg),
              _BankDataRow(label: 'RIF', value: 'J-40123456-7'),
            ],
          ),
        ),
        const SizedBox(height: RSSpacing.lg),
        Text('Confirma tu pago',
            style: RSTypography.titleLarge
                .copyWith(color: RSColors.textPrimary)),
        const SizedBox(height: RSSpacing.md),
        RSTextField(
          label: 'Número de referencia',
          hint: 'Número de operación bancaria',
          controller: referenceCtrl,
          onChanged: onReferenceChanged,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
      ],
    );
  }
}

class _BankDataRow extends StatelessWidget {
  const _BankDataRow({required this.label, required this.value});
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
        Text(value,
            style: RSTypography.mono.copyWith(
              fontSize: 13,
              color: RSColors.textPrimary,
              fontWeight: FontWeight.w600,
            )),
      ],
    );
  }
}

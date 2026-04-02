import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:ruedaseguro/core/theme/colors.dart';
import 'package:ruedaseguro/core/theme/spacing.dart';
import 'package:ruedaseguro/core/theme/typography.dart';
import 'package:ruedaseguro/features/onboarding/domain/onboarding_state.dart';
import 'package:ruedaseguro/shared/widgets/rs_button.dart';
import 'package:ruedaseguro/shared/widgets/rs_text_field.dart';

class LicenciaConfirmScreen extends ConsumerStatefulWidget {
  const LicenciaConfirmScreen({super.key});

  @override
  ConsumerState<LicenciaConfirmScreen> createState() =>
      _LicenciaConfirmScreenState();
}

class _LicenciaConfirmScreenState extends ConsumerState<LicenciaConfirmScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _licNumCtrl;
  late final TextEditingController _expiryCtrl;

  String? _bloodType;
  DateTime? _selectedExpiry;
  final Set<String> _selectedCategories = {};

  static const _allGrados = ['1°', '2°', '3°', '4°', '5°'];
  static const _gradoLabels = {
    '1°': 'Motos',
    '2°': 'Autos',
    '3°': 'Medianos',
    '4°': 'Pesados',
    '5°': 'Especiales',
  };

  @override
  void initState() {
    super.initState();
    // DEPRECATED: licencia step removed in Sprint 4A — fields stubbed to compile
    _licNumCtrl = TextEditingController(text: '');
    _selectedExpiry = null;
    _expiryCtrl = TextEditingController(text: '');
    _bloodType = null;
  }

  @override
  void dispose() {
    _licNumCtrl.dispose();
    _expiryCtrl.dispose();
    super.dispose();
  }

  double _fieldConf(String field) => 0.0; // deprecated

  Future<void> _pickExpiry() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedExpiry ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime(2000),
      lastDate: DateTime(2040),
      locale: const Locale('es'),
    );
    if (picked != null) {
      setState(() {
        _selectedExpiry = picked;
        _expiryCtrl.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    // Deprecated — this screen is unreachable in Sprint 4A router
    context.push('/onboarding/certificado');
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(onboardingProvider);
    final isExpired =
        _selectedExpiry != null && _selectedExpiry!.isBefore(DateTime.now());

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
        title: Text('Confirma tu licencia',
            style: RSTypography.titleLarge.copyWith(color: RSColors.primary)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(RSSpacing.lg),
          children: [
            // Deprecated — no image in Sprint 4A licencia path

            const SizedBox(height: RSSpacing.lg),
            Text('Verifica la información de tu licencia',
                style: RSTypography.bodyMedium
                    .copyWith(color: RSColors.textSecondary)),
            const SizedBox(height: RSSpacing.lg),

            // License number
            _ConfField(
              label: 'Número de licencia',
              controller: _licNumCtrl,
              confidence: _fieldConf('licenciaNumber'),
              keyboardType: TextInputType.text,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Requerido';
                return null;
              },
            ),
            const SizedBox(height: RSSpacing.lg),

            // Categories (grados)
            Text('Grados autorizados',
                style: RSTypography.bodyMedium
                    .copyWith(color: RSColors.textSecondary)),
            const SizedBox(height: RSSpacing.sm),
            Wrap(
              spacing: RSSpacing.sm,
              runSpacing: RSSpacing.sm,
              children: _allGrados.map((grado) {
                final selected = _selectedCategories.contains(grado);
                return FilterChip(
                  label: Text('$grado ${_gradoLabels[grado] ?? ''}'),
                  selected: selected,
                  onSelected: (v) {
                    setState(() {
                      if (v) {
                        _selectedCategories.add(grado);
                      } else {
                        _selectedCategories.remove(grado);
                      }
                    });
                  },
                  selectedColor: RSColors.primary.withValues(alpha: 0.15),
                  checkmarkColor: RSColors.primary,
                  labelStyle: RSTypography.bodyMedium.copyWith(
                    color: selected ? RSColors.primary : RSColors.textPrimary,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(RSRadius.md),
                    side: BorderSide(
                      color: selected ? RSColors.primary : RSColors.border,
                    ),
                  ),
                );
              }).toList(),
            ),
            if (_selectedCategories.isNotEmpty && !_selectedCategories.any((c) => c.contains('1'))) ...[
              const SizedBox(height: RSSpacing.sm),
              Container(
                padding: const EdgeInsets.all(RSSpacing.sm),
                decoration: BoxDecoration(
                  color: RSColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(RSRadius.sm),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        size: 18, color: RSColors.warning),
                    const SizedBox(width: RSSpacing.sm),
                    Expanded(
                      child: Text(
                        'Se requiere el 1° grado para conducir motocicletas',
                        style: RSTypography.caption
                            .copyWith(color: RSColors.warning),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: RSSpacing.lg),

            // Expiry date
            RSTextField(
              label: 'Fecha de vencimiento',
              controller: _expiryCtrl,
              readOnly: true,
              suffixIcon:
                  const Icon(Icons.calendar_today, color: RSColors.primary),
              onTap: _pickExpiry,
            ),
            if (isExpired) ...[
              const SizedBox(height: RSSpacing.sm),
              Container(
                padding: const EdgeInsets.all(RSSpacing.sm),
                decoration: BoxDecoration(
                  color: RSColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(RSRadius.sm),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        size: 18, color: RSColors.error),
                    const SizedBox(width: RSSpacing.sm),
                    Expanded(
                      child: Text(
                        'Tu licencia está vencida. Podrás continuar pero deberás renovarla.',
                        style: RSTypography.caption
                            .copyWith(color: RSColors.error),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: RSSpacing.lg),

            // Blood type
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tipo de sangre (opcional)',
                    style: RSTypography.bodyMedium
                        .copyWith(color: RSColors.textSecondary)),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  value: _bloodType,
                  hint: const Text('Seleccionar'),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: RSSpacing.md, vertical: RSSpacing.md),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(RSRadius.md),
                      borderSide: const BorderSide(color: RSColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(RSRadius.md),
                      borderSide: const BorderSide(color: RSColors.border),
                    ),
                    filled: true,
                    fillColor: RSColors.surface,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'A+', child: Text('A+')),
                    DropdownMenuItem(value: 'A-', child: Text('A-')),
                    DropdownMenuItem(value: 'B+', child: Text('B+')),
                    DropdownMenuItem(value: 'B-', child: Text('B-')),
                    DropdownMenuItem(value: 'AB+', child: Text('AB+')),
                    DropdownMenuItem(value: 'AB-', child: Text('AB-')),
                    DropdownMenuItem(value: 'O+', child: Text('O+')),
                    DropdownMenuItem(value: 'O-', child: Text('O-')),
                  ],
                  onChanged: (v) => setState(() => _bloodType = v),
                ),
              ],
            ),

            const SizedBox(height: RSSpacing.xxl),

            RSButton(label: 'Continuar', onPressed: _submit),
            const SizedBox(height: RSSpacing.xl),
          ],
        ),
      ),
    );
  }
}

class _ConfField extends StatelessWidget {
  const _ConfField({
    required this.label,
    required this.controller,
    required this.confidence,
    this.keyboardType,
    this.validator,
  });

  final String label;
  final TextEditingController controller;
  final double confidence;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    final isAmber = confidence > 0 && confidence < 0.9;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RSTextField(
          label: label,
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          borderColor: isAmber ? RSColors.warning : null,
        ),
        if (isAmber)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              'Verifica este campo',
              style: RSTypography.caption.copyWith(color: RSColors.warning),
            ),
          ),
      ],
    );
  }
}

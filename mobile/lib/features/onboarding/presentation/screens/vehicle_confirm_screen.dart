import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ruedaseguro/core/theme/colors.dart';
import 'package:ruedaseguro/core/theme/spacing.dart';
import 'package:ruedaseguro/core/theme/typography.dart';
import 'package:ruedaseguro/core/utils/validators.dart';
import 'package:ruedaseguro/features/onboarding/domain/onboarding_state.dart';
import 'package:ruedaseguro/shared/widgets/rs_button.dart';
import 'package:ruedaseguro/shared/widgets/rs_text_field.dart';

class VehicleConfirmScreen extends ConsumerStatefulWidget {
  const VehicleConfirmScreen({super.key, this.ocrData});
  final Map<String, dynamic>? ocrData;

  @override
  ConsumerState<VehicleConfirmScreen> createState() => _VehicleConfirmScreenState();
}

class _VehicleConfirmScreenState extends ConsumerState<VehicleConfirmScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _plateCtrl;
  late final TextEditingController _brandCtrl;
  late final TextEditingController _modelCtrl;
  late final TextEditingController _yearCtrl;
  late final TextEditingController _colorCtrl;
  late final TextEditingController _serialMotorCtrl;
  late final TextEditingController _serialCarrCtrl;

  String _vehicleUse = 'particular';
  bool _isLegalRepresentative = false;

  @override
  void initState() {
    super.initState();
    final data = ref.read(onboardingProvider);
    _plateCtrl = TextEditingController(text: data.plate ?? '');
    _brandCtrl = TextEditingController(text: data.brand ?? '');
    _modelCtrl = TextEditingController(text: data.model ?? '');
    _yearCtrl = TextEditingController(text: data.year?.toString() ?? '');
    _colorCtrl = TextEditingController(text: data.color ?? '');
    _serialMotorCtrl = TextEditingController(text: data.serialMotor ?? '');
    _serialCarrCtrl = TextEditingController(text: data.serialCarroceria ?? '');
    _vehicleUse = data.vehicleUse ?? 'particular';
  }

  @override
  void dispose() {
    _plateCtrl.dispose();
    _brandCtrl.dispose();
    _modelCtrl.dispose();
    _yearCtrl.dispose();
    _colorCtrl.dispose();
    _serialMotorCtrl.dispose();
    _serialCarrCtrl.dispose();
    super.dispose();
  }

  double _fieldConf(String f) =>
      ref.read(onboardingProvider).carnetOcr?.fieldConfidences[f] ?? 0.0;

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final cross = ref.read(onboardingProvider).crossValidation;
    ref.read(onboardingProvider.notifier).confirmVehicle(
      plate: _plateCtrl.text.trim().toUpperCase(),
      brand: _brandCtrl.text.trim(),
      model: _modelCtrl.text.trim(),
      year: int.tryParse(_yearCtrl.text.trim()) ?? DateTime.now().year,
      color: _colorCtrl.text.trim().isEmpty ? null : _colorCtrl.text.trim(),
      vehicleUse: _vehicleUse,
      serialMotor: _serialMotorCtrl.text.trim().isEmpty
          ? null
          : _serialMotorCtrl.text.trim(),
      serialCarroceria: _serialCarrCtrl.text.trim().isEmpty
          ? null
          : _serialCarrCtrl.text.trim(),
      crossValidation: cross,
      isLegalRepresentative: _isLegalRepresentative,
    );
    context.push('/onboarding/vehicle-photo');
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(onboardingProvider);
    final cross = data.crossValidation;
    final hasMismatch = cross != null && !cross.overallMatch && !cross.skipped;

    return Scaffold(
      backgroundColor: RSColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: RSColors.primary),
          onPressed: () => context.pop(),
        ),
        title: Text('Confirma los datos de tu moto',
            style: RSTypography.titleLarge.copyWith(color: RSColors.primary)),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(RSSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            // Carnet thumbnail
            if (data.carnetImage != null)
              GestureDetector(
                onTap: () => showDialog(
                  context: context,
                  builder: (_) => Dialog(
                      child: Image.file(data.carnetImage!, fit: BoxFit.contain)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(RSRadius.md),
                  child: Image.file(
                    data.carnetImage!,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

            const SizedBox(height: RSSpacing.lg),

            // Cross-validation result
            if (cross != null && !cross.skipped) ...[
              Container(
                padding: const EdgeInsets.all(RSSpacing.md),
                decoration: BoxDecoration(
                  color: hasMismatch
                      ? RSColors.error.withValues(alpha: 0.1)
                      : RSColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(RSRadius.md),
                  border: Border.all(
                    color: hasMismatch ? RSColors.error : RSColors.success,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          hasMismatch
                              ? Icons.warning_amber_rounded
                              : Icons.verified_rounded,
                          color: hasMismatch ? RSColors.error : RSColors.success,
                        ),
                        const SizedBox(width: RSSpacing.sm),
                        Expanded(
                          child: Text(
                            hasMismatch
                                ? 'El nombre del propietario no coincide con la cédula'
                                : 'Datos verificados',
                            style: RSTypography.bodyLarge.copyWith(
                              color: hasMismatch ? RSColors.error : RSColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (hasMismatch) ...[
                      const SizedBox(height: RSSpacing.md),
                      RSButton(
                        label: 'Subir nueva cédula',
                        variant: RSButtonVariant.secondary,
                        onPressed: () =>
                            context.go('/onboarding/cedula'),
                        isFullWidth: false,
                      ),
                      const SizedBox(height: RSSpacing.sm),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Soy representante legal del propietario',
                          style: RSTypography.bodyMedium,
                        ),
                        value: _isLegalRepresentative,
                        onChanged: (v) =>
                            setState(() => _isLegalRepresentative = v!),
                        activeColor: RSColors.primary,
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: RSSpacing.lg),
            ],

            // Vehicle fields
            _ConfField(
              label: 'Placa',
              controller: _plateCtrl,
              confidence: _fieldConf('plate'),
              textCapitalization: TextCapitalization.characters,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Requerido';
                if (!Validators.isValidPlate(v.trim())) return 'Formato de placa inválido';
                return null;
              },
            ),
            const SizedBox(height: RSSpacing.md),
            _ConfField(
              label: 'Marca',
              controller: _brandCtrl,
              confidence: _fieldConf('brand'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Requerido' : null,
            ),
            const SizedBox(height: RSSpacing.md),
            _ConfField(
              label: 'Modelo',
              controller: _modelCtrl,
              confidence: _fieldConf('model'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Requerido' : null,
            ),
            const SizedBox(height: RSSpacing.md),
            _ConfField(
              label: 'Año',
              controller: _yearCtrl,
              confidence: _fieldConf('year'),
              keyboardType: TextInputType.number,
              validator: (v) {
                final y = int.tryParse(v ?? '');
                if (y == null) return 'Requerido';
                if (y < 1980 || y > DateTime.now().year + 1) return 'Año inválido';
                return null;
              },
            ),
            const SizedBox(height: RSSpacing.md),
            RSTextField(label: 'Color (opcional)', controller: _colorCtrl),
            const SizedBox(height: RSSpacing.md),

            // Vehicle use
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Uso del vehículo',
                    style: RSTypography.bodyMedium.copyWith(color: RSColors.textSecondary)),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  value: _vehicleUse,
                  isExpanded: true,
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
                    DropdownMenuItem(value: 'particular', child: Text('Particular')),
                    DropdownMenuItem(value: 'cargo', child: Text('Carga / Comercial')),
                  ],
                  onChanged: (v) => setState(() => _vehicleUse = v!),
                ),
              ],
            ),
            const SizedBox(height: RSSpacing.md),
            RSTextField(
              label: 'Serial del motor (opcional)',
              controller: _serialMotorCtrl,
            ),
            const SizedBox(height: RSSpacing.md),
            RSTextField(
              label: 'Serial de carrocería (opcional)',
              controller: _serialCarrCtrl,
            ),

            const SizedBox(height: RSSpacing.xxl),

            RSButton(
              label: 'Continuar',
              onPressed: (hasMismatch && !_isLegalRepresentative) ? null : _submit,
            ),
            const SizedBox(height: RSSpacing.xl),
          ],
          ),
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
    this.textCapitalization = TextCapitalization.none,
    this.validator,
  });

  final String label;
  final TextEditingController controller;
  final double confidence;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
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
          textCapitalization: textCapitalization,
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

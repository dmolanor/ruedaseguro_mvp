import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ruedaseguro/core/theme/colors.dart';
import 'package:ruedaseguro/core/theme/spacing.dart';
import 'package:ruedaseguro/core/theme/typography.dart';
import 'package:ruedaseguro/core/utils/validators.dart';
import 'package:ruedaseguro/features/onboarding/domain/onboarding_state.dart';
import 'package:ruedaseguro/shared/widgets/rs_button.dart';
import 'package:ruedaseguro/shared/widgets/rs_text_field.dart';

// ---------------------------------------------------------------------------
// Vehicle body types available in Venezuelan INTT certificates
const _bodyTypes = [
  'DEPORTIVA',
  'SCOOTER',
  'PASEO',
  'DOBLE PROPÓSITO',
  'CARGA',
  'ELÉCTRICA',
  'CHOPPER',
];

// ---------------------------------------------------------------------------
// Async provider: loads vehicle_brands.json from assets
// Returns Map<brandName, List<models>>
final _brandsProvider = FutureProvider<Map<String, List<String>>>((ref) async {
  try {
    final raw =
        await rootBundle.loadString('assets/data/vehicle_brands.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final brands = (json['brands'] as List).cast<Map<String, dynamic>>();
    return {
      for (final b in brands)
        b['name'] as String: (b['models'] as List).cast<String>(),
    };
  } on Exception {
    return {};
  }
});

// ---------------------------------------------------------------------------

/// RS-074/081/083 — Step 2b: Confirm Certificado de Circulación data.
///
/// Features:
/// - Cross-validation banner (name + cédula match, vehicle type check)
/// - RS-081: 3-tier OCR confidence indicator per field
///   (🟢 ≥0.90, 🟡 0.75–0.89, 🔴 <0.75)
/// - RS-083: Brand dropdown + model dropdown filtered by brand + body type chips
/// - Year picker (scroll wheel)
/// - Plate real-time regex validation (RS-104 preview)
class CertificadoConfirmScreen extends ConsumerStatefulWidget {
  const CertificadoConfirmScreen({super.key, this.ocrData});
  final Map<String, dynamic>? ocrData;

  @override
  ConsumerState<CertificadoConfirmScreen> createState() =>
      _CertificadoConfirmScreenState();
}

class _CertificadoConfirmScreenState
    extends ConsumerState<CertificadoConfirmScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _plateCtrl;
  late final TextEditingController _serialNivCtrl;
  late final TextEditingController _serialMotorCtrl;

  String? _selectedBrand;
  String? _selectedModel;
  String? _selectedBodyType;
  String _vehicleUse = 'particular';
  int _selectedYear = DateTime.now().year;
  int? _seats;
  bool _isLegalRepresentative = false;

  @override
  void initState() {
    super.initState();
    final data = ref.read(onboardingProvider);
    _plateCtrl = TextEditingController(text: data.plate ?? '');
    _serialNivCtrl = TextEditingController(text: data.serialNiv ?? '');
    _serialMotorCtrl = TextEditingController(text: data.serialMotor ?? '');
    _selectedBrand = data.brand;
    _selectedModel = data.model;
    _selectedBodyType = data.vehicleBodyType;
    _vehicleUse = data.vehicleUse ?? 'particular';
    _selectedYear = data.year ?? DateTime.now().year;
    _seats = data.seats;
    if (data.vehicleType?.contains('CARGA') ?? false) {
      _vehicleUse = 'cargo';
    }
  }

  @override
  void dispose() {
    _plateCtrl.dispose();
    _serialNivCtrl.dispose();
    _serialMotorCtrl.dispose();
    super.dispose();
  }

  double _fieldConf(String f) =>
      ref.read(onboardingProvider).certificadoOcr?.fieldConfidences[f] ?? 0.0;

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final cross = ref.read(onboardingProvider).crossValidation;
    ref.read(onboardingProvider.notifier).confirmVehicle(
          plate: _plateCtrl.text.trim().toUpperCase(),
          brand: _selectedBrand ?? '',
          model: _selectedModel ?? '',
          year: _selectedYear,
          vehicleType: _vehicleUse == 'cargo' ? 'MOTO CARGA' : 'MOTO PARTICULAR',
          vehicleBodyType: _selectedBodyType,
          vehicleUse: _vehicleUse,
          serialNiv: _serialNivCtrl.text.trim().isEmpty
              ? null
              : _serialNivCtrl.text.trim().toUpperCase(),
          serialMotor: _serialMotorCtrl.text.trim().isEmpty
              ? null
              : _serialMotorCtrl.text.trim().toUpperCase(),
          seats: _seats,
          crossValidation: cross,
          isLegalRepresentative: _isLegalRepresentative,
        );
    context.push('/onboarding/address');
  }

  Future<void> _pickYear() async {
    final now = DateTime.now().year;
    final years = List.generate(now - 1979, (i) => now - i);
    final picked = await showDialog<int>(
      context: context,
      builder: (ctx) => _YearPickerDialog(
        years: years,
        selected: _selectedYear,
      ),
    );
    if (picked != null) setState(() => _selectedYear = picked);
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(onboardingProvider);
    final cross = data.crossValidation;
    final hasMismatch = cross != null && !cross.overallMatch;
    final vehicleTypeWrong = cross != null && !cross.vehicleTypeOk;

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
        title: Text('Confirma los datos del vehículo',
            style:
                RSTypography.titleLarge.copyWith(color: RSColors.primary)),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(RSSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Certificado thumbnail
              if (data.certificadoImage != null)
                GestureDetector(
                  onTap: () => showDialog(
                    context: context,
                    builder: (_) => Dialog(
                        child: Image.file(data.certificadoImage!,
                            fit: BoxFit.contain)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(RSRadius.md),
                    child: Image.file(
                      data.certificadoImage!,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

              const SizedBox(height: RSSpacing.lg),

              // Vehicle type warning — blocks submission
              if (vehicleTypeWrong) ...[
                _AlertBanner(
                  icon: Icons.block,
                  color: RSColors.error,
                  message:
                      'El documento parece no corresponder a una motocicleta '
                      '("${data.certificadoOcr?.vehicleType ?? ""}"). '
                      'Solo se pueden asegurar motos bajo esta póliza.',
                ),
                const SizedBox(height: RSSpacing.md),
              ],

              // Cross-validation result (name/CI match)
              if (cross != null && !vehicleTypeWrong) ...[
                _CrossValidationBanner(
                  hasMismatch: hasMismatch,
                  mismatchDetails: cross.mismatchDetails,
                  onRescanCedula: () => context.go('/onboarding/cedula'),
                  onToggleLegal: (v) =>
                      setState(() => _isLegalRepresentative = v),
                  isLegalRepresentative: _isLegalRepresentative,
                ),
                const SizedBox(height: RSSpacing.lg),
              ],

              // ── Plate (RS-104 real-time validation) ──────────────
              _ConfidenceField(
                label: 'Placa',
                controller: _plateCtrl,
                confidence: _fieldConf('plate'),
                textCapitalization: TextCapitalization.characters,
                onChanged: (_) => setState(() {}),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Requerido';
                  if (!Validators.isValidPlate(v.trim())) {
                    return 'Formato inválido (ej. ABC-123-DE)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: RSSpacing.md),

              // ── Brand dropdown (RS-083) ───────────────────────────
              ref.watch(_brandsProvider).when(
                    data: (brandsMap) => _BrandModelSelector(
                      brandsMap: brandsMap,
                      selectedBrand: _selectedBrand,
                      selectedModel: _selectedModel,
                      brandConfidence: _fieldConf('brand'),
                      modelConfidence: _fieldConf('model'),
                      onBrandChanged: (b) => setState(() {
                        _selectedBrand = b;
                        _selectedModel = null;
                      }),
                      onModelChanged: (m) =>
                          setState(() => _selectedModel = m),
                    ),
                    loading: () => const _BrandModelFallback(),
                    error: (_, __) => const _BrandModelFallback(),
                  ),
              const SizedBox(height: RSSpacing.md),

              // ── Vehicle body type chips (RS-083) ─────────────────
              _BodyTypeSelector(
                selected: _selectedBodyType,
                confidence: _fieldConf('vehicleBodyType'),
                onSelected: (t) => setState(() => _selectedBodyType = t),
              ),
              const SizedBox(height: RSSpacing.md),

              // ── Year picker ───────────────────────────────────────
              _ConfidenceLabel(
                label: 'Año',
                confidence: _fieldConf('year'),
              ),
              const SizedBox(height: 4),
              InkWell(
                onTap: _pickYear,
                borderRadius: BorderRadius.circular(RSRadius.md),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: RSSpacing.md,
                    vertical: RSSpacing.md + 2,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _confidenceColor(_fieldConf('year')),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(RSRadius.md),
                    color: RSColors.surface,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '$_selectedYear',
                          style: RSTypography.bodyLarge,
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down,
                          color: RSColors.textSecondary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: RSSpacing.md),

              // ── Vehicle use ───────────────────────────────────────
              _DropdownRow(
                label: 'Uso del vehículo',
                value: _vehicleUse,
                items: const {
                  'particular': 'Particular',
                  'cargo': 'Carga / Comercial',
                },
                onChanged: (v) => setState(() => _vehicleUse = v!),
              ),
              const SizedBox(height: RSSpacing.md),

              // ── Serial NIV ────────────────────────────────────────
              _ConfidenceField(
                label: 'Serial NIV',
                controller: _serialNivCtrl,
                confidence: _fieldConf('serialNiv'),
                textCapitalization: TextCapitalization.characters,
                validator: (v) => null, // optional
              ),
              const SizedBox(height: RSSpacing.md),

              // ── Serial Motor ──────────────────────────────────────
              _ConfidenceField(
                label: 'Serial Motor (opcional)',
                controller: _serialMotorCtrl,
                confidence: _fieldConf('serialMotor'),
                textCapitalization: TextCapitalization.characters,
                validator: (v) => null,
              ),
              const SizedBox(height: RSSpacing.md),

              // ── Seats ─────────────────────────────────────────────
              _DropdownRow<int>(
                label: 'Número de puestos',
                value: _seats,
                hint: 'Seleccionar',
                items: const {1: '1', 2: '2', 3: '3'},
                onChanged: (v) => setState(() => _seats = v),
              ),

              const SizedBox(height: RSSpacing.xxl),

              RSButton(
                label: 'Continuar',
                onPressed: (vehicleTypeWrong ||
                        (hasMismatch && !_isLegalRepresentative))
                    ? null
                    : _submit,
              ),
              const SizedBox(height: RSSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// RS-081: Confidence utilities

Color _confidenceColor(double conf) {
  if (conf <= 0) return RSColors.border;
  if (conf >= 0.90) return RSColors.success;
  if (conf >= 0.75) return RSColors.warning;
  return RSColors.error;
}

IconData _confidenceIcon(double conf) {
  if (conf <= 0) return Icons.radio_button_unchecked;
  if (conf >= 0.90) return Icons.check_circle_outline;
  if (conf >= 0.75) return Icons.warning_amber_outlined;
  return Icons.error_outline;
}

String _confidenceHint(double conf) {
  if (conf <= 0) return '';
  if (conf >= 0.90) return 'Leído con alta confianza';
  if (conf >= 0.75) return 'Verifica este campo';
  return 'Lectura poco confiable — corrige si es necesario';
}

// ---------------------------------------------------------------------------
// Local widgets

class _ConfidenceLabel extends StatelessWidget {
  const _ConfidenceLabel({required this.label, required this.confidence});
  final String label;
  final double confidence;

  @override
  Widget build(BuildContext context) {
    final color = _confidenceColor(confidence);
    return Row(
      children: [
        Text(label,
            style: RSTypography.bodyMedium
                .copyWith(color: RSColors.textSecondary)),
        if (confidence > 0) ...[
          const SizedBox(width: RSSpacing.xs),
          Icon(_confidenceIcon(confidence), color: color, size: 16),
        ],
      ],
    );
  }
}

class _ConfidenceField extends StatelessWidget {
  const _ConfidenceField({
    required this.label,
    required this.controller,
    required this.confidence,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final double confidence;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final hint = _confidenceHint(confidence);
    final color = _confidenceColor(confidence);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RSTextField(
          label: label,
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          validator: validator,
          onChanged: onChanged,
          borderColor: confidence > 0 && confidence < 0.90 ? color : null,
        ),
        if (hint.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Row(
              children: [
                Icon(_confidenceIcon(confidence), color: color, size: 14),
                const SizedBox(width: 4),
                Text(hint,
                    style: RSTypography.caption.copyWith(color: color)),
              ],
            ),
          ),
      ],
    );
  }
}

class _CrossValidationBanner extends StatelessWidget {
  const _CrossValidationBanner({
    required this.hasMismatch,
    required this.mismatchDetails,
    required this.onRescanCedula,
    required this.onToggleLegal,
    required this.isLegalRepresentative,
  });

  final bool hasMismatch;
  final String? mismatchDetails;
  final VoidCallback onRescanCedula;
  final ValueChanged<bool> onToggleLegal;
  final bool isLegalRepresentative;

  @override
  Widget build(BuildContext context) {
    return Container(
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
                      ? 'El nombre o cédula del propietario no coincide con tu cédula'
                      : 'Propietario verificado con tu cédula',
                  style: RSTypography.bodyLarge.copyWith(
                    color: hasMismatch ? RSColors.error : RSColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (hasMismatch && mismatchDetails != null) ...[
            const SizedBox(height: RSSpacing.sm),
            Text(mismatchDetails!,
                style: RSTypography.caption
                    .copyWith(color: RSColors.textSecondary)),
            const SizedBox(height: RSSpacing.md),
            RSButton(
              label: 'Volver a escanear cédula',
              variant: RSButtonVariant.secondary,
              onPressed: onRescanCedula,
              isFullWidth: false,
            ),
            const SizedBox(height: RSSpacing.sm),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Soy representante legal del propietario',
                style: RSTypography.bodyMedium,
              ),
              value: isLegalRepresentative,
              onChanged: (v) => onToggleLegal(v!),
              activeColor: RSColors.primary,
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ],
        ],
      ),
    );
  }
}

class _AlertBanner extends StatelessWidget {
  const _AlertBanner({
    required this.icon,
    required this.color,
    required this.message,
  });
  final IconData icon;
  final Color color;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(RSSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(RSRadius.md),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: RSSpacing.sm),
          Expanded(
              child: Text(message, style: RSTypography.bodyMedium)),
        ],
      ),
    );
  }
}

// RS-083: Brand + Model cascading dropdowns
class _BrandModelSelector extends StatelessWidget {
  const _BrandModelSelector({
    required this.brandsMap,
    required this.selectedBrand,
    required this.selectedModel,
    required this.brandConfidence,
    required this.modelConfidence,
    required this.onBrandChanged,
    required this.onModelChanged,
  });

  final Map<String, List<String>> brandsMap;
  final String? selectedBrand;
  final String? selectedModel;
  final double brandConfidence;
  final double modelConfidence;
  final ValueChanged<String?> onBrandChanged;
  final ValueChanged<String?> onModelChanged;

  @override
  Widget build(BuildContext context) {
    final models =
        selectedBrand != null ? (brandsMap[selectedBrand] ?? []) : <String>[];
    // Ensure selectedModel is still valid when brand changes
    final validModel = (models.contains(selectedModel)) ? selectedModel : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ConfidenceLabel(label: 'Marca', confidence: brandConfidence),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: brandsMap.containsKey(selectedBrand) ? selectedBrand : null,
          hint: const Text('Selecciona la marca'),
          isExpanded: true,
          decoration: _dropdownDecoration(
              _confidenceColor(brandConfidence)),
          items: brandsMap.keys
              .map((b) => DropdownMenuItem(value: b, child: Text(b)))
              .toList(),
          validator: (v) =>
              v == null ? 'Selecciona la marca' : null,
          onChanged: onBrandChanged,
        ),
        const SizedBox(height: RSSpacing.md),
        _ConfidenceLabel(label: 'Modelo', confidence: modelConfidence),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: validModel,
          hint: const Text('Selecciona el modelo'),
          isExpanded: true,
          decoration: _dropdownDecoration(
              _confidenceColor(modelConfidence)),
          items: [
            ...models.map(
                (m) => DropdownMenuItem(value: m, child: Text(m))),
            const DropdownMenuItem(
                value: '__other', child: Text('Otro (escribir)')),
          ],
          validator: (v) =>
              v == null ? 'Selecciona el modelo' : null,
          onChanged: onModelChanged,
        ),
      ],
    );
  }

  InputDecoration _dropdownDecoration(Color borderColor) {
    return InputDecoration(
      contentPadding: const EdgeInsets.symmetric(
          horizontal: RSSpacing.md, vertical: RSSpacing.md),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(RSRadius.md),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(RSRadius.md),
        borderSide: BorderSide(color: borderColor),
      ),
      filled: true,
      fillColor: RSColors.surface,
    );
  }
}

class _BrandModelFallback extends StatelessWidget {
  const _BrandModelFallback();
  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

// RS-083: Vehicle body type selection chips
class _BodyTypeSelector extends StatelessWidget {
  const _BodyTypeSelector({
    required this.selected,
    required this.confidence,
    required this.onSelected,
  });

  final String? selected;
  final double confidence;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ConfidenceLabel(
            label: 'Tipo de carrocería', confidence: confidence),
        const SizedBox(height: 8),
        Wrap(
          spacing: RSSpacing.sm,
          runSpacing: RSSpacing.sm,
          children: _bodyTypes.map((type) {
            final isSelected = selected == type;
            return FilterChip(
              label: Text(type),
              selected: isSelected,
              onSelected: (_) =>
                  onSelected(isSelected ? null : type),
              selectedColor:
                  RSColors.primary.withValues(alpha: 0.15),
              checkmarkColor: RSColors.primary,
              labelStyle: RSTypography.bodyMedium.copyWith(
                color: isSelected
                    ? RSColors.primary
                    : RSColors.textSecondary,
                fontWeight: isSelected
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _DropdownRow<T> extends StatelessWidget {
  const _DropdownRow({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
  });

  final String label;
  final T? value;
  final String? hint;
  final Map<T, String> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: RSTypography.bodyMedium
                .copyWith(color: RSColors.textSecondary)),
        const SizedBox(height: 4),
        DropdownButtonFormField<T>(
          value: value,
          hint: hint != null ? Text(hint!) : null,
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
          items: items.entries
              .map((e) => DropdownMenuItem<T>(
                    value: e.key,
                    child: Text(e.value, style: RSTypography.bodyLarge),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

// Year picker dialog (scroll wheel)
class _YearPickerDialog extends StatefulWidget {
  const _YearPickerDialog({required this.years, required this.selected});
  final List<int> years;
  final int selected;

  @override
  State<_YearPickerDialog> createState() => _YearPickerDialogState();
}

class _YearPickerDialogState extends State<_YearPickerDialog> {
  late int _current;
  late final FixedExtentScrollController _ctrl;

  @override
  void initState() {
    super.initState();
    _current = widget.selected;
    final idx = widget.years.indexOf(widget.selected);
    _ctrl = FixedExtentScrollController(initialItem: idx < 0 ? 0 : idx);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Selecciona el año'),
      content: SizedBox(
        height: 200,
        child: ListWheelScrollView.useDelegate(
          controller: _ctrl,
          itemExtent: 48,
          perspective: 0.005,
          onSelectedItemChanged: (i) =>
              setState(() => _current = widget.years[i]),
          childDelegate: ListWheelChildBuilderDelegate(
            childCount: widget.years.length,
            builder: (ctx, i) => Center(
              child: Text(
                '${widget.years[i]}',
                style: RSTypography.titleMedium.copyWith(
                  color: widget.years[i] == _current
                      ? RSColors.primary
                      : RSColors.textSecondary,
                  fontWeight: widget.years[i] == _current
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: RSColors.primary),
          onPressed: () => Navigator.of(context).pop(_current),
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}

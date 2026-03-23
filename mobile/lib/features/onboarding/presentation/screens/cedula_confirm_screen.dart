import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:ruedaseguro/core/theme/colors.dart';
import 'package:ruedaseguro/core/theme/spacing.dart';
import 'package:ruedaseguro/core/theme/typography.dart';
import 'package:ruedaseguro/core/utils/validators.dart';
import 'package:ruedaseguro/features/onboarding/domain/onboarding_state.dart';
import 'package:ruedaseguro/shared/widgets/rs_button.dart';
import 'package:ruedaseguro/shared/widgets/rs_text_field.dart';

class CedulaConfirmScreen extends ConsumerStatefulWidget {
  const CedulaConfirmScreen({super.key, this.ocrData});
  final Map<String, dynamic>? ocrData;

  @override
  ConsumerState<CedulaConfirmScreen> createState() => _CedulaConfirmScreenState();
}

class _CedulaConfirmScreenState extends ConsumerState<CedulaConfirmScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _idNumberCtrl;
  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _dobCtrl;
  late final TextEditingController _emergContactCtrl;
  late final TextEditingController _emergPhoneCtrl;

  String _idType = 'V';
  String? _sex;
  String? _nationality;
  DateTime? _selectedDob;
  String? _emergRelation;
  bool _showEmergency = false;

  @override
  void initState() {
    super.initState();
    final data = ref.read(onboardingProvider);
    _idType = data.idType ?? 'V';
    _sex = data.sex;
    _nationality = data.nationality;
    _selectedDob = data.dateOfBirth;
    _idNumberCtrl = TextEditingController(text: data.idNumber ?? '');
    _firstNameCtrl = TextEditingController(text: data.firstName ?? '');
    _lastNameCtrl = TextEditingController(text: data.lastName ?? '');
    _dobCtrl = TextEditingController(
      text: data.dateOfBirth != null
          ? DateFormat('dd/MM/yyyy').format(data.dateOfBirth!)
          : '',
    );
    _emergContactCtrl = TextEditingController(text: data.emergencyContactName ?? '');
    _emergPhoneCtrl = TextEditingController(text: data.emergencyContactPhone ?? '');
  }

  @override
  void dispose() {
    _idNumberCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _dobCtrl.dispose();
    _emergContactCtrl.dispose();
    _emergPhoneCtrl.dispose();
    super.dispose();
  }

  double _fieldConf(String field) {
    return ref.read(onboardingProvider).cedulaOcr?.fieldConfidences[field] ?? 0.0;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime(1990),
      firstDate: DateTime(1920),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 16)),
      locale: const Locale('es'),
    );
    if (picked != null) {
      setState(() {
        _selectedDob = picked;
        _dobCtrl.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(onboardingProvider.notifier).confirmIdentity(
      idType: _idType,
      idNumber: _idNumberCtrl.text.trim(),
      firstName: _firstNameCtrl.text.trim(),
      lastName: _lastNameCtrl.text.trim(),
      dateOfBirth: _selectedDob,
      nationality: _nationality,
      sex: _sex,
      emergencyContactName: _emergContactCtrl.text.trim().isEmpty
          ? null
          : _emergContactCtrl.text.trim(),
      emergencyContactPhone: _emergPhoneCtrl.text.trim().isEmpty
          ? null
          : _emergPhoneCtrl.text.trim(),
      emergencyContactRelation: _emergRelation,
    );
    context.push('/onboarding/licencia');
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(onboardingProvider);

    return Scaffold(
      backgroundColor: RSColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: RSColors.primary),
          onPressed: () => context.pop(),
        ),
        title: Text('Confirma tus datos',
            style: RSTypography.titleLarge.copyWith(color: RSColors.primary)),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(RSSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            // Scanned image thumbnail
            if (data.cedulaImage != null)
              GestureDetector(
                onTap: () => _showFullImage(context, data),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(RSRadius.md),
                  child: Image.file(
                    data.cedulaImage!,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

            const SizedBox(height: RSSpacing.xl),
            Text('Verifica que la información sea correcta',
                style: RSTypography.bodyMedium.copyWith(color: RSColors.textSecondary)),
            const SizedBox(height: RSSpacing.lg),

            // ID Type + Number
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 90,
                  child: _RSDropdownField(
                    label: 'Tipo',
                    value: _idType,
                    items: const ['V', 'E', 'CC'],
                    onChanged: (v) => setState(() => _idType = v!),
                  ),
                ),
                const SizedBox(width: RSSpacing.md),
                Expanded(
                  child: _ConfidenceField(
                    label: 'Número de cédula',
                    controller: _idNumberCtrl,
                    confidence: _fieldConf('idNumber'),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Requerido';
                      if (!RegExp(r'^\d{6,10}$').hasMatch(v.trim())) {
                        return 'Formato inválido (6-10 dígitos)';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: RSSpacing.md),

            // Names
            _ConfidenceField(
              label: 'Nombre(s)',
              controller: _firstNameCtrl,
              confidence: _fieldConf('firstName'),
              textCapitalization: TextCapitalization.words,
              validator: (v) {
                if (v == null || v.trim().length < 2) return 'Requerido (mín. 2 letras)';
                return null;
              },
            ),
            const SizedBox(height: RSSpacing.md),
            _ConfidenceField(
              label: 'Apellido(s)',
              controller: _lastNameCtrl,
              confidence: _fieldConf('lastName'),
              textCapitalization: TextCapitalization.words,
              validator: (v) {
                if (v == null || v.trim().length < 2) return 'Requerido (mín. 2 letras)';
                return null;
              },
            ),
            const SizedBox(height: RSSpacing.md),

            // Date of birth
            RSTextField(
              label: 'Fecha de nacimiento',
              controller: _dobCtrl,
              readOnly: true,
              suffixIcon: const Icon(Icons.calendar_today, color: RSColors.primary),
              onTap: _pickDate,
              validator: (v) {
                if (_selectedDob == null) return null; // optional
                if (!Validators.isAdult(_selectedDob)) return 'Debes ser mayor de 18 años';
                return null;
              },
            ),
            const SizedBox(height: RSSpacing.md),

            // Nationality
            _RSDropdownField(
              label: 'Nacionalidad',
              value: _nationality,
              items: const ['VENEZOLANO', 'EXTRANJERO'],
              hint: 'Seleccionar',
              onChanged: (v) => setState(() => _nationality = v),
            ),
            const SizedBox(height: RSSpacing.md),

            // Sex
            _RSDropdownField(
              label: 'Sexo',
              value: _sex,
              items: const ['M', 'F'],
              itemLabels: const {'M': 'Masculino', 'F': 'Femenino'},
              hint: 'Seleccionar',
              onChanged: (v) => setState(() => _sex = v),
            ),

            const SizedBox(height: RSSpacing.xl),

            // Emergency contact (collapsible)
            InkWell(
              onTap: () => setState(() => _showEmergency = !_showEmergency),
              borderRadius: BorderRadius.circular(RSRadius.md),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: RSSpacing.sm),
                child: Row(
                  children: [
                    Icon(
                      _showEmergency
                          ? Icons.expand_less
                          : Icons.expand_more,
                      color: RSColors.primary,
                    ),
                    const SizedBox(width: RSSpacing.sm),
                    Text(
                      'Contacto de emergencia (opcional)',
                      style: RSTypography.bodyLarge.copyWith(color: RSColors.primary),
                    ),
                  ],
                ),
              ),
            ),

            if (_showEmergency) ...[
              const SizedBox(height: RSSpacing.md),
              RSTextField(label: 'Nombre del contacto', controller: _emergContactCtrl),
              const SizedBox(height: RSSpacing.md),
              RSTextField(
                label: 'Teléfono',
                controller: _emergPhoneCtrl,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: RSSpacing.md),
              _RSDropdownField(
                label: 'Parentesco',
                value: _emergRelation,
                items: const [
                  'Padre/Madre', 'Esposo/a', 'Hijo/a', 'Hermano/a', 'Amigo/a', 'Otro',
                ],
                hint: 'Seleccionar',
                onChanged: (v) => setState(() => _emergRelation = v),
              ),
            ],

            const SizedBox(height: RSSpacing.xxl),

            RSButton(label: 'Continuar', onPressed: _submit),
            const SizedBox(height: RSSpacing.xl),
          ],
          ),
        ),
      ),
    );
  }

  void _showFullImage(BuildContext context, OnboardingData data) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Image.file(data.cedulaImage!, fit: BoxFit.contain),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Local helper widgets

/// Field that shows amber/green border based on OCR confidence.
class _ConfidenceField extends StatelessWidget {
  const _ConfidenceField({
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

class _RSDropdownField<T> extends StatelessWidget {
  const _RSDropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
    this.itemLabels,
  });

  final String label;
  final T? value;
  final List<T> items;
  final ValueChanged<T?> onChanged;
  final String? hint;
  final Map<T, String>? itemLabels;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: RSTypography.bodyMedium.copyWith(color: RSColors.textSecondary)),
        const SizedBox(height: 4),
        DropdownButtonFormField<T>(
          value: value,
          hint: hint != null ? Text(hint!) : null,
          isExpanded: true,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: RSSpacing.md,
              vertical: RSSpacing.md,
            ),
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
          items: items
              .map((item) => DropdownMenuItem<T>(
                    value: item,
                    child: Text(
                      itemLabels?[item] ?? item.toString(),
                      style: RSTypography.bodyLarge,
                    ),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

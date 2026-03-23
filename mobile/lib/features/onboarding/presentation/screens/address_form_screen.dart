import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ruedaseguro/core/theme/colors.dart';
import 'package:ruedaseguro/core/theme/spacing.dart';
import 'package:ruedaseguro/core/theme/typography.dart';
import 'package:ruedaseguro/features/onboarding/domain/onboarding_state.dart';
import 'package:ruedaseguro/shared/widgets/rs_button.dart';
import 'package:ruedaseguro/shared/widgets/rs_text_field.dart';

const _venezuelanStates = [
  'Amazonas', 'Anzoátegui', 'Apure', 'Aragua', 'Barinas', 'Bolívar',
  'Carabobo', 'Cojedes', 'Delta Amacuro', 'Dependencias Federales',
  'Distrito Capital', 'Falcón', 'Guárico', 'Lara', 'Mérida', 'Miranda',
  'Monagas', 'Nueva Esparta', 'Portuguesa', 'Sucre', 'Táchira', 'Trujillo',
  'La Guaira (Vargas)', 'Yaracuy', 'Zulia',
];

class AddressFormScreen extends ConsumerStatefulWidget {
  const AddressFormScreen({super.key});

  @override
  ConsumerState<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends ConsumerState<AddressFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _urbCtrl;
  late final TextEditingController _ciudadCtrl;
  late final TextEditingController _municipioCtrl;
  late final TextEditingController _cpCtrl;

  String? _estado;

  @override
  void initState() {
    super.initState();
    final data = ref.read(onboardingProvider);
    _urbCtrl = TextEditingController(text: data.urbanizacion ?? '');
    _ciudadCtrl = TextEditingController(text: data.ciudad ?? '');
    _municipioCtrl = TextEditingController(text: data.municipio ?? '');
    _cpCtrl = TextEditingController(text: data.codigoPostal ?? '');
    _estado = data.estado;
  }

  @override
  void dispose() {
    _urbCtrl.dispose();
    _ciudadCtrl.dispose();
    _municipioCtrl.dispose();
    _cpCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(onboardingProvider.notifier).updateAddress(
      urbanizacion: _urbCtrl.text.trim(),
      ciudad: _ciudadCtrl.text.trim(),
      municipio: _municipioCtrl.text.trim(),
      estado: _estado!,
      codigoPostal: _cpCtrl.text.trim().isEmpty ? null : _cpCtrl.text.trim(),
    );
    context.push('/onboarding/consent');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RSColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: RSColors.primary),
          onPressed: () => context.pop(),
        ),
        title: Text('Tu dirección',
            style: RSTypography.titleLarge.copyWith(color: RSColors.primary)),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(RSSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            Text(
              'Necesitamos tu dirección para emitir la póliza',
              style: RSTypography.bodyLarge.copyWith(color: RSColors.textSecondary),
            ),
            const SizedBox(height: RSSpacing.xl),

            RSTextField(
              label: 'Urbanización / Sector',
              controller: _urbCtrl,
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Requerido' : null,
            ),
            const SizedBox(height: RSSpacing.md),
            RSTextField(
              label: 'Ciudad',
              controller: _ciudadCtrl,
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Requerido' : null,
            ),
            const SizedBox(height: RSSpacing.md),
            RSTextField(
              label: 'Municipio',
              controller: _municipioCtrl,
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Requerido' : null,
            ),
            const SizedBox(height: RSSpacing.md),

            // Estado dropdown
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Estado',
                    style: RSTypography.bodyMedium
                        .copyWith(color: RSColors.textSecondary)),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  value: _estado,
                  hint: const Text('Selecciona tu estado'),
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
                  items: _venezuelanStates
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  validator: (v) =>
                      v == null ? 'Selecciona un estado' : null,
                  onChanged: (v) => setState(() => _estado = v),
                ),
              ],
            ),
            const SizedBox(height: RSSpacing.md),

            RSTextField(
              label: 'Código Postal (opcional)',
              controller: _cpCtrl,
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: RSSpacing.xxl),
            RSButton(label: 'Continuar', onPressed: _submit),
            const SizedBox(height: RSSpacing.xl),
          ],
          ),
        ),
      ),
    );
  }
}

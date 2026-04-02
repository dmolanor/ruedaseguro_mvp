import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import 'package:ruedaseguro/core/theme/colors.dart';
import 'package:ruedaseguro/core/theme/spacing.dart';
import 'package:ruedaseguro/core/theme/typography.dart';
import 'package:ruedaseguro/features/onboarding/domain/onboarding_state.dart';
import 'package:ruedaseguro/shared/widgets/rs_button.dart';
import 'package:ruedaseguro/shared/widgets/rs_text_field.dart';

// ---------------------------------------------------------------------------
// Async provider: loads estados_municipios.json
// Returns List<{nombre, municipios}>
final _locationDataProvider =
    FutureProvider<List<_EstadoData>>((ref) async {
  try {
    final raw = await rootBundle
        .loadString('assets/data/estados_municipios.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return (json['estados'] as List)
        .cast<Map<String, dynamic>>()
        .map(_EstadoData.fromJson)
        .toList();
  } on Exception {
    return _fallbackEstados;
  }
});

class _EstadoData {
  final String nombre;
  final List<String> municipios;
  const _EstadoData({required this.nombre, required this.municipios});
  factory _EstadoData.fromJson(Map<String, dynamic> j) => _EstadoData(
        nombre: j['nombre'] as String,
        municipios: (j['municipios'] as List).cast<String>(),
      );
}

// Minimal fallback if asset loading fails
const _fallbackEstados = [
  _EstadoData(nombre: 'Distrito Capital', municipios: ['Libertador']),
  _EstadoData(nombre: 'Miranda', municipios: ['Baruta', 'Chacao', 'El Hatillo', 'Sucre']),
  _EstadoData(nombre: 'Carabobo', municipios: ['Valencia', 'Naguanagua', 'San Diego']),
  _EstadoData(nombre: 'Zulia', municipios: ['Maracaibo', 'San Francisco', 'Cabimas']),
  _EstadoData(nombre: 'Aragua', municipios: ['Girardot', 'Mario Briceño Iragorry']),
  _EstadoData(nombre: 'Lara', municipios: ['Iribarren', 'Palavecino']),
  _EstadoData(nombre: 'Táchira', municipios: ['San Cristóbal', 'Cárdenas']),
  _EstadoData(nombre: 'Bolívar', municipios: ['Heres', 'Caroní']),
  _EstadoData(nombre: 'Anzoátegui', municipios: ['Juan Antonio Sotillo', 'Simón Bolívar']),
  _EstadoData(nombre: 'Monagas', municipios: ['Maturín', 'Cedeño']),
];

// ---------------------------------------------------------------------------

/// RS-084/085 — Address collection with:
/// - Estado → Municipio cascading dropdowns (RS-084)
/// - GPS geolocation button for auto-fill (RS-085)
///
/// NOTE: RS-085 requires platform permissions:
///   Android: ACCESS_FINE_LOCATION + ACCESS_COARSE_LOCATION in AndroidManifest.xml
///   iOS: NSLocationWhenInUseUsageDescription in Info.plist
class AddressFormScreen extends ConsumerStatefulWidget {
  const AddressFormScreen({super.key});

  @override
  ConsumerState<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends ConsumerState<AddressFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _urbCtrl;
  late final TextEditingController _cpCtrl;

  String? _estado;
  String? _municipio;
  double? _latitude;
  double? _longitude;
  bool _addressFromGps = false;
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    final data = ref.read(onboardingProvider);
    _urbCtrl = TextEditingController(text: data.urbanizacion ?? '');
    _cpCtrl = TextEditingController(text: data.codigoPostal ?? '');
    _estado = data.estado;
    _municipio = data.municipio;
    _latitude = data.latitude;
    _longitude = data.longitude;
    _addressFromGps = data.addressFromGps;
  }

  @override
  void dispose() {
    _urbCtrl.dispose();
    _cpCtrl.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // RS-085: Geolocation
  // ---------------------------------------------------------------------------

  Future<void> _detectLocation(List<_EstadoData> estados) async {
    setState(() => _isLocating = true);
    try {
      // Check service enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationError(
            'El servicio de ubicación está desactivado. Actívalo en la configuración.');
        return;
      }

      // Check / request permission
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showLocationError(
              'Permiso de ubicación denegado. Puedes escribir tu dirección manualmente.');
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _showLocationError(
            'Permiso de ubicación bloqueado permanentemente. Actívalo en Configuración > Privacidad.');
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      setState(() {
        _latitude = pos.latitude;
        _longitude = pos.longitude;
        _addressFromGps = true;
      });

      // Rough reverse geocoding via coordinate → estado lookup
      // (Real implementation would use geocoding package or Supabase function)
      _showGpsSuccess(pos.latitude, pos.longitude);
    } on Exception catch (e) {
      _showLocationError('No se pudo obtener la ubicación: $e');
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  void _showLocationError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: RSColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showGpsSuccess(double lat, double lon) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Ubicación detectada (${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)}). '
            'Selecciona tu estado y municipio.'),
        backgroundColor: RSColors.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // ---------------------------------------------------------------------------

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(onboardingProvider.notifier).updateAddress(
          urbanizacion: _urbCtrl.text.trim(),
          municipio: _municipio!,
          estado: _estado!,
          codigoPostal:
              _cpCtrl.text.trim().isEmpty ? null : _cpCtrl.text.trim(),
          latitude: _latitude,
          longitude: _longitude,
          addressFromGps: _addressFromGps,
        );
    context.push('/onboarding/consent');
  }

  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
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
        title: Text('Tu dirección',
            style:
                RSTypography.titleLarge.copyWith(color: RSColors.primary)),
      ),
      body: ref.watch(_locationDataProvider).when(
            data: (estados) => _buildForm(estados),
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (_, __) => _buildForm(_fallbackEstados),
          ),
    );
  }

  Widget _buildForm(List<_EstadoData> estados) {
    final municipios = _estado != null
        ? estados
            .firstWhere((e) => e.nombre == _estado,
                orElse: () =>
                    const _EstadoData(nombre: '', municipios: []))
            .municipios
        : <String>[];

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(RSSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Necesitamos tu dirección para emitir la póliza',
              style: RSTypography.bodyLarge
                  .copyWith(color: RSColors.textSecondary),
            ),
            const SizedBox(height: RSSpacing.md),

            // RS-085: GPS detect button
            OutlinedButton.icon(
              icon: _isLocating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      _addressFromGps
                          ? Icons.my_location
                          : Icons.location_searching,
                      color: RSColors.primary,
                    ),
              label: Text(
                _isLocating
                    ? 'Detectando ubicación...'
                    : _addressFromGps
                        ? 'Ubicación detectada — actualizar'
                        : 'Detectar mi ubicación',
                style: RSTypography.bodyMedium
                    .copyWith(color: RSColors.primary),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: _addressFromGps
                      ? RSColors.success
                      : RSColors.primary,
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: RSSpacing.md,
                  horizontal: RSSpacing.lg,
                ),
              ),
              onPressed:
                  _isLocating ? null : () => _detectLocation(estados),
            ),

            if (_addressFromGps && _latitude != null) ...[
              const SizedBox(height: RSSpacing.sm),
              Row(
                children: [
                  const Icon(Icons.check_circle,
                      color: RSColors.success, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'GPS: ${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}',
                    style: RSTypography.caption
                        .copyWith(color: RSColors.success),
                  ),
                ],
              ),
            ],

            const SizedBox(height: RSSpacing.xl),

            // ── Estado dropdown (RS-084) ──────────────────────────
            _dropdownField<String>(
              label: 'Estado',
              value: _estado,
              hint: 'Selecciona tu estado',
              items: {for (final e in estados) e.nombre: e.nombre},
              validator: (v) =>
                  v == null ? 'Selecciona un estado' : null,
              onChanged: (v) => setState(() {
                _estado = v;
                _municipio = null; // Reset municipio when estado changes
              }),
            ),
            const SizedBox(height: RSSpacing.md),

            // ── Municipio dropdown (RS-084) — filtered by estado ──
            _dropdownField<String>(
              label: 'Municipio',
              value: municipios.contains(_municipio) ? _municipio : null,
              hint: _estado == null
                  ? 'Primero selecciona el estado'
                  : 'Selecciona tu municipio',
              items: {for (final m in municipios) m: m},
              validator: (v) =>
                  v == null ? 'Selecciona un municipio' : null,
              onChanged: _estado == null
                  ? null
                  : (v) => setState(() => _municipio = v),
            ),
            const SizedBox(height: RSSpacing.md),

            // ── Urbanización / Sector ─────────────────────────────
            RSTextField(
              label: 'Urbanización / Sector',
              controller: _urbCtrl,
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Requerido' : null,
            ),
            const SizedBox(height: RSSpacing.md),

            // ── Código postal ─────────────────────────────────────
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
    );
  }

  Widget _dropdownField<T>({
    required String label,
    required T? value,
    required String hint,
    required Map<T, String> items,
    required String? Function(T?) validator,
    required ValueChanged<T?>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: RSTypography.bodyMedium
                .copyWith(color: RSColors.textSecondary)),
        const SizedBox(height: 4),
        DropdownButtonFormField<T>(
          value: value,
          hint: Text(hint),
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
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(RSRadius.md),
              borderSide: BorderSide(
                  color: RSColors.border.withValues(alpha: 0.5)),
            ),
            filled: true,
            fillColor: onChanged == null
                ? RSColors.surface.withValues(alpha: 0.5)
                : RSColors.surface,
          ),
          items: items.entries
              .map((e) => DropdownMenuItem<T>(
                    value: e.key,
                    child: Text(e.value,
                        style: RSTypography.bodyLarge),
                  ))
              .toList(),
          validator: validator,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

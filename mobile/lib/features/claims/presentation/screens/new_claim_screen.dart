import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import 'package:ruedaseguro/core/theme/colors.dart';
import 'package:ruedaseguro/core/theme/spacing.dart';
import 'package:ruedaseguro/core/theme/typography.dart';
import 'package:ruedaseguro/shared/widgets/rs_button.dart';
import 'package:ruedaseguro/shared/widgets/rs_text_field.dart';

class NewClaimScreen extends StatefulWidget {
  const NewClaimScreen({super.key});

  @override
  State<NewClaimScreen> createState() => _NewClaimScreenState();
}

class _NewClaimScreenState extends State<NewClaimScreen> {
  int _selectedType = 0;
  bool _isSubmitting = false;
  final List<bool> _photosAdded = [false, false, false];

  final _incidentTypes = [
    _IncidentType(
      id: 'colision',
      label: 'Colisión',
      icon: Icons.car_crash_rounded,
      color: const Color(0xFFC62828),
    ),
    _IncidentType(
      id: 'dano_tercero',
      label: 'Daño a tercero',
      icon: Icons.directions_car_rounded,
      color: const Color(0xFFFF6D00),
    ),
    _IncidentType(
      id: 'robo',
      label: 'Robo / Hurto',
      icon: Icons.no_transfer_rounded,
      color: const Color(0xFF6A1B9A),
    ),
    _IncidentType(
      id: 'lesiones',
      label: 'Lesiones',
      icon: Icons.local_hospital_rounded,
      color: const Color(0xFF1A237E),
    ),
  ];

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Siniestro reportado. Número: SIN-2026-0043'),
          backgroundColor: RSColors.success,
          duration: Duration(seconds: 4),
        ),
      );
      context.pop();
    }
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
        title: Text('Reportar siniestro',
            style: RSTypography.titleLarge.copyWith(color: RSColors.primary)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(RSSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress steps
            _ProgressSteps(currentStep: 1)
                .animate()
                .fadeIn(duration: 400.ms),

            const SizedBox(height: RSSpacing.lg),

            // Policy info banner
            _PolicyBanner()
                .animate(delay: 100.ms)
                .fadeIn(duration: 400.ms),

            const SizedBox(height: RSSpacing.lg),

            // Incident type
            Text('Tipo de siniestro',
                style: RSTypography.titleLarge.copyWith(
                    color: RSColors.textPrimary))
                .animate(delay: 150.ms)
                .fadeIn(duration: 400.ms),
            const SizedBox(height: RSSpacing.md),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: RSSpacing.sm,
              crossAxisSpacing: RSSpacing.sm,
              childAspectRatio: 2.2,
              children: _incidentTypes
                  .asMap()
                  .entries
                  .map((e) => _IncidentTypeCard(
                        type: e.value,
                        isSelected: _selectedType == e.key,
                        onTap: () => setState(() => _selectedType = e.key),
                      )
                          .animate(delay: (80 * e.key).ms)
                          .fadeIn(duration: 300.ms)
                          .scale(begin: const Offset(0.95, 0.95)))
                  .toList(),
            ),

            const SizedBox(height: RSSpacing.lg),

            // Date and time
            Text('Fecha y hora del incidente',
                style: RSTypography.titleLarge.copyWith(
                    color: RSColors.textPrimary))
                .animate(delay: 300.ms)
                .fadeIn(duration: 400.ms),
            const SizedBox(height: RSSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _DateTimeTile(
                    icon: Icons.calendar_today_rounded,
                    label: '23 Mar 2026',
                  ),
                ),
                const SizedBox(width: RSSpacing.md),
                Expanded(
                  child: _DateTimeTile(
                    icon: Icons.access_time_rounded,
                    label: '02:45 PM',
                  ),
                ),
              ],
            ).animate(delay: 350.ms).fadeIn(duration: 400.ms),

            const SizedBox(height: RSSpacing.lg),

            // Location
            Text('Ubicación del siniestro',
                style: RSTypography.titleLarge.copyWith(
                    color: RSColors.textPrimary))
                .animate(delay: 400.ms)
                .fadeIn(duration: 400.ms),
            const SizedBox(height: RSSpacing.md),
            RSTextField(
              label: 'Dirección',
              hint: 'Ej: Av. Libertador con Av. Bolívar',
              prefixIcon: const Icon(Icons.location_on_rounded,
                  color: RSColors.textSecondary, size: 20),
            ).animate(delay: 430.ms).fadeIn(duration: 400.ms),
            const SizedBox(height: RSSpacing.sm),
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: RSColors.surfaceVariant,
                borderRadius: BorderRadius.circular(RSRadius.md),
                border: Border.all(color: RSColors.border),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.map_rounded,
                        color: RSColors.textSecondary, size: 32),
                    const SizedBox(height: 8),
                    Text('Vista de mapa',
                        style: RSTypography.caption.copyWith(
                            color: RSColors.textSecondary)),
                  ],
                ),
              ),
            ).animate(delay: 450.ms).fadeIn(duration: 400.ms),

            const SizedBox(height: RSSpacing.lg),

            // Description
            Text('Descripción del incidente',
                style: RSTypography.titleLarge.copyWith(
                    color: RSColors.textPrimary))
                .animate(delay: 500.ms)
                .fadeIn(duration: 400.ms),
            const SizedBox(height: RSSpacing.md),
            _DescriptionField()
                .animate(delay: 530.ms)
                .fadeIn(duration: 400.ms),

            const SizedBox(height: RSSpacing.lg),

            // Photo evidence
            Text('Evidencia fotográfica',
                style: RSTypography.titleLarge.copyWith(
                    color: RSColors.textPrimary))
                .animate(delay: 600.ms)
                .fadeIn(duration: 400.ms),
            const SizedBox(height: RSSpacing.xs),
            Text('Agrega fotos del incidente (mínimo 2)',
                style: RSTypography.bodyMedium.copyWith(
                    color: RSColors.textSecondary))
                .animate(delay: 620.ms)
                .fadeIn(duration: 400.ms),
            const SizedBox(height: RSSpacing.md),
            Row(
              children: List.generate(
                3,
                (i) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i < 2 ? RSSpacing.sm : 0),
                    child: _PhotoSlot(
                      added: _photosAdded[i],
                      onTap: () =>
                          setState(() => _photosAdded[i] = !_photosAdded[i]),
                    ),
                  ),
                ),
              ),
            ).animate(delay: 650.ms).fadeIn(duration: 400.ms),

            const SizedBox(height: RSSpacing.xl),

            // Injuries question
            _InjuriesToggle()
                .animate(delay: 700.ms)
                .fadeIn(duration: 400.ms),

            const SizedBox(height: RSSpacing.xl),

            RSButton(
              label: 'Enviar reporte',
              isLoading: _isSubmitting,
              onPressed: _isSubmitting ? null : _submit,
            ).animate(delay: 750.ms).fadeIn(duration: 400.ms).slideY(begin: 0.2),

            const SizedBox(height: RSSpacing.md),
            Center(
              child: Text(
                'Un asesor te contactará en las próximas 2 horas',
                style: RSTypography.caption.copyWith(color: RSColors.textSecondary),
              ),
            ),

            const SizedBox(height: RSSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

// ─── Progress Steps ──────────────────────────────────────────────
class _ProgressSteps extends StatelessWidget {
  const _ProgressSteps({required this.currentStep});
  final int currentStep;

  @override
  Widget build(BuildContext context) {
    final steps = ['Datos', 'Evidencia', 'Revisión'];
    return Row(
      children: steps.asMap().entries.map((e) {
        final stepNum = e.key + 1;
        final isDone = stepNum < currentStep;
        final isActive = stepNum == currentStep;
        return Expanded(
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isDone
                      ? RSColors.success
                      : isActive
                          ? RSColors.primary
                          : RSColors.surfaceVariant,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: isDone
                      ? const Icon(Icons.check_rounded,
                          color: Colors.white, size: 16)
                      : Text('$stepNum',
                          style: RSTypography.caption.copyWith(
                            color: isActive ? Colors.white : RSColors.textSecondary,
                            fontWeight: FontWeight.w700,
                          )),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(e.value,
                    style: RSTypography.caption.copyWith(
                      color: isActive ? RSColors.primary : RSColors.textSecondary,
                      fontWeight:
                          isActive ? FontWeight.w700 : FontWeight.normal,
                    )),
              ),
              if (e.key < steps.length - 1)
                Expanded(
                  child: Container(
                    height: 1,
                    margin:
                        const EdgeInsets.symmetric(horizontal: RSSpacing.xs),
                    color: RSColors.border,
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ─── Policy Banner ───────────────────────────────────────────────
class _PolicyBanner extends StatelessWidget {
  const _PolicyBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(RSSpacing.md),
      decoration: BoxDecoration(
        color: RSColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(RSRadius.md),
        border: Border.all(color: RSColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_user_rounded,
              color: RSColors.primary, size: 20),
          const SizedBox(width: RSSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Póliza activa verificada',
                    style: RSTypography.bodyMedium.copyWith(
                      color: RSColors.primary,
                      fontWeight: FontWeight.w600,
                    )),
                Text('RCV Plus · RS-2026-001234 · Vence 23 Mar 2027',
                    style: RSTypography.caption
                        .copyWith(color: RSColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Incident Type Card ──────────────────────────────────────────
class _IncidentType {
  final String id;
  final String label;
  final IconData icon;
  final Color color;
  const _IncidentType(
      {required this.id,
      required this.label,
      required this.icon,
      required this.color});
}

class _IncidentTypeCard extends StatelessWidget {
  const _IncidentTypeCard({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });
  final _IncidentType type;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
            horizontal: RSSpacing.md, vertical: RSSpacing.sm),
        decoration: BoxDecoration(
          color: isSelected
              ? type.color.withValues(alpha: 0.08)
              : RSColors.surface,
          borderRadius: BorderRadius.circular(RSRadius.md),
          border: Border.all(
            color: isSelected ? type.color : RSColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(type.icon,
                color: isSelected ? type.color : RSColors.textSecondary,
                size: 20),
            const SizedBox(width: RSSpacing.sm),
            Expanded(
              child: Text(type.label,
                  style: RSTypography.bodyMedium.copyWith(
                    color: isSelected ? type.color : RSColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  )),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Date Time Tile ──────────────────────────────────────────────
class _DateTimeTile extends StatelessWidget {
  const _DateTimeTile({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(RSSpacing.md),
      decoration: BoxDecoration(
        color: RSColors.surface,
        borderRadius: BorderRadius.circular(RSRadius.md),
        border: Border.all(color: RSColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: RSColors.primary, size: 18),
          const SizedBox(width: RSSpacing.sm),
          Text(label,
              style: RSTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              )),
        ],
      ),
    );
  }
}

// ─── Description Field ───────────────────────────────────────────
class _DescriptionField extends StatelessWidget {
  const _DescriptionField();

  @override
  Widget build(BuildContext context) {
    return TextField(
      maxLines: 4,
      decoration: InputDecoration(
        hintText: 'Describe brevemente lo ocurrido: circunstancias, daños, lesiones...',
        hintStyle: RSTypography.bodyMedium.copyWith(color: RSColors.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RSRadius.md),
          borderSide: const BorderSide(color: RSColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RSRadius.md),
          borderSide: const BorderSide(color: RSColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RSRadius.md),
          borderSide: const BorderSide(color: RSColors.primary, width: 2),
        ),
        filled: true,
        fillColor: RSColors.surface,
        contentPadding: const EdgeInsets.all(RSSpacing.md),
      ),
    );
  }
}

// ─── Photo Slot ──────────────────────────────────────────────────
class _PhotoSlot extends StatelessWidget {
  const _PhotoSlot({required this.added, required this.onTap});
  final bool added;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 90,
        decoration: BoxDecoration(
          color: added
              ? RSColors.success.withValues(alpha: 0.08)
              : RSColors.surfaceVariant,
          borderRadius: BorderRadius.circular(RSRadius.md),
          border: Border.all(
            color: added ? RSColors.success : RSColors.border,
            width: added ? 2 : 1,
          ),
        ),
        child: Center(
          child: added
              ? const Icon(Icons.check_circle_rounded,
                  color: RSColors.success, size: 28)
              : const Icon(Icons.add_a_photo_rounded,
                  color: RSColors.textSecondary, size: 28),
        ),
      ),
    );
  }
}

// ─── Injuries Toggle ─────────────────────────────────────────────
class _InjuriesToggle extends StatefulWidget {
  const _InjuriesToggle();

  @override
  State<_InjuriesToggle> createState() => _InjuriesToggleState();
}

class _InjuriesToggleState extends State<_InjuriesToggle> {
  bool _hasInjuries = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(RSSpacing.md),
      decoration: BoxDecoration(
        color: _hasInjuries
            ? RSColors.error.withValues(alpha: 0.05)
            : RSColors.surface,
        borderRadius: BorderRadius.circular(RSRadius.md),
        border: Border.all(
          color: _hasInjuries ? RSColors.error : RSColors.border,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('¿Hubo lesionados?',
                    style: RSTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    )),
                Text(
                  _hasInjuries
                      ? 'Se activará asistencia médica inmediata'
                      : 'Incluye al conductor y/o terceros',
                  style: RSTypography.caption.copyWith(
                    color: _hasInjuries ? RSColors.error : RSColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _hasInjuries,
            onChanged: (v) => setState(() => _hasInjuries = v),
            activeThumbColor: RSColors.error,
          ),
        ],
      ),
    );
  }
}

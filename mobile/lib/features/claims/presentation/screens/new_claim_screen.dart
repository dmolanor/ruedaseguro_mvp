import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'package:ruedaseguro/core/theme/colors.dart';
import 'package:ruedaseguro/core/theme/spacing.dart';
import 'package:ruedaseguro/core/theme/typography.dart';
import 'package:ruedaseguro/features/audit/data/audit_repository.dart';
import 'package:ruedaseguro/features/claims/data/claim_repository.dart';
import 'package:ruedaseguro/features/policy/providers/policy_providers.dart';
import 'package:ruedaseguro/shared/providers/auth_provider.dart';
import 'package:ruedaseguro/shared/widgets/rs_button.dart';
import 'package:ruedaseguro/shared/widgets/rs_text_field.dart';

class NewClaimScreen extends ConsumerStatefulWidget {
  const NewClaimScreen({super.key});

  @override
  ConsumerState<NewClaimScreen> createState() => _NewClaimScreenState();
}

class _NewClaimScreenState extends ConsumerState<NewClaimScreen> {
  int _selectedType = 0;
  bool _isSubmitting = false;
  bool _hasInjuries = false;
  DateTime _incidentAt = DateTime.now();

  final List<XFile?> _photos = [null, null, null];
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _picker = ImagePicker();

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
      color: const Color(0xFFFF6A1A),
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
      color: const Color(0xFF0A1B2A),
    ),
  ];

  @override
  void dispose() {
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(int index) async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 75,
      maxWidth: 1280,
    );
    if (picked != null && mounted) {
      setState(() => _photos[index] = picked);
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _incidentAt,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
      locale: const Locale('es'),
    );
    if (picked != null && mounted) {
      setState(
        () => _incidentAt = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _incidentAt.hour,
          _incidentAt.minute,
        ),
      );
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_incidentAt),
    );
    if (picked != null && mounted) {
      setState(
        () => _incidentAt = DateTime(
          _incidentAt.year,
          _incidentAt.month,
          _incidentAt.day,
          picked.hour,
          picked.minute,
        ),
      );
    }
  }

  Future<void> _submit() async {
    final photoCount = _photos.where((p) => p != null).length;
    if (photoCount < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes agregar al menos 2 fotos del incidente'),
          backgroundColor: RSColors.error,
        ),
      );
      return;
    }
    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Describe brevemente lo ocurrido'),
          backgroundColor: RSColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final auth = ref.read(authProvider);
      final userId = auth.user?.id;

      // Demo mode: show fake success
      if (userId == null) {
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          _showSuccess('SIN-${DateTime.now().year}-DEMO01');
        }
        return;
      }

      // Fetch active policy for this rider
      final activePolicy = await ref.read(activePolicySummaryProvider.future);
      if (activePolicy == null) {
        throw Exception('No tienes una póliza activa');
      }

      // 1. Create claim record
      final (:claimId, :claimNumber) = await ClaimRepository.instance
          .createClaim(
            profileId: userId,
            policyId: activePolicy.id,
            incidentType: _incidentTypes[_selectedType].id,
            description: _descriptionController.text.trim(),
            location: _locationController.text.trim(),
            hasInjuries: _hasInjuries,
            incidentAt: _incidentAt,
          );

      // 2. Upload photos
      int photoIndex = 0;
      for (final photo in _photos) {
        if (photo != null) {
          await ClaimRepository.instance.uploadClaimPhoto(
            userId: userId,
            claimId: claimId,
            photoFile: File(photo.path),
            index: photoIndex++,
          );
        }
      }

      // 3. Audit log
      await AuditRepository.instance.logEvent(
        actorId: userId,
        eventType: 'claim.reported',
        targetId: claimId,
        targetTable: 'claims',
        payload: {
          'type': _incidentTypes[_selectedType].id,
          'has_injuries': _hasInjuries,
          'photos': photoIndex,
        },
      );

      if (mounted) _showSuccess(claimNumber);
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar: ${e.toString()}'),
            backgroundColor: RSColors.error,
          ),
        );
      }
    }
  }

  void _showSuccess(String claimNumber) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Siniestro reportado. Número: $claimNumber'),
        backgroundColor: RSColors.success,
        duration: const Duration(seconds: 5),
      ),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('dd MMM yyyy', 'es').format(_incidentAt);
    final timeLabel = DateFormat('hh:mm a').format(_incidentAt);

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
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Reportar siniestro',
          style: RSTypography.titleLarge.copyWith(color: RSColors.primary),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(RSSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProgressSteps(currentStep: 1).animate().fadeIn(duration: 400.ms),
            const SizedBox(height: RSSpacing.lg),

            const _ActivePolicyBanner()
                .animate(delay: 100.ms)
                .fadeIn(duration: 400.ms),
            const SizedBox(height: RSSpacing.lg),

            // Incident type
            Text(
              'Tipo de siniestro',
              style: RSTypography.titleLarge.copyWith(
                color: RSColors.textPrimary,
              ),
            ).animate(delay: 150.ms).fadeIn(duration: 400.ms),
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
                  .map(
                    (e) =>
                        _IncidentTypeCard(
                              type: e.value,
                              isSelected: _selectedType == e.key,
                              onTap: () =>
                                  setState(() => _selectedType = e.key),
                            )
                            .animate(delay: (80 * e.key).ms)
                            .fadeIn(duration: 300.ms)
                            .scale(begin: const Offset(0.95, 0.95)),
                  )
                  .toList(),
            ),

            const SizedBox(height: RSSpacing.lg),

            // Date and time (interactive)
            Text(
              'Fecha y hora del incidente',
              style: RSTypography.titleLarge.copyWith(
                color: RSColors.textPrimary,
              ),
            ).animate(delay: 300.ms).fadeIn(duration: 400.ms),
            const SizedBox(height: RSSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _DateTimeTile(
                    icon: Icons.calendar_today_rounded,
                    label: dateLabel,
                    onTap: _selectDate,
                  ),
                ),
                const SizedBox(width: RSSpacing.md),
                Expanded(
                  child: _DateTimeTile(
                    icon: Icons.access_time_rounded,
                    label: timeLabel,
                    onTap: _selectTime,
                  ),
                ),
              ],
            ).animate(delay: 350.ms).fadeIn(duration: 400.ms),

            const SizedBox(height: RSSpacing.lg),

            // Location
            Text(
              'Ubicación del siniestro',
              style: RSTypography.titleLarge.copyWith(
                color: RSColors.textPrimary,
              ),
            ).animate(delay: 400.ms).fadeIn(duration: 400.ms),
            const SizedBox(height: RSSpacing.md),
            RSTextField(
              label: 'Dirección',
              hint: 'Ej: Av. Libertador con Av. Bolívar',
              controller: _locationController,
              prefixIcon: const Icon(
                Icons.location_on_rounded,
                color: RSColors.textSecondary,
                size: 20,
              ),
            ).animate(delay: 430.ms).fadeIn(duration: 400.ms),

            const SizedBox(height: RSSpacing.lg),

            // Description
            Text(
              'Descripción del incidente',
              style: RSTypography.titleLarge.copyWith(
                color: RSColors.textPrimary,
              ),
            ).animate(delay: 500.ms).fadeIn(duration: 400.ms),
            const SizedBox(height: RSSpacing.md),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText:
                    'Describe brevemente lo ocurrido: circunstancias, daños, lesiones...',
                hintStyle: RSTypography.bodyMedium.copyWith(
                  color: RSColors.textSecondary,
                ),
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
                  borderSide: const BorderSide(
                    color: RSColors.primary,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: RSColors.surface,
                contentPadding: const EdgeInsets.all(RSSpacing.md),
              ),
            ).animate(delay: 530.ms).fadeIn(duration: 400.ms),

            const SizedBox(height: RSSpacing.lg),

            // Photo evidence
            Text(
              'Evidencia fotográfica',
              style: RSTypography.titleLarge.copyWith(
                color: RSColors.textPrimary,
              ),
            ).animate(delay: 600.ms).fadeIn(duration: 400.ms),
            const SizedBox(height: RSSpacing.xs),
            Text(
              'Agrega fotos del incidente (mínimo 2)',
              style: RSTypography.bodyMedium.copyWith(
                color: RSColors.textSecondary,
              ),
            ).animate(delay: 620.ms).fadeIn(duration: 400.ms),
            const SizedBox(height: RSSpacing.md),
            Row(
              children: List.generate(
                3,
                (i) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i < 2 ? RSSpacing.sm : 0),
                    child: _PhotoSlot(
                      photo: _photos[i],
                      onTap: () => _pickPhoto(i),
                    ),
                  ),
                ),
              ),
            ).animate(delay: 650.ms).fadeIn(duration: 400.ms),

            const SizedBox(height: RSSpacing.xl),

            // Injuries toggle
            _InjuriesToggle(
              value: _hasInjuries,
              onChanged: (v) => setState(() => _hasInjuries = v),
            ).animate(delay: 700.ms).fadeIn(duration: 400.ms),

            const SizedBox(height: RSSpacing.xl),

            RSButton(
                  label: 'Enviar reporte',
                  isLoading: _isSubmitting,
                  onPressed: _isSubmitting ? null : _submit,
                )
                .animate(delay: 750.ms)
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.2),

            const SizedBox(height: RSSpacing.md),
            Center(
              child: Text(
                'Un asesor te contactará en las próximas 2 horas',
                style: RSTypography.caption.copyWith(
                  color: RSColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: RSSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

// ─── Active Policy Banner ─────────────────────────────────────────
class _ActivePolicyBanner extends ConsumerWidget {
  const _ActivePolicyBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final policyAsync = ref.watch(activePolicySummaryProvider);
    return policyAsync.when(
      loading: () => const SizedBox(height: 48),
      error: (_, __) => const SizedBox.shrink(),
      data: (policy) {
        if (policy == null) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.all(RSSpacing.md),
          decoration: BoxDecoration(
            color: RSColors.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(RSRadius.md),
            border: Border.all(color: RSColors.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.verified_user_rounded,
                color: RSColors.primary,
                size: 20,
              ),
              const SizedBox(width: RSSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Póliza activa verificada',
                      style: RSTypography.bodyMedium.copyWith(
                        color: RSColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${policy.planName} · ${policy.displayNumber} · Vence ${policy.formattedEndDate}',
                      style: RSTypography.caption.copyWith(
                        color: RSColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Progress Steps ───────────────────────────────────────────────
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
                      ? const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 16,
                        )
                      : Text(
                          '$stepNum',
                          style: RSTypography.caption.copyWith(
                            color: isActive
                                ? Colors.white
                                : RSColors.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  e.value,
                  style: RSTypography.caption.copyWith(
                    color: isActive ? RSColors.primary : RSColors.textSecondary,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.normal,
                  ),
                ),
              ),
              if (e.key < steps.length - 1)
                Expanded(
                  child: Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(
                      horizontal: RSSpacing.xs,
                    ),
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

// ─── Incident Type Card ───────────────────────────────────────────
class _IncidentType {
  final String id;
  final String label;
  final IconData icon;
  final Color color;
  const _IncidentType({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
  });
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
          horizontal: RSSpacing.md,
          vertical: RSSpacing.sm,
        ),
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
            Icon(
              type.icon,
              color: isSelected ? type.color : RSColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: RSSpacing.sm),
            Expanded(
              child: Text(
                type.label,
                style: RSTypography.bodyMedium.copyWith(
                  color: isSelected ? type.color : RSColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Date Time Tile (interactive) ────────────────────────────────
class _DateTimeTile extends StatelessWidget {
  const _DateTimeTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
            Expanded(
              child: Text(
                label,
                style: RSTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(
              Icons.edit_rounded,
              color: RSColors.textSecondary,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Photo Slot (real image_picker) ──────────────────────────────
class _PhotoSlot extends StatelessWidget {
  const _PhotoSlot({required this.photo, required this.onTap});
  final XFile? photo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photo != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 90,
        decoration: BoxDecoration(
          color: hasPhoto
              ? RSColors.success.withValues(alpha: 0.08)
              : RSColors.surfaceVariant,
          borderRadius: BorderRadius.circular(RSRadius.md),
          border: Border.all(
            color: hasPhoto ? RSColors.success : RSColors.border,
            width: hasPhoto ? 2 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(RSRadius.md - 1),
          child: hasPhoto
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(File(photo!.path), fit: BoxFit.cover),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          color: RSColors.success,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ],
                )
              : const Center(
                  child: Icon(
                    Icons.add_a_photo_rounded,
                    color: RSColors.textSecondary,
                    size: 28,
                  ),
                ),
        ),
      ),
    );
  }
}

// ─── Injuries Toggle ──────────────────────────────────────────────
class _InjuriesToggle extends StatelessWidget {
  const _InjuriesToggle({required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(RSSpacing.md),
      decoration: BoxDecoration(
        color: value
            ? RSColors.error.withValues(alpha: 0.05)
            : RSColors.surface,
        borderRadius: BorderRadius.circular(RSRadius.md),
        border: Border.all(color: value ? RSColors.error : RSColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¿Hubo lesionados?',
                  style: RSTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  value
                      ? 'Se activará asistencia médica inmediata'
                      : 'Incluye al conductor y/o terceros',
                  style: RSTypography.caption.copyWith(
                    color: value ? RSColors.error : RSColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: RSColors.error,
          ),
        ],
      ),
    );
  }
}

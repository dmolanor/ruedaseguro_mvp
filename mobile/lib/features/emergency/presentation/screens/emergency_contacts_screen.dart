import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ruedaseguro/core/services/supabase_service.dart';
import 'package:ruedaseguro/core/theme/colors.dart';
import 'package:ruedaseguro/core/theme/spacing.dart';
import 'package:ruedaseguro/core/theme/typography.dart';
import 'package:ruedaseguro/features/emergency/data/emergency_contact_repository.dart';
import 'package:ruedaseguro/shared/widgets/rs_button.dart';
import 'package:ruedaseguro/shared/widgets/rs_text_field.dart';

// ─── Provider ────────────────────────────────────────────────────────────────

/// Exposed for widget testing — override with a fake list via ProviderScope.
final emergencyContactsProvider =
    FutureProvider.autoDispose<List<EmergencyContact>>((ref) async {
      final uid = SupabaseService.auth.currentUser?.id;
      if (uid == null) return [];
      return EmergencyContactRepository.instance.fetchAll(uid);
    });

// ─── Screen ──────────────────────────────────────────────────────────────────

/// RS-089: List + add/edit/delete emergency contacts.
/// Used in onboarding (/onboarding/emergency-contacts) and profile settings.
class EmergencyContactsScreen extends ConsumerWidget {
  const EmergencyContactsScreen({super.key, this.onboardingMode = false});

  /// When true, shows a "Continuar" CTA at the bottom and blocks progress
  /// if no contacts have been added.
  final bool onboardingMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncContacts = ref.watch(emergencyContactsProvider);

    return Scaffold(
      backgroundColor: RSColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: onboardingMode
            ? null
            : IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: RSColors.primary,
                ),
                onPressed: () => context.pop(),
              ),
        title: Text(
          'Contactos de emergencia',
          style: RSTypography.titleLarge.copyWith(color: RSColors.primary),
        ),
      ),
      body: asyncContacts.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Error al cargar contactos',
            style: RSTypography.bodyMedium.copyWith(
              color: RSColors.textSecondary,
            ),
          ),
        ),
        data: (contacts) => _ContactsBody(
          contacts: contacts,
          onboardingMode: onboardingMode,
          onRefresh: () => ref.invalidate(emergencyContactsProvider),
        ),
      ),
    );
  }
}

// ─── Body ─────────────────────────────────────────────────────────────────────

class _ContactsBody extends StatelessWidget {
  const _ContactsBody({
    required this.contacts,
    required this.onboardingMode,
    required this.onRefresh,
  });

  final List<EmergencyContact> contacts;
  final bool onboardingMode;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(RSSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header copy
                Container(
                  padding: const EdgeInsets.all(RSSpacing.md),
                  decoration: BoxDecoration(
                    color: RSColors.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(RSRadius.md),
                    border: Border.all(
                      color: RSColors.primary.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        color: RSColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: RSSpacing.sm),
                      Expanded(
                        child: Text(
                          'Tu app puede avisarle a estas personas si detecta una caída o presionas el botón de emergencia.',
                          style: RSTypography.bodyMedium.copyWith(
                            color: RSColors.primary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms),

                const SizedBox(height: RSSpacing.lg),

                // Warning badge if empty
                if (contacts.isEmpty) ...[
                  _EmptyBadge().animate().fadeIn(
                    duration: 400.ms,
                    delay: 100.ms,
                  ),
                  const SizedBox(height: RSSpacing.lg),
                ],

                // Contact list
                ...contacts.asMap().entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: RSSpacing.sm),
                    child:
                        _ContactCard(
                              contact: e.value,
                              onEdit: () => _showContactSheet(
                                context,
                                onRefresh,
                                existing: e.value,
                              ),
                              onDelete: () =>
                                  _confirmDelete(context, e.value, onRefresh),
                            )
                            .animate(delay: (100 + e.key * 60).ms)
                            .fadeIn(duration: 300.ms),
                  ),
                ),

                const SizedBox(height: RSSpacing.sm),

                // Add button (max 5)
                if (contacts.length < 5)
                  OutlinedButton.icon(
                    onPressed: () => _showContactSheet(context, onRefresh),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: RSColors.primary,
                      side: const BorderSide(color: RSColors.primary),
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(RSRadius.md),
                      ),
                    ),
                    icon: const Icon(Icons.add_rounded),
                    label: Text(
                      contacts.isEmpty
                          ? 'Agregar contacto de emergencia'
                          : 'Agregar otro contacto',
                      style: RSTypography.titleMedium.copyWith(
                        color: RSColors.primary,
                      ),
                    ),
                  ).animate(delay: 200.ms).fadeIn(duration: 400.ms),

                const SizedBox(height: RSSpacing.sm),

                Center(
                  child: Text(
                    'Puedes agregar hasta 5 contactos. Podrás cambiarlos cuando quieras desde tu perfil.',
                    style: RSTypography.caption.copyWith(
                      color: RSColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Onboarding CTA
        if (onboardingMode)
          _OnboardingFooter(
            enabled: contacts.isNotEmpty,
            onContinue: () => context.go('/onboarding/consent'),
          ),
      ],
    );
  }

  void _showContactSheet(
    BuildContext context,
    VoidCallback onRefresh, {
    EmergencyContact? existing,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ContactSheet(
        existing: existing,
        onSaved: (_) {
          Navigator.of(context).pop();
          onRefresh();
        },
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    EmergencyContact contact,
    VoidCallback onRefresh,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar contacto'),
        content: Text(
          '¿Eliminar a ${contact.fullName} de tus contactos de emergencia?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await EmergencyContactRepository.instance.delete(contact.id);
              onRefresh();
            },
            style: TextButton.styleFrom(foregroundColor: RSColors.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

// ─── Empty Badge ──────────────────────────────────────────────────────────────

class _EmptyBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(RSSpacing.md),
      decoration: BoxDecoration(
        color: RSColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(RSRadius.md),
        border: Border.all(color: RSColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: RSColors.warning, size: 20),
          const SizedBox(width: RSSpacing.sm),
          Expanded(
            child: Text(
              'Agrega al menos un contacto de emergencia para activar la protección en la calle.',
              style: RSTypography.bodyMedium.copyWith(
                color: RSColors.warning,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Contact Card ─────────────────────────────────────────────────────────────

class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.contact,
    required this.onEdit,
    required this.onDelete,
  });

  final EmergencyContact contact;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(RSSpacing.md),
      decoration: BoxDecoration(
        color: RSColors.surface,
        borderRadius: BorderRadius.circular(RSRadius.md),
        border: Border.all(
          color: contact.isPrimary
              ? RSColors.primary.withValues(alpha: 0.4)
              : RSColors.border,
          width: contact.isPrimary ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: RSColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                contact.fullName.isNotEmpty
                    ? contact.fullName[0].toUpperCase()
                    : '?',
                style: RSTypography.titleLarge.copyWith(
                  color: RSColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: RSSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      contact.fullName,
                      style: RSTypography.titleMedium.copyWith(
                        color: RSColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (contact.isPrimary) ...[
                      const SizedBox(width: RSSpacing.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: RSColors.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Principal',
                          style: RSTypography.caption.copyWith(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${contact.phone}  ·  ${contact.relationLabel}',
                  style: RSTypography.bodyMedium.copyWith(
                    color: RSColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.edit_outlined,
              color: RSColors.textSecondary,
              size: 20,
            ),
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: RSColors.error,
              size: 20,
            ),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

// ─── Contact Sheet (Add/Edit) ─────────────────────────────────────────────────

class _ContactSheet extends StatefulWidget {
  const _ContactSheet({this.existing, required this.onSaved});

  final EmergencyContact? existing;
  final ValueChanged<EmergencyContact> onSaved;

  @override
  State<_ContactSheet> createState() => _ContactSheetState();
}

class _ContactSheetState extends State<_ContactSheet> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String? _relation = 'madre';
  bool _isPrimary = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _nameCtrl.text = widget.existing!.fullName;
      _phoneCtrl.text = widget.existing!.phone;
      _relation = widget.existing!.relation ?? 'madre';
      _isPrimary = widget.existing!.isPrimary;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  bool get _isValid =>
      _nameCtrl.text.trim().length >= 2 && _phoneCtrl.text.trim().length >= 10;

  Future<void> _save() async {
    if (!_isValid || _saving) return;
    setState(() => _saving = true);
    try {
      final contact = EmergencyContact(
        id: widget.existing?.id ?? '',
        profileId: '',
        fullName: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        relation: _relation,
        isPrimary: _isPrimary,
      );

      final saved = widget.existing != null
          ? await EmergencyContactRepository.instance.update(contact)
          : await EmergencyContactRepository.instance.insert(contact);

      widget.onSaved(saved);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(
        RSSpacing.lg,
        RSSpacing.lg,
        RSSpacing.lg,
        RSSpacing.lg + bottomInset,
      ),
      decoration: const BoxDecoration(
        color: RSColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(RSRadius.xl)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: RSColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: RSSpacing.lg),

          Text(
            widget.existing != null
                ? 'Editar contacto'
                : '¿A quién avisamos si te pasa algo?',
            style: RSTypography.titleLarge.copyWith(
              color: RSColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: RSSpacing.sm),
          Text(
            'Elige una persona de confianza para avisarle en caso de emergencia.',
            style: RSTypography.bodyMedium.copyWith(
              color: RSColors.textSecondary,
            ),
          ),
          const SizedBox(height: RSSpacing.lg),

          RSTextField(
            label: 'Nombre y apellido',
            hint: 'María Pérez',
            controller: _nameCtrl,
            onChanged: (_) => setState(() {}),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: RSSpacing.md),

          RSTextField(
            label: 'Número de teléfono',
            hint: '0414-1234567',
            controller: _phoneCtrl,
            onChanged: (_) => setState(() {}),
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9\-+]')),
            ],
          ),
          const SizedBox(height: RSSpacing.md),

          // Relation dropdown
          Text(
            'Parentesco',
            style: RSTypography.bodyMedium.copyWith(
              color: RSColors.textSecondary,
            ),
          ),
          const SizedBox(height: RSSpacing.xs),
          Container(
            decoration: BoxDecoration(
              color: RSColors.surface,
              borderRadius: BorderRadius.circular(RSRadius.md),
              border: Border.all(color: RSColors.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _relation,
                isExpanded: true,
                dropdownColor: RSColors.surface,
                padding: const EdgeInsets.symmetric(horizontal: RSSpacing.md),
                items: EmergencyContact.relationLabels.entries
                    .map(
                      (e) => DropdownMenuItem(
                        value: e.key,
                        child: Text(
                          e.value,
                          style: RSTypography.bodyMedium.copyWith(
                            color: RSColors.textPrimary,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _relation = v),
              ),
            ),
          ),
          const SizedBox(height: RSSpacing.md),

          // Primary toggle
          GestureDetector(
            onTap: () => setState(() => _isPrimary = !_isPrimary),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isPrimary ? RSColors.primary : Colors.transparent,
                    border: Border.all(
                      color: _isPrimary ? RSColors.primary : RSColors.border,
                      width: 2,
                    ),
                  ),
                  child: _isPrimary
                      ? const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 14,
                        )
                      : null,
                ),
                const SizedBox(width: RSSpacing.sm),
                Text(
                  'Contacto principal (primero a quien avisamos)',
                  style: RSTypography.bodyMedium.copyWith(
                    color: RSColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: RSSpacing.xl),

          RSButton(
            label: widget.existing != null
                ? 'Guardar cambios'
                : 'Guardar contacto',
            isLoading: _saving,
            onPressed: _isValid && !_saving ? _save : null,
          ),

          const SizedBox(height: RSSpacing.sm),
          Center(
            child: Text(
              'Podrás cambiarlo después cuando quieras.',
              style: RSTypography.caption.copyWith(
                color: RSColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Onboarding Footer ────────────────────────────────────────────────────────

class _OnboardingFooter extends StatelessWidget {
  const _OnboardingFooter({required this.enabled, required this.onContinue});
  final bool enabled;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        RSSpacing.lg,
        RSSpacing.md,
        RSSpacing.lg,
        RSSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: RSColors.background,
        border: Border(top: BorderSide(color: RSColors.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!enabled)
            Padding(
              padding: const EdgeInsets.only(bottom: RSSpacing.sm),
              child: Text(
                'Agrega al menos un contacto para continuar',
                style: RSTypography.caption.copyWith(
                  color: RSColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          RSButton(label: 'Continuar', onPressed: enabled ? onContinue : null),
          if (kDebugMode) ...[
            const SizedBox(height: RSSpacing.sm),
            Center(
              child: TextButton(
                onPressed: onContinue,
                child: const Text('[DEV] Omitir a Consentimiento'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// RS-068 — In-app "Reportar Problema" screen.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ruedaseguro/core/theme/colors.dart';
import 'package:ruedaseguro/core/theme/spacing.dart';
import 'package:ruedaseguro/core/theme/typography.dart';
import 'package:ruedaseguro/features/audit/data/audit_repository.dart';
import 'package:ruedaseguro/features/support/data/ticket_repository.dart';
import 'package:ruedaseguro/shared/providers/auth_provider.dart';
import 'package:ruedaseguro/shared/widgets/rs_button.dart';
import 'package:ruedaseguro/shared/widgets/rs_text_field.dart';

class CreateTicketScreen extends ConsumerStatefulWidget {
  const CreateTicketScreen({super.key});

  @override
  ConsumerState<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends ConsumerState<CreateTicketScreen> {
  static const _categories = [
    _TicketCategory(
      id: 'payment',
      label: 'Problema de pago',
      subtitle: 'Pago no reflejado, error en monto',
      icon: Icons.payment_rounded,
      priority: 'critical',
      color: Color(0xFFC62828),
    ),
    _TicketCategory(
      id: 'policy',
      label: 'Póliza o cobertura',
      subtitle: 'Datos incorrectos, no aparece activa',
      icon: Icons.policy_rounded,
      priority: 'high',
      color: Color(0xFFE65100),
    ),
    _TicketCategory(
      id: 'claim',
      label: 'Mi siniestro',
      subtitle: 'Estado, documentos faltantes',
      icon: Icons.car_crash_rounded,
      priority: 'high',
      color: Color(0xFF6A1B9A),
    ),
    _TicketCategory(
      id: 'app',
      label: 'Problema técnico',
      subtitle: 'Error en la app, no puedo ingresar',
      icon: Icons.bug_report_rounded,
      priority: 'medium',
      color: Color(0xFF1565C0),
    ),
    _TicketCategory(
      id: 'other',
      label: 'Otro',
      subtitle: 'Consulta general o sugerencia',
      icon: Icons.help_outline_rounded,
      priority: 'low',
      color: RSColors.textSecondary,
    ),
  ];

  int _selectedCategory = 0;
  bool _isSubmitting = false;
  bool _submitted = false;
  String? _ticketNumber;

  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final subject = _subjectController.text.trim();
    final description = _descriptionController.text.trim();

    if (subject.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Escribe un asunto para tu solicitud'),
          backgroundColor: RSColors.error,
        ),
      );
      return;
    }
    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Describe el problema con más detalle'),
          backgroundColor: RSColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final auth = ref.read(authProvider);
      final userId = auth.user?.id;

      if (userId == null) {
        // Demo mode
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          setState(() {
            _submitted = true;
            _ticketNumber = 'TKT-${DateTime.now().year}-DEMO01';
            _isSubmitting = false;
          });
        }
        return;
      }

      final category = _categories[_selectedCategory];
      final fullSubject = '[${category.label}] $subject';

      final (:ticketId, :ticketNumber) =
          await TicketRepository.instance.createTicket(
        profileId: userId,
        subject: fullSubject,
        description: description,
        priority: category.priority,
      );

      await AuditRepository.instance.logEvent(
        actorId: userId,
        eventType: 'ticket.created',
        targetId: ticketId,
        targetTable: 'tickets',
        payload: {'category': category.id, 'priority': category.priority},
      );

      if (mounted) {
        setState(() {
          _submitted = true;
          _ticketNumber = ticketNumber;
          _isSubmitting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: RSColors.error,
          ),
        );
      }
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: RSColors.primary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Reportar problema',
          style: RSTypography.titleLarge.copyWith(color: RSColors.primary),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: _submitted
            ? _SuccessView(
                key: const ValueKey('success'),
                ticketNumber: _ticketNumber ?? '',
                onDone: () => context.pop(),
              )
            : _FormView(
                key: const ValueKey('form'),
                categories: _categories,
                selectedCategory: _selectedCategory,
                onCategorySelected: (i) =>
                    setState(() => _selectedCategory = i),
                subjectController: _subjectController,
                descriptionController: _descriptionController,
                isSubmitting: _isSubmitting,
                onSubmit: _submit,
              ),
      ),
    );
  }
}

// ─── Form view ────────────────────────────────────────────────────
class _FormView extends StatelessWidget {
  const _FormView({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.subjectController,
    required this.descriptionController,
    required this.isSubmitting,
    required this.onSubmit,
  });

  final List<_TicketCategory> categories;
  final int selectedCategory;
  final ValueChanged<int> onCategorySelected;
  final TextEditingController subjectController;
  final TextEditingController descriptionController;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(RSSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '¿Cómo podemos ayudarte?',
            style: RSTypography.titleLarge.copyWith(color: RSColors.textPrimary),
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: RSSpacing.md),

          // Category selection
          ...categories.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: RSSpacing.sm),
                child: _CategoryCard(
                  category: e.value,
                  isSelected: selectedCategory == e.key,
                  onTap: () => onCategorySelected(e.key),
                )
                    .animate(delay: (60 * e.key).ms)
                    .fadeIn(duration: 300.ms)
                    .slideX(begin: 0.05),
              )),

          const SizedBox(height: RSSpacing.lg),

          Text('Asunto',
                  style: RSTypography.titleLarge
                      .copyWith(color: RSColors.textPrimary))
              .animate(delay: 350.ms)
              .fadeIn(duration: 300.ms),
          const SizedBox(height: RSSpacing.sm),
          RSTextField(
            hint: 'Resume el problema en una línea',
            controller: subjectController,
            textCapitalization: TextCapitalization.sentences,
          ).animate(delay: 380.ms).fadeIn(duration: 300.ms),

          const SizedBox(height: RSSpacing.lg),

          Text('Descripción',
                  style: RSTypography.titleLarge
                      .copyWith(color: RSColors.textPrimary))
              .animate(delay: 420.ms)
              .fadeIn(duration: 300.ms),
          const SizedBox(height: RSSpacing.sm),
          TextField(
            controller: descriptionController,
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText:
                  'Cuéntanos qué pasó, cuándo ocurrió y qué esperabas que pasara...',
              hintStyle: RSTypography.bodyMedium
                  .copyWith(color: RSColors.textSecondary),
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
                borderSide:
                    const BorderSide(color: RSColors.primary, width: 2),
              ),
              filled: true,
              fillColor: RSColors.surface,
              contentPadding: const EdgeInsets.all(RSSpacing.md),
            ),
          ).animate(delay: 450.ms).fadeIn(duration: 300.ms),

          const SizedBox(height: RSSpacing.xs),
          Text(
            'Prioridad asignada automáticamente según la categoría.',
            style: RSTypography.caption.copyWith(color: RSColors.textSecondary),
          ).animate(delay: 480.ms).fadeIn(duration: 300.ms),

          const SizedBox(height: RSSpacing.xl),

          RSButton(
            label: 'Enviar solicitud',
            isLoading: isSubmitting,
            onPressed: isSubmitting ? null : onSubmit,
          ).animate(delay: 520.ms).fadeIn(duration: 300.ms).slideY(begin: 0.2),

          const SizedBox(height: RSSpacing.xxl),
        ],
      ),
    );
  }
}

// ─── Success view ─────────────────────────────────────────────────
class _SuccessView extends StatelessWidget {
  const _SuccessView({
    super.key,
    required this.ticketNumber,
    required this.onDone,
  });
  final String ticketNumber;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(RSSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96, height: 96,
              decoration: BoxDecoration(
                color: RSColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: RSColors.success, size: 52),
            )
                .animate()
                .scale(
                    begin: const Offset(0.5, 0.5),
                    duration: 600.ms,
                    curve: Curves.elasticOut)
                .fadeIn(duration: 300.ms),

            const SizedBox(height: RSSpacing.xl),

            Text(
              '¡Solicitud enviada!',
              style: RSTypography.displayLarge.copyWith(
                color: RSColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.2),

            const SizedBox(height: RSSpacing.sm),

            Text(
              'Un asesor revisará tu caso y te contactará en las próximas horas.',
              style: RSTypography.bodyLarge.copyWith(
                  color: RSColors.textSecondary, height: 1.5),
              textAlign: TextAlign.center,
            ).animate(delay: 400.ms).fadeIn(),

            const SizedBox(height: RSSpacing.lg),

            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: RSSpacing.lg, vertical: RSSpacing.md),
              decoration: BoxDecoration(
                color: RSColors.surfaceVariant,
                borderRadius: BorderRadius.circular(RSRadius.md),
                border: Border.all(color: RSColors.border),
              ),
              child: Column(
                children: [
                  Text('Número de ticket',
                      style: RSTypography.caption
                          .copyWith(color: RSColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text(
                    ticketNumber,
                    style: RSTypography.mono.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: RSColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('Guarda este número para seguimiento',
                      style: RSTypography.caption
                          .copyWith(color: RSColors.textSecondary)),
                ],
              ),
            ).animate(delay: 500.ms).fadeIn().slideY(begin: 0.1),

            const SizedBox(height: RSSpacing.xl),

            RSButton(
              label: 'Listo',
              onPressed: onDone,
            ).animate(delay: 700.ms).fadeIn().slideY(begin: 0.2),
          ],
        ),
      ),
    );
  }
}

// ─── Category Card ────────────────────────────────────────────────
class _TicketCategory {
  final String id;
  final String label;
  final String subtitle;
  final IconData icon;
  final String priority;
  final Color color;

  const _TicketCategory({
    required this.id,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.priority,
    required this.color,
  });
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard(
      {required this.category, required this.isSelected, required this.onTap});
  final _TicketCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
            horizontal: RSSpacing.md, vertical: RSSpacing.sm + 2),
        decoration: BoxDecoration(
          color: isSelected
              ? category.color.withValues(alpha: 0.07)
              : RSColors.surface,
          borderRadius: BorderRadius.circular(RSRadius.md),
          border: Border.all(
              color: isSelected ? category.color : RSColors.border,
              width: isSelected ? 2 : 1),
        ),
        child: Row(
          children: [
            Icon(category.icon,
                color: isSelected ? category.color : RSColors.textSecondary,
                size: 22),
            const SizedBox(width: RSSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(category.label,
                      style: RSTypography.bodyMedium.copyWith(
                        color: isSelected
                            ? category.color
                            : RSColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      )),
                  Text(category.subtitle,
                      style: RSTypography.caption
                          .copyWith(color: RSColors.textSecondary)),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.radio_button_checked_rounded,
                  color: category.color, size: 20)
            else
              const Icon(Icons.radio_button_unchecked_rounded,
                  color: RSColors.border, size: 20),
          ],
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ruedaseguro/core/services/supabase_service.dart';
import 'package:ruedaseguro/core/theme/colors.dart';
import 'package:ruedaseguro/core/theme/spacing.dart';
import 'package:ruedaseguro/core/theme/typography.dart';
import 'package:ruedaseguro/features/emergency/data/emergency_contact_repository.dart';
import 'package:ruedaseguro/shared/widgets/rs_button.dart';

// ─── Preferences keys ─────────────────────────────────────────────────────────
const _kContactTimer = 'emergency_contact_timer_secs';
const _kAssistTimer = 'emergency_assist_timer_secs';
const _kSetupDone = 'emergency_setup_done';

// ─── Providers ───────────────────────────────────────────────────────────────

final _contactsForSetupProvider =
    FutureProvider.autoDispose<List<EmergencyContact>>((ref) async {
      final uid = SupabaseService.auth.currentUser?.id;
      if (uid == null) return [];
      return EmergencyContactRepository.instance.fetchAll(uid);
    });

// ─── Emergency Setup Screen ───────────────────────────────────────────────────

/// 5-step wizard: Pitch → Contact → Timers → Tutorial → Confirmation
/// Triggered from EmissionScreen post-success via "Activar servicios de emergencia".
/// Route: /emergency/setup
class EmergencySetupScreen extends ConsumerStatefulWidget {
  const EmergencySetupScreen({super.key, this.fromOnboarding = false});

  /// If true, navigating "back" from confirmation goes to /home instead of popping.
  final bool fromOnboarding;

  @override
  ConsumerState<EmergencySetupScreen> createState() =>
      _EmergencySetupScreenState();
}

class _EmergencySetupScreenState extends ConsumerState<EmergencySetupScreen> {
  final _pageCtrl = PageController();
  int _currentPage = 0;

  // Step 3 state — timer selection
  int _contactTimerSecs = 30;
  int _assistTimerSecs = 15;

  // Step 5 state — test mode
  bool _testRunning = false;
  int _testCountdown = 0;
  Timer? _testTimer;

  void _next() {
    if (_currentPage < 4) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage++);
    }
  }

  Future<void> _saveAndFinish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kContactTimer, _contactTimerSecs);
    await prefs.setInt(_kAssistTimer, _assistTimerSecs);
    await prefs.setBool(_kSetupDone, true);

    if (mounted) {
      widget.fromOnboarding ? context.go('/home') : context.pop();
    }
  }

  void _startTest() {
    setState(() {
      _testRunning = true;
      _testCountdown = 5;
    });
    _testTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _testCountdown--);
      if (_testCountdown <= 0) {
        t.cancel();
        setState(() => _testRunning = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Prueba completada! Así se verá tu alerta real.'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _testTimer?.cancel();
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RSColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar
            _ProgressBar(current: _currentPage, total: 5),

            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _PitchPage(onNext: _next),
                  _ContactPage(onNext: _next),
                  _TimersPage(
                    contactSecs: _contactTimerSecs,
                    assistSecs: _assistTimerSecs,
                    onContactChanged: (v) =>
                        setState(() => _contactTimerSecs = v),
                    onAssistChanged: (v) =>
                        setState(() => _assistTimerSecs = v),
                    onNext: _next,
                  ),
                  _TutorialPage(onNext: _next),
                  _ConfirmPage(
                    contactSecs: _contactTimerSecs,
                    assistSecs: _assistTimerSecs,
                    testRunning: _testRunning,
                    testCountdown: _testCountdown,
                    onTest: _startTest,
                    onFinish: _saveAndFinish,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Progress Bar ─────────────────────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.current, required this.total});
  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        RSSpacing.lg,
        RSSpacing.md,
        RSSpacing.lg,
        0,
      ),
      child: Row(
        children: List.generate(total, (i) {
          final done = i < current;
          final active = i == current;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i < total - 1 ? 4 : 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 4,
                decoration: BoxDecoration(
                  color: done || active ? RSColors.primary : RSColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─── Page 1: Pitch ────────────────────────────────────────────────────────────

class _PitchPage extends StatelessWidget {
  const _PitchPage({required this.onNext});
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(RSSpacing.lg),
      child: Column(
        children: [
          const Spacer(),
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: RSColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: RSColors.primary,
              size: 48,
            ),
          ).animate().scale(
            begin: const Offset(0.7, 0.7),
            duration: 500.ms,
            curve: Curves.elasticOut,
          ),
          const SizedBox(height: RSSpacing.xl),
          Text(
            'Activa tu respaldo en la calle',
            style: RSTypography.displayMedium.copyWith(
              color: RSColors.textPrimary,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ).animate(delay: 200.ms).fadeIn(duration: 400.ms),
          const SizedBox(height: RSSpacing.md),
          Text(
            'Si tienes una caída o un accidente, la app puede avisar por ti a una persona de confianza y pedir ayuda.',
            style: RSTypography.bodyLarge.copyWith(
              color: RSColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ).animate(delay: 300.ms).fadeIn(duration: 400.ms),
          const SizedBox(height: RSSpacing.sm),
          Text(
            'Tu app puede ayudarte cuando más lo necesites. No quedas solo en la calle.',
            style: RSTypography.bodyMedium.copyWith(
              color: RSColors.primary,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ).animate(delay: 400.ms).fadeIn(duration: 400.ms),
          const Spacer(),
          RSButton(
            label: 'Activarlo ahora',
            onPressed: onNext,
          ).animate(delay: 500.ms).fadeIn(duration: 400.ms).slideY(begin: 0.3),
          const SizedBox(height: RSSpacing.md),
          TextButton(
            onPressed: () => context.pop(),
            child: Text(
              'Hacerlo después',
              style: RSTypography.bodyMedium.copyWith(
                color: RSColors.textSecondary,
              ),
            ),
          ).animate(delay: 600.ms).fadeIn(duration: 400.ms),
          const SizedBox(height: RSSpacing.md),
        ],
      ),
    );
  }
}

// ─── Page 2: Contact ──────────────────────────────────────────────────────────

class _ContactPage extends ConsumerWidget {
  const _ContactPage({required this.onNext});
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_contactsForSetupProvider);

    return Padding(
      padding: const EdgeInsets.all(RSSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: RSSpacing.lg),
          Text(
            '¿A quién avisamos si te pasa algo?',
            style: RSTypography.displayMedium.copyWith(
              color: RSColors.textPrimary,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: RSSpacing.sm),
          Text(
            'Elige tus contactos de confianza. Ya los configuraste al crear tu cuenta — puedes agregarlos aquí también.',
            style: RSTypography.bodyMedium.copyWith(
              color: RSColors.textSecondary,
              height: 1.4,
            ),
          ).animate(delay: 100.ms).fadeIn(duration: 400.ms),
          const SizedBox(height: RSSpacing.xl),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text(
                  'Error al cargar contactos',
                  style: RSTypography.bodyMedium,
                ),
              ),
              data: (contacts) => contacts.isEmpty
                  ? _EmptyContactsHint(
                      onAdd: () {
                        context.push('/onboarding/emergency-contacts');
                      },
                    )
                  : ListView.separated(
                      itemCount: contacts.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: RSSpacing.sm),
                      itemBuilder: (_, i) => _ContactSummaryTile(
                        contact: contacts[i],
                      ).animate(delay: (i * 60).ms).fadeIn(duration: 300.ms),
                    ),
            ),
          ),
          const SizedBox(height: RSSpacing.lg),
          async
              .when(
                data: (c) => RSButton(
                  label: c.isEmpty ? 'Agregar contacto primero' : 'Continuar',
                  onPressed: c.isNotEmpty ? onNext : null,
                ),
                loading: () =>
                    const RSButton(label: 'Continuar', onPressed: null),
                error: (_, __) => const SizedBox.shrink(),
              )
              .animate(delay: 300.ms)
              .fadeIn(duration: 400.ms),
          const SizedBox(height: RSSpacing.md),
        ],
      ),
    );
  }
}

class _EmptyContactsHint extends StatelessWidget {
  const _EmptyContactsHint({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_add_outlined,
            color: RSColors.textSecondary,
            size: 48,
          ),
          const SizedBox(height: RSSpacing.md),
          Text(
            'Aún no tienes contactos guardados.',
            style: RSTypography.bodyLarge.copyWith(
              color: RSColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: RSSpacing.lg),
          OutlinedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Agregar contacto'),
            style: OutlinedButton.styleFrom(
              foregroundColor: RSColors.primary,
              side: const BorderSide(color: RSColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactSummaryTile extends StatelessWidget {
  const _ContactSummaryTile({required this.contact});
  final EmergencyContact contact;

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
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: RSColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                contact.fullName.isNotEmpty
                    ? contact.fullName[0].toUpperCase()
                    : '?',
                style: RSTypography.titleMedium.copyWith(
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
                Text(
                  contact.fullName,
                  style: RSTypography.titleMedium.copyWith(
                    color: RSColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${contact.phone}  ·  ${contact.relationLabel}',
                  style: RSTypography.bodyMedium.copyWith(
                    color: RSColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (contact.isPrimary)
            const Icon(Icons.star_rounded, color: RSColors.primary, size: 18),
        ],
      ),
    );
  }
}

// ─── Page 3: Timers ───────────────────────────────────────────────────────────

class _TimersPage extends StatelessWidget {
  const _TimersPage({
    required this.contactSecs,
    required this.assistSecs,
    required this.onContactChanged,
    required this.onAssistChanged,
    required this.onNext,
  });

  final int contactSecs;
  final int assistSecs;
  final ValueChanged<int> onContactChanged;
  final ValueChanged<int> onAssistChanged;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(RSSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: RSSpacing.lg),
          Text(
            'Configura tu ayuda de emergencia',
            style: RSTypography.displayMedium.copyWith(
              color: RSColors.textPrimary,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: RSSpacing.sm),
          Text(
            'Elige cuánto tiempo quieres que la app espere antes de avisar por ti.',
            style: RSTypography.bodyMedium.copyWith(
              color: RSColors.textSecondary,
              height: 1.4,
            ),
          ).animate(delay: 100.ms).fadeIn(duration: 400.ms),

          const SizedBox(height: RSSpacing.xl),

          _TimerSelector(
            label: 'Tiempo para avisar a tu contacto',
            description: 'Desde que presionas el botón o se detecta la caída.',
            options: const [10, 30, 60, 120],
            selected: contactSecs,
            onChanged: onContactChanged,
          ).animate(delay: 200.ms).fadeIn(duration: 400.ms),

          const SizedBox(height: RSSpacing.xl),

          _TimerSelector(
            label: 'Tiempo para pedir asistencia',
            description:
                'Si no respondes en este tiempo, se envía la alerta de emergencia.',
            options: const [15, 20, 30],
            selected: assistSecs,
            onChanged: onAssistChanged,
          ).animate(delay: 300.ms).fadeIn(duration: 400.ms),

          const SizedBox(height: RSSpacing.md),
          Container(
            padding: const EdgeInsets.all(RSSpacing.md),
            decoration: BoxDecoration(
              color: RSColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(RSRadius.md),
            ),
            child: Text(
              'Si la app detecta una caída fuerte, te mostrará una alerta en pantalla. Si no la detienes a tiempo, avisará automáticamente.',
              style: RSTypography.bodyMedium.copyWith(
                color: RSColors.primary,
                height: 1.4,
              ),
            ),
          ).animate(delay: 400.ms).fadeIn(duration: 400.ms),

          const SizedBox(height: RSSpacing.xl),
          RSButton(
            label: 'Guardar configuración',
            onPressed: onNext,
          ).animate(delay: 500.ms).fadeIn(duration: 400.ms),
          const SizedBox(height: RSSpacing.xl),
        ],
      ),
    );
  }
}

class _TimerSelector extends StatelessWidget {
  const _TimerSelector({
    required this.label,
    required this.description,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final String label;
  final String description;
  final List<int> options;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: RSTypography.titleMedium.copyWith(
            color: RSColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: RSTypography.bodyMedium.copyWith(
            color: RSColors.textSecondary,
            height: 1.3,
          ),
        ),
        const SizedBox(height: RSSpacing.md),
        Wrap(
          spacing: RSSpacing.sm,
          children: options.map((secs) {
            final isSelected = secs == selected;
            final label = secs < 60 ? '$secs segundos' : '${secs ~/ 60} min';
            return GestureDetector(
              onTap: () => onChanged(secs),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: RSSpacing.md,
                  vertical: RSSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? RSColors.primary : RSColors.surface,
                  borderRadius: BorderRadius.circular(RSRadius.md),
                  border: Border.all(
                    color: isSelected ? RSColors.primary : RSColors.border,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Text(
                  label,
                  style: RSTypography.titleMedium.copyWith(
                    color: isSelected ? Colors.white : RSColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ─── Page 4: Tutorial ─────────────────────────────────────────────────────────

class _TutorialPage extends StatelessWidget {
  const _TutorialPage({required this.onNext});
  final VoidCallback onNext;

  static const _steps = [
    (
      Icons.sensors_rounded,
      'Detecta la caída',
      'La app detecta una caída fuerte o tú presionas el botón de emergencia',
    ),
    (
      Icons.notifications_active_rounded,
      'Te avisamos primero',
      'Te mostramos una alerta en pantalla. Si respondes, cancelamos todo',
    ),
    (
      Icons.person_pin_circle_outlined,
      'Avisamos a tu contacto',
      'Si no respondes a tiempo, enviamos tu ubicación a tu contacto de confianza',
    ),
    (
      Icons.local_hospital_rounded,
      'Pedimos asistencia',
      'Iniciamos la solicitud de asistencia de emergencia con tu número de póliza',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(RSSpacing.lg),
      child: Column(
        children: [
          const SizedBox(height: RSSpacing.lg),
          Text(
            'Así funciona tu ayuda de emergencia',
            style: RSTypography.displayMedium.copyWith(
              color: RSColors.textPrimary,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: RSSpacing.xl),
          ..._steps.asMap().entries.map((e) {
            final (icon, title, desc) = e.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: RSSpacing.lg),
              child:
                  Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: RSColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              icon,
                              color: RSColors.primary,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: RSSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  title,
                                  style: RSTypography.titleMedium.copyWith(
                                    color: RSColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  desc,
                                  style: RSTypography.bodyMedium.copyWith(
                                    color: RSColors.textSecondary,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                      .animate(delay: (e.key * 100).ms)
                      .fadeIn(duration: 400.ms)
                      .slideX(begin: 0.05),
            );
          }),
          const Spacer(),
          RSButton(
            label: 'Entendido',
            onPressed: onNext,
          ).animate(delay: 500.ms).fadeIn(duration: 400.ms),
          const SizedBox(height: RSSpacing.md),
        ],
      ),
    );
  }
}

// ─── Page 5: Confirmation ─────────────────────────────────────────────────────

class _ConfirmPage extends ConsumerWidget {
  const _ConfirmPage({
    required this.contactSecs,
    required this.assistSecs,
    required this.testRunning,
    required this.testCountdown,
    required this.onTest,
    required this.onFinish,
  });

  final int contactSecs;
  final int assistSecs;
  final bool testRunning;
  final int testCountdown;
  final VoidCallback onTest;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactsAsync = ref.watch(_contactsForSetupProvider);
    final primaryContact = contactsAsync.value
        ?.where((c) => c.isPrimary)
        .firstOrNull;

    return Padding(
      padding: const EdgeInsets.all(RSSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: RSSpacing.lg),

          // Success icon
          Center(
            child:
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2E7D32),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 38,
                  ),
                ).animate().scale(
                  begin: const Offset(0.5, 0.5),
                  duration: 500.ms,
                  curve: Curves.elasticOut,
                ),
          ),
          const SizedBox(height: RSSpacing.lg),
          Center(
            child: Text(
              'Tu respaldo ya está activo',
              style: RSTypography.displayMedium.copyWith(
                color: RSColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ).animate(delay: 200.ms).fadeIn(duration: 400.ms),
          ),
          const SizedBox(height: RSSpacing.xl),

          // Summary
          _SummaryRow(
            icon: Icons.person_rounded,
            label: 'Contacto principal',
            value: primaryContact?.fullName ?? 'Sin contacto principal',
          ),
          if (primaryContact != null)
            _SummaryRow(
              icon: Icons.phone_rounded,
              label: 'Teléfono',
              value: primaryContact.phone,
            ),
          _SummaryRow(
            icon: Icons.timer_outlined,
            label: 'Aviso al contacto',
            value: contactSecs < 60
                ? '$contactSecs segundos'
                : '${contactSecs ~/ 60} minuto(s)',
          ),
          _SummaryRow(
            icon: Icons.local_hospital_rounded,
            label: 'Aviso a asistencia',
            value: '$assistSecs segundos',
          ),

          const Spacer(),

          // Test alert button
          if (testRunning)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(RSSpacing.lg),
              decoration: BoxDecoration(
                color: const Color(0xFF0D0D0D),
                borderRadius: BorderRadius.circular(RSRadius.lg),
              ),
              child: Column(
                children: [
                  Text(
                    '¿Necesitas ayuda?',
                    style: RSTypography.titleLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: RSSpacing.sm),
                  Text(
                    'Enviando en $testCountdown...',
                    style: RSTypography.displayMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: RSSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: Text(
                        'ESTOY BIEN',
                        style: RSTypography.titleLarge.copyWith(
                          color: const Color(0xFF0D0D0D),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms)
          else
            OutlinedButton.icon(
              onPressed: onTest,
              icon: const Icon(Icons.play_circle_outline_rounded),
              label: const Text('Hacer una prueba ahora'),
              style: OutlinedButton.styleFrom(
                foregroundColor: RSColors.primary,
                side: const BorderSide(color: RSColors.primary),
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(RSRadius.md),
                ),
              ),
            ).animate(delay: 400.ms).fadeIn(duration: 400.ms),

          const SizedBox(height: RSSpacing.md),

          RSButton(
            label: 'Volver al inicio',
            onPressed: testRunning ? null : onFinish,
          ).animate(delay: 500.ms).fadeIn(duration: 400.ms),

          const SizedBox(height: RSSpacing.md),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: RSSpacing.md),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: RSColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: RSColors.primary, size: 18),
          ),
          const SizedBox(width: RSSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: RSTypography.caption.copyWith(
                  color: RSColors.textSecondary,
                ),
              ),
              Text(
                value,
                style: RSTypography.titleMedium.copyWith(
                  color: RSColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

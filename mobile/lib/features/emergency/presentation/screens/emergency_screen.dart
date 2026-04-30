import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ruedaseguro/core/services/supabase_service.dart';
import 'package:ruedaseguro/core/theme/spacing.dart';
import 'package:ruedaseguro/core/theme/typography.dart';
import 'package:ruedaseguro/features/emergency/data/emergency_contact_repository.dart';

// ─── Constants ────────────────────────────────────────────────────────────────
const _kAssistTimer = 'emergency_assist_timer_secs';

// ─── Urgency level ────────────────────────────────────────────────────────────

enum UrgencyLevel {
  accidentWithInjuries(
    'Accidente con lesiones',
    'Necesito atención médica urgente',
    Color(0xFFC62828),
  ),
  accidentNoInjuries(
    'Accidente sin lesiones',
    'Golpe o caída — sin heridos',
    Color(0xFFE65100),
  ),
  assistanceOnly(
    'Solo necesito asistencia',
    'Moto varada o problema en la vía',
    Color(0xFF1565C0),
  );

  const UrgencyLevel(this.label, this.description, this.color);
  final String label;
  final String description;
  final Color color;
}

// ─── Activation type ─────────────────────────────────────────────────────────

enum EmergencyActivationType { manual, autoFall }

// ─── Dispatch phase ───────────────────────────────────────────────────────────
// Controls what the cancel button can actually do.

enum _DispatchPhase {
  countdown, // Nothing sent yet — full cancel available
  sentToService, // Assistance notified; contact not yet sent
  sentToAll, // Both assistance and contact notified
}

// ─── Screen ──────────────────────────────────────────────────────────────────

class EmergencyScreen extends ConsumerStatefulWidget {
  const EmergencyScreen({
    super.key,
    this.activationType = EmergencyActivationType.manual,
  });

  final EmergencyActivationType activationType;

  @override
  ConsumerState<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends ConsumerState<EmergencyScreen>
    with TickerProviderStateMixin {
  // State machine
  UrgencyLevel? _urgency;
  bool _showUrgencySheet = false;
  int _countdown = 15;
  bool _cancelled = false;
  bool _activated = false;
  _DispatchPhase _phase = _DispatchPhase.countdown;
  String? _caseId;

  // Contacts
  List<EmergencyContact> _contacts = [];

  // Animation
  late final AnimationController _pulseController;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _loadContactsAndCountdown();
  }

  Future<void> _loadContactsAndCountdown() async {
    final uid = SupabaseService.auth.currentUser?.id;
    if (uid != null) {
      _contacts = await EmergencyContactRepository.instance.fetchAll(uid);
    }

    final prefs = await SharedPreferences.getInstance();
    final savedTimer = prefs.getInt(_kAssistTimer) ?? 15;

    if (widget.activationType == EmergencyActivationType.manual) {
      // Manual: show urgency bottom-sheet first, then start countdown
      if (mounted) setState(() => _showUrgencySheet = true);
    } else {
      // Auto-fall: longer countdown (user may be stunned)
      if (mounted) setState(() => _countdown = savedTimer + 5);
      _startCountdown();
    }
  }

  void _onUrgencySelected(UrgencyLevel level) {
    setState(() {
      _urgency = level;
      _showUrgencySheet = false;
    });
    _startCountdown();
  }

  void _startCountdown() {
    // Haptic + vibration feedback
    HapticFeedback.heavyImpact();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        if (_countdown > 0) {
          _countdown--;

          // Phase transition: service notified at 50% of countdown
          if (_countdown == (_countdown ~/ 2) &&
              _phase == _DispatchPhase.countdown) {
            _phase = _DispatchPhase.sentToService;
          }
        } else {
          t.cancel();
          _dispatch();
        }
      });
    });
  }

  void _dispatch() {
    final ts = DateTime.now().millisecondsSinceEpoch % 10000000;
    setState(() {
      _activated = true;
      _phase = _DispatchPhase.sentToAll;
      _caseId = 'RS-EMG-$ts';
    });
    HapticFeedback.heavyImpact();
  }

  void _cancel() {
    _timer?.cancel();
    if (_phase == _DispatchPhase.sentToAll) {
      // Already fully dispatched — show "I'm OK" state instead
      setState(() => _activated = true);
      return;
    }
    setState(() => _cancelled = true);
    HapticFeedback.lightImpact();
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) context.pop();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cancelled) return const _CancelledView();
    if (_activated) {
      return _ActivatedView(
        caseId: _caseId,
        contacts: _contacts,
        urgency: _urgency,
        phase: _phase,
      );
    }

    final isAutoFall =
        widget.activationType == EmergencyActivationType.autoFall;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFF0D0D0D),
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(RSSpacing.md),
                  child: Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white54,
                        size: 28,
                      ),
                      onPressed: _showUrgencySheet ? null : _cancel,
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _PulsingSosRing(
                          controller: _pulseController,
                          urgency: _urgency,
                        ).animate().fadeIn(duration: 400.ms),
                        const SizedBox(height: RSSpacing.xl),
                        if (isAutoFall)
                          Text(
                            'DETECTAMOS UNA CAÍDA FUERTE',
                            style: RSTypography.caption.copyWith(
                              color: Colors.white54,
                              letterSpacing: 2,
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.center,
                          ).animate(delay: 200.ms).fadeIn(duration: 400.ms)
                        else
                          Text(
                            'MODO EMERGENCIA',
                            style: RSTypography.caption.copyWith(
                              color: Colors.white54,
                              letterSpacing: 3,
                              fontWeight: FontWeight.w700,
                            ),
                          ).animate(delay: 200.ms).fadeIn(duration: 400.ms),
                        const SizedBox(height: RSSpacing.sm),
                        Text(
                          _showUrgencySheet
                              ? 'Selecciona el tipo de ayuda...'
                              : 'Activando en $_countdown segundos',
                          style: RSTypography.displayMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ).animate().fadeIn(duration: 300.ms),
                        const SizedBox(height: RSSpacing.md),
                        Text(
                          isAutoFall
                              ? 'Si estás bien, detén esta alerta ahora.\nSi no respondes, avisaremos por ti.'
                              : 'Vamos a avisar a tu contacto y pedir asistencia.',
                          style: RSTypography.bodyLarge.copyWith(
                            color: Colors.white60,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ).animate(delay: 300.ms).fadeIn(duration: 400.ms),
                        const SizedBox(height: RSSpacing.xl),
                        _PhaseIndicators(
                          phase: _phase,
                          contacts: _contacts,
                        ).animate(delay: 400.ms).fadeIn(duration: 400.ms),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(RSSpacing.lg),
                  child: Column(
                    children: [
                      _GpsRow().animate(delay: 500.ms).fadeIn(duration: 400.ms),
                      const SizedBox(height: RSSpacing.lg),
                      // Cancel button — must be large and easy to tap
                      GestureDetector(
                            onTap: _showUrgencySheet ? null : _cancel,
                            child: Container(
                              width: double.infinity,
                              height: 68,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(34),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  'ESTOY BIEN — CANCELAR',
                                  style: RSTypography.titleLarge.copyWith(
                                    color: const Color(0xFF0D0D0D),
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          )
                          .animate(delay: 600.ms)
                          .fadeIn(duration: 400.ms)
                          .scale(begin: const Offset(0.9, 0.9)),
                      const SizedBox(height: RSSpacing.sm),
                      Text(
                        'Toca para cancelar la alerta',
                        style: RSTypography.caption.copyWith(
                          color: Colors.white38,
                        ),
                      ),
                      const SizedBox(height: RSSpacing.xl),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Urgency selection bottom-sheet overlay
        if (_showUrgencySheet) _UrgencySheet(onSelected: _onUrgencySelected),
      ],
    );
  }
}

// ─── Urgency Sheet ─────────────────────────────────────────────────────────────

class _UrgencySheet extends StatelessWidget {
  const _UrgencySheet({required this.onSelected});
  final ValueChanged<UrgencyLevel> onSelected;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child:
          Container(
                padding: const EdgeInsets.fromLTRB(
                  RSSpacing.lg,
                  RSSpacing.lg,
                  RSSpacing.lg,
                  RSSpacing.xxl,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(RSRadius.xl),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: RSSpacing.lg),
                    Text(
                      '¿Qué tipo de ayuda necesitas?',
                      style: RSTypography.titleLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: RSSpacing.sm),
                    Text(
                      'Esto nos ayuda a enviarte el tipo de asistencia correcto.',
                      style: RSTypography.bodyMedium.copyWith(
                        color: Colors.white54,
                      ),
                    ),
                    const SizedBox(height: RSSpacing.lg),
                    ...UrgencyLevel.values.map(
                      (level) => Padding(
                        padding: const EdgeInsets.only(bottom: RSSpacing.sm),
                        child: GestureDetector(
                          onTap: () => onSelected(level),
                          child: Container(
                            padding: const EdgeInsets.all(RSSpacing.md),
                            decoration: BoxDecoration(
                              color: level.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(RSRadius.md),
                              border: Border.all(
                                color: level.color.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: level.color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: RSSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        level.label,
                                        style: RSTypography.titleMedium
                                            .copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      Text(
                                        level.description,
                                        style: RSTypography.bodyMedium.copyWith(
                                          color: Colors.white60,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  color: Colors.white38,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
              .animate()
              .slideY(begin: 1.0, duration: 400.ms, curve: Curves.easeOutCubic)
              .fadeIn(duration: 300.ms),
    );
  }
}

// ─── Phase Indicators ─────────────────────────────────────────────────────────

class _PhaseIndicators extends StatelessWidget {
  const _PhaseIndicators({required this.phase, required this.contacts});
  final _DispatchPhase phase;
  final List<EmergencyContact> contacts;

  @override
  Widget build(BuildContext context) {
    final gpsActive = true;
    final contactActive = phase == _DispatchPhase.sentToAll;
    final serviceActive = phase != _DispatchPhase.countdown;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _IndicatorDot(
          label: 'GPS activo',
          icon: Icons.gps_fixed_rounded,
          isActive: gpsActive,
        ),
        const SizedBox(width: RSSpacing.xl),
        _IndicatorDot(
          label: 'Contacto avisado',
          icon: Icons.person_rounded,
          isActive: contactActive,
        ),
        const SizedBox(width: RSSpacing.xl),
        _IndicatorDot(
          label: 'Asistencia',
          icon: Icons.local_hospital_rounded,
          isActive: serviceActive,
        ),
      ],
    );
  }
}

class _IndicatorDot extends StatelessWidget {
  const _IndicatorDot({
    required this.label,
    required this.icon,
    required this.isActive,
  });
  final String label;
  final IconData icon;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFF2E7D32).withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.05),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isActive ? const Color(0xFF81C784) : Colors.white30,
            size: 20,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: RSTypography.caption.copyWith(
            color: isActive ? Colors.white70 : Colors.white30,
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ─── GPS Row ──────────────────────────────────────────────────────────────────

class _GpsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: RSSpacing.md,
        vertical: RSSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(RSRadius.md),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.location_on_rounded,
            color: Color(0xFF81C784),
            size: 18,
          ),
          const SizedBox(width: RSSpacing.sm),
          Expanded(
            child: Text(
              'Obteniendo ubicación GPS...',
              style: RSTypography.mono.copyWith(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF81C784),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Pulsing SOS Ring ─────────────────────────────────────────────────────────

class _PulsingSosRing extends StatelessWidget {
  const _PulsingSosRing({required this.controller, this.urgency});
  final AnimationController controller;
  final UrgencyLevel? urgency;

  @override
  Widget build(BuildContext context) {
    final baseColor = urgency?.color ?? const Color(0xFFC62828);

    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final pulse = controller.value;
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 200 + pulse * 20,
              height: 200 + pulse * 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: baseColor.withValues(alpha: 0.1 + pulse * 0.05),
                  width: 1,
                ),
              ),
            ),
            Container(
              width: 170 + pulse * 15,
              height: 170 + pulse * 15,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: baseColor.withValues(alpha: 0.2 + pulse * 0.1),
                  width: 1.5,
                ),
              ),
            ),
            Container(
              width: 140 + pulse * 10,
              height: 140 + pulse * 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: baseColor.withValues(alpha: 0.1 + pulse * 0.08),
              ),
            ),
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [baseColor, baseColor.withValues(alpha: 0.9)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: baseColor.withValues(alpha: 0.5 + pulse * 0.2),
                    blurRadius: 24 + pulse * 8,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'SOS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Activated View ───────────────────────────────────────────────────────────

class _ActivatedView extends StatelessWidget {
  const _ActivatedView({
    this.caseId,
    required this.contacts,
    this.urgency,
    required this.phase,
  });

  final String? caseId;
  final List<EmergencyContact> contacts;
  final UrgencyLevel? urgency;
  final _DispatchPhase phase;

  @override
  Widget build(BuildContext context) {
    final alreadySentToAll = phase == _DispatchPhase.sentToAll;
    final contactNames = contacts.map((c) => c.fullName).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(RSSpacing.lg),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: RSSpacing.md),
                  child: IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white54,
                      size: 28,
                    ),
                    onPressed: () => context.pop(),
                  ),
                ),
              ),
              const Spacer(),
              Container(
                    width: 100,
                    height: 100,
                    decoration: const BoxDecoration(
                      color: Color(0xFFC62828),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.sos_rounded,
                      color: Colors.white,
                      size: 52,
                    ),
                  )
                  .animate()
                  .scale(
                    begin: const Offset(0.5, 0.5),
                    duration: 500.ms,
                    curve: Curves.elasticOut,
                  )
                  .fadeIn(duration: 300.ms),
              const SizedBox(height: RSSpacing.xl),
              Text(
                '¡Emergencia activada!',
                style: RSTypography.displayLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ).animate(delay: 300.ms).fadeIn(duration: 400.ms),
              if (caseId != null) ...[
                const SizedBox(height: RSSpacing.sm),
                Text(
                  'Caso: $caseId',
                  style: RSTypography.mono.copyWith(
                    color: Colors.white38,
                    fontSize: 13,
                  ),
                ).animate(delay: 350.ms).fadeIn(duration: 400.ms),
              ],
              const SizedBox(height: RSSpacing.md),
              if (contactNames.isNotEmpty)
                Text(
                  'Contactando a:\n${contactNames.map((n) => '• $n').join('\n')}',
                  style: RSTypography.bodyLarge.copyWith(
                    color: Colors.white60,
                    height: 1.7,
                  ),
                  textAlign: TextAlign.center,
                ).animate(delay: 400.ms).fadeIn(duration: 400.ms)
              else
                Text(
                  'Notificando a los servicios de asistencia.',
                  style: RSTypography.bodyLarge.copyWith(
                    color: Colors.white60,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ).animate(delay: 400.ms).fadeIn(duration: 400.ms),
              const SizedBox(height: RSSpacing.xl),
              _StatusItem(
                icon: Icons.gps_fixed_rounded,
                label: 'Ubicación enviada',
                active: true,
              ).animate(delay: 600.ms).fadeIn(duration: 400.ms),
              const SizedBox(height: RSSpacing.md),
              _StatusItem(
                icon: Icons.medical_services_rounded,
                label: alreadySentToAll
                    ? 'Solicitud de asistencia enviada'
                    : 'Solicitando asistencia de emergencia...',
                active: alreadySentToAll,
              ).animate(delay: 800.ms).fadeIn(duration: 400.ms),
              const Spacer(),

              // Phase-aware action buttons
              if (alreadySentToAll) ...[
                _ActionRow(
                  icon: Icons.check_circle_outline_rounded,
                  label: 'Estoy bien — sin ayuda',
                  color: const Color(0xFF81C784),
                  onTap: () => context.pop(),
                ).animate(delay: 900.ms).fadeIn(duration: 400.ms),
                const SizedBox(height: RSSpacing.sm),
                _ActionRow(
                  icon: Icons.info_outline_rounded,
                  label: 'Ver estado del caso',
                  color: Colors.white54,
                  onTap: () {},
                ).animate(delay: 1000.ms).fadeIn(duration: 400.ms),
                const SizedBox(height: RSSpacing.sm),
              ],

              ElevatedButton(
                onPressed: () => context.pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF0D0D0D),
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(RSRadius.md),
                  ),
                ),
                child: Text(
                  'Volver al inicio',
                  style: RSTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ).animate(delay: 1000.ms).fadeIn(duration: 400.ms),
              const SizedBox(height: RSSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: RSSpacing.md,
          vertical: RSSpacing.sm + 2,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(RSRadius.md),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: RSSpacing.md),
            Text(
              label,
              style: RSTypography.bodyMedium.copyWith(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusItem extends StatelessWidget {
  const _StatusItem({
    required this.icon,
    required this.label,
    required this.active,
  });
  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: active ? const Color(0xFF81C784) : Colors.white38,
          size: 18,
        ),
        const SizedBox(width: RSSpacing.md),
        Expanded(
          child: Text(
            label,
            style: RSTypography.bodyMedium.copyWith(
              color: active ? Colors.white70 : Colors.white38,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Cancelled View ───────────────────────────────────────────────────────────

class _CancelledView extends StatelessWidget {
  const _CancelledView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF81C784),
              size: 80,
            ).animate().scale(
              begin: const Offset(0.5, 0.5),
              duration: 400.ms,
              curve: Curves.elasticOut,
            ),
            const SizedBox(height: RSSpacing.xl),
            Text(
              'Emergencia cancelada',
              style: RSTypography.displayMedium.copyWith(color: Colors.white),
            ).animate(delay: 200.ms).fadeIn(duration: 400.ms),
            const SizedBox(height: RSSpacing.md),
            Text(
              'Nos alegra que estés bien.',
              style: RSTypography.bodyLarge.copyWith(color: Colors.white54),
            ).animate(delay: 300.ms).fadeIn(duration: 400.ms),
          ],
        ),
      ),
    );
  }
}

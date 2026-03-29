import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import 'package:ruedaseguro/core/theme/spacing.dart';
import 'package:ruedaseguro/core/theme/typography.dart';
import 'package:ruedaseguro/core/data/mock_data.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen>
    with TickerProviderStateMixin {
  int _countdown = 10;
  Timer? _timer;
  bool _activated = false;
  bool _cancelled = false;

  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_countdown > 0) {
          _countdown--;
        } else {
          _timer?.cancel();
          _activated = true;
        }
      });
    });
  }

  void _cancel() {
    _timer?.cancel();
    setState(() => _cancelled = true);
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
    if (_cancelled) return _CancelledView();
    if (_activated) return _ActivatedView();

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: Column(
          children: [
            // Close button
            Padding(
              padding: const EdgeInsets.all(RSSpacing.md),
              child: Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: Colors.white54, size: 28),
                  onPressed: _cancel,
                ),
              ),
            ),

            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Pulsing SOS ring
                  _PulsingSosRing(controller: _pulseController)
                      .animate()
                      .fadeIn(duration: 400.ms),

                  const SizedBox(height: RSSpacing.xl),

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
                    'Activando en $_countdown segundos',
                    style: RSTypography.displayMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ).animate().fadeIn(duration: 300.ms),

                  const SizedBox(height: RSSpacing.md),

                  Text(
                    'Si no puedes responder, mantenemos\ntu posición y contactamos a tu familia.',
                    style: RSTypography.bodyLarge.copyWith(
                      color: Colors.white60,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ).animate(delay: 300.ms).fadeIn(duration: 400.ms),

                  const SizedBox(height: RSSpacing.xxl),

                  // Status indicators
                  _StatusIndicators()
                      .animate(delay: 400.ms)
                      .fadeIn(duration: 400.ms),
                ],
              ),
            ),

            // GPS + Cancel
            Padding(
              padding: const EdgeInsets.all(RSSpacing.lg),
              child: Column(
                children: [
                  _GpsRow()
                      .animate(delay: 500.ms)
                      .fadeIn(duration: 400.ms),

                  const SizedBox(height: RSSpacing.lg),

                  // Cancel button
                  GestureDetector(
                    onTap: _cancel,
                    child: Container(
                      width: 200,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
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
                          'ESTOY BIEN',
                          style: RSTypography.titleLarge.copyWith(
                            color: const Color(0xFF0D0D0D),
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  )
                      .animate(delay: 600.ms)
                      .fadeIn(duration: 400.ms)
                      .scale(begin: const Offset(0.9, 0.9)),

                  const SizedBox(height: RSSpacing.md),

                  Text(
                    'Toca para cancelar la alerta',
                    style: RSTypography.caption.copyWith(color: Colors.white38),
                  ),

                  const SizedBox(height: RSSpacing.xl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Pulsing SOS Ring ────────────────────────────────────────────
class _PulsingSosRing extends StatelessWidget {
  const _PulsingSosRing({required this.controller});
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final pulse = controller.value;
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer ring 3
            Container(
              width: 200 + pulse * 20,
              height: 200 + pulse * 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFC62828).withValues(alpha: 0.1 + pulse * 0.05),
                  width: 1,
                ),
              ),
            ),
            // Outer ring 2
            Container(
              width: 170 + pulse * 15,
              height: 170 + pulse * 15,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFC62828).withValues(alpha: 0.2 + pulse * 0.1),
                  width: 1.5,
                ),
              ),
            ),
            // Outer ring 1
            Container(
              width: 140 + pulse * 10,
              height: 140 + pulse * 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFC62828).withValues(alpha: 0.1 + pulse * 0.08),
              ),
            ),
            // Inner circle
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFE53935),
                    const Color(0xFFC62828).withValues(alpha: 0.9),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFC62828).withValues(alpha: 0.5 + pulse * 0.2),
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

// ─── Status Indicators ───────────────────────────────────────────
class _StatusIndicators extends StatelessWidget {
  const _StatusIndicators();

  @override
  Widget build(BuildContext context) {
    final items = [
      ('GPS activo', Icons.gps_fixed_rounded, true),
      ('Contacto notificado', Icons.person_rounded, false),
      ('Asistencia en camino', Icons.local_hospital_rounded, false),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: items
          .asMap()
          .entries
          .map((e) {
            final (label, icon, isActive) = e.value;
            return Padding(
              padding: EdgeInsets.only(
                  right: e.key < items.length - 1 ? RSSpacing.xl : 0),
              child: Column(
                children: [
                  Container(
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
                      color: isActive
                          ? const Color(0xFF81C784)
                          : Colors.white30,
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
              ),
            );
          })
          .toList(),
    );
  }
}

// ─── GPS Row ─────────────────────────────────────────────────────
class _GpsRow extends StatelessWidget {
  const _GpsRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: RSSpacing.md, vertical: RSSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(RSRadius.md),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on_rounded,
              color: Color(0xFF81C784), size: 18),
          const SizedBox(width: RSSpacing.sm),
          Expanded(
            child: Text(
              '10.4880° N, 66.8792° O — Caracas, VE',
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

// ─── Activated View ──────────────────────────────────────────────
class _ActivatedView extends StatelessWidget {
  const _ActivatedView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(RSSpacing.lg),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: RSSpacing.md),
                child: Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: Colors.white54, size: 28),
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
                child: const Icon(Icons.sos_rounded,
                    color: Colors.white, size: 52),
              )
                  .animate()
                  .scale(
                    begin: const Offset(0.5, 0.5),
                    duration: 500.ms,
                    curve: Curves.elasticOut,
                  )
                  .fadeIn(duration: 300.ms),
              const SizedBox(height: RSSpacing.xl),
              Text('¡Emergencia activada!',
                  style: RSTypography.displayLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center)
                  .animate(delay: 300.ms)
                  .fadeIn(duration: 400.ms),
              const SizedBox(height: RSSpacing.md),
              Text(
                'Se está contactando a:\n• ${MockRider.emergencyContact} (${MockRider.emergencyPhone})\n• Venemergencias\n• Grupo Nueve Once',
                style: RSTypography.bodyLarge.copyWith(
                  color: Colors.white60,
                  height: 1.7,
                ),
                textAlign: TextAlign.center,
              ).animate(delay: 400.ms).fadeIn(duration: 400.ms),
              const SizedBox(height: RSSpacing.xxl),
              _StatusItem(
                icon: Icons.gps_fixed_rounded,
                label: 'Ubicación enviada: 10.4880° N, 66.8792° O',
                active: true,
              ).animate(delay: 600.ms).fadeIn(duration: 400.ms),
              const SizedBox(height: RSSpacing.md),
              _StatusItem(
                icon: Icons.medical_services_rounded,
                label: 'Solicitud de ambulancia en proceso...',
                active: false,
              ).animate(delay: 800.ms).fadeIn(duration: 400.ms),
              const Spacer(),
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
                child: Text('Volver al inicio',
                    style: RSTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    )),
              ).animate(delay: 1000.ms).fadeIn(duration: 400.ms),
              const SizedBox(height: RSSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusItem extends StatelessWidget {
  const _StatusItem({required this.icon, required this.label, required this.active});
  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon,
            color: active ? const Color(0xFF81C784) : Colors.white38,
            size: 18),
        const SizedBox(width: RSSpacing.md),
        Expanded(
          child: Text(label,
              style: RSTypography.bodyMedium.copyWith(
                color: active ? Colors.white70 : Colors.white38,
              )),
        ),
      ],
    );
  }
}

// ─── Cancelled View ──────────────────────────────────────────────
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
            const Icon(Icons.check_circle_rounded,
                color: Color(0xFF81C784), size: 80)
                .animate()
                .scale(
                  begin: const Offset(0.5, 0.5),
                  duration: 400.ms,
                  curve: Curves.elasticOut,
                ),
            const SizedBox(height: RSSpacing.xl),
            Text('Emergencia cancelada',
                style: RSTypography.displayMedium.copyWith(color: Colors.white))
                .animate(delay: 200.ms)
                .fadeIn(duration: 400.ms),
            const SizedBox(height: RSSpacing.md),
            Text('Nos alegra que estés bien.',
                style: RSTypography.bodyLarge.copyWith(color: Colors.white54))
                .animate(delay: 300.ms)
                .fadeIn(duration: 400.ms),
          ],
        ),
      ),
    );
  }
}

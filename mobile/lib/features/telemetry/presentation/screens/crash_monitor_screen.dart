// RS-Phase-1.5 — Crash detection demo screen.
//
// Shows real-time G-force from the accelerometer (if the device has one),
// lets the user adjust the detection threshold, and fires the emergency flow
// when an impact is detected — or on demand with "Simular impacto".
//
// The MQTT telemetry payload preview shows what will be sent to the IoT
// platform (Quasar Infotech) once the broker credentials are configured.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ruedaseguro/core/theme/spacing.dart';
import 'package:ruedaseguro/core/theme/typography.dart';
import 'package:ruedaseguro/features/emergency/presentation/screens/emergency_screen.dart';
import 'package:ruedaseguro/features/telemetry/presentation/providers/accelerometer_provider.dart';

class CrashMonitorScreen extends ConsumerStatefulWidget {
  const CrashMonitorScreen({super.key});

  @override
  ConsumerState<CrashMonitorScreen> createState() => _CrashMonitorScreenState();
}

class _CrashMonitorScreenState extends ConsumerState<CrashMonitorScreen>
    with SingleTickerProviderStateMixin {
  double _peakGForce = 0.0;
  bool _navigating = false;
  bool _impactFlash = false;
  late AnimationController _flashController;

  @override
  void initState() {
    super.initState();
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
  }

  @override
  void dispose() {
    _flashController.dispose();
    super.dispose();
  }

  void _triggerEmergency() {
    if (_navigating) return;
    _navigating = true;

    HapticFeedback.heavyImpact();
    setState(() => _impactFlash = true);
    _flashController.forward();

    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      context.push('/emergency', extra: EmergencyActivationType.autoFall);
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          setState(() {
            _impactFlash = false;
            _navigating = false;
          });
          _flashController.reverse();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final threshold = ref.watch(crashThresholdProvider);
    final readingAsync = ref.watch(accelerometerProvider);

    // React to live sensor data
    readingAsync.whenData((reading) {
      if (reading.gForce > _peakGForce) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _peakGForce = reading.gForce);
        });
      }
      if (reading.gForce >= threshold && !_navigating) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _triggerEmergency();
        });
      }
    });

    final gForce = readingAsync.asData?.value.gForce ?? 0.0;
    final x = readingAsync.asData?.value.x ?? 0.0;
    final y = readingAsync.asData?.value.y ?? 0.0;
    final z = readingAsync.asData?.value.z ?? 0.0;
    final hasSensor = !readingAsync.hasError && !readingAsync.isLoading;
    final isLoading = readingAsync.isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white54,
          ),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monitor de Impacto',
              style: RSTypography.titleMedium.copyWith(color: Colors.white),
            ),
            Text(
              'Detección de caídas — Demo',
              style: RSTypography.caption.copyWith(color: Colors.white38),
            ),
          ],
        ),
        actions: [
          _SensorBadge(isLoading: isLoading, hasSensor: hasSensor),
          const SizedBox(width: RSSpacing.md),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              RSSpacing.lg,
              RSSpacing.md,
              RSSpacing.lg,
              120,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _GaugeSection(
                  gForce: gForce,
                  threshold: threshold,
                  peakGForce: _peakGForce,
                ).animate().fadeIn(duration: 400.ms),

                const SizedBox(height: RSSpacing.lg),

                _AxisRow(
                  x: x,
                  y: y,
                  z: z,
                  visible: hasSensor,
                ).animate(delay: 100.ms).fadeIn(duration: 400.ms),

                const SizedBox(height: RSSpacing.lg),

                _ThresholdSection(
                  threshold: threshold,
                  onChanged: (v) =>
                      ref.read(crashThresholdProvider.notifier).update(v),
                ).animate(delay: 200.ms).fadeIn(duration: 400.ms),

                const SizedBox(height: RSSpacing.lg),

                const _MqttPreviewCard()
                    .animate(delay: 300.ms)
                    .fadeIn(duration: 400.ms),
              ],
            ),
          ),

          // Red flash on impact detection
          if (_impactFlash)
            IgnorePointer(
              child: Container(
                color: const Color(0xFFC62828).withValues(alpha: 0.25),
              ).animate().fadeIn(duration: 100.ms),
            ),

          // Impact detected label
          if (_impactFlash)
            const Positioned(top: 0, left: 0, right: 0, child: _ImpactBanner()),

          // Simulate / dismiss button pinned to bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _BottomBar(
              navigating: _navigating,
              onSimulate: _triggerEmergency,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sensor badge ─────────────────────────────────────────────────

class _SensorBadge extends StatelessWidget {
  const _SensorBadge({required this.isLoading, required this.hasSensor});
  final bool isLoading;
  final bool hasSensor;

  @override
  Widget build(BuildContext context) {
    final active = hasSensor && !isLoading;
    final label = isLoading
        ? 'Iniciando...'
        : active
        ? 'En vivo'
        : 'Simulador';
    final dotColor = active ? const Color(0xFF81C784) : Colors.white30;
    final textColor = active ? const Color(0xFF81C784) : Colors.white38;
    final borderColor = active
        ? const Color(0xFF81C784).withValues(alpha: 0.5)
        : Colors.white24;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: RSSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: active
            ? const Color(0xFF2E7D32).withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(RSRadius.sm),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: RSTypography.caption.copyWith(
              color: textColor,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── G-force gauge ────────────────────────────────────────────────

class _GaugeSection extends StatelessWidget {
  const _GaugeSection({
    required this.gForce,
    required this.threshold,
    required this.peakGForce,
  });

  final double gForce;
  final double threshold;
  final double peakGForce;

  Color _gaugeColor() {
    if (gForce >= threshold) return const Color(0xFFC62828);
    if (gForce >= threshold * 0.65) return const Color(0xFFE65100);
    return const Color(0xFF2E7D32);
  }

  @override
  Widget build(BuildContext context) {
    final color = _gaugeColor();

    return Column(
      children: [
        SizedBox(
          width: 220,
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(220, 220),
                painter: _GaugePainter(
                  gForce: gForce,
                  threshold: threshold,
                  color: color,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 150),
                    style: TextStyle(
                      color: color,
                      fontSize: 52,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                    child: Text(gForce.toStringAsFixed(2)),
                  ),
                  Text(
                    'G-force',
                    style: RSTypography.caption.copyWith(
                      color: Colors.white38,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: RSSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _StatChip(
              label: 'Umbral',
              value: '${threshold.toStringAsFixed(1)} G',
              color: const Color(0xFFE65100),
            ),
            const SizedBox(width: RSSpacing.lg),
            _StatChip(
              label: 'Pico sesión',
              value: '${peakGForce.toStringAsFixed(2)} G',
              color: Colors.white70,
            ),
          ],
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: RSTypography.titleMedium.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: RSTypography.caption.copyWith(
            color: Colors.white38,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

// ─── Gauge painter ────────────────────────────────────────────────

class _GaugePainter extends CustomPainter {
  const _GaugePainter({
    required this.gForce,
    required this.threshold,
    required this.color,
  });

  final double gForce;
  final double threshold;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const startAngle = pi * 0.75;
    const sweepAngle = pi * 1.5;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 18;
    final maxG = threshold * 1.6;

    // Background arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round,
    );

    // G-force fill arc
    final fraction = (gForce / maxG).clamp(0.0, 1.0);
    if (fraction > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle * fraction,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 14
          ..strokeCap = StrokeCap.round,
      );
    }

    // Threshold tick mark
    final tickFrac = (threshold / maxG).clamp(0.0, 1.0);
    final tickAngle = startAngle + sweepAngle * tickFrac;
    canvas.drawLine(
      Offset(
        center.dx + (radius - 20) * cos(tickAngle),
        center.dy + (radius - 20) * sin(tickAngle),
      ),
      Offset(
        center.dx + (radius + 8) * cos(tickAngle),
        center.dy + (radius + 8) * sin(tickAngle),
      ),
      Paint()
        ..color = const Color(0xFFE65100)
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.gForce != gForce || old.threshold != threshold || old.color != color;
}

// ─── XYZ axis row ─────────────────────────────────────────────────

class _AxisRow extends StatelessWidget {
  const _AxisRow({
    required this.x,
    required this.y,
    required this.z,
    required this.visible,
  });
  final double x;
  final double y;
  final double z;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    if (!visible) {
      return Container(
        padding: const EdgeInsets.all(RSSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(RSRadius.md),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.sensors_off_rounded,
              color: Colors.white30,
              size: 18,
            ),
            const SizedBox(width: RSSpacing.sm),
            Expanded(
              child: Text(
                'Acelerómetro no disponible en esta plataforma — usa "Simular impacto"',
                style: RSTypography.caption.copyWith(color: Colors.white38),
              ),
            ),
          ],
        ),
      );
    }
    return Row(
      children: [
        _AxisChip(axis: 'X', value: x, color: const Color(0xFFC62828)),
        const SizedBox(width: RSSpacing.sm),
        _AxisChip(axis: 'Y', value: y, color: const Color(0xFF2E7D32)),
        const SizedBox(width: RSSpacing.sm),
        _AxisChip(axis: 'Z', value: z, color: const Color(0xFF1565C0)),
      ],
    );
  }
}

class _AxisChip extends StatelessWidget {
  const _AxisChip({
    required this.axis,
    required this.value,
    required this.color,
  });
  final String axis;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: RSSpacing.sm,
          horizontal: RSSpacing.md,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(RSRadius.sm),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Text(
              axis,
              style: RSTypography.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${value.toStringAsFixed(2)} m/s²',
              style: RSTypography.mono.copyWith(
                color: Colors.white70,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Threshold slider ─────────────────────────────────────────────

class _ThresholdSection extends StatelessWidget {
  const _ThresholdSection({required this.threshold, required this.onChanged});
  final double threshold;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(RSSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(RSRadius.md),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune_rounded, color: Colors.white54, size: 18),
              const SizedBox(width: RSSpacing.sm),
              Text(
                'Umbral de detección',
                style: RSTypography.bodyMedium.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${threshold.toStringAsFixed(1)} G',
                style: RSTypography.titleMedium.copyWith(
                  color: const Color(0xFFE65100),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: RSSpacing.sm),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFFE65100),
              inactiveTrackColor: Colors.white12,
              thumbColor: const Color(0xFFE65100),
              overlayColor: const Color(0xFFE65100).withValues(alpha: 0.2),
              trackHeight: 4,
            ),
            child: Slider(
              value: threshold,
              min: 1.5,
              max: 5.0,
              divisions: 7,
              onChanged: onChanged,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '1.5 G — Caída leve',
                style: RSTypography.caption.copyWith(
                  color: Colors.white30,
                  fontSize: 10,
                ),
              ),
              Text(
                '5.0 G — Choque severo',
                style: RSTypography.caption.copyWith(
                  color: Colors.white30,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── MQTT preview card ────────────────────────────────────────────

class _MqttPreviewCard extends StatelessWidget {
  const _MqttPreviewCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(RSSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(RSRadius.md),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.cloud_queue_rounded,
                color: Colors.white54,
                size: 18,
              ),
              const SizedBox(width: RSSpacing.sm),
              Text(
                'Telemetría MQTT',
                style: RSTypography.bodyMedium.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: RSSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE65100).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: const Color(0xFFE65100).withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  'Pendiente config.',
                  style: RSTypography.caption.copyWith(
                    color: const Color(0xFFFF8A50),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: RSSpacing.md),
          Text(
            'Al confirmar credenciales con Thony (Quasar Infotech),\neste payload se enviará al broker MQTT:',
            style: RSTypography.caption.copyWith(
              color: Colors.white38,
              height: 1.5,
            ),
          ),
          const SizedBox(height: RSSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(RSSpacing.md),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(RSRadius.sm),
            ),
            child: Text(
              '// topic: rs/telemetry/{device_id}/anomaly\n'
              '{\n'
              '  "event":     "impact_detected",\n'
              '  "g_force":   3.84,\n'
              '  "timestamp": "2026-04-10T15:32:01Z",\n'
              '  "lat":       10.4880,\n'
              '  "lng":       -66.8792,\n'
              '  "policy_id": "RS-2026-001234",\n'
              '  "window_15m": [\n'
              '    { "t": -14.9, "g": 0.98 },\n'
              '    { "t": -0.02, "g": 3.84 }\n'
              '  ]\n'
              '}',
              style: RSTypography.mono.copyWith(
                color: Colors.white54,
                fontSize: 11,
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(height: RSSpacing.sm),
          Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: Colors.white24,
                size: 14,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Los últimos 15 minutos de datos quedan en el buffer SQLite local '
                  'y se adjuntan al evento de impacto.',
                  style: RSTypography.caption.copyWith(
                    color: Colors.white30,
                    fontSize: 10,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Impact banner ────────────────────────────────────────────────

class _ImpactBanner extends StatelessWidget {
  const _ImpactBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: RSSpacing.md),
      color: const Color(0xFFC62828),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.warning_rounded, color: Colors.white, size: 20),
          const SizedBox(width: RSSpacing.sm),
          Text(
            'IMPACTO DETECTADO — Activando emergencia...',
            style: RSTypography.bodyMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    ).animate().slideY(
      begin: -1.0,
      duration: 300.ms,
      curve: Curves.easeOutCubic,
    );
  }
}

// ─── Bottom bar ───────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.navigating, required this.onSimulate});
  final bool navigating;
  final VoidCallback onSimulate;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF0D0D0D).withValues(alpha: 0.0),
            const Color(0xFF0D0D0D),
            const Color(0xFF0D0D0D),
          ],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        RSSpacing.lg,
        RSSpacing.lg,
        RSSpacing.lg,
        RSSpacing.xl,
      ),
      child: GestureDetector(
        onTap: navigating ? null : onSimulate,
        child: AnimatedOpacity(
          opacity: navigating ? 0.5 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFC62828),
              borderRadius: BorderRadius.circular(RSRadius.md),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFC62828).withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                const SizedBox(width: RSSpacing.sm),
                Text(
                  navigating
                      ? 'Activando emergencia...'
                      : 'Simular impacto fuerte',
                  style: RSTypography.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

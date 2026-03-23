import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ruedaseguro/core/constants/app_constants.dart';
import 'package:ruedaseguro/core/theme/colors.dart';
import 'package:ruedaseguro/core/theme/spacing.dart';
import 'package:ruedaseguro/core/theme/typography.dart';
import 'package:ruedaseguro/features/auth/data/auth_repository.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key, required this.phone});

  final String phone;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final List<TextEditingController> _controllers =
      List.generate(AppConstants.otpLength, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(AppConstants.otpLength, (_) => FocusNode());

  bool _isLoading = false;
  String? _errorMessage;
  int _resendSeconds = AppConstants.otpResendSeconds;
  int _resendCount = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    // Auto-focus first box
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _resendSeconds = AppConstants.otpResendSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendSeconds <= 0) {
        t.cancel();
      } else {
        setState(() => _resendSeconds--);
      }
    });
  }

  String get _otp => _controllers.map((c) => c.text).join();
  bool get _isComplete => _otp.length == AppConstants.otpLength;

  String get _maskedPhone {
    if (widget.phone.length < 6) return widget.phone;
    return '${widget.phone.substring(0, widget.phone.length - 4)}****';
  }

  void _onDigitChanged(int index, String value) {
    if (value.length > 1) {
      // Handle paste: distribute digits across boxes
      final digits = value.replaceAll(RegExp(r'[^\d]'), '');
      for (var i = 0; i < digits.length && i + index < AppConstants.otpLength; i++) {
        _controllers[index + i].text = digits[i];
      }
      final nextIndex = (index + digits.length).clamp(0, AppConstants.otpLength - 1);
      _focusNodes[nextIndex].requestFocus();
    } else if (value.isNotEmpty) {
      if (index < AppConstants.otpLength - 1) {
        _focusNodes[index + 1].requestFocus();
      }
    }
    setState(() => _errorMessage = null);
    if (_isComplete) _verify();
  }

  void _onKeyDown(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  Future<void> _verify() async {
    if (!_isComplete || _isLoading) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final session = await AuthRepository.instance.verifyOtp(widget.phone, _otp);
      if (session != null && mounted) {
        // Router redirect will handle navigation based on profile existence
        context.go('/home');
      }
    } on Exception catch (e) {
      final msg = e.toString().toLowerCase();
      String userMsg;
      if (msg.contains('expired')) {
        userMsg = 'Código expirado. Solicita uno nuevo.';
      } else if (msg.contains('attempt') || msg.contains('limit')) {
        userMsg = 'Demasiados intentos. Espera 10 minutos.';
      } else {
        userMsg = 'Código incorrecto. Intenta de nuevo.';
      }
      if (mounted) {
        _clearBoxes();
        setState(() => _errorMessage = userMsg);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _clearBoxes() {
    for (final c in _controllers) c.clear();
    _focusNodes[0].requestFocus();
  }

  Future<void> _resend() async {
    if (_resendSeconds > 0 || _resendCount >= 3) return;
    if (_resendCount >= 3) {
      setState(() => _errorMessage = 'Contacta soporte para más ayuda.');
      return;
    }
    try {
      await AuthRepository.instance.signInWithOtp(widget.phone);
      _resendCount++;
      _startCountdown();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Código reenviado'), duration: Duration(seconds: 2)),
        );
      }
    } on Exception {
      if (mounted) {
        setState(() => _errorMessage = 'Error al reenviar. Intenta de nuevo.');
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: RSColors.primary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: RSSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: RSSpacing.xl),
              Text(
                'Ingresa el código',
                style: RSTypography.displayMedium.copyWith(color: RSColors.primary),
              ),
              const SizedBox(height: RSSpacing.sm),
              Text(
                'Enviamos un código de 6 dígitos a $_maskedPhone',
                style: RSTypography.bodyLarge.copyWith(color: RSColors.textSecondary),
              ),
              const SizedBox(height: RSSpacing.xxl),

              // OTP boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(AppConstants.otpLength, (i) {
                  return _OtpBox(
                    controller: _controllers[i],
                    focusNode: _focusNodes[i],
                    hasError: _errorMessage != null,
                    onChanged: (v) => _onDigitChanged(i, v),
                    onKeyEvent: (e) => _onKeyDown(i, e),
                  );
                }),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: RSSpacing.md),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: RSTypography.bodyMedium.copyWith(color: RSColors.error),
                ),
              ],

              const SizedBox(height: RSSpacing.xl),

              // Resend / countdown
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                Center(
                  child: _resendSeconds > 0
                      ? Text(
                          'Reenviar código en $_resendSeconds segundos',
                          style: RSTypography.bodyMedium.copyWith(
                            color: RSColors.textSecondary,
                          ),
                        )
                      : _resendCount >= 3
                          ? Text(
                              'Contacta soporte para más ayuda.',
                              style: RSTypography.bodyMedium.copyWith(
                                color: RSColors.textSecondary,
                              ),
                            )
                          : GestureDetector(
                              onTap: _resend,
                              child: Text(
                                'Reenviar código',
                                style: RSTypography.bodyMedium.copyWith(
                                  color: RSColors.primary,
                                  decoration: TextDecoration.underline,
                                  decorationColor: RSColors.primary,
                                ),
                              ),
                            ),
                ),

              const SizedBox(height: RSSpacing.lg),
              Center(
                child: TextButton(
                  onPressed: () => context.pop(),
                  child: Text(
                    'Cambiar número',
                    style: RSTypography.bodyMedium.copyWith(
                      color: RSColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OtpBox extends StatelessWidget {
  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.hasError,
    required this.onChanged,
    required this.onKeyEvent,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasError;
  final ValueChanged<String> onChanged;
  final ValueChanged<KeyEvent> onKeyEvent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 56,
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: onKeyEvent,
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 6, // allow paste of full OTP
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: RSTypography.displayMedium.copyWith(color: RSColors.primary),
          decoration: InputDecoration(
            counterText: '',
            contentPadding: EdgeInsets.zero,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(RSRadius.md),
              borderSide: BorderSide(
                color: hasError ? RSColors.error : RSColors.border,
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(RSRadius.md),
              borderSide: const BorderSide(color: RSColors.borderFocus, width: 2),
            ),
            filled: true,
            fillColor: RSColors.surface,
          ),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

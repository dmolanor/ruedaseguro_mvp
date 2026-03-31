import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:cloudflare_turnstile/cloudflare_turnstile.dart';

import 'package:ruedaseguro/core/config/env_config.dart';
import 'package:ruedaseguro/core/theme/colors.dart';
import 'package:ruedaseguro/core/theme/spacing.dart';
import 'package:ruedaseguro/core/theme/typography.dart';
import 'package:ruedaseguro/features/auth/data/auth_repository.dart';
import 'package:ruedaseguro/shared/widgets/rs_button.dart';

// ---------------------------------------------------------------------------
// Country configuration
// ---------------------------------------------------------------------------

class _Country {
  const _Country({
    required this.flag,
    required this.dialCode,
    required this.hint,
    required this.isValid,
  });
  final String flag;
  final String dialCode;
  final String hint;
  final bool Function(String digits) isValid;
}

const _venezuela = _Country(
  flag: '🇻🇪',
  dialCode: '+58',
  hint: '412 1234567',
  isValid: _isVenezuelanPhone,
);

const _colombia = _Country(
  flag: '🇨🇴',
  dialCode: '+57',
  hint: '312 3456789',
  isValid: _isColombianPhone,
);

const _countries = [_venezuela, _colombia];

bool _isVenezuelanPhone(String d) => d.length == 10 && d.startsWith('4');
bool _isColombianPhone(String d) => d.length == 10 && d.startsWith('3');

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _turnstileController = TurnstileController();
  bool _isLoading = false;
  String? _errorMessage;
  String? _captchaToken;
  _Country _country = _venezuela;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _turnstileController.dispose();
    super.dispose();
  }

  String get _rawPhone => _controller.text.replaceAll(RegExp(r'[^\d]'), '');

  bool get _isValid => _country.isValid(_rawPhone);

  Future<void> _submit() async {
    if (!_isValid || _isLoading) return;
    // If Turnstile is enabled but hasn't resolved yet, ask the user to wait.
    if (EnvConfig.turnstileSiteKey.isNotEmpty && _captchaToken == null) {
      setState(() => _errorMessage = 'Verificación de seguridad en curso. Intenta de nuevo en un momento.');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final fullPhone = '${_country.dialCode}$_rawPhone';
      await AuthRepository.instance.signInWithOtp(
        fullPhone,
        captchaToken: _captchaToken,
      );
      if (mounted) unawaited(context.push('/otp', extra: fullPhone));
    } on Exception catch (e) {
      final msg = e.toString().toLowerCase();
      String userMsg;
      if (msg.contains('rate') || msg.contains('limit')) {
        userMsg = 'Has excedido el límite de intentos. Intenta en unos minutos.';
      } else if (msg.contains('network') || msg.contains('socket')) {
        userMsg = 'Sin conexión a internet. Verifica tu conexión.';
      } else if (msg.contains('captcha') || msg.contains('turnstile')) {
        userMsg = 'Verificación de seguridad fallida. Intenta de nuevo.';
      } else {
        userMsg = kDebugMode
            ? '[dev] ${e.toString()}'
            : 'Error al enviar el código. Intenta de nuevo.';
      }
      // Reset the Turnstile token so a fresh challenge is issued on retry.
      // Guard against web controller not yet initialized (LateInitializationError).
      try {
        if (EnvConfig.turnstileSiteKey.isNotEmpty) {
          _turnstileController.refreshToken();
        }
      } catch (_) {}
      if (mounted) setState(() {
        _errorMessage = userMsg;
        _captchaToken = null;
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _pickCountry() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: RSColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(RSRadius.lg)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: RSSpacing.md),
            Text('Selecciona tu país',
                style: RSTypography.titleLarge.copyWith(color: RSColors.textPrimary)),
            const SizedBox(height: RSSpacing.md),
            for (final c in _countries)
              ListTile(
                leading: Text(c.flag, style: const TextStyle(fontSize: 26)),
                title: Text('${c.dialCode}', style: RSTypography.bodyLarge),
                trailing: _country == c
                    ? const Icon(Icons.check_circle, color: RSColors.primary)
                    : null,
                onTap: () {
                  setState(() {
                    _country = c;
                    _controller.clear();
                    _errorMessage = null;
                  });
                  Navigator.of(ctx).pop();
                },
              ),
            const SizedBox(height: RSSpacing.md),
          ],
        ),
      ),
    );
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
                'Ingresa tu número\nde teléfono',
                style: RSTypography.displayMedium.copyWith(color: RSColors.primary),
              ),
              const SizedBox(height: RSSpacing.sm),
              Text(
                'Te enviaremos un código de verificación por SMS',
                style: RSTypography.bodyLarge.copyWith(color: RSColors.textSecondary),
              ),
              const SizedBox(height: RSSpacing.xl),

              // Phone input
              Container(
                decoration: BoxDecoration(
                  color: RSColors.surface,
                  borderRadius: BorderRadius.circular(RSRadius.md),
                  border: Border.all(
                    color: _errorMessage != null
                        ? RSColors.error
                        : _focusNode.hasFocus
                            ? RSColors.borderFocus
                            : RSColors.border,
                    width: _focusNode.hasFocus ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Country prefix — tappable
                    GestureDetector(
                      onTap: _pickCountry,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: RSSpacing.md,
                          vertical: RSSpacing.md,
                        ),
                        decoration: BoxDecoration(
                          color: RSColors.surfaceVariant,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(RSRadius.md - 1),
                            bottomLeft: Radius.circular(RSRadius.md - 1),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(_country.flag,
                                style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 4),
                            Text(
                              _country.dialCode,
                              style: RSTypography.bodyLarge.copyWith(
                                color: RSColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(Icons.arrow_drop_down,
                                color: RSColors.textSecondary, size: 18),
                          ],
                        ),
                      ),
                    ),
                    const VerticalDivider(width: 1, color: RSColors.border),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          _PhoneInputFormatter(),
                        ],
                        style: RSTypography.bodyLarge.copyWith(
                          color: RSColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: _country.hint,
                          hintStyle: RSTypography.bodyLarge.copyWith(
                            color: RSColors.textSecondary,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: RSSpacing.md,
                          ),
                        ),
                        onChanged: (_) => setState(() => _errorMessage = null),
                        onSubmitted: (_) => _submit(),
                      ),
                    ),
                  ],
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: RSSpacing.sm),
                Text(
                  _errorMessage!,
                  style: RSTypography.bodyMedium.copyWith(color: RSColors.error),
                ),
              ],

              const Spacer(),

              // Invisible Turnstile — no wrapper needed.
              // On web the widget renders as a 0.01×0.01px iframe; any
              // display:none wrapper (Offstage/Visibility) blocks the
              // Cloudflare JS challenge from running.
              if (EnvConfig.turnstileSiteKey.isNotEmpty)
                CloudFlareTurnstile(
                  siteKey: EnvConfig.turnstileSiteKey,
                  options: TurnstileOptions(
                    mode: TurnstileMode.invisible,
                    theme: TurnstileTheme.dark,
                  ),
                  controller: _turnstileController,
                  onTokenRecived: (token) {
                    setState(() => _captchaToken = token);
                  },
                  onTokenExpired: () {
                    setState(() => _captchaToken = null);
                  },
                ),

              RSButton(
                label: 'Continuar',
                onPressed: _isValid ? _submit : null,
                isLoading: _isLoading,
              ),
              if (kDebugMode) ...[
                const SizedBox(height: RSSpacing.md),
                _DevBypassButton(isLoading: _isLoading),
              ],
              const SizedBox(height: RSSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dev-only bypass button (anonymous sign-in, no SMS required)
// ---------------------------------------------------------------------------

class _DevBypassButton extends ConsumerStatefulWidget {
  const _DevBypassButton({required this.isLoading});
  final bool isLoading;

  @override
  ConsumerState<_DevBypassButton> createState() => _DevBypassButtonState();
}

class _DevBypassButtonState extends ConsumerState<_DevBypassButton> {
  bool _busy = false;

  Future<void> _bypass() async {
    if (_busy || widget.isLoading) return;
    setState(() => _busy = true);
    try {
      await AuthRepository.instance.signInAnonymously();
      // Router redirect will automatically send authenticated user to /onboarding/cedula
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('[dev] ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: _busy || widget.isLoading ? null : _bypass,
      style: OutlinedButton.styleFrom(
        foregroundColor: RSColors.textSecondary,
        side: const BorderSide(color: RSColors.border),
      ),
      child: _busy
          ? const SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Text('[DEV] Saltar SMS → anónimo'),
    );
  }
}

/// Auto-formats phone as "XXX XXXXXXX"
class _PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length > 10) return oldValue;
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i == 3) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final formatted = buffer.toString();
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

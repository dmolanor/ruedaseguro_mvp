import 'package:flutter/material.dart';
import 'package:ruedaseguro/core/theme/colors.dart';
import 'package:ruedaseguro/core/theme/spacing.dart';
import 'package:ruedaseguro/core/theme/typography.dart';

enum RSButtonVariant { primary, secondary, danger }

class RSButton extends StatelessWidget {
  const RSButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = RSButtonVariant.primary,
    this.isLoading = false,
    this.isFullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final RSButtonVariant variant;
  final bool isLoading;
  final bool isFullWidth;

  Color get _backgroundColor {
    switch (variant) {
      case RSButtonVariant.primary:
        return RSColors.accent;
      case RSButtonVariant.secondary:
        return Colors.transparent;
      case RSButtonVariant.danger:
        return RSColors.error;
    }
  }

  Color get _foregroundColor {
    switch (variant) {
      case RSButtonVariant.primary:
        return RSColors.textOnAccent;
      case RSButtonVariant.secondary:
        return RSColors.primary;
      case RSButtonVariant.danger:
        return RSColors.textOnPrimary;
    }
  }

  Color get _borderColor {
    switch (variant) {
      case RSButtonVariant.primary:
        return Colors.transparent;
      case RSButtonVariant.secondary:
        return RSColors.primary;
      case RSButtonVariant.danger:
        return Colors.transparent;
    }
  }

  bool get _isEnabled => onPressed != null && !isLoading;

  @override
  Widget build(BuildContext context) {
    final buttonStyle = ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return _backgroundColor.withValues(alpha: 0.5);
        }
        return _backgroundColor;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return _foregroundColor.withValues(alpha: 0.5);
        }
        return _foregroundColor;
      }),
      side: WidgetStateProperty.all(
        BorderSide(
          color: _isEnabled ? _borderColor : _borderColor.withValues(alpha: 0.5),
          width: variant == RSButtonVariant.secondary ? 1.5 : 0,
        ),
      ),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RSRadius.md),
        ),
      ),
      padding: WidgetStateProperty.all(
        const EdgeInsets.symmetric(
          horizontal: RSSpacing.lg,
          vertical: RSSpacing.md,
        ),
      ),
      minimumSize: WidgetStateProperty.all(
        const Size(48, 48),
      ),
      elevation: WidgetStateProperty.all(0),
    );

    final child = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(_foregroundColor),
            ),
          )
        : Text(
            label,
            style: RSTypography.labelLarge.copyWith(color: _foregroundColor),
          );

    final button = variant == RSButtonVariant.secondary
        ? OutlinedButton(
            onPressed: _isEnabled ? onPressed : null,
            style: buttonStyle,
            child: child,
          )
        : ElevatedButton(
            onPressed: _isEnabled ? onPressed : null,
            style: buttonStyle,
            child: child,
          );

    if (isFullWidth) {
      return SizedBox(
        width: double.infinity,
        child: button,
      );
    }

    return button;
  }
}

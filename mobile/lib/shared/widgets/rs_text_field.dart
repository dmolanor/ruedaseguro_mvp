import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ruedaseguro/core/theme/colors.dart';
import 'package:ruedaseguro/core/theme/spacing.dart';
import 'package:ruedaseguro/core/theme/typography.dart';

class RSTextField extends StatelessWidget {
  const RSTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.validator,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.readOnly = false,
    this.keyboardType,
    this.isAmberHighlight = false,
    this.borderColor,
    this.onTap,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.maxLength,
    this.onChanged,
  });

  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool readOnly;
  final TextInputType? keyboardType;
  final bool isAmberHighlight;
  final Color? borderColor;
  final VoidCallback? onTap;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final effectiveBorderColor =
        borderColor ?? (isAmberHighlight ? RSColors.warning : RSColors.border);
    final focusBorderColor =
        borderColor ?? (isAmberHighlight ? RSColors.warning : RSColors.borderFocus);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: RSTypography.bodyMedium.copyWith(
              color: RSColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: RSSpacing.xs),
        ],
        TextFormField(
          controller: controller,
          validator: validator,
          obscureText: obscureText,
          readOnly: readOnly,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          maxLength: maxLength,
          onTap: onTap,
          onChanged: onChanged,
          inputFormatters: inputFormatters,
          style: RSTypography.bodyLarge.copyWith(
            color: RSColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: RSTypography.bodyLarge.copyWith(
              color: RSColors.textSecondary,
            ),
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: RSColors.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: RSSpacing.md,
              vertical: RSSpacing.md,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(RSRadius.md),
              borderSide: BorderSide(color: effectiveBorderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(RSRadius.md),
              borderSide: BorderSide(
                color: effectiveBorderColor,
                width: (isAmberHighlight || borderColor != null) ? 2.0 : 1.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(RSRadius.md),
              borderSide: BorderSide(
                color: focusBorderColor,
                width: 2.0,
              ),
            ),
            counterText: '',
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(RSRadius.md),
              borderSide: const BorderSide(
                color: RSColors.error,
                width: 1.5,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(RSRadius.md),
              borderSide: const BorderSide(
                color: RSColors.error,
                width: 2.0,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

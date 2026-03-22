import 'package:flutter/material.dart';
import 'package:ruedaseguro/core/theme/colors.dart';
import 'package:ruedaseguro/core/theme/spacing.dart';

class RSConsentCheckbox extends StatelessWidget {
  const RSConsentCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    this.isRequired = false,
    this.hasError = false,
  });

  final bool value;
  final ValueChanged<bool?> onChanged;
  final Widget label;
  final bool isRequired;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: hasError
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(RSRadius.sm),
              border: Border.all(
                color: RSColors.error,
                width: 1.5,
              ),
            )
          : null,
      padding: hasError
          ? const EdgeInsets.symmetric(
              horizontal: RSSpacing.sm,
              vertical: RSSpacing.xs,
            )
          : EdgeInsets.zero,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: RSColors.primary,
              checkColor: RSColors.textOnPrimary,
              side: BorderSide(
                color: hasError ? RSColors.error : RSColors.border,
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: RSSpacing.sm),
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(!value),
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: label,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

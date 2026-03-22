import 'package:flutter/material.dart';
import 'package:ruedaseguro/core/theme/colors.dart';
import 'package:ruedaseguro/core/theme/spacing.dart';
import 'package:ruedaseguro/core/theme/typography.dart';

class AmountDisplay extends StatelessWidget {
  const AmountDisplay({
    super.key,
    required this.amountUsd,
    required this.amountVes,
    required this.exchangeRate,
  });

  final double amountUsd;
  final double amountVes;
  final double exchangeRate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '\$ ${amountUsd.toStringAsFixed(2)}',
          style: RSTypography.mono.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: RSColors.textPrimary,
          ),
        ),
        const SizedBox(height: RSSpacing.xs),
        Text(
          'Bs. ${amountVes.toStringAsFixed(2)}',
          style: RSTypography.mono.copyWith(
            fontSize: 16,
            color: RSColors.textSecondary,
          ),
        ),
        const SizedBox(height: RSSpacing.xs),
        Text(
          'Tasa: 1 USD = ${exchangeRate.toStringAsFixed(2)} VES',
          style: RSTypography.caption.copyWith(
            color: RSColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

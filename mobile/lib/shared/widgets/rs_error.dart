import 'package:flutter/material.dart';
import 'package:ruedaseguro/core/theme/colors.dart';
import 'package:ruedaseguro/core/theme/spacing.dart';
import 'package:ruedaseguro/core/theme/typography.dart';
import 'package:ruedaseguro/shared/widgets/rs_button.dart';

class RSError extends StatelessWidget {
  const RSError({
    super.key,
    this.title = 'Error',
    required this.message,
    this.onRetry,
    this.icon = Icons.error_outline,
    this.iconColor = RSColors.error,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(RSSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 48,
              color: iconColor,
            ),
            const SizedBox(height: RSSpacing.md),
            Text(
              title,
              style: RSTypography.titleLarge.copyWith(
                color: RSColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: RSSpacing.sm),
            Text(
              message,
              style: RSTypography.bodyMedium.copyWith(
                color: RSColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: RSSpacing.lg),
              RSButton(
                label: 'Reintentar',
                onPressed: onRetry,
                variant: RSButtonVariant.secondary,
                isFullWidth: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class RSNetworkError extends StatelessWidget {
  const RSNetworkError({
    super.key,
    this.onRetry,
  });

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return RSError(
      title: 'Sin conexión',
      message: 'Sin conexión a internet',
      icon: Icons.wifi_off,
      iconColor: RSColors.textSecondary,
      onRetry: onRetry,
    );
  }
}

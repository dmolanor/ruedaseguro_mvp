import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:ruedaseguro/core/theme/colors.dart';
import 'package:ruedaseguro/core/theme/spacing.dart';
import 'package:ruedaseguro/core/theme/typography.dart';

class RSLoadingOverlay extends StatelessWidget {
  const RSLoadingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: RSColors.background.withValues(alpha: 0.85),
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(RSColors.primary),
              strokeWidth: 3,
            ),
            const SizedBox(height: RSSpacing.md),
            Text(
              'Cargando...',
              style: RSTypography.bodyMedium.copyWith(
                color: RSColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RSShimmer extends StatelessWidget {
  const RSShimmer({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: RSColors.surfaceVariant,
      highlightColor: RSColors.surface,
      child: child,
    );
  }
}

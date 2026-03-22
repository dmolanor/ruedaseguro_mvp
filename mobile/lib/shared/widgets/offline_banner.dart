import 'package:flutter/material.dart';
import 'package:ruedaseguro/core/theme/colors.dart';
import 'package:ruedaseguro/core/theme/spacing.dart';
import 'package:ruedaseguro/core/theme/typography.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({
    super.key,
    required this.isOffline,
  });

  final bool isOffline;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: isOffline ? 48 : 0,
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(
        color: RSColors.warning,
      ),
      child: isOffline
          ? Material(
              color: RSColors.warning,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: RSSpacing.md,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.wifi_off,
                      size: 18,
                      color: RSColors.textPrimary,
                    ),
                    const SizedBox(width: RSSpacing.sm),
                    Text(
                      'Sin conexión a internet',
                      style: RSTypography.bodyMedium.copyWith(
                        color: RSColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}

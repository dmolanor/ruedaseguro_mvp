import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:ruedaseguro/core/theme/colors.dart';
import 'package:ruedaseguro/core/theme/typography.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RSColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo / Brand mark
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: RSColors.accent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.shield_rounded,
                color: Colors.white,
                size: 48,
              ),
            )
                .animate()
                .fadeIn(duration: 600.ms)
                .scale(begin: const Offset(0.8, 0.8)),
            const SizedBox(height: 20),
            Text(
              'RuedaSeguro',
              style: RSTypography.displayMedium.copyWith(
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            )
                .animate(delay: 200.ms)
                .fadeIn(duration: 500.ms)
                .slideY(begin: 0.2, end: 0),
            const SizedBox(height: 8),
            Text(
              'Si te caes, no estás solo.',
              style: RSTypography.bodyMedium.copyWith(
                color: Colors.white.withValues(alpha: 0.7),
              ),
            )
                .animate(delay: 400.ms)
                .fadeIn(duration: 500.ms),
            const SizedBox(height: 48),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.white.withValues(alpha: 0.6),
                ),
              ),
            )
                .animate(delay: 600.ms)
                .fadeIn(duration: 400.ms),
          ],
        ),
      ),
    );
  }
}

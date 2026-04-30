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
            Image.asset(
                  'assets/images/logo.png',
                  width: 220,
                  fit: BoxFit.contain,
                )
                .animate()
                .fadeIn(duration: 600.ms)
                .scale(begin: const Offset(0.85, 0.85)),
            const SizedBox(height: 24),
            Text(
              'Si te caes, no estás solo.',
              style: RSTypography.bodyMedium.copyWith(
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ).animate(delay: 300.ms).fadeIn(duration: 500.ms),
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
            ).animate(delay: 600.ms).fadeIn(duration: 400.ms),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:ruedaseguro/core/theme/colors.dart';
import 'package:ruedaseguro/core/theme/typography.dart';
import 'package:ruedaseguro/core/theme/spacing.dart';

final rsTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  scaffoldBackgroundColor: RSColors.background,

  colorScheme: const ColorScheme.light(
    primary: RSColors.primary,
    onPrimary: RSColors.textOnPrimary,
    secondary: RSColors.accent,
    onSecondary: RSColors.textOnAccent,
    surface: RSColors.surface,
    onSurface: RSColors.textPrimary,
    error: RSColors.error,
    onError: Colors.white,
    outline: RSColors.border,
  ),

  appBarTheme: AppBarTheme(
    backgroundColor: RSColors.primary,
    foregroundColor: RSColors.textOnPrimary,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: RSTypography.titleLarge.copyWith(
      color: RSColors.textOnPrimary,
    ),
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: RSColors.accent,
      foregroundColor: RSColors.textOnAccent,
      minimumSize: const Size(double.infinity, 48),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RSRadius.md),
      ),
      textStyle: RSTypography.labelLarge,
    ),
  ),

  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: RSColors.primary,
      minimumSize: const Size(double.infinity, 48),
      side: const BorderSide(color: RSColors.primary),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RSRadius.md),
      ),
      textStyle: RSTypography.labelLarge,
    ),
  ),

  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: RSColors.surface,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: RSSpacing.md,
      vertical: RSSpacing.sm + 4,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(RSRadius.sm),
      borderSide: const BorderSide(color: RSColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(RSRadius.sm),
      borderSide: const BorderSide(color: RSColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(RSRadius.sm),
      borderSide: const BorderSide(color: RSColors.borderFocus, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(RSRadius.sm),
      borderSide: const BorderSide(color: RSColors.error),
    ),
    labelStyle: RSTypography.bodyMedium.copyWith(color: RSColors.textSecondary),
    hintStyle: RSTypography.bodyMedium.copyWith(color: RSColors.textSecondary),
  ),

  cardTheme: CardThemeData(
    elevation: 1,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(RSRadius.md),
    ),
    color: RSColors.surface,
    margin: const EdgeInsets.symmetric(
      horizontal: RSSpacing.md,
      vertical: RSSpacing.sm,
    ),
  ),

  textTheme: TextTheme(
    displayLarge: RSTypography.displayLarge,
    displayMedium: RSTypography.displayMedium,
    titleLarge: RSTypography.titleLarge,
    titleMedium: RSTypography.titleMedium,
    bodyLarge: RSTypography.bodyLarge,
    bodyMedium: RSTypography.bodyMedium,
    labelLarge: RSTypography.labelLarge,
  ),

  dividerTheme: const DividerThemeData(
    color: RSColors.border,
    thickness: 1,
    space: RSSpacing.md,
  ),

  snackBarTheme: SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(RSRadius.sm),
    ),
  ),
);

import 'package:flutter/material.dart';

class RSColors {
  RSColors._();

  // Primary
  static const primary = Color(0xFF1A237E);       // Navy Blue — trust, protection
  static const primaryLight = Color(0xFF3949AB);   // Lighter blue for hover/focus

  // Accent
  static const accent = Color(0xFFFF6D00);         // Orange — alert, urgency, action

  // Semantic
  static const success = Color(0xFF2E7D32);        // Green
  static const error = Color(0xFFC62828);           // Red
  static const warning = Color(0xFFFFB300);         // Amber — "Observada", low-confidence

  // Surfaces
  static const background = Color(0xFFFAFAFA);    // Off-white — avoids glare
  static const surface = Color(0xFFFFFFFF);        // White
  static const surfaceVariant = Color(0xFFF5F5F5); // Subtle surface

  // Text
  static const textPrimary = Color(0xFF212121);    // Off-black — high contrast
  static const textSecondary = Color(0xFF757575);  // Gray
  static const textOnPrimary = Color(0xFFFFFFFF);  // White on navy
  static const textOnAccent = Color(0xFFFFFFFF);   // White on orange

  // Border
  static const border = Color(0xFFE0E0E0);         // Light gray
  static const borderFocus = Color(0xFF1A237E);    // Navy on focus
}

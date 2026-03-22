import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RSTypography {
  RSTypography._();

  // Headings — Montserrat
  static TextStyle displayLarge = GoogleFonts.montserrat(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );

  static TextStyle displayMedium = GoogleFonts.montserrat(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );

  static TextStyle titleLarge = GoogleFonts.montserrat(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  // Body — Lato
  static TextStyle titleMedium = GoogleFonts.lato(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  static TextStyle bodyLarge = GoogleFonts.lato(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static TextStyle bodyMedium = GoogleFonts.lato(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  // Labels
  static TextStyle labelLarge = GoogleFonts.montserrat(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static TextStyle caption = GoogleFonts.lato(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  // Monospace — for amounts, reference numbers
  static const mono = TextStyle(
    fontFamily: 'monospace',
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );
}

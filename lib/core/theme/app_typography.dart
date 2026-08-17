import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Typography tokens: Fraunces (serif) for headings, Roboto (sans) for body
/// and labels — matching the Figma "Leo's team library" frames.
abstract class AppTypography {
  static TextStyle get displaySerif => GoogleFonts.fraunces(
    fontSize: 22,
    height: 33 / 22,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static TextStyle get headlineSerif => GoogleFonts.fraunces(
    fontSize: 20,
    height: 30 / 20,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static TextStyle get buttonLabel => GoogleFonts.roboto(
    fontSize: 15,
    height: 18 / 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle get bodyInput => GoogleFonts.roboto(
    fontSize: 14,
    height: 21 / 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static TextStyle get fieldLabel => GoogleFonts.roboto(
    fontSize: 13,
    height: 19.5 / 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  static TextStyle get chipLabel => GoogleFonts.roboto(
    fontSize: 12.5,
    height: 15 / 12.5,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  static TextStyle get caption => GoogleFonts.roboto(
    fontSize: 10,
    height: 15 / 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.25,
    color: AppColors.textMuted,
  );
}

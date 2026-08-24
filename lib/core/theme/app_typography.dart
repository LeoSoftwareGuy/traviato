import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Typography tokens: Fraunces (serif) for headings, Roboto (sans) for body
/// and labels — matching the Figma "Leo's team library" frames, plus the
/// redesign handoff's JetBrains Mono label voice and additional serif roles
/// (see `docs/design/README.md` § Typography).
abstract class AppTypography {
  /// Hero headline (landing, wrap-up). Callers wrap the emphasis span in
  /// `.copyWith(fontStyle: FontStyle.italic, color: AppColors.primaryLight)`.
  static TextStyle get heroHeadline => GoogleFonts.fraunces(
    fontSize: 40,
    height: 1.05,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.6,
    color: AppColors.textPrimary,
  );

  /// Screen title (Fraunces 26–30/1.15 in the spec).
  static TextStyle get screenTitle => GoogleFonts.fraunces(
    fontSize: 28,
    height: 1.15,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  /// Big number: totals, stats, day counts (Fraunces 21–42/1).
  static TextStyle get bigNumber => GoogleFonts.fraunces(
    fontSize: 30,
    height: 1.0,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  /// Italic pull-quote / narrative copy.
  static TextStyle get pullQuote => GoogleFonts.fraunces(
    fontSize: 15,
    height: 1.7,
    fontWeight: FontWeight.w400,
    fontStyle: FontStyle.italic,
    color: AppColors.textSecondary,
  );

  /// Body emphasis / list item (Roboto 500, 12.5–14).
  static TextStyle get bodyEmphasis => GoogleFonts.roboto(
    fontSize: 13,
    height: 1.5,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  /// Eyebrow / metadata label voice: dates, counts, category names, section
  /// headers. Always rendered uppercase — callers apply `.toUpperCase()` to
  /// the string themselves, since [TextStyle] has no text-transform.
  static TextStyle get mono => GoogleFonts.jetBrainsMono(
    fontSize: 9.5,
    height: 1.3,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.3, // ~.14em at this size; spec range is .10–.18em.
    color: AppColors.textTertiary,
  );

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

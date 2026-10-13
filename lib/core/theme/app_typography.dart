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

  // --- Journal note page (docs/design/JOURNAL_NOTE_PAGETURN_SPEC.md §2–4,
  // #205) ----------------------------------------------------------------

  /// Line height of the note body — the ruled lines are drawn on this grid.
  static const double noteLineHeight = 30;

  /// Forces every body line (old entry + new field) onto the
  /// [noteLineHeight] grid, so the text keeps sitting on the rules whatever
  /// the font's own metrics are.
  static const StrutStyle noteBodyStrut = StrutStyle(
    fontSize: 15,
    height: noteLineHeight / 15,
    forceStrutHeight: true,
  );

  /// Note body, old and new: Fraunces italic 15 on a 30px line.
  static TextStyle get noteBody => GoogleFonts.fraunces(
    fontSize: 15,
    height: noteLineHeight / 15,
    fontWeight: FontWeight.w400,
    fontStyle: FontStyle.italic,
    color: AppColors.paperInk,
  );

  /// Writing-page title.
  static TextStyle get noteTitle => GoogleFonts.fraunces(
    fontSize: 23,
    height: 1.2,
    fontWeight: FontWeight.w400,
    color: AppColors.paperInk,
  );

  /// "DAY 2 · 13 AUG" on the writing page (uppercase by caller).
  static TextStyle get noteStamp =>
      mono.copyWith(fontSize: 9.5, color: AppColors.paperInkMuted);

  /// Cancel / Done in the writing-page header.
  static TextStyle get noteHeaderAction => GoogleFonts.roboto(
    fontSize: 14,
    height: 1.2,
    fontWeight: FontWeight.w600,
    color: AppColors.paperInkMuted,
  );

  /// The dock's "Aa" button glyph.
  static TextStyle get noteDockAa => GoogleFonts.fraunces(
    fontSize: 15,
    height: 1,
    fontWeight: FontWeight.w600,
    color: AppColors.paperInk,
  );

  /// Label under the mic button.
  static TextStyle get noteDockLabel => GoogleFonts.roboto(
    fontSize: 11,
    height: 1.3,
    fontWeight: FontWeight.w600,
    color: AppColors.paperDockLabel,
  );

  /// "+12 words" draft counter.
  static TextStyle get noteDockCounter =>
      mono.copyWith(fontSize: 10, color: AppColors.paperInkMuted);

  /// "LISTENING · 0:07" above the dock while dictating — Mono 10, .12em.
  static TextStyle get noteListening => mono.copyWith(
    fontSize: 10,
    letterSpacing: 1.2,
    color: AppColors.paperListenInk,
  );

  /// Inline "Microphone is off…" notice under the dock.
  static TextStyle get noteNotice => GoogleFonts.roboto(
    fontSize: 12,
    height: 1.4,
    fontWeight: FontWeight.w500,
    color: AppColors.paperInkMuted,
  );

  /// Title-page stamp — Mono 10, .2em.
  static TextStyle get titlePageStamp => mono.copyWith(
    fontSize: 10,
    letterSpacing: 2,
    color: AppColors.paperInkMuted,
  );

  /// Title-page title — Fraunces 32/1.15, centred by caller.
  static TextStyle get titlePageTitle => GoogleFonts.fraunces(
    fontSize: 32,
    height: 1.15,
    fontWeight: FontWeight.w400,
    color: AppColors.paperInk,
  );

  /// "128 words · 5 photos" under the polaroid.
  static TextStyle get titlePageMeta => GoogleFonts.fraunces(
    fontSize: 13,
    height: 1.4,
    fontWeight: FontWeight.w400,
    fontStyle: FontStyle.italic,
    color: AppColors.paperInkMuted,
  );
}

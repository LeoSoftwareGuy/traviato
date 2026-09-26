import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';

/// Color/font token reconciliation for the Wrap-Up Film
/// (docs/design/WRAP_UP_FILM_FLUTTER_SPEC.md §2) against this app's actual theme —
/// every spec token below maps to an existing `AppColors` value except
/// [bg], which was genuinely missing (`AppColors.filmBackground`, #126 plan
/// comment).
abstract class WrapUpFilmColors {
  static const Color ink = AppColors.textPrimary;
  static const Color dim = AppColors.textSecondary;
  static const Color faint = AppColors.textTertiary;
  static const Color bg = AppColors.filmBackground;
  static const Color accent = AppColors.primary;
  static const Color amber = AppColors.primaryLight;
  static const Color dare = AppColors.accentBlue;

  // Collage paper stock (docs/design/WRAP_UP_FILM_COLLAGE_SPEC.md §3, §5) —
  // film-only, like the print's card-stock colours: never UI chrome, so
  // deliberately not promoted to `AppColors` (#151 plan).
  static const Color paper = Color(0xFFEFECE4);
  static const Color paperRim = Color(0xFFF6F4EE);
}

/// Text builders for the film's fixed 1080×1920 canvas — sizes are literal
/// canvas px from the spec, not the app's device-independent
/// `AppTypography` scale (the whole canvas is uniformly scaled to fit the
/// screen, so these never need to be responsive on their own).
abstract class WrapUpFilmText {
  static TextStyle serif({
    required double size,
    required Color color,
    double height = 1.1,
    double letterSpacing = 0,
    bool italic = false,
    FontWeight weight = FontWeight.w300,
  }) => GoogleFonts.fraunces(
    fontSize: size,
    height: height,
    letterSpacing: letterSpacing,
    fontStyle: italic ? FontStyle.italic : FontStyle.normal,
    fontWeight: weight,
    color: color,
  );

  static TextStyle sans({
    required double size,
    required Color color,
    double height = 1.4,
    FontWeight weight = FontWeight.w400,
  }) => GoogleFonts.roboto(
    fontSize: size,
    height: height,
    fontWeight: weight,
    color: color,
  );

  /// Uppercase mono label voice — callers apply `.toUpperCase()` to the
  /// string themselves, matching `AppTypography.mono`'s convention.
  static TextStyle mono({
    double size = 24,
    Color color = WrapUpFilmColors.faint,
    double letterSpacingEm = 0.26,
  }) => GoogleFonts.jetBrainsMono(
    fontSize: size,
    fontWeight: FontWeight.w500,
    letterSpacing: size * letterSpacingEm,
    color: color,
  );
}

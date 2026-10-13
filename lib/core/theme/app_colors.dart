import 'package:flutter/material.dart';

/// Color tokens pulled from the Figma "Leo's team library" file (New memory
/// / Add trip frame, node 449:2) — dark navy background with an orange
/// accent. See `docs/issue-backlog.md` #3 for the source frame.
abstract class AppColors {
  static const Color background = Color(0xFF0C0F27);
  static const Color backgroundScrim = Color(0xB30C0F27);
  // "background-50" — `background`'s navy hue scaled darker (not a
  // different, more violet color), so it reads as unmistakably dark blue
  // rather than purple. Cards in the `surface*` navy family read as a
  // distinct layer on top of it instead of blending in (e.g. Plan's quest
  // cards).
  static const Color background50 = Color(0xFF0A0D21);
  static const Color surface = Color(0xB3131736);
  static const Color surfaceBorder = Color(0x991D2248);
  static const Color surfaceDisabled = Color(0xB31D2248);
  // Card fill for idle/unchecked rows on very dark screens (e.g. Plan) where
  // `surface` reads as barely-there — bumped opacity so the card visibly
  // separates from the background instead of melting into it.
  static const Color surfaceElevated = Color(0xCC131736);

  static const Color textPrimary = Color(0xFFFBFAF6);
  static const Color textSecondary = Color(0xFFAEACB7);
  static const Color textTertiary = Color(0xFF6D6D7A);
  static const Color textMuted = Color(0xFF92909E);
  // Overlaid on photography — pure white, distinct from the app's off-white
  // textPrimary, matching the Figma photo-hero/card treatment.
  static const Color textOnPhoto = Color(0xFFFFFFFF);
  static const Color textOnPhotoMuted = Color(0xB3FFFFFF);

  static const Color primary = Color(0xFFF29520);
  static const Color primaryTint = Color(0x26F29520);
  // Warm light variant of primary — serif emphasis spans, headline italics.
  static const Color primaryLight = Color(0xFFF2A65A);
  static const Color accentCoral = Color(0xFFFF6D79);
  static const Color accentCoralTint = Color(0x26FF6D79);
  static const Color accentPurple = Color(0xFF8962C5);
  static const Color accentPurpleTint = Color(0x1A8962C5);
  // Light variant of accentPurple — compare column B text.
  static const Color accentPurpleLight = Color(0xFFC9A9F5);
  // Shopping category color.
  static const Color accentBlue = Color(0xFF4FB0D8);
  // Success / positive — Activities category color.
  static const Color success = Color(0xFF5FBF8E);

  // Modal barrier scrim — #07091A @ 72%.
  static const Color scrim = Color(0xB807091A);
  // Wrap-Up Film's own background (docs/design/WRAP_UP_FILM_FLUTTER_SPEC.md `bg`) —
  // deliberately distinct from `background`; it's the opaque form of
  // `scrim`'s base color, used pervasively across the film's chrome.
  static const Color filmBackground = Color(0xFF07091A);

  // --- Paper (Journal note page, docs/design/JOURNAL_NOTE_PAGETURN_SPEC.md
  // §2, #205) ------------------------------------------------------------
  // The notebook is a light island in the dark app; the full-screen
  // backdrop behind it is `filmBackground`.
  static const Color paper = Color(0xFFF3EDE0);
  static const Color paperDock = Color(0xFFECE5D5);
  // Stacked page edges peeking out behind the writing page (front → back).
  static const Color paperEdge = Color(0xFFE1D8C4);
  static const Color paperEdgeBack = Color(0xFFCFC5B0);
  // Light end of the turned page's back-face gradient.
  static const Color paperBackLight = Color(0xFFEAE2D0);
  static const Color paperInk = Color(0xFF1E1B3A);
  // Existing (read-only) entry text — faded ink.
  static const Color paperInkOld = Color(0xFF625D7A);
  static const Color paperInkMuted = Color(0xFF6B6680);
  // Ruled lines and the dock divider — ink @ 10%.
  static const Color paperRule = Color(0x1A1E1B3A);
  // "Done" — 4.5:1 on `paper`.
  static const Color paperDoneInk = Color(0xFFB4600A);
  static const Color paperDockLabel = Color(0xFF4A4566);
  static const Color polaroid = Color(0xFFFFFFFF);
  // Drop shadow under the turning page — black @ 25%.
  static const Color paperDropShadow = Color(0x40000000);

  /// Tints an accent [color] to the given [opacity] (0–1) for icon-chip
  /// fills, card washes and borders — the 10–18% alpha fills used throughout
  /// the redesign (e.g. `AppColors.tint(AppColors.primary, .16)`).
  static Color tint(Color color, double opacity) =>
      color.withValues(alpha: opacity);
}

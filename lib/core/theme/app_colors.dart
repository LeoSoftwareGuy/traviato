import 'package:flutter/material.dart';

/// Color tokens pulled from the Figma "Leo's team library" file (New memory
/// / Add trip frame, node 449:2) — dark navy background with an orange
/// accent. See `docs/issue-backlog.md` #3 for the source frame.
abstract class AppColors {
  static const Color background = Color(0xFF0C0F27);
  static const Color backgroundScrim = Color(0xB30C0F27);
  static const Color surface = Color(0xB3131736);
  static const Color surfaceBorder = Color(0x991D2248);
  static const Color surfaceDisabled = Color(0xB31D2248);

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
  static const Color accentCoral = Color(0xFFFF6D79);
  static const Color accentCoralTint = Color(0x26FF6D79);
  static const Color accentPurple = Color(0xFF8962C5);
  static const Color accentPurpleTint = Color(0x1A8962C5);
}

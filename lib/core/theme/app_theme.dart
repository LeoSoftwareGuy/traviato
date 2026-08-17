import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Builds the app's [ThemeData] from the design tokens in this directory.
///
/// The Figma design has no light variant, so this is the app's only theme
/// for the MVP.
abstract class AppTheme {
  static ThemeData get dark {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
      primary: AppColors.primary,
      secondary: AppColors.accentCoral,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      error: AppColors.accentCoral,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: TextTheme(
        displaySmall: AppTypography.displaySerif,
        headlineSmall: AppTypography.headlineSerif,
        titleLarge: AppTypography.headlineSerif,
        bodyLarge: AppTypography.bodyInput,
        labelLarge: AppTypography.buttonLabel,
        labelMedium: AppTypography.fieldLabel,
        labelSmall: AppTypography.chipLabel,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        titleTextStyle: AppTypography.headlineSerif,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base,
          vertical: AppSpacing.md,
        ),
        hintStyle: AppTypography.bodyInput.copyWith(
          color: AppColors.textTertiary,
        ),
        border: const OutlineInputBorder(
          borderRadius: AppRadius.cardRadius,
          borderSide: BorderSide(color: AppColors.surfaceBorder),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadius.cardRadius,
          borderSide: BorderSide(color: AppColors.surfaceBorder),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppRadius.cardRadius,
          borderSide: BorderSide(color: AppColors.primary),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.background,
          disabledBackgroundColor: AppColors.surfaceDisabled,
          disabledForegroundColor: AppColors.textTertiary,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.base),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.cardRadius,
          ),
          textStyle: AppTypography.buttonLabel,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        side: const BorderSide(color: AppColors.surfaceBorder),
        shape: const StadiumBorder(),
        labelStyle: AppTypography.chipLabel,
        padding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: AppSpacing.sm,
        ),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.cardRadius,
          side: BorderSide(color: AppColors.surfaceBorder),
        ),
      ),
    );
  }
}

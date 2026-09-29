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
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.base,
          ),
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
      datePickerTheme: datePicker,
    );
  }

  /// Calendar skin shared by `AppDatePickerSheet` and any stray
  /// `showDatePicker` (#163) — tokens only, so both platforms match.
  static DatePickerThemeData get datePicker {
    WidgetStateProperty<Color?> selectable({
      required Color selected,
      required Color idle,
    }) => WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) return AppColors.textTertiary;
      if (states.contains(WidgetState.selected)) return selected;
      return idle;
    });

    final selectedFill = WidgetStateProperty.resolveWith<Color?>(
      (states) =>
          states.contains(WidgetState.selected) ? AppColors.primary : null,
    );

    return DatePickerThemeData(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      headerBackgroundColor: AppColors.background,
      headerForegroundColor: AppColors.textPrimary,
      headerHeadlineStyle: AppTypography.displaySerif,
      headerHelpStyle: AppTypography.mono,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.mediaRadius),
      weekdayStyle: AppTypography.mono.copyWith(color: AppColors.textTertiary),
      dayStyle: AppTypography.bodyInput,
      dayForegroundColor: selectable(
        selected: AppColors.background,
        idle: AppColors.textPrimary,
      ),
      dayBackgroundColor: selectedFill,
      dayOverlayColor: WidgetStatePropertyAll(
        AppColors.tint(AppColors.primary, .12),
      ),
      todayForegroundColor: selectable(
        selected: AppColors.background,
        idle: AppColors.primary,
      ),
      todayBackgroundColor: selectedFill,
      todayBorder: const BorderSide(color: AppColors.primary),
      yearStyle: AppTypography.bodyInput,
      yearForegroundColor: selectable(
        selected: AppColors.background,
        idle: AppColors.textPrimary,
      ),
      yearBackgroundColor: selectedFill,
      dividerColor: AppColors.surfaceBorder,
      cancelButtonStyle: TextButton.styleFrom(
        foregroundColor: AppColors.textSecondary,
      ),
      confirmButtonStyle: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
      ),
    );
  }
}

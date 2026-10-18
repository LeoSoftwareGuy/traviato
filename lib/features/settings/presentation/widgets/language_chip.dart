import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import 'language_sheet.dart';

/// Guest landing's pre-account language switch (localization design 1d):
/// the 2-letter code + ▾, never a flag — one language isn't one country.
class LanguageChip extends StatelessWidget {
  const LanguageChip({super.key});

  @override
  Widget build(BuildContext context) {
    // The language the UI is actually in right now.
    final code = Localizations.localeOf(context).languageCode.toUpperCase();
    return Semantics(
      button: true,
      child: InkWell(
        key: const Key('guest-language-chip'),
        onTap: () => LanguageSheet.show(context),
        borderRadius: AppRadius.pillRadius,
        // ≥48pt hit area around the small pill.
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(
                  color: AppColors.tint(AppColors.primary, .55),
                ),
                borderRadius: AppRadius.pillRadius,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    code,
                    style: AppTypography.mono.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '▾',
                    style: AppTypography.caption.copyWith(
                      fontSize: 8,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

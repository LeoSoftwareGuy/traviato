import 'package:flutter/material.dart';

import '../../../../core/l10n/context_l10n.dart';
import '../../../../core/l10n/l10n_dates.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/bottom_sheet_chrome.dart';

/// "This photo was taken on 12 Apr · Add it to 12 Apr instead?" (#468):
/// Move / Keep here, when a gallery photo is added to another Journal day
/// than the one it was taken on. A batch asks once for all of them. True
/// to move; dismissing keeps them where they were added.
abstract final class MovePhotoDaySheet {
  static Future<bool> ask(
    BuildContext context, {
    required int count,
    required DateTime takenOn,
  }) async {
    final moved = await showAppBottomSheet<bool>(
      context: context,
      builder: (context) {
        final l10n = context.l10n;
        final date = L10nDates.weekdayDayMonth(
          l10n.localeName,
        ).format(takenOn);
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.base,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                count == 1
                    ? l10n.photo_movePromptTitle(date)
                    : l10n.photo_moveBatchTitle(count),
                style: AppTypography.displaySerif,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                count == 1
                    ? l10n.photo_movePromptBody(date)
                    : l10n.photo_moveBatchBody,
                style: AppTypography.bodyEmphasis.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      key: const Key('move-photo-keep'),
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: AppColors.hairline),
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: Text(l10n.photo_keepHere),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FilledButton(
                      key: const Key('move-photo-move'),
                      onPressed: () => Navigator.of(context).pop(true),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.background,
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: Text(l10n.photo_moveAction),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
    return moved ?? false;
  }
}

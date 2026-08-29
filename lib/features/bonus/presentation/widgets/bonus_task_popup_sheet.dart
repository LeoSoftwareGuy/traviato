import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/bottom_sheet_chrome.dart';
import '../controllers/bonus_tray_state.dart';

/// Task detail popup — reward + prompt, "Open camera" / "Maybe later"
/// (issue #64 AC). Purely presentational: resolves to `true` when the user
/// wants to capture a photo for this task, `false`/`null` otherwise. The
/// caller owns the actual capture + completion flow, since that needs a
/// [WidgetRef] that outlives this sheet.
class BonusTaskPopupSheet extends StatelessWidget {
  const BonusTaskPopupSheet({required this.task, super.key});

  final BonusTrayTask task;

  static Future<bool?> show(
    BuildContext context, {
    required BonusTrayTask task,
  }) {
    return showAppBottomSheet<bool>(
      context: context,
      builder: (context) => BonusTaskPopupSheet(task: task),
    );
  }

  @override
  Widget build(BuildContext context) {
    final detail = task.template.detail;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.sm,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  task.template.title,
                  style: AppTypography.screenTitle.copyWith(fontSize: 21),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.tint(AppColors.primary, .16),
                  borderRadius: AppRadius.pillRadius,
                ),
                child: Text(
                  '✦${task.template.points}',
                  style: AppTypography.mono.copyWith(color: AppColors.primary),
                ),
              ),
            ],
          ),
          if (detail != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              detail,
              style: AppTypography.chipLabel.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            child: const Text('Open camera'),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Maybe later'),
          ),
        ],
      ),
    );
  }
}

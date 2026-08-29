import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/bonus_task_template_entity.dart';
import '../controllers/bonus_tray_state.dart';

IconData _iconFor(BonusTaskKind kind) => switch (kind) {
  BonusTaskKind.starter => Icons.auto_awesome_outlined,
  BonusTaskKind.stretch => Icons.bolt_outlined,
  BonusTaskKind.milestone => Icons.flag_outlined,
  BonusTaskKind.streakSaver => Icons.favorite_outline,
  BonusTaskKind.regular => Icons.camera_alt_outlined,
};

/// One row in the daily tray — a tint icon tile, title/detail, and a ✦N
/// badge, per the R-1 tray visual language (issue #64 AC). Completed rows
/// dim and check off; tapping an open row opens the task popup.
class BonusTaskTile extends StatelessWidget {
  const BonusTaskTile({required this.task, required this.onTap, super.key});

  final BonusTrayTask task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final completed = task.isCompleted;
    return InkWell(
      key: Key('bonus-task-tile-${task.assignment.id}'),
      onTap: completed ? null : onTap,
      borderRadius: AppRadius.cardRadius,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.base),
        decoration: BoxDecoration(
          color: completed ? AppColors.surface : AppColors.surfaceElevated,
          border: Border.all(color: AppColors.surfaceBorder),
          borderRadius: AppRadius.cardRadius,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.tint(AppColors.primary, .16),
                shape: BoxShape.circle,
              ),
              child: Icon(
                completed ? Icons.check_rounded : _iconFor(task.template.kind),
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                task.template.title,
                style: AppTypography.bodyEmphasis.copyWith(
                  color: completed
                      ? AppColors.textTertiary
                      : AppColors.textPrimary,
                  decoration: completed ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            _PointsBadge(points: task.template.points, dim: completed),
          ],
        ),
      ),
    );
  }
}

class _PointsBadge extends StatelessWidget {
  const _PointsBadge({required this.points, required this.dim});

  final int points;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.tint(AppColors.primary, dim ? .08 : .16),
        borderRadius: AppRadius.pillRadius,
      ),
      child: Text(
        '✦$points',
        style: AppTypography.mono.copyWith(
          color: dim ? AppColors.textTertiary : AppColors.primary,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/quest_entity.dart';
import 'quest_time_format.dart';

/// One timeline row: check circle + connector line, time badge, title,
/// detail line, and an edit affordance.
class QuestTile extends StatelessWidget {
  const QuestTile({
    required this.quest,
    required this.isLast,
    required this.isToggling,
    required this.onToggle,
    required this.onEdit,
    super.key,
  });

  final QuestEntity quest;
  final bool isLast;
  final bool isToggling;
  final VoidCallback onToggle;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              _CheckCircle(
                key: Key('quest-check-${quest.id}'),
                isCompleted: quest.isCompleted,
                isToggling: isToggling,
                onTap: onToggle,
              ),
              if (!isLast)
                const Expanded(
                  child: VerticalDivider(
                    color: AppColors.surfaceBorder,
                    width: 1,
                    thickness: 1,
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.base,
                  vertical: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.surfaceBorder),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (quest.time != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          border: Border.all(color: AppColors.surfaceBorder),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          formatQuestTime(quest.time!),
                          style: AppTypography.chipLabel.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            quest.title,
                            style: AppTypography.bodyInput.copyWith(
                              fontWeight: FontWeight.w600,
                              decoration: quest.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: quest.isCompleted
                                  ? AppColors.textMuted
                                  : AppColors.textPrimary,
                            ),
                          ),
                          if (quest.placeText != null)
                            Text(
                              quest.placeText!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.chipLabel.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: onEdit,
                      icon: const Icon(Icons.more_horiz, size: 20),
                      color: AppColors.textTertiary,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckCircle extends StatelessWidget {
  const _CheckCircle({
    super.key,
    required this.isCompleted,
    required this.isToggling,
    required this.onTap,
  });

  final bool isCompleted;
  final bool isToggling;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isToggling ? null : onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isCompleted ? AppColors.accentCoral : AppColors.background,
          border: Border.all(
            color: AppColors.accentCoral.withValues(
              alpha: isCompleted ? 1 : 0.7,
            ),
            width: 2,
          ),
        ),
        child: isToggling
            ? const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.accentCoral,
                ),
              )
            : isCompleted
            ? const Icon(Icons.check, size: 16, color: AppColors.background)
            : null,
      ),
    );
  }
}

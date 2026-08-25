import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/quest_entity.dart';
import 'quest_time_format.dart';

/// One timeline row: check circle + connector rail, mono time, serif title,
/// detail line. `docs/design/README.md` § 5.
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
                Expanded(
                  child: Container(
                    width: 1.5,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.tint(AppColors.primary, .5),
                          AppColors.surfaceBorder,
                        ],
                      ),
                    ),
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
                  color: quest.isCompleted
                      ? AppColors.tint(AppColors.primary, .09)
                      : AppColors.surface,
                  border: Border.all(
                    color: quest.isCompleted
                        ? AppColors.tint(AppColors.primary, .4)
                        : AppColors.surfaceBorder,
                  ),
                  borderRadius: AppRadius.cardRadius,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (quest.time != null) ...[
                      Text(
                        formatQuestTime(quest.time!),
                        style: AppTypography.mono.copyWith(
                          color: AppColors.primary,
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
                            style: AppTypography.screenTitle.copyWith(
                              fontSize: 16,
                              decoration: quest.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: quest.isCompleted
                                  ? AppColors.textSecondary
                                  : AppColors.textPrimary,
                            ),
                          ),
                          if (quest.placeText != null)
                            Text(
                              quest.placeText!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.chipLabel.copyWith(
                                fontSize: 11.5,
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
        width: 22,
        height: 22,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isCompleted ? AppColors.primary : Colors.transparent,
          border: Border.all(
            color: isCompleted
                ? AppColors.primary
                : AppColors.tint(AppColors.textSecondary, .4),
            width: 1.5,
          ),
        ),
        child: isToggling
            ? const SizedBox(
                width: 11,
                height: 11,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              )
            : isCompleted
            ? const Icon(Icons.check, size: 14, color: AppColors.background)
            : null,
      ),
    );
  }
}

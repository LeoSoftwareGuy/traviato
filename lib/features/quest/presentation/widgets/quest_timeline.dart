import 'package:flutter/material.dart';
import 'package:flutter_riverpod/experimental/mutation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/quest_entity.dart';
import '../mutations/quest_mutations.dart';
import 'quest_tile.dart';

/// The current day's quests, or an empty-day prompt.
class QuestTimeline extends ConsumerWidget {
  const QuestTimeline({
    required this.tripId,
    required this.quests,
    required this.onToggle,
    required this.onEditQuest,
    required this.onAddQuest,
    super.key,
  });

  final String tripId;
  final List<QuestEntity> quests;
  final void Function(QuestEntity quest) onToggle;
  final void Function(QuestEntity quest) onEditQuest;
  final VoidCallback onAddQuest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (quests.isEmpty) {
      return _EmptyDay(onAddQuest: onAddQuest);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < quests.length; i++)
          QuestTile(
            quest: quests[i],
            isLast: i == quests.length - 1,
            isToggling:
                ref.watch(toggleQuestMutation(quests[i].id)) is MutationPending,
            onToggle: () => onToggle(quests[i]),
            onEdit: () => onEditQuest(quests[i]),
          ),
      ],
    );
  }
}

class _EmptyDay extends StatelessWidget {
  const _EmptyDay({required this.onAddQuest});

  final VoidCallback onAddQuest;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.surfaceBorder),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.checklist_outlined,
            color: AppColors.textTertiary,
            size: 32,
          ),
          const SizedBox(height: AppSpacing.base),
          Text('No quests added yet', style: AppTypography.bodyInput),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Plan something for this day.',
            style: AppTypography.chipLabel.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton.icon(
            onPressed: onAddQuest,
            icon: const Icon(Icons.add),
            label: const Text('Add plan'),
          ),
        ],
      ),
    );
  }
}

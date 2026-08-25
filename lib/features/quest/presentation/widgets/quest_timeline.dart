import 'package:flutter/material.dart';
import 'package:flutter_riverpod/experimental/mutation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/quest_entity.dart';
import '../mutations/quest_mutations.dart';
import 'quest_tile.dart';

/// The current day's quests, top to bottom. Reused by Plan and Journal's
/// To Do sheet — the dashed "+ Add a quest" footer lives with the caller
/// (Plan's `AddQuestRow`), not here, so this stays a plain list in both
/// places.
class QuestTimeline extends ConsumerWidget {
  const QuestTimeline({
    required this.tripId,
    required this.quests,
    required this.onToggle,
    required this.onEditQuest,
    super.key,
  });

  final String tripId;
  final List<QuestEntity> quests;
  final void Function(QuestEntity quest) onToggle;
  final void Function(QuestEntity quest) onEditQuest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (quests.isEmpty) return const SizedBox.shrink();
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

import 'package:flutter_riverpod/experimental/mutation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/presentation_failure_exception.dart';
import '../../../../core/events/global_event.dart';
import '../../../../core/events/global_event_bus.dart';
import '../../domain/entities/quest_entity.dart';
import '../controllers/plan_controller.dart';
import '../providers/quest_providers.dart';

final addQuestMutation = Mutation<QuestEntity>();
final updateQuestMutation = Mutation<QuestEntity>();
final deleteQuestMutation = Mutation<void>();
final toggleQuestMutation = Mutation<QuestEntity>();

int _nextPosition(List<QuestEntity> questsForDay) {
  if (questsForDay.isEmpty) return 0;
  return questsForDay.map((q) => q.position).reduce((a, b) => a > b ? a : b) +
      1;
}

Future<QuestEntity> runAddQuest({
  required WidgetRef ref,
  required String tripId,
  required DateTime dayDate,
  required String title,
  Duration? time,
  String? placeText,
}) {
  return addQuestMutation.run(ref, (tsx) async {
    final repo = tsx.get(questRepositoryProvider);
    final controller = tsx.get(planControllerProvider(tripId).notifier);
    final currentState = tsx.get(planControllerProvider(tripId)).value;
    final questsForDay =
        currentState?.quests
            .where(
              (q) =>
                  q.dayDate.year == dayDate.year &&
                  q.dayDate.month == dayDate.month &&
                  q.dayDate.day == dayDate.day,
            )
            .toList() ??
        const [];

    final result = await repo.addQuest(
      tripId: tripId,
      dayDate: dayDate,
      title: title,
      time: time,
      placeText: placeText,
      position: _nextPosition(questsForDay),
    );
    return result.fold(
      (failure) => throw PresentationFailureException(failure),
      (
        quest,
      ) {
        controller.applyQuestUpserted(quest);
        return quest;
      },
    );
  });
}

Future<QuestEntity> runUpdateQuest({
  required WidgetRef ref,
  required String tripId,
  required String questId,
  required String title,
  Duration? time,
  String? placeText,
}) {
  return updateQuestMutation.run(ref, (tsx) async {
    final repo = tsx.get(questRepositoryProvider);
    final controller = tsx.get(planControllerProvider(tripId).notifier);
    final result = await repo.updateQuest(
      id: questId,
      title: title,
      time: time,
      placeText: placeText,
    );
    return result.fold(
      (failure) => throw PresentationFailureException(failure),
      (
        quest,
      ) {
        controller.applyQuestUpserted(quest);
        return quest;
      },
    );
  });
}

Future<void> runDeleteQuest({
  required WidgetRef ref,
  required String tripId,
  required String questId,
}) {
  return deleteQuestMutation.run(ref, (tsx) async {
    final repo = tsx.get(questRepositoryProvider);
    final controller = tsx.get(planControllerProvider(tripId).notifier);
    (await repo.deleteQuest(questId)).fold(
      (failure) => throw PresentationFailureException(failure),
      (_) => controller.applyQuestRemoved(questId),
    );
  });
}

Future<QuestEntity> runToggleQuest({
  required WidgetRef ref,
  required String tripId,
  required QuestEntity quest,
}) {
  final isCompleting = !quest.isCompleted;
  return toggleQuestMutation(quest.id).run(ref, (tsx) async {
    final repo = tsx.get(questRepositoryProvider);
    final controller = tsx.get(planControllerProvider(tripId).notifier);
    final result = await repo.toggleCompleted(
      id: quest.id,
      tripId: tripId,
      completed: isCompleting,
    );
    return result.fold(
      (failure) => throw PresentationFailureException(failure),
      (
        updated,
      ) {
        controller.applyQuestUpserted(updated);
        // Unchecking never removes stars, so only the checking-off
        // transition needs to refresh the Home stars badge (issue #77).
        if (isCompleting) {
          tsx.get(globalEventBusProvider).add(const StarsAwardedDispatched());
        }
        return updated;
      },
    );
  });
}

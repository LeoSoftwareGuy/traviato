import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/errors/presentation_failure_exception.dart';
import '../../../trip/presentation/providers/trip_providers.dart';
import '../../domain/entities/quest_entity.dart';
import '../providers/quest_providers.dart';
import 'plan_state.dart';

part 'plan_controller.g.dart';

@riverpod
class PlanController extends _$PlanController {
  @override
  Future<PlanState> build(String tripId) async {
    final tripRepo = ref.watch(tripRepositoryProvider);
    final questRepo = ref.watch(questRepositoryProvider);

    final tripResult = await tripRepo.getTripCard(tripId);
    final trip = tripResult.fold(
      (failure) => throw PresentationFailureException(failure),
      (t) => t,
    );

    final questsResult = await questRepo.getQuestsForTrip(tripId);
    final quests = questsResult.fold(
      (failure) => throw PresentationFailureException(failure),
      (q) => q,
    );

    return PlanState(
      trip: trip,
      quests: quests,
      currentDayDate: _initialDayDate(trip.startDate, trip.endDate),
    );
  }

  void goToPreviousDay() {
    final current = state.value;
    if (current == null || !current.canGoToPreviousDay) return;
    state = AsyncData(
      current.copyWith(
        currentDayDate: () =>
            current.currentDayDate!.subtract(const Duration(days: 1)),
      ),
    );
  }

  void goToNextDay() {
    final current = state.value;
    if (current == null || !current.canGoToNextDay) return;
    state = AsyncData(
      current.copyWith(
        currentDayDate: () =>
            current.currentDayDate!.add(const Duration(days: 1)),
      ),
    );
  }

  /// Called by the quest mutations after a successful add/update/toggle.
  void applyQuestUpserted(QuestEntity quest) {
    final current = state.value;
    if (current == null) return;
    final exists = current.quests.any((q) => q.id == quest.id);
    final updated = exists
        ? [
            for (final q in current.quests)
              if (q.id == quest.id) quest else q,
          ]
        : [...current.quests, quest];
    state = AsyncData(current.copyWith(quests: updated));
  }

  /// Called by the delete mutation after a successful delete.
  void applyQuestRemoved(String questId) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(
        quests: current.quests.where((q) => q.id != questId).toList(),
      ),
    );
  }
}

DateTime? _initialDayDate(DateTime? startDate, DateTime? endDate) {
  if (startDate == null || endDate == null) return null;
  final today = DateTime.now();
  final todayDate = DateTime(today.year, today.month, today.day);
  if (todayDate.isBefore(startDate)) return startDate;
  if (todayDate.isAfter(endDate)) return endDate;
  return todayDate;
}

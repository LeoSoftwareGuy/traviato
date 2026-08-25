import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/errors/presentation_failure_exception.dart';
import '../../../trip/domain/entities/trip_card_entity.dart';
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

  /// Jumps to the day at 1-based [dayNumber] (a pager segment dot tap).
  void goToDayNumber(int dayNumber) {
    final current = state.value;
    if (current == null || !current.hasDateRange) return;
    if (dayNumber < 1 || dayNumber > current.totalDays) return;
    state = AsyncData(
      current.copyWith(
        currentDayDate: () =>
            current.trip.startDate!.add(Duration(days: dayNumber - 1)),
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

  /// Called by the rename/cover-change mutations after a successful update.
  void applyTripUpdated(TripCardEntity trip) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(trip: trip));
  }

  /// Called by the date-shift mutation after the `shift_trip_dates` RPC
  /// succeeds — mirrors what it just did server-side by re-dating every
  /// held quest (and the currently-viewed day) by the same delta, rather
  /// than refetching.
  void applyDatesShifted(TripCardEntity trip, int deltaDays) {
    final current = state.value;
    if (current == null) return;
    final shift = Duration(days: deltaDays);
    state = AsyncData(
      current.copyWith(
        trip: trip,
        quests: [
          for (final q in current.quests) q.withDayDate(q.dayDate.add(shift)),
        ],
        currentDayDate: current.currentDayDate == null
            ? null
            : () => current.currentDayDate!.add(shift),
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

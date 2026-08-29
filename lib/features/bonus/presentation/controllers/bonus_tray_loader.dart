import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/errors/presentation_failure_exception.dart';
import '../../../journal/domain/repositories/day_note_repository.dart';
import '../../../journal/presentation/providers/day_note_providers.dart';
import '../../../photo/domain/repositories/photo_repository.dart';
import '../../../photo/presentation/providers/photo_providers.dart';
import '../../../quest/domain/repositories/quest_repository.dart';
import '../../../quest/presentation/providers/quest_providers.dart';
import '../../../trip/presentation/providers/trip_providers.dart';
import '../providers/bonus_task_providers.dart';
import 'bonus_tray_state.dart';

/// Shared load: trip + templates + assignments, ensuring today's tray (and,
/// if due, a streak-saver) exist. Used by both [BonusTrayController] and the
/// Home badge-dot provider so both reflect the same state.
Future<BonusTrayState> loadBonusTrayState(Ref ref, String tripId) async {
  final tripRepo = ref.watch(tripRepositoryProvider);
  final questRepo = ref.watch(questRepositoryProvider);
  final noteRepo = ref.watch(dayNoteRepositoryProvider);
  final photoRepo = ref.watch(photoRepositoryProvider);
  final useCase = ref.watch(ensureDailyTrayUseCaseProvider);

  final trip = (await tripRepo.getTripCard(tripId)).fold(
    (failure) => throw PresentationFailureException(failure),
    (t) => t,
  );

  final activityDates = await _activityDatesForTrip(
    tripId: tripId,
    questRepo: questRepo,
    noteRepo: noteRepo,
    photoRepo: photoRepo,
  );

  final today = _dateOnly(DateTime.now());
  final result = (await useCase(
    trip: trip,
    today: today,
    activityDates: activityDates,
  )).fold((failure) => throw PresentationFailureException(failure), (r) => r);

  return BonusTrayState(
    trip: trip,
    templates: result.templates,
    assignments: result.assignments,
    today: today,
  );
}

Future<Set<DateTime>> _activityDatesForTrip({
  required String tripId,
  required QuestRepository questRepo,
  required DayNoteRepository noteRepo,
  required PhotoRepository photoRepo,
}) async {
  final quests = (await questRepo.getQuestsForTrip(tripId)).fold(
    (failure) => throw PresentationFailureException(failure),
    (q) => q,
  );
  final notes = (await noteRepo.getNotesForTrip(tripId)).fold(
    (failure) => throw PresentationFailureException(failure),
    (n) => n,
  );
  final photos = (await photoRepo.getPhotosForTrip(tripId)).fold(
    (failure) => throw PresentationFailureException(failure),
    (p) => p,
  );

  return {
    for (final q in quests)
      if (q.completedAt != null) _dateOnly(q.completedAt!),
    for (final n in notes) _dateOnly(n.dayDate),
    for (final p in photos)
      if ((p.dayDate ?? p.takenAt) != null)
        _dateOnly((p.dayDate ?? p.takenAt)!),
  };
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

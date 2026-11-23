import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/presentation_failure_exception.dart';
import '../../../bonus/presentation/providers/bonus_task_providers.dart';
import '../../../journal/presentation/providers/journal_note_providers.dart';
import '../../../photo/presentation/providers/photo_providers.dart';
import '../../../quest/presentation/providers/quest_providers.dart';
import '../../../trip/presentation/providers/trip_providers.dart';
import '../../domain/build_kept_memory.dart';
import '../../domain/entities/kept_memory.dart';

part 'kept_memory_provider.g.dart';

/// Everything the Kept Memory page shows (#279), fetched concurrently and
/// grouped by [buildKeptMemory]. Read-only — the page edits nothing, so
/// there's no controller or event subscription.
@riverpod
Future<KeptMemory> keptMemory(Ref ref, String tripId) async {
  final bonusRepo = ref.watch(bonusTaskRepositoryProvider);
  final tripFuture = ref.watch(tripRepositoryProvider).getTripCard(tripId);
  final photosFuture = ref
      .watch(photoRepositoryProvider)
      .getPhotosForTrip(tripId);
  final notesFuture = ref
      .watch(journalNoteRepositoryProvider)
      .getNotesForTrip(tripId);
  final questsFuture = ref
      .watch(questRepositoryProvider)
      .getQuestsForTrip(tripId);
  final assignmentsFuture = bonusRepo.getAssignmentsForTrip(tripId);
  final templatesFuture = bonusRepo.getTemplates();

  T orThrow<T>(Either<Failure, T> result) => result.fold(
    (failure) => throw PresentationFailureException(failure),
    (value) => value,
  );

  // Bonus pills are a garnish: without them every photo still shows.
  List<T> orEmpty<T>(Either<Failure, List<T>> result) => result.fold((failure) {
    debugPrint('Kept memory bonus lookup failed for $tripId: $failure');
    return const [];
  }, (value) => value);

  final trip = orThrow(await tripFuture);
  // Times on the clock of where each one happened (#461).
  return buildKeptMemory(
    trip: trip,
    photos: [
      for (final p in orThrow(await photosFuture)) p.onClockOf(trip.timeZone),
    ],
    notes: [
      for (final n in orThrow(await notesFuture)) n.onClockOf(trip.timeZone),
    ],
    quests: orThrow(await questsFuture),
    bonusAssignments: orEmpty(await assignmentsFuture),
    bonusTemplates: orEmpty(await templatesFuture),
  );
}

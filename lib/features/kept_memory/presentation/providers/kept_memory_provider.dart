import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/presentation_failure_exception.dart';
import '../../../bonus/presentation/providers/bonus_task_providers.dart';
import '../../../journal/presentation/providers/day_note_providers.dart';
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
      .watch(dayNoteRepositoryProvider)
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

  return buildKeptMemory(
    trip: orThrow(await tripFuture),
    photos: orThrow(await photosFuture),
    notes: orThrow(await notesFuture),
    quests: orThrow(await questsFuture),
    bonusAssignments: orEmpty(await assignmentsFuture),
    bonusTemplates: orEmpty(await templatesFuture),
  );
}

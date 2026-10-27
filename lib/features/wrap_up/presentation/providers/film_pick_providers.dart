import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../bonus/presentation/providers/bonus_task_providers.dart';
import '../../../journal/presentation/controllers/journal_controller.dart';
import '../../domain/film_moment_picks.dart';

part 'film_pick_providers.g.dart';

/// Photos of the memory's completed bonus tasks, in completion order — the
/// film badges the first 3 (#294). A garnish for the "Film chose this one"
/// hint: on failure it's empty rather than an error.
@riverpod
Future<List<String>> filmBonusPhotoIds(Ref ref, String tripId) async {
  final result = await ref
      .watch(bonusTaskRepositoryProvider)
      .getAssignmentsForTrip(tripId);
  return result.fold(
    (failure) {
      debugPrint('Film bonus lookup failed for $tripId: $failure');
      return const [];
    },
    (assignments) {
      final completed =
          assignments
              .where((a) => a.completedAt != null && a.photoId != null)
              .toList()
            ..sort((a, b) => a.completedAt!.compareTo(b.completedAt!));
      return [for (final a in completed) a.photoId!];
    },
  );
}

/// The Journal's photos the film gives a main moment to, with the current
/// picks (#294) — computed locally, never a network or AI call. Follows
/// every optimistic pick change in the Journal at once.
@riverpod
Set<String> filmMomentIds(Ref ref, String tripId) {
  final photos =
      ref.watch(journalControllerProvider(tripId)).value?.photos ?? const [];
  final bonusPhotoIds =
      ref.watch(filmBonusPhotoIdsProvider(tripId)).value ?? const [];
  return filmMomentPhotoIds(photos: photos, bonusPhotoIds: bonusPhotoIds);
}

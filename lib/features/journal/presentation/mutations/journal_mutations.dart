import 'package:flutter_riverpod/experimental/mutation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/presentation_failure_exception.dart';
import '../../../../core/events/global_event.dart';
import '../../../../core/events/global_event_bus.dart';
import '../../domain/entities/day_note_entity.dart';
import '../controllers/journal_controller.dart';
import '../providers/day_note_providers.dart';

final upsertNoteMutation = Mutation<DayNoteEntity>();

Future<DayNoteEntity> runUpsertNote({
  required WidgetRef ref,
  required String tripId,
  required DateTime dayDate,
  required String content,
}) {
  return upsertNoteMutation.run(ref, (tsx) async {
    final repo = tsx.get(dayNoteRepositoryProvider);
    final controller = tsx.get(journalControllerProvider(tripId).notifier);
    final result = await repo.upsertNote(
      tripId: tripId,
      dayDate: dayDate,
      content: content,
    );
    return result.fold(
      (failure) => throw PresentationFailureException(failure),
      (
        note,
      ) {
        controller.applyNoteUpserted(dayDate, note);
        tsx.get(globalEventBusProvider).add(const StarsAwardedDispatched());
        return note;
      },
    );
  });
}

final deleteNoteMutation = Mutation<Unit>();

/// Clearing the note page's text and confirming (#276): deletes the day's
/// note and takes back its ✦1, so the stars totals refetch.
Future<Unit> runDeleteNote({
  required WidgetRef ref,
  required String tripId,
  required DateTime dayDate,
  required String noteId,
}) {
  return deleteNoteMutation.run(ref, (tsx) async {
    final repo = tsx.get(dayNoteRepositoryProvider);
    final controller = tsx.get(journalControllerProvider(tripId).notifier);
    final result = await repo.deleteNote(noteId);
    return result.fold(
      (failure) => throw PresentationFailureException(failure),
      (_) {
        controller.applyNoteDeleted(dayDate);
        tsx.get(globalEventBusProvider).add(const StarsAwardedDispatched());
        return unit;
      },
    );
  });
}

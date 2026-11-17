import 'package:flutter_riverpod/experimental/mutation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/presentation_failure_exception.dart';
import '../../../../core/events/global_event.dart';
import '../../../../core/events/global_event_bus.dart';
import '../../domain/entities/journal_note_entity.dart';
import '../controllers/journal_controller.dart';
import '../providers/journal_note_providers.dart';

final upsertNoteMutation = Mutation<JournalNoteEntity>();

/// Saves the note page's text: new text for [existingNoteId] when the day
/// already has a note (its time stays, no star), else a new note timed now
/// (✦1, at most 3 a day). Until the timeline view (#401) each day shows one
/// note, so the note page edits it.
Future<JournalNoteEntity> runUpsertNote({
  required WidgetRef ref,
  required String tripId,
  required DateTime dayDate,
  required String content,
  String? existingNoteId,
}) {
  return upsertNoteMutation.run(ref, (tsx) async {
    final repo = tsx.get(journalNoteRepositoryProvider);
    final controller = tsx.get(journalControllerProvider(tripId).notifier);
    final result = existingNoteId == null
        ? await repo.createNote(
            tripId: tripId,
            dayDate: dayDate,
            takenAt: DateTime.now(),
            content: content,
          )
        : await repo.updateNote(
            noteId: existingNoteId,
            content: content,
            dictated: false,
          );
    return result.fold(
      (failure) => throw PresentationFailureException(failure),
      (note) {
        controller.applyNoteUpserted(dayDate, note);
        if (existingNoteId == null) {
          tsx.get(globalEventBusProvider).add(const StarsAwardedDispatched());
        }
        return note;
      },
    );
  });
}

final deleteNoteMutation = Mutation<Unit>();

/// Clearing the note page's text and confirming (#276): deletes the day's
/// note. Its ✦1 stays (#397).
Future<Unit> runDeleteNote({
  required WidgetRef ref,
  required String tripId,
  required DateTime dayDate,
  required String noteId,
}) {
  return deleteNoteMutation.run(ref, (tsx) async {
    final repo = tsx.get(journalNoteRepositoryProvider);
    final controller = tsx.get(journalControllerProvider(tripId).notifier);
    final result = await repo.deleteNote(noteId);
    return result.fold(
      (failure) => throw PresentationFailureException(failure),
      (_) {
        controller.applyNoteDeleted(dayDate, noteId);
        return unit;
      },
    );
  });
}

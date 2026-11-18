import 'package:flutter_riverpod/experimental/mutation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/presentation_failure_exception.dart';
import '../../../../core/events/global_event.dart';
import '../../../../core/events/global_event_bus.dart';
import '../../domain/entities/journal_note_entity.dart';
import '../controllers/journal_controller.dart';
import '../providers/journal_note_providers.dart';

final createNoteMutation = Mutation<JournalNoteEntity>();

/// Every Done on a new note saves a separate note at [takenAt] (#397,
/// #401) on [dayDate] — the logical day the page decided. ✦1, at most 3 a
/// day (the server caps it). [photoId] writes it on that photo (#402).
Future<JournalNoteEntity> runCreateNote({
  required WidgetRef ref,
  required String tripId,
  required DateTime dayDate,
  required DateTime takenAt,
  required String content,
  bool dictated = false,
  String? photoId,
}) {
  return createNoteMutation.run(ref, (tsx) async {
    final repo = tsx.get(journalNoteRepositoryProvider);
    final controller = tsx.get(journalControllerProvider(tripId).notifier);
    final result = await repo.createNote(
      tripId: tripId,
      dayDate: dayDate,
      takenAt: takenAt,
      content: content,
      dictated: dictated,
      photoId: photoId,
    );
    return result.fold(
      (failure) => throw PresentationFailureException(failure),
      (note) {
        controller.applyNoteSaved(note);
        tsx.get(globalEventBusProvider).add(const StarsAwardedDispatched());
        return note;
      },
    );
  });
}

final updateNoteMutation = Mutation<JournalNoteEntity>();

/// New text for a note: its time and day stay, stars don't change.
Future<JournalNoteEntity> runUpdateNote({
  required WidgetRef ref,
  required String tripId,
  required String noteId,
  required String content,
  required bool dictated,
}) {
  return updateNoteMutation.run(ref, (tsx) async {
    final repo = tsx.get(journalNoteRepositoryProvider);
    final controller = tsx.get(journalControllerProvider(tripId).notifier);
    final result = await repo.updateNote(
      noteId: noteId,
      content: content,
      dictated: dictated,
    );
    return result.fold(
      (failure) => throw PresentationFailureException(failure),
      (note) {
        controller.applyNoteSaved(note);
        return note;
      },
    );
  });
}

final deleteNoteMutation = Mutation<Unit>();

/// Deletes one note (#401's long-press, or clearing it on the note page,
/// #276). It leaves the timeline after [foldFor] — the card's fold-away
/// (#407) — while the delete is already under way, and comes back if the
/// delete fails. Its ✦1 stays (#397), so no stars event. The wait lives
/// here, not in the page, so leaving the Journal mid-fold still deletes.
Future<Unit> runDeleteNote({
  required WidgetRef ref,
  required String tripId,
  required String noteId,
  Duration foldFor = Duration.zero,
}) {
  return deleteNoteMutation.run(ref, (tsx) async {
    final repo = tsx.get(journalNoteRepositoryProvider);
    final controller = tsx.get(journalControllerProvider(tripId).notifier);
    final deleting = repo.deleteNote(noteId);
    if (foldFor > Duration.zero) await Future<void>.delayed(foldFor);
    final removed = controller.applyNoteDeleted(noteId);
    final result = await deleting;
    return result.fold((failure) {
      if (removed != null) controller.applyNoteSaved(removed);
      throw PresentationFailureException(failure);
    }, (_) => unit);
  });
}

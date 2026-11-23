import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/errors/presentation_failure_exception.dart';
import '../../../../core/utils/logical_day.dart';
import '../../../photo/domain/entities/film_pick.dart';
import '../../../photo/domain/entities/photo_entity.dart';
import '../../../photo/presentation/providers/photo_providers.dart';
import '../../../quest/presentation/providers/quest_providers.dart';
import '../../../trip/presentation/providers/trip_providers.dart';
import '../../domain/entities/journal_note_entity.dart';
import '../providers/journal_note_providers.dart';
import 'initial_journal_day.dart';
import 'journal_state.dart';

part 'journal_controller.g.dart';

@riverpod
class JournalController extends _$JournalController {
  @override
  Future<JournalState> build(String tripId) async {
    final tripRepo = ref.watch(tripRepositoryProvider);
    final photoRepo = ref.watch(photoRepositoryProvider);
    final noteRepo = ref.watch(journalNoteRepositoryProvider);
    final questRepo = ref.watch(questRepositoryProvider);

    // Independent reads, fetched together: run back to back they were four
    // sequential round trips before the Journal could render (#179).
    final (tripResult, photosResult, notesResult, questsResult) = await (
      tripRepo.getTripCard(tripId),
      photoRepo.getPhotosForTrip(tripId),
      // All-trip notes: the day timeline, wrap-up eligibility (#103) and
      // empty days (#140) all read this one list (#401).
      noteRepo.getNotesForTrip(tripId),
      // Decides whether "To Do" is offered at all (#164) — the sheet itself
      // fetches its own day-scoped copy lazily.
      questRepo.getQuestsForTrip(tripId),
    ).wait;

    final trip = tripResult.fold(
      (failure) => throw PresentationFailureException(failure),
      (t) => t,
    );
    final photos = photosResult.fold(
      (failure) => throw PresentationFailureException(failure),
      (p) => p,
    );
    final notes = notesResult.fold(
      (failure) => throw PresentationFailureException(failure),
      (n) => n,
    );
    final quests = questsResult.fold(
      (failure) => throw PresentationFailureException(failure),
      (q) => q,
    );

    // Times on the clock of where each one happened (#461): its own
    // offset, else the memory's zone.
    final loaded = JournalState(
      trip: trip,
      photos: [for (final p in photos) p.onClockOf(trip.timeZone)],
      notes: [for (final n in notes) n.onClockOf(trip.timeZone)],
      quests: quests,
    );
    // After midnight, a night still going belongs to the evening before
    // (#397): open on that day.
    final now = DateTime.now();
    final latest = loaded.latestItemBefore(now);
    final initialDay = initialJournalDay(
      startDate: trip.startDate,
      endDate: trip.endDate,
      today: logicalDayOf(
        now,
        previousAt: latest?.at,
        previousDay: latest?.day,
      ),
    );

    return loaded.copyWith(currentDayDate: () => initialDay);
  }

  void selectDay(DateTime day) {
    final current = state.value;
    if (current == null || current.isDayLocked(day)) return;
    state = AsyncData(current.copyWith(currentDayDate: () => day));
  }

  /// A note was created, or saved with new text: added, or replaced in
  /// place by id.
  void applyNoteSaved(JournalNoteEntity note) {
    final current = state.value;
    if (current == null) return;
    final notes = [
      for (final n in current.notes)
        if (n.id != note.id) n,
      note,
    ];
    state = AsyncData(current.copyWith(notes: notes));
  }

  /// Drops a note (#401's delete) and returns it, for putting back if the
  /// delete fails; `null` when it isn't loaded.
  JournalNoteEntity? applyNoteDeleted(String noteId) {
    final current = state.value;
    if (current == null) return null;
    final index = current.notes.indexWhere((n) => n.id == noteId);
    if (index == -1) return null;
    final removed = current.notes[index];
    state = AsyncData(
      current.copyWith(notes: [...current.notes]..removeAt(index)),
    );
    return removed;
  }

  /// Called by the add-photo mutation after a successful upload.
  void applyPhotoAdded(PhotoEntity photo) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(photos: [...current.photos, photo]));
  }

  /// Optimistically drops a photo (#165) and returns its position so a
  /// failed delete can put it back exactly where it was; `-1` when it
  /// wasn't there (or the journal isn't loaded).
  int applyPhotoDeleted(String photoId) {
    final current = state.value;
    if (current == null) return -1;
    final index = current.photos.indexWhere((p) => p.id == photoId);
    if (index == -1) return -1;
    state = AsyncData(
      current.copyWith(photos: [...current.photos]..removeAt(index)),
    );
    return index;
  }

  /// Optimistically sets a photo's Wrap-Up Film pick (#294) and returns the
  /// photo as it was, for rolling back; `null` when it isn't loaded.
  PhotoEntity? applyPhotoFilmPick(String photoId, FilmPick pick) {
    final current = state.value;
    if (current == null) return null;
    final index = current.photos.indexWhere((p) => p.id == photoId);
    if (index == -1) return null;
    final previous = current.photos[index];
    final photos = [...current.photos]
      ..[index] = previous.copyWith(filmPick: pick);
    state = AsyncData(current.copyWith(photos: photos));
    return previous;
  }

  /// After a pick saved: records the server's stamp, and — when the save
  /// failed — puts [previous] back. Either only while the photo still holds
  /// [pick], so a newer tap made meanwhile is never overwritten.
  void applyPhotoFilmPickSettled(
    String photoId,
    FilmPick pick, {
    DateTime? setAt,
    PhotoEntity? previous,
  }) {
    final current = state.value;
    if (current == null) return;
    final index = current.photos.indexWhere((p) => p.id == photoId);
    if (index == -1 || current.photos[index].filmPick != pick) return;
    final settled =
        previous ??
        current.photos[index].copyWith(
          filmPickSetAt: setAt,
        );
    final photos = [...current.photos]..[index] = settled;
    state = AsyncData(current.copyWith(photos: photos));
  }

  /// Rolls back [applyPhotoDeleted] after a failed delete.
  void applyPhotoRestored(PhotoEntity photo, int index) {
    final current = state.value;
    if (current == null || current.photos.any((p) => p.id == photo.id)) {
      return;
    }
    final photos = [...current.photos]
      ..insert(index.clamp(0, current.photos.length), photo);
    state = AsyncData(current.copyWith(photos: photos));
  }
}

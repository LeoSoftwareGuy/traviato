import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/errors/presentation_failure_exception.dart';
import '../../../photo/domain/entities/photo_entity.dart';
import '../../../photo/presentation/providers/photo_providers.dart';
import '../../../trip/presentation/providers/trip_providers.dart';
import '../../domain/entities/day_note_entity.dart';
import '../providers/day_note_providers.dart';
import 'journal_state.dart';

part 'journal_controller.g.dart';

@riverpod
class JournalController extends _$JournalController {
  @override
  Future<JournalState> build(String tripId) async {
    final tripRepo = ref.watch(tripRepositoryProvider);
    final photoRepo = ref.watch(photoRepositoryProvider);
    final noteRepo = ref.watch(dayNoteRepositoryProvider);

    final tripResult = await tripRepo.getTripCard(tripId);
    final trip = tripResult.fold(
      (failure) => throw PresentationFailureException(failure),
      (t) => t,
    );

    final photosResult = await photoRepo.getPhotosForTrip(tripId);
    final photos = photosResult.fold(
      (failure) => throw PresentationFailureException(failure),
      (p) => p,
    );

    // All-trip notes, used only to gate wrap-up eligibility (#103) — kept
    // separate from notesByDay's per-day, lazily-fetched cache below.
    final notesResult = await noteRepo.getNotesForTrip(tripId);
    final notes = notesResult.fold(
      (failure) => throw PresentationFailureException(failure),
      (n) => n,
    );

    final initialDay = _initialDayDate(trip.startDate, trip.endDate);

    var notesByDay = const <DateTime, DayNoteEntity?>{};
    if (initialDay != null) {
      final noteResult = await noteRepo.getNote(
        tripId: tripId,
        dayDate: initialDay,
      );
      final note = noteResult.fold(
        (failure) => throw PresentationFailureException(failure),
        (n) => n,
      );
      notesByDay = {initialDay: note};
    }

    return JournalState(
      trip: trip,
      currentDayDate: initialDay,
      notesByDay: notesByDay,
      photos: photos,
      notes: notes,
    );
  }

  Future<void> selectDay(DateTime day) async {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(currentDayDate: () => day));

    if (current.notesByDay.containsKey(day)) return;
    final repo = ref.read(dayNoteRepositoryProvider);
    final result = await repo.getNote(tripId: current.trip.id, dayDate: day);
    final latest = state.value;
    if (latest == null) return;
    result.fold(
      // Leave the day uncached on failure so re-selecting it retries.
      (failure) {},
      (note) {
        final updated = Map<DateTime, DayNoteEntity?>.from(latest.notesByDay)
          ..[day] = note;
        state = AsyncData(latest.copyWith(notesByDay: updated));
      },
    );
  }

  /// Called by the upsert-note mutation after a successful save.
  void applyNoteUpserted(DateTime day, DayNoteEntity note) {
    final current = state.value;
    if (current == null) return;
    final updated = Map<DateTime, DayNoteEntity?>.from(current.notesByDay)
      ..[day] = note;
    // Keep the all-trip notes list (wrap-up eligibility, #103) in sync too —
    // replace an existing day's note or add a newly-created one.
    final notes = [
      for (final n in current.notes)
        if (!_isSameDate(n.dayDate, day)) n,
      note,
    ];
    state = AsyncData(current.copyWith(notesByDay: updated, notes: notes));
  }

  /// Called by the add-photo mutation after a successful upload.
  void applyPhotoAdded(PhotoEntity photo) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(photos: [...current.photos, photo]));
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

bool _isSameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

import 'package:fpdart/fpdart.dart';
import 'package:traviato/core/errors/failures.dart';
import 'package:traviato/features/journal/domain/entities/journal_note_entity.dart';
import 'package:traviato/features/journal/domain/repositories/journal_note_repository.dart';

class FakeJournalNoteRepository implements JournalNoteRepository {
  /// The day's note for [getNotesForDay] (a one-note day, or none).
  Either<Failure, JournalNoteEntity?>? getNoteResult;
  Either<Failure, List<JournalNoteEntity>>? notesForTripResult;

  /// The result of a save, create or update alike.
  Either<Failure, JournalNoteEntity>? upsertNoteResult;
  Either<Failure, Unit>? deleteNoteResult;
  var getNoteCallCount = 0;
  var getNotesForTripCallCount = 0;

  /// Saves, create or update alike.
  var upsertNoteCallCount = 0;
  var createNoteCallCount = 0;
  var updateNoteCallCount = 0;
  var deleteNoteCallCount = 0;
  String? lastDeletedNoteId;
  String? lastUpdatedNoteId;
  DateTime? lastGetNoteDay;
  DateTime? lastCreatedTakenAt;
  DateTime? lastCreatedDay;
  bool? lastCreatedDictated;
  String? lastCreatedPhotoId;
  bool? lastUpdatedDictated;
  String? lastUpsertedContent;

  @override
  Future<Either<Failure, List<JournalNoteEntity>>> getNotesForDay({
    required String tripId,
    required DateTime dayDate,
  }) async {
    getNoteCallCount++;
    lastGetNoteDay = dayDate;
    return (getNoteResult ?? const Right(null)).map(
      (note) => note == null ? const [] : [note],
    );
  }

  @override
  Future<Either<Failure, List<JournalNoteEntity>>> getNotesForTrip(
    String tripId,
  ) async {
    getNotesForTripCallCount++;
    return notesForTripResult ?? const Right([]);
  }

  @override
  Future<Either<Failure, JournalNoteEntity>> createNote({
    required String tripId,
    required DateTime dayDate,
    required DateTime takenAt,
    required String content,
    bool dictated = false,
    String? photoId,
  }) async {
    upsertNoteCallCount++;
    createNoteCallCount++;
    lastUpsertedContent = content;
    lastCreatedTakenAt = takenAt;
    lastCreatedDay = dayDate;
    lastCreatedDictated = dictated;
    lastCreatedPhotoId = photoId;
    return upsertNoteResult ??
        Right(
          buildJournalNoteEntity(
            id: 'created-$createNoteCallCount',
            tripId: tripId,
            dayDate: dayDate,
            content: content,
            createdAt: takenAt,
            dictated: dictated,
            photoId: photoId,
          ),
        );
  }

  @override
  Future<Either<Failure, JournalNoteEntity>> updateNote({
    required String noteId,
    required String content,
    required bool dictated,
  }) async {
    upsertNoteCallCount++;
    updateNoteCallCount++;
    lastUpsertedContent = content;
    lastUpdatedNoteId = noteId;
    lastUpdatedDictated = dictated;
    final stored = notesForTripResult
        ?.getOrElse((_) => const [])
        .where(
          (n) => n.id == noteId,
        );
    final base = stored == null || stored.isEmpty ? null : stored.first;
    return upsertNoteResult ??
        Right(
          buildJournalNoteEntity(
            id: noteId,
            tripId: base?.tripId ?? 't1',
            dayDate: base?.dayDate,
            createdAt: base?.takenAt,
            content: content,
            dictated: dictated,
          ),
        );
  }

  @override
  Future<Either<Failure, Unit>> deleteNote(String noteId) async {
    deleteNoteCallCount++;
    lastDeletedNoteId = noteId;
    return deleteNoteResult ?? const Right(unit);
  }
}

JournalNoteEntity buildJournalNoteEntity({
  String id = 'n1',
  String tripId = 't1',
  DateTime? dayDate,
  String content = 'Great day.',
  DateTime? createdAt,
  DateTime? editedAt,
  bool dictated = false,
  String? photoId,
  bool legacy = false,
}) {
  final takenAt = createdAt ?? DateTime(2026, 1, 1);
  return JournalNoteEntity(
    id: id,
    tripId: tripId,
    dayDate: dayDate ?? DateTime(2026, 8, 18),
    takenAt: takenAt,
    editedAt: editedAt ?? takenAt,
    content: content,
    dictated: dictated,
    photoId: photoId,
    legacy: legacy,
  );
}

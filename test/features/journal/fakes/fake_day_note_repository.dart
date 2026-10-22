import 'package:fpdart/fpdart.dart';
import 'package:traviato/core/errors/failures.dart';
import 'package:traviato/features/journal/domain/entities/day_note_entity.dart';
import 'package:traviato/features/journal/domain/repositories/day_note_repository.dart';

class FakeDayNoteRepository implements DayNoteRepository {
  Either<Failure, DayNoteEntity?>? getNoteResult;
  Either<Failure, List<DayNoteEntity>>? notesForTripResult;
  Either<Failure, DayNoteEntity>? upsertNoteResult;
  Either<Failure, Unit>? deleteNoteResult;
  var getNoteCallCount = 0;
  var getNotesForTripCallCount = 0;
  var upsertNoteCallCount = 0;
  var deleteNoteCallCount = 0;
  String? lastDeletedNoteId;
  DateTime? lastGetNoteDay;
  String? lastUpsertedContent;

  @override
  Future<Either<Failure, DayNoteEntity?>> getNote({
    required String tripId,
    required DateTime dayDate,
  }) async {
    getNoteCallCount++;
    lastGetNoteDay = dayDate;
    return getNoteResult ?? const Right(null);
  }

  @override
  Future<Either<Failure, List<DayNoteEntity>>> getNotesForTrip(
    String tripId,
  ) async {
    getNotesForTripCallCount++;
    return notesForTripResult ?? const Right([]);
  }

  @override
  Future<Either<Failure, DayNoteEntity>> upsertNote({
    required String tripId,
    required DateTime dayDate,
    required String content,
  }) async {
    upsertNoteCallCount++;
    lastUpsertedContent = content;
    return upsertNoteResult ??
        Right(
          buildDayNoteEntity(
            tripId: tripId,
            dayDate: dayDate,
            content: content,
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

DayNoteEntity buildDayNoteEntity({
  String id = 'n1',
  String tripId = 't1',
  DateTime? dayDate,
  String content = 'Great day.',
  DateTime? createdAt,
}) {
  final now = createdAt ?? DateTime(2026, 1, 1);
  return DayNoteEntity(
    id: id,
    tripId: tripId,
    dayDate: dayDate ?? DateTime(2026, 8, 18),
    content: content,
    createdAt: now,
    updatedAt: now,
  );
}

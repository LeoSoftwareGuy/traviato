import 'package:fpdart/fpdart.dart';
import 'package:traviato/core/errors/failures.dart';
import 'package:traviato/features/journal/domain/entities/day_note_entity.dart';
import 'package:traviato/features/journal/domain/repositories/day_note_repository.dart';

class FakeDayNoteRepository implements DayNoteRepository {
  Either<Failure, DayNoteEntity?>? getNoteResult;
  Either<Failure, DayNoteEntity>? upsertNoteResult;
  var getNoteCallCount = 0;
  var upsertNoteCallCount = 0;
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
}

DayNoteEntity buildDayNoteEntity({
  String id = 'n1',
  String tripId = 't1',
  DateTime? dayDate,
  String content = 'Great day.',
}) {
  final now = DateTime(2026, 1, 1);
  return DayNoteEntity(
    id: id,
    tripId: tripId,
    dayDate: dayDate ?? DateTime(2026, 8, 18),
    content: content,
    createdAt: now,
    updatedAt: now,
  );
}

import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/day_note_entity.dart';

abstract interface class DayNoteRepository {
  /// Null when the day has no note yet.
  Future<Either<Failure, DayNoteEntity?>> getNote({
    required String tripId,
    required DateTime dayDate,
  });

  /// Every note across the trip — used for the manage sheet's delete
  /// consequence count ("N days of notes").
  Future<Either<Failure, List<DayNoteEntity>>> getNotesForTrip(String tripId);

  Future<Either<Failure, DayNoteEntity>> upsertNote({
    required String tripId,
    required DateTime dayDate,
    required String content,
  });
}

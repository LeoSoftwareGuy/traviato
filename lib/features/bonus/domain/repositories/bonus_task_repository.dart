import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/bonus_task_assignment_entity.dart';
import '../entities/bonus_task_template_entity.dart';

abstract interface class BonusTaskRepository {
  /// The full seeded template pool — select-only, cheap, effectively static.
  Future<Either<Failure, List<BonusTaskTemplateEntity>>> getTemplates();

  /// Every assignment ever made for [tripId] — needed for the 10-day
  /// no-repeat window, the streak-saver lookback, and the COMPLETED history.
  Future<Either<Failure, List<BonusTaskAssignmentEntity>>>
  getAssignmentsForTrip(
    String tripId,
  );

  /// Idempotent insert — the unique `(trip_id, template_id, day_date)`
  /// constraint absorbs a race (two opens on the same day drawing at once).
  /// Returns the canonical assignment rows for [dayDate] after inserting
  /// (pre-existing rows included), so a caller never needs to guess which
  /// of [templateIds] actually landed.
  Future<Either<Failure, List<BonusTaskAssignmentEntity>>> assignForDay({
    required String tripId,
    required DateTime dayDate,
    required List<int> templateIds,
  });

  /// Marks an assignment complete with the proof photo, and awards its
  /// stars + runs achievement checks server-side.
  Future<Either<Failure, BonusTaskAssignmentEntity>> completeAssignment({
    required String id,
    required String tripId,
    required String photoId,
  });
}

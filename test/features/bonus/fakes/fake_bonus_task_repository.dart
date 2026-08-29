import 'package:fpdart/fpdart.dart';
import 'package:traviato/core/errors/failures.dart';
import 'package:traviato/features/bonus/domain/entities/bonus_task_assignment_entity.dart';
import 'package:traviato/features/bonus/domain/entities/bonus_task_template_entity.dart';
import 'package:traviato/features/bonus/domain/repositories/bonus_task_repository.dart';

/// Test double for [BonusTaskRepository]. `assignForDay` fabricates a
/// plausible assignment row per template id unless [assignForDayResult] is
/// set, so use-case tests can assert on what it was called with.
class FakeBonusTaskRepository implements BonusTaskRepository {
  List<BonusTaskTemplateEntity> templates = const [];
  List<BonusTaskAssignmentEntity> assignments = const [];

  Either<Failure, List<BonusTaskTemplateEntity>>? templatesResult;
  Either<Failure, List<BonusTaskAssignmentEntity>>? assignmentsResult;
  Either<Failure, List<BonusTaskAssignmentEntity>>? assignForDayResult;
  Either<Failure, BonusTaskAssignmentEntity>? completeResult;

  var getTemplatesCallCount = 0;
  var getAssignmentsCallCount = 0;
  var assignForDayCallCount = 0;
  var completeCallCount = 0;
  final assignForDayCalls = <List<int>>[];

  @override
  Future<Either<Failure, List<BonusTaskTemplateEntity>>> getTemplates() async {
    getTemplatesCallCount++;
    return templatesResult ?? Right(templates);
  }

  @override
  Future<Either<Failure, List<BonusTaskAssignmentEntity>>>
  getAssignmentsForTrip(String tripId) async {
    getAssignmentsCallCount++;
    return assignmentsResult ?? Right(assignments);
  }

  @override
  Future<Either<Failure, List<BonusTaskAssignmentEntity>>> assignForDay({
    required String tripId,
    required DateTime dayDate,
    required List<int> templateIds,
  }) async {
    assignForDayCallCount++;
    assignForDayCalls.add(templateIds);
    if (assignForDayResult != null) return assignForDayResult!;
    return Right([
      for (final id in templateIds)
        BonusTaskAssignmentEntity(
          id: 'gen-$id-${dayDate.toIso8601String()}',
          tripId: tripId,
          templateId: id,
          dayDate: dayDate,
          createdAt: DateTime(2026, 1, 1),
        ),
    ]);
  }

  @override
  Future<Either<Failure, BonusTaskAssignmentEntity>> completeAssignment({
    required String id,
    required String tripId,
    required String photoId,
  }) async {
    completeCallCount++;
    return completeResult ??
        Right(
          BonusTaskAssignmentEntity(
            id: id,
            tripId: tripId,
            templateId: 1,
            dayDate: DateTime(2026, 1, 1),
            completedAt: DateTime(2026, 1, 2),
            photoId: photoId,
            createdAt: DateTime(2026, 1, 1),
          ),
        );
  }
}

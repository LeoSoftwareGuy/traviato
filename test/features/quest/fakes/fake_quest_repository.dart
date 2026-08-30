import 'package:fpdart/fpdart.dart';
import 'package:traviato/core/errors/failures.dart';
import 'package:traviato/features/quest/domain/entities/quest_entity.dart';
import 'package:traviato/features/quest/domain/repositories/quest_repository.dart';

/// Test double for [QuestRepository]. Configure the `*Result` fields to
/// force a failure; otherwise each method fabricates a plausible success.
class FakeQuestRepository implements QuestRepository {
  Either<Failure, List<QuestEntity>>? questsResult;
  Either<Failure, QuestEntity>? addQuestResult;
  Either<Failure, QuestEntity>? updateQuestResult;
  Either<Failure, void>? deleteQuestResult;
  Either<Failure, QuestEntity>? toggleResult;

  var getQuestsCallCount = 0;
  var addQuestCallCount = 0;
  var updateQuestCallCount = 0;
  var deleteQuestCallCount = 0;
  var toggleCallCount = 0;
  int? lastAddPosition;

  @override
  Future<Either<Failure, List<QuestEntity>>> getQuestsForTrip(
    String tripId,
  ) async {
    getQuestsCallCount++;
    return questsResult ?? const Right([]);
  }

  @override
  Future<Either<Failure, QuestEntity>> addQuest({
    required String tripId,
    required DateTime dayDate,
    required String title,
    Duration? time,
    String? placeText,
    required int position,
  }) async {
    addQuestCallCount++;
    lastAddPosition = position;
    return addQuestResult ??
        Right(
          buildQuestEntity(
            tripId: tripId,
            dayDate: dayDate,
            title: title,
            time: time,
            placeText: placeText,
            position: position,
          ),
        );
  }

  @override
  Future<Either<Failure, QuestEntity>> updateQuest({
    required String id,
    required String title,
    Duration? time,
    String? placeText,
  }) async {
    updateQuestCallCount++;
    return updateQuestResult ??
        Right(
          buildQuestEntity(
            id: id,
            title: title,
            time: time,
            placeText: placeText,
          ),
        );
  }

  @override
  Future<Either<Failure, void>> deleteQuest(String id) async {
    deleteQuestCallCount++;
    return deleteQuestResult ?? const Right(null);
  }

  @override
  Future<Either<Failure, QuestEntity>> toggleCompleted({
    required String id,
    required String tripId,
    required bool completed,
  }) async {
    toggleCallCount++;
    return toggleResult ??
        Right(
          buildQuestEntity(
            id: id,
            completedAt: completed ? DateTime(2026, 1, 2) : null,
          ),
        );
  }
}

QuestEntity buildQuestEntity({
  String id = 'q1',
  String tripId = 't1',
  DateTime? dayDate,
  Duration? time,
  String title = 'Pack the car',
  String? placeText,
  int position = 0,
  DateTime? completedAt,
}) {
  return QuestEntity(
    id: id,
    tripId: tripId,
    dayDate: dayDate ?? DateTime(2026, 8, 18),
    time: time,
    title: title,
    placeText: placeText,
    position: position,
    completedAt: completedAt,
    createdAt: DateTime(2026, 1, 1),
  );
}

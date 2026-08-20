import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/quest_entity.dart';

abstract interface class QuestRepository {
  Future<Either<Failure, List<QuestEntity>>> getQuestsForTrip(String tripId);

  Future<Either<Failure, QuestEntity>> addQuest({
    required String tripId,
    required DateTime dayDate,
    required String title,
    Duration? time,
    String? placeText,
    required int position,
  });

  Future<Either<Failure, QuestEntity>> updateQuest({
    required String id,
    required String title,
    Duration? time,
    String? placeText,
  });

  Future<Either<Failure, void>> deleteQuest(String id);

  Future<Either<Failure, QuestEntity>> toggleCompleted({
    required String id,
    required bool completed,
  });
}

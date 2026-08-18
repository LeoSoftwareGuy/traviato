import '../models/quest_model.dart';

abstract interface class QuestRemoteDataSource {
  Future<List<QuestModel>> getQuestsForTrip(String tripId);

  Future<QuestModel> addQuest({
    required String id,
    required String tripId,
    required DateTime dayDate,
    required String title,
    Duration? time,
    String? placeText,
    required int position,
  });

  Future<QuestModel> updateQuest({
    required String id,
    required String title,
    Duration? time,
    String? placeText,
  });

  Future<void> deleteQuest(String id);

  Future<QuestModel> toggleCompleted({
    required String id,
    required bool completed,
  });
}

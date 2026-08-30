import '../models/bonus_task_assignment_model.dart';
import '../models/bonus_task_template_model.dart';

abstract interface class BonusTaskRemoteDataSource {
  Future<List<BonusTaskTemplateModel>> getTemplates();

  Future<List<BonusTaskAssignmentModel>> getAssignmentsForTrip(String tripId);

  /// [assignments] pairs a client-generated row id with the template it
  /// assigns — id generation happens in the repository (see quest/photo
  /// precedent), not here.
  Future<List<BonusTaskAssignmentModel>> assignForDay({
    required String tripId,
    required DateTime dayDate,
    required List<(String id, int templateId)> assignments,
  });

  Future<BonusTaskAssignmentModel> completeAssignment({
    required String id,
    required String tripId,
    required String photoId,
  });
}

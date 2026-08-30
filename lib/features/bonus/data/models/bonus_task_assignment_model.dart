import '../../domain/entities/bonus_task_assignment_entity.dart';

class BonusTaskAssignmentModel extends BonusTaskAssignmentEntity {
  const BonusTaskAssignmentModel({
    required super.id,
    required super.tripId,
    required super.templateId,
    required super.dayDate,
    super.completedAt,
    super.photoId,
    required super.createdAt,
  });

  factory BonusTaskAssignmentModel.fromJson(Map<String, dynamic> json) =>
      BonusTaskAssignmentModel(
        id: json['id'] as String,
        tripId: json['trip_id'] as String,
        templateId: (json['template_id'] as num).toInt(),
        dayDate: DateTime.parse(json['day_date'] as String),
        completedAt: json['completed_at'] == null
            ? null
            : DateTime.parse(json['completed_at'] as String),
        photoId: json['photo_id'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

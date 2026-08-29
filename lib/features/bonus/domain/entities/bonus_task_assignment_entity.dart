import 'package:equatable/equatable.dart';

/// A drawn task for one trip/day, from `bonus_task_assignments`. Expiry is
/// derived, never stored: an assignment whose [dayDate] is in the past and
/// has no [completedAt] simply stops being rendered (functionality.md §12) —
/// there is no "expired" state to model here.
class BonusTaskAssignmentEntity extends Equatable {
  const BonusTaskAssignmentEntity({
    required this.id,
    required this.tripId,
    required this.templateId,
    required this.dayDate,
    this.completedAt,
    this.photoId,
    required this.createdAt,
  });

  final String id;
  final String tripId;
  final int templateId;
  final DateTime dayDate;
  final DateTime? completedAt;
  final String? photoId;
  final DateTime createdAt;

  bool get isCompleted => completedAt != null;

  BonusTaskAssignmentEntity copyWith({
    DateTime? Function()? completedAt,
    String? Function()? photoId,
  }) => BonusTaskAssignmentEntity(
    id: id,
    tripId: tripId,
    templateId: templateId,
    dayDate: dayDate,
    completedAt: completedAt != null ? completedAt() : this.completedAt,
    photoId: photoId != null ? photoId() : this.photoId,
    createdAt: createdAt,
  );

  @override
  List<Object?> get props => [
    id,
    tripId,
    templateId,
    dayDate,
    completedAt,
    photoId,
    createdAt,
  ];
}

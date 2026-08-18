import 'package:equatable/equatable.dart';

/// A day-plan item for a memory. [time] is the offset from midnight (no
/// Flutter `TimeOfDay` in the domain layer — see guidelines doc 05).
class QuestEntity extends Equatable {
  const QuestEntity({
    required this.id,
    required this.tripId,
    required this.dayDate,
    this.time,
    required this.title,
    this.placeText,
    required this.position,
    this.completedAt,
    required this.createdAt,
  });

  final String id;
  final String tripId;
  final DateTime dayDate;
  final Duration? time;
  final String title;
  final String? placeText;
  final int position;
  final DateTime? completedAt;
  final DateTime createdAt;

  bool get isCompleted => completedAt != null;

  @override
  List<Object?> get props => [
    id,
    tripId,
    dayDate,
    time,
    title,
    placeText,
    position,
    completedAt,
    createdAt,
  ];
}

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

  /// A copy re-dated to [newDayDate] — used when a manage-sheet date shift
  /// moves every quest on the trip by the same delta.
  QuestEntity withDayDate(DateTime newDayDate) => QuestEntity(
    id: id,
    tripId: tripId,
    dayDate: newDayDate,
    time: time,
    title: title,
    placeText: placeText,
    position: position,
    completedAt: completedAt,
    createdAt: createdAt,
  );

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

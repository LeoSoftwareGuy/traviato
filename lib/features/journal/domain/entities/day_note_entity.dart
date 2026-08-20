import 'package:equatable/equatable.dart';

/// The single note for one day of a memory (`unique (trip_id, day_date)`) —
/// edited in place, not appended.
class DayNoteEntity extends Equatable {
  const DayNoteEntity({
    required this.id,
    required this.tripId,
    required this.dayDate,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String tripId;
  final DateTime dayDate;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [
    id,
    tripId,
    dayDate,
    content,
    createdAt,
    updatedAt,
  ];
}

import 'package:equatable/equatable.dart';

import '../../../photo/domain/entities/photo_entity.dart';
import '../../../trip/domain/entities/trip_card_entity.dart';
import '../../domain/entities/day_note_entity.dart';

class JournalState extends Equatable {
  const JournalState({
    required this.trip,
    this.currentDayDate,
    this.notesByDay = const {},
    this.photos = const [],
  });

  final TripCardEntity trip;
  final DateTime? currentDayDate;

  /// Cache of fetched notes, keyed by day. A day present with a `null`
  /// value means "fetched, no note yet" — distinct from "not fetched".
  final Map<DateTime, DayNoteEntity?> notesByDay;
  final List<PhotoEntity> photos;

  bool get hasDateRange => trip.startDate != null && trip.endDate != null;

  int get totalDays =>
      hasDateRange ? trip.endDate!.difference(trip.startDate!).inDays + 1 : 0;

  int? get currentDayNumber {
    final day = currentDayDate;
    if (!hasDateRange || day == null) return null;
    return day.difference(trip.startDate!).inDays + 1;
  }

  List<DateTime> get dayDates {
    if (!hasDateRange) return const [];
    return [
      for (var i = 0; i < totalDays; i++)
        trip.startDate!.add(Duration(days: i)),
    ];
  }

  bool get isCurrentDayNoteCached =>
      currentDayDate != null && notesByDay.containsKey(currentDayDate);

  DayNoteEntity? get currentNote =>
      currentDayDate == null ? null : notesByDay[currentDayDate];

  List<PhotoEntity> photosForDay(DateTime day) => photos
      .where((p) => p.dayDate != null && _isSameDate(p.dayDate!, day))
      .toList();

  List<PhotoEntity> get photosForCurrentDay {
    final day = currentDayDate;
    return day == null ? const [] : photosForDay(day);
  }

  PhotoEntity? thumbnailForDay(DateTime day) {
    final forDay = photosForDay(day);
    return forDay.isEmpty ? null : forDay.first;
  }

  JournalState copyWith({
    DateTime? Function()? currentDayDate,
    Map<DateTime, DayNoteEntity?>? notesByDay,
    List<PhotoEntity>? photos,
  }) => JournalState(
    trip: trip,
    currentDayDate: currentDayDate != null
        ? currentDayDate()
        : this.currentDayDate,
    notesByDay: notesByDay ?? this.notesByDay,
    photos: photos ?? this.photos,
  );

  @override
  List<Object?> get props => [trip, currentDayDate, notesByDay, photos];
}

bool _isSameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

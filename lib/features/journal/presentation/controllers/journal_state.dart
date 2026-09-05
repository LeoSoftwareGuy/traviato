import 'package:equatable/equatable.dart';

import '../../../photo/domain/entities/photo_entity.dart';
import '../../../trip/domain/entities/trip_card_entity.dart';
import '../../domain/entities/day_note_entity.dart';

/// Gate on the Journal's "View wrap-up ▸" CTA (#103): wrap-up only makes
/// sense once the trip has ended, and only once there's enough content to
/// be worth an Anthropic screenplay-generation call.
enum WrapUpAvailability {
  /// Trip hasn't ended yet (or has no end date) — button isn't shown at all.
  hidden,

  /// Trip has ended but content is under the minimum — button shows
  /// disabled with an explanation.
  locked,

  /// Trip has ended and meets the content minimum — button is tappable.
  unlocked,
}

class JournalState extends Equatable {
  const JournalState({
    required this.trip,
    this.currentDayDate,
    this.notesByDay = const {},
    this.photos = const [],
    this.notes = const [],
  });

  /// Minimum content required before wrap-up generation is offered — see
  /// [wrapUpAvailability]. Kept low: the goal is only to avoid an Anthropic
  /// call on a genuinely empty trip, not to gate the feature behind a high
  /// bar (#103).
  static const wrapUpMinPhotos = 3;
  static const wrapUpMinNoteDays = 2;

  final TripCardEntity trip;
  final DateTime? currentDayDate;

  /// Cache of fetched notes, keyed by day. A day present with a `null`
  /// value means "fetched, no note yet" — distinct from "not fetched".
  final Map<DateTime, DayNoteEntity?> notesByDay;
  final List<PhotoEntity> photos;

  /// Every day-note across the whole trip (one row per day, per the data
  /// model's unique constraint) — used only to gate wrap-up eligibility,
  /// distinct from [notesByDay]'s per-day cache used for editing.
  final List<DayNoteEntity> notes;

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

  bool get _hasTripEnded {
    if (!hasDateRange) return false;
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    return !todayDate.isBefore(trip.endDate!);
  }

  /// The generated wrap-up always covers the whole trip regardless of which
  /// day tab is open (`generate_wrap_up` gathers by trip, not by day) — so
  /// the CTA is scoped to the last day only, to avoid implying it covers
  /// just "up to this day" (#107).
  bool get _isViewingLastDay {
    final day = currentDayDate;
    final dates = dayDates;
    return day != null && dates.isNotEmpty && _isSameDate(day, dates.last);
  }

  WrapUpAvailability get wrapUpAvailability {
    if (!_hasTripEnded || !_isViewingLastDay) return WrapUpAvailability.hidden;
    final hasEnoughPhotos = photos.length >= wrapUpMinPhotos;
    final hasEnoughNotes = notes.length >= wrapUpMinNoteDays;
    return hasEnoughPhotos && hasEnoughNotes
        ? WrapUpAvailability.unlocked
        : WrapUpAvailability.locked;
  }

  /// Helper copy for the [WrapUpAvailability.locked] state — `null` in any
  /// other state.
  String? get wrapUpLockedReason {
    if (wrapUpAvailability != WrapUpAvailability.locked) return null;
    final missingPhotos = wrapUpMinPhotos - photos.length;
    final missingNotes = wrapUpMinNoteDays - notes.length;
    final parts = [
      if (missingPhotos > 0) '$missingPhotos more photo${_s(missingPhotos)}',
      if (missingNotes > 0) '$missingNotes more note${_s(missingNotes)}',
    ];
    return 'Add ${parts.join(' and ')} to unlock your wrap-up';
  }

  JournalState copyWith({
    DateTime? Function()? currentDayDate,
    Map<DateTime, DayNoteEntity?>? notesByDay,
    List<PhotoEntity>? photos,
    List<DayNoteEntity>? notes,
  }) => JournalState(
    trip: trip,
    currentDayDate: currentDayDate != null
        ? currentDayDate()
        : this.currentDayDate,
    notesByDay: notesByDay ?? this.notesByDay,
    photos: photos ?? this.photos,
    notes: notes ?? this.notes,
  );

  @override
  List<Object?> get props => [
    trip,
    currentDayDate,
    notesByDay,
    photos,
    notes,
  ];
}

String _s(int count) => count == 1 ? '' : 's';

bool _isSameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

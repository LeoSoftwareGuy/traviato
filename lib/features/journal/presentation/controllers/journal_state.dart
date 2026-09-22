import 'package:equatable/equatable.dart';

import '../../../photo/domain/entities/photo_entity.dart';
import '../../../quest/domain/entities/quest_entity.dart';
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
    this.quests = const [],
  });

  /// Minimum content required before wrap-up generation is offered — see
  /// [wrapReady]/[wrapUpAvailability].
  /// docs/design/M6_MONETIZATION_SPEC.md §3's `wrapReady` formula (#140).
  static const wrapUpMinPhotos = 5;
  static const wrapUpMinNotes = 1;

  final TripCardEntity trip;
  final DateTime? currentDayDate;

  /// Cache of fetched notes, keyed by day. A day present with a `null`
  /// value means "fetched, no note yet" — distinct from "not fetched".
  final Map<DateTime, DayNoteEntity?> notesByDay;
  final List<PhotoEntity> photos;

  /// Every day-note across the whole trip (one row per day, per the data
  /// model's unique constraint) — used only to gate wrap-up eligibility and
  /// empty-day detection, distinct from [notesByDay]'s per-day cache used
  /// for editing.
  final List<DayNoteEntity> notes;

  /// Every quest across the whole trip — fetched only for the empty-day
  /// nudge's "N quests done" subtitle (#140); the "To Do" sheet fetches its
  /// own day-scoped copy lazily and doesn't read this.
  final List<QuestEntity> quests;

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

  bool _hasNoteForDay(DateTime day) =>
      notes.any((n) => _isSameDate(n.dayDate, day));

  /// A day with zero photos AND zero notes — the empty-day nudge's trigger
  /// (#140/M6-4b). Both lists are already loaded for the whole trip, so this
  /// works for every day in the strip, not just the one currently open.
  bool isDayEmpty(DateTime day) =>
      photosForDay(day).isEmpty && !_hasNoteForDay(day);

  int completedQuestCountForDay(DateTime day) =>
      quests.where((q) => _isSameDate(q.dayDate, day) && q.isCompleted).length;

  /// A day is locked once the trip hasn't gotten there yet — past days and
  /// today stay open, but a future day can't be opened ahead of time (#118).
  bool isDayLocked(DateTime day) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final dayDate = DateTime(day.year, day.month, day.day);
    return dayDate.isAfter(todayDate);
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

  /// Single source of truth for content sufficiency
  /// (docs/design/M6_MONETIZATION_SPEC.md §3, #140) — identical for free and
  /// Pro users. Paying never bypasses this: deliberately no `isPro` check
  /// here, unlike the M6-3 plan-limit triggers.
  bool get wrapReady =>
      photos.length >= wrapUpMinPhotos && notes.length >= wrapUpMinNotes;

  WrapUpAvailability get wrapUpAvailability {
    if (!_hasTripEnded || !_isViewingLastDay) return WrapUpAvailability.hidden;
    return wrapReady ? WrapUpAvailability.unlocked : WrapUpAvailability.locked;
  }

  bool get wrapUpPhotosMet => photos.length >= wrapUpMinPhotos;
  bool get wrapUpNotesMet => notes.length >= wrapUpMinNotes;

  /// Clamped so the checklist counter never shows a count above the
  /// requirement (spec §6: "never show ... a count above the requirement").
  int get wrapUpPhotosHave => photos.length.clamp(0, wrapUpMinPhotos);
  int get wrapUpNotesHave => notes.length.clamp(0, wrapUpMinNotes);

  /// The explainer card's lead-line `{ask}` (spec §6's three variants) —
  /// `null` unless the wrap-up is actually locked.
  String? get wrapUpAskLine {
    if (wrapUpAvailability != WrapUpAvailability.locked) return null;
    final missingPhotos = wrapUpMinPhotos - photos.length;
    final missingNotes = wrapUpMinNotes - notes.length;
    if (missingPhotos > 0 && missingNotes > 0) {
      return 'Add $missingPhotos more photo${_s(missingPhotos)} and one '
          'note to unlock it.';
    }
    if (missingPhotos > 0) {
      return 'Add $missingPhotos more photo${_s(missingPhotos)} to unlock '
          'it.';
    }
    return 'Write one note to unlock it.';
  }

  JournalState copyWith({
    DateTime? Function()? currentDayDate,
    Map<DateTime, DayNoteEntity?>? notesByDay,
    List<PhotoEntity>? photos,
    List<DayNoteEntity>? notes,
    List<QuestEntity>? quests,
  }) => JournalState(
    trip: trip,
    currentDayDate: currentDayDate != null
        ? currentDayDate()
        : this.currentDayDate,
    notesByDay: notesByDay ?? this.notesByDay,
    photos: photos ?? this.photos,
    notes: notes ?? this.notes,
    quests: quests ?? this.quests,
  );

  @override
  List<Object?> get props => [
    trip,
    currentDayDate,
    notesByDay,
    photos,
    notes,
    quests,
  ];
}

String _s(int count) => count == 1 ? '' : 's';

bool _isSameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

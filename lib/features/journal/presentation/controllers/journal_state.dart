import 'package:equatable/equatable.dart';

import '../../../photo/domain/entities/photo_entity.dart';
import '../../../photo/domain/photo_order.dart';
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

  /// Every quest across the whole trip — fetched for the empty-day nudge's
  /// "N quests done" subtitle (#140) and [showsToDo]; the "To Do" sheet
  /// fetches its own day-scoped copy lazily and doesn't read this.
  final List<QuestEntity> quests;

  /// "To Do" is hidden for a memory logged after its trip ended (#164) —
  /// it never had a planning phase. If it already has quests (added before
  /// that rule existed) they stay reachable: the sheet has no add row, so
  /// it's read-only either way.
  bool get showsToDo => !trip.isPastCreated || quests.isNotEmpty;

  bool get hasDateRange => trip.startDate != null && trip.endDate != null;

  int get totalDays =>
      hasDateRange ? trip.endDate!.difference(trip.startDate!).inDays + 1 : 0;

  /// Start and end on the same date — the "Day N" framing is dropped (#186).
  bool get isSingleDay => totalDays == 1;

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

  /// The day's photos as they happened, oldest first (#291) — the order the
  /// strip, the day-tab thumbnail and the viewer all share.
  List<PhotoEntity> photosForDay(DateTime day) =>
      photos
          .where((p) => p.dayDate != null && _isSameDate(p.dayDate!, day))
          .toList()
        ..sort(comparePhotosByTime);

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

  /// What's still missing before the wrap-up unlocks (spec §6's three
  /// variants) — `null` unless it's actually locked. The sentence itself is
  /// built in the UI language by `wrapUpAskLine` (#220).
  ({int missingPhotos, bool needsNote})? get wrapUpMissing {
    if (wrapUpAvailability != WrapUpAvailability.locked) return null;
    final missingPhotos = wrapUpMinPhotos - photos.length;
    return (
      missingPhotos: missingPhotos > 0 ? missingPhotos : 0,
      needsNote: notes.length < wrapUpMinNotes,
    );
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

bool _isSameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

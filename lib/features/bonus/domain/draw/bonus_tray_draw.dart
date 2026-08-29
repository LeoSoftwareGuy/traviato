import 'dart:convert';

import '../entities/bonus_task_assignment_entity.dart';
import '../entities/bonus_task_template_entity.dart';

/// The no-repeat lookback window (functionality.md §12).
const noRepeatWindowDays = 10;

/// Pure daily-tray draw logic — no repository, no I/O, no `DateTime.now()`.
/// Every input (trip dates, today's date, the template pool, the trip's
/// assignment history) is passed in explicitly, which is what makes this
/// deterministic and trivially unit-testable (issue #64 AC).
abstract class BonusTrayDraw {
  const BonusTrayDraw._();

  /// 1-based day index — day 1 is the trip's start date.
  static int dayIndexFor({
    required DateTime tripStartDate,
    required DateTime dayDate,
  }) => _dateOnly(dayDate).difference(_dateOnly(tripStartDate)).inDays + 1;

  /// The templates a fresh day's tray should be assigned: on day one, one
  /// `starter` plus two `regular`; other days, two `regular`; days 7/14/21
  /// additionally get one `milestone`. Every pick excludes templates used on
  /// this trip within the last [noRepeatWindowDays] days and is ranked by a
  /// stable hash of `tripId + dayDate + template code`, so the same inputs
  /// always produce the same tray (reopening the app never reshuffles it).
  static List<BonusTaskTemplateEntity> drawDaily({
    required String tripId,
    required DateTime dayDate,
    required DateTime tripStartDate,
    DateTime? tripEndDate,
    required List<BonusTaskTemplateEntity> templates,
    required List<BonusTaskAssignmentEntity> existingAssignments,
  }) {
    final day = _dateOnly(dayDate);
    final dayIndex = dayIndexFor(tripStartDate: tripStartDate, dayDate: day);
    final isLastDay = tripEndDate != null && _dateOnly(tripEndDate) == day;
    final excluded = _recentlyAssignedTemplateIds(
      tripId: tripId,
      dayDate: day,
      assignments: existingAssignments,
    );

    final picks = <BonusTaskTemplateEntity>[];

    if (dayIndex == 1) {
      final starters = templates
          .where((t) => t.kind == BonusTaskKind.starter)
          .where((t) => !excluded.contains(t.id))
          .toList();
      final starter = _rank(starters, '$tripId|$day|starter').firstOrNull;
      if (starter != null) picks.add(starter);
    }

    final regularEligible = templates
        .where((t) => t.kind == BonusTaskKind.regular)
        .where(
          (t) => _isPhaseEligible(
            phase: t.phase,
            dayIndex: dayIndex,
            isLastDay: isLastDay,
          ),
        )
        .where((t) => !excluded.contains(t.id))
        .toList();
    picks.addAll(_rank(regularEligible, '$tripId|$day|regular').take(2));

    if (const [7, 14, 21].contains(dayIndex)) {
      final milestones = templates
          .where((t) => t.kind == BonusTaskKind.milestone)
          .where((t) => !excluded.contains(t.id))
          .toList();
      final milestone = _rank(milestones, '$tripId|$day|milestone').firstOrNull;
      if (milestone != null) picks.add(milestone);
    }

    return picks;
  }

  /// The single opt-in stretch offer shown once both dailies are done. Never
  /// auto-inserted — the caller only persists this when the user accepts it.
  static BonusTaskTemplateEntity? pickStretchTemplate({
    required String tripId,
    required DateTime dayDate,
    required List<BonusTaskTemplateEntity> templates,
    required List<BonusTaskAssignmentEntity> existingAssignments,
  }) {
    final day = _dateOnly(dayDate);
    final excluded = _recentlyAssignedTemplateIds(
      tripId: tripId,
      dayDate: day,
      assignments: existingAssignments,
    );
    final eligible = templates
        .where((t) => t.kind == BonusTaskKind.stretch)
        .where((t) => !excluded.contains(t.id))
        .toList();
    return _rank(eligible, '$tripId|$day|stretch').firstOrNull;
  }

  /// True when neither of the 2 days before [today] has any recorded
  /// activity — the streak-saver re-engagement trigger.
  static bool isStreakSaverDue({
    required DateTime today,
    required Set<DateTime> activityDates,
  }) {
    final day = _dateOnly(today);
    final yesterday = day.subtract(const Duration(days: 1));
    final dayBefore = day.subtract(const Duration(days: 2));
    final normalized = activityDates.map(_dateOnly).toSet();
    return !normalized.contains(yesterday) && !normalized.contains(dayBefore);
  }

  static Set<int> _recentlyAssignedTemplateIds({
    required String tripId,
    required DateTime dayDate,
    required List<BonusTaskAssignmentEntity> assignments,
  }) {
    return {
      for (final a in assignments)
        if (a.tripId == tripId)
          if (() {
            final daysAgo = dayDate.difference(_dateOnly(a.dayDate)).inDays;
            return daysAgo >= 1 && daysAgo <= noRepeatWindowDays;
          }())
            a.templateId,
    };
  }

  static bool _isPhaseEligible({
    required BonusTaskPhase phase,
    required int dayIndex,
    required bool isLastDay,
  }) {
    switch (phase) {
      case BonusTaskPhase.arrival:
        return dayIndex == 1;
      case BonusTaskPhase.departure:
        return isLastDay;
      case BonusTaskPhase.middle:
        return dayIndex != 1;
      case BonusTaskPhase.anytime:
        return true;
    }
  }

  /// Ranks [pool] by a stable hash of `seed + template code`, ascending —
  /// deterministic and evenly distributed without relying on Dart's
  /// [Object.hashCode] (not a persistence-safe contract across versions).
  static List<BonusTaskTemplateEntity> _rank(
    List<BonusTaskTemplateEntity> pool,
    String seed,
  ) {
    final ranked = [...pool]
      ..sort(
        (a, b) => _stableHash(
          '$seed|${a.code}',
        ).compareTo(_stableHash('$seed|${b.code}')),
      );
    return ranked;
  }

  /// djb2 over the UTF-8 bytes of [input].
  static int _stableHash(String input) {
    var hash = 5381;
    for (final byte in utf8.encode(input)) {
      hash = (hash * 33 + byte) & 0x7fffffff;
    }
    return hash;
  }
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

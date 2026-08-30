import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/bonus/domain/draw/bonus_tray_draw.dart';
import 'package:traviato/features/bonus/domain/entities/bonus_task_assignment_entity.dart';
import 'package:traviato/features/bonus/domain/entities/bonus_task_template_entity.dart';

BonusTaskTemplateEntity _template({
  required int id,
  required String code,
  BonusTaskPhase phase = BonusTaskPhase.anytime,
  BonusTaskKind kind = BonusTaskKind.regular,
  int points = 1,
}) => BonusTaskTemplateEntity(
  id: id,
  code: code,
  title: code,
  points: points,
  phase: phase,
  kind: kind,
);

BonusTaskAssignmentEntity _assignment({
  required String id,
  String tripId = 't1',
  required int templateId,
  required DateTime dayDate,
  DateTime? completedAt,
}) => BonusTaskAssignmentEntity(
  id: id,
  tripId: tripId,
  templateId: templateId,
  dayDate: dayDate,
  completedAt: completedAt,
  createdAt: DateTime(2026, 1, 1),
);

/// A pool with plenty of anytime/middle regular templates plus one of each
/// special kind — enough variety to exercise every rule without collisions.
List<BonusTaskTemplateEntity> _pool() => [
  for (var i = 1; i <= 10; i++) _template(id: i, code: 'anytime_$i'),
  for (var i = 11; i <= 15; i++)
    _template(id: i, code: 'middle_$i', phase: BonusTaskPhase.middle),
  _template(id: 20, code: 'arrival_1', phase: BonusTaskPhase.arrival),
  _template(id: 21, code: 'arrival_2', phase: BonusTaskPhase.arrival),
  _template(id: 30, code: 'departure_1', phase: BonusTaskPhase.departure),
  _template(id: 31, code: 'departure_2', phase: BonusTaskPhase.departure),
  _template(id: 40, code: 'starter_1', kind: BonusTaskKind.starter),
  _template(id: 50, code: 'stretch_1', kind: BonusTaskKind.stretch, points: 3),
  _template(id: 51, code: 'stretch_2', kind: BonusTaskKind.stretch, points: 3),
  _template(
    id: 60,
    code: 'milestone_1',
    kind: BonusTaskKind.milestone,
    points: 5,
  ),
  _template(
    id: 61,
    code: 'milestone_2',
    kind: BonusTaskKind.milestone,
    points: 5,
  ),
  _template(
    id: 70,
    code: 'streak_saver_1',
    kind: BonusTaskKind.streakSaver,
    points: 2,
  ),
];

void main() {
  final start = DateTime(2026, 8, 1);
  final templates = _pool();

  group('drawDaily determinism', () {
    test('same inputs always produce the same tray', () {
      final day = DateTime(2026, 8, 5);
      final a = BonusTrayDraw.drawDaily(
        tripId: 't1',
        dayDate: day,
        tripStartDate: start,
        templates: templates,
        existingAssignments: const [],
      );
      final b = BonusTrayDraw.drawDaily(
        tripId: 't1',
        dayDate: day,
        tripStartDate: start,
        templates: templates,
        existingAssignments: const [],
      );
      expect(a.map((t) => t.id).toList(), b.map((t) => t.id).toList());
    });

    test('different trips draw independently (not forced identical)', () {
      final day = DateTime(2026, 8, 5);
      final a = BonusTrayDraw.drawDaily(
        tripId: 't1',
        dayDate: day,
        tripStartDate: start,
        templates: templates,
        existingAssignments: const [],
      );
      final b = BonusTrayDraw.drawDaily(
        tripId: 't2',
        dayDate: day,
        tripStartDate: start,
        templates: templates,
        existingAssignments: const [],
      );
      // Not a strict requirement that they differ, but with 15 eligible
      // regular templates the same 2 picks in the same order for two
      // different trip ids would indicate the seed isn't actually being
      // used.
      expect(
        a.map((t) => t.id).toList(),
        isNot(equals(b.map((t) => t.id).toList())),
      );
    });
  });

  group('phase eligibility', () {
    test('arrival templates only ever appear on day 1', () {
      final day1 = BonusTrayDraw.drawDaily(
        tripId: 't1',
        dayDate: start,
        tripStartDate: start,
        templates: templates,
        existingAssignments: const [],
      );
      expect(
        day1.any((t) => t.phase == BonusTaskPhase.arrival),
        isTrue,
        reason: 'day 1 pool should be able to draw an arrival template',
      );

      final day5 = BonusTrayDraw.drawDaily(
        tripId: 't1',
        dayDate: start.add(const Duration(days: 4)),
        tripStartDate: start,
        templates: templates,
        existingAssignments: const [],
      );
      expect(day5.any((t) => t.phase == BonusTaskPhase.arrival), isFalse);
    });

    test('departure templates only ever appear on the last day', () {
      final end = start.add(const Duration(days: 6));
      final lastDay = BonusTrayDraw.drawDaily(
        tripId: 't1',
        dayDate: end,
        tripStartDate: start,
        tripEndDate: end,
        templates: templates,
        existingAssignments: const [],
      );
      expect(lastDay.any((t) => t.phase == BonusTaskPhase.departure), isTrue);

      final midTrip = BonusTrayDraw.drawDaily(
        tripId: 't1',
        dayDate: start.add(const Duration(days: 3)),
        tripStartDate: start,
        tripEndDate: end,
        templates: templates,
        existingAssignments: const [],
      );
      expect(
        midTrip.any((t) => t.phase == BonusTaskPhase.departure),
        isFalse,
      );
    });

    test('middle templates never appear on day 1', () {
      final day1 = BonusTrayDraw.drawDaily(
        tripId: 't1',
        dayDate: start,
        tripStartDate: start,
        templates: templates,
        existingAssignments: const [],
      );
      expect(day1.any((t) => t.phase == BonusTaskPhase.middle), isFalse);
    });
  });

  group('10-day no-repeat window', () {
    test('a template assigned 5 days ago is excluded today', () {
      final today = start.add(const Duration(days: 20));
      final recentlyUsedId = templates
          .firstWhere((t) => t.kind == BonusTaskKind.regular)
          .id;
      final existing = [
        _assignment(
          id: 'a1',
          templateId: recentlyUsedId,
          dayDate: today.subtract(const Duration(days: 5)),
        ),
      ];
      final picks = BonusTrayDraw.drawDaily(
        tripId: 't1',
        dayDate: today,
        tripStartDate: start,
        templates: templates,
        existingAssignments: existing,
      );
      expect(picks.map((t) => t.id), isNot(contains(recentlyUsedId)));
    });

    test('a template assigned 11 days ago is eligible again', () {
      // Force the pool down to a single eligible regular template so the
      // draw has no choice but to reuse it once it's outside the window.
      final onlyRegular = [
        _template(id: 900, code: 'only_regular'),
        _template(id: 901, code: 'anytime_only'),
      ];
      final today = start.add(const Duration(days: 20));
      final existing = [
        _assignment(
          id: 'a1',
          templateId: 900,
          dayDate: today.subtract(const Duration(days: 11)),
        ),
      ];
      final picks = BonusTrayDraw.drawDaily(
        tripId: 't1',
        dayDate: today,
        tripStartDate: start,
        templates: onlyRegular,
        existingAssignments: existing,
      );
      expect(picks.map((t) => t.id), contains(900));
    });
  });

  group('day composition', () {
    test('day one draws a starter plus two regulars', () {
      final picks = BonusTrayDraw.drawDaily(
        tripId: 't1',
        dayDate: start,
        tripStartDate: start,
        templates: templates,
        existingAssignments: const [],
      );
      expect(picks.length, 3);
      expect(picks.where((t) => t.kind == BonusTaskKind.starter), hasLength(1));
      expect(picks.where((t) => t.kind == BonusTaskKind.regular), hasLength(2));
    });

    test('other days draw exactly two regulars, no starter', () {
      final picks = BonusTrayDraw.drawDaily(
        tripId: 't1',
        dayDate: start.add(const Duration(days: 2)),
        tripStartDate: start,
        templates: templates,
        existingAssignments: const [],
      );
      expect(picks.length, 2);
      expect(picks.every((t) => t.kind == BonusTaskKind.regular), isTrue);
    });

    test('days 7, 14, 21 add exactly one milestone task', () {
      for (final dayIndex in [7, 14, 21]) {
        final picks = BonusTrayDraw.drawDaily(
          tripId: 't1',
          dayDate: start.add(Duration(days: dayIndex - 1)),
          tripStartDate: start,
          templates: templates,
          existingAssignments: const [],
        );
        expect(
          picks.where((t) => t.kind == BonusTaskKind.milestone),
          hasLength(1),
          reason: 'day $dayIndex should include one milestone task',
        );
      }
    });

    test('a non-milestone day never adds a milestone task', () {
      final picks = BonusTrayDraw.drawDaily(
        tripId: 't1',
        dayDate: start.add(const Duration(days: 5)),
        tripStartDate: start,
        templates: templates,
        existingAssignments: const [],
      );
      expect(picks.any((t) => t.kind == BonusTaskKind.milestone), isFalse);
    });
  });

  group('pickStretchTemplate', () {
    test('returns an eligible stretch template deterministically', () {
      final a = BonusTrayDraw.pickStretchTemplate(
        tripId: 't1',
        dayDate: start,
        templates: templates,
        existingAssignments: const [],
      );
      final b = BonusTrayDraw.pickStretchTemplate(
        tripId: 't1',
        dayDate: start,
        templates: templates,
        existingAssignments: const [],
      );
      expect(a, isNotNull);
      expect(a!.kind, BonusTaskKind.stretch);
      expect(a.id, b!.id);
    });

    test('returns null when no stretch templates exist', () {
      final withoutStretch = templates
          .where((t) => t.kind != BonusTaskKind.stretch)
          .toList();
      final result = BonusTrayDraw.pickStretchTemplate(
        tripId: 't1',
        dayDate: start,
        templates: withoutStretch,
        existingAssignments: const [],
      );
      expect(result, isNull);
    });
  });

  group('isStreakSaverDue', () {
    test('true when neither of the last 2 days has activity', () {
      final today = DateTime(2026, 8, 10);
      expect(
        BonusTrayDraw.isStreakSaverDue(today: today, activityDates: const {}),
        isTrue,
      );
    });

    test('false when yesterday had activity', () {
      final today = DateTime(2026, 8, 10);
      final yesterday = DateTime(2026, 8, 9);
      expect(
        BonusTrayDraw.isStreakSaverDue(
          today: today,
          activityDates: {yesterday},
        ),
        isFalse,
      );
    });

    test('false when only the day before yesterday had activity', () {
      final today = DateTime(2026, 8, 10);
      final dayBefore = DateTime(2026, 8, 8);
      expect(
        BonusTrayDraw.isStreakSaverDue(
          today: today,
          activityDates: {dayBefore},
        ),
        isFalse,
      );
    });

    test('activity today does not affect the last-2-days check', () {
      final today = DateTime(2026, 8, 10);
      expect(
        BonusTrayDraw.isStreakSaverDue(today: today, activityDates: {today}),
        isTrue,
      );
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/bonus/domain/entities/bonus_task_assignment_entity.dart';
import 'package:traviato/features/bonus/domain/entities/bonus_task_template_entity.dart';
import 'package:traviato/features/kept_memory/domain/build_kept_memory.dart';
import 'package:traviato/features/trip/domain/entities/trip_card_entity.dart';

import '../../journal/fakes/fake_day_note_repository.dart';
import '../../photo/fakes/fake_photo_repository.dart';
import '../../quest/fakes/fake_quest_repository.dart';
import '../../trip/fakes/fake_trip_repository.dart';

final _trip = buildTripCard(
  startDate: DateTime(2026, 8, 12),
  endDate: DateTime(2026, 8, 16),
  durationDays: 5,
  status: TripStatus.finished,
);

const _template = BonusTaskTemplateEntity(
  id: 7,
  code: 'sky_moment',
  title: 'Catch the sky',
  points: 2,
  phase: BonusTaskPhase.anytime,
  kind: BonusTaskKind.regular,
);

void main() {
  test('groups photos by day_date and orders each day by time', () {
    final memory = buildKeptMemory(
      trip: _trip,
      photos: [
        buildPhotoEntity(
          id: 'late',
          dayDate: DateTime(2026, 8, 13),
          takenAt: DateTime(2026, 8, 13, 18),
        ),
        buildPhotoEntity(
          id: 'early',
          dayDate: DateTime(2026, 8, 13),
          takenAt: DateTime(2026, 8, 13, 6),
        ),
        buildPhotoEntity(
          id: 'first',
          dayDate: DateTime(2026, 8, 12),
          takenAt: DateTime(2026, 8, 12, 9),
        ),
      ],
      notes: const [],
      quests: const [],
    );

    expect(memory.days.map((d) => d.dayIndex), [1, 2]);
    expect(memory.days[1].photos.map((p) => p.photo.id), ['early', 'late']);
    // Viewer order: day order, then time order.
    expect(memory.photos.map((p) => p.photo.id), ['first', 'early', 'late']);
    expect(memory.days[1].firstPhotoIndex, 1);
    expect(memory.days[1].date, DateTime.utc(2026, 8, 13));
  });

  test('without a day_date, falls back to the taken date', () {
    final memory = buildKeptMemory(
      trip: _trip,
      photos: [buildPhotoEntity(takenAt: DateTime(2026, 8, 15, 10))],
      notes: const [],
      quests: const [],
    );

    expect(memory.days.single.dayIndex, 4);
  });

  test('clamps anything outside the trip into the first or last day', () {
    final memory = buildKeptMemory(
      trip: _trip,
      photos: [
        buildPhotoEntity(id: 'before', dayDate: DateTime(2026, 8, 1)),
        buildPhotoEntity(id: 'after', dayDate: DateTime(2026, 9, 1)),
      ],
      notes: [buildDayNoteEntity(dayDate: DateTime(2026, 9, 2))],
      quests: const [],
    );

    expect(memory.days.map((d) => d.dayIndex), [1, 5]);
    expect(memory.days.last.notes, hasLength(1));
  });

  test('a day with only a note is its own chapter, with no photos', () {
    final memory = buildKeptMemory(
      trip: _trip,
      photos: [buildPhotoEntity(dayDate: DateTime(2026, 8, 12))],
      notes: [
        buildDayNoteEntity(dayDate: DateTime(2026, 8, 14), content: 'Rain.'),
      ],
      quests: const [],
    );

    final notesOnly = memory.days.last;
    expect(notesOnly.dayIndex, 3);
    expect(notesOnly.photos, isEmpty);
    expect(notesOnly.notes.single.content, 'Rain.');
    expect(memory.noteCount, 1);
    expect(memory.photoCount, 1);
  });

  test('marks photos that completed a bonus task with its template', () {
    final memory = buildKeptMemory(
      trip: _trip,
      photos: [
        buildPhotoEntity(id: 'dare', dayDate: DateTime(2026, 8, 12)),
        buildPhotoEntity(id: 'plain', dayDate: DateTime(2026, 8, 12)),
      ],
      notes: const [],
      quests: const [],
      bonusTemplates: const [_template],
      bonusAssignments: [
        BonusTaskAssignmentEntity(
          id: 'a1',
          tripId: 't1',
          templateId: 7,
          dayDate: DateTime(2026, 8, 12),
          completedAt: DateTime(2026, 8, 12, 10),
          photoId: 'dare',
          createdAt: DateTime(2026, 8, 12),
        ),
        // Not completed: never marks anything.
        BonusTaskAssignmentEntity(
          id: 'a2',
          tripId: 't1',
          templateId: 7,
          dayDate: DateTime(2026, 8, 13),
          photoId: 'plain',
          createdAt: DateTime(2026, 8, 13),
        ),
      ],
    );

    final byId = {for (final p in memory.photos) p.photo.id: p};
    expect(byId['dare']!.bonusTask, _template);
    expect(byId['plain']!.bonusTask, isNull);
  });

  test('orders the plan by day then position and counts what was done', () {
    final memory = buildKeptMemory(
      trip: _trip,
      photos: const [],
      notes: const [],
      quests: [
        buildQuestEntity(id: 'b', dayDate: DateTime(2026, 8, 13)),
        buildQuestEntity(
          id: 'a2',
          dayDate: DateTime(2026, 8, 12),
          position: 1,
          completedAt: DateTime(2026, 8, 12),
        ),
        buildQuestEntity(id: 'a1', dayDate: DateTime(2026, 8, 12)),
      ],
    );

    expect(memory.plan.map((p) => p.quest.id), ['a1', 'a2', 'b']);
    expect(memory.plan.map((p) => p.dayIndex), [1, 1, 2]);
    expect(memory.planDoneCount, 1);
    expect(memory.days, isEmpty);
  });

  test('day numbers stay whole across a DST change', () {
    final trip = buildTripCard(
      startDate: DateTime(2026, 10, 24),
      endDate: DateTime(2026, 10, 27),
      durationDays: 4,
    );
    final memory = buildKeptMemory(
      trip: trip,
      photos: [buildPhotoEntity(dayDate: DateTime(2026, 10, 26))],
      notes: const [],
      quests: const [],
    );

    expect(memory.days.single.dayIndex, 3);
  });
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:traviato/features/bonus/domain/entities/bonus_task_assignment_entity.dart';
import 'package:traviato/features/bonus/domain/entities/bonus_task_template_entity.dart';
import 'package:traviato/features/bonus/presentation/controllers/bonus_tray_controller.dart';
import 'package:traviato/features/bonus/presentation/providers/bonus_task_providers.dart';
import 'package:traviato/features/journal/presentation/providers/day_note_providers.dart';
import 'package:traviato/features/photo/presentation/providers/photo_providers.dart';
import 'package:traviato/features/quest/presentation/providers/quest_providers.dart';
import 'package:traviato/features/trip/presentation/providers/trip_providers.dart';

import '../../../journal/fakes/fake_day_note_repository.dart';
import '../../../photo/fakes/fake_photo_repository.dart';
import '../../../quest/fakes/fake_quest_repository.dart';
import '../../../trip/fakes/fake_trip_repository.dart';
import '../../fakes/fake_bonus_task_repository.dart';

List<BonusTaskTemplateEntity> _templates() => const [
  BonusTaskTemplateEntity(
    id: 1,
    code: 'r1',
    title: 'Regular one',
    points: 1,
    phase: BonusTaskPhase.anytime,
    kind: BonusTaskKind.regular,
  ),
  BonusTaskTemplateEntity(
    id: 2,
    code: 'r2',
    title: 'Regular two',
    points: 1,
    phase: BonusTaskPhase.anytime,
    kind: BonusTaskKind.regular,
  ),
];

ProviderContainer _buildContainer({
  required FakeTripRepository tripRepo,
  required FakeBonusTaskRepository bonusRepo,
  FakeQuestRepository? questRepo,
  FakeDayNoteRepository? noteRepo,
  FakePhotoRepository? photoRepo,
}) {
  return ProviderContainer(
    retry: (_, _) => null,
    overrides: [
      tripRepositoryProvider.overrideWithValue(tripRepo),
      bonusTaskRepositoryProvider.overrideWithValue(bonusRepo),
      questRepositoryProvider.overrideWithValue(
        questRepo ?? FakeQuestRepository(),
      ),
      dayNoteRepositoryProvider.overrideWithValue(
        noteRepo ?? FakeDayNoteRepository(),
      ),
      photoRepositoryProvider.overrideWithValue(
        photoRepo ?? FakePhotoRepository(),
      ),
    ],
  );
}

void main() {
  final today = DateTime.now();
  final todayDate = DateTime(today.year, today.month, today.day);
  final start = todayDate.subtract(const Duration(days: 3));
  final end = todayDate.add(const Duration(days: 3));

  test('build loads the trip, draws today\'s tray, and exposes it', () async {
    final tripRepo = FakeTripRepository()
      ..tripCardResult = Right(
        buildTripCard(id: 't1', startDate: start, endDate: end),
      );
    final bonusRepo = FakeBonusTaskRepository()..templates = _templates();
    final container = _buildContainer(tripRepo: tripRepo, bonusRepo: bonusRepo);
    addTearDown(container.dispose);

    final state = await container.read(
      bonusTrayControllerProvider('t1').future,
    );

    expect(state.trip.id, 't1');
    expect(state.dailyTasks, hasLength(2));
    expect(bonusRepo.assignForDayCallCount, greaterThan(0));
  });

  test(
    'applyAssignmentUpserted inserts a new row and replaces an existing one',
    () async {
      final tripRepo = FakeTripRepository()
        ..tripCardResult = Right(
          buildTripCard(id: 't1', startDate: start, endDate: end),
        );
      final bonusRepo = FakeBonusTaskRepository()..templates = _templates();
      final container = _buildContainer(
        tripRepo: tripRepo,
        bonusRepo: bonusRepo,
      );
      addTearDown(container.dispose);
      container.listen(bonusTrayControllerProvider('t1'), (_, _) {});

      final initial = await container.read(
        bonusTrayControllerProvider('t1').future,
      );
      final notifier = container.read(
        bonusTrayControllerProvider('t1').notifier,
      );

      final existingId = initial.assignments.first.id;
      final completed = initial.assignments.first.copyWith(
        completedAt: () => DateTime(2026, 1, 2),
      );
      notifier.applyAssignmentUpserted(completed);

      final state = container.read(bonusTrayControllerProvider('t1')).value!;
      expect(
        state.assignments.firstWhere((a) => a.id == existingId).isCompleted,
        isTrue,
      );
      expect(state.assignments, hasLength(initial.assignments.length));

      final newAssignment = BonusTaskAssignmentEntity(
        id: 'brand-new',
        tripId: 't1',
        templateId: 1,
        dayDate: todayDate,
        createdAt: DateTime(2026, 1, 1),
      );
      notifier.applyAssignmentUpserted(newAssignment);
      final finalState = container
          .read(bonusTrayControllerProvider('t1'))
          .value!;
      expect(
        finalState.assignments.any((a) => a.id == 'brand-new'),
        isTrue,
      );
      expect(finalState.assignments, hasLength(initial.assignments.length + 1));
    },
  );
}

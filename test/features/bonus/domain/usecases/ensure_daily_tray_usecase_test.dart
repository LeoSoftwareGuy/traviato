import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:traviato/core/errors/failures.dart';
import 'package:traviato/features/bonus/domain/entities/bonus_task_assignment_entity.dart';
import 'package:traviato/features/bonus/domain/entities/bonus_task_template_entity.dart';
import 'package:traviato/features/bonus/domain/usecases/ensure_daily_tray_usecase.dart';

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
  BonusTaskTemplateEntity(
    id: 40,
    code: 'starter',
    title: 'Starter',
    points: 1,
    phase: BonusTaskPhase.arrival,
    kind: BonusTaskKind.starter,
  ),
  BonusTaskTemplateEntity(
    id: 70,
    code: 'streak_saver',
    title: 'Streak saver',
    points: 2,
    phase: BonusTaskPhase.anytime,
    kind: BonusTaskKind.streakSaver,
  ),
];

void main() {
  final start = DateTime(2026, 8, 1);
  final end = DateTime(2026, 8, 10);

  test('draws and inserts today\'s tray when none exists yet', () async {
    final repo = FakeBonusTaskRepository()..templates = _templates();
    final useCase = EnsureDailyTrayUseCase(repository: repo);
    final trip = buildTripCard(id: 't1', startDate: start, endDate: end);
    final today = start.add(const Duration(days: 3));

    // Recent activity keeps the independent streak-saver check from also
    // firing, isolating this test to the daily-draw insert.
    final result = await useCase(
      trip: trip,
      today: today,
      activityDates: {today.subtract(const Duration(days: 1))},
    );

    expect(result.isRight(), isTrue);
    expect(repo.assignForDayCallCount, 1);
    expect(repo.assignForDayCalls.single, hasLength(2)); // 2 regulars
    final state = result.getRight().toNullable()!;
    expect(state.assignments, hasLength(2));
  });

  test(
    'does not re-draw when a regular assignment already exists today',
    () async {
      final today = start.add(const Duration(days: 3));
      final repo = FakeBonusTaskRepository()
        ..templates = _templates()
        ..assignments = [
          BonusTaskAssignmentEntity(
            id: 'existing',
            tripId: 't1',
            templateId: 1,
            dayDate: today,
            createdAt: DateTime(2026, 1, 1),
          ),
        ];
      final useCase = EnsureDailyTrayUseCase(repository: repo);
      final trip = buildTripCard(id: 't1', startDate: start, endDate: end);

      final result = await useCase(
        trip: trip,
        today: today,
        activityDates: {today.subtract(const Duration(days: 1))},
      );

      expect(result.isRight(), isTrue);
      expect(repo.assignForDayCallCount, 0);
    },
  );

  test('does nothing outside the trip\'s active window', () async {
    final repo = FakeBonusTaskRepository()..templates = _templates();
    final useCase = EnsureDailyTrayUseCase(repository: repo);
    final trip = buildTripCard(id: 't1', startDate: start, endDate: end);
    final beforeTrip = start.subtract(const Duration(days: 1));

    final result = await useCase(
      trip: trip,
      today: beforeTrip,
      activityDates: {},
    );

    expect(result.isRight(), isTrue);
    expect(repo.assignForDayCallCount, 0);
  });

  test('skips everything for an undated trip', () async {
    final repo = FakeBonusTaskRepository()..templates = _templates();
    final useCase = EnsureDailyTrayUseCase(repository: repo);
    final trip = buildTripCard(id: 't1');

    final result = await useCase(
      trip: trip,
      today: DateTime(2026, 8, 5),
      activityDates: {},
    );

    expect(result.isRight(), isTrue);
    expect(repo.assignForDayCallCount, 0);
  });

  test('inserts a streak-saver when due and none is active', () async {
    final today = start.add(const Duration(days: 5));
    final repo = FakeBonusTaskRepository()
      ..templates = _templates()
      ..assignments = [
        // Today's regular draw already happened, isolating the
        // streak-saver insert as the only expected call.
        BonusTaskAssignmentEntity(
          id: 'a1',
          tripId: 't1',
          templateId: 1,
          dayDate: today,
          createdAt: DateTime(2026, 1, 1),
        ),
        BonusTaskAssignmentEntity(
          id: 'a2',
          tripId: 't1',
          templateId: 2,
          dayDate: today,
          createdAt: DateTime(2026, 1, 1),
        ),
      ];
    final useCase = EnsureDailyTrayUseCase(repository: repo);
    final trip = buildTripCard(id: 't1', startDate: start, endDate: end);

    final result = await useCase(trip: trip, today: today, activityDates: {});

    expect(result.isRight(), isTrue);
    expect(repo.assignForDayCallCount, 1);
    expect(repo.assignForDayCalls.single, [70]);
  });

  test('does not insert a second streak-saver while one is active', () async {
    final today = start.add(const Duration(days: 5));
    final repo = FakeBonusTaskRepository()
      ..templates = _templates()
      ..assignments = [
        BonusTaskAssignmentEntity(
          id: 'a1',
          tripId: 't1',
          templateId: 1,
          dayDate: today,
          createdAt: DateTime(2026, 1, 1),
        ),
        BonusTaskAssignmentEntity(
          id: 'a2',
          tripId: 't1',
          templateId: 2,
          dayDate: today,
          createdAt: DateTime(2026, 1, 1),
        ),
        BonusTaskAssignmentEntity(
          id: 'streak',
          tripId: 't1',
          templateId: 70,
          dayDate: today.subtract(const Duration(days: 2)),
          createdAt: DateTime(2026, 1, 1),
        ),
      ];
    final useCase = EnsureDailyTrayUseCase(repository: repo);
    final trip = buildTripCard(id: 't1', startDate: start, endDate: end);

    final result = await useCase(trip: trip, today: today, activityDates: {});

    expect(result.isRight(), isTrue);
    expect(repo.assignForDayCallCount, 0);
  });

  test('propagates a repository failure', () async {
    final repo = FakeBonusTaskRepository()
      ..templatesResult = const Left(NetworkFailure());
    final useCase = EnsureDailyTrayUseCase(repository: repo);
    final trip = buildTripCard(id: 't1', startDate: start, endDate: end);

    final result = await useCase(
      trip: trip,
      today: start,
      activityDates: {},
    );

    expect(result.isLeft(), isTrue);
    expect(result.getLeft().toNullable(), isA<NetworkFailure>());
  });
}

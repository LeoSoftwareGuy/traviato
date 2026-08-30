import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:traviato/features/bonus/domain/entities/bonus_task_template_entity.dart';
import 'package:traviato/features/bonus/presentation/controllers/bonus_tray_controller.dart';
import 'package:traviato/features/bonus/presentation/mutations/bonus_task_mutations.dart';
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

const _tripId = 't1';

class _Harness extends ConsumerWidget {
  const _Harness();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keeps bonusTrayControllerProvider(tripId) alive for the test, same as
    // the real Bonus screen would.
    ref.watch(bonusTrayControllerProvider(_tripId));
    return MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            ElevatedButton(
              onPressed: () async {
                try {
                  await runCompleteBonusTask(
                    ref: ref,
                    tripId: _tripId,
                    assignmentId: 'a1',
                    photoId: 'p1',
                  );
                } catch (_) {}
              },
              child: const Text('Complete'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await runClaimStretchTask(
                    ref: ref,
                    tripId: _tripId,
                    dayDate: DateTime(2026, 8, 18),
                    templateId: 50,
                  );
                } catch (_) {}
              },
              child: const Text('Claim stretch'),
            ),
          ],
        ),
      ),
    );
  }
}

Future<ProviderContainer> _pumpHarness(
  WidgetTester tester, {
  required FakeTripRepository tripRepo,
  required FakeBonusTaskRepository bonusRepo,
}) async {
  late final ProviderContainer container;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tripRepositoryProvider.overrideWithValue(tripRepo),
        bonusTaskRepositoryProvider.overrideWithValue(bonusRepo),
        questRepositoryProvider.overrideWithValue(FakeQuestRepository()),
        dayNoteRepositoryProvider.overrideWithValue(FakeDayNoteRepository()),
        photoRepositoryProvider.overrideWithValue(FakePhotoRepository()),
      ],
      child: Builder(
        builder: (context) {
          container = ProviderScope.containerOf(context);
          return const _Harness();
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

FakeTripRepository _activeTripRepo() {
  final today = DateTime.now();
  final todayDate = DateTime(today.year, today.month, today.day);
  return FakeTripRepository()
    ..tripCardResult = Right(
      buildTripCard(
        id: _tripId,
        startDate: todayDate.subtract(const Duration(days: 1)),
        endDate: todayDate.add(const Duration(days: 1)),
      ),
    );
}

void main() {
  testWidgets(
    'runCompleteBonusTask completes the assignment and updates the tray',
    (tester) async {
      final tripRepo = _activeTripRepo();
      final bonusRepo = FakeBonusTaskRepository()
        ..templates = const [
          BonusTaskTemplateEntity(
            id: 1,
            code: 'r1',
            title: 'Regular one',
            points: 1,
            phase: BonusTaskPhase.anytime,
            kind: BonusTaskKind.regular,
          ),
        ];

      final container = await _pumpHarness(
        tester,
        tripRepo: tripRepo,
        bonusRepo: bonusRepo,
      );

      await tester.tap(find.text('Complete'));
      await tester.pumpAndSettle();

      expect(bonusRepo.completeCallCount, 1);
      final state = container.read(bonusTrayControllerProvider(_tripId)).value!;
      expect(
        state.assignments.any((a) => a.id == 'a1' && a.isCompleted),
        isTrue,
      );
    },
  );

  testWidgets(
    'calling runCompleteBonusTask twice for the same assignment stays safe',
    (tester) async {
      final tripRepo = _activeTripRepo();
      final bonusRepo = FakeBonusTaskRepository()
        ..templates = const [
          BonusTaskTemplateEntity(
            id: 1,
            code: 'r1',
            title: 'Regular one',
            points: 1,
            phase: BonusTaskPhase.anytime,
            kind: BonusTaskKind.regular,
          ),
        ];

      final container = await _pumpHarness(
        tester,
        tripRepo: tripRepo,
        bonusRepo: bonusRepo,
      );

      await tester.tap(find.text('Complete'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Complete'));
      await tester.pumpAndSettle();

      expect(bonusRepo.completeCallCount, 2);
      final state = container.read(bonusTrayControllerProvider(_tripId)).value!;
      // Still exactly one row for this assignment id — no duplication.
      expect(state.assignments.where((a) => a.id == 'a1'), hasLength(1));
    },
  );

  testWidgets('runClaimStretchTask inserts the stretch assignment', (
    tester,
  ) async {
    final tripRepo = _activeTripRepo();
    final bonusRepo = FakeBonusTaskRepository()
      ..templates = const [
        BonusTaskTemplateEntity(
          id: 50,
          code: 'stretch_1',
          title: 'Stretch',
          points: 3,
          phase: BonusTaskPhase.anytime,
          kind: BonusTaskKind.stretch,
        ),
      ];

    final container = await _pumpHarness(
      tester,
      tripRepo: tripRepo,
      bonusRepo: bonusRepo,
    );

    await tester.tap(find.text('Claim stretch'));
    await tester.pumpAndSettle();

    expect(
      bonusRepo.assignForDayCalls.any(
        (ids) => ids.length == 1 && ids.first == 50,
      ),
      isTrue,
    );
    final state = container.read(bonusTrayControllerProvider(_tripId)).value!;
    expect(state.assignments.any((a) => a.templateId == 50), isTrue);
  });
}

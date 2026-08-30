import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/core/events/global_event.dart';
import 'package:traviato/core/events/global_event_bus.dart';
import 'package:traviato/features/quest/domain/entities/quest_entity.dart';
import 'package:traviato/features/quest/presentation/controllers/plan_controller.dart';
import 'package:traviato/features/quest/presentation/mutations/quest_mutations.dart';
import 'package:traviato/features/quest/presentation/providers/quest_providers.dart';
import 'package:traviato/features/trip/presentation/providers/trip_providers.dart';

import '../../../trip/fakes/fake_trip_repository.dart';
import '../../fakes/fake_quest_repository.dart';

const _tripId = 't1';

class _Harness extends ConsumerWidget {
  const _Harness({required this.quest});

  final QuestEntity quest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(planControllerProvider(_tripId));
    return MaterialApp(
      home: Scaffold(
        body: ElevatedButton(
          onPressed: () async {
            try {
              await runToggleQuest(ref: ref, tripId: _tripId, quest: quest);
            } catch (_) {}
          },
          child: const Text('Toggle'),
        ),
      ),
    );
  }
}

Future<List<GlobalEvent>> _toggle(
  WidgetTester tester, {
  required QuestEntity quest,
  required FakeQuestRepository questRepo,
}) async {
  final bus = GlobalEventBus();
  addTearDown(bus.dispose);
  final events = <GlobalEvent>[];
  final sub = bus.stream.listen(events.add);
  addTearDown(sub.cancel);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        questRepositoryProvider.overrideWithValue(questRepo),
        tripRepositoryProvider.overrideWithValue(FakeTripRepository()),
        globalEventBusProvider.overrideWithValue(bus),
      ],
      child: _Harness(quest: quest),
    ),
  );
  await tester.tap(find.text('Toggle'));
  await tester.pumpAndSettle();
  return events;
}

void main() {
  testWidgets('completing a quest passes tripId through and awards stars', (
    tester,
  ) async {
    final quest = buildQuestEntity(id: 'q1', tripId: _tripId);
    final questRepo = FakeQuestRepository();

    final events = await _toggle(tester, quest: quest, questRepo: questRepo);

    expect(questRepo.toggleCallCount, 1);
    expect(events, hasLength(1));
    expect(events.single, isA<StarsAwardedDispatched>());
  });

  testWidgets('unchecking a quest does not fire StarsAwardedDispatched', (
    tester,
  ) async {
    final quest = buildQuestEntity(
      id: 'q1',
      tripId: _tripId,
      completedAt: DateTime(2026, 8, 18, 9),
    );
    final questRepo = FakeQuestRepository();

    final events = await _toggle(tester, quest: quest, questRepo: questRepo);

    expect(questRepo.toggleCallCount, 1);
    expect(events, isEmpty);
  });
}

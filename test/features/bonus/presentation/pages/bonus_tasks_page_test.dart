import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:traviato/features/bonus/domain/entities/bonus_task_assignment_entity.dart';
import 'package:traviato/features/bonus/domain/entities/bonus_task_template_entity.dart';
import 'package:traviato/features/bonus/presentation/pages/bonus_tasks_page.dart';
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
import '../../../../helpers/localized_app.dart';

const _tripId = 't1';

List<BonusTaskTemplateEntity> _regularPair() => const [
  BonusTaskTemplateEntity(
    id: 1,
    code: 'r1',
    title: 'The worst photo of the day',
    points: 2,
    phase: BonusTaskPhase.anytime,
    kind: BonusTaskKind.regular,
  ),
  BonusTaskTemplateEntity(
    id: 2,
    code: 'r2',
    title: 'Find something free',
    points: 1,
    phase: BonusTaskPhase.anytime,
    kind: BonusTaskKind.regular,
  ),
];

FakeTripRepository _activeTripRepo({DateTime? start, DateTime? end}) {
  final today = DateTime.now();
  final todayDate = DateTime(today.year, today.month, today.day);
  return FakeTripRepository()
    ..tripCardResult = Right(
      buildTripCard(
        id: _tripId,
        startDate: start ?? todayDate.subtract(const Duration(days: 5)),
        endDate: end ?? todayDate.add(const Duration(days: 5)),
      ),
    );
}

Future<void> _pump(
  WidgetTester tester, {
  required FakeTripRepository tripRepo,
  required FakeBonusTaskRepository bonusRepo,
  Locale locale = const Locale('en'),
}) async {
  final router = GoRouter(
    initialLocation: '/bonus',
    routes: [
      GoRoute(
        path: '/bonus',
        builder: (context, state) => const BonusTasksPage(tripId: _tripId),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tripRepositoryProvider.overrideWithValue(tripRepo),
        bonusTaskRepositoryProvider.overrideWithValue(bonusRepo),
        questRepositoryProvider.overrideWithValue(FakeQuestRepository()),
        dayNoteRepositoryProvider.overrideWithValue(FakeDayNoteRepository()),
        photoRepositoryProvider.overrideWithValue(FakePhotoRepository()),
      ],
      child: localizedRouterApp(locale: locale, routerConfig: router),
    ),
  );
}

void main() {
  testWidgets('renders today\'s open tasks with their ✦ values', (
    tester,
  ) async {
    final tripRepo = _activeTripRepo();
    final bonusRepo = FakeBonusTaskRepository()..templates = _regularPair();

    await _pump(tester, tripRepo: tripRepo, bonusRepo: bonusRepo);
    await tester.pumpAndSettle();

    expect(find.text('The worst photo of the day'), findsOneWidget);
    expect(find.text('Find something free'), findsOneWidget);
    expect(find.text('✦2'), findsOneWidget);
    expect(find.text('✦1'), findsOneWidget);
  });

  testWidgets('shows the earned banner once both dailies are done', (
    tester,
  ) async {
    final tripRepo = _activeTripRepo();
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final bonusRepo = FakeBonusTaskRepository()
      ..templates = _regularPair()
      ..assignments = [
        BonusTaskAssignmentEntity(
          id: 'a1',
          tripId: _tripId,
          templateId: 1,
          dayDate: todayDate,
          completedAt: DateTime(2026, 1, 1),
          createdAt: DateTime(2026, 1, 1),
        ),
        BonusTaskAssignmentEntity(
          id: 'a2',
          tripId: _tripId,
          templateId: 2,
          dayDate: todayDate,
          completedAt: DateTime(2026, 1, 1),
          createdAt: DateTime(2026, 1, 1),
        ),
      ];

    await _pump(tester, tripRepo: tripRepo, bonusRepo: bonusRepo);
    await tester.pumpAndSettle();

    expect(find.textContaining('Both done'), findsOneWidget);
    expect(find.text('The worst photo of the day'), findsNothing);
  });

  testWidgets('shows past completions in the COMPLETED history', (
    tester,
  ) async {
    final tripRepo = _activeTripRepo();
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final pastDay = todayDate.subtract(const Duration(days: 2));
    final bonusRepo = FakeBonusTaskRepository()
      ..templates = _regularPair()
      ..assignments = [
        BonusTaskAssignmentEntity(
          id: 'past1',
          tripId: _tripId,
          templateId: 1,
          dayDate: pastDay,
          completedAt: DateTime(2026, 1, 1),
          createdAt: DateTime(2026, 1, 1),
        ),
      ];

    await _pump(tester, tripRepo: tripRepo, bonusRepo: bonusRepo);
    await tester.pumpAndSettle();

    expect(find.text('COMPLETED'), findsOneWidget);
    expect(find.textContaining('COMPLETED · DAY'), findsOneWidget);
  });

  group('in ru / et (#220)', () {
    testWidgets('seeded tasks read in Russian; unknown codes keep the DB '
        'title (#243)', (tester) async {
      final bonusRepo = FakeBonusTaskRepository()
        ..templates = const [
          BonusTaskTemplateEntity(
            id: 1,
            code: 'worst_photo_of_day',
            title: 'The worst photo of the day',
            points: 2,
            phase: BonusTaskPhase.anytime,
            kind: BonusTaskKind.regular,
          ),
          BonusTaskTemplateEntity(
            id: 2,
            code: 'not_seeded_yet',
            title: 'A dare the app does not know',
            points: 1,
            phase: BonusTaskPhase.anytime,
            kind: BonusTaskKind.regular,
          ),
        ];
      await _pump(
        tester,
        tripRepo: _activeTripRepo(),
        bonusRepo: bonusRepo,
        locale: const Locale('ru'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Худшее фото дня'), findsOneWidget);
      expect(find.text('The worst photo of the day'), findsNothing);
      expect(find.text('A dare the app does not know'), findsOneWidget);
    });

    testWidgets('earned banner and completed history read in Russian', (
      tester,
    ) async {
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      final bonusRepo = FakeBonusTaskRepository()
        ..templates = _regularPair()
        ..assignments = [
          for (final (id, day) in [
            ('a1', todayDate),
            ('a2', todayDate),
            ('p1', todayDate.subtract(const Duration(days: 2))),
          ])
            BonusTaskAssignmentEntity(
              id: id,
              tripId: _tripId,
              templateId: id == 'a2' ? 2 : 1,
              dayDate: day,
              completedAt: DateTime(2026, 1, 1),
              createdAt: DateTime(2026, 1, 1),
            ),
        ];
      await _pump(
        tester,
        tripRepo: _activeTripRepo(),
        bonusRepo: bonusRepo,
        locale: const Locale('ru'),
      );
      await tester.pumpAndSettle();

      expect(find.text('БОНУСНЫЕ ЗАДАНИЯ'), findsOneWidget);
      expect(find.textContaining('Оба выполнены · ✦'), findsOneWidget);
      expect(find.text('Новые — завтра.'), findsOneWidget);
      expect(find.text('ВЫПОЛНЕНО'), findsWidgets);
      expect(find.textContaining('ВЫПОЛНЕНО · ДЕНЬ'), findsOneWidget);
    });

    for (final locale in const [Locale('en'), Locale('ru'), Locale('et')]) {
      testWidgets('lays out without overflow at 360pt in '
          '${locale.languageCode}', (tester) async {
        setScreenSize(tester, height: 1600);
        await _pump(
          tester,
          tripRepo: _activeTripRepo(),
          bonusRepo: FakeBonusTaskRepository()..templates = _regularPair(),
          locale: locale,
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:traviato/core/config/router/route_constants.dart';
import 'package:traviato/core/errors/failures.dart';
import 'package:traviato/core/theme/app_typography.dart';
import 'package:traviato/features/bonus/domain/entities/bonus_task_template_entity.dart';
import 'package:traviato/features/bonus/domain/entities/star_ledger_group_entity.dart';
import 'package:traviato/features/bonus/presentation/pages/bonus_empty_state_page.dart';
import 'package:traviato/features/bonus/presentation/pages/stars_by_memory_page.dart';
import 'package:traviato/features/bonus/presentation/providers/bonus_empty_state_providers.dart';
import 'package:traviato/features/bonus/presentation/providers/bonus_task_providers.dart';
import 'package:traviato/features/journal/presentation/providers/day_note_providers.dart';
import 'package:traviato/features/photo/presentation/providers/photo_providers.dart';
import 'package:traviato/features/quest/presentation/providers/quest_providers.dart';
import 'package:traviato/features/trip/domain/entities/trip_card_entity.dart';
import 'package:traviato/features/trip/presentation/providers/trip_providers.dart';

import '../../../../helpers/localized_app.dart';
import '../../../journal/fakes/fake_day_note_repository.dart';
import '../../../photo/fakes/fake_photo_repository.dart';
import '../../../quest/fakes/fake_quest_repository.dart';
import '../../../trip/fakes/fake_trip_repository.dart';
import '../../fakes/fake_bonus_task_repository.dart';
import '../../fakes/fake_star_breakdown_repository.dart';

/// Saturday 17 Oct 2026, 09:00 local — Lisbon starts Wednesday the 21st.
final _now = DateTime(2026, 10, 17, 9);

final _lisbon = buildTripCard(
  id: 'lisbon',
  name: 'Lisbon long weekend',
  startDate: DateTime(2026, 10, 21),
  endDate: DateTime(2026, 10, 24),
  durationDays: 4,
  vibes: const ['Foodie'],
  questCount: 3,
);

TripCardEntity _kept(String id, String name, DateTime start) => buildTripCard(
  id: id,
  name: name,
  startDate: start,
  endDate: start.add(const Duration(days: 3)),
  status: TripStatus.finished,
  wrapUpPublishedAt: DateTime(2026, 9, 1),
);

final _dolomites = _kept('d', 'Dolomites, slowly', DateTime(2026, 8, 3));
final _tartu = _kept('t', 'Tartu in the rain', DateTime(2026, 5, 9));
final _mum = _kept('m', "Mum's 60th", DateTime(2026, 3, 14));

StarLedgerGroupEntity _g(String? trip, StarSource s, int count, int points) =>
    StarLedgerGroupEntity(
      tripId: trip,
      source: s,
      entryCount: count,
      points: points,
    );

/// 47 stars: 9 photos (18), 12 notes (12), 7 quests (7), 5 dares (10).
final _fortySevenStars = [
  _g('d', StarSource.photo, 6, 12),
  _g('d', StarSource.note, 7, 7),
  _g('d', StarSource.bonusTask, 5, 10),
  _g('t', StarSource.photo, 3, 6),
  _g('t', StarSource.note, 5, 5),
  _g('t', StarSource.quest, 1, 1),
  _g('m', StarSource.quest, 6, 6),
];

const _teaserTemplates = [
  BonusTaskTemplateEntity(
    id: 1,
    code: 'local_snack',
    title: "Try a snack you can't get at home",
    points: 2,
    phase: BonusTaskPhase.anytime,
    kind: BonusTaskKind.regular,
  ),
  BonusTaskTemplateEntity(
    id: 2,
    code: 'something_free',
    title: 'Find something free',
    points: 1,
    phase: BonusTaskPhase.anytime,
    kind: BonusTaskKind.regular,
  ),
];

Future<void> _pump(
  WidgetTester tester, {
  List<TripCardEntity> trips = const [],
  List<StarLedgerGroupEntity> stars = const [],
  FakeTripRepository? tripRepo,
  FakeBonusTaskRepository? bonusRepo,
  DateTime Function()? clock,
  Locale locale = const Locale('en'),
  double width = 390,
}) async {
  setScreenSize(tester, width: width, height: 2400);
  final router = GoRouter(
    initialLocation: '/bonus',
    routes: [
      GoRoute(
        path: '/bonus',
        builder: (context, state) => const BonusEmptyStatePage(),
      ),
      GoRoute(
        path: RoutePaths.bonusStarsByMemory,
        name: RouteNames.bonusStarsByMemory,
        builder: (context, state) => const StarsByMemoryPage(),
      ),
      GoRoute(
        path: RoutePaths.createMemory,
        name: RouteNames.createMemory,
        builder: (context, state) => const Text('create-memory'),
      ),
      GoRoute(
        path: RoutePaths.tripPlan,
        name: RouteNames.tripPlan,
        builder: (context, state) =>
            Text('plan:${state.pathParameters['tripId']}'),
      ),
      GoRoute(
        path: RoutePaths.tripJournal,
        name: RouteNames.tripJournal,
        builder: (context, state) =>
            Text('journal:${state.pathParameters['tripId']}'),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tripRepositoryProvider.overrideWithValue(
          tripRepo ?? (FakeTripRepository()..tripsResult = Right(trips)),
        ),
        starBreakdownRepositoryProvider.overrideWithValue(
          FakeStarBreakdownRepository()..groups = stars,
        ),
        bonusTaskRepositoryProvider.overrideWithValue(
          bonusRepo ??
              (FakeBonusTaskRepository()..templates = _teaserTemplates),
        ),
        bonusClockProvider.overrideWithValue(clock ?? () => _now),
        questRepositoryProvider.overrideWithValue(FakeQuestRepository()),
        dayNoteRepositoryProvider.overrideWithValue(FakeDayNoteRepository()),
        photoRepositoryProvider.overrideWithValue(FakePhotoRepository()),
      ],
      child: localizedRouterApp(locale: locale, routerConfig: router),
    ),
  );
}

void main() {
  group('1a · upcoming memory', () {
    testWidgets('says when the next tray opens, and for which memory', (
      tester,
    ) async {
      await _pump(
        tester,
        trips: [_lisbon, _dolomites, _tartu, _mum],
        stars: _fortySevenStars,
      );
      await tester.pumpAndSettle();

      expect(find.text('NEXT MEMORY'), findsOneWidget);
      expect(
        find.text('Your next tray opens\nWednesday, 21 October'),
        findsOneWidget,
      );
      expect(
        find.text(
          "That's in 4 days, when Lisbon long weekend begins. "
          'Nothing to do before then.',
        ),
        findsOneWidget,
      );
      expect(find.text('Lisbon long weekend'), findsOneWidget);
      expect(find.text('OCT 21 – OCT 24 · 4 DAYS · FOODIE'), findsOneWidget);
      expect(find.text('3 quests planned'), findsOneWidget);
    });

    testWidgets('previews two first-day tasks, not tappable, no timers', (
      tester,
    ) async {
      await _pump(tester, trips: [_lisbon], stars: _fortySevenStars);
      await tester.pumpAndSettle();

      expect(find.text('WHAT A TRAY LOOKS LIKE'), findsOneWidget);
      expect(find.text("Try a snack you can't get at home"), findsOneWidget);
      expect(find.text('Find something free'), findsOneWidget);
      expect(
        find.ancestor(
          of: find.text('Find something free'),
          matching: find.byType(InkWell),
        ),
        findsNothing,
      );
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.textContaining(RegExp(r'\d+:\d\d')), findsNothing);
    });

    testWidgets('a memory starting tomorrow says tomorrow', (tester) async {
      await _pump(
        tester,
        trips: [_lisbon],
        clock: () => DateTime(2026, 10, 20, 23, 59),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
          "That's tomorrow, when Lisbon long weekend begins. "
          'Nothing to do before then.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('the memory card opens its plan', (tester) async {
      await _pump(tester, trips: [_lisbon]);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Lisbon long weekend'));
      await tester.pumpAndSettle();

      expect(find.text('plan:lisbon'), findsOneWidget);
    });

    testWidgets('with 0 stars the star block is the earning guide', (
      tester,
    ) async {
      await _pump(tester, trips: [_lisbon]);
      await tester.pumpAndSettle();

      expect(find.text('NEXT MEMORY'), findsOneWidget);
      expect(find.text('HOW STARS COLLECT'), findsOneWidget);
      expect(find.text('YOUR STARS'), findsNothing);
    });
  });

  group('1b · nothing upcoming, has stars', () {
    testWidgets('prompts a next memory and summarises the stars', (
      tester,
    ) async {
      await _pump(
        tester,
        trips: [_dolomites, _tartu, _mum],
        stars: _fortySevenStars,
      );
      await tester.pumpAndSettle();

      expect(find.text('NOTHING ON THE WAY'), findsOneWidget);
      expect(
        find.text('Bonus tasks start\nwith your next memory'),
        findsOneWidget,
      );
      expect(find.text('YOUR STARS'), findsOneWidget);
      // Top-bar pill and the big number.
      expect(find.text('47'), findsNWidgets(2));
      expect(find.text('across 3 memories'), findsOneWidget);
      expect(find.text('9 × ✦2'), findsOneWidget);
      expect(find.text('12 × ✦1'), findsOneWidget);
      expect(find.text('7 × ✦1'), findsOneWidget);
      expect(find.text('5 dares'), findsOneWidget);
      expect(find.text('Dolomites, slowly'), findsOneWidget);
      expect(find.text('AUG 2026 · KEPT'), findsOneWidget);
      expect(find.text('✦29'), findsOneWidget);
      // Exactly 3 memories: no "All memories" link.
      expect(find.text('All memories ›'), findsNothing);
    });

    testWidgets('Create a memory opens the create flow', (tester) async {
      await _pump(tester, trips: [_dolomites], stars: _fortySevenStars);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create a memory'));
      await tester.pumpAndSettle();

      expect(find.text('create-memory'), findsOneWidget);
    });

    testWidgets('a memory row opens that memory', (tester) async {
      await _pump(
        tester,
        trips: [_dolomites, _tartu, _mum],
        stars: _fortySevenStars,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tartu in the rain'));
      await tester.pumpAndSettle();

      expect(find.text('journal:t'), findsOneWidget);
    });

    testWidgets('more than 3 rows: top 3 plus All memories › → full list, '
        'deleted memories as Earlier memories', (tester) async {
      await _pump(
        tester,
        trips: [_dolomites, _tartu, _mum],
        stars: [..._fortySevenStars, _g(null, StarSource.photo, 1, 2)],
      );
      await tester.pumpAndSettle();

      expect(find.text('across 3 memories'), findsOneWidget);
      expect(find.text('Earlier memories'), findsNothing);
      await tester.tap(find.text('All memories ›'));
      await tester.pumpAndSettle();

      expect(find.text('ALL MEMORIES'), findsOneWidget);
      expect(find.text('Earlier memories'), findsOneWidget);
      expect(find.text("Mum's 60th"), findsOneWidget);
    });
  });

  group('1c · brand new', () {
    testWidgets('prompts a first memory and shows the earning guide', (
      tester,
    ) async {
      await _pump(tester);
      await tester.pumpAndSettle();

      expect(
        find.text('Bonus tasks start\nwith your first memory'),
        findsOneWidget,
      );
      expect(find.text('Create a memory'), findsOneWidget);
      expect(find.text('HOW STARS COLLECT'), findsOneWidget);
      expect(find.text('A photo'), findsOneWidget);
      expect(find.text('✦2'), findsOneWidget);
      expect(find.text('✦1'), findsNWidgets(2));
      expect(find.text('✦1–3'), findsOneWidget);
      expect(find.text('BY MEMORY'), findsNothing);
      expect(
        find.textContaining("They aren't points to spend"),
        findsOneWidget,
      );
    });
  });

  testWidgets('a memory under way shows its tray instead', (tester) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final active = buildTripCard(
      id: 'now',
      startDate: today.subtract(const Duration(days: 1)),
      endDate: today.add(const Duration(days: 1)),
      status: TripStatus.current,
    );
    final tripRepo = FakeTripRepository()
      ..tripsResult = Right([active])
      ..tripCardResult = Right(active);

    await _pump(tester, tripRepo: tripRepo, clock: DateTime.now);
    await tester.pumpAndSettle();

    expect(find.text('NEXT MEMORY'), findsNothing);
    expect(find.text('NOTHING ON THE WAY'), findsNothing);
    expect(find.text("Try a snack you can't get at home"), findsOneWidget);
  });

  testWidgets('shows a spinner while loading', (tester) async {
    final tripRepo = FakeTripRepository()
      ..delay = const Duration(seconds: 1)
      ..tripsResult = const Right([]);

    await _pump(tester, tripRepo: tripRepo);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('shows a retry on error', (tester) async {
    final tripRepo = FakeTripRepository()
      ..tripsResult = const Left(NetworkFailure());

    await _pump(tester, tripRepo: tripRepo);
    await tester.pumpAndSettle();

    expect(find.text('Retry'), findsOneWidget);
  });

  group('localized', () {
    for (final width in [360.0, 390.0]) {
      testWidgets('1a in Russian at ${width.toInt()}pt: Literata, no '
          'clipping', (tester) async {
        await _pump(
          tester,
          trips: [_lisbon, _dolomites, _tartu, _mum],
          stars: _fortySevenStars,
          locale: const Locale('ru'),
          width: width,
        );
        await tester.pumpAndSettle();

        expect(AppTypography.serifIsLiterata, isTrue);
        expect(find.text('СЛЕДУЮЩЕЕ ВОСПОМИНАНИЕ'), findsOneWidget);
        expect(
          find.text('Новые задания —\nв среду, 21 октября'),
          findsOneWidget,
        );
        expect(
          find.text(
            'Через 4 дня, когда начнётся Lisbon long weekend. '
            'До тех пор ничего делать не нужно.',
          ),
          findsOneWidget,
        );
        expect(find.text('в 3 воспоминаниях'), findsOneWidget);
        expect(find.text('5 шт.'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('1b in English at ${width.toInt()}pt: no clipping', (
        tester,
      ) async {
        await _pump(
          tester,
          trips: [_dolomites, _tartu, _mum],
          stars: _fortySevenStars,
          width: width,
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('Russian weekdays take the right preposition', (tester) async {
      final tuesdayTrip = buildTripCard(
        id: 'tue',
        name: 'Тарту',
        startDate: DateTime(2026, 10, 20),
        endDate: DateTime(2026, 10, 21),
      );
      await _pump(tester, trips: [tuesdayTrip], locale: const Locale('ru'));
      await tester.pumpAndSettle();

      expect(
        find.text('Новые задания —\nво вторник, 20 октября'),
        findsOneWidget,
      );
    });
  });
}

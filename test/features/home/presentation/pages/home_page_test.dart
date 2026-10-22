import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:traviato/core/config/router/route_constants.dart';
import 'package:traviato/core/errors/failures.dart';
import 'package:traviato/core/events/global_event.dart';
import 'package:traviato/core/events/global_event_bus.dart';
import 'package:traviato/core/theme/app_colors.dart';
import 'package:traviato/core/theme/app_theme.dart';
import 'package:traviato/features/auth/domain/entities/user_entity.dart';
import 'package:traviato/features/auth/presentation/providers/auth_providers.dart';
import 'package:traviato/features/bonus/presentation/providers/bonus_task_providers.dart';
import 'package:traviato/features/checklist/domain/entities/checklist_item_entity.dart';
import 'package:traviato/features/checklist/presentation/providers/checklist_providers.dart';
import 'package:traviato/features/expense/presentation/providers/expense_providers.dart';
import 'package:traviato/features/home/presentation/pages/home_page.dart';
import 'package:traviato/features/home/presentation/providers/profile_stats_provider.dart';
import 'package:traviato/features/home/presentation/widgets/home_stats_bar.dart';
import 'package:traviato/features/home/presentation/widgets/upcoming_hero_card.dart';
import 'package:traviato/features/journal/presentation/providers/day_note_providers.dart';
import 'package:traviato/features/photo/presentation/providers/photo_providers.dart';
import 'package:traviato/features/profile/presentation/providers/profile_providers.dart';
import 'package:traviato/features/quest/presentation/providers/quest_providers.dart';
import 'package:traviato/features/trip/domain/entities/trip_card_entity.dart';
import 'package:traviato/features/trip/presentation/providers/trip_providers.dart';

import '../../../auth/fakes/fake_auth_repository.dart';
import '../../../bonus/fakes/fake_bonus_task_repository.dart';
import '../../../checklist/fakes/fake_checklist_repository.dart';
import '../../../expense/fakes/fake_expense_repository.dart';
import '../../../journal/fakes/fake_day_note_repository.dart';
import '../../../photo/fakes/fake_photo_repository.dart';
import '../../../profile/fakes/fake_profile_repository.dart';
import '../../../quest/fakes/fake_quest_repository.dart';
import '../../../trip/fakes/fake_trip_repository.dart';
import '../../fakes/fake_profile_stats_repository.dart';

Future<void> _pump(
  WidgetTester tester, {
  required FakeTripRepository tripRepo,
  FakeAuthRepository? authRepo,
  FakeProfileRepository? profileRepo,
  GlobalEventBus? bus,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        profileRepositoryProvider.overrideWithValue(
          profileRepo ?? FakeProfileRepository(),
        ),
        if (bus != null) globalEventBusProvider.overrideWithValue(bus),
        authRepositoryProvider.overrideWithValue(
          authRepo ?? FakeAuthRepository(),
        ),
        tripRepositoryProvider.overrideWithValue(tripRepo),
        questRepositoryProvider.overrideWithValue(FakeQuestRepository()),
        checklistRepositoryProvider.overrideWithValue(
          FakeChecklistRepository(),
        ),
        profileStatsRepositoryProvider.overrideWithValue(
          FakeProfileStatsRepository(),
        ),
        // The Manage/Delete sheets (issue #115's long-press entry point)
        // fetch photo/note counts for the delete-confirmation copy.
        photoRepositoryProvider.overrideWithValue(FakePhotoRepository()),
        dayNoteRepositoryProvider.overrideWithValue(FakeDayNoteRepository()),
      ],
      child: MaterialApp(theme: AppTheme.dark, home: const HomePage()),
    ),
  );
}

void main() {
  testWidgets('shows a spinner while loading', (tester) async {
    final tripRepo = FakeTripRepository()
      ..tripsResult = const Right([])
      ..delay = const Duration(milliseconds: 50);
    await _pump(tester, tripRepo: tripRepo);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('shows the retry scaffold on failure', (tester) async {
    final tripRepo = FakeTripRepository()
      ..tripsResult = const Left(NetworkFailure());
    await _pump(tester, tripRepo: tripRepo);
    await tester.pumpAndSettle();

    expect(find.text('Please check your connection.'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Retry'), findsOneWidget);
  });

  testWidgets('shows the empty prompt when there are no trips', (
    tester,
  ) async {
    final tripRepo = FakeTripRepository()..tripsResult = const Right([]);
    await _pump(tester, tripRepo: tripRepo);
    await tester.pumpAndSettle();

    expect(find.text('No memories yet'), findsOneWidget);
    expect(find.text('HAPPENING NOW'), findsNothing);
  });

  testWidgets('shows the hero card only when a trip is current/upcoming', (
    tester,
  ) async {
    final trip = buildTripCard(
      id: 't1',
      name: 'Mountain cabin retreat',
      startDate: DateTime.now().add(const Duration(days: 5)),
      status: TripStatus.upcoming,
    );
    final tripRepo = FakeTripRepository()..tripsResult = Right([trip]);
    await _pump(tester, tripRepo: tripRepo);
    await tester.pumpAndSettle();

    expect(find.text('Mountain cabin retreat'), findsOneWidget);
    expect(find.byType(UpcomingHeroCard), findsOneWidget);
  });

  // A named greeting is a Text.rich; "Hello!" is plain data.
  String greetingText(WidgetTester tester) {
    final text = tester.widget<Text>(find.byKey(const Key('home-greeting')));
    return text.data ?? text.textSpan!.toPlainText();
  }

  testWidgets('greets with the Profile name, not the auth metadata (#266)', (
    tester,
  ) async {
    final authRepo = FakeAuthRepository();
    final tripRepo = FakeTripRepository()..tripsResult = const Right([]);
    await _pump(
      tester,
      tripRepo: tripRepo,
      authRepo: authRepo,
      profileRepo: FakeProfileRepository()
        ..profileResult = Right(buildProfile(username: 'Leo')),
    );
    // AuthController only subscribes to the stream once the widget tree
    // (and thus authControllerProvider) has built, so emit after pumping.
    authRepo.emit(
      const UserEntity(id: 'u1', email: 'ada@example.com', username: 'ada'),
    );
    await tester.pumpAndSettle();

    expect(greetingText(tester), 'Hello, Leo');
  });

  testWidgets(
    'falls back to the auth metadata name when the profile read fails',
    (tester) async {
      final authRepo = FakeAuthRepository();
      final tripRepo = FakeTripRepository()..tripsResult = const Right([]);
      await _pump(
        tester,
        tripRepo: tripRepo,
        authRepo: authRepo,
        profileRepo: FakeProfileRepository()
          ..profileResult = const Left(NetworkFailure()),
      );
      authRepo.emit(
        const UserEntity(id: 'u1', email: 'ada@example.com', username: 'ada'),
      );
      await tester.pumpAndSettle();

      expect(greetingText(tester), 'Hello, ada');
    },
  );

  testWidgets(
    'a name saved in Profile reaches the greeting and avatar without a '
    'restart (#266)',
    (tester) async {
      final bus = GlobalEventBus();
      addTearDown(bus.dispose);
      final authRepo = FakeAuthRepository();
      final tripRepo = FakeTripRepository()..tripsResult = const Right([]);
      await _pump(
        tester,
        tripRepo: tripRepo,
        authRepo: authRepo,
        bus: bus,
        // Apple sign-in: no name anywhere yet.
        profileRepo: FakeProfileRepository()
          ..profileResult = Right(buildProfile(username: null)),
      );
      authRepo.emit(const UserEntity(id: 'u1', email: 'x@privaterelay.com'));
      await tester.pumpAndSettle();
      expect(greetingText(tester), 'Hello!');
      expect(find.text('?'), findsOneWidget);

      bus.add(ProfileUpdatedDispatched(profile: buildProfile(username: 'Leo')));
      await tester.pumpAndSettle();

      expect(greetingText(tester), 'Hello, Leo');
      expect(find.text('L'), findsOneWidget);
    },
  );

  testWidgets('the hero-card Checklist row navigates to the checklist '
      'route', (tester) async {
    final trip = buildTripCard(
      id: 't1',
      name: 'Mountain cabin retreat',
      startDate: DateTime.now().add(const Duration(days: 5)),
      status: TripStatus.upcoming,
    );
    final tripRepo = FakeTripRepository()..tripsResult = Right([trip]);
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(path: '/home', builder: (context, state) => const HomePage()),
        GoRoute(
          path: '/memory/:tripId/checklist',
          name: RouteNames.tripChecklist,
          builder: (context, state) =>
              const Scaffold(body: Text('checklist page')),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          tripRepositoryProvider.overrideWithValue(tripRepo),
          questRepositoryProvider.overrideWithValue(FakeQuestRepository()),
          checklistRepositoryProvider.overrideWithValue(
            FakeChecklistRepository(),
          ),
        ],
        child: MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Checklist'));
    await tester.pumpAndSettle();

    expect(find.text('checklist page'), findsOneWidget);
  });

  testWidgets(
    'the hero-card Expenses button opens the sheet pre-selecting that trip',
    (tester) async {
      final trip = buildTripCard(
        id: 't1',
        name: 'Mountain cabin retreat',
        startDate: DateTime.now().add(const Duration(days: 5)),
        status: TripStatus.upcoming,
      );
      final tripRepo = FakeTripRepository()..tripsResult = Right([trip]);
      final expenseRepo = FakeExpenseRepository()
        ..summariesResult = Right([
          buildExpenseSummaryEntity(
            tripId: 't1',
            tripName: 'Mountain cabin retreat',
          ),
        ]);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
            tripRepositoryProvider.overrideWithValue(tripRepo),
            questRepositoryProvider.overrideWithValue(FakeQuestRepository()),
            checklistRepositoryProvider.overrideWithValue(
              FakeChecklistRepository(),
            ),
            expenseRepositoryProvider.overrideWithValue(expenseRepo),
          ],
          child: MaterialApp(theme: AppTheme.dark, home: const HomePage()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Expenses'));
      await tester.pumpAndSettle();

      expect(expenseRepo.getSummariesCallCount, 1);
      expect(find.text('Description'), findsOneWidget); // sheet is open
      // The hero card's trip is pre-selected in the memory dropdown.
      expect(find.text('Mountain cabin retreat'), findsWidgets);
    },
  );

  testWidgets('a Coming-up card navigates to Plan for that memory', (
    tester,
  ) async {
    final hero = buildTripCard(
      id: 't1',
      name: 'Mountain cabin retreat',
      startDate: DateTime.now().add(const Duration(days: 1)),
      status: TripStatus.upcoming,
    );
    final comingUp = buildTripCard(
      id: 't2',
      name: 'Lisbon winter',
      startDate: DateTime.now().add(const Duration(days: 20)),
      status: TripStatus.upcoming,
    );
    final tripRepo = FakeTripRepository()
      ..tripsResult = Right([hero, comingUp]);
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(path: '/home', builder: (context, state) => const HomePage()),
        GoRoute(
          path: '/memory/:tripId/plan',
          name: RouteNames.tripPlan,
          builder: (context, state) => Scaffold(
            body: Text('plan page ${state.pathParameters['tripId']}'),
          ),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          tripRepositoryProvider.overrideWithValue(tripRepo),
          questRepositoryProvider.overrideWithValue(FakeQuestRepository()),
          checklistRepositoryProvider.overrideWithValue(
            FakeChecklistRepository(),
          ),
        ],
        child: MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Lisbon winter'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lisbon winter'));
    await tester.pumpAndSettle();

    expect(find.text('plan page t2'), findsOneWidget);
  });

  group('a Kept-forever card', () {
    /// Taps the finished memory's card and returns the destination's label.
    Future<void> tapCard(WidgetTester tester, TripCardEntity finished) async {
      final tripRepo = FakeTripRepository()..tripsResult = Right([finished]);
      Widget label(String text) => Scaffold(body: Text(text));
      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          GoRoute(path: '/home', builder: (context, state) => const HomePage()),
          GoRoute(
            path: '/memory/:tripId/journal',
            name: RouteNames.tripJournal,
            builder: (context, state) => label('Journal'),
          ),
          GoRoute(
            path: '/memory/:tripId/wrap-up',
            name: RouteNames.tripWrapUp,
            builder: (context, state) => label('Film'),
          ),
          GoRoute(
            path: '/memory/:tripId',
            name: RouteNames.keptMemory,
            builder: (context, state) => label('Memory page'),
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
            tripRepositoryProvider.overrideWithValue(tripRepo),
            questRepositoryProvider.overrideWithValue(FakeQuestRepository()),
            checklistRepositoryProvider.overrideWithValue(
              FakeChecklistRepository(),
            ),
          ],
          child: MaterialApp.router(
            theme: AppTheme.dark,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Atlas high road'));
      await tester.pumpAndSettle();
    }

    TripCardEntity finished({DateTime? keptAt, DateTime? filmSeenAt}) =>
        buildTripCard(
          id: 't1',
          name: 'Atlas high road',
          startDate: DateTime(2025, 1, 1),
          endDate: DateTime(2025, 1, 9),
          status: TripStatus.finished,
          wrapUpPublishedAt: keptAt,
          filmSeenAt: filmSeenAt,
        );

    testWidgets('not kept yet: opens Journal, not Wrap-up (#101)', (
      tester,
    ) async {
      await tapCard(tester, finished());

      expect(find.text('Journal'), findsOneWidget);
    });

    testWidgets('kept, film not seen yet: plays the film first (#279)', (
      tester,
    ) async {
      await tapCard(tester, finished(keptAt: DateTime(2025, 1, 10)));

      expect(find.text('Film'), findsOneWidget);
    });

    testWidgets('kept, film seen: opens the memory page (#279)', (
      tester,
    ) async {
      await tapCard(
        tester,
        finished(
          keptAt: DateTime(2025, 1, 10),
          filmSeenAt: DateTime(2025, 1, 10),
        ),
      );

      expect(find.text('Memory page'), findsOneWidget);
    });
  });

  testWidgets(
    'a kept-forever card shows the "Kept forever" badge, not "Recap" (#95)',
    (tester) async {
      final finished = buildTripCard(
        id: 't1',
        name: 'Atlas high road',
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 1, 9),
        status: TripStatus.finished,
        wrapUpPublishedAt: DateTime(2025, 1, 10),
      );
      final tripRepo = FakeTripRepository()..tripsResult = Right([finished]);
      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomePage(),
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
            tripRepositoryProvider.overrideWithValue(tripRepo),
            questRepositoryProvider.overrideWithValue(FakeQuestRepository()),
            checklistRepositoryProvider.overrideWithValue(
              FakeChecklistRepository(),
            ),
          ],
          child: MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('✦ Kept forever'), findsOneWidget);
      expect(find.text('▸ Recap'), findsNothing);
    },
  );

  testWidgets('the stars badge navigates to the Bonus tasks placeholder', (
    tester,
  ) async {
    final tripRepo = FakeTripRepository()..tripsResult = const Right([]);
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(path: '/home', builder: (context, state) => const HomePage()),
        GoRoute(
          path: '/bonus-tasks',
          name: RouteNames.bonusTasks,
          builder: (context, state) =>
              const Scaffold(body: Text('Bonus tasks')),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          tripRepositoryProvider.overrideWithValue(tripRepo),
          questRepositoryProvider.overrideWithValue(FakeQuestRepository()),
          checklistRepositoryProvider.overrideWithValue(
            FakeChecklistRepository(),
          ),
        ],
        child: MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('home-stars-badge')));
    await tester.pumpAndSettle();

    expect(find.text('Bonus tasks'), findsOneWidget);
  });

  group('the stars badge with a hero memory (#219)', () {
    Future<void> pumpWithHero(WidgetTester tester, TripCardEntity hero) async {
      final tripRepo = FakeTripRepository()
        ..tripsResult = Right([hero])
        ..tripCardResult = Right(hero);
      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          GoRoute(path: '/home', builder: (context, state) => const HomePage()),
          GoRoute(
            path: RoutePaths.bonusTasks,
            name: RouteNames.bonusTasks,
            builder: (context, state) =>
                const Scaffold(body: Text('no-tray page')),
          ),
          GoRoute(
            path: RoutePaths.tripBonusTasks,
            name: RouteNames.tripBonusTasks,
            builder: (context, state) => Scaffold(
              body: Text('tray:${state.pathParameters['tripId']}'),
            ),
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
            tripRepositoryProvider.overrideWithValue(tripRepo),
            questRepositoryProvider.overrideWithValue(FakeQuestRepository()),
            checklistRepositoryProvider.overrideWithValue(
              FakeChecklistRepository(),
            ),
            bonusTaskRepositoryProvider.overrideWithValue(
              FakeBonusTaskRepository(),
            ),
            dayNoteRepositoryProvider.overrideWithValue(
              FakeDayNoteRepository(),
            ),
            photoRepositoryProvider.overrideWithValue(FakePhotoRepository()),
          ],
          child: MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('home-stars-badge')));
      await tester.pumpAndSettle();
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    testWidgets('under way → its tray', (tester) async {
      await pumpWithHero(
        tester,
        buildTripCard(
          id: 'now',
          startDate: today,
          endDate: today.add(const Duration(days: 2)),
          status: TripStatus.current,
        ),
      );
      expect(find.text('tray:now'), findsOneWidget);
    });

    testWidgets('only upcoming → the no-tray page', (tester) async {
      await pumpWithHero(
        tester,
        buildTripCard(
          id: 'soon',
          startDate: today.add(const Duration(days: 4)),
          endDate: today.add(const Duration(days: 7)),
        ),
      );
      expect(find.text('no-tray page'), findsOneWidget);
    });
  });

  testWidgets(
    'stats cards use the same fill as the Plan/Expenses buttons (#111)',
    (tester) async {
      final tripRepo = FakeTripRepository()..tripsResult = const Right([]);
      await _pump(tester, tripRepo: tripRepo);
      await tester.pumpAndSettle();

      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(HomeStatsBar),
              matching: find.byType(Container),
            )
            .first,
      );
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.color, AppColors.surfaceDisabled);
    },
  );

  testWidgets(
    'hides the entire Coming-up section when only the hero trip exists '
    '(#111)',
    (tester) async {
      final hero = buildTripCard(
        id: 't1',
        name: 'Solo hero trip',
        startDate: DateTime.now().add(const Duration(days: 3)),
        status: TripStatus.upcoming,
      );
      final tripRepo = FakeTripRepository()..tripsResult = Right([hero]);
      await _pump(tester, tripRepo: tripRepo);
      await tester.pumpAndSettle();

      expect(find.text('COMING UP'), findsNothing);
      expect(find.text('Capture a new memory'), findsNothing);
    },
  );

  testWidgets(
    'shows the Coming-up section with no add-card once a second upcoming '
    'trip exists (#111)',
    (tester) async {
      final hero = buildTripCard(
        id: 't1',
        name: 'Hero trip',
        startDate: DateTime.now().add(const Duration(days: 1)),
        status: TripStatus.upcoming,
      );
      final second = buildTripCard(
        id: 't2',
        name: 'Second trip',
        startDate: DateTime.now().add(const Duration(days: 10)),
        status: TripStatus.upcoming,
      );
      final tripRepo = FakeTripRepository()
        ..tripsResult = Right([hero, second]);
      await _pump(tester, tripRepo: tripRepo);
      await tester.pumpAndSettle();

      expect(find.text('COMING UP'), findsOneWidget);
      expect(find.text('Second trip'), findsOneWidget);
      expect(find.text('Capture a new memory'), findsNothing);
    },
  );

  testWidgets(
    'the hero card no longer renders a trip-progress divider (#111)',
    (tester) async {
      final hero = buildTripCard(
        id: 't1',
        name: 'Hero trip',
        startDate: DateTime.now().add(const Duration(days: 1)),
        status: TripStatus.upcoming,
      );
      final tripRepo = FakeTripRepository()..tripsResult = Right([hero]);
      await _pump(tester, tripRepo: tripRepo);
      await tester.pumpAndSettle();

      expect(find.byType(LinearProgressIndicator), findsNothing);
    },
  );

  Future<void> pumpHeroWithChecklist(
    WidgetTester tester,
    List<ChecklistItemEntity> items,
  ) async {
    final hero = buildTripCard(
      id: 't1',
      name: 'Hero trip',
      startDate: DateTime.now().add(const Duration(days: 1)),
      status: TripStatus.upcoming,
    );
    final tripRepo = FakeTripRepository()..tripsResult = Right([hero]);
    final checklistRepo = FakeChecklistRepository()
      ..itemsResult = Right(
        items,
      );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          tripRepositoryProvider.overrideWithValue(tripRepo),
          questRepositoryProvider.overrideWithValue(FakeQuestRepository()),
          checklistRepositoryProvider.overrideWithValue(checklistRepo),
        ],
        child: MaterialApp(theme: AppTheme.dark, home: const HomePage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  double heroChecklistFillFraction(WidgetTester tester) {
    return tester
        .widget<FractionallySizedBox>(
          find.descendant(
            of: find.byType(UpcomingHeroCard),
            matching: find.byType(FractionallySizedBox),
          ),
        )
        .widthFactor!;
  }

  testWidgets('hero-card checklist fill is 0% when nothing is packed (#111)', (
    tester,
  ) async {
    await pumpHeroWithChecklist(tester, [
      buildChecklistItemEntity(id: 'i1'),
      buildChecklistItemEntity(id: 'i2'),
    ]);

    expect(heroChecklistFillFraction(tester), 0.0);
    expect(find.text('0 of 2 packed →'), findsOneWidget);
  });

  testWidgets(
    'hero-card checklist fill is 50% when half the items are packed (#111)',
    (tester) async {
      await pumpHeroWithChecklist(tester, [
        buildChecklistItemEntity(id: 'i1', isChecked: true),
        buildChecklistItemEntity(id: 'i2', isChecked: true),
        buildChecklistItemEntity(id: 'i3'),
        buildChecklistItemEntity(id: 'i4'),
      ]);

      expect(heroChecklistFillFraction(tester), 0.5);
      expect(find.text('2 of 4 packed →'), findsOneWidget);
    },
  );

  testWidgets(
    'hero-card checklist fill is 100% when everything is packed (#111)',
    (tester) async {
      await pumpHeroWithChecklist(tester, [
        buildChecklistItemEntity(id: 'i1', isChecked: true),
        buildChecklistItemEntity(id: 'i2', isChecked: true),
      ]);

      expect(heroChecklistFillFraction(tester), 1.0);
      expect(find.text('2 of 2 packed →'), findsOneWidget);
    },
  );

  testWidgets('uses a flat background color for the whole screen (#111)', (
    tester,
  ) async {
    final tripRepo = FakeTripRepository()..tripsResult = const Right([]);
    await _pump(tester, tripRepo: tripRepo);
    await tester.pumpAndSettle();

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    expect(scaffold.backgroundColor, AppColors.background);
  });

  group('long-press to manage/delete (#115)', () {
    testWidgets(
      'long-press on the Happening-now hero card opens the full Manage '
      'sheet',
      (tester) async {
        final trip = buildTripCard(
          id: 't1',
          name: 'Mountain cabin retreat',
          startDate: DateTime.now().add(const Duration(days: 5)),
          status: TripStatus.upcoming,
        );
        final tripRepo = FakeTripRepository()..tripsResult = Right([trip]);
        await _pump(tester, tripRepo: tripRepo);
        await tester.pumpAndSettle();

        await tester.longPress(find.text('Mountain cabin retreat'));
        await tester.pumpAndSettle();

        expect(find.text('Edit this memory'), findsOneWidget);
      },
    );

    testWidgets('long-press on a Coming-up card opens the full Manage sheet', (
      tester,
    ) async {
      final hero = buildTripCard(
        id: 't1',
        name: 'Mountain cabin retreat',
        startDate: DateTime.now().add(const Duration(days: 1)),
        status: TripStatus.upcoming,
      );
      final comingUp = buildTripCard(
        id: 't2',
        name: 'Lisbon winter',
        startDate: DateTime.now().add(const Duration(days: 20)),
        status: TripStatus.upcoming,
      );
      final tripRepo = FakeTripRepository()
        ..tripsResult = Right([hero, comingUp]);
      await _pump(tester, tripRepo: tripRepo);
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Lisbon winter'));
      await tester.pumpAndSettle();
      await tester.longPress(find.text('Lisbon winter'));
      await tester.pumpAndSettle();

      expect(find.text('Edit this memory'), findsOneWidget);
    });

    testWidgets(
      'long-press on a Kept-forever card opens the delete-only sheet, not '
      'the full Manage sheet',
      (tester) async {
        final finished = buildTripCard(
          id: 't1',
          name: 'Atlas high road',
          startDate: DateTime(2025, 1, 1),
          endDate: DateTime(2025, 1, 9),
          status: TripStatus.finished,
        );
        final tripRepo = FakeTripRepository()..tripsResult = Right([finished]);
        await _pump(tester, tripRepo: tripRepo);
        await tester.pumpAndSettle();

        await tester.longPress(find.text('Atlas high road'));
        await tester.pumpAndSettle();

        expect(find.text('Delete this memory'), findsWidgets); // title+button
        expect(find.text('Edit this memory'), findsNothing);
        expect(find.text('Rename'), findsNothing);
      },
    );

    testWidgets('a scroll gesture over the hero card does not open a sheet', (
      tester,
    ) async {
      final trip = buildTripCard(
        id: 't1',
        name: 'Mountain cabin retreat',
        startDate: DateTime.now().add(const Duration(days: 5)),
        status: TripStatus.upcoming,
      );
      final tripRepo = FakeTripRepository()..tripsResult = Right([trip]);
      await _pump(tester, tripRepo: tripRepo);
      await tester.pumpAndSettle();

      await tester.drag(
        find.text('Mountain cabin retreat'),
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();

      expect(find.text('Edit this memory'), findsNothing);
    });
  });
}

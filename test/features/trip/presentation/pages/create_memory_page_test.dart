import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:traviato/core/config/router/route_constants.dart';
import 'package:traviato/core/theme/app_theme.dart';
import 'package:traviato/features/subscription/presentation/providers/subscription_providers.dart';
import 'package:traviato/features/trip/presentation/pages/create_memory_page.dart';
import 'package:traviato/features/trip/presentation/providers/trip_providers.dart';

import '../../../subscription/fakes/fake_subscription_repository.dart';
import '../../../trip/fakes/fake_trip_repository.dart';

Future<FakeTripRepository> _pump(WidgetTester tester) async {
  final tripRepo = FakeTripRepository()..tripsResult = const Right([]);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tripRepositoryProvider.overrideWithValue(tripRepo),
        // Free by default — the memory-limit pre-check is tier-aware (#267).
        subscriptionRepositoryProvider.overrideWithValue(
          FakeSubscriptionRepository(),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.dark,
        home: const CreateMemoryPage(),
      ),
    ),
  );
  return tripRepo;
}

/// For tests that submit successfully — `_submit` calls `context.pop()`,
/// which needs something to pop back to.
Future<FakeTripRepository> _pumpWithRouter(WidgetTester tester) async {
  final tripRepo = FakeTripRepository()..tripsResult = const Right([]);
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: ElevatedButton(
            onPressed: () => context.push('/create'),
            child: const Text('open'),
          ),
        ),
      ),
      GoRoute(
        path: '/create',
        builder: (context, state) => const CreateMemoryPage(),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tripRepositoryProvider.overrideWithValue(tripRepo),
        // Free by default — the memory-limit pre-check is tier-aware (#267).
        subscriptionRepositoryProvider.overrideWithValue(
          FakeSubscriptionRepository(),
        ),
      ],
      child: MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return tripRepo;
}

/// Picks a start then an end date through the real date sheet — required
/// since #270. Days in the currently shown month, so the range is valid.
Future<void> _pickDates(WidgetTester tester) async {
  for (final day in ['10', '12']) {
    final field = find.text('Pick a date').first;
    await tester.ensureVisible(field);
    await tester.tap(field);
    await tester.pumpAndSettle();
    await tester.tap(find.text(day).last);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
  }
}

Future<void> _nameAndSubmit(WidgetTester tester) async {
  await tester.enterText(
    find.byType(TextFormField).first,
    'Summer in Tokyo',
  );
  await _pickDates(tester);
  final submitButton = find.widgetWithText(ElevatedButton, 'Create memory');
  await tester.ensureVisible(submitButton);
  await tester.tap(submitButton);
  await tester.pump();
}

void main() {
  testWidgets('shows a validation error when the name is empty', (
    tester,
  ) async {
    await _pump(tester);

    final submitButton = find.widgetWithText(ElevatedButton, 'Create memory');
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    expect(find.text('Give this memory a name.'), findsOneWidget);
  });

  testWidgets('toggles vibe chip selection and updates the counter', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text('0 chosen'), findsOneWidget);

    final chip = find.text('Adventure');
    await tester.ensureVisible(chip);
    await tester.tap(chip);
    await tester.pump();

    expect(find.text('1 chosen'), findsOneWidget);

    // Tapping again deselects — no exception, no crash, chip still present.
    await tester.tap(chip);
    await tester.pump();

    expect(chip, findsOneWidget);
    expect(find.text('0 chosen'), findsOneWidget);
  });

  group('cover picker', () {
    testWidgets('shows the empty state with no suggestion until a vibe is '
        'picked', (tester) async {
      await _pump(tester);

      expect(find.text('Choose a cover'), findsOneWidget);
      expect(find.textContaining('SUGGESTED:'), findsNothing);

      final chip = find.text('Romantic');
      await tester.ensureVisible(chip);
      await tester.tap(chip);
      await tester.pump();

      expect(find.text('SUGGESTED: ROMANTIC'), findsOneWidget);
    });

    testWidgets('selecting a thumbnail shows the chosen state', (
      tester,
    ) async {
      await _pump(tester);

      final thumbnail = find.byKey(
        const Key('cover-thumbnail-epic_milestone'),
      );
      await tester.ensureVisible(thumbnail);
      await tester.tap(thumbnail);
      await tester.pump();

      expect(find.text('YOUR COVER'), findsOneWidget);
      expect(find.text('Choose a cover'), findsNothing);
    });

    testWidgets('an explicit thumbnail pick persists that asset id', (
      tester,
    ) async {
      final tripRepo = await _pumpWithRouter(tester);

      final thumbnail = find.byKey(
        const Key('cover-thumbnail-epic_milestone'),
      );
      await tester.ensureVisible(thumbnail);
      await tester.tap(thumbnail);
      await tester.pump();

      await _nameAndSubmit(tester);
      await tester.pumpAndSettle();

      expect(
        tripRepo.lastCreateTripCoverImagePath,
        'asset:epic_milestone',
      );
    });

    testWidgets(
      'no pick + a matching vibe persists the suggested cover',
      (tester) async {
        final tripRepo = await _pumpWithRouter(tester);

        final chip = find.text('Romantic');
        await tester.ensureVisible(chip);
        await tester.tap(chip);
        await tester.pump();

        await _nameAndSubmit(tester);
        await tester.pumpAndSettle();

        expect(
          tripRepo.lastCreateTripCoverImagePath,
          'asset:romantic',
        );
      },
    );

    testWidgets('no pick + no vibe persists the fallback cover', (
      tester,
    ) async {
      final tripRepo = await _pumpWithRouter(tester);

      await _nameAndSubmit(tester);
      await tester.pumpAndSettle();

      expect(tripRepo.lastCreateTripCoverImagePath, 'asset:hero');
    });
  });

  group('dates are required (#270)', () {
    testWidgets('submitting without dates shows an error and creates nothing', (
      tester,
    ) async {
      final tripRepo = await _pump(tester);

      await tester.enterText(
        find.byType(TextFormField).first,
        'Summer in Tokyo',
      );
      final submitButton = find.widgetWithText(
        ElevatedButton,
        'Create memory',
      );
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      expect(find.text('Add a start and end date.'), findsOneWidget);
      expect(tripRepo.createTripCallCount, 0);
    });

    testWidgets(
      "picking only a start date doesn't flag the end before Create",
      (tester) async {
        await _pump(tester);
        expect(
          find.text(
            'Not sure yet? Pick your best guess you can change it later.',
          ),
          findsOneWidget,
        );

        final field = find.text('Pick a date').first;
        await tester.ensureVisible(field);
        await tester.tap(field);
        await tester.pumpAndSettle();
        await tester.tap(find.text('10').last);
        await tester.tap(find.text('Done'));
        await tester.pumpAndSettle();

        expect(find.text('Add a start and end date.'), findsNothing);
      },
    );

    testWidgets('with both dates it creates the memory', (tester) async {
      final tripRepo = await _pumpWithRouter(tester);

      await _nameAndSubmit(tester);
      await tester.pumpAndSettle();

      expect(tripRepo.createTripCallCount, 1);
      expect(find.text('Add a start and end date.'), findsNothing);
    });
  });

  testWidgets('submits successfully and pops the page', (tester) async {
    final tripRepo = FakeTripRepository()
      ..tripsResult = const Right([])
      ..delay = const Duration(milliseconds: 50);
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: ElevatedButton(
              onPressed: () => context.push('/create'),
              child: const Text('open'),
            ),
          ),
        ),
        GoRoute(
          path: '/create',
          builder: (context, state) => const CreateMemoryPage(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tripRepositoryProvider.overrideWithValue(tripRepo),
          // Free by default — the memory-limit pre-check is tier-aware (#267).
          subscriptionRepositoryProvider.overrideWithValue(
            FakeSubscriptionRepository(),
          ),
        ],
        child: MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).first,
      'Summer in Tokyo',
    );
    await _pickDates(tester);
    final submitButton = find.widgetWithText(ElevatedButton, 'Create memory');
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();

    expect(tripRepo.createTripCallCount, 1);
    expect(find.byType(CreateMemoryPage), findsNothing);
  });

  testWidgets(
    'hitting the free-tier memory limit shows an Upgrade action, not a '
    'dead-end error (#139)',
    (tester) async {
      final tripRepo = FakeTripRepository()
        ..tripsResult = Right([
          buildTripCard(id: 't1'),
          buildTripCard(id: 't2'),
          buildTripCard(id: 't3'),
        ]);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tripRepositoryProvider.overrideWithValue(tripRepo),
            // Free by default — the memory-limit pre-check is tier-aware (#267).
            subscriptionRepositoryProvider.overrideWithValue(
              FakeSubscriptionRepository(),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.dark,
            home: const CreateMemoryPage(),
          ),
        ),
      );

      await tester.enterText(
        find.byType(TextFormField).first,
        'One too many',
      );
      await _pickDates(tester);
      final submitButton = find.widgetWithText(
        ElevatedButton,
        'Create memory',
      );
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      expect(tripRepo.createTripCallCount, 0); // blocked before the network
      expect(find.widgetWithText(SnackBarAction, 'Upgrade'), findsOneWidget);
    },
  );

  testWidgets(
    'tapping the Upgrade action on the limit snackbar opens the offerings '
    'screen',
    (tester) async {
      final tripRepo = FakeTripRepository()
        ..tripsResult = Right([
          buildTripCard(id: 't1'),
          buildTripCard(id: 't2'),
          buildTripCard(id: 't3'),
        ]);
      final router = GoRouter(
        initialLocation: RoutePaths.createMemory,
        routes: [
          GoRoute(
            path: RoutePaths.createMemory,
            builder: (context, state) => const CreateMemoryPage(),
          ),
          GoRoute(
            path: RoutePaths.subscriptionOfferings,
            name: RouteNames.subscriptionOfferings,
            builder: (context, state) =>
                const Scaffold(body: Text('Offerings screen')),
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tripRepositoryProvider.overrideWithValue(tripRepo),
            // Free by default — the memory-limit pre-check is tier-aware (#267).
            subscriptionRepositoryProvider.overrideWithValue(
              FakeSubscriptionRepository(),
            ),
          ],
          child: MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
        ),
      );

      await tester.enterText(
        find.byType(TextFormField).first,
        'One too many',
      );
      await _pickDates(tester);
      final submitButton = find.widgetWithText(
        ElevatedButton,
        'Create memory',
      );
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(SnackBarAction, 'Upgrade'));
      await tester.pumpAndSettle();

      expect(find.text('Offerings screen'), findsOneWidget);
    },
  );
}

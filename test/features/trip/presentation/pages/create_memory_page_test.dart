import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:traviato/core/theme/app_theme.dart';
import 'package:traviato/features/trip/presentation/pages/create_memory_page.dart';
import 'package:traviato/features/trip/presentation/providers/trip_providers.dart';

import '../../../trip/fakes/fake_trip_repository.dart';

Future<FakeTripRepository> _pump(WidgetTester tester) async {
  final tripRepo = FakeTripRepository()..tripsResult = const Right([]);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [tripRepositoryProvider.overrideWithValue(tripRepo)],
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
      overrides: [tripRepositoryProvider.overrideWithValue(tripRepo)],
      child: MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return tripRepo;
}

Future<void> _nameAndSubmit(WidgetTester tester) async {
  await tester.enterText(
    find.byType(TextFormField).first,
    'Summer in Tokyo',
  );
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
          'asset:honeymoon_escape',
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
        overrides: [tripRepositoryProvider.overrideWithValue(tripRepo)],
        child: MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).first,
      'Summer in Tokyo',
    );
    final submitButton = find.widgetWithText(ElevatedButton, 'Create memory');
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();

    expect(tripRepo.createTripCallCount, 1);
    expect(find.byType(CreateMemoryPage), findsNothing);
  });
}

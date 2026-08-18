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

  testWidgets('toggles vibe chip selection', (tester) async {
    await _pump(tester);

    final chip = find.text('Adventure');
    await tester.ensureVisible(chip);
    expect(chip, findsOneWidget);

    await tester.tap(chip);
    await tester.pump();
    // Tapping again deselects — no exception, no crash, chip still present.
    await tester.tap(chip);
    await tester.pump();

    expect(chip, findsOneWidget);
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

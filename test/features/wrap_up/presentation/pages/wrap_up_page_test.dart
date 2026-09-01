import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:traviato/core/errors/failures.dart';
import 'package:traviato/core/theme/app_theme.dart';
import 'package:traviato/features/photo/presentation/providers/photo_providers.dart';
import 'package:traviato/features/trip/presentation/providers/trip_providers.dart';
import 'package:traviato/features/wrap_up/domain/entities/wrap_up_route_chapter.dart';
import 'package:traviato/features/wrap_up/domain/entities/wrap_up_route_stop.dart';
import 'package:traviato/features/wrap_up/presentation/pages/wrap_up_page.dart';
import 'package:traviato/features/wrap_up/presentation/providers/wrap_up_providers.dart';

import '../../../photo/fakes/fake_photo_repository.dart';
import '../../../trip/fakes/fake_trip_repository.dart';
import '../../fakes/fake_wrap_up_repository.dart';

Future<void> _pump(
  WidgetTester tester, {
  required FakeWrapUpRepository wrapUpRepo,
  FakeTripRepository? tripRepo,
  FakePhotoRepository? photoRepo,
}) async {
  final router = GoRouter(
    initialLocation: '/wrap-up',
    routes: [
      GoRoute(
        path: '/wrap-up',
        builder: (context, state) => const WrapUpPage(tripId: 't1'),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const Scaffold(body: Text('Home')),
      ),
      GoRoute(
        path: '/memory/:tripId/journal',
        builder: (context, state) => const Scaffold(body: Text('Journal')),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      // Riverpod 3's default auto-retry-on-error would otherwise leave the
      // failure test stuck in a loading state until retries exhaust.
      retry: (_, _) => null,
      overrides: [
        wrapUpRepositoryProvider.overrideWithValue(wrapUpRepo),
        tripRepositoryProvider.overrideWithValue(
          tripRepo ??
              (FakeTripRepository()
                ..tripCardResult = Right(buildTripCard(id: 't1'))),
        ),
        photoRepositoryProvider.overrideWithValue(
          photoRepo ?? (FakePhotoRepository()..photosResult = const Right([])),
        ),
      ],
      child: MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
    ),
  );
}

/// The hero/photo-beat blocks run an infinite `kenburns` ticker, so
/// `pumpAndSettle` (which waits for *no* scheduled frames) hangs forever once
/// they're in the tree. Pump a bounded number of frames instead — enough to
/// flush the fakes' async chain without waiting on an animation that never
/// stops.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump();
  }
}

/// Content past the ~640px hero is below the default test viewport and
/// isn't laid out (so plain `find.text` treats it as offstage) until
/// scrolled into view — same pattern as journal_page_test.dart.
Future<void> _scrollToVisible(WidgetTester tester, Finder finder) {
  return tester.dragUntilVisible(
    finder,
    find.byType(Scrollable),
    const Offset(0, -400),
  );
}

void main() {
  testWidgets('shows the generating view while loading, then the content', (
    tester,
  ) async {
    final wrapUpRepo = FakeWrapUpRepository()
      ..delay = const Duration(milliseconds: 500);
    await _pump(tester, wrapUpRepo: wrapUpRepo);

    await tester.pump();
    expect(find.text('Reliving your trip…'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 500));
    await _settle(tester);
    expect(find.text('Dolomites, slowly'), findsOneWidget);
  });

  testWidgets('renders only the blocks present, skipping the rest', (
    tester,
  ) async {
    final wrapUpRepo = FakeWrapUpRepository()
      ..getOrGenerateResult = Right(buildWrapUpEntity());
    await _pump(tester, wrapUpRepo: wrapUpRepo);
    await _settle(tester);

    expect(find.text('Dolomites, slowly'), findsOneWidget);
    expect(find.textContaining('CHAPTER ONE'), findsNothing);
    expect(find.textContaining('CHAPTER THREE'), findsNothing);

    final closeLine = find.text("This one you'll keep.");
    await _scrollToVisible(tester, closeLine);
    expect(closeLine, findsOneWidget);
  });

  testWidgets(
    'a single-stop route chapter (a trip that never left one place) '
    'renders without error',
    (tester) async {
      final wrapUpRepo = FakeWrapUpRepository()
        ..getOrGenerateResult = Right(
          buildWrapUpEntity(
            routeChapter: WrapUpRouteChapter(
              intro: 'You never left the lake.',
              stops: [
                WrapUpRouteStop(
                  placeText: 'Loch Ness',
                  dayDate: DateTime(2026, 6, 1),
                ),
              ],
              stopCount: 1,
            ),
          ),
        );
      await _pump(tester, wrapUpRepo: wrapUpRepo);
      await _settle(tester);

      final placeLabel = find.textContaining('LOCH NESS');
      await _scrollToVisible(tester, placeLabel);

      expect(tester.takeException(), isNull);
      expect(placeLabel, findsOneWidget);
    },
  );

  testWidgets('tapping Keep forever publishes and shows the kept badge', (
    tester,
  ) async {
    final wrapUpRepo = FakeWrapUpRepository();
    await _pump(tester, wrapUpRepo: wrapUpRepo);
    await _settle(tester);

    final keepForever = find.text('Keep forever');
    await _scrollToVisible(tester, keepForever);
    expect(keepForever, findsOneWidget);

    await tester.tap(keepForever);
    await _settle(tester);

    expect(wrapUpRepo.publishCallCount, 1);
    expect(find.text('✦ Kept forever'), findsOneWidget);
  });

  testWidgets('shows a retry scaffold on failure', (tester) async {
    final wrapUpRepo = FakeWrapUpRepository()
      ..getOrGenerateResult = const Left(
        AuthenticationFailure(message: 'Session expired.'),
      );
    await _pump(tester, wrapUpRepo: wrapUpRepo);
    await _settle(tester);

    expect(find.text('Session expired.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}

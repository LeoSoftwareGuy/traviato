import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:traviato/core/config/router/route_constants.dart';
import 'package:traviato/core/errors/failures.dart';
import 'package:traviato/core/events/global_event.dart';
import 'package:traviato/core/events/global_event_bus.dart';
import 'package:traviato/core/theme/app_theme.dart';
import 'package:traviato/features/photo/presentation/providers/photo_providers.dart';
import 'package:traviato/features/wrap_up/domain/entities/wrap_up_cover_photo.dart';
import 'package:traviato/features/wrap_up/presentation/film/wrap_up_film_canvas.dart';
import 'package:traviato/features/wrap_up/presentation/pages/wrap_up_page.dart';
import 'package:traviato/features/wrap_up/presentation/providers/wrap_up_providers.dart';

import '../../../photo/fakes/fake_photo_repository.dart';
import '../../fakes/fake_wrap_up_repository.dart';

Future<void> _pump(
  WidgetTester tester, {
  required FakeWrapUpRepository wrapUpRepo,
  FakePhotoRepository? photoRepo,
  GlobalEventBus? eventBus,
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
        name: RouteNames.home,
        builder: (context, state) => const Scaffold(body: Text('Home')),
      ),
      GoRoute(
        path: '/memory/:tripId/journal',
        name: RouteNames.tripJournal,
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
        photoRepositoryProvider.overrideWithValue(
          photoRepo ?? (FakePhotoRepository()..photosResult = const Right([])),
        ),
        if (eventBus != null)
          globalEventBusProvider.overrideWithValue(eventBus),
      ],
      child: MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
    ),
  );
}

/// The HUD (close/Open journal/Keep forever) renders as soon as the wrap-up
/// data loads — independent of the film canvas's own asset-prep future —
/// so a bounded pump loop is enough for it. Never `pumpAndSettle`: once the
/// canvas mounts it runs an infinite looping `AnimationController`, which
/// `pumpAndSettle` (waits for *no* scheduled frames) would hang on forever.
Future<void> _settle(WidgetTester tester, {int iterations = 10}) async {
  for (var i = 0; i < iterations; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  testWidgets('shows the generating view while loading, then the HUD', (
    tester,
  ) async {
    final wrapUpRepo = FakeWrapUpRepository()
      ..delay = const Duration(milliseconds: 500);
    await _pump(tester, wrapUpRepo: wrapUpRepo);

    await tester.pump();
    expect(find.text('Reliving your trip…'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 500));
    await _settle(tester);
    expect(find.text('Keep forever'), findsOneWidget);
  });

  testWidgets(
    'the film canvas receives the loaded wrap-up content once assets prep',
    (tester) async {
      // No cover path and no photo urls means asset prep has nothing to
      // precache but the grain tile, so it resolves within a normal
      // fake-async pump loop.
      final wrapUpRepo = FakeWrapUpRepository()
        ..getOrGenerateResult = Right(
          buildWrapUpEntity(coverPhoto: const WrapUpCoverPhoto()),
        );
      await _pump(tester, wrapUpRepo: wrapUpRepo);
      await _settle(tester);
      // `WrapUpFilmGrain.generate()`'s `decodeImageFromPixels` callback is a
      // real engine completion that fake-async `pump()` never drives on its
      // own (same category as real network/asset IO) — let real time pass
      // once to flush it, then pump to apply the resulting rebuild.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await _settle(tester);

      final canvas = tester.widget<WrapUpFilmCanvas>(
        find.byType(WrapUpFilmCanvas),
      );
      expect(canvas.wrapUp.invitation.line1, 'Five days.');
    },
  );

  testWidgets('tapping Keep forever publishes and shows the kept badge', (
    tester,
  ) async {
    final wrapUpRepo = FakeWrapUpRepository();
    await _pump(tester, wrapUpRepo: wrapUpRepo);
    await _settle(tester);

    final keepForever = find.text('Keep forever');
    expect(keepForever, findsOneWidget);

    await tester.tap(keepForever);
    await _settle(tester);

    expect(wrapUpRepo.publishCallCount, 1);
    expect(find.text('✦ Kept forever'), findsOneWidget);
  });

  testWidgets(
    'publishing echoes WrapUpPublishedDispatched so Home can update live',
    (tester) async {
      final wrapUpRepo = FakeWrapUpRepository();
      final bus = GlobalEventBus();
      addTearDown(bus.dispose);
      final events = <GlobalEvent>[];
      final sub = bus.stream.listen(events.add);
      addTearDown(sub.cancel);

      await _pump(tester, wrapUpRepo: wrapUpRepo, eventBus: bus);
      await _settle(tester);

      await tester.tap(find.text('Keep forever'));
      await _settle(tester);

      expect(events, hasLength(1));
      final event = events.single as WrapUpPublishedDispatched;
      expect(event.tripId, 't1');
    },
  );

  testWidgets('tapping Open journal navigates to the trip journal', (
    tester,
  ) async {
    final wrapUpRepo = FakeWrapUpRepository();
    await _pump(tester, wrapUpRepo: wrapUpRepo);
    await _settle(tester);

    await tester.tap(find.text('Open journal'));
    await _settle(tester);

    expect(find.text('Journal'), findsOneWidget);
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

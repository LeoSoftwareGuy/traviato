import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:traviato/core/config/router/route_constants.dart';
import 'package:traviato/core/theme/app_theme.dart';
import 'package:traviato/features/home/domain/entities/profile_stats_entity.dart';
import 'package:traviato/features/home/presentation/providers/profile_stats_provider.dart';
import 'package:traviato/features/journal/presentation/pages/journal_page.dart';
import 'package:traviato/features/journal/presentation/providers/day_note_providers.dart';
import 'package:traviato/features/photo/presentation/providers/photo_providers.dart';
import 'package:traviato/features/quest/presentation/providers/quest_providers.dart';
import 'package:traviato/features/subscription/presentation/providers/subscription_providers.dart';
import 'package:traviato/features/trip/presentation/providers/trip_providers.dart';

import '../../../home/fakes/fake_profile_stats_repository.dart';
import '../../../photo/fakes/fake_photo_repository.dart';
import '../../../quest/fakes/fake_quest_repository.dart';
import '../../../subscription/fakes/fake_subscription_repository.dart';
import '../../../trip/fakes/fake_trip_repository.dart';
import '../../fakes/fake_day_note_repository.dart';

DateTime get _today {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

Future<void> _pump(
  WidgetTester tester, {
  required FakeTripRepository tripRepo,
  required FakePhotoRepository photoRepo,
  required FakeDayNoteRepository noteRepo,
  FakeQuestRepository? questRepo,
  FakeProfileStatsRepository? profileStatsRepo,
  FakeSubscriptionRepository? subscriptionRepo,
}) async {
  final router = GoRouter(
    initialLocation: '/journal',
    routes: [
      GoRoute(
        path: '/journal',
        builder: (context, state) => const JournalPage(tripId: 't1'),
      ),
      GoRoute(
        path: '/back',
        builder: (context, state) => const Scaffold(body: Text('back')),
      ),
      GoRoute(
        path: '/memory/:tripId/wrap-up',
        name: RouteNames.tripWrapUp,
        builder: (context, state) => const Scaffold(body: Text('Wrap-up')),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tripRepositoryProvider.overrideWithValue(tripRepo),
        photoRepositoryProvider.overrideWithValue(photoRepo),
        dayNoteRepositoryProvider.overrideWithValue(noteRepo),
        questRepositoryProvider.overrideWithValue(
          questRepo ?? FakeQuestRepository(),
        ),
        profileStatsRepositoryProvider.overrideWithValue(
          profileStatsRepo ?? FakeProfileStatsRepository(),
        ),
        subscriptionRepositoryProvider.overrideWithValue(
          subscriptionRepo ?? FakeSubscriptionRepository(),
        ),
      ],
      child: MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
    ),
  );
}

void main() {
  testWidgets('renders day tabs and the current note', (tester) async {
    final tripRepo = FakeTripRepository()
      ..tripCardResult = Right(
        buildTripCard(
          id: 't1',
          name: 'Cabin 2026',
          startDate: _today.subtract(const Duration(days: 1)),
          endDate: _today.add(const Duration(days: 1)),
        ),
      );
    final photoRepo = FakePhotoRepository()
      ..photosResult = Right([buildPhotoEntity(id: 'p1', dayDate: _today)]);
    final noteRepo = FakeDayNoteRepository()
      ..getNoteResult = Right(buildDayNoteEntity(content: 'Great day.'))
      ..notesForTripResult = Right([
        buildDayNoteEntity(dayDate: _today, content: 'Great day.'),
      ]);
    await _pump(
      tester,
      tripRepo: tripRepo,
      photoRepo: photoRepo,
      noteRepo: noteRepo,
    );
    await tester.pumpAndSettle();

    expect(find.text('JOURNAL'), findsOneWidget);
    expect(find.textContaining('Cabin 2026'), findsOneWidget);
    expect(find.text('Great day.'), findsOneWidget);
    // The note starts in view mode — no editable field until it's tapped.
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('shows the blocking message for a memory with no dates', (
    tester,
  ) async {
    final tripRepo = FakeTripRepository()
      ..tripCardResult = Right(buildTripCard(id: 't1'));
    final photoRepo = FakePhotoRepository();
    final noteRepo = FakeDayNoteRepository();
    await _pump(
      tester,
      tripRepo: tripRepo,
      photoRepo: photoRepo,
      noteRepo: noteRepo,
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Add dates to this memory to start your journal.'),
      findsOneWidget,
    );
  });

  testWidgets('tapping the add prompt, typing, and saving persists the note', (
    tester,
  ) async {
    final tripRepo = FakeTripRepository()
      ..tripCardResult = Right(
        buildTripCard(
          id: 't1',
          startDate: _today.subtract(const Duration(days: 1)),
          endDate: _today.add(const Duration(days: 1)),
        ),
      );
    // At least one photo, so the day isn't "empty" (#140) and the normal
    // note-prompt flow under test actually renders instead of the nudge.
    final photoRepo = FakePhotoRepository()
      ..photosResult = Right([buildPhotoEntity(id: 'p1', dayDate: _today)]);
    final noteRepo = FakeDayNoteRepository();
    await _pump(
      tester,
      tripRepo: tripRepo,
      photoRepo: photoRepo,
      noteRepo: noteRepo,
    );
    await tester.pumpAndSettle();

    expect(find.text('Add notes about today'), findsOneWidget);
    await tester.tap(find.byKey(const Key('journal-note-add-prompt')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('journal-note-field')),
      'What a trip.',
    );
    await tester.tap(find.byKey(const Key('journal-note-save')));
    await tester.pump(); // one frame: view-mode flip + toast are synchronous

    expect(noteRepo.upsertNoteCallCount, 1);
    expect(noteRepo.lastUpsertedContent, 'What a trip.');
    // Back to view mode, showing the just-saved content.
    expect(find.byType(TextField), findsNothing);
    expect(find.text('What a trip.'), findsOneWidget);
    expect(find.text('✦ +1 star · note logged'), findsOneWidget);

    await tester.pumpAndSettle(); // let the toast's own timer finish cleanly
  });

  testWidgets('cancelling an edit discards it and keeps the old content', (
    tester,
  ) async {
    final tripRepo = FakeTripRepository()
      ..tripCardResult = Right(
        buildTripCard(
          id: 't1',
          startDate: _today.subtract(const Duration(days: 1)),
          endDate: _today.add(const Duration(days: 1)),
        ),
      );
    final photoRepo = FakePhotoRepository()
      ..photosResult = Right([buildPhotoEntity(id: 'p1', dayDate: _today)]);
    final noteRepo = FakeDayNoteRepository()
      ..getNoteResult = Right(buildDayNoteEntity(content: 'Great day.'))
      ..notesForTripResult = Right([
        buildDayNoteEntity(dayDate: _today, content: 'Great day.'),
      ]);
    await _pump(
      tester,
      tripRepo: tripRepo,
      photoRepo: photoRepo,
      noteRepo: noteRepo,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('journal-note-view')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('journal-note-field')),
      'Scribbled over it.',
    );
    await tester.tap(find.byKey(const Key('journal-note-cancel')));
    await tester.pumpAndSettle();

    expect(noteRepo.upsertNoteCallCount, 0);
    expect(find.text('Great day.'), findsOneWidget);
    expect(find.text('Scribbled over it.'), findsNothing);
  });

  testWidgets('shows saved photos for the current day', (tester) async {
    final tripRepo = FakeTripRepository()
      ..tripCardResult = Right(
        buildTripCard(
          id: 't1',
          startDate: _today,
          endDate: _today,
        ),
      );
    final photoRepo = FakePhotoRepository()
      ..photosResult = Right([
        buildPhotoEntity(id: 'p1', dayDate: _today),
        buildPhotoEntity(id: 'p2', dayDate: _today),
      ]);
    final noteRepo = FakeDayNoteRepository();
    await _pump(
      tester,
      tripRepo: tripRepo,
      photoRepo: photoRepo,
      noteRepo: noteRepo,
    );
    await tester.pumpAndSettle();

    expect(find.text('2 saved'), findsOneWidget);
  });

  testWidgets(
    'tapping a photo tile opens the day-scoped viewer at that index (#117)',
    (tester) async {
      final tripRepo = FakeTripRepository()
        ..tripCardResult = Right(
          buildTripCard(id: 't1', startDate: _today, endDate: _today),
        );
      final photoRepo = FakePhotoRepository()
        ..photosResult = Right([
          buildPhotoEntity(id: 'p1', dayDate: _today),
          buildPhotoEntity(id: 'p2', dayDate: _today),
        ]);
      final noteRepo = FakeDayNoteRepository();
      await _pump(
        tester,
        tripRepo: tripRepo,
        photoRepo: photoRepo,
        noteRepo: noteRepo,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('journal-photo-tile-p2')));
      await tester.pumpAndSettle();

      expect(find.text('2 / 2'), findsOneWidget);
    },
  );

  testWidgets('tapping the Add tile opens the photo capture entry sheet', (
    tester,
  ) async {
    final tripRepo = FakeTripRepository()
      ..tripCardResult = Right(
        buildTripCard(id: 't1', startDate: _today, endDate: _today),
      );
    final photoRepo = FakePhotoRepository()..photosResult = const Right([]);
    // A note (no photos yet) keeps the day non-"empty" (#140), so the
    // normal photo strip under test renders instead of the nudge.
    final noteRepo = FakeDayNoteRepository()
      ..notesForTripResult = Right([buildDayNoteEntity(dayDate: _today)]);
    await _pump(
      tester,
      tripRepo: tripRepo,
      photoRepo: photoRepo,
      noteRepo: noteRepo,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('journal-add-photo')));
    await tester.pumpAndSettle();

    expect(find.text('Add a photo'), findsOneWidget);
    expect(find.text('Take a photo'), findsOneWidget);
    expect(find.text('Choose from gallery'), findsOneWidget);
  });

  testWidgets('the To Do sheet check-off toggles the quest', (tester) async {
    final tripRepo = FakeTripRepository()
      ..tripCardResult = Right(
        buildTripCard(
          id: 't1',
          startDate: _today,
          endDate: _today,
        ),
      );
    final photoRepo = FakePhotoRepository();
    final noteRepo = FakeDayNoteRepository();
    final quest = buildQuestEntity(
      id: 'q1',
      dayDate: _today,
      title: 'Pack the car',
    );
    final questRepo = FakeQuestRepository()..questsResult = Right([quest]);
    await _pump(
      tester,
      tripRepo: tripRepo,
      photoRepo: photoRepo,
      noteRepo: noteRepo,
      questRepo: questRepo,
    );
    await tester.pumpAndSettle();

    await tester.dragUntilVisible(
      find.byKey(const Key('journal-to-do-action')),
      find.byKey(const Key('journal-content-list')),
      const Offset(0, -200),
    );
    await tester.tap(find.byKey(const Key('journal-to-do-action')));
    await tester.pumpAndSettle();

    expect(find.text('Pack the car'), findsOneWidget);

    await tester.tap(find.byKey(const Key('quest-check-q1')));
    await tester.pumpAndSettle();

    expect(questRepo.toggleCallCount, 1);
  });

  testWidgets(
    'the View wrap-up button navigates to Wrap-up once unlocked (#94, #103)',
    (tester) async {
      // Trip has ended and meets the wrap-up content minimum (>=5 photos,
      // >=1 note, docs/design/M6_MONETIZATION_SPEC.md §3) — see
      // JournalState.wrapUpAvailability.
      final tripRepo = FakeTripRepository()
        ..tripCardResult = Right(
          buildTripCard(id: 't1', startDate: _today, endDate: _today),
        );
      final photoRepo = FakePhotoRepository()
        ..photosResult = Right([
          for (var i = 0; i < 5; i++)
            buildPhotoEntity(id: 'p$i', dayDate: _today),
        ]);
      final noteRepo = FakeDayNoteRepository()
        ..notesForTripResult = Right([
          buildDayNoteEntity(id: 'n1', dayDate: _today),
        ]);
      await _pump(
        tester,
        tripRepo: tripRepo,
        photoRepo: photoRepo,
        noteRepo: noteRepo,
      );
      await tester.pumpAndSettle();

      await tester.dragUntilVisible(
        find.byKey(const Key('journal-view-wrap-up-action')),
        find.byKey(const Key('journal-content-list')),
        const Offset(0, -200),
      );
      await tester.tap(find.byKey(const Key('journal-view-wrap-up-action')));
      await tester.pumpAndSettle();

      expect(find.text('Wrap-up'), findsOneWidget);
    },
  );

  testWidgets(
    'View wrap-up is hidden while the trip has not ended yet (#103)',
    (tester) async {
      final tripRepo = FakeTripRepository()
        ..tripCardResult = Right(
          buildTripCard(
            id: 't1',
            startDate: _today,
            endDate: _today.add(const Duration(days: 2)),
          ),
        );
      final photoRepo = FakePhotoRepository()..photosResult = const Right([]);
      final noteRepo = FakeDayNoteRepository();
      await _pump(
        tester,
        tripRepo: tripRepo,
        photoRepo: photoRepo,
        noteRepo: noteRepo,
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('journal-view-wrap-up-action')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('journal-view-wrap-up-locked')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'View wrap-up shows disabled with helper copy once ended but under '
    'the content minimum (#103)',
    (tester) async {
      final tripRepo = FakeTripRepository()
        ..tripCardResult = Right(
          buildTripCard(id: 't1', startDate: _today, endDate: _today),
        );
      final photoRepo = FakePhotoRepository()
        ..photosResult = Right([buildPhotoEntity(id: 'p1', dayDate: _today)]);
      final noteRepo = FakeDayNoteRepository()
        ..notesForTripResult = Right([
          buildDayNoteEntity(id: 'n1', dayDate: _today),
        ]);
      await _pump(
        tester,
        tripRepo: tripRepo,
        photoRepo: photoRepo,
        noteRepo: noteRepo,
      );
      await tester.pumpAndSettle();

      await tester.dragUntilVisible(
        find.byKey(const Key('journal-view-wrap-up-locked')),
        find.byKey(const Key('journal-content-list')),
        const Offset(0, -200),
      );

      expect(
        find.byKey(const Key('journal-view-wrap-up-action')),
        findsNothing,
      );
      expect(
        find.text(
          'Your film needs a little more to work with. Add 4 more '
          'photos to unlock it.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    "the header's stars badge shows the account's real total, not 0 (#105)",
    (tester) async {
      final tripRepo = FakeTripRepository()
        ..tripCardResult = Right(
          buildTripCard(
            id: 't1',
            startDate: _today.subtract(const Duration(days: 1)),
            endDate: _today.add(const Duration(days: 1)),
          ),
        );
      final photoRepo = FakePhotoRepository()..photosResult = const Right([]);
      final noteRepo = FakeDayNoteRepository();
      final profileStatsRepo = FakeProfileStatsRepository()
        ..statsResult = const Right(
          ProfileStatsEntity(
            memories: 1,
            places: 0,
            countries: 0,
            days: 0,
            stars: 42,
            photos: 0,
            notes: 0,
          ),
        );
      await _pump(
        tester,
        tripRepo: tripRepo,
        photoRepo: photoRepo,
        noteRepo: noteRepo,
        profileStatsRepo: profileStatsRepo,
      );
      await tester.pumpAndSettle();

      expect(find.text('42'), findsOneWidget);
    },
  );

  // docs/design/M6_MONETIZATION_SPEC.md §8 test matrix (#140).
  testWidgets(
    'Pro, 3 photos, 1 note → still locked — paying never bypasses the '
    'content gate (§0)',
    (tester) async {
      final tripRepo = FakeTripRepository()
        ..tripCardResult = Right(
          buildTripCard(id: 't1', startDate: _today, endDate: _today),
        );
      final photoRepo = FakePhotoRepository()
        ..photosResult = Right([
          for (var i = 0; i < 3; i++)
            buildPhotoEntity(id: 'p$i', dayDate: _today),
        ]);
      final noteRepo = FakeDayNoteRepository()
        ..notesForTripResult = Right([
          buildDayNoteEntity(id: 'n1', dayDate: _today),
        ]);
      final subscriptionRepo = FakeSubscriptionRepository()
        ..entitlementResult = Right(buildProEntitlement());
      await _pump(
        tester,
        tripRepo: tripRepo,
        photoRepo: photoRepo,
        noteRepo: noteRepo,
        subscriptionRepo: subscriptionRepo,
      );
      await tester.pumpAndSettle();

      await tester.dragUntilVisible(
        find.byKey(const Key('journal-view-wrap-up-locked')),
        find.byKey(const Key('journal-content-list')),
        const Offset(0, -200),
      );

      expect(
        find.byKey(const Key('journal-view-wrap-up-action')),
        findsNothing,
      );
      expect(find.byKey(const Key('wrap-up-explainer-card')), findsOneWidget);
      expect(
        find.textContaining("Nothing to buy"),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'an empty day shows the nudge card and no photo grid or note card',
    (tester) async {
      final tripRepo = FakeTripRepository()
        ..tripCardResult = Right(
          buildTripCard(id: 't1', startDate: _today, endDate: _today),
        );
      final photoRepo = FakePhotoRepository()..photosResult = const Right([]);
      final noteRepo = FakeDayNoteRepository();
      await _pump(
        tester,
        tripRepo: tripRepo,
        photoRepo: photoRepo,
        noteRepo: noteRepo,
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('empty-day-nudge')), findsOneWidget);
      expect(find.textContaining('a quiet one'), findsOneWidget);
      expect(find.textContaining('No photos, no notes yet'), findsOneWidget);
      expect(find.byKey(const Key('journal-add-photo')), findsNothing);
      expect(find.byKey(const Key('journal-note-add-prompt')), findsNothing);
    },
  );

  testWidgets(
    'an empty day looks identical for a Pro user — no upsell in the nudge',
    (tester) async {
      final tripRepo = FakeTripRepository()
        ..tripCardResult = Right(
          buildTripCard(id: 't1', startDate: _today, endDate: _today),
        );
      final photoRepo = FakePhotoRepository()..photosResult = const Right([]);
      final noteRepo = FakeDayNoteRepository();
      final subscriptionRepo = FakeSubscriptionRepository()
        ..entitlementResult = Right(buildProEntitlement());
      await _pump(
        tester,
        tripRepo: tripRepo,
        photoRepo: photoRepo,
        noteRepo: noteRepo,
        subscriptionRepo: subscriptionRepo,
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('empty-day-nudge')), findsOneWidget);
      expect(find.textContaining('Upgrade'), findsNothing);
      expect(find.textContaining(r'$'), findsNothing);
    },
  );

  testWidgets('a day with a photo shows no empty-day nudge', (tester) async {
    final tripRepo = FakeTripRepository()
      ..tripCardResult = Right(
        buildTripCard(id: 't1', startDate: _today, endDate: _today),
      );
    final photoRepo = FakePhotoRepository()
      ..photosResult = Right([buildPhotoEntity(id: 'p1', dayDate: _today)]);
    final noteRepo = FakeDayNoteRepository();
    await _pump(
      tester,
      tripRepo: tripRepo,
      photoRepo: photoRepo,
      noteRepo: noteRepo,
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('empty-day-nudge')), findsNothing);
  });

  testWidgets(
    'the empty-day nudge\'s Write a note action reveals the normal note '
    'editor',
    (tester) async {
      final tripRepo = FakeTripRepository()
        ..tripCardResult = Right(
          buildTripCard(id: 't1', startDate: _today, endDate: _today),
        );
      final photoRepo = FakePhotoRepository()..photosResult = const Right([]);
      final noteRepo = FakeDayNoteRepository();
      await _pump(
        tester,
        tripRepo: tripRepo,
        photoRepo: photoRepo,
        noteRepo: noteRepo,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('empty-day-nudge-write-note')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('empty-day-nudge')), findsNothing);
      expect(find.text('Add notes about today'), findsOneWidget);
    },
  );
}

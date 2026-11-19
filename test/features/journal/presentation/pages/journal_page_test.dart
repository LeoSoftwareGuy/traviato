import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:traviato/core/config/router/route_constants.dart';
import 'package:traviato/core/errors/failures.dart';
import 'package:traviato/core/theme/app_theme.dart';
import 'package:traviato/core/widgets/app_bottom_nav_bar.dart';
import 'package:traviato/features/home/domain/entities/profile_stats_entity.dart';
import 'package:traviato/features/home/presentation/providers/profile_stats_provider.dart';
import 'package:traviato/features/journal/presentation/pages/journal_page.dart';
import 'package:traviato/features/journal/presentation/widgets/journal_action_buttons.dart';
import 'package:traviato/features/journal/presentation/providers/journal_note_providers.dart';
import 'package:traviato/features/photo/domain/entities/photo_entity.dart';
import 'package:traviato/features/photo/presentation/providers/photo_providers.dart';
import 'package:traviato/features/quest/domain/entities/quest_entity.dart';
import 'package:traviato/features/quest/presentation/providers/quest_providers.dart';
import 'package:traviato/features/subscription/presentation/providers/subscription_providers.dart';
import 'package:traviato/features/trip/presentation/providers/trip_providers.dart';

import '../../../home/fakes/fake_profile_stats_repository.dart';
import '../../../photo/fakes/fake_photo_repository.dart';
import '../../../quest/fakes/fake_quest_repository.dart';
import '../../../subscription/fakes/fake_subscription_repository.dart';
import '../../../trip/fakes/fake_trip_repository.dart';
import '../../fakes/fake_journal_note_repository.dart';

DateTime get _today {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

Future<void> _pump(
  WidgetTester tester, {
  required FakeTripRepository tripRepo,
  required FakePhotoRepository photoRepo,
  required FakeJournalNoteRepository noteRepo,
  FakeQuestRepository? questRepo,
  FakeProfileStatsRepository? profileStatsRepo,
  FakeSubscriptionRepository? subscriptionRepo,
}) async {
  // A tall phone, so a whole day's timeline is laid out (#401).
  tester.view
    ..physicalSize = const Size(390 * 3, 1600 * 3)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
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
        journalNoteRepositoryProvider.overrideWithValue(noteRepo),
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
    final noteRepo = FakeJournalNoteRepository()
      ..notesForTripResult = Right([
        buildJournalNoteEntity(dayDate: _today, content: 'Great day.'),
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
    final noteRepo = FakeJournalNoteRepository();
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

  group('timeline notes (#401)', () {
    final dayWithPhoto = Right<Failure, List<PhotoEntity>>([
      buildPhotoEntity(id: 'p1', dayDate: _today),
    ]);

    FakeTripRepository threeDayTrip() =>
        FakeTripRepository()
          ..tripCardResult = Right(
            buildTripCard(
              id: 't1',
              startDate: _today.subtract(const Duration(days: 1)),
              endDate: _today.add(const Duration(days: 1)),
            ),
          );

    Future<void> pumpDay(
      WidgetTester tester,
      FakeJournalNoteRepository noteRepo,
    ) async {
      await _pump(
        tester,
        tripRepo: threeDayTrip(),
        photoRepo: FakePhotoRepository()..photosResult = dayWithPhoto,
        noteRepo: noteRepo,
      );
      await tester.pumpAndSettle();
    }

    Future<void> openNewAndType(WidgetTester tester, String text) async {
      await tester.tap(find.byKey(const Key('capture-note')));
      await tester.pumpAndSettle(); // the full turn
      await tester.enterText(find.byKey(const Key('note-page-field')), text);
      await tester.pump();
    }

    Future<void> longPressNote(WidgetTester tester, String id) async {
      await tester.longPress(find.byKey(Key('timeline-note-$id')));
      await tester.pumpAndSettle();
    }

    FakeJournalNoteRepository repoWith(List<String> contents) {
      final notes = [
        for (var i = 0; i < contents.length; i++)
          buildJournalNoteEntity(
            id: 'n${i + 1}',
            dayDate: _today,
            content: contents[i],
            createdAt: _today.add(Duration(hours: 9 + i)),
          ),
      ];
      return FakeJournalNoteRepository()..notesForTripResult = Right(notes);
    }

    testWidgets('the capsule opens an empty NEW page for the day', (
      tester,
    ) async {
      await pumpDay(tester, repoWith(['Great day.']));

      expect(find.byType(TextField), findsNothing);
      await tester.tap(find.byKey(const Key('capture-note')));
      await tester.pumpAndSettle();

      final field = find.byKey(const Key('note-page-field'));
      expect(tester.widget<TextField>(field).controller!.text, isEmpty);
      expect(find.textContaining('· NEW NOTE ·'), findsOneWidget);
    });

    testWidgets('every Done saves a separate note, with the star toast '
        'after the book closes', (tester) async {
      final noteRepo = repoWith(['Great day.']);
      await pumpDay(tester, noteRepo);

      await openNewAndType(tester, '  What a trip.  ');
      await tester.tap(find.byKey(const Key('note-page-done')));
      await tester.pump(); // the close starts ticking
      await tester.pump(const Duration(milliseconds: 400)); // mid-close
      expect(noteRepo.createNoteCallCount, 0);
      expect(find.text('+1 ✦ · note saved'), findsNothing);

      await tester.pump(const Duration(milliseconds: 600)); // route popped
      await tester.pump();
      expect(noteRepo.createNoteCallCount, 1);
      expect(noteRepo.updateNoteCallCount, 0);
      expect(noteRepo.lastUpsertedContent, 'What a trip.');
      expect(noteRepo.lastCreatedDay, isNotNull);
      expect(find.text('+1 ✦ · note saved'), findsOneWidget);

      await tester.pump();
      expect(find.text('Great day.'), findsOneWidget);
      expect(find.text('What a trip.'), findsOneWidget);
      expect(find.text('JUST NOW'), findsOneWidget);

      await tester.pumpAndSettle(const Duration(seconds: 4));
      expect(find.text('JUST NOW'), findsNothing);
    });

    testWidgets('a 4th note of the day says "Note saved" with no star', (
      tester,
    ) async {
      final noteRepo = repoWith(['One.', 'Two.', 'Three.']);
      await pumpDay(tester, noteRepo);

      await openNewAndType(tester, 'Four.');
      await tester.tap(find.byKey(const Key('note-page-done')));
      await tester.pumpAndSettle();

      expect(noteRepo.createNoteCallCount, 1);
      expect(find.text('+1 ✦ · note saved'), findsNothing);
    });

    testWidgets('notes sit on the timeline in time order', (tester) async {
      await pumpDay(tester, repoWith(['Morning.', 'Evening.']));

      final morning = tester.getTopLeft(find.text('Morning.')).dy;
      final evening = tester.getTopLeft(find.text('Evening.')).dy;
      expect(morning, lessThan(evening));
      expect(find.textContaining('2 notes'), findsOneWidget);
      expect(find.textContaining('1 photo'), findsOneWidget);
    });

    testWidgets('long-press → Edit edits that note, with no star', (
      tester,
    ) async {
      final noteRepo = repoWith(['Great day.']);
      await pumpDay(tester, noteRepo);

      await longPressNote(tester, 'n1');
      await tester.tap(find.byKey(const Key('note-sheet-edit')));
      await tester.pumpAndSettle();
      final field = find.byKey(const Key('note-page-field'));
      expect(tester.widget<TextField>(field).controller!.text, 'Great day.');
      expect(find.textContaining('· EDIT NOTE ·'), findsOneWidget);
      await tester.enterText(field, 'Great day. Fixed a typo.');
      await tester.tap(find.byKey(const Key('note-page-done')));
      await tester.pumpAndSettle();

      expect(noteRepo.createNoteCallCount, 0);
      expect(noteRepo.lastUpdatedNoteId, 'n1');
      expect(noteRepo.lastUpsertedContent, 'Great day. Fixed a typo.');
      expect(find.textContaining('note saved'), findsNothing);
      expect(find.text('Great day. Fixed a typo.'), findsOneWidget);
    });

    testWidgets('Done on an unchanged note saves nothing', (tester) async {
      final noteRepo = repoWith(['Great day.']);
      await pumpDay(tester, noteRepo);

      await longPressNote(tester, 'n1');
      await tester.tap(find.byKey(const Key('note-sheet-edit')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('note-page-done')));
      await tester.pumpAndSettle();

      expect(noteRepo.upsertNoteCallCount, 0);
      expect(noteRepo.deleteNoteCallCount, 0);
    });

    testWidgets('clearing a note on its page and confirming deletes it '
        '(#276)', (tester) async {
      final noteRepo = repoWith(['Great day.', 'Then rain.']);
      await pumpDay(tester, noteRepo);

      await longPressNote(tester, 'n1');
      await tester.tap(find.byKey(const Key('note-sheet-edit')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('note-page-field')), '');
      await tester.tap(find.byKey(const Key('note-page-done')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('note-page-delete-note')));
      await tester.pumpAndSettle();

      expect(noteRepo.lastDeletedNoteId, 'n1');
      expect(noteRepo.upsertNoteCallCount, 0);
      expect(find.text('Great day.'), findsNothing);
      expect(find.text('Then rain.'), findsOneWidget);
    });

    testWidgets('long-press → Delete asks; Keep keeps it, Delete removes it', (
      tester,
    ) async {
      final noteRepo = repoWith(['Great day.']);
      await pumpDay(tester, noteRepo);

      await longPressNote(tester, 'n1');
      await tester.tap(find.byKey(const Key('note-sheet-delete')));
      await tester.pumpAndSettle();
      expect(find.textContaining('note?'), findsOneWidget);
      await tester.tap(find.byKey(const Key('note-delete-keep')));
      await tester.pumpAndSettle();
      expect(noteRepo.deleteNoteCallCount, 0);
      expect(find.text('Great day.'), findsOneWidget);

      await longPressNote(tester, 'n1');
      await tester.tap(find.byKey(const Key('note-sheet-delete')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('note-delete-confirm')));
      await tester.pumpAndSettle();

      expect(noteRepo.lastDeletedNoteId, 'n1');
      expect(find.text('Great day.'), findsNothing);
    });

    testWidgets('a deleted note folds away before it leaves (#407)', (
      tester,
    ) async {
      final noteRepo = repoWith(['Great day.', 'Then rain.']);
      await pumpDay(tester, noteRepo);

      await longPressNote(tester, 'n1');
      await tester.tap(find.byKey(const Key('note-sheet-delete')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('note-delete-confirm')));
      await tester.pump(); // the sheet starts closing
      await tester.pump(const Duration(milliseconds: 300)); // sheet gone
      // Mid-fold: the delete is under way, the card is still leaving.
      expect(noteRepo.deleteNoteCallCount, 1);
      await tester.pump(const Duration(milliseconds: 100)); // fold done
      await tester.pump();

      expect(find.text('Great day.'), findsNothing);
      expect(find.text('Then rain.'), findsOneWidget);
      expect(find.text('Note deleted'), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('on iOS a left swipe on a note offers Delete (#407)', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final noteRepo = repoWith(['Great day.']);
      await pumpDay(tester, noteRepo);

      await tester.drag(
        find.byKey(const Key('timeline-note-n1')),
        const Offset(-120, 0),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('note-swipe-delete')));
      await tester.pumpAndSettle();
      expect(find.textContaining('note?'), findsOneWidget);
      await tester.tap(find.byKey(const Key('note-delete-confirm')));
      await tester.pumpAndSettle();

      expect(noteRepo.lastDeletedNoteId, 'n1');
      expect(find.text('Great day.'), findsNothing);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('a failed delete puts the note back', (tester) async {
      final noteRepo = repoWith(['Great day.', 'Then rain.'])
        ..deleteNoteResult = const Left(NetworkFailure());
      await pumpDay(tester, noteRepo);

      await longPressNote(tester, 'n1');
      await tester.tap(find.byKey(const Key('note-sheet-delete')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('note-delete-confirm')));
      await tester.pumpAndSettle();

      expect(noteRepo.deleteNoteCallCount, 1);
      expect(find.text('Great day.'), findsOneWidget);
    });

    testWidgets('Done with an empty draft writes nothing and shows no toast', (
      tester,
    ) async {
      final noteRepo = repoWith(['Great day.']);
      await pumpDay(tester, noteRepo);

      await openNewAndType(tester, '   ');
      await tester.tap(find.byKey(const Key('note-page-done')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('note-page-field')), findsNothing);
      expect(noteRepo.upsertNoteCallCount, 0);
      expect(find.textContaining('note saved'), findsNothing);
    });

    testWidgets('Cancel with text asks first; Discard saves nothing', (
      tester,
    ) async {
      final noteRepo = repoWith(['Great day.']);
      await pumpDay(tester, noteRepo);

      await openNewAndType(tester, 'Scribbled.');
      await tester.tap(find.byKey(const Key('note-page-cancel')));
      await tester.pumpAndSettle();
      expect(find.text('Discard your changes?'), findsOneWidget);
      await tester.tap(find.byKey(const Key('note-page-discard')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('note-page-field')), findsNothing);
      expect(noteRepo.upsertNoteCallCount, 0);
    });

    testWidgets('a long note folds to 4 lines and "more" opens it', (
      tester,
    ) async {
      await pumpDay(tester, repoWith(['A long day. ' * 40]));

      expect(find.byKey(const Key('timeline-note-collapsed')), findsOneWidget);
      await tester.tap(find.byKey(const Key('timeline-note-more')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('timeline-note-collapsed')), findsNothing);
      expect(find.text('less'), findsOneWidget);
    });
  });

  group('photo notes (#402)', () {
    Future<FakeJournalNoteRepository> openPhoto(
      WidgetTester tester, {
      List<String> notesOnPhoto = const [],
    }) async {
      final noteRepo = FakeJournalNoteRepository()
        ..notesForTripResult = Right([
          for (var i = 0; i < notesOnPhoto.length; i++)
            buildJournalNoteEntity(
              id: 'pn$i',
              dayDate: _today,
              content: notesOnPhoto[i],
              photoId: 'p1',
              createdAt: _today.add(Duration(hours: 9, minutes: i)),
            ),
        ]);
      await _pump(
        tester,
        tripRepo: FakeTripRepository()
          ..tripCardResult = Right(
            buildTripCard(id: 't1', startDate: _today, endDate: _today),
          ),
        photoRepo: FakePhotoRepository()
          ..photosResult = Right([
            buildPhotoEntity(id: 'p1', dayDate: _today, caption: 'Canal'),
          ]),
        noteRepo: noteRepo,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('timeline-photo-p1')));
      await tester.pumpAndSettle();
      return noteRepo;
    }

    testWidgets('a photo without notes says so', (tester) async {
      await openPhoto(tester);

      expect(find.byKey(const Key('photo-notes-panel')), findsOneWidget);
      expect(find.text('No notes on this photo yet.'), findsOneWidget);
    });

    testWidgets("the viewer lists the photo's notes", (tester) async {
      await openPhoto(tester, notesOnPhoto: ['Ducks.', 'More ducks.']);

      expect(find.text('NOTES ON THIS PHOTO · 2'), findsOneWidget);
      final panel = find.byKey(const Key('photo-notes-panel'));
      expect(
        find.descendant(of: panel, matching: find.text('Ducks.')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: panel, matching: find.text('More ducks.')),
        findsOneWidget,
      );
    });

    testWidgets('Add a note writes it on the photo; it shows under the '
        'photo and on the timeline', (tester) async {
      final noteRepo = await openPhoto(tester);

      await tester.tap(find.byKey(const Key('photo-notes-add')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('note-page-attached-photo')), findsOneWidget);
      expect(find.textContaining('· PHOTO NOTE ·'), findsOneWidget);
      expect(
        find.text('What was happening here? Type, or tap the mic.'),
        findsOneWidget,
      );
      expect(find.text('Canal'), findsWidgets);

      await tester.enterText(
        find.byKey(const Key('note-page-field')),
        'Boats everywhere.',
      );
      await tester.tap(find.byKey(const Key('note-page-done')));
      await tester.pumpAndSettle();

      expect(noteRepo.lastCreatedPhotoId, 'p1');
      final panel = find.byKey(const Key('photo-notes-panel'));
      expect(
        find.descendant(of: panel, matching: find.text('Boats everywhere.')),
        findsOneWidget,
      );
      expect(find.text('NOTES ON THIS PHOTO · 1'), findsOneWidget);

      await tester.tap(find.byKey(const Key('photo-viewer-close')));
      await tester.pumpAndSettle();
      expect(find.text('Boats everywhere.'), findsOneWidget);
      expect(find.byKey(const Key('timeline-note-on-photo')), findsOneWidget);
      expect(find.byKey(const Key('timeline-photo-noted')), findsOneWidget);
    });
  });

  testWidgets('shows the day\'s photos on the timeline', (tester) async {
    final tripRepo = FakeTripRepository()
      ..tripCardResult = Right(
        buildTripCard(id: 't1', startDate: _today, endDate: _today),
      );
    final photoRepo = FakePhotoRepository()
      ..photosResult = Right([
        buildPhotoEntity(id: 'p1', dayDate: _today),
        buildPhotoEntity(id: 'p2', dayDate: _today),
      ]);
    await _pump(
      tester,
      tripRepo: tripRepo,
      photoRepo: photoRepo,
      noteRepo: FakeJournalNoteRepository(),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('timeline-photo-p1')), findsOneWidget);
    expect(find.byKey(const Key('timeline-photo-p2')), findsOneWidget);
    expect(find.textContaining('2 photos'), findsOneWidget);
  });

  testWidgets('a group of 5 photos shows 3 and "+2" opens the rest', (
    tester,
  ) async {
    final tripRepo = FakeTripRepository()
      ..tripCardResult = Right(
        buildTripCard(id: 't1', startDate: _today, endDate: _today),
      );
    final photoRepo = FakePhotoRepository()
      ..photosResult = Right([
        for (var i = 0; i < 5; i++)
          buildPhotoEntity(id: 'p$i', dayDate: _today),
      ]);
    await _pump(
      tester,
      tripRepo: tripRepo,
      photoRepo: photoRepo,
      noteRepo: FakeJournalNoteRepository(),
    );
    await tester.pumpAndSettle();

    expect(find.text('+2'), findsOneWidget);
    expect(find.byKey(const Key('timeline-photo-p4')), findsNothing);
    await tester.tap(find.byKey(const Key('timeline-photos-more')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('timeline-photo-p4')), findsOneWidget);
    await tester.tap(find.byKey(const Key('timeline-photos-less')));
    await tester.pumpAndSettle();
    expect(find.text('+2'), findsOneWidget);
  });

  testWidgets(
    'tapping a photo opens the day-scoped viewer at that index (#117)',
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
      await _pump(
        tester,
        tripRepo: tripRepo,
        photoRepo: photoRepo,
        noteRepo: FakeJournalNoteRepository(),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('timeline-photo-p2')));
      await tester.pumpAndSettle();

      expect(find.text('2 / 2'), findsOneWidget);
    },
  );

  testWidgets("the capsule's Photo opens the photo capture entry sheet", (
    tester,
  ) async {
    final tripRepo = FakeTripRepository()
      ..tripCardResult = Right(
        buildTripCard(id: 't1', startDate: _today, endDate: _today),
      );
    final photoRepo = FakePhotoRepository()..photosResult = const Right([]);
    // A note keeps the day non-empty, so the timeline and capsule show.
    final noteRepo = FakeJournalNoteRepository()
      ..notesForTripResult = Right([buildJournalNoteEntity(dayDate: _today)]);
    await _pump(
      tester,
      tripRepo: tripRepo,
      photoRepo: photoRepo,
      noteRepo: noteRepo,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('capture-photo')));
    await tester.pumpAndSettle();

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
    final noteRepo = FakeJournalNoteRepository();
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
      final noteRepo = FakeJournalNoteRepository()
        ..notesForTripResult = Right([
          buildJournalNoteEntity(id: 'n1', dayDate: _today),
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
      // Clear of the floating capture capsule.
      await tester.drag(
        find.byKey(const Key('journal-content-list')),
        const Offset(0, -400),
      );
      await tester.pumpAndSettle();
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
      final noteRepo = FakeJournalNoteRepository();
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
      final noteRepo = FakeJournalNoteRepository()
        ..notesForTripResult = Right([
          buildJournalNoteEntity(id: 'n1', dayDate: _today),
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
      final noteRepo = FakeJournalNoteRepository();
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
      final noteRepo = FakeJournalNoteRepository()
        ..notesForTripResult = Right([
          buildJournalNoteEntity(id: 'n1', dayDate: _today),
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

  group('day title (#186)', () {
    Future<void> pumpWithPhoto(
      WidgetTester tester, {
      required DateTime start,
      required DateTime end,
    }) async {
      final tripRepo = FakeTripRepository()
        ..tripCardResult = Right(
          buildTripCard(
            id: 't1',
            name: 'Cabin 2026',
            startDate: start,
            endDate: end,
          ),
        );
      final photoRepo = FakePhotoRepository()
        ..photosResult = Right([buildPhotoEntity(id: 'p1', dayDate: _today)]);
      await _pump(
        tester,
        tripRepo: tripRepo,
        photoRepo: photoRepo,
        noteRepo: FakeJournalNoteRepository(),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('a single-day memory shows the name with no "Day 1 —"', (
      tester,
    ) async {
      await pumpWithPhoto(tester, start: _today, end: _today);

      expect(find.text('Cabin 2026'), findsOneWidget);
      expect(find.textContaining('Day 1 —'), findsNothing);
    });

    testWidgets('a multi-day memory keeps the "Day N —" prefix', (
      tester,
    ) async {
      await pumpWithPhoto(
        tester,
        start: _today.subtract(const Duration(days: 1)),
        end: _today.add(const Duration(days: 1)),
      );

      expect(find.text('Day 2 — Cabin 2026'), findsOneWidget);
    });
  });

  testWidgets('an empty day shows the notebook page and no capsule', (
    tester,
  ) async {
    final tripRepo = FakeTripRepository()
      ..tripCardResult = Right(
        buildTripCard(id: 't1', startDate: _today, endDate: _today),
      );
    await _pump(
      tester,
      tripRepo: tripRepo,
      photoRepo: FakePhotoRepository()..photosResult = const Right([]),
      noteRepo: FakeJournalNoteRepository(),
    );
    await tester.pumpAndSettle();

    final weekday = DateFormat.EEEE('en').format(_today);
    expect(find.byKey(const Key('timeline-empty-day')), findsOneWidget);
    expect(find.text('Nothing written for $weekday yet'), findsOneWidget);
    expect(find.byKey(const Key('capture-capsule')), findsNothing);
    expect(find.byKey(const Key('journal-day-timeline')), findsNothing);
  });

  testWidgets(
    'an empty day looks identical for a Pro user — no upsell on the page',
    (tester) async {
      final tripRepo = FakeTripRepository()
        ..tripCardResult = Right(
          buildTripCard(id: 't1', startDate: _today, endDate: _today),
        );
      final subscriptionRepo = FakeSubscriptionRepository()
        ..entitlementResult = Right(buildProEntitlement());
      await _pump(
        tester,
        tripRepo: tripRepo,
        photoRepo: FakePhotoRepository()..photosResult = const Right([]),
        noteRepo: FakeJournalNoteRepository(),
        subscriptionRepo: subscriptionRepo,
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('timeline-empty-day')), findsOneWidget);
      expect(find.textContaining('Upgrade'), findsNothing);
      expect(find.textContaining(r'$'), findsNothing);
    },
  );

  testWidgets('a day with a photo shows the timeline and capsule', (
    tester,
  ) async {
    final tripRepo = FakeTripRepository()
      ..tripCardResult = Right(
        buildTripCard(id: 't1', startDate: _today, endDate: _today),
      );
    await _pump(
      tester,
      tripRepo: tripRepo,
      photoRepo: FakePhotoRepository()
        ..photosResult = Right([buildPhotoEntity(id: 'p1', dayDate: _today)]),
      noteRepo: FakeJournalNoteRepository(),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('timeline-empty-day')), findsNothing);
    expect(find.byKey(const Key('journal-day-timeline')), findsOneWidget);
    expect(find.byKey(const Key('capture-capsule')), findsOneWidget);
  });

  testWidgets('the Journal has no bottom bar; the capsule sits at the '
      'bottom on its own (#410)', (tester) async {
    await _pump(
      tester,
      tripRepo: FakeTripRepository()
        ..tripCardResult = Right(
          buildTripCard(id: 't1', startDate: _today, endDate: _today),
        ),
      photoRepo: FakePhotoRepository()
        ..photosResult = Right([buildPhotoEntity(id: 'p1', dayDate: _today)]),
      noteRepo: FakeJournalNoteRepository(),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AppBottomNavBar), findsNothing);
    final screen = tester.getSize(find.byType(JournalPage));
    final capsule = tester.getRect(find.byKey(const Key('capture-capsule')));
    expect(screen.height - capsule.bottom, lessThan(40));
  });

  testWidgets('the last row scrolls clear of the capsule (#410)', (
    tester,
  ) async {
    await _pump(
      tester,
      tripRepo: FakeTripRepository()
        ..tripCardResult = Right(
          buildTripCard(id: 't1', startDate: _today, endDate: _today),
        ),
      photoRepo: FakePhotoRepository()
        ..photosResult = Right([buildPhotoEntity(id: 'p1', dayDate: _today)]),
      noteRepo: FakeJournalNoteRepository(),
    );
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const Key('journal-content-list')),
      const Offset(0, -3000),
    );
    await tester.pumpAndSettle();

    final capsule = tester.getRect(find.byKey(const Key('capture-capsule')));
    final last = tester.getRect(find.byType(JournalActionButtons));
    expect(last.bottom, lessThan(capsule.top));
  });

  testWidgets('the empty day\'s Write the first note opens the note page', (
    tester,
  ) async {
    final tripRepo = FakeTripRepository()
      ..tripCardResult = Right(
        buildTripCard(id: 't1', startDate: _today, endDate: _today),
      );
    final noteRepo = FakeJournalNoteRepository();
    await _pump(
      tester,
      tripRepo: tripRepo,
      photoRepo: FakePhotoRepository()..photosResult = const Right([]),
      noteRepo: noteRepo,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('timeline-empty-write')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('note-page-field')), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('note-page-field')),
      'First line.',
    );
    await tester.tap(find.byKey(const Key('note-page-done')));
    await tester.pumpAndSettle();

    expect(noteRepo.createNoteCallCount, 1);
    expect(find.text('First line.'), findsOneWidget);
    expect(find.byKey(const Key('timeline-empty-day')), findsNothing);
  });

  group('deleting a photo (#165)', () {
    Future<FakePhotoRepository> openViewerOnFirstPhoto(
      WidgetTester tester, {
      Either<Failure, void>? deleteResult,
      FakeProfileStatsRepository? profileStatsRepo,
    }) async {
      final tripRepo = FakeTripRepository()
        ..tripCardResult = Right(
          buildTripCard(id: 't1', startDate: _today, endDate: _today),
        );
      final photoRepo = FakePhotoRepository()
        ..photosResult = Right([
          buildPhotoEntity(id: 'p1', dayDate: _today),
          buildPhotoEntity(id: 'p2', dayDate: _today),
        ])
        ..deletePhotoResult = deleteResult;
      await _pump(
        tester,
        tripRepo: tripRepo,
        photoRepo: photoRepo,
        noteRepo: FakeJournalNoteRepository(),
        profileStatsRepo: profileStatsRepo,
      );
      await tester.pumpAndSettle();
      await tester.dragUntilVisible(
        find.byKey(const Key('timeline-photo-p1')),
        find.byKey(const Key('journal-content-list')),
        const Offset(0, -200),
      );
      await tester.tap(find.byKey(const Key('timeline-photo-p1')));
      await tester.pumpAndSettle();
      return photoRepo;
    }

    Future<void> deleteFromViewer(WidgetTester tester) async {
      await tester.tap(find.byKey(const Key('photo-viewer-delete')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('photo-delete-confirm')));
      await tester.pumpAndSettle();
    }

    Future<void> closeViewer(WidgetTester tester) async {
      await tester.tap(find.byKey(const Key('photo-viewer-close')));
      await tester.pumpAndSettle();
    }

    testWidgets('removes it from the timeline and the count immediately', (
      tester,
    ) async {
      final photoRepo = await openViewerOnFirstPhoto(tester);

      await deleteFromViewer(tester);
      await closeViewer(tester);

      expect(photoRepo.deletedPhotoIds, ['p1']);
      expect(find.byKey(const Key('timeline-photo-p1')), findsNothing);
      expect(find.byKey(const Key('timeline-photo-p2')), findsOneWidget);
      expect(find.textContaining('1 photo'), findsOneWidget);
    });

    testWidgets('refetches the star total, since the photo ✦2 is taken '
        'back', (tester) async {
      final statsRepo = FakeProfileStatsRepository();
      await openViewerOnFirstPhoto(tester, profileStatsRepo: statsRepo);
      final before = statsRepo.getStatsCallCount;

      await deleteFromViewer(tester);

      expect(statsRepo.getStatsCallCount, greaterThan(before));
    });

    testWidgets('a failed delete puts it back on the timeline', (tester) async {
      await openViewerOnFirstPhoto(
        tester,
        deleteResult: const Left(NetworkFailure()),
      );

      await deleteFromViewer(tester);
      await closeViewer(tester);

      expect(find.byKey(const Key('timeline-photo-p1')), findsOneWidget);
      expect(find.textContaining('2 photos'), findsOneWidget);
    });
  });

  group('long-press on a timeline photo (#424)', () {
    Future<FakePhotoRepository> pumpDay(
      WidgetTester tester, {
      Either<Failure, void>? deleteResult,
    }) async {
      final tripRepo = FakeTripRepository()
        ..tripCardResult = Right(
          buildTripCard(id: 't1', startDate: _today, endDate: _today),
        );
      final photoRepo = FakePhotoRepository()
        ..photosResult = Right([
          buildPhotoEntity(id: 'p1', dayDate: _today, caption: 'Canal boat'),
          buildPhotoEntity(id: 'p2', dayDate: _today),
        ])
        ..deletePhotoResult = deleteResult;
      await _pump(
        tester,
        tripRepo: tripRepo,
        photoRepo: photoRepo,
        noteRepo: FakeJournalNoteRepository(),
      );
      await tester.pumpAndSettle();
      await tester.dragUntilVisible(
        find.byKey(const Key('timeline-photo-p1')),
        find.byKey(const Key('journal-content-list')),
        const Offset(0, -200),
      );
      return photoRepo;
    }

    Future<void> longPressP1(WidgetTester tester) async {
      await tester.longPress(find.byKey(const Key('timeline-photo-p1')));
      await tester.pumpAndSettle();
    }

    testWidgets('opens the photo sheet with a preview, not the photo', (
      tester,
    ) async {
      await pumpDay(tester);

      await longPressP1(tester);

      expect(find.byKey(const Key('photo-sheet-preview')), findsOneWidget);
      expect(find.byKey(const Key('photo-sheet-delete')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('photo-sheet-preview')),
          matching: find.text('Canal boat'),
        ),
        findsOneWidget,
      );
      // The release didn't also open the viewer.
      expect(find.byKey(const Key('photo-viewer-close')), findsNothing);
    });

    testWidgets('Delete photo → confirm folds it away, updates the count '
        'and shows a toast', (tester) async {
      final photoRepo = await pumpDay(tester);

      await longPressP1(tester);
      await tester.tap(find.byKey(const Key('photo-sheet-delete')));
      await tester.pumpAndSettle();
      expect(find.text('Delete this photo?'), findsOneWidget);

      await tester.tap(find.byKey(const Key('photo-delete-confirm')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(const Key('fold-away')), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Photo deleted'), findsOneWidget);

      await tester.pumpAndSettle();
      expect(photoRepo.deletedPhotoIds, ['p1']);
      expect(find.byKey(const Key('timeline-photo-p1')), findsNothing);
      expect(find.byKey(const Key('timeline-photo-p2')), findsOneWidget);
      expect(find.textContaining('1 photo'), findsOneWidget);
    });

    testWidgets('Keep on the confirm leaves the photo', (tester) async {
      final photoRepo = await pumpDay(tester);

      await longPressP1(tester);
      await tester.tap(find.byKey(const Key('photo-sheet-delete')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('photo-delete-keep')));
      await tester.pumpAndSettle();

      expect(photoRepo.deletedPhotoIds, isEmpty);
      expect(find.byKey(const Key('timeline-photo-p1')), findsOneWidget);
    });

    testWidgets('Cancel closes the sheet and deletes nothing', (
      tester,
    ) async {
      final photoRepo = await pumpDay(tester);

      await longPressP1(tester);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('photo-sheet-preview')), findsNothing);
      expect(photoRepo.deletedPhotoIds, isEmpty);
    });

    testWidgets('a failed delete puts it back', (tester) async {
      await pumpDay(tester, deleteResult: const Left(NetworkFailure()));

      await longPressP1(tester);
      await tester.tap(find.byKey(const Key('photo-sheet-delete')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('photo-delete-confirm')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('timeline-photo-p1')), findsOneWidget);
      expect(find.textContaining('2 photos'), findsOneWidget);
    });

    testWidgets('a tap still opens the photo', (tester) async {
      await pumpDay(tester);

      await tester.tap(find.byKey(const Key('timeline-photo-p1')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('photo-viewer-close')), findsOneWidget);
    });
  });

  group('To Do visibility (#164)', () {
    Future<void> pumpWith(
      WidgetTester tester, {
      required DateTime startDate,
      required DateTime endDate,
      required DateTime createdAt,
      List<QuestEntity> quests = const [],
    }) async {
      final tripRepo = FakeTripRepository()
        ..tripCardResult = Right(
          buildTripCard(
            id: 't1',
            startDate: startDate,
            endDate: endDate,
            createdAt: createdAt,
          ),
        );
      await _pump(
        tester,
        tripRepo: tripRepo,
        photoRepo: FakePhotoRepository(),
        noteRepo: FakeJournalNoteRepository(),
        questRepo: FakeQuestRepository()..questsResult = Right(quests),
      );
      await tester.pumpAndSettle();
    }

    final toDo = find.byKey(
      const Key('journal-to-do-action'),
      skipOffstage: false,
    );

    testWidgets('is hidden for a memory logged after its trip ended', (
      tester,
    ) async {
      await pumpWith(
        tester,
        startDate: _today.subtract(const Duration(days: 20)),
        endDate: _today.subtract(const Duration(days: 15)),
        createdAt: _today.subtract(const Duration(days: 2)),
      );
      expect(toDo, findsNothing);
    });

    testWidgets('stays for a past-created memory that already has quests', (
      tester,
    ) async {
      final start = _today.subtract(const Duration(days: 20));
      await pumpWith(
        tester,
        startDate: start,
        endDate: _today.subtract(const Duration(days: 15)),
        createdAt: _today.subtract(const Duration(days: 2)),
        quests: [buildQuestEntity(dayDate: start)],
      );
      expect(toDo, findsOneWidget);
    });

    testWidgets('is shown for a memory created mid-trip (regression)', (
      tester,
    ) async {
      await pumpWith(
        tester,
        startDate: _today.subtract(const Duration(days: 2)),
        endDate: _today.add(const Duration(days: 2)),
        createdAt: _today,
      );
      expect(toDo, findsOneWidget);
    });

    testWidgets('is shown for an upcoming memory (regression)', (tester) async {
      await pumpWith(
        tester,
        startDate: _today.add(const Duration(days: 5)),
        endDate: _today.add(const Duration(days: 9)),
        createdAt: _today,
      );
      expect(toDo, findsOneWidget);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:traviato/core/theme/app_theme.dart';
import 'package:traviato/features/journal/presentation/pages/journal_page.dart';
import 'package:traviato/features/journal/presentation/providers/day_note_providers.dart';
import 'package:traviato/features/photo/presentation/providers/photo_providers.dart';
import 'package:traviato/features/quest/presentation/providers/quest_providers.dart';
import 'package:traviato/features/trip/presentation/providers/trip_providers.dart';

import '../../../photo/fakes/fake_photo_repository.dart';
import '../../../quest/fakes/fake_quest_repository.dart';
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
    final photoRepo = FakePhotoRepository()..photosResult = const Right([]);
    final noteRepo = FakeDayNoteRepository()
      ..getNoteResult = Right(buildDayNoteEntity(content: 'Great day.'));
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
    final photoRepo = FakePhotoRepository()..photosResult = const Right([]);
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
    final photoRepo = FakePhotoRepository()..photosResult = const Right([]);
    final noteRepo = FakeDayNoteRepository()
      ..getNoteResult = Right(buildDayNoteEntity(content: 'Great day.'));
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

  testWidgets('tapping the Add tile opens the photo capture entry sheet', (
    tester,
  ) async {
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
}

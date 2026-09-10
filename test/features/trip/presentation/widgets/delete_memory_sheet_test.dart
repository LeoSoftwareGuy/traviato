import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:traviato/core/theme/app_theme.dart';
import 'package:traviato/features/journal/presentation/providers/day_note_providers.dart';
import 'package:traviato/features/photo/presentation/providers/photo_providers.dart';
import 'package:traviato/features/trip/presentation/providers/trip_providers.dart';
import 'package:traviato/features/trip/presentation/widgets/delete_memory_sheet.dart';

import '../../../journal/fakes/fake_day_note_repository.dart';
import '../../../photo/fakes/fake_photo_repository.dart';
import '../../fakes/fake_trip_repository.dart';

Future<void> _pump(
  WidgetTester tester, {
  required FakeTripRepository tripRepo,
  FakePhotoRepository? photoRepo,
  FakeDayNoteRepository? noteRepo,
  String tripName = 'Atlas high road',
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tripRepositoryProvider.overrideWithValue(tripRepo),
        photoRepositoryProvider.overrideWithValue(
          photoRepo ?? FakePhotoRepository(),
        ),
        dayNoteRepositoryProvider.overrideWithValue(
          noteRepo ?? FakeDayNoteRepository(),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => DeleteMemorySheet.show(
                context,
                tripId: 't1',
                tripName: tripName,
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('opens delete-only, resting, no rename/cover controls', (
    tester,
  ) async {
    final tripRepo = FakeTripRepository();
    await _pump(tester, tripRepo: tripRepo, tripName: 'Atlas high road');

    expect(find.text('Delete this memory'), findsWidgets); // title + button
    expect(find.text('Atlas high road'), findsOneWidget);
    expect(find.text('Yes — delete it forever'), findsNothing);
    expect(find.text('Rename'), findsNothing);
    expect(find.text('COVER'), findsNothing);
  });

  testWidgets('delete arms on first tap, showing real photo/note counts', (
    tester,
  ) async {
    final tripRepo = FakeTripRepository();
    final photoRepo = FakePhotoRepository()
      ..photosResult = Right([
        buildPhotoEntity(id: 'p1'),
        buildPhotoEntity(id: 'p2'),
      ]);
    final noteRepo = FakeDayNoteRepository()
      ..notesForTripResult = Right([buildDayNoteEntity(id: 'n1')]);
    await _pump(
      tester,
      tripRepo: tripRepo,
      photoRepo: photoRepo,
      noteRepo: noteRepo,
    );

    await tester.tap(find.text('Delete this memory').last);
    await tester.pumpAndSettle();

    expect(find.text('Yes — delete it forever'), findsOneWidget);
    expect(
      find.textContaining('This removes 2 photos and 1 days of notes'),
      findsOneWidget,
    );
    expect(tripRepo.deleteTripCallCount, 0);
  });

  testWidgets('confirming delete deletes the trip and pops true', (
    tester,
  ) async {
    final tripRepo = FakeTripRepository()..deleteTripResult = const Right(null);
    await _pump(tester, tripRepo: tripRepo);

    await tester.tap(find.text('Delete this memory').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yes — delete it forever'));
    await tester.pumpAndSettle();

    expect(tripRepo.deleteTripCallCount, 1);
    // The sheet is gone — back to the button that opened it.
    expect(find.text('Open'), findsOneWidget);
    expect(find.text('Delete this memory'), findsNothing);
  });

  testWidgets('Cancel closes the sheet without deleting', (tester) async {
    final tripRepo = FakeTripRepository();
    await _pump(tester, tripRepo: tripRepo);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(tripRepo.deleteTripCallCount, 0);
    expect(find.text('Open'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:traviato/core/config/router/route_constants.dart';
import 'package:traviato/core/errors/failures.dart';
import 'package:traviato/core/theme/app_theme.dart';
import 'package:traviato/features/bonus/presentation/providers/bonus_task_providers.dart';
import 'package:traviato/features/journal/domain/entities/day_note_entity.dart';
import 'package:traviato/features/journal/presentation/providers/day_note_providers.dart';
import 'package:traviato/features/kept_memory/presentation/pages/kept_memory_page.dart';
import 'package:traviato/features/kept_memory/presentation/pages/kept_memory_viewer_page.dart';
import 'package:traviato/features/photo/domain/entities/photo_entity.dart';
import 'package:traviato/features/photo/presentation/providers/photo_providers.dart';
import 'package:traviato/features/quest/domain/entities/quest_entity.dart';
import 'package:traviato/features/quest/presentation/providers/quest_providers.dart';
import 'package:traviato/features/trip/domain/entities/trip_card_entity.dart';
import 'package:traviato/features/trip/presentation/providers/trip_providers.dart';
import 'package:traviato/features/wrap_up/domain/entities/wrap_up_moment.dart';
import 'package:traviato/features/wrap_up/presentation/providers/wrap_up_providers.dart';

import '../../../bonus/fakes/fake_bonus_task_repository.dart';
import '../../../journal/fakes/fake_day_note_repository.dart';
import '../../../photo/fakes/fake_photo_repository.dart';
import '../../../quest/fakes/fake_quest_repository.dart';
import '../../../trip/fakes/fake_trip_repository.dart';
import '../../../wrap_up/fakes/fake_wrap_up_repository.dart';

final _trip = buildTripCard(
  name: 'One long road',
  startDate: DateTime(2026, 8, 12),
  endDate: DateTime(2026, 8, 16),
  durationDays: 5,
  status: TripStatus.finished,
  stars: 46,
  wrapUpPublishedAt: DateTime(2026, 8, 17, 12),
);

// imageUrl stays null throughout: thumbs render their placeholder, so no
// test ever touches the network.
final _photos = [
  buildPhotoEntity(
    id: 'p1',
    dayDate: DateTime(2026, 8, 12),
    takenAt: DateTime(2026, 8, 12, 5, 48),
    caption: 'Up at five for it.',
  ),
  buildPhotoEntity(
    id: 'p2',
    dayDate: DateTime(2026, 8, 13),
    takenAt: DateTime(2026, 8, 13, 10),
  ),
  buildPhotoEntity(
    id: 'p3',
    dayDate: DateTime(2026, 8, 13),
    takenAt: DateTime(2026, 8, 13, 15),
  ),
];

final _notes = [
  buildDayNoteEntity(
    dayDate: DateTime(2026, 8, 12),
    content: 'Before either of us was awake.',
    createdAt: DateTime(2026, 8, 12, 21, 4),
  ),
  // Day 3 has a note and no photos.
  buildDayNoteEntity(
    id: 'n3',
    dayDate: DateTime(2026, 8, 14),
    content: 'Rain all day. Cards and soup.',
    createdAt: DateTime(2026, 8, 14, 20),
  ),
];

final _quests = [
  buildQuestEntity(
    dayDate: DateTime(2026, 8, 12),
    title: 'Sunrise at the loch',
    completedAt: DateTime(2026, 8, 12, 6),
  ),
  buildQuestEntity(
    id: 'q2',
    dayDate: DateTime(2026, 8, 13),
    title: 'Row across',
  ),
];

Future<void> _pump(
  WidgetTester tester, {
  List<PhotoEntity>? photos,
  List<DayNoteEntity>? notes,
  List<QuestEntity> quests = const [],
  Failure? tripFailure,
  FakeWrapUpRepository? wrapUpRepo,
}) async {
  tester.view.physicalSize = const Size(420, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final router = GoRouter(
    initialLocation: '/memory/t1',
    routes: [
      GoRoute(
        path: '/memory/:tripId',
        name: RouteNames.keptMemory,
        builder: (context, state) =>
            KeptMemoryPage(tripId: state.pathParameters['tripId']!),
      ),
      GoRoute(
        path: '/memory/:tripId/wrap-up',
        name: RouteNames.tripWrapUp,
        builder: (context, state) => Scaffold(
          body: Text('Film from=${state.uri.queryParameters['from']}'),
        ),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        tripRepositoryProvider.overrideWithValue(
          FakeTripRepository()
            ..tripCardResult = tripFailure == null
                ? Right(_trip)
                : Left(tripFailure),
        ),
        photoRepositoryProvider.overrideWithValue(
          FakePhotoRepository()..photosResult = Right(photos ?? _photos),
        ),
        dayNoteRepositoryProvider.overrideWithValue(
          FakeDayNoteRepository()..notesForTripResult = Right(notes ?? _notes),
        ),
        questRepositoryProvider.overrideWithValue(
          FakeQuestRepository()..questsResult = Right(quests),
        ),
        bonusTaskRepositoryProvider.overrideWithValue(
          FakeBonusTaskRepository(),
        ),
        wrapUpRepositoryProvider.overrideWithValue(
          wrapUpRepo ?? FakeWrapUpRepository(),
        ),
      ],
      child: MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the hero, every day chapter and every note', (
    tester,
  ) async {
    await _pump(tester, quests: _quests);

    expect(find.text('One long road'), findsOneWidget);
    expect(find.text('KEPT FOREVER · 12–16 AUG 2026'), findsOneWidget);
    // Counts match the content below.
    expect(find.text('5 DAYS · 3 PHOTOS · 2 NOTES · ✦46'), findsOneWidget);
    expect(find.text('DAY 1 · WED 12 AUG'), findsOneWidget);
    expect(find.text('DAY 2 · THU 13 AUG'), findsOneWidget);
    expect(find.text('1 PHOTO ›'), findsOneWidget);
    expect(find.text('2 PHOTOS ›'), findsOneWidget);
    // Notes in full, exactly as written, with their time.
    expect(find.text('“Before either of us was awake.”'), findsOneWidget);
    expect(find.text('21:04'), findsOneWidget);
    expect(find.text('KEPT FOREVER · SINCE 17 AUG 2026'), findsOneWidget);
    // The film's length, once its schedule is known.
    expect(
      find.descendant(
        of: find.byKey(const Key('kept-memory-play-film')),
        matching: find.textContaining(RegExp(r'^\d+:\d\d$')),
      ),
      findsOneWidget,
    );
  });

  testWidgets('a day with notes only has no strip and no photos link', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text('DAY 3 · FRI 14 AUG'), findsOneWidget);
    expect(find.text('“Rain all day. Cards and soup.”'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('kept-memory-day-photos-3')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('kept-memory-day-photos-1')), findsOne);
  });

  testWidgets('the plan is collapsed, then lists every quest read-only', (
    tester,
  ) async {
    await _pump(tester, quests: _quests);

    expect(find.text('The plan'), findsOneWidget);
    expect(find.text('1 OF 2 DONE'), findsOneWidget);
    expect(find.text('Sunrise at the loch'), findsNothing);

    await tester.tap(find.byKey(const Key('kept-memory-plan-toggle')));
    await tester.pumpAndSettle();

    expect(find.text('Sunrise at the loch'), findsOneWidget);
    expect(find.text('Row across'), findsOneWidget);
    expect(find.text('D2'), findsOneWidget);
  });

  testWidgets('without a plan, the plan card is left out', (tester) async {
    await _pump(tester);

    expect(find.text('The plan'), findsNothing);
  });

  testWidgets('tapping a thumb opens the viewer on that photo', (
    tester,
  ) async {
    await _pump(tester);

    await tester.tap(find.byKey(const ValueKey('kept-memory-thumb-p3')));
    await tester.pumpAndSettle();

    expect(find.byType(KeptMemoryViewerPage), findsOneWidget);
    expect(find.text('DAY 2 · 3 / 3'), findsOneWidget);
  });

  testWidgets('a day\'s photos link opens the viewer at its first photo', (
    tester,
  ) async {
    await _pump(tester);

    await tester.tap(find.byKey(const ValueKey('kept-memory-day-photos-2')));
    await tester.pumpAndSettle();

    expect(find.text('DAY 2 · 2 / 3'), findsOneWidget);
  });

  testWidgets('Play the film opens it so it leads back here', (tester) async {
    await _pump(tester);

    await tester.tap(find.byKey(const Key('kept-memory-play-film')));
    await tester.pumpAndSettle();

    expect(find.text('Film from=memory'), findsOneWidget);
  });

  testWidgets('with no photos, the slideshow is off', (tester) async {
    await _pump(tester, photos: const []);

    final slideshow = tester.widget<InkWell>(
      find.byKey(const Key('kept-memory-slideshow')),
    );
    expect(slideshow.onTap, isNull);
    expect(find.text('5 DAYS · 2 NOTES · ✦46'), findsOneWidget);
  });

  testWidgets('shows a retry scaffold when the memory fails to load', (
    tester,
  ) async {
    await _pump(
      tester,
      tripFailure: const NetworkFailure(),
    );

    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('a kept film whose photos changed offers a rebuild (#294)', (
    tester,
  ) async {
    await _pump(
      tester,
      wrapUpRepo: FakeWrapUpRepository()
        ..getOrGenerateResult = Right(
          buildWrapUpEntity(
            generatedAt: DateTime.utc(2026, 8, 17),
            publishedAt: DateTime.utc(2026, 8, 17, 12),
            // p9 was deleted after the film was kept.
            moments: const [WrapUpMoment(photoId: 'p9')],
          ),
        ),
    );

    expect(find.text('Photos changed · Rebuild film'), findsOneWidget);
  });

  testWidgets('an up-to-date kept film offers no rebuild', (tester) async {
    await _pump(tester);

    expect(find.byKey(const Key('film-out-of-date-chip')), findsNothing);
  });
}

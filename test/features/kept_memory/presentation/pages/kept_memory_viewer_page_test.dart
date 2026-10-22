import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/core/theme/app_theme.dart';
import 'package:traviato/features/bonus/domain/entities/bonus_task_assignment_entity.dart';
import 'package:traviato/features/bonus/domain/entities/bonus_task_template_entity.dart';
import 'package:traviato/features/kept_memory/domain/build_kept_memory.dart';
import 'package:traviato/features/kept_memory/domain/entities/kept_memory.dart';
import 'package:traviato/features/kept_memory/presentation/pages/kept_memory_viewer_page.dart';
import 'package:traviato/features/trip/domain/entities/trip_card_entity.dart';

import '../../../photo/fakes/fake_photo_repository.dart';
import '../../../trip/fakes/fake_trip_repository.dart';

/// Day 1: two photos (the first a bonus-task photo with a caption), day 2:
/// three photos — five in all.
KeptMemory _memory() => buildKeptMemory(
  trip: buildTripCard(
    startDate: DateTime(2026, 8, 12),
    endDate: DateTime(2026, 8, 13),
    durationDays: 2,
    status: TripStatus.finished,
  ),
  photos: [
    for (var i = 0; i < 5; i++)
      buildPhotoEntity(
        id: 'p$i',
        dayDate: DateTime(2026, 8, i < 2 ? 12 : 13),
        takenAt: DateTime(2026, 8, i < 2 ? 12 : 13, 8 + i),
        caption: i == 0 ? 'Up at five for it. Worth it.' : null,
      ),
  ],
  notes: const [],
  quests: const [],
  bonusTemplates: const [
    BonusTaskTemplateEntity(
      id: 1,
      code: 'unknown_code',
      title: 'Before the sun',
      points: 2,
      phase: BonusTaskPhase.anytime,
      kind: BonusTaskKind.regular,
    ),
  ],
  bonusAssignments: [
    BonusTaskAssignmentEntity(
      id: 'a1',
      tripId: 't1',
      templateId: 1,
      dayDate: DateTime(2026, 8, 12),
      completedAt: DateTime(2026, 8, 12, 8),
      photoId: 'p0',
      createdAt: DateTime(2026, 8, 12),
    ),
  ],
);

Future<void> _pump(
  WidgetTester tester, {
  int initialIndex = 0,
  bool autoplay = false,
  bool disableAnimations = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark,
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => KeptMemoryViewerPage.show(
              context,
              memory: _memory(),
              initialIndex: initialIndex,
              autoplay: autoplay,
            ),
            child: const Text('Memory page'),
          ),
        ),
      ),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(disableAnimations: disableAnimations),
        child: child!,
      ),
    ),
  );
  await tester.tap(find.text('Memory page'));
  // The viewer fades in over 200ms.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 250));
}

String _position(WidgetTester tester) => tester
    .widget<Text>(find.byKey(const Key('kept-memory-viewer-position')))
    .data!;

List<double> _fills(WidgetTester tester) => tester
    .widgetList<FractionallySizedBox>(find.byType(FractionallySizedBox))
    .map((box) => box.widthFactor!)
    .toList();

Future<void> _tapAt(WidgetTester tester, double fractionOfWidth) async {
  final stage = find.byKey(const Key('kept-memory-viewer-stage'));
  final rect = tester.getRect(stage);
  await tester.tapAt(
    Offset(rect.left + rect.width * fractionOfWidth, rect.center.dy),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  testWidgets('opens on the tapped photo, across every day', (tester) async {
    await _pump(tester, initialIndex: 3);

    expect(_position(tester), 'DAY 2 · 4 / 5');
    // One segment per day, sized by photo count, filled to the photo.
    expect(_fills(tester), [1.0, 2 / 3]);
  });

  testWidgets('the right two-thirds goes forward, the left third back', (
    tester,
  ) async {
    await _pump(tester, initialIndex: 1);

    await _tapAt(tester, .8);
    expect(_position(tester), 'DAY 2 · 3 / 5');

    await _tapAt(tester, .5);
    expect(_position(tester), 'DAY 2 · 4 / 5');

    await _tapAt(tester, .1);
    expect(_position(tester), 'DAY 2 · 3 / 5');
  });

  testWidgets('swiping moves between photos', (tester) async {
    await _pump(tester);

    await tester.fling(
      find.byKey(const Key('kept-memory-viewer-pager')),
      const Offset(-300, 0),
      1000,
    );
    await tester.pumpAndSettle();

    expect(_position(tester), 'DAY 1 · 2 / 5');
  });

  testWidgets('shows the bonus task, caption and date of the photo', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text('Dare · Before the sun · ✦2'), findsOneWidget);
    expect(find.text('Up at five for it. Worth it.'), findsOneWidget);
    expect(find.text('WED 12 AUG'), findsOneWidget);

    await _tapAt(tester, .8);
    expect(find.byKey(const Key('kept-memory-viewer-bonus')), findsNothing);
  });

  testWidgets('swiping down closes it', (tester) async {
    await _pump(tester);

    await tester.fling(
      find.byKey(const Key('kept-memory-viewer-stage')),
      const Offset(0, 300),
      1500,
    );
    await tester.pumpAndSettle();

    expect(find.byType(KeptMemoryViewerPage), findsNothing);
  });

  group('slideshow', () {
    testWidgets('advances every 3.2s and loops at the end', (tester) async {
      await _pump(tester, initialIndex: 3, autoplay: true);
      expect(find.text('❚❚ Pause'), findsOneWidget);

      await tester.pump(slideshowInterval);
      expect(_position(tester), 'DAY 2 · 5 / 5');

      await tester.pump(slideshowInterval);
      expect(_position(tester), 'DAY 1 · 1 / 5');
    });

    testWidgets('a manual move restarts the timer', (tester) async {
      await _pump(tester, autoplay: true);

      await tester.pump(const Duration(seconds: 2));
      await _tapAt(tester, .8);
      expect(_position(tester), 'DAY 1 · 2 / 5');

      // 2.4s after the tap: the old timer would have fired by now.
      await tester.pump(const Duration(seconds: 2));
      expect(_position(tester), 'DAY 1 · 2 / 5');

      await tester.pump(const Duration(milliseconds: 900));
      expect(_position(tester), 'DAY 2 · 3 / 5');
    });

    testWidgets('pausing stops it', (tester) async {
      await _pump(tester, autoplay: true);

      await tester.tap(find.byKey(const Key('kept-memory-viewer-play')));
      await tester.pump();
      expect(find.text('▶ Slideshow'), findsOneWidget);

      await tester.pump(slideshowInterval * 2);
      expect(_position(tester), 'DAY 1 · 1 / 5');
    });

    testWidgets('slowly zooms each photo', (tester) async {
      await _pump(tester, autoplay: true);

      expect(find.byType(TweenAnimationBuilder<double>), findsOneWidget);
    });

    testWidgets('under reduced motion, only crossfades', (tester) async {
      await _pump(tester, autoplay: true, disableAnimations: true);

      expect(find.byType(TweenAnimationBuilder<double>), findsNothing);
      await tester.pump(slideshowInterval);
      expect(_position(tester), 'DAY 1 · 2 / 5');
    });
  });
}

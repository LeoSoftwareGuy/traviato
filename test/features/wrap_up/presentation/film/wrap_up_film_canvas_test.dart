import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/wrap_up/domain/entities/wrap_up_collage_layout.dart';
import 'package:traviato/features/wrap_up/domain/entities/wrap_up_cover_photo.dart';
import 'package:traviato/features/wrap_up/domain/entities/wrap_up_dates.dart';
import 'package:traviato/features/wrap_up/domain/entities/wrap_up_entity.dart';
import 'package:traviato/features/wrap_up/domain/entities/wrap_up_film_cut.dart';
import 'package:traviato/features/wrap_up/domain/entities/wrap_up_flurry_leftovers.dart';
import 'package:traviato/features/wrap_up/domain/entities/wrap_up_footnote.dart';
import 'package:traviato/features/wrap_up/domain/entities/wrap_up_invitation.dart';
import 'package:traviato/features/wrap_up/domain/entities/wrap_up_keepsake.dart';
import 'package:traviato/features/wrap_up/domain/entities/wrap_up_moment.dart';
import 'package:traviato/features/wrap_up/domain/entities/wrap_up_photo_ref.dart';
import 'package:traviato/features/wrap_up/domain/entities/wrap_up_unlock.dart';
import 'package:traviato/features/wrap_up/presentation/film/frames/wrap_up_film_collage.dart';
import 'package:traviato/features/wrap_up/presentation/film/frames/wrap_up_film_plate.dart';
import 'package:traviato/features/wrap_up/presentation/film/wrap_up_film_canvas.dart';
import 'package:traviato/features/wrap_up/presentation/film/wrap_up_film_scenes.dart';

WrapUpEntity _entity({
  WrapUpFilmCut? cut,
  List<WrapUpMoment> moments = const [],
  WrapUpFlurryLeftovers flurryLeftovers = const WrapUpFlurryLeftovers(),
  WrapUpUnlock? unlock,
}) {
  return WrapUpEntity(
    cut: cut,
    dates: const WrapUpDates(formatted: '1–5 June 2026'),
    coverPhoto: const WrapUpCoverPhoto(),
    invitation: const WrapUpInvitation(
      line1: 'Five days.',
      line2: 'One long road.',
    ),
    bridges: const ['Bridge one.', 'Bridge two.', 'Bridge three.'],
    moments: moments,
    flurryLeftovers: flurryLeftovers,
    footnote: const WrapUpFootnote(
      photoCount: 3,
      bonusCompletedCount: 0,
      stars: 4,
    ),
    unlock: unlock,
    keepsake: const WrapUpKeepsake(
      titleLine1: 'A Trip',
      titleLine2: '',
      closingQuote: 'Kept.',
    ),
    generatedAt: DateTime(2026, 1, 1),
  );
}

Future<void> _scrub(WidgetTester tester, WrapUpEntity wrapUp) async {
  await tester.pumpWidget(
    MaterialApp(
      home: WrapUpFilmCanvas(
        wrapUp: wrapUp,
        photoUrlById: const {},
        coverImage: null,
        grainImage: null,
      ),
    ),
  );

  // Sample every scene boundary across the film without waiting in real
  // time — `pump(duration)` advances the AnimationController's clock
  // directly. Uses the same schedule the canvas derives, so the samples
  // match whatever this wrapUp actually cut.
  final scenes = WrapUpFilmScenes.forWrapUp(wrapUp);
  final hasFlurry2 = scenes.hasFlurry2;
  final hasUnlock = scenes.hasUnlock;

  var elapsed = 0.0;
  for (final target in [
    0.5,
    scenes.invitationStart + 0.1,
    for (final at in scenes.momentStarts) ...[at + 0.5, at + 2.0],
    if (scenes.hasFlurry1) scenes.flurry1Start + 1,
    if (hasFlurry2) scenes.flurry2Start + 1,
    scenes.footnoteStart + 1,
    if (hasUnlock) scenes.unlockStart + 1,
    scenes.keepsakeStart + 1,
    scenes.total - 0.1,
  ]) {
    final delta = target - elapsed;
    if (delta > 0) {
      await tester.pump(Duration(milliseconds: (delta * 1000).round()));
    }
    elapsed = target;
    expect(tester.takeException(), isNull, reason: 'at T=$target');
  }
}

void main() {
  testWidgets('zero bonus tasks completed: all moments have no badge', (
    tester,
  ) async {
    final moments = List.generate(
      8,
      (i) => WrapUpMoment(photoId: 'p$i', note: 'Note $i'),
    );
    await _scrub(tester, _entity(moments: moments));
    for (final m in moments) {
      expect(m.badge, isNull);
    }
  });

  testWidgets('fewer than 8 total photos renders without error', (
    tester,
  ) async {
    final moments = List.generate(
      3,
      (i) => WrapUpMoment(photoId: 'p$i', note: 'Note $i'),
    );
    await _scrub(tester, _entity(moments: moments));
  });

  testWidgets('fewer than 15 leftovers for a flurry renders without error', (
    tester,
  ) async {
    final leftovers = WrapUpFlurryLeftovers(
      photos: List.generate(5, (i) => WrapUpPhotoRef(photoId: 'l$i')),
    );
    await _scrub(tester, _entity(flurryLeftovers: leftovers));
  });

  testWidgets('a photo with no caption renders without a generated note', (
    tester,
  ) async {
    final moments = [
      const WrapUpMoment(photoId: 'p0', note: null),
      const WrapUpMoment(photoId: 'p1', note: 'Has a note'),
    ];
    await _scrub(tester, _entity(moments: moments));
  });

  testWidgets('zero photos and zero leftovers renders without error', (
    tester,
  ) async {
    await _scrub(tester, _entity());
  });

  testWidgets('more than 15 leftovers renders the Flurry2 frame', (
    tester,
  ) async {
    final leftovers = WrapUpFlurryLeftovers(
      photos: List.generate(20, (i) => WrapUpPhotoRef(photoId: 'l$i')),
    );
    await _scrub(tester, _entity(flurryLeftovers: leftovers));
  });

  testWidgets('an earned achievement renders the Unlock frame', (
    tester,
  ) async {
    const unlock = WrapUpUnlock(
      code: 'first_adventure',
      name: 'First Adventure',
      reason: 'You logged your first memory.',
    );
    await _scrub(tester, _entity(unlock: unlock));
  });

  group('#151 cuts and collages', () {
    List<WrapUpPhotoRef> refs(int n, String prefix) => [
      for (var i = 0; i < n; i++) WrapUpPhotoRef(photoId: '$prefix$i'),
    ];

    // A full-cut plan as the generator resolves it for 30 photos: M2
    // stack3, M5 torn4, M7 tilt6, M8 torn6, and one 7-card Flurry.
    WrapUpEntity fullPlan() {
      const layouts = <int, WrapUpCollageLayout>{
        1: WrapUpCollageLayout.stack3,
        4: WrapUpCollageLayout.torn4,
        6: WrapUpCollageLayout.tilt6,
        7: WrapUpCollageLayout.torn6,
      };
      return _entity(
        cut: WrapUpFilmCut.full,
        moments: [
          for (var i = 0; i < 8; i++)
            WrapUpMoment(
              photoId: 'm$i',
              note: 'Note $i',
              badge: i == 0 ? 'Dare · Snap anything · ✦1' : null,
              layout: layouts[i],
              collageExtras: layouts[i] == null
                  ? const []
                  : refs(layouts[i]!.tileCount - 1, 'x$i-'),
            ),
        ],
        flurryLeftovers: WrapUpFlurryLeftovers(
          photos: refs(7, 'f'),
          flurry1: refs(7, 'f'),
        ),
      );
    }

    Future<WrapUpFilmScenes> pumpCanvasAt(
      WidgetTester tester,
      WrapUpEntity wrapUp,
      double Function(WrapUpFilmScenes) timeOf, {
      bool collages = true,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: WrapUpFilmCanvas(
            wrapUp: wrapUp,
            photoUrlById: const {},
            coverImage: null,
            grainImage: null,
            collages: collages,
          ),
        ),
      );
      final scenes = WrapUpFilmScenes.forWrapUp(wrapUp);
      await tester.pump(
        Duration(milliseconds: (timeOf(scenes) * 1000).round()),
      );
      return scenes;
    }

    testWidgets('a collage moment plays as a collage, not a card flip', (
      tester,
    ) async {
      await pumpCanvasAt(tester, fullPlan(), (s) => s.momentStarts[4] + 0.5);
      // Only M5's torn4 is on screen: exactly four tiles rendered.
      expect(find.byKey(const ValueKey('collage-tile-3')), findsOneWidget);
      expect(find.byKey(const ValueKey('collage-tile-4')), findsNothing);
    });

    testWidgets('collages = false plays every moment as a card flip', (
      tester,
    ) async {
      await pumpCanvasAt(
        tester,
        fullPlan(),
        (s) => s.momentStarts[4] + 0.5,
        collages: false,
      );
      expect(find.byType(WrapUpFilmCollage), findsNothing);
      expect(find.byKey(const ValueKey('collage-tile-0')), findsNothing);
      // M5 is on screen as a print instead.
      expect(find.byType(WrapUpFilmPlate), findsWidgets);
    });

    testWidgets('collage moments never land in the card pile', (
      tester,
    ) async {
      // Just before the Footnote the pile holds every card-flip moment.
      await pumpCanvasAt(tester, fullPlan(), (s) => s.footnoteStart - 1.2);
      expect(find.byType(WrapUpFilmPlate), findsNWidgets(4));
    });

    testWidgets('with collages off, all 8 prints are in the pile', (
      tester,
    ) async {
      await pumpCanvasAt(
        tester,
        fullPlan(),
        (s) => s.footnoteStart - 1.2,
        collages: false,
      );
      expect(find.byType(WrapUpFilmPlate), findsNWidgets(8));
    });

    testWidgets('a full plan scrubs end to end without error', (
      tester,
    ) async {
      await _scrub(tester, fullPlan());
    });

    testWidgets('a highlight plan (5 flips, no Flurry) scrubs without error', (
      tester,
    ) async {
      await _scrub(
        tester,
        _entity(
          cut: WrapUpFilmCut.highlight,
          moments: [
            for (var i = 0; i < 5; i++)
              WrapUpMoment(photoId: 'm$i', note: 'Note $i'),
          ],
        ),
      );
    });
  });
}

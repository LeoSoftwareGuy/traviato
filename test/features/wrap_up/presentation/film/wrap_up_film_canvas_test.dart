import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/wrap_up/domain/entities/wrap_up_cover_photo.dart';
import 'package:traviato/features/wrap_up/domain/entities/wrap_up_dates.dart';
import 'package:traviato/features/wrap_up/domain/entities/wrap_up_entity.dart';
import 'package:traviato/features/wrap_up/domain/entities/wrap_up_flurry_leftovers.dart';
import 'package:traviato/features/wrap_up/domain/entities/wrap_up_footnote.dart';
import 'package:traviato/features/wrap_up/domain/entities/wrap_up_invitation.dart';
import 'package:traviato/features/wrap_up/domain/entities/wrap_up_keepsake.dart';
import 'package:traviato/features/wrap_up/domain/entities/wrap_up_moment.dart';
import 'package:traviato/features/wrap_up/domain/entities/wrap_up_photo_ref.dart';
import 'package:traviato/features/wrap_up/domain/entities/wrap_up_unlock.dart';
import 'package:traviato/features/wrap_up/presentation/film/wrap_up_film_canvas.dart';
import 'package:traviato/features/wrap_up/presentation/film/wrap_up_film_scenes.dart';

WrapUpEntity _entity({
  List<WrapUpMoment> moments = const [],
  WrapUpFlurryLeftovers flurryLeftovers = const WrapUpFlurryLeftovers(),
  WrapUpUnlock? unlock,
}) {
  return WrapUpEntity(
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
  // directly. Mirrors WrapUpFilmCanvas's own hasFlurry2/hasUnlock derivation
  // so the sampled schedule matches whatever this wrapUp actually cut.
  final hasFlurry2 = wrapUp.flurryLeftovers.photos.length > 15;
  final hasUnlock = wrapUp.unlock != null;
  final scenes = WrapUpFilmScenes(hasFlurry2: hasFlurry2, hasUnlock: hasUnlock);

  var elapsed = 0.0;
  for (final target in [
    0.5,
    scenes.invitationStart + 0.1,
    scenes.momentStarts.first,
    scenes.momentStarts.last + WrapUpFilmScenes.momentDurations.last - 0.1,
    scenes.flurry1Start + 1,
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
}

@Tags(['golden'])
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/wrap_up/domain/entities/wrap_up_collage_layout.dart';
import 'package:traviato/features/wrap_up/domain/entities/wrap_up_entity.dart';
import 'package:traviato/features/wrap_up/domain/entities/wrap_up_film_cut.dart';
import 'package:traviato/features/wrap_up/domain/entities/wrap_up_flurry_leftovers.dart';
import 'package:traviato/features/wrap_up/domain/entities/wrap_up_footnote.dart';
import 'package:traviato/features/wrap_up/domain/entities/wrap_up_keepsake.dart';
import 'package:traviato/features/wrap_up/domain/entities/wrap_up_moment.dart';
import 'package:traviato/features/wrap_up/domain/entities/wrap_up_photo_ref.dart';
import 'package:traviato/features/wrap_up/domain/entities/wrap_up_unlock.dart';
import 'package:traviato/features/wrap_up/presentation/film/wrap_up_film_canvas.dart';

import '../../fakes/fake_wrap_up_repository.dart';
import 'legacy_film_scenes_oracle.dart';

// Before/after screenshots of the film for the #344 timeline refactor: made
// on today's player, they must still match once the schedule is a list of
// scenes. Pixel output differs between Windows (where they're made) and the
// Ubuntu CI, so they only run on Windows; CI relies on the
// schedule-equivalence tests. Regenerate with
// `flutter test --update-goldens --tags golden`.
final bool _skip = !Platform.isWindows;

List<WrapUpPhotoRef> _refs(int n, String prefix) => [
  for (var i = 0; i < n; i++) WrapUpPhotoRef(photoId: '$prefix$i'),
];

const _unlock = WrapUpUnlock(
  code: 'first_adventure',
  name: 'First Adventure',
  reason: 'You logged your first memory.',
);

/// A 16-slot full film: captions, a badge, three collages, both Flurries,
/// an unlock.
WrapUpEntity _fullFilm() {
  const layouts = <int, WrapUpCollageLayout>{
    2: WrapUpCollageLayout.stack3,
    7: WrapUpCollageLayout.torn4,
    13: WrapUpCollageLayout.tilt6,
  };
  return buildWrapUpEntity(
    cut: WrapUpFilmCut.full,
    momentSlots: 16,
    bridges: const ['You came for the canals.', 'Then the bikes won.', 'Home.'],
    moments: [
      for (var i = 0; i < 16; i++)
        WrapUpMoment(
          photoId: 'm$i',
          note: i.isEven ? 'Note number $i' : null,
          badge: i == 1 ? 'Dare · Snap anything · ✦1' : null,
          layout: layouts[i],
          collageExtras: layouts[i] == null
              ? const []
              : _refs(layouts[i]!.tileCount - 1, 'x$i-'),
        ),
    ],
    flurryLeftovers: WrapUpFlurryLeftovers(
      photos: _refs(20, 'f'),
      flurry1: _refs(12, 'f'),
      flurry2: _refs(8, 'g'),
      totalRemainingLabel: '+ 12 more',
    ),
    footnote: const WrapUpFootnote(
      photoCount: 48,
      bonusCompletedCount: 3,
      stars: 21,
    ),
    unlock: _unlock,
    keepsake: const WrapUpKeepsake(
      titleLine1: 'Amsterdam',
      titleLine2: 'in June',
      closingQuote: 'You left with dry socks, barely.',
    ),
  );
}

/// A pre-#151 film: no cut, 5 moments in 8 slots, 20 leftovers.
WrapUpEntity _legacyFilm() => buildWrapUpEntity(
  bridges: const ['One.', 'Two.', 'Three.'],
  moments: [
    for (var i = 0; i < 5; i++) WrapUpMoment(photoId: 'm$i', note: 'Note $i'),
  ],
  flurryLeftovers: WrapUpFlurryLeftovers(photos: _refs(20, 'l')),
);

Future<void> _expectFilmAt(
  WidgetTester tester,
  WrapUpEntity wrapUp,
  Map<String, double Function(LegacyFilmScenes)> shots,
  String prefix,
) async {
  tester.view.physicalSize = const Size(540, 960);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: WrapUpFilmCanvas(
        wrapUp: wrapUp,
        photoUrlById: const {},
        coverImage: null,
        grainImage: null,
      ),
    ),
  );
  final scenes = LegacyFilmScenes.forWrapUp(wrapUp);
  var elapsed = 0.0;
  for (final MapEntry(key: name, value: timeOf) in shots.entries) {
    final target = timeOf(scenes);
    expect(target, greaterThanOrEqualTo(elapsed), reason: name);
    await tester.pump(
      Duration(milliseconds: ((target - elapsed) * 1000).round()),
    );
    elapsed = target;
    await expectLater(
      find.byType(WrapUpFilmCanvas),
      matchesGoldenFile('goldens/${prefix}_$name.png'),
    );
  }
}

void main() {
  // The film's Google Fonts aren't bundled, and a failed font load errors
  // on a future nobody listens to, failing the test. Requests that never
  // answer keep those loads pending instead: text renders in the test font,
  // which is all a before/after comparison needs.
  late HttpOverrides? previous;
  setUpAll(() {
    previous = HttpOverrides.current;
    HttpOverrides.global = _SilentHttpOverrides();
  });
  tearDownAll(() => HttpOverrides.global = previous);

  testWidgets('full 16-slot film', skip: _skip, (tester) async {
    await _expectFilmAt(tester, _fullFilm(), {
      'dust': (s) => 1.6,
      'invitation': (s) => s.invitationStart + 2.0,
      'bridge1': (s) => s.bridge1Start + 3.0,
      'moment_captioned': (s) => s.momentStarts[0] + 1.8,
      'moment_badge': (s) => s.momentStarts[1] + 1.8,
      'collage': (s) => s.momentStarts[2] + 2.5,
      'flurry1': (s) => s.flurry1Start + 3.0,
      'bridge2': (s) => s.bridge2Start + 3.0,
      'flurry2': (s) => s.flurry2Start + 4.0,
      'pile': (s) => s.footnoteStart - 1.2,
      'footnote': (s) => s.footnoteStart + 2.0,
      'unlock': (s) => s.unlockStart + 2.0,
      'keepsake': (s) => s.keepsakeStart + 4.0,
    }, 'full');
  });

  testWidgets('pre-#151 film', skip: _skip, (tester) async {
    await _expectFilmAt(tester, _legacyFilm(), {
      'invitation': (s) => s.invitationStart + 2.0,
      'moment': (s) => s.momentStarts[1] + 1.8,
      'flurry1': (s) => s.flurry1Start + 3.0,
      'flurry2': (s) => s.flurry2Start + 3.0,
      'empty_slot': (s) => s.momentStarts[6] + 1.0,
      'keepsake': (s) => s.keepsakeStart + 4.0,
    }, 'legacy');
  });
}

class _SilentHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _SilentHttpClient();
}

class _SilentHttpClient implements HttpClient {
  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) =>
      Completer<HttpClientRequest>().future;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/wrap_up/data/models/wrap_up_golden_vows_model.dart';
import 'package:traviato/features/wrap_up/domain/wrap_up_limits.dart';
import 'package:traviato/features/wrap_up/presentation/film/golden_vows/golden_vows_canvas.dart';
import 'package:traviato/features/wrap_up/presentation/film/golden_vows/golden_vows_fit.dart';
import 'package:traviato/features/wrap_up/presentation/film/golden_vows/golden_vows_from_wrap_up.dart';
import 'package:traviato/features/wrap_up/presentation/film/golden_vows/golden_vows_story.dart';
import 'package:traviato/l10n/app_localizations.dart';

/// Golden Vows as it plays on the phone (#458): the edge function's
/// albums, played with the film's own fonts, last what GvFit measures —
/// never past the longest film.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    for (final (family, asset) in const [
      ('CormorantGaramond', 'assets/fonts/CormorantGaramond[wght].ttf'),
      ('PinyonScript', 'assets/fonts/PinyonScript-Regular.ttf'),
      ('GreatVibes', 'assets/fonts/GreatVibes-Regular.ttf'),
    ]) {
      await (FontLoader(family)..addFont(rootBundle.load(asset))).load();
    }
  });

  final fixtures =
      (jsonDecode(
                File(
                  'supabase/functions/generate_wrap_up/film_lengths.json',
                ).readAsStringSync(),
              )
              as List<dynamic>)
          .cast<Map<dynamic, dynamic>>()
          .where((f) => f['film'] == 'golden_vows')
          .map((f) => f.cast<String, dynamic>())
          .toList();

  GoldenVowsStory storyOf(Map<String, dynamic> fixture) => goldenVowsFromWrapUp(
    parseWrapUpGoldenVows(
      (fixture['content'] as Map).cast<String, dynamic>(),
    )!,
    photoIds: (fixture['photo_ids'] as List<dynamic>).cast<String>().toSet(),
    startDate: DateTime.parse(fixture['start_date'] as String),
    endDate: DateTime.parse(fixture['end_date'] as String),
  )!;

  for (final fixture in fixtures) {
    testWidgets("${fixture['photos']} photos: the player's length is "
        "GvFit's, within 75 s", (tester) async {
      final story = storyOf(fixture);
      final measured = GvFit.lengthOf(story);
      expect(measured, lessThanOrEqualTo(WrapUpLimits.longestFilmSeconds));

      await tester.pumpWidget(
        Localizations(
          locale: const Locale('en'),
          delegates: AppLocalizations.localizationsDelegates,
          child: GoldenVowsCanvas(story: story, photo: (_) => null),
        ),
      );
      final player = tester.state(find.byType(GoldenVowsCanvas));
      final played = (player as GoldenVowsPlayback).playLength;
      expect(played.inMilliseconds / 1000, closeTo(measured, 0.001));
      expect(
        played.inMilliseconds,
        lessThanOrEqualTo(WrapUpLimits.longestFilmSeconds * 1000),
      );
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('an album too long for 75 s is fitted before it plays', (
    tester,
  ) async {
    final long = GoldenVowsFixtures.wedding.fitted(
      heroes: [
        for (var i = 1; i <= 6; i++)
          GvHero(
            photoId: 'hero-$i',
            note:
                'We walked along the river until dark, holding hands and '
                'laughing at nothing, day $i.',
          ),
      ],
    );
    final fitted = GvFit.toLongest(long, maxSeconds: 60);
    expect(GvFit.lengthOf(fitted), lessThanOrEqualTo(60));
    await tester.pumpWidget(
      Localizations(
        locale: const Locale('en'),
        delegates: AppLocalizations.localizationsDelegates,
        child: GoldenVowsCanvas(story: fitted, photo: (_) => null),
      ),
    );
    final player = tester.state(find.byType(GoldenVowsCanvas));
    expect(
      (player as GoldenVowsPlayback).playLength.inMilliseconds / 1000,
      closeTo(GvFit.lengthOf(fitted), 0.001),
    );
    await tester.pumpWidget(const SizedBox());
  });
}

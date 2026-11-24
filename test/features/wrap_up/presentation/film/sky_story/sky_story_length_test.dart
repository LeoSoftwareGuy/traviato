import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/wrap_up/data/models/wrap_up_sky_model.dart';
import 'package:traviato/features/wrap_up/domain/wrap_up_limits.dart';
import 'package:traviato/features/wrap_up/presentation/film/sky_story/sky_story.dart';
import 'package:traviato/features/wrap_up/presentation/film/sky_story/sky_story_from_wrap_up.dart';
import 'package:traviato/features/wrap_up/presentation/film/sky_story/sky_story_timeline.dart';

/// Sky Story as it plays on the phone (#463): ADE-Amsterdam and "Elmas
/// birthday" forced to Sky Story, built by the edge function and played
/// with the film's own fonts (#456: a test font hid what didn't fit). Each
/// page shows every line code chose, and the film lasts what the edge
/// function estimated — never past 75 s or 4 s a photo.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    for (final (family, asset) in const [
      ('DMSerifDisplay', 'assets/fonts/DMSerifDisplay-Regular.ttf'),
      ('PlayfairDisplay', 'assets/fonts/PlayfairDisplay[wght].ttf'),
      ('OpenSans', 'assets/fonts/OpenSans[wdth,wght].ttf'),
      ('Caveat', 'assets/fonts/Caveat[wght].ttf'),
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
          .where((f) => '${f['case']}'.endsWith('_sky'))
          .map((f) => f.cast<String, dynamic>())
          .toList();

  test('both real memories are in film_lengths.json', () {
    expect(fixtures.map((f) => f['case']), ['ade_sky', 'budapest_sky']);
  });

  for (final fixture in fixtures) {
    test("${fixture['case']}: every chosen line shows, the length is the "
        "edge function's, within the limit", () {
      final content = (fixture['content'] as Map).cast<String, dynamic>();
      final captions = (content['photo_captions'] as Map)
          .cast<String, String>();
      final sky = parseWrapUpSky(content)!;
      final story = skyStoryFromWrapUp(
        sky,
        photos: {
          for (final id in (fixture['photo_ids'] as List).cast<String>())
            id: SkyPhoto(id: id, caption: captions[id]),
        },
        startDate: DateTime.parse(fixture['start_date'] as String),
        endDate: DateTime.parse(fixture['end_date'] as String),
      )!;
      for (final (i, page) in sky.pages.indexed) {
        final lines = page.excerpts.join(' ');
        expect(
          story.pages[i].note,
          lines.isEmpty ? anyOf(isNull, isNotEmpty) : lines,
          reason: 'page ${i + 1}: the lines fit it whole',
        );
      }
      final played = SkyStoryTimeline.forStory(story).total;
      final photos = fixture['photos'] as int;
      printOnFailure("${fixture['case']}: $played s");
      expect(played, closeTo(content['sky_estimate_seconds'] as num, 0.05));
      expect(played, lessThanOrEqualTo(WrapUpLimits.longestFilmSeconds));
      expect(played, lessThanOrEqualTo(4.0 * photos));
    });
  }
}

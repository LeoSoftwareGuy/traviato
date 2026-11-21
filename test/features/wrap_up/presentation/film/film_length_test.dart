import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/wrap_up/data/models/wrap_up_golden_vows_model.dart';
import 'package:traviato/features/wrap_up/data/models/wrap_up_neon_night_model.dart';
import 'package:traviato/features/wrap_up/data/models/wrap_up_sky_model.dart';
import 'package:traviato/features/wrap_up/domain/wrap_up_limits.dart';
import 'package:traviato/features/wrap_up/presentation/film/golden_vows/golden_vows_from_wrap_up.dart';
import 'package:traviato/features/wrap_up/presentation/film/golden_vows/golden_vows_timeline.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_night_canvas.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_night_from_wrap_up.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_night_timeline.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_reading_time.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_track.dart';
import 'package:traviato/features/wrap_up/presentation/film/sky_story/sky_story.dart';
import 'package:traviato/features/wrap_up/presentation/film/sky_story/sky_story_from_wrap_up.dart';
import 'package:traviato/features/wrap_up/presentation/film/sky_story/sky_story_timeline.dart';

/// The edge function's content for a 15-, 25- and 40-photo memory of each
/// film (#434; written by `write_film_lengths.ts`), played through the
/// real parsers and timelines: each lasts about its target length.
void main() {
  final fixtures =
      jsonDecode(
            File(
              'supabase/functions/generate_wrap_up/film_lengths.json',
            ).readAsStringSync(),
          )
          as List<dynamic>;

  /// How far a film may land from its target: a bar of Neon Night, a page
  /// that needs time to be read.
  const tolerance = 3.0;

  /// Neon Night's shortest film for [fixture]: every chapter's card and
  /// moments, held for their words. A short film never loses
  /// a chapter or its Note scene (#444), so this is its floor.
  double neonFloorOf(Map<String, dynamic> fixture) {
    final content = (fixture['content'] as Map).cast<String, dynamic>();
    final story = neonNightFromWrapUp(
      parseWrapUpNeonNight(content)!,
      photoIds: (fixture['photo_ids'] as List<dynamic>).cast<String>().toSet(),
      startDate: DateTime.parse(fixture['start_date'] as String),
    )!;
    // Each chapter's card and moments with their lines' reading time
    // (#399 T1 — never shorter), the Note, no Plan (it can go).
    return NeonNightTimeline(
      chapters: NnReadingTime.chaptersFor(story, NeonTrack.beat),
      hasPlan: false,
      hasNote: story.note != null,
      noteMinBeats: NnReadingTime.noteBeats(story, NeonTrack.beat),
      beat: NeonTrack.beat,
    ).total;
  }

  double lengthOf(Map<String, dynamic> fixture) {
    final content = (fixture['content'] as Map).cast<String, dynamic>();
    final ids = (fixture['photo_ids'] as List<dynamic>).cast<String>();
    final start = DateTime.parse(fixture['start_date'] as String);
    final end = DateTime.parse(fixture['end_date'] as String);
    switch (fixture['film']) {
      case 'golden_vows':
        final story = goldenVowsFromWrapUp(
          parseWrapUpGoldenVows(content)!,
          photoIds: ids.toSet(),
          startDate: start,
          endDate: end,
        )!;
        return GoldenVowsTimeline.forStory(story).total;
      case 'neon_night':
        final story = neonNightFromWrapUp(
          parseWrapUpNeonNight(content)!,
          photoIds: ids.toSet(),
          startDate: start,
        )!;
        // As it plays: on the music's clock.
        return NeonNightCanvas.timelineFor(story, beat: NeonTrack.beat).total;
      default:
        final story = skyStoryFromWrapUp(
          parseWrapUpSky(content)!,
          photos: {for (final id in ids) id: SkyPhoto(id: id)},
          startDate: start,
          endDate: end,
        )!;
        return SkyStoryTimeline.forStory(story).total;
    }
  }

  for (final raw in fixtures) {
    final fixture = (raw as Map).cast<String, dynamic>();
    final photos = fixture['photos'] as int;
    test('${fixture['film']} at $photos photos lasts about '
        '${WrapUpLimits.filmSeconds(photos)} s (#434)', () {
      final target = WrapUpLimits.filmSeconds(photos);
      expect(
        (fixture['content'] as Map)['film_seconds'],
        target,
        reason: 'the edge function and the app agree on the target',
      );
      final length = lengthOf(fixture);
      printOnFailure('${fixture['film']} $photos: $length s');
      if (fixture['film'] == 'neon_night') {
        // About its target, or its chapters' floor when that is longer.
        final floor = neonFloorOf(fixture);
        printOnFailure('floor $floor s');
        expect(length, greaterThan(target - tolerance));
        expect(
          length,
          lessThanOrEqualTo(math.max(target, floor) + tolerance),
        );
      } else {
        expect(length, closeTo(target, tolerance));
      }
    });
  }

  test('without film_seconds a film keeps its reference pacing', () {
    final fixture = (fixtures.last as Map).cast<String, dynamic>();
    final content = {
      ...(fixture['content'] as Map).cast<String, dynamic>(),
    }..remove('film_seconds');
    expect(parseWrapUpSky(content)!.filmSeconds, isNull);
    expect(parseWrapUpNeonNight(content)!.filmSeconds, isNull);
  });
}

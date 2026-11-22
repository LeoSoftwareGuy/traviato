import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/wrap_up/data/models/wrap_up_neon_night_model.dart';
import 'package:traviato/features/wrap_up/domain/wrap_up_limits.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_grain.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_night_canvas.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_night_fit.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_night_from_wrap_up.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_night_story.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_night_texts.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_placeholder_photo.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_track.dart';
import 'package:traviato/l10n/app_localizations.dart';

import 'neon_test_fonts.dart';

/// ADE-Amsterdam as it plays on the phone (#456: 77.4 s where the tests
/// said 73.5). Tests laid text out in Ahem, so a long line that fits on
/// the phone didn't fit here and its reading time went uncounted. With
/// the film's own fonts, NnFit's measure is the player's.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadNeonNightFonts);

  final fixture =
      (jsonDecode(
                File(
                  'supabase/functions/generate_wrap_up/film_lengths.json',
                ).readAsStringSync(),
              )
              as List<dynamic>)
          .cast<Map<dynamic, dynamic>>()
          .firstWhere((f) => f['case'] == 'ade')
          .cast<String, dynamic>();
  final ids = (fixture['photo_ids'] as List<dynamic>).cast<String>();

  NeonNightStory ade() => neonNightFromWrapUp(
    parseWrapUpNeonNight((fixture['content'] as Map).cast<String, dynamic>())!,
    photoIds: ids.toSet(),
  )!;

  testWidgets("the player's length is NnFit's, within 75 s", (tester) async {
    final story = ade();
    final fitted = NnFit.lengthOf(story, NeonTrack.beat);
    expect(fitted, lessThanOrEqualTo(WrapUpLimits.longestFilmSeconds));

    await tester.runAsync(NeonGrain.load);
    await tester.pumpWidget(
      Localizations(
        locale: const Locale('ru'),
        delegates: AppLocalizations.localizationsDelegates,
        child: NeonNightCanvas(
          story: story,
          photo: NeonPlaceholderPhoto.forIds(ids),
          beat: NeonTrack.beat,
        ),
      ),
    );
    await tester.pump();
    final player = tester.state(find.byType(NeonNightCanvas));
    final played = (player as NeonNightPlayback).playLength;
    expect(played.inMicroseconds / 1e6, closeTo(fitted, 0.001));
    expect(
      played.inMilliseconds,
      lessThanOrEqualTo(WrapUpLimits.longestFilmSeconds * 1000),
    );
    // Stop the film's loop before the test ends.
    await tester.pumpWidget(const SizedBox());
  });

  test('every word the film counts is a word it shows (#456)', () {
    final story = ade();
    for (final (i, chapter) in story.chapters.indexed) {
      for (final moment in chapter.moments) {
        for (final photo in moment.photos) {
          final words = photo.line ?? photo.caption;
          if (words == null) continue;
          // Laid out with the film's fonts: it fits, so it shows and is
          // read — never counted in one place and left out in another.
          expect(
            nnCaptionBox(photo, withLine: true),
            isNotNull,
            reason: 'ch${i + 1}: $words',
          );
        }
      }
    }
  });

  test('the Ch1 split shows a caption, no time on a captioned photo', () {
    final story = ade();
    final split = story.chapters.first.moments.first as NnSplit;
    expect(split.photos.every((p) => p.captioned), isTrue);
    expect(split.photos.any((p) => p.caption != null), isTrue);
    for (final p in split.photos) {
      expect(p.timeLabel, isNull, reason: p.id);
    }
  });
}

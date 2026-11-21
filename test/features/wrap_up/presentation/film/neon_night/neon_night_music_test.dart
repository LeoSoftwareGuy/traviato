import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_grain.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_night_canvas.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_night_story.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_photo_images.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_placeholder_photo.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_track.dart';
import 'package:traviato/l10n/app_localizations.dart';

import '../../../fakes/fake_film_music_player.dart';
import 'neon_test_fonts.dart';

void main() {
  final story = NeonNightFixtures.reference;
  final photo = NeonPlaceholderPhoto.forIds(NeonNightFixtures.photoIds(story));

  Future<void> pumpFilm(
    WidgetTester tester, {
    required FakeFilmMusicPlayer Function(List<NeonTrackPart>) music,
    bool muted = false,
  }) async {
    await tester.runAsync(NeonGrain.load);
    await loadNeonNightFonts();
    await tester.pumpWidget(const SizedBox());
    final context = tester.element(find.byType(SizedBox));
    final (:thumbs, :large, :tiles) = NeonPhotoImages.idsFor(
      story,
      NeonNightCanvas.timelineFor(story, beat: NeonTrack.beat),
    );
    await tester.runAsync(() async {
      for (final id in thumbs) {
        await precacheImage(NeonPhotoImages.thumbProvider(photo, id)!, context);
      }
      for (final id in large) {
        await precacheImage(NeonPhotoImages.largeProvider(photo, id)!, context);
      }
      for (final id in tiles) {
        await precacheImage(NeonPhotoImages.tileProvider(photo, id)!, context);
      }
    });
    await tester.pumpWidget(
      Localizations(
        locale: const Locale('en'),
        delegates: AppLocalizations.localizationsDelegates,
        child: NeonNightCanvas(
          story: story,
          photo: photo,
          beat: NeonTrack.beat,
          music: music,
          muted: muted,
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('plays the parts that fit the film, from the top', (
    tester,
  ) async {
    late FakeFilmMusicPlayer player;
    List<NeonTrackPart>? parts;
    await pumpFilm(
      tester,
      music: (p) {
        parts = p;
        return player = FakeFilmMusicPlayer();
      },
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // The reference night: its Finale is 30 bars in (27, plus a bar to
    // read the note, #399, plus two for the ~2.4 s zooms, #448).
    expect(parts, NeonTrack.partsFor(30));
    expect(player.calls.take(2), ['load', 'play']);
    expect(player.seeks.first, lessThan(0.3));
    expect(player.volumes.last, 1);

    await tester.pumpWidget(const SizedBox());
    expect(player.disposed, isTrue);
  });

  testWidgets('muted: the music keeps its clock, silent', (tester) async {
    late FakeFilmMusicPlayer player;
    await pumpFilm(
      tester,
      muted: true,
      music: (_) => player = FakeFilmMusicPlayer(),
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(player.playing, isTrue);
    expect(player.volumes.last, 0);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a failing track: the film plays on, silent', (tester) async {
    late FakeFilmMusicPlayer player;
    await pumpFilm(
      tester,
      music: (_) => player = FakeFilmMusicPlayer(failLoad: true),
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(tester.takeException(), isNull);
    expect(player.playing, isFalse);
    expect(find.byType(NeonNightCanvas), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}

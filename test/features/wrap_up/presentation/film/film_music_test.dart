import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/wrap_up/presentation/film/sky_story/sky_story_canvas.dart';
import 'package:traviato/features/wrap_up/presentation/film/sky_story/sky_story_fixture.dart';
import 'package:traviato/features/wrap_up/presentation/film/film_music.dart';
import 'package:traviato/features/wrap_up/presentation/film/sky_story/sky_story_timeline.dart';
import 'package:traviato/features/wrap_up/presentation/pages/sky_story_preview_page.dart';
import 'package:traviato/l10n/app_localizations.dart';

import '../../fakes/fake_film_music_player.dart';

Widget _film(FilmMusicPlayer Function() music) => Localizations(
  locale: const Locale('en'),
  delegates: AppLocalizations.localizationsDelegates,
  child: SkyStoryCanvas(
    story: SkyStoryFixtures.lisbon,
    photo: (_) => null,
    music: music,
  ),
);

void main() {
  group('volumeAt', () {
    for (var n = 1; n <= SkyStoryTimeline.maxChapters; n++) {
      test('fades in and out of a $n-chapter film', () {
        final total = SkyStoryTimeline.forChapters(n).total;
        expect(FilmMusic.volumeAt(0, total), 0);
        expect(FilmMusic.volumeAt(0.2, total), closeTo(0.5, 1e-9));
        expect(FilmMusic.volumeAt(0.4, total), 1);
        expect(FilmMusic.volumeAt(total / 2, total), 1);
        expect(FilmMusic.volumeAt(total - 2.5, total), 1);
        expect(
          FilmMusic.volumeAt(total - 1.25, total),
          closeTo(0.5, 1e-9),
        );
        expect(FilmMusic.volumeAt(total, total), 0);
      });
    }
  });

  group('on the film clock', () {
    late FakeFilmMusicPlayer player;
    late FilmMusic music;

    setUp(() async {
      player = FakeFilmMusicPlayer();
      music = FilmMusic(player, filmLength: 54);
      await music.ready;
    });

    test('starts at the film time when the film runs', () {
      music.sync(0.1, running: true);
      expect(player.seeks, [0.1]);
      expect(player.playing, isTrue);
    });

    test('a little drift is left alone; more is pulled back', () {
      music.sync(1, running: true);
      player.positionS = 1.6;
      music.sync(1.6, running: true); // in step
      player.positionS = 1.7;
      music.sync(1.8, running: true); // 0.1 s behind: fine
      expect(player.seeks, [1]);
      player.positionS = 1.9;
      music.sync(2.1, running: true); // 0.2 s behind
      expect(player.seeks, [1, 2.1]);
    });

    test('is not pulled again straight after a seek', () {
      music.sync(1, running: true);
      player.positionS = 0.5;
      music.sync(1.2, running: true); // within the cooldown
      expect(player.seeks, [1]);
      music.sync(1.6, running: true);
      expect(player.seeks, [1, 1.6]);
    });

    test('pauses and resumes with the film', () {
      music.sync(5, running: true);
      music.sync(6, running: false);
      expect(player.playing, isFalse);
      music.sync(6, running: true);
      expect(player.playing, isTrue);
      expect(player.seeks.last, 6);
      music.pause(); // the app was hidden
      expect(player.playing, isFalse);
    });

    test('starts again from the top when the film loops', () {
      music.sync(53.9, running: true);
      player.positionS = 53.9;
      music.sync(0.02, running: true);
      expect(player.seeks.last, 0.02);
    });

    test('follows the fades, and mutes without stopping', () {
      music.sync(0.2, running: true);
      expect(player.volumes.last, closeTo(0.5, 1e-9));
      player.positionS = 10;
      music.sync(10, running: true);
      expect(player.volumes.last, 1);
      music.muted = true;
      expect(player.volumes.last, 0);
      expect(player.playing, isTrue);
      music.muted = false;
      expect(player.volumes.last, 1);
    });

    test('disposes its player and then does nothing', () async {
      await music.dispose();
      expect(player.disposed, isTrue);
      music.sync(3, running: true);
      expect(player.calls, ['load']);
    });
  });

  test('a track that fails to load leaves the film silent', () async {
    final player = FakeFilmMusicPlayer(failLoad: true);
    final music = FilmMusic(player, filmLength: 54);
    await music.ready;
    expect(music.failed, isTrue);
    music.sync(1, running: true);
    expect(player.calls, ['load']);
  });

  testWidgets('the film plays its music', (tester) async {
    late FakeFilmMusicPlayer player;
    await tester.pumpWidget(_film(() => player = FakeFilmMusicPlayer()));
    await tester.pump(const Duration(seconds: 2));
    expect(player.playing, isTrue);
    expect(player.seeks, isNotEmpty);
    await tester.pumpWidget(const SizedBox());
    expect(player.disposed, isTrue);
  });

  testWidgets('a failing track: the film plays on, silent', (tester) async {
    late FakeFilmMusicPlayer player;
    await tester.pumpWidget(
      _film(() => player = FakeFilmMusicPlayer(failLoad: true)),
    );
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    expect(tester.takeException(), isNull);
    expect(player.playing, isFalse);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('the preview mutes and unmutes the music', (tester) async {
    late FakeFilmMusicPlayer player;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SkyStoryPreviewPage(music: () => player = FakeFilmMusicPlayer()),
      ),
    );
    await tester.pump(const Duration(seconds: 2));
    expect(player.volumes.last, 1);
    await tester.tap(find.byKey(const Key('sky-story-mute')));
    await tester.pump();
    expect(player.volumes.last, 0);
    expect(find.byIcon(Icons.volume_off_rounded), findsOneWidget);
    await tester.tap(find.byKey(const Key('sky-story-mute')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(player.volumes.last, 1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('the music stops while another screen covers the film', (
    tester,
  ) async {
    late FakeFilmMusicPlayer player;
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SkyStoryCanvas(
          story: SkyStoryFixtures.lisbon,
          photo: (_) => null,
          music: () => player = FakeFilmMusicPlayer(),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 2));
    expect(player.playing, isTrue);

    unawaited(
      navigator.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => const Text('Journal')),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(player.playing, isFalse);

    navigator.currentState!.pop();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(player.playing, isTrue);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a failure stops the film and the music, once', (
    tester,
  ) async {
    late FakeFilmMusicPlayer player;
    final failures = <Object>[];
    // No Localizations: laying out the words throws.
    await tester.pumpWidget(
      SkyStoryCanvas(
        story: SkyStoryFixtures.lisbon,
        photo: (_) => null,
        music: () => player = FakeFilmMusicPlayer(),
        onFailure: (error, _) => failures.add(error),
      ),
    );
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    expect(failures, hasLength(1));
    expect(find.byType(CustomPaint), findsNothing);
    expect(player.playing, isFalse);
    await tester.pumpWidget(const SizedBox());
  });
}

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/wrap_up/presentation/film/film_music.dart';
import 'package:traviato/features/wrap_up/presentation/film/golden_vows/golden_vows_canvas.dart';
import 'package:traviato/features/wrap_up/presentation/film/golden_vows/golden_vows_story.dart';
import 'package:traviato/features/wrap_up/presentation/film/golden_vows/golden_vows_timeline.dart';
import 'package:traviato/features/wrap_up/presentation/pages/golden_vows_preview_page.dart';
import 'package:traviato/l10n/app_localizations.dart';

import '../../../fakes/fake_film_music_player.dart';

Widget _app(Widget home, {GlobalKey<NavigatorState>? navigator}) => MaterialApp(
  navigatorKey: navigator,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: home,
);

Widget _film(FilmMusicPlayer Function() music) => _app(
  GoldenVowsCanvas(story: GoldenVowsFixtures.wedding, music: music),
);

void main() {
  final total = GoldenVowsTimeline.forStory(GoldenVowsFixtures.wedding).total;

  test('the track is bundled and credited', () {
    const asset = 'assets/audio/golden_vows_wedding.m4a';
    expect(File(asset).existsSync(), isTrue);
    final credits = File('assets/audio/CREDITS.md').readAsStringSync();
    expect(credits, contains('golden_vows_wedding.m4a'));
    expect(credits, contains('pixabay.com/music/wedding-wedding-wedding'));
    expect(File('pubspec.yaml').readAsStringSync(), contains('assets/audio/'));
    final player = JustAudioFilmMusicPlayer.goldenVows();
    expect((player as JustAudioFilmMusicPlayer).asset, asset);
    unawaited(player.dispose());
  });

  testWidgets('plays from the top and fades out as the film ends', (
    tester,
  ) async {
    late FakeFilmMusicPlayer player;
    await tester.pumpWidget(_film(() => player = FakeFilmMusicPlayer()));
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(player.playing, isTrue);
    expect(
      player.seeks.first,
      lessThan(0.3),
      reason: 'the track starts from its beginning with the film',
    );
    expect(player.volumes.last, 1);

    // 1 s before the end (the film is at 2 s): fading out.
    await tester.pump(Duration(milliseconds: ((total - 3) * 1000).round()));
    expect(player.volumes.last, lessThan(1));
    expect(player.volumes.last, greaterThan(0));

    // The film loops: the music starts again from the top.
    final seeksBefore = player.seeks.length;
    await tester.pump(const Duration(milliseconds: 1500));
    expect(player.seeks.length, greaterThan(seeksBefore));
    expect(player.seeks.last, lessThan(1));
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
      _app(GoldenVowsPreviewPage(music: () => player = FakeFilmMusicPlayer())),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(player.volumes.last, 1);
    await tester.tap(find.byKey(const Key('golden-vows-mute')));
    await tester.pump();
    expect(player.volumes.last, 0);
    expect(find.byIcon(Icons.volume_off_rounded), findsOneWidget);
    await tester.tap(find.byKey(const Key('golden-vows-mute')));
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
      _app(
        GoldenVowsCanvas(
          story: GoldenVowsFixtures.wedding,
          music: () => player = FakeFilmMusicPlayer(),
        ),
        navigator: navigator,
      ),
    );
    await tester.pump();
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
}

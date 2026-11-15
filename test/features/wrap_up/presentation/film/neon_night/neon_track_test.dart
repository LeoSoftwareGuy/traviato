import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/wrap_up/presentation/film/film_music.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_night_timeline.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_track.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  int barsBeforeTail(List<NeonTrackPart> parts) => parts
      .takeWhile((p) => p != NeonTrackPart.tail)
      .fold(0, (sum, p) => sum + p.bars);

  test('20 bars before the Finale: the track as it is', () {
    expect(NeonTrack.partsFor(20), NeonTrackPart.values);
  });

  test('every length from 7 bars: from the top, bar 21 on the Finale', () {
    for (var bars = NeonTrack.minBars; bars <= 60; bars++) {
      final parts = NeonTrack.partsFor(bars);
      expect(parts.first, NeonTrackPart.intro1, reason: '$bars bars');
      expect(parts.last, NeonTrackPart.tail, reason: '$bars bars');
      expect(
        parts.where((p) => p == NeonTrackPart.tail),
        hasLength(1),
        reason: '$bars bars',
      );
      expect(barsBeforeTail(parts), bars, reason: '$bars bars');
      // The intro's fill always leads into the groove.
      expect(
        parts.lastIndexOf(NeonTrackPart.intro5),
        parts.indexWhere((p) => p.index > NeonTrackPart.intro5.index) - 1,
        reason: '$bars bars',
      );
    }
  });

  test('longer films repeat bar 4, then the fuller groove and the groove', () {
    expect(NeonTrack.partsFor(21), [
      NeonTrackPart.intro1,
      NeonTrackPart.intro4,
      NeonTrackPart.intro4,
      NeonTrackPart.intro5,
      ...NeonTrackPart.values.skip(3),
    ]);
    expect(NeonTrack.partsFor(24).sublist(3), [
      NeonTrackPart.groove9,
      NeonTrackPart.groove11,
      NeonTrackPart.groove13,
      NeonTrackPart.groove11,
      NeonTrackPart.groove15,
      NeonTrackPart.full17,
      NeonTrackPart.full19,
      NeonTrackPart.full17,
      NeonTrackPart.tail,
    ]);
  });

  test('shorter films leave out bar 4, then whole units', () {
    expect(NeonTrack.partsFor(19), [
      NeonTrackPart.intro1,
      NeonTrackPart.intro5,
      ...NeonTrackPart.values.skip(3),
    ]);
    expect(NeonTrack.partsFor(9), [
      NeonTrackPart.intro1,
      NeonTrackPart.intro5,
      NeonTrackPart.groove13,
      NeonTrackPart.tail,
    ]);
    expect(NeonTrack.partsFor(7), [
      NeonTrackPart.intro1,
      NeonTrackPart.intro5,
      NeonTrackPart.tail,
    ]);
  });

  test('too short to fit: the track plays as it is', () {
    expect(NeonTrack.partsFor(6), NeonTrackPart.values);
  });

  test('on every film shape, bar 21 is the Finale and bar 25 the Ending', () {
    for (final chapters in [1, 2, 3, 4, 5]) {
      for (final hasPlan in [true, false]) {
        for (final hasNote in [true, false]) {
          for (final photos in [1, 20]) {
            final film = NeonNightTimeline.standard(
              chapters,
              photos: photos,
              hasPlan: hasPlan,
              hasNote: hasNote,
              beat: NeonTrack.beat,
            );
            final layout = NeonTrack.layout(NeonTrack.partsForTimeline(film));
            final tail = layout.last;
            final label = '$chapters ch, plan $hasPlan, note $hasNote, $photos';
            expect(tail.start, closeTo(film.finaleCue, 1e-9), reason: label);
            expect(
              tail.start + 4 * NeonTrack.beat.bar,
              closeTo(film.endingCue, 1e-9),
              reason: label,
            );
            expect(
              tail.start + tail.length,
              closeTo(film.total, 1e-9),
              reason: label,
            );
          }
        }
      }
    }
  });

  test('the layout puts the parts back to back from 0', () {
    final layout = NeonTrack.layout(NeonTrack.partsFor(20));
    expect(layout.first.start, 0);
    for (var i = 1; i < layout.length; i++) {
      expect(
        layout[i].start,
        closeTo(layout[i - 1].start + layout[i - 1].length, 1e-9),
      );
    }
    expect(layout[3].start, closeTo(8 * NeonTrack.beat.bar, 1e-9));
  });

  test('every part is bundled, declared and credited', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('assets/audio/neon_night/'));
    final credits = File('assets/audio/CREDITS.md').readAsStringSync();
    expect(credits, contains('Summer Party'));
    expect(credits, contains('pixabay.com/music/dance-summer-party-590004'));
    for (final part in NeonTrackPart.values) {
      expect(File(part.asset).existsSync(), isTrue, reason: part.asset);
    }
  });

  test('the player plays the parts in order, on the film clock', () {
    final parts = NeonTrack.partsFor(9);
    final player = NeonTrack.player(parts) as JustAudioPlaylistMusicPlayer;
    expect(player.pieces.map((p) => p.asset), [
      for (final part in parts) part.asset,
    ]);
    final bar = NeonTrack.beat.bar;
    expect(player.pieces.map((p) => p.start), [0, 3 * bar, 7 * bar, 9 * bar]);
    unawaited(player.dispose());
  });

  test('a film time finds the piece playing then', () {
    const pieces = [
      (asset: 'a', start: 0.0),
      (asset: 'b', start: 2.0),
      (asset: 'c', start: 5.0),
    ];
    expect(JustAudioPlaylistMusicPlayer.pieceAt(pieces, 0), 0);
    expect(JustAudioPlaylistMusicPlayer.pieceAt(pieces, 1.99), 0);
    expect(JustAudioPlaylistMusicPlayer.pieceAt(pieces, 2), 1);
    expect(JustAudioPlaylistMusicPlayer.pieceAt(pieces, 4.9), 1);
    expect(JustAudioPlaylistMusicPlayer.pieceAt(pieces, 99), 2);
  });
}

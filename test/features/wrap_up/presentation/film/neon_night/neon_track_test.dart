import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_night_timeline.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_track.dart';

void main() {
  test('the reference track lands its drop on the reference finale', () {
    const track = NeonTrack.reference;
    final film = NeonNightTimeline.reference();
    expect(track.dropIsOnDownbeat, isTrue);
    expect(track.startsAt(finaleCue: film.finaleCue), closeTo(0, 1e-9));
    expect(
      track.positionAt(film.finaleCue, finaleCue: film.finaleCue),
      closeTo(track.drop, 1e-9),
    );
  });

  test('a shorter film starts the track partway in, a longer one late', () {
    const track = NeonTrack.reference;
    for (final chapters in [1, 2, 4, 5]) {
      final film = NeonNightTimeline.standard(chapters);
      final cue = film.finaleCue;
      expect(track.positionAt(cue, finaleCue: cue), closeTo(track.drop, 1e-9));
      // Film time 0 is still on one of the track's downbeats.
      final atStart = track.positionAt(0, finaleCue: cue);
      final bars = (atStart - track.firstDownbeat) / track.beat.bar;
      expect(bars, closeTo(bars.roundToDouble(), 1e-6), reason: '$chapters');
    }
    final five = NeonNightTimeline.standard(5);
    expect(track.startsAt(finaleCue: five.finaleCue), greaterThan(0));
    expect(track.positionAt(0, finaleCue: five.finaleCue), lessThan(0));
  });

  test('a track whose drop is off the bar grid is flagged', () {
    const off = NeonTrack(bpm: 126, firstDownbeat: 0.2, drop: 51.0);
    expect(off.dropIsOnDownbeat, isFalse);
    const on = NeonTrack(bpm: 128, firstDownbeat: 0.31, drop: 0.31 + 52.5);
    expect(on.dropIsOnDownbeat, isTrue);
    expect(on.beat.bpm, 128);
  });
}

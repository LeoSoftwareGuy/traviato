import '../film_music.dart';
import 'neon_beat.dart';
import 'neon_night_timeline.dart';

/// One bar-aligned piece of Neon Night's track (#363): "Summer Party" by
/// AtlasAudio (credits in `assets/audio/CREDITS.md`), cut at its
/// downbeats into the parts the film strings together.
///
/// The track's shape: an intro (bars 1–8, bar 8 a fill), a groove (9–16),
/// a fuller groove (17–24, bar 24 a fill), then a softer part (25–28) and
/// an outro without kick drums. Its harmony repeats every 2 bars, so the
/// 2-bar units can be repeated or left out without a seam.
enum NeonTrackPart {
  /// Bars 1–3.
  intro1(3),

  /// Bar 4: the one bar that can be repeated or left out on its own.
  intro4(1),

  /// Bars 5–8, ending on the fill into the groove.
  intro5(4),

  /// The groove, bars 9–10, 11–12, 13–14, 15–16.
  groove9(2),
  groove11(2),
  groove13(2),
  groove15(2),

  /// The fuller groove, bars 17–18 and 19–20.
  full17(2),
  full19(2),

  /// Bar 21 to the end: the last loud bars (21–24) under the Finale, the
  /// soft bars (25–27) under the Ending, then the outro the film fades.
  tail(7);

  const NeonTrackPart(this.bars);

  /// How many bars the part holds (the tail: the ones the film uses).
  final int bars;

  String get asset => 'assets/audio/neon_night/neon_night_${_files[index]}.m4a';

  static const _files = [
    'i1', 'i4', 'i5', 'a1', 'a2', 'a3', 'a4', 'b1', 'b2', 'tail', //
  ];
}

/// Fits the track to a Neon Night film (#363, Leo): it always starts from
/// its beginning with the film, and its loud last bars (21–24) always
/// carry the Finale's heart, its soft bars the Ending. The steady groove
/// between grows or shrinks by whole bars to make that fit.
abstract final class NeonTrack {
  /// The track's tempo: the film runs on this clock when it plays the
  /// music.
  static const double bpm = 124;

  static const NeonBeat beat = NeonBeat(bpm);

  /// The bars before the Finale in the track as cut: intro (8), groove
  /// (8) and the fuller groove's first 4.
  static const int naturalBars = 20;

  /// The fewest bars the parts can make before the Finale: bars 1–3 and
  /// 5–8.
  static const int minBars = 7;

  /// The parts to play, in order, for a film whose Finale starts
  /// [barsBeforeFinale] bars in, so bar 21 lands on its first beat.
  ///
  /// Longer films repeat bar 4 (for an odd number of extra bars) and then
  /// 2-bar units: first the fuller groove's, then the groove's, in turn.
  /// Shorter ones leave out bar 4, then units in the order 9, 11, 17, 15,
  /// 19, 13. Below [minBars] the track can't fit, and it plays as it is.
  static List<NeonTrackPart> partsFor(int barsBeforeFinale) {
    final intro = [
      NeonTrackPart.intro1,
      NeonTrackPart.intro4,
      NeonTrackPart.intro5,
    ];
    final groove = [
      NeonTrackPart.groove9,
      NeonTrackPart.groove11,
      NeonTrackPart.groove13,
      NeonTrackPart.groove15,
    ];
    final full = [NeonTrackPart.full17, NeonTrackPart.full19];
    if (barsBeforeFinale >= naturalBars) {
      var extra = barsBeforeFinale - naturalBars;
      if (extra.isOdd) {
        intro.insert(1, NeonTrackPart.intro4);
        extra--;
      }
      for (var unit = 0; unit < extra ~/ 2; unit++) {
        if (unit.isEven) {
          full.add(full[(unit ~/ 2) % 2]);
        } else {
          final repeat = unit ~/ 2;
          groove.insert(
            groove.length - 1,
            repeat.isEven ? NeonTrackPart.groove11 : NeonTrackPart.groove13,
          );
        }
      }
    } else if (barsBeforeFinale >= minBars) {
      var cut = naturalBars - barsBeforeFinale;
      if (cut.isOdd) {
        intro.remove(NeonTrackPart.intro4);
        cut--;
      }
      for (final unit in const [
        NeonTrackPart.groove9,
        NeonTrackPart.groove11,
        NeonTrackPart.full17,
        NeonTrackPart.groove15,
        NeonTrackPart.full19,
        NeonTrackPart.groove13,
      ]) {
        if (cut == 0) break;
        if (!groove.remove(unit)) full.remove(unit);
        cut -= 2;
      }
    }
    return [...intro, ...groove, ...full, NeonTrackPart.tail];
  }

  /// [partsFor] the Finale of [timeline] (which must run on [beat]).
  static List<NeonTrackPart> partsForTimeline(NeonNightTimeline timeline) {
    assert(timeline.beat.bpm == bpm, 'the film must run on the track clock');
    assert(timeline.finaleBeat % 4 == 0, 'the Finale starts on a downbeat');
    return partsFor(timeline.finaleBeat ~/ 4);
  }

  /// Where each part starts on the film clock, s, and its length.
  static List<({NeonTrackPart part, double start, double length})> layout(
    List<NeonTrackPart> parts,
  ) {
    final layout = <({NeonTrackPart part, double start, double length})>[];
    var bars = 0;
    for (final part in parts) {
      layout.add((
        part: part,
        start: beat.bar * bars,
        length: beat.bar * part.bars,
      ));
      bars += part.bars;
    }
    return layout;
  }

  /// The player for [parts], gapless, on the film clock.
  static FilmMusicPlayer player(List<NeonTrackPart> parts) =>
      JustAudioPlaylistMusicPlayer([
        for (final piece in layout(parts))
          (asset: piece.part.asset, start: piece.start),
      ]);
}

import 'neon_random.dart';

/// Which contact-sheet tiles a long chapter card's laser zooms pick
/// (#363, NEON_NIGHT_SPEC.md §5.3), drawn from `rng(n × 77 + 1)`.
///
/// Every long card zooms, whatever the chapter's photo count (Leo, #363 —
/// this overrides §8's "fewer than 4 tiles → no zooms"), and never zooms
/// the same tile twice:
/// - 3 or more tiles: three different tiles, at lb 6, 9 and 12;
/// - 2 tiles: each once, at lb 6 and 9;
/// - 1 tile: once, at lb 6.
///
/// After the last zoom the card holds (the typed line and the cursor keep
/// going) until its 16 beats are up.
abstract final class NeonZoomPicks {
  /// The most zoom cycles a long card plays.
  static const int cycles = 3;

  /// Cycle starts on a long card, in local beats: the i-th pick zooms at
  /// `cycleStarts[i]`.
  static const List<int> cycleStarts = [6, 9, 12];

  /// The tiles (indices in reading order) for chapter [chapterNumber]
  /// (from 1, as on the card's "CH 0n") with [tiles] tiles on its sheet.
  static List<int> pick({required int chapterNumber, required int tiles}) {
    assert(tiles >= 1, 'a chapter card has at least one tile');
    final count = tiles < cycles ? tiles : cycles;
    final r = NeonRandom(NeonSeeds.zoomPicks(chapterNumber));
    final picks = <int>[];
    while (picks.length < count) {
      final i = (r.next() * tiles).floor();
      if (!picks.contains(i)) picks.add(i);
    }
    return List.unmodifiable(picks);
  }
}

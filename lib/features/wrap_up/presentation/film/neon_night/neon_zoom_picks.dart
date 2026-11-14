import 'neon_random.dart';

/// Which contact-sheet tiles a long chapter card's three laser zooms pick
/// (#363, NEON_NIGHT_SPEC.md §5.3), drawn from `rng(n × 77 + 1)`.
///
/// Every long card zooms three times, whatever the chapter's photo count
/// (Leo, #363 — this overrides §8's "fewer than 4 tiles → no zooms"):
/// - 3 or more tiles: three different tiles;
/// - 2 tiles: they alternate (A, B, A), never the same one twice running;
/// - 1 tile: it is zoomed three times.
abstract final class NeonZoomPicks {
  /// How many zoom cycles a long card plays (at lb 6, 9 and 12).
  static const int cycles = 3;

  /// Cycle starts on a long card, in local beats.
  static const List<int> cycleStarts = [6, 9, 12];

  /// The tiles (indices in reading order) for chapter [chapterNumber]
  /// (from 1, as on the card's "CH 0n") with [tiles] tiles on its sheet.
  static List<int> pick({required int chapterNumber, required int tiles}) {
    assert(tiles >= 1, 'a chapter card has at least one tile');
    if (tiles <= 1) return List.filled(cycles, 0);
    final r = NeonRandom(NeonSeeds.zoomPicks(chapterNumber));
    final picks = <int>[];
    while (picks.length < cycles) {
      final i = (r.next() * tiles).floor();
      final fresh = tiles >= cycles
          ? !picks.contains(i)
          : picks.isEmpty || picks.last != i;
      if (fresh) picks.add(i);
    }
    return List.unmodifiable(picks);
  }
}

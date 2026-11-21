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
/// A card with 1–2 zooms is 12 beats instead of 16 (`NnChapterCardSpec`).
abstract final class NeonZoomPicks {
  /// The most zoom cycles a card plays (#444: 2, so a card stays about
  /// 6 s; was 3).
  static const int cycles = 2;

  /// The most beats a zoom holds its photo for its caption (#446): a
  /// zoom is on screen at most about 4 s (2 beats + the hold). A caption
  /// that needs longer isn't zoomed: its photo plays in a moment, which
  /// holds it for its reading time (the edge function moves it there).
  static const int maxHoldBeats = 6;

  /// The fewest beats a zoom holds its photo (#448): 3 + 2 beats, about
  /// 2.4 s a zoom — Neon's signature, never a flash.
  static const int minHoldBeats = 2;

  /// The card tiles chapter [chapterNumber] zooms (#446), best first: the
  /// photos whose caption a zoom can show ([fitsZoom]), then the highest
  /// hero score, then the seeded order; a photo whose caption is too long
  /// for a zoom last (it zooms with no label, #450). At most [countFor] of
  /// [photos].
  static List<int> best({
    required int chapterNumber,
    required List<({String? caption, int? heroScore})> photos,
    required bool Function(String caption) fitsZoom,
    // A film over the longest (#450): the quickest photos instead — no
    // caption first, then the shortest, then hero score.
    bool quickest = false,
  }) {
    if (photos.isEmpty) return const [];
    final seeded = pick(chapterNumber: chapterNumber, tiles: photos.length);
    final order = [
      ...seeded,
      for (var k = 0; k < photos.length; k++)
        if (!seeded.contains(k)) k,
    ];
    int rank(int k) {
      final caption = photos[k].caption?.trim();
      final captioned = caption != null && caption.isNotEmpty;
      // A caption too long to read in a zoom: the photo still zooms (#450:
      // every card zooms), with no label, after every other photo.
      if (captioned && !fitsZoom(caption)) {
        return -1000 + (photos[k].heroScore ?? 0);
      }
      if (quickest) {
        return 1000 -
            (captioned ? caption.runes.length * 10 : 0) +
            (photos[k].heroScore ?? 0);
      }
      return (captioned ? 10 : 0) + (photos[k].heroScore ?? 0);
    }

    final ranked = [...order];
    // Stable: equal ranks keep the seeded order.
    final position = {for (final (i, k) in order.indexed) k: i};
    ranked.sort((a, b) {
      final byRank = rank(b) - rank(a);
      return byRank != 0 ? byRank : position[a]! - position[b]!;
    });
    return List.unmodifiable(ranked.take(countFor(photos.length)));
  }

  /// Cycle starts on a long card, in local beats: the i-th pick zooms at
  /// `cycleStarts[i]`.
  static const List<int> cycleStarts = [6, 9, 12];

  /// How many zooms a zoom card plays for a chapter with [photos] photos.
  /// The contact sheet shows min(photos, 4) tiles or more, so this is also
  /// min(tiles, 3).
  static int countFor(int photos) => photos < cycles ? photos : cycles;

  /// The tiles (indices in reading order) for chapter [chapterNumber]
  /// (from 1, as on the card's "CH 0n") with [tiles] tiles on its sheet.
  static List<int> pick({required int chapterNumber, required int tiles}) {
    assert(tiles >= 1, 'a chapter card has at least one tile');
    final count = countFor(tiles);
    final r = NeonRandom(NeonSeeds.zoomPicks(chapterNumber));
    final picks = <int>[];
    while (picks.length < count) {
      final i = (r.next() * tiles).floor();
      if (!picks.contains(i)) picks.add(i);
    }
    return List.unmodifiable(picks);
  }
}

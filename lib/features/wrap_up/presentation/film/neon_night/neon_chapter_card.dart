import 'dart:math' as math;
import 'dart:ui';

import 'neon_beat.dart';
import 'neon_eases.dart';
import 'neon_random.dart';
import 'neon_zoom_picks.dart';

/// A chapter card's contact sheet (#363, NEON_NIGHT_SPEC.md §5.3): where
/// each tile sits, in reading order (the order the photos fill it and pop
/// in).
///
/// - 10+ photos: 2–5 rows (`2 + (n − 10) ÷ 8`). Rows 0–1: hero A (cols
///   0–1, 2×2), col 2 ×2, hero B (cols 3–4, 2×2), cols 5–7 ×2; rows 2+: 8
///   tiles each. 10 + 8 × (rows − 2) tiles, up to 34. Hero A is the
///   chapter's first photo, hero B its 4th.
/// - Fewer: one row of up to 4 heroes (2×2 each).
class NnContactSheet {
  factory NnContactSheet.forPhotos(int photos) {
    assert(photos >= 1, 'photos: $photos');
    Rect cell(int col, int row, [int span = 1]) => Rect.fromLTWH(
      left + col * pitch,
      top + row * pitch,
      span * pitch - gap,
      span * pitch - gap,
    );
    // A rect [cols] wide and [rows] high from column [col] (fractional
    // columns for 3 equal tiles).
    Rect box(double col, double cols, int rows) => Rect.fromLTWH(
      left + col * pitch,
      top,
      cols * pitch - gap,
      rows * pitch - gap,
    );
    // Up to 9 photos (#444): the 8 × 2 grid is always full, never a band
    // of empty space — 1–3 side by side, 4 squares, 5 and 6 a mosaic of
    // squares and tall tiles. 7–9 (older content) show the first 6.
    if (photos < 10) {
      return NnContactSheet._(2, switch (photos) {
        1 || 2 || 3 => [
          for (var i = 0; i < photos; i++) box(i * 8 / photos, 8 / photos, 2),
        ],
        4 => [for (var i = 0; i < 4; i++) cell(2 * i, 0, 2)],
        5 => [
          cell(0, 0, 2),
          cell(2, 0, 2),
          cell(4, 0, 2),
          box(6, 1, 2),
          box(7, 1, 2),
        ],
        _ => [
          cell(0, 0, 2),
          box(2, 1, 2),
          box(3, 1, 2),
          cell(4, 0, 2),
          box(6, 1, 2),
          box(7, 1, 2),
        ],
      });
    }
    final rows = (2 + (photos - 10) ~/ 8).clamp(2, 5);
    return NnContactSheet._(rows, [
      cell(0, 0, 2),
      cell(2, 0),
      cell(2, 1),
      cell(3, 0, 2),
      for (final row in [0, 1])
        for (final col in [5, 6, 7]) cell(col, row),
      for (var row = 2; row < rows; row++)
        for (var col = 0; col < 8; col++) cell(col, row),
    ]);
  }

  const NnContactSheet._(this.rows, this.tiles);

  static const left = 72.0;
  static const top = 950.0;
  static const cellSize = 106.5;
  static const gap = 12.0;
  static const pitch = cellSize + gap;
  static const radius = 10.0;
  static const border = 3.0;

  /// Rows of single cells (a hero spans two).
  final int rows;

  /// Each tile's rect, in reading order; tile k shows photo k.
  final List<Rect> tiles;

  /// Where the sheet ends: `950 + rows × 118.5 − 12`.
  double get bottom => top + rows * pitch - gap;
}

/// A chapter card's timing (§5.3), in local beats `lb` from its cue: the
/// highlight's jumps and the laser zooms. Pure functions of `lb`.
class NnCardTiming {
  NnCardTiming({
    required this.chapterNumber,
    required this.beats,
    required this.zooms,
    required this.tiles,
    List<int> zoomHolds = const [],
    // The tiles to zoom, best first (#446: NnChapterTexts.zoomTilesFor);
    // null = the seeded picks.
    List<int>? zoomTiles,
    this.beat = const NeonBeat(),
  }) : zoomHolds = [
         for (var i = 0; i < zooms; i++)
           i < zoomHolds.length ? zoomHolds[i] : 0,
       ],
       zoomTiles = zooms == 0
           ? const []
           : (zoomTiles ??
                     NeonZoomPicks.pick(
                       chapterNumber: chapterNumber,
                       tiles: tiles,
                     ))
                 .take(zooms)
                 .toList(),
       highlights = _highlights(
         chapterNumber,
         tiles,
         (zooms > 0 ? zoomStart : beats) - highlightFrom,
       );

  /// From 1, as on the card.
  final int chapterNumber;

  /// The card's length: 16, 12 or 8, longer when a caption needs it.
  final int beats;

  /// 0–3 laser zooms.
  final int zooms;
  final int tiles;
  final NeonBeat beat;

  /// The extra beats each zoom holds its photo in the big frame, so its
  /// caption can be read (#399 T1). 0 = the spec's 3-beat cycle.
  final List<int> zoomHolds;

  /// The tiles the zooms pick, in order.
  final List<int> zoomTiles;

  /// The highlighted tile on each beat from [highlightFrom].
  final List<int> highlights;

  static const sheetFrom = 2.0;
  static const highlightFrom = 4;
  static const zoomStart = 6;
  static const typeFrom = 4.0;

  /// A card that zooms nothing types from lb 2, with its sheet (#448: a
  /// film that runs long drops the zooms; its line needs less time).
  static const typeFromWithoutZooms = 2.0;

  /// When this card starts typing its line.
  double get typeAt => typeFromFor(zooms);

  static double typeFromFor(int zooms) =>
      zooms == 0 ? typeFromWithoutZooms : typeFrom;
  static const barFrom = 3.0;

  /// The highlight jumps every beat from lb 4: tile `rng(n×1000+j)`,
  /// re-rolled if it repeats the one before.
  static List<int> _highlights(int chapter, int tiles, int jumps) {
    final picks = <int>[];
    for (var j = 0; j < jumps; j++) {
      final r = NeonRandom(NeonSeeds.highlight(chapter, j));
      var tile = (r.next() * tiles).floor();
      while (tiles > 1 && picks.isNotEmpty && tile == picks.last) {
        tile = (r.next() * tiles).floor();
      }
      picks.add(tile);
    }
    return picks;
  }

  /// When tile [k] pops in, in seconds after the cue.
  double popAt(int k) => beat.beatToSec(sheetFrom) + 0.03 * k;

  /// How strongly each tile is highlighted at [lb]: the current one 1, the
  /// two before it 0.5 and 0.25. Reduced flashing fades the current one
  /// in over 0.15 s instead of switching.
  Map<int, double> highlightAt(double lb, {bool reducedFlashing = false}) {
    final j = (lb - highlightFrom).floor();
    if (j < 0 || j >= highlights.length) return const {};
    final out = <int, double>{};
    for (final (back, strength) in const [(2, 0.25), (1, 0.5)]) {
      if (j - back >= 0) out[highlights[j - back]] = strength;
    }
    var now = 1.0;
    if (reducedFlashing) {
      final since = beat.beatToSec(lb - (highlightFrom + j));
      now = (since / 0.15).clamp(0.0, 1.0);
    }
    final current = highlights[j];
    final trail = out[current] ?? 0;
    out[current] = now > trail ? now : trail;
    return out;
  }

  /// Zoom [cycle]'s start, in local beats: lb 6, then each cycle 3 beats
  /// (plus its hold) after the one before.
  double cycleStart(int cycle) => cycleStartFor(cycle, zoomHolds);

  /// [cycleStart] for zooms holding [holds] extra beats.
  static double cycleStartFor(int cycle, List<int> holds) {
    var c = NeonZoomPicks.cycleStarts.first.toDouble();
    for (var i = 0; i < cycle; i++) {
      c += 3 + (i < holds.length ? holds[i] : 0);
    }
    return c;
  }

  /// How many beats a card with [zooms] zooms holding [holds] needs: the
  /// spec's 16 / 12 / 8, or the last zoom's end rounded up to a bar.
  static int beatsFor(int zooms, List<int> holds) {
    if (zooms == 0) return 8;
    final end = cycleStartFor(zooms - 1, holds) + 3 + holds[zooms - 1];
    final bars = (end / 4).ceil() * 4;
    return math.max(zooms == 3 ? 16 : 12, bars);
  }

  int _hold(int cycle) => zoomHolds[cycle];

  /// Which zoom cycle is under way at [lb] (from 0), or null.
  int? zoomAt(double lb) {
    for (var i = 0; i < zoomTiles.length; i++) {
      final c = cycleStart(i);
      if (lb >= c && lb < c + 3 + _hold(i)) return i;
    }
    return null;
  }

  /// How far the zoom photo is from its tile to the big frame at [lb]
  /// (0–1): flies out over ½ beat from c + ½, holds, then back over ½ beat
  /// from c + 2½ + hold (ease in-out).
  double zoomAmount(double lb, int cycle) {
    final c = cycleStart(cycle);
    final back = c + 2.5 + _hold(cycle);
    if (lb < c + 0.5 || lb >= back + 0.5) return 0;
    if (lb < c + 1) return NeonEases.enter((lb - c - 0.5) / 0.5);
    if (lb < back) return 1;
    return 1 - NeonEases.scroll((lb - back) / 0.5);
  }

  /// How much of the laser has grown at [lb] (0–1, over the first ½
  /// beat) and how bright it is (fading out from c + 2 over ½ beat).
  (double length, double alpha) laserAt(double lb, int cycle) {
    final c = cycleStart(cycle);
    if (lb < c || lb >= c + 2.5) return (0, 0);
    final length = NeonEases.enter(((lb - c) / 0.5).clamp(0.0, 1.0));
    final alpha = 1 - ((lb - c - 2) / 0.5).clamp(0.0, 1.0);
    return (length, alpha);
  }

  /// The zoom's two hits, s after the cue: the laser landing (c + ½) and
  /// the photo landing (c + 1).
  (double hit, double land) zoomHits(int cycle) {
    final c = cycleStart(cycle);
    return (beat.beatToSec(c + 0.5), beat.beatToSec(c + 1));
  }

  /// The big frame a zoom flies to.
  static const zoomRect = Rect.fromLTWH(90, 480, 900, 900);

  /// Where the zoom's time label sits.
  static const zoomLabel = Offset(90, 1400);
}

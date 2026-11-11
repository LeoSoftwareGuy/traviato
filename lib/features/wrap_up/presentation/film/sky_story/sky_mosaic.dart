import 'dart:math' as math;

import 'package:flutter/animation.dart';

/// The closing photo mosaic (#345, phase 4): the memory's photos swirl up
/// and lock into a hot-air balloon. Pure layout and timing; painting is
/// `paintSkyOutro`.
///
/// The envelope is the reference's own grid, sampled tile by tile at 50 s
/// (`R` red-tinted gore, `c` cream stripe): 250 tiles at a 40 px pitch over
/// x 222–858, y 320–1156, with the basket's 4×2 sepia tiles below.
class SkyMosaic {
  SkyMosaic({required this.gatherStart, required int photoCount})
    : tiles = _build(gatherStart, photoCount);

  /// When the gather begins: the mosaic's clock starts here.
  final double gatherStart;

  /// Every tile, bottom rows first.
  final List<SkyMosaicTile> tiles;

  static const pitch = 40.0;
  static const tileSize = 36.0;
  static const tileRadius = 6.0;
  static const left = 222.0;
  static const top = 320.0;

  static const basketPitch = 38.0;
  static const basketTileSize = 34.0;
  static const basketLeft = 466.0;
  static const basketTop = 1212.0;

  /// The burner's glow behind the basket.
  static const glowCenter = Offset(540, 1235);
  static const glowRadius = 210.0;

  static const grid = [
    '.....RcRRcR.....',
    '...RRcRccRcRR...',
    '..RRccRccRccRR..',
    '..RccRRccRRccR..',
    '.RRccRRccRRccRR.',
    'RRRccRRccRRccRRR',
    'RRcccRRccRRcccRR',
    'RRcccRRccRRcccRR',
    'RRccRRRccRRRccRR',
    'RRcccRRccRRcccRR',
    'RRcccRRccRRcccRR',
    '.RRccRRccRRccRR.',
    '.RRccRRccRRccRR.',
    '..RRcRRccRRcRR..',
    '..RRccRccRccRR..',
    '...RccRccRccR...',
    '...RRcRccRcRR...',
    '....RcRccRcR....',
    '....RcRccRcR....',
    '.....RcRRcR.....',
    '.....RcRRcR.....',
  ];

  /// After the gather starts: the first tiles leave, the last start, and
  /// how long each flies. The reference's shape is whole by 46.5 s
  /// (gather + 3.5).
  static const firstStart = 0.7;
  static const startSpread = 1.3;
  static const startJitter = 0.3;
  static const flight = 1.2;

  /// When every tile has locked, relative to the gather.
  static const lockedAfter = firstStart + startSpread + startJitter + flight;

  /// The moment count, tagline and brand line, relative to the gather.
  static const momentsAt = 3.6;
  static const taglineAt = 4.2;
  static const brandAt = 5.2;
  static const glowStart = 1.6;

  double get lockedAt => gatherStart + lockedAfter;

  /// The glow's strength at [t], 0–1.
  double glowAt(double t) => Curves.easeOut.transform(
    ((t - gatherStart - glowStart) / 0.8).clamp(0, 1),
  );

  static List<SkyMosaicTile> _build(double gatherStart, int photoCount) {
    final cells = <(Offset, double, SkyTileTint, int)>[];
    final rows = grid.length + 2; // + the basket's two rows
    for (var r = 0; r < 2; r++) {
      for (var c = 0; c < 4; c++) {
        cells.add((
          Offset(
            basketLeft + basketPitch * c + basketTileSize / 2,
            basketTop + basketPitch * r + basketTileSize / 2,
          ),
          basketTileSize,
          SkyTileTint.basket,
          1 - r,
        ));
      }
    }
    for (var r = grid.length - 1; r >= 0; r--) {
      final row = grid[r];
      for (var c = 0; c < row.length; c++) {
        final mark = row[c];
        if (mark == '.') continue;
        cells.add((
          Offset(
            left + pitch * c + tileSize / 2,
            top + pitch * r + tileSize / 2,
          ),
          tileSize,
          mark == 'R' ? SkyTileTint.red : SkyTileTint.cream,
          2 + grid.length - 1 - r,
        ));
      }
    }
    final photos = assignPhotos(
      [for (final (home, _, _, _) in cells) home],
      photoCount,
    );
    return [
      for (final (i, (home, size, tint, fromBottom)) in cells.indexed)
        SkyMosaicTile(
          home: home,
          size: size,
          tint: tint,
          photo: photos[i],
          start:
              gatherStart +
              firstStart +
              startSpread * fromBottom / (rows - 1) +
              startJitter * _rnd(i, 1),
          from: Offset(
            540 + (_rnd(i, 2) - 0.5) * 760,
            1980 + _rnd(i, 3) * 320,
          ),
          spin: (_rnd(i, 4) - 0.5) * 2 * 160 * math.pi / 180,
          sway: (_rnd(i, 5) - 0.5) * 2 * 180,
          phase: _rnd(i, 6) * 2 * math.pi,
        ),
    ];
  }

  /// Which photo (0 … [count] − 1) each tile at [homes] shows: the photos
  /// cycled in a seeded order, skipping one that matches a tile's
  /// neighbour above, below or beside it where another fits. −1 for every
  /// tile when there are no photos.
  static List<int> assignPhotos(List<Offset> homes, int count) {
    if (count <= 0) return List.filled(homes.length, -1);
    final order = List.generate(count, (i) => i)
      ..shuffle(math.Random(count * 7919 + homes.length));
    final byHome = <Offset, int>{};
    final out = <int>[];
    var next = 0;
    for (final home in homes) {
      final near = {
        for (final d in const [
          Offset(-1, 0),
          Offset(1, 0),
          Offset(0, -1),
          Offset(0, 1),
        ])
          ?byHome[_cell(home) + d],
      };
      var pick = order[next % count];
      for (var k = 0; k < count && near.contains(pick); k++) {
        next++;
        pick = order[next % count];
      }
      next++;
      byHome[_cell(home)] = pick;
      out.add(pick);
    }
    return out;
  }

  /// A tile's grid cell, so neighbours can be found from either grid.
  static Offset _cell(Offset home) => Offset(
    (home.dx / pitch).roundToDouble(),
    (home.dy / pitch).roundToDouble(),
  );

  /// A stable pseudo-random 0–1 for tile [i], channel [k].
  static double _rnd(int i, int k) {
    final x = math.sin(i * 12.9898 + k * 78.233) * 43758.5453;
    return x - x.floorToDouble();
  }
}

enum SkyTileTint { red, cream, basket }

/// One tile's place in the mosaic and its flight there.
class SkyMosaicTile {
  const SkyMosaicTile({
    required this.home,
    required this.size,
    required this.tint,
    required this.photo,
    required this.start,
    required this.from,
    required this.spin,
    required this.sway,
    required this.phase,
  });

  /// The tile's centre once locked.
  final Offset home;
  final double size;
  final SkyTileTint tint;

  /// Index into the story's mosaic photos, or −1 for a placeholder.
  final int photo;

  /// When it leaves from below the frame ([from]); it locks
  /// [SkyMosaic.flight] s later.
  final double start;
  final Offset from;

  /// Its turn when it starts (radians), and its swirl's sideways reach
  /// (px) and phase.
  final double spin;
  final double sway;
  final double phase;

  double get lockedAt => start + SkyMosaic.flight;

  /// Where it is at [t], or null before it has started.
  ({Offset center, double angle, double scale, double opacity})? at(
    double t,
  ) {
    if (t < start) return null;
    final u = ((t - start) / SkyMosaic.flight).clamp(0.0, 1.0);
    if (u >= 1) return (center: home, angle: 0, scale: 1, opacity: 1);
    // power2.out (spec §6), with a swirl that dies away as it settles.
    final e = 1 - (1 - u) * (1 - u);
    final swirl = sway * math.sin(phase + u * math.pi * 1.5) * (1 - e);
    return (
      center: Offset.lerp(from, home, e)!.translate(swirl, 0),
      angle: spin * (1 - e),
      scale: 0.8 + 0.2 * e,
      opacity: 0.4 + 0.6 * math.min(1.0, u * 2.5),
    );
  }
}

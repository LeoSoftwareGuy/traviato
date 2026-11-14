import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'neon_beat.dart';
import 'neon_eases.dart';
import 'neon_random.dart';
import 'neon_svg_path.dart';
import 'neon_tokens.dart';

/// The Finale's heart of photos (#363, NEON_NIGHT_SPEC.md §5.8): which
/// grid cells it uses, which photo each shows, when each pops in, and how
/// it beats. Pure functions of local beats or film time.
class NnHeart {
  factory NnHeart({required int photos}) {
    assert(photos >= 1, 'photos: $photos');
    final cells = <Rect>[];
    final rows = (box.height / pitch).floor();
    final left = box.left + (box.width - columns * pitch) / 2;
    final top = box.top + (box.height - rows * pitch) / 2;
    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < columns; col++) {
        final cell = Rect.fromLTWH(
          left + col * pitch,
          top + row * pitch,
          pitch,
          pitch,
        );
        // §5.8 says "all four corners (inset 3 px) inside", which gives
        // 194 cells; its "about 220" and the reference render's density
        // come from the centre test (222), so the render wins.
        if (path.contains(cell.center)) cells.add(cell);
      }
    }
    return NnHeart._(cells, _ranks(cells.length), photos);
  }

  NnHeart._(this.cells, this.ranks, this.photos);

  /// The heart path's box and its viewBox scale (200 × 180 × 4.5).
  static const box = Rect.fromLTWH(90, 330, 900, 810);
  static const scale = 4.5;
  static const pitch = 44.0;
  static const columns = 20;

  /// A tile inside its cell.
  static const tileSize = 40.0;
  static const tileRadius = 5.0;
  static const tileBorder = 2.5;

  /// What the heart beats and shrinks about.
  static const centre = Offset(540, 735);

  static const heartPath =
      'M100 172 C40 128 6 96 6 58 C6 28 28 8 56 8 C76 8 92 20 100 36 '
      'C108 20 124 8 144 8 C172 8 194 28 194 58 C194 96 160 128 100 172 Z';

  /// `HEART` placed on [box].
  static final Path path = parseNeonSvgPath(
    heartPath,
  ).transform(_scaleThenMove(scale, box.topLeft));

  /// The outline: `HEART` grown about its box's centre so it runs 20 px
  /// outside the tiles.
  static final Path outline = () {
    const s = (900 + 40) / 900;
    return path.transform(
      _scaleThenMove(s, box.center - box.center * s),
    );
  }();

  /// Every used cell, in reading order.
  final List<Rect> cells;

  /// Each cell's place in the pop-in order (0 = first).
  final List<int> ranks;

  /// How many photos fill the heart (N).
  final int photos;

  /// Cell [k]'s photo: `⌊k × N / cells⌋ mod N`. Fewer photos than cells
  /// repeat in order; more are sampled evenly.
  int photoFor(int k) => (k * photos ~/ cells.length) % photos;

  /// A Fisher–Yates shuffle of the cells, seeded `rng(424242)`: rank of
  /// each cell.
  static List<int> _ranks(int n) {
    final order = [for (var i = 0; i < n; i++) i];
    final r = NeonRandom(NeonSeeds.heartShuffle);
    for (var i = n - 1; i > 0; i--) {
      final j = (r.next() * (i + 1)).floor();
      final swap = order[i];
      order[i] = order[j];
      order[j] = swap;
    }
    final ranks = List.filled(n, 0);
    for (var rank = 0; rank < n; rank++) {
      ranks[order[rank]] = rank;
    }
    return ranks;
  }

  /// When cell [k] pops in, in local beats: `0.5 + 5.5 × rank / cells`.
  double popBeat(int k) => 0.5 + 5.5 * ranks[k] / cells.length;

  /// Cell [k]'s pop at local beat [lb]: scale 0 → 1 (back-out) over
  /// 0.35 s, turning from its start angle to 0.
  (double scale, double degrees) popAt(double lb, int k, NeonBeat beat) {
    final since = beat.beatToSec(lb - popBeat(k));
    if (since < 0) return (0, 0);
    final p = (since / 0.35).clamp(0.0, 1.0);
    final e = NeonEases.pop(p);
    return (e, startDegrees(k) * (1 - e));
  }

  /// ±20°, seeded per cell.
  double startDegrees(int k) =>
      (NeonRandom(NeonSeeds.heartShuffle + 1 + k).next() * 2 - 1) * 20;

  /// The tile's border colour: pink, cyan, green, violet by rank.
  Color tileColor(int k) => _tileColors[ranks[k] % _tileColors.length];

  static const _tileColors = [
    NeonColors.pink,
    NeonColors.cyan,
    NeonColors.green,
    NeonColors.violet,
  ];

  /// The outline's draw from lb 6 over 2 beats (enter): how much of it
  /// shows, 0–1.
  static double outlineAt(double lb) =>
      NeonEases.enter(((lb - 6) / 2).clamp(0.0, 1.0));

  /// The heartbeat at film time [t], [finale] being the Finale's cue: a
  /// lub-dub on every beat from lb 8, about [centre]. `1 + 0.05 ×
  /// (flare(beat, 0.09) + 0.6 × flare(beat + 0.16 s, 0.09))`; 0.025 when
  /// reduced. It carries on into the Ending.
  static double beatScale(
    double t,
    double finale,
    NeonBeat beat, {
    bool reducedFlashing = false,
  }) {
    // A hair of slack, so a time exactly on a beat counts as that beat
    // despite float rounding.
    final lb = beat.secToBeat(t - finale) + 1e-9;
    if (lb < 8) return 1;
    final on = finale + beat.beatToSec(lb.floor().toDouble());
    final amp = reducedFlashing ? 0.025 : 0.05;
    return 1 +
        amp *
            (NeonBeat.flare(t, on, 0.09) +
                0.6 * NeonBeat.flare(t, on + 0.16, 0.09));
  }
}

/// One confetti piece (§5.8) at a moment of its flight.
class NnConfettiPiece {
  const NnConfettiPiece({
    required this.position,
    required this.size,
    required this.degrees,
    required this.color,
    required this.opacity,
  });

  final Offset position;
  final Size size;
  final double degrees;
  final Color color;
  final double opacity;
}

/// The Finale's two confetti bursts (§5.8).
abstract final class NnConfetti {
  /// (burst seed, pieces, local beat).
  static const bursts = [(1, 70, 8.0), (2, 50, 12.0)];
  static const origin = Offset(540, 700);
  static const life = 5.0;

  static const _colors = [
    NeonColors.pink,
    NeonColors.cyan,
    NeonColors.green,
    NeonColors.violet,
  ];

  /// Piece [k] of burst [seed], [t] s after the burst; null outside its
  /// 5 s. Draws from `rng(seed × 1000 + k)` in this order: angle, speed,
  /// width, height, colour, start rotation, spin direction.
  static NnConfettiPiece? piece(int seed, int k, double t) {
    if (t < 0 || t > life) return null;
    final r = NeonRandom(NeonSeeds.confetti(seed, k));
    final angle = (-90 + (r.next() * 2 - 1) * 80) * math.pi / 180;
    final speed = 900 + 1100 * r.next();
    final width = 8 + 8 * r.next();
    final height = 14 + 12 * r.next();
    final color = _colors[(r.next() * _colors.length).floor()];
    final rotation = r.next() * 360;
    final spin = r.next() < 0.5 ? -450.0 : 450.0;
    final d = (1 - math.exp(-2.2 * t)) / 2.2;
    return NnConfettiPiece(
      position: Offset(
        origin.dx + math.cos(angle) * speed * d + 30 * math.sin(4 * t + k),
        origin.dy + math.sin(angle) * speed * d + 240 * t * t,
      ),
      size: Size(width, height),
      degrees: rotation + t * spin,
      color: color,
      opacity: t <= 3 ? 1 : 1 - (t - 3) / 2,
    );
  }
}

/// A 4×4 column-major matrix (what `Path.transform` takes): scale by [s],
/// then move by [offset].
Float64List _scaleThenMove(double s, Offset offset) => Float64List.fromList([
  s, 0, 0, 0, //
  0, s, 0, 0,
  0, 0, 1, 0,
  offset.dx, offset.dy, 0, 1,
]);

import 'dart:math' as math;
import 'dart:ui';

import '../film_eases.dart';
import 'gv_random.dart';
import 'golden_vows_tokens.dart';

typedef _E = FilmEases;

/// One photo tile of the heart: where it flies in from, how tilted, which
/// cell it settles in, and which of the memory's photos it shows.
class GvHeartTile {
  const GvHeartTile({
    required this.cell,
    required this.start,
    required this.tiltDeg,
    required this.photo,
  });

  final Offset cell;
  final Offset start;
  final double tiltDeg;

  /// Index into the heart's photos.
  final int photo;
}

/// One piece of confetti (spec §5.4), drawn in the spec's order.
class GvConfetti {
  const GvConfetti({
    required this.burst,
    required this.width,
    required this.height,
    required this.rotDeg,
    required this.fall,
    required this.round,
    required this.color,
  });

  /// Where the burst carries it, from the heart's centre.
  final Offset burst;
  final double width;
  final double height;
  final double rotDeg;
  final double fall;

  /// A round piece is a [width]×[width] circle.
  final bool round;
  final Color color;
}

/// A tile, a piece of confetti or the basket at one instant.
typedef GvPlaced = ({Offset centre, double angleDeg, double opacity});

/// Every photo forms a heart, which beats, bursts into confetti, gains
/// ropes and a basket and lifts off as the balloon (#346, spec §5.4). Pure
/// functions of film time; [start] is the spec's h0, when the heart page
/// lies open.
class GoldenVowsHeart {
  GoldenVowsHeart({required this.start, required this.photoCount})
    : assert(photoCount >= 0, 'photos: $photoCount') {
    final (size, cells) = layout(photoCount);
    cellSize = size;
    final r = GvRandom(53);
    tiles = photoCount == 0
        ? const []
        : [
            for (final (i, cell) in cells.indexed)
              () {
                final a = r.next() * 2 * math.pi;
                final tilt = r.next() * 70 - 35;
                return GvHeartTile(
                  cell: cell,
                  start: centre + Offset(math.cos(a), math.sin(a)) * 1450,
                  tiltDeg: tilt,
                  photo: i % photoCount,
                );
              }(),
          ];
    confetti = _confetti();
  }

  /// When the heart page lies open: the spec's h0.
  final double start;

  /// How many photos the heart has to show.
  final int photoCount;

  /// A cell's side; tiles are 4 px smaller.
  late final double cellSize;
  late final List<GvHeartTile> tiles;
  late final List<GvConfetti> confetti;

  static const centre = Offset(540, 900);
  static const radius = 370.0;

  /// The spec's photo cap: more than this and the tiles get too small.
  static const maxPhotos = 200;

  bool get isEmpty => tiles.isEmpty;

  double get tileSize => cellSize - 4;

  /// A tile's paper border.
  double get border => math.max(2.5, tileSize * 0.05);

  // ---- Layout (spec §5.4, ported line for line) ------------------------

  static bool _inside(double x, double y) {
    final a = x * x + y * y - 1;
    return a * a * a - x * x * y * y * y <= 0;
  }

  static List<Offset> _cells(double c) {
    final out = <Offset>[];
    final n = (1.4 * radius / c).ceil();
    for (var j = -n; j <= n; j++) {
      for (var i = -n; i <= n; i++) {
        final px = (i + .5) * c;
        final py = (j + .5) * c;
        if (_inside(px / radius, -py / radius + 0.1)) {
          out.add(Offset(centre.dx + px, centre.dy + py));
        }
      }
    }
    return out;
  }

  /// The cell size and cells for [photos]: the spec's search shrinks the
  /// cells by 1.5% until one more step would give more than max(N, 44).
  static (double, List<Offset>) layout(int photos) {
    var c = 340.0;
    var cells = _cells(c);
    final most = math.max(photos, 44);
    for (var k = 0; k < 300; k++) {
      final c2 = c * .985;
      final next = _cells(c2);
      if (next.length > most) break;
      c = c2;
      cells = next;
    }
    return (c, cells);
  }

  static const _confettiColors = [
    GoldenVowsColors.gold,
    GoldenVowsColors.goldLight,
    GoldenVowsColors.paper,
    GoldenVowsColors.blush,
    GoldenVowsColors.goldDeep,
  ];

  static List<GvConfetti> _confetti() {
    final r = GvRandom(29);
    return [
      for (var i = 0; i < 54; i++)
        () {
          final a = r.next() * 2 * math.pi;
          final d = 260 + r.next() * 520;
          final w = 10 + r.next() * 16;
          final h = 6 + r.next() * 8;
          final rot = r.next() * 720 - 360;
          final fall = 500 + r.next() * 500;
          final round = r.next() > 0.7;
          return GvConfetti(
            burst: Offset(math.cos(a) * d, math.sin(a) * d * 0.9 - 120),
            width: w,
            height: h,
            rotDeg: rot,
            fall: fall,
            round: round,
            color: _confettiColors[i % _confettiColors.length],
          );
        }(),
    ];
  }

  // ---- Timing (seconds from h0) ----------------------------------------

  static const flyFrom = 0.2;
  static const flySpread = 2.0;
  static const flyDur = 1.2;
  static const beatStart = 3.4;
  static const beatLeg = 0.35;
  static const burstStart = 3.45;
  static const burstDur = 1.1;
  static const fallStart = 4.55;
  static const fallDur = 2.6;
  static const ropeStarts = [4.0, 4.1];
  static const ropeDur = 0.8;
  static const lineStart = 4.4;
  static const lineInDur = 1.2;
  static const lineOutStart = 6.0;
  static const lineOutDur = 0.8;
  static const basketStart = 4.6;
  static const basketDur = 0.6;
  static const riseStart = 6.2;
  static const riseDur = 2.8;

  /// From h0 until the heart has risen away.
  static const length = riseStart + riseDur;

  static const ropes = [
    (Offset(474, 1241), Offset(508, 1399)),
    (Offset(606, 1241), Offset(572, 1399)),
  ];
  static const basket = Rect.fromLTWH(498, 1395, 84, 60);

  /// Whether any of the heart shows at [t].
  bool visibleAt(double t) => !isEmpty && t >= start && t < start + length;

  /// Tile [i]: flying in from far off, straightening as it settles.
  GvPlaced tileAt(int i, double t) {
    final tile = tiles[i];
    final p = _E.at(
      t - start,
      flyFrom + i / tiles.length * flySpread,
      flyDur,
      _E.power3Out,
    );
    return (
      centre: Offset.lerp(tile.start, tile.cell, p)!,
      angleDeg: tile.tiltDeg * (1 - p),
      opacity: 1,
    );
  }

  /// The heart's two beats: 1 → 1.05 → 1, twice, about its centre.
  double beatScaleAt(double t) {
    final local = t - start - beatStart;
    if (local <= 0 || local >= 4 * beatLeg) return 1;
    final leg = (local / beatLeg).floor();
    final p = _E.sineInOut(local / beatLeg - leg);
    return 1 + 0.05 * (leg.isEven ? p : 1 - p);
  }

  /// The whole heart (tiles, ropes, basket) rising away, tilting 3°.
  ({double dy, double angleDeg}) riseAt(double t) {
    final p = _E.at(t - start, riseStart, riseDur, _E.power2In);
    return (dy: -2100 * p, angleDeg: 3 * p);
  }

  /// How much of rope [i] has drawn on (0–1).
  double ropeAt(int i, double t) => _E.at(t - start, ropeStarts[i], ropeDur);

  /// The basket popping in from 32 px below with an overshoot.
  ({double dy, double opacity}) basketAt(double t) {
    final local = t - start;
    final p = _E.at(local, basketStart, basketDur, (p) => _E.backOut(p, 2));
    final fade = _E.at(local, basketStart, basketDur * 0.5);
    return (dy: 32 * (1 - p), opacity: fade);
  }

  /// The line under the balloon: rises in, then fades out.
  ({double top, double opacity}) lineAt(double t) {
    final local = t - start;
    final p = _E.at(local, lineStart, lineInDur);
    final out = _E.at(local, lineOutStart, lineOutDur);
    return (top: 1560 - 40 * p, opacity: p * (1 - out));
  }

  /// Piece [i]: bursting out, then falling and fading.
  GvPlaced confettiAt(int i, double t) {
    final piece = confetti[i];
    final local = t - start;
    final burst = _E.at(local, burstStart, burstDur, _E.power3Out);
    final fall = _E.at(local, fallStart, fallDur, _E.power1In);
    return (
      centre: centre + piece.burst * burst + Offset(0, piece.fall * fall),
      angleDeg: piece.rotDeg * (burst + fall),
      opacity: local < burstStart ? 0 : 1 - fall,
    );
  }
}

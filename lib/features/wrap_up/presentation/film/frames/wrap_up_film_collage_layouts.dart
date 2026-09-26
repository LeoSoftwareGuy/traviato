import 'dart:math' as math;
import 'dart:ui';

import '../../../domain/entities/wrap_up_collage_layout.dart';
import '../wrap_up_film_motion.dart';
import '../wrap_up_film_tokens.dart';

/// Which side a collage tile slides in from, or [zoom] for an in-place pop
/// (docs/design/WRAP_UP_FILM_COLLAGE_SPEC.md §3 `enterFrom`).
enum CollageEntry { left, right, top, bottom, zoom }

/// One collage tile in the film's 1080×1920 canvas space: a box, a tilt, the
/// edges that get a torn-paper outline, and its entrance direction.
class CollageTileSpec {
  const CollageTileSpec(
    this.x,
    this.y,
    this.w,
    this.h,
    this.rotationDeg,
    this.tornEdges,
    this.entry, {
    this.isHero = false,
  });

  final double x;
  final double y;
  final double w;
  final double h;
  final double rotationDeg;

  /// Any of `t r b l`; empty = a plain rectangle.
  final String tornEdges;
  final CollageEntry entry;

  /// torn6's centre piece: grayscale + contrast ×1.1, painted on top.
  final bool isHero;

  bool get isTorn => tornEdges.isNotEmpty;
}

/// A layout's tiles (in paint order) plus its backdrop.
class CollageLayoutSpec {
  const CollageLayoutSpec({
    required this.tiles,
    required this.background,
    required this.isPaper,
  });

  final List<CollageTileSpec> tiles;
  final Color background;

  /// Paper layouts (torn4, tilt6, torn6) drop a shadow under every tile.
  final bool isPaper;
}

const _l = CollageEntry.left;
const _r = CollageEntry.right;
const _t = CollageEntry.top;
const _b = CollageEntry.bottom;

/// The four layouts, verbatim from the collage spec §3.
const Map<WrapUpCollageLayout, CollageLayoutSpec> collageLayouts = {
  WrapUpCollageLayout.stack3: CollageLayoutSpec(
    background: WrapUpFilmColors.bg,
    isPaper: false,
    tiles: [
      CollageTileSpec(0, 0, 1080, 636, 0, '', _l),
      CollageTileSpec(0, 642, 1080, 636, 0, '', _r),
      CollageTileSpec(0, 1284, 1080, 636, 0, '', _l),
    ],
  ),
  WrapUpCollageLayout.torn4: CollageLayoutSpec(
    background: WrapUpFilmColors.paper,
    isPaper: true,
    tiles: [
      CollageTileSpec(0, 0, 572, 968, 0, 'rb', _t),
      CollageTileSpec(560, 0, 520, 952, 0, 'lb', _r),
      CollageTileSpec(0, 958, 462, 962, 0, 'tr', _l),
      CollageTileSpec(448, 944, 632, 976, 0, 'tl', _b),
    ],
  ),
  WrapUpCollageLayout.tilt6: CollageLayoutSpec(
    background: WrapUpFilmColors.paper,
    isPaper: true,
    tiles: [
      CollageTileSpec(-30, -30, 560, 600, -1.6, '', _t),
      CollageTileSpec(500, -50, 620, 820, 2.2, '', _r),
      CollageTileSpec(-40, 540, 620, 620, 1.2, '', _l),
      CollageTileSpec(520, 720, 600, 780, -2.6, '', _r),
      CollageTileSpec(-50, 1140, 720, 820, -1.0, '', _b),
      CollageTileSpec(640, 1460, 480, 500, 2.4, '', _b),
    ],
  ),
  WrapUpCollageLayout.torn6: CollageLayoutSpec(
    background: WrapUpFilmColors.paper,
    isPaper: true,
    tiles: [
      CollageTileSpec(0, 0, 586, 760, 0, 'rb', _t),
      CollageTileSpec(576, 0, 504, 860, 0, 'lb', _r),
      CollageTileSpec(560, 850, 520, 820, 0, 'tl', _r),
      CollageTileSpec(0, 1660, 590, 260, 0, 'tr', _b),
      CollageTileSpec(580, 1650, 500, 270, 0, 'tl', _b),
      CollageTileSpec(
        0,
        720,
        780,
        960,
        0,
        'trb',
        CollageEntry.zoom,
        isHero: true,
      ),
    ],
  ),
};

/// How far straight (untorn) edges of a torn tile reach past the tile, so a
/// rotated or sliding tile never shows a gap along them.
const double tornEdgeOverhang = 60;

final Map<String, Path> _tornPathCache = {};

/// The closed torn-paper outline for a `w × h` tile (collage spec §5), in the
/// tile's own coordinates. Deterministic for a given input — cached, so the
/// tear is identical every frame and every replay.
Path tornOutline({
  required double w,
  required double h,
  required String tornEdges,
  required int seed,
  required double amp,
  required double pad,
}) {
  final key = '$w|$h|$tornEdges|$seed|$amp|$pad';
  return _tornPathCache.putIfAbsent(
    key,
    () => _buildTornOutline(w, h, tornEdges, seed, amp, pad),
  );
}

Path _buildTornOutline(
  double w,
  double h,
  String tornEdges,
  int seed,
  double amp,
  double pad,
) {
  const e = tornEdgeOverhang;
  final t = tornEdges.contains('t');
  final r = tornEdges.contains('r');
  final b = tornEdges.contains('b');
  final l = tornEdges.contains('l');

  final tl = Offset(l ? 0 : -e, t ? 0 : -e);
  final tr = Offset(r ? w : w + e, t ? 0 : -e);
  final br = Offset(r ? w : w + e, b ? h : h + e);
  final bl = Offset(l ? 0 : -e, b ? h : h + e);

  // (start, end, outward normal, torn?, edge index s = 1..4)
  final edges = <(Offset, Offset, Offset, bool, int)>[
    (tl, tr, const Offset(0, -1), t, 1),
    (tr, br, const Offset(1, 0), r, 2),
    (br, bl, const Offset(0, 1), b, 3),
    (bl, tl, const Offset(-1, 0), l, 4),
  ];

  final points = <Offset>[];
  for (final (start, end, normal, torn, s) in edges) {
    if (!torn) {
      points.add(start);
      continue;
    }
    final n = math.max(2, ((end - start).distance / 13).round());
    for (var k = 0; k < n; k++) {
      final p = k / n;
      final jitter = k == 0
          ? 0.0
          : (rnd(k + seed * 31, s) - .5) * 2 * amp +
                (rnd(k * 3 + seed, s + 7) - .5) * amp * .8;
      points.add(start + (end - start) * p + normal * (jitter + pad));
    }
  }
  return Path()..addPolygon(points, true);
}

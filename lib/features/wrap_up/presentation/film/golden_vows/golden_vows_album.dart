import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/rendering.dart' show Matrix4;

import '../film_eases.dart';
import 'golden_vows_scene_spec.dart';
import 'golden_vows_story.dart' show GvChapterLayout;
import 'golden_vows_timeline.dart';

typedef _E = FilmEases;

/// One leaf of the album: the cover, or a page (spec §5.3).
class GvLeaf {
  const GvLeaf({
    required this.page,
    required this.showFrom,
    required this.turnAt,
  });

  /// Null for the cover.
  final GvPageSpec? page;

  /// When it starts to show: the album's rise for the cover, else the
  /// moment the leaf above it starts to turn.
  final double showFrom;

  /// When it starts to turn; null for the heart page, which never does.
  final double? turnAt;

  /// When it has turned away; the heart page stays until the album leaves.
  double get goneAt =>
      turnAt == null ? double.infinity : turnAt! + GoldenVowsTimeline.turnDur;
}

/// A leaf's turn at one instant: its angle about the spine, the ink
/// shade over it and its opacity.
typedef GvTurn = ({double angleDeg, double shade, double opacity});

/// The album's movement (spec §5.3, §5.5) as pure functions of film time.
class GoldenVowsAlbum {
  GoldenVowsAlbum(this.timeline)
    : riseAt = timeline.film.first<GvAlbumOpenSpec>()!.start,
      closeAt = timeline.closeStart {
    final leaves = <GvLeaf>[];
    var showFrom = riseAt;
    for (final scene in timeline.film.scenes) {
      switch (scene.spec) {
        case GvAlbumOpenSpec():
          final turnAt = scene.start + GoldenVowsTimeline.albumRiseDur;
          leaves.add(GvLeaf(page: null, showFrom: showFrom, turnAt: turnAt));
          showFrom = turnAt;
        case final GvPageSpec page:
          final turnAt = page.kind == GvPageKind.heart
              ? null
              : scene.end - GoldenVowsTimeline.turnDur;
          leaves.add(GvLeaf(page: page, showFrom: showFrom, turnAt: turnAt));
          if (turnAt != null) showFrom = turnAt;
        default:
      }
    }
    this.leaves = List.unmodifiable(leaves);
  }

  final GoldenVowsTimeline timeline;

  /// When the closed album starts to rise (spec: 11.9).
  final double riseAt;

  /// When the cover swings back (spec: 59.95).
  final double closeAt;

  /// The cover first, then the pages in order.
  late final List<GvLeaf> leaves;

  // ---- Geometry (canvas px) ------------------------------------------

  static const spineX = 70.0;
  static const pageRect = Rect.fromLTWH(70, 220, 940, 1480);
  static const boardRect = Rect.fromLTWH(80, 232, 940, 1480);
  static const edgeRect = Rect.fromLTWH(75, 226, 940, 1480);
  static const perspective = 2600.0;

  static const riseDur = 1.2;
  static const closeDur = 1.3;

  /// The closed album leaves this long after the cover swings back.
  static const leaveAfter = 1.4;
  static const leaveDur = 1.0;

  /// The ink shade a turning leaf reaches, and how fast.
  static const maxShade = 0.32;
  static const shadeDur = 0.875;
  static const fadeDur = 0.25;
  static const turnTo = -100.0;
  static const zoomTo = 1.08;

  /// Whether any of the album shows at [t].
  bool visibleAt(double t) =>
      t >= riseAt && t < closeAt + leaveAfter + leaveDur;

  /// The whole album's offset, tilt, scale and opacity: it rises in,
  /// then rises away smaller.
  ({double dy, double angleDeg, double scale, double opacity}) bodyAt(
    double t,
  ) {
    final rise = _E.at(t, riseAt, riseDur, _E.power3Out);
    final leave = _E.at(t, closeAt + leaveAfter, leaveDur, _E.power2In);
    return (
      dy: 1950 * (1 - rise) - 320 * leave,
      angleDeg: 3 * (1 - rise),
      scale: 1 - 0.08 * leave,
      opacity: 1 - leave,
    );
  }

  /// The leaf on top at [t] (fully open or turning): the first not yet
  /// turned away. Once the album closes, the cover is back on top.
  int topAt(double t) {
    if (t >= closeAt) return 0;
    for (var i = 0; i < leaves.length; i++) {
      if (t < leaves[i].goneAt) return i;
    }
    return leaves.length - 1;
  }

  /// The top leaf's turn at [t]: flat until its turn, then 0° → −100°
  /// with the shade coming on and a fade at the end. The cover swings
  /// back at the close, its shade clearing.
  GvTurn turnAt(int index, double t) {
    if (index == 0 && t >= closeAt) {
      final p = _E.at(t, closeAt, closeDur, _E.power2InOut);
      return (
        angleDeg: turnTo * (1 - p),
        shade: maxShade * (1 - p),
        opacity: 1,
      );
    }
    final start = leaves[index].turnAt;
    if (start == null || t < start) {
      return (angleDeg: 0, shade: 0, opacity: 1);
    }
    final local = t - start;
    return (
      angleDeg:
          turnTo *
          _E.power2InOut((local / GoldenVowsTimeline.turnDur).clamp(0, 1)),
      shade: maxShade * _E.at(local, 0, shadeDur),
      opacity: 1 - _E.at(local, GoldenVowsTimeline.turnDur - fadeDur, fadeDur),
    );
  }

  /// How far the leaf's photos have zoomed (1 → 1.08, sine.out) over its
  /// whole visible life.
  double zoomAt(int index, double t) {
    final leaf = leaves[index];
    final end = leaf.turnAt == null ? closeAt : leaf.goneAt;
    final life = end - leaf.showFrom;
    if (life <= 0) return 1;
    return 1 +
        (zoomTo - 1) * _E.sineOut(((t - leaf.showFrom) / life).clamp(0, 1));
  }

  /// How far through its visible life (0–1, sine.inOut) the leaf is: the
  /// carousel's rows slide with it.
  double slideAt(int index, double t) {
    final leaf = leaves[index];
    final life = leaf.goneAt - leaf.showFrom;
    if (!life.isFinite || life <= 0) return 0;
    return _E.sineInOut(((t - leaf.showFrom) / life).clamp(0, 1));
  }

  /// The hinge: a turn of [angleDeg] about the vertical axis through the
  /// spine, with the spec's perspective seen from the spine itself (the
  /// reference's `perspective(2600px) rotateY()` on a page whose transform
  /// origin is its spine edge, at the page's mid-height).
  static Matrix4 hinge(double angleDeg) {
    final origin = Offset(spineX, pageRect.center.dy);
    return Matrix4.translationValues(origin.dx, origin.dy, 0)
      ..multiply(Matrix4.identity()..setEntry(3, 2, -1 / perspective))
      ..multiply(Matrix4.rotationY(angleDeg * math.pi / 180))
      ..multiply(Matrix4.translationValues(-origin.dx, -origin.dy, 0));
  }
}

/// The part of an image of [image] size that fills [box] edge to edge
/// (centred), seen [zoom] times closer: photos are cover-cropped.
Rect gvCoverCrop(Size image, Size box, [double zoom = 1]) {
  final scale = math.max(box.width / image.width, box.height / image.height);
  return Rect.fromCenter(
    center: Offset(image.width / 2, image.height / 2),
    width: box.width / scale / zoom,
    height: box.height / scale / zoom,
  );
}

/// The carousel's prints (spec §5.3): two rows of up to 6, each 460 tall
/// with its width from the photo's aspect.
abstract final class GvCarouselLayout {
  static const window = Rect.fromLTWH(84, 470, 912, 1180);
  static const printHeight = 460.0;
  static const photoHeight = 430.0;
  static const border = 15.0;
  static const gap = 36.0;
  static const tiltDeg = 1.8;
  static const rowTops = [20.0, 570.0];

  /// A print's width for a photo of [aspect] (width / height).
  static double printWidth(double aspect) =>
      (photoHeight * aspect.clamp(0.68, 1.45)).roundToDouble() + 2 * border;

  static double rowWidth(List<double> widths) => widths.isEmpty
      ? 0
      : widths.reduce((a, b) => a + b) + gap * (widths.length - 1);

  /// The rows' left edges, in the window, at [slide] (0–1): row 1 from 40
  /// to −1460, row 2 from its right edge at 870 to 1500 further right.
  static double rowX(int row, double rowWidth, double slide) =>
      row == 0 ? 40 - 1500 * slide : 870 - rowWidth + 1500 * slide;

  /// The photos split into the two rows, the first row taking the odd one.
  static List<List<T>> rows<T>(List<T> photos) {
    final first = (photos.length + 1) ~/ 2;
    return [photos.sublist(0, first), photos.sublist(first)];
  }
}

/// The chapter pages' print spots (spec §5.3): (x, y, w, h, tilt°).
abstract final class GvChapterLayouts {
  static const a = [
    (120.0, 470.0, 840.0, 600.0, -1.2),
    (120.0, 1100.0, 405.0, 520.0, 1.5),
    (555.0, 1100.0, 405.0, 520.0, -1.0),
  ];
  static const b = [
    (120.0, 470.0, 470.0, 1150.0, -1.0),
    (620.0, 470.0, 340.0, 560.0, 1.6),
    (620.0, 1060.0, 340.0, 560.0, -1.4),
  ];
  static const c = [
    (120.0, 470.0, 405.0, 520.0, -1.5),
    (555.0, 470.0, 405.0, 520.0, 1.2),
    (120.0, 1020.0, 840.0, 600.0, 1.0),
  ];

  /// The chapter's [layout], else A, B, C in turn.
  static List<(double, double, double, double, double)> forChapter(
    int i, [
    GvChapterLayout? layout,
  ]) => switch (layout) {
    GvChapterLayout.a => a,
    GvChapterLayout.b => b,
    GvChapterLayout.c => c,
    null => const [a, b, c][i % 3],
  };
}

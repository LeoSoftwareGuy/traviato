import 'dart:math' as math;
import 'dart:ui';

import 'neon_beat.dart';
import 'neon_eases.dart';
import 'neon_tokens.dart';

/// Where the moments' pieces sit (#363, NEON_NIGHT_SPEC.md §5.4–5.6) and
/// how they move, as pure functions of local beats `lb`. The painting is
/// in `NnMomentPainter`.
abstract final class NnMomentLayout {
  /// Every moment's label box (split, burst).
  static const labelAt = Offset(48, 1760);

  /// Each moment's Ken Burns across the scene (§3.5: 0.06–0.15). The spec
  /// gives only Split's.
  static const kbSplit = 0.14;
  static const kbBurst = 0.08;
  static const kbTimeline = 0.06;
  static const kbPeak = 0.10;
}

/// Split (§5.4a): 2–3 strips side by side.
abstract final class NnSplitLayout {
  static const top = 440.0;
  static const height = 1000.0;
  static const gap = 26.0;
  static const radius = 22.0;
  static const border = 6.0;
  static const colors = [NeonColors.pink, NeonColors.cyan, NeonColors.green];

  /// `sw = (1000 − 26(n − 1)) / n`: 316 for 3, 487 for 2.
  static double stripWidth(int n) => (1000 - gap * (n - 1)) / n;

  static Rect strip(int i, int n) {
    final sw = stripWidth(n);
    return Rect.fromLTWH(40 + i * (sw + gap), top, sw, height);
  }

  /// Strip [i] wipes down from lb 0.5 i over 0.45 s (enter): how much of
  /// it shows, 0–1.
  static double wipe(double lb, int i, NeonBeat beat) {
    final since = beat.beatToSec(lb - 0.5 * i);
    return NeonEases.enter((since / 0.45).clamp(0.0, 1.0));
  }

  /// The beats strip [i] pulses on: lb 2 + i and 5 + i.
  static List<double> pulses(int i) => [2.0 + i, 5.0 + i];
}

/// One of Burst's tilted frames.
class NnBurstFrame {
  const NnBurstFrame(this.rect, this.degrees, this.color);

  final Rect rect;
  final double degrees;
  final Color color;
}

/// Burst (§5.4b): up to 4 tilted frames popping in, then each jumping to
/// the front in turn.
abstract final class NnBurstLayout {
  /// Painted in this order; 2–3 photos use the first slots.
  static const frames = [
    NnBurstFrame(Rect.fromLTWH(50, 140, 720, 450), -3, NeonColors.pink),
    NnBurstFrame(Rect.fromLTWH(340, 560, 680, 420), 2.5, NeonColors.cyan),
    NnBurstFrame(Rect.fromLTWH(40, 920, 740, 460), -2, NeonColors.green),
    NnBurstFrame(Rect.fromLTWH(400, 1240, 600, 380), 2.5, NeonColors.violet),
  ];
  static const radius = 22.0;
  static const border = 6.0;

  /// Frame [i]'s pop at lb 1 + i: its scale (1.25 → 1, settling past 1)
  /// and opacity (in over 0.13 s); (0, 0) before it.
  static (double scale, double alpha) pop(double lb, int i, NeonBeat beat) {
    final since = beat.beatToSec(lb - 1 - i);
    if (since < 0) return (0, 0);
    final p = (since / 0.4).clamp(0.0, 1.0);
    return (1.25 - 0.25 * NeonEases.pop(p), (since / 0.13).clamp(0.0, 1.0));
  }

  /// Frame [i]'s jump: from lb 5 + i for a beat it is on top at × 1.06,
  /// easing back over the beat's last 40 %. Null outside it.
  static double? jump(double lb, int i) {
    final p = lb - 5 - i;
    if (p < 0 || p >= 1) return null;
    if (p < 0.6) return 1.06;
    return 1.06 - 0.06 * NeonEases.enter((p - 0.6) / 0.4);
  }

  /// Who is painted when at [lb]: in order, the jumping one last.
  static List<int> order(double lb, int n) {
    final jumping = [
      for (var i = 0; i < n; i++)
        if (jump(lb, i) != null) i,
    ];
    return [
      for (var i = 0; i < n; i++)
        if (!jumping.contains(i)) i,
      ...jumping,
    ];
  }
}

/// Timeline (§5.5b): 2–8 photos in a two-column masonry, highlighted one
/// per beat while the list scrolls under a fixed title.
class NnTimelineLayout {
  factory NnTimelineLayout(int m) {
    assert(m >= 2 && m <= 8, 'timeline: $m items');
    final columns = [top, top];
    final items = <Rect>[];
    for (var i = 0; i < m; i++) {
      final h = i == 1 || i == 6 ? 560.0 : 280.0;
      final c = columns[1] < columns[0] ? 1 : 0;
      items.add(Rect.fromLTWH(c == 0 ? 70 : 570, columns[c], width, h));
      columns[c] += h + 100;
    }
    final bottom = items.map((r) => r.bottom).reduce(math.max);
    return NnTimelineLayout._(items, bottom + timeGap + timeHeight);
  }

  NnTimelineLayout._(this.items, this.contentBottom);

  static const top = 330.0;
  static const width = 440.0;
  static const timeGap = 14.0;

  /// The time label's line height (mono 44 × 1.2).
  static const timeHeight = 52.8;

  /// Each item's frame, unscrolled, in time order.
  final List<Rect> items;

  /// Where the list ends (the last time label's foot).
  final double contentBottom;

  int get length => items.length;

  /// How far the list can scroll: `contentBottom − 1540`, at least 0.
  double get maxScroll => math.max(0, contentBottom - 1540);

  /// The scroll that centres item [j] (at y 900).
  double scrollFor(int j) => (items[j].center.dy - 900).clamp(0.0, maxScroll);

  /// The item highlighted at [lb]: one per beat from lb 2, holding on the
  /// last. Null before lb 2.
  int? highlightAt(double lb) {
    if (lb < 2) return null;
    return math.min((lb - 2).floor(), length - 1);
  }

  /// The list's scroll at [lb]: each new highlight scrolls to centre it
  /// over 0.35 s (scroll ease).
  double scrollAt(double lb, NeonBeat beat) {
    final j = highlightAt(lb);
    if (j == null) return 0;
    final from = j == 0 ? 0.0 : scrollFor(j - 1);
    final to = scrollFor(j);
    if (j < (lb - 2).floor()) return to;
    final since = beat.beatToSec(lb - 2 - j);
    return from + (to - from) * NeonEases.scroll((since / 0.35).clamp(0, 1));
  }

  /// When item [i] rises in, s after the cue: lb 1 + 0.06 s × i.
  double enterAt(int i, NeonBeat beat) => beat.beatToSec(1) + 0.06 * i;

  /// The list's mask: clear above 250, solid 330–1470, clear by 1600.
  static const maskStops = [250.0, 330.0, 1470.0, 1600.0];
}

/// Peak (§5.6b): 3–5 tapered strips fanned over a laser fan.
abstract final class NnPeakLayout {
  static const pivot = Offset(540, 1790);
  static const stripWidth = 250.0;
  static const stripHeight = 1150.0;
  static const fanDegrees = 16.0;

  /// The strip's box, bottom centre on the pivot, before it turns.
  static final Rect box = Rect.fromLTWH(
    pivot.dx - stripWidth / 2,
    pivot.dy - stripHeight,
    stripWidth,
    stripHeight,
  );

  /// `polygon(0 0, 100% 0, 54% 100%, 46% 100%)` in [box].
  static final Path shape = Path()
    ..moveTo(box.left, box.top)
    ..lineTo(box.right, box.top)
    ..lineTo(box.left + 0.54 * stripWidth, box.bottom)
    ..lineTo(box.left + 0.46 * stripWidth, box.bottom)
    ..close();

  /// Strip [i]'s final angle: `(i − (n − 1)/2) × 16°`.
  static double degrees(int i, int n) => (i - (n - 1) / 2) * fanDegrees;

  /// Its angle at [lb]: it pops (back-out) from 0 over 0.6 s, from
  /// 0.08 s × i.
  static double degreesAt(double lb, int i, int n, NeonBeat beat) {
    final since = beat.beatToSec(lb) - 0.08 * i;
    return degrees(i, n) * NeonEases.pop((since / 0.6).clamp(0.0, 1.0));
  }

  /// Centre strip green, the others pink.
  static Color color(int i, int n) =>
      i * 2 == n - 1 ? NeonColors.green : NeonColors.pink;

  /// The beats strip [i] pulses on: lb 2 + i, then all at 7.
  static List<double> pulses(int i) => [2.0 + i, 7.0];

  /// Paint order at [lb]: outer strips first; the one pulsing last.
  static List<int> order(double lb, int n) {
    final centre = (n - 1) / 2;
    final out = [for (var i = 0; i < n; i++) i]
      ..sort((a, b) {
        final byDistance = (b - centre).abs().compareTo((a - centre).abs());
        return byDistance != 0 ? byDistance : a.compareTo(b);
      });
    final pulsing = (lb - 2).floor();
    if (lb >= 2 && lb < 7 && pulsing < n && out.remove(pulsing)) {
      out.add(pulsing);
    }
    return out;
  }

  /// The laser fan: 9 beams, −80° … +80° in 20° steps, cyan and pink.
  static const beams = 9;
  static const beamWidth = 18.0;
  static const beamLength = 1500.0;
  static double beamDegrees(int k) => -80.0 + 20 * k;
  static Color beamColor(int k) => k.isEven ? NeonColors.cyan : NeonColors.pink;
}

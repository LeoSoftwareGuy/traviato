/// Neon Night's seeded random (#363, NEON_NIGHT_SPEC.md §3.3): mulberry32,
/// ported exactly, so the same seed gives the same grain, glitch slices,
/// highlights and confetti on every render and every platform.
///
/// ```js
/// rng(seed): a = seed >>> 0
///   next(): a = (a + 0x6D2B79F5)>>>0; t = a;
///           t = imul(t ^ t>>>15, t | 1);
///           t ^= t + imul(t ^ t>>>7, t | 61);
///           return ((t ^ t>>>14)>>>0) / 2^32
/// ```
///
/// Kept apart from Golden Vows' generator: the two specs use different
/// ones, and each must match its own reference.
class NeonRandom {
  NeonRandom(int seed) : _a = seed & _mask;

  static const _mask = 0xFFFFFFFF;
  int _a;

  /// The next value in [0, 1).
  double next() {
    _a = (_a + 0x6D2B79F5) & _mask;
    var t = _a;
    t = _imul(t ^ (t >>> 15), t | 1);
    t = (t ^ ((t + _imul(t ^ (t >>> 7), t | 61)) & _mask)) & _mask;
    return ((t ^ (t >>> 14)) & _mask) / 4294967296;
  }

  /// JS `Math.imul` on unsigned 32-bit values: the low 32 bits of the
  /// product, split in halves so the product never leaves 53 bits.
  static int _imul(int a, int b) {
    final lo = (a & 0xFFFF) * b;
    final hi = (((a >>> 16) * b) & 0xFFFF) << 16;
    return (lo + hi) & _mask;
  }
}

/// The spec's seed formulas (§3.3 and the scenes in §5), named so every
/// effect draws from the same stream on every platform.
abstract final class NeonSeeds {
  /// The grain tile's offset for [frame].
  static int grain(int frame) => frame * 7 + 3;

  /// A placeholder photo's colours (fixtures only).
  static int placeholderPhoto(int i) => i * 977 + 13;

  /// A glitch-in's slices on [frame] of a title seeded [seed].
  static int glitch(int seed, int frame) => seed * 131 + frame;

  /// The [j]-th highlight jump on chapter [chapter]'s contact sheet.
  static int highlight(int chapter, int j) => chapter * 1000 + j;

  /// Which tiles chapter [chapter]'s laser zooms pick.
  static int zoomPicks(int chapter) => chapter * 77 + 1;

  /// Mosaic piece [k]'s order and flight.
  static int mosaicOrder(int k) => k * 53 + 9;
  static int mosaicFlight(int k) => k * 31 + 5;

  /// Confetti piece [k] of a burst seeded [burst].
  static int confetti(int burst, int k) => burst * 1000 + k;

  /// The heart cells' pop-in shuffle (Fisher–Yates).
  static const int heartShuffle = 424242;
}

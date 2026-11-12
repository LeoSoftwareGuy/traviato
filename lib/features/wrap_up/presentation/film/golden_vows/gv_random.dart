/// The spec's seeded random (golden-vows-spec.md §2, #346), ported
/// exactly: a 32-bit linear congruential generator, so the same seed gives
/// the same petals, heart and confetti on every render.
///
/// ```js
/// const rng = seed => { let s = seed >>> 0;
///   return () => (s = (s * 1664525 + 1013904223) >>> 0) / 4294967296; };
/// ```
class GvRandom {
  GvRandom(int seed) : _s = seed & _mask;

  static const _mask = 0xFFFFFFFF;
  int _s;

  /// The next value in [0, 1).
  double next() {
    _s = (_s * 1664525 + 1013904223) & _mask;
    return _s / 4294967296;
  }
}

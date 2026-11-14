import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_random.dart';

void main() {
  // Computed with the spec's JS (NEON_NIGHT_SPEC.md §3.3) in Node.
  test("matches the spec's mulberry32, value for value", () {
    const expected = {
      11: [
        0.5115870486479253,
        0.5299464082345366,
        0.6081185641232878,
        0.5901576359756291,
      ],
      424242: [
        0.1287079993635416,
        0.23631658218801022,
        0.18376533640548587,
        0.64380112150684,
      ],
      3: [
        0.7202267837710679,
        0.03866216051392257,
        0.4561921926215291,
        0.07492800964973867,
      ],
      0: [
        0.26642920868471265,
        0.0003297457005828619,
        0.2232720274478197,
        0.1462021479383111,
      ],
    };
    for (final MapEntry(key: seed, value: values) in expected.entries) {
      final r = NeonRandom(seed);
      expect([for (var i = 0; i < 4; i++) r.next()], values, reason: '$seed');
    }
  });

  test('the same seed gives the same stream; stays in [0, 1)', () {
    final a = NeonRandom(NeonSeeds.grain(1234));
    final b = NeonRandom(NeonSeeds.grain(1234));
    for (var i = 0; i < 100000; i++) {
      final v = a.next();
      expect(v, b.next());
      expect(v >= 0 && v < 1, isTrue);
    }
  });

  test("the spec's seed formulas", () {
    expect(NeonSeeds.grain(10), 73);
    expect(NeonSeeds.placeholderPhoto(2), 1967);
    expect(NeonSeeds.glitch(11, 4), 1445);
    expect(NeonSeeds.highlight(3, 2), 3002);
    expect(NeonSeeds.zoomPicks(1), 78);
    expect(NeonSeeds.mosaicOrder(1), 62);
    expect(NeonSeeds.mosaicFlight(1), 36);
    expect(NeonSeeds.confetti(2, 5), 2005);
  });
}

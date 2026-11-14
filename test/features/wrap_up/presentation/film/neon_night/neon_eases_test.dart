import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_eases.dart';

void main() {
  test("the spec's eases (§3.4)", () {
    // easeOutCubic, easeOutBack, easeOutExpo, easeInOutCubic.
    expect(NeonEases.enter(0.5), 0.875);
    expect(NeonEases.pop(0.5), closeTo(1.0876975, 1e-6));
    expect(NeonEases.slam(0.1), 0.5);
    expect(NeonEases.scroll(0.25), 0.0625);
    expect(NeonEases.scroll(0.75), 0.9375);
    expect(NeonEases.kenBurns(0.3), 0.3);
    for (final ease in [
      NeonEases.enter,
      NeonEases.pop,
      NeonEases.slam,
      NeonEases.scroll,
    ]) {
      expect(ease(0), closeTo(0, 1e-12));
      expect(ease(1), closeTo(1, 1e-12));
    }
  });
}

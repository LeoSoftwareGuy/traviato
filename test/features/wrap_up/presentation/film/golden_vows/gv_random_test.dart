import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/wrap_up/presentation/film/golden_vows/gv_random.dart';

void main() {
  // Computed with the spec's JS arithmetic (golden-vows-spec.md §2).
  test("matches the spec's generator, value for value", () {
    final petals = GvRandom(11);
    expect(
      [for (var i = 0; i < 4; i++) petals.next()],
      [
        0.2403310495428741,
        0.2763083253521472,
        0.35132475569844246,
        0.07504692277871072,
      ],
    );
    final heart = GvRandom(53);
    expect(
      [heart.next(), heart.next()],
      [
        0.2566082514822483,
        0.08586646220646799,
      ],
    );
  });

  test('stays in [0, 1) for a long run', () {
    final r = GvRandom(29);
    for (var i = 0; i < 100000; i++) {
      final v = r.next();
      expect(v >= 0 && v < 1, isTrue);
    }
  });
}

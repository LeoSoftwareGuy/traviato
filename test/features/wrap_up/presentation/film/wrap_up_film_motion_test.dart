import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/wrap_up/presentation/film/wrap_up_film_motion.dart';

void main() {
  group('rise', () {
    test('is 0 opacity / full lift before start', () {
      final r = rise(0, 5, 2);
      expect(r.opacity, 0);
      expect(r.translateY, 38);
    });

    test('reaches full opacity / zero lift once dur has elapsed', () {
      final r = rise(7, 5, 2);
      expect(r.opacity, 1);
      expect(r.translateY, 0);
    });

    test('honours a custom lift', () {
      final r = rise(0, 5, 2, lift: 10);
      expect(r.translateY, 10);
    });
  });

  group('fade', () {
    test('holds `from` before start and `to` after start+dur', () {
      expect(fade(0, 5, 2, 1, 0), 1);
      expect(fade(10, 5, 2, 1, 0), 0);
    });

    test('is partway through mid-transition', () {
      final mid = fade(6, 5, 2, 0, 10);
      expect(mid, greaterThan(0));
      expect(mid, lessThan(10));
    });
  });

  group('swell', () {
    test('is linear, unlike fade', () {
      // At the exact midpoint, a linear ease always lands at 50% — a curved
      // one (easeInOutSine) would not for an asymmetric-looking check, but
      // midpoint symmetry alone doesn't distinguish them, so assert the
      // quarter point instead where linear and easeInOutSine diverge.
      final quarter = swell(2.5, 0, 10, 0, 100);
      expect(quarter, 25); // exactly proportional for a linear ramp
    });

    test('holds `from`/`to` outside its window', () {
      expect(swell(-1, 0, 10, 2, 8), 2);
      expect(swell(11, 0, 10, 2, 8), 8);
    });
  });

  group('toss', () {
    test('starts at 0 and can overshoot past 1 before settling', () {
      expect(toss(0, 0, 1), 0);
      final overshoot = List.generate(20, (i) => toss(i / 20, 0, 1));
      expect(overshoot.any((v) => v > 1.0), isTrue);
      expect(toss(2, 0, 1), 1);
    });
  });

  group('band', () {
    test('is 0 outside the window, 1 on the plateau', () {
      expect(band(0, 1, 1, 5, 1), 0);
      expect(band(3, 1, 1, 5, 1), 1);
      expect(band(10, 1, 1, 5, 1), 0);
    });
  });

  group('rnd', () {
    test('is deterministic for the same (index, salt)', () {
      expect(rnd(3, 9), rnd(3, 9));
    });

    test('stays within [0, 1)', () {
      for (var i = 0; i < 50; i++) {
        final v = rnd(i, 31);
        expect(v, greaterThanOrEqualTo(0));
        expect(v, lessThan(1));
      }
    });

    test('differs across salts (not a constant)', () {
      final values = {for (var s = 0; s < 10; s++) rnd(5, s)};
      expect(values.length, greaterThan(1));
    });
  });

  group('mix', () {
    test('linearly interpolates between two values', () {
      expect(mix(0, 10, 0.5), 5);
      expect(mix(0, 10, 0), 0);
      expect(mix(0, 10, 1), 10);
    });
  });
}

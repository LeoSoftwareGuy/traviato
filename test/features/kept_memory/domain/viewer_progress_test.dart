import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/kept_memory/domain/viewer_progress.dart';

void main() {
  group('dayProgressFills', () {
    test('fills earlier days, part of the current one, none after', () {
      // Days of 4, 2 and 4 photos; index 5 is day 2's second photo.
      expect(dayProgressFills([4, 2, 4], 5), [1.0, 1.0, 0.0]);
      // Index 4 is day 2's first photo.
      expect(dayProgressFills([4, 2, 4], 4), [1.0, .5, 0.0]);
    });

    test('the first photo fills one step of the first day', () {
      expect(dayProgressFills([4, 2], 0), [.25, 0.0]);
    });

    test('the last photo fills every day', () {
      expect(dayProgressFills([4, 2, 4], 9), [1.0, 1.0, 1.0]);
    });
  });

  group('nextSlideshowIndex', () {
    test('advances, then loops back to the first photo', () {
      expect(nextSlideshowIndex(0, 3), 1);
      expect(nextSlideshowIndex(2, 3), 0);
    });

    test('a single photo stays put', () {
      expect(nextSlideshowIndex(0, 1), 0);
    });
  });
}

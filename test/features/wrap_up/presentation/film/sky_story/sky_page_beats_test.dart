import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/wrap_up/presentation/film/sky_story/sky_page_beats.dart';
import 'package:traviato/features/wrap_up/presentation/film/sky_story/sky_story.dart';
import 'package:traviato/features/wrap_up/presentation/film/sky_story/sky_story_timeline.dart';
import 'package:traviato/features/wrap_up/presentation/film/sky_story/sky_world.dart';

void main() {
  group('the reference film (3 pages)', () {
    final pages = SkyPageBeats.all(SkyStoryTimeline.forChapters(3));
    final [day1, day2, day3] = pages;

    test('layouts', () {
      expect(
        [for (final p in pages) p.layout],
        [
          SkyPageLayout.fan,
          SkyPageLayout.taped,
          SkyPageLayout.flyOut,
        ],
      );
    });

    test('day 1 matches the reference frames', () {
      expect(day1.headerIn, closeTo(5.7, 0.1));
      // Photos land at 6.1, 6.35, 6.6, 6.85; the hero by 8.0.
      expect(day1.dealAt(0), closeTo(6.1, 1e-9));
      expect(day1.dealAt(3), closeTo(6.85, 1e-9));
      expect(day1.heroAt + 0.65, closeTo(8.0, 1e-9));
      expect(day1.cardAt, closeTo(8.2, 1e-9));
      expect(day1.fanSignatureAt, closeTo(9.8, 1e-9));
    });

    test('day 2: grid, hero, card, badge, then the writing', () {
      expect(day2.dealAt(0), closeTo(18.75, 1e-9));
      expect(day2.dealAt(3), lessThan(day2.heroAt));
      expect(day2.heroAt, lessThan(day2.cardAt));
      expect(day2.cardAt, lessThan(day2.badgeAt));
      expect(day2.badgeAt, lessThan(day2.writeAt));
      expect(day2.writeAt, closeTo(21.45, 1e-9));
    });

    test('day 3: photos out of the balloon first, the hero at 34.75', () {
      expect(day3.dealAt(0), closeTo(31.0, 1e-9));
      expect(day3.heroAt, closeTo(34.75, 1e-9));
      expect(day3.cardAt, greaterThan(day3.heroAt + 1));
    });

    test('pages fall away before the next one deals; the last by 43', () {
      expect(day1.exitStart, closeTo(16.25, 1e-9));
      expect(day3.exitStart, closeTo(41.5, 1e-9));
      for (final (i, page) in pages.indexed) {
        expect(page.fallAt(page.exitStart), 0);
        expect(page.fallAt(page.exitStart + 1.2), greaterThan(SkyWorld.height));
        if (i + 1 < pages.length) {
          final next = pages[i + 1];
          expect(page.isVisibleAt(next.dealAt(0) + 0.6), isFalse);
        }
      }
      expect(day3.isVisibleAt(43.0), isFalse);
    });
  });

  test('every length keeps each page in order and on its own', () {
    for (var n = 1; n <= SkyStoryTimeline.maxChapters; n++) {
      final pages = SkyPageBeats.all(SkyStoryTimeline.forChapters(n));
      expect(pages, hasLength(n));
      for (final page in pages) {
        expect(page.headerIn, greaterThan(page.previousEnd), reason: 'n=$n');
        expect(page.dealAt(0), greaterThan(page.previousEnd), reason: 'n=$n');
        expect(page.heroAt, lessThan(page.exitStart), reason: 'n=$n');
        expect(page.cardAt + 2, lessThan(page.exitStart), reason: 'n=$n');
      }
    }
  });
}

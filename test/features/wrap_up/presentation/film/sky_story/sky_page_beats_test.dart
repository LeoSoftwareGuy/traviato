import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/wrap_up/presentation/film/sky_story/sky_page_beats.dart';
import 'package:traviato/features/wrap_up/presentation/film/sky_story/sky_scene_spec.dart';
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
      expect(day3.exitStart, closeTo(41.25, 1e-9));
      for (final (i, page) in pages.indexed) {
        expect(page.fallAt(page.exitStart), 0);
        expect(page.fallAt(page.exitStart + 1.5), greaterThan(SkyWorld.height));
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

  group('exits (phase 3)', () {
    test('the fall follows the reference headers within 15 %', () {
      for (final (dt, px) in const [
        (0.25, 44.0),
        (0.5, 192.0),
        (0.75, 450.0),
        (1.0, 970.0),
        (1.25, 1640.0),
      ]) {
        // 15 %, or 10 px at the start where a pixel is a lot of it.
        expect(
          SkyPageBeats.fall(dt),
          closeTo(px, math.max(px * 0.15, 10)),
          reason: '$dt',
        );
      }
      expect(SkyPageBeats.fall(0), 0);
      expect(SkyPageBeats.fall(-1), 0);
    });

    test('the title falls from 4.75 s, like a page', () {
      expect(SkyTitleBeats.exitStart(5), 4.75);
      expect(SkyTitleBeats.fallAt(4.75, 5), 0);
      expect(SkyTitleBeats.fallAt(5.25, 5), closeTo(160, 40));
      expect(SkyTitleBeats.fallAt(6.5, 5), greaterThan(SkyWorld.height));
    });

    test('only a taped page tilts, to −4°, as it falls', () {
      final pages = SkyPageBeats.all(SkyStoryTimeline.forChapters(5));
      for (final page in pages) {
        expect(page.tiltAt(page.exitStart), 0);
        final later = page.tiltAt(page.exitStart + 1.2);
        if (page.layout == SkyPageLayout.taped) {
          expect(later, closeTo(-4 * math.pi / 180, 1e-9));
          expect(page.tiltAt(page.headerIn + 1), 0);
        } else {
          expect(later, 0);
        }
      }
      expect(
        pages.where((p) => p.layout == SkyPageLayout.taped),
        hasLength(2),
      );
    });

    test('every length: the title and each page are gone in time', () {
      for (var n = 1; n <= SkyStoryTimeline.maxChapters; n++) {
        final timeline = SkyStoryTimeline.forChapters(n);
        final openingEnd = timeline.first<SkyOpeningSpec>()!.end;
        final pages = SkyPageBeats.all(timeline);
        // Day 1's header fades in above the falling title (as in the
        // reference); the title's text, from y ≈ 1180 down, is out of
        // frame before Day 1's photos are dealt.
        expect(
          SkyTitleBeats.fallAt(pages.first.dealAt(0), openingEnd),
          greaterThan(SkyWorld.height - 1100),
          reason: 'n=$n',
        );
        for (var i = 0; i + 1 < pages.length; i++) {
          final next = pages[i + 1];
          expect(
            pages[i].fallAt(next.dealAt(0)),
            greaterThan(SkyWorld.height),
            reason: 'n=$n page=$i',
          );
          expect(pages[i].isVisibleAt(next.headerIn), isFalse);
        }
        expect(
          pages.last.isVisibleAt(timeline.first<SkyGatherSpec>()!.start),
          isFalse,
          reason: 'n=$n',
        );
      }
    });
  });
}

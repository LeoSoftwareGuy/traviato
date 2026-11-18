import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/wrap_up/presentation/film/sky_story/sky_note_flow.dart';
import 'package:traviato/features/wrap_up/presentation/film/sky_story/sky_scene_spec.dart';
import 'package:traviato/features/wrap_up/presentation/film/sky_story/sky_story.dart';
import 'package:traviato/features/wrap_up/presentation/film/sky_story/sky_story_copy.dart';
import 'package:traviato/features/wrap_up/presentation/film/sky_story/sky_story_texts.dart';
import 'package:traviato/features/wrap_up/presentation/film/sky_story/sky_story_timeline.dart';
import 'package:traviato/l10n/app_localizations.dart';

import 'sky_story_canvas_golden_test.dart' show loadSkyStoryFonts;

/// Long notes over a day's pages, the hero's caption and reading time
/// (#383, #399).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final en = lookupAppLocalizations(const Locale('en'));

  SkyPage page(
    int day, {
    String? note,
    String? caption,
    String? skyLine,
    String hero = 'h',
  }) => SkyPage(
    firstDay: day,
    date: DateTime(2026, 6, 11 + day),
    photoCount: 10,
    hero: SkyPhoto(id: hero, caption: caption, place: 'Alfama'),
    note: note,
    signature: note == null ? null : 'Leo',
    skyLine: skyLine,
  );

  SkyStory story(List<SkyPage> pages) => SkyStory(
    title: 'Amsterdam',
    startDate: DateTime(2026, 6, 12),
    endDate: DateTime(2026, 6, 14),
    pages: pages,
    momentCount: 30,
  );

  // 40 characters fit a page: simple to reason about.
  bool fits(String text, SkyPageLayout layout) => text.length <= 40;

  group('flowSkyNotes', () {
    test("a long note continues on the day's next page, by sentence", () {
      final flowed = flowSkyNotes(
        story([
          page(1, note: 'We landed at six. Breakfast first. Then the canals.'),
          page(1, hero: 'h2', caption: 'our castle'),
          page(2, note: 'Brussels never changes.'),
        ]),
        fits: fits,
      );
      expect(flowed.pages[0].note, 'We landed at six. Breakfast first.');
      expect(flowed.pages[1].note, 'Then the canals.');
      expect(flowed.pages[2].note, 'Brussels never changes.');
      // Only the note's last words are signed.
      expect(flowed.pages[0].signature, isNull);
      expect(flowed.pages[1].signature, 'Leo');
    });

    test('Russian notes split at their sentence ends', () {
      final flowed = flowSkyNotes(
        story([
          page(1, note: 'Ждём полтора метра рёбер. Заказали 4,5 кг!'),
          page(1, hero: 'h2'),
        ]),
        fits: (text, _) => text.length <= 26,
      );
      expect(flowed.pages[0].note, 'Ждём полтора метра рёбер.');
      expect(flowed.pages[1].note, 'Заказали 4,5 кг!');
    });

    test('no "…": a sentence too long for any page is left out', () {
      final flowed = flowSkyNotes(
        story([
          page(
            1,
            note:
                'This first sentence is far too long to fit on any page. '
                'Short one.',
          ),
        ]),
        fits: fits,
      );
      expect(flowed.pages.single.note, 'Short one.');
      expect(flowed.pages.single.note, isNot(contains('…')));
    });

    test('a page left without words keeps its sky line', () {
      final flowed = flowSkyNotes(
        story([
          page(1, note: 'Short.'),
          page(1, hero: 'h2', skyLine: 'The canals at dusk'),
        ]),
        fits: fits,
      );
      expect(flowed.pages[1].note, isNull);
      expect(flowed.pages[1].skyLine, 'The canals at dusk');
    });
  });

  group("the hero's caption (#399)", () {
    test("the user's caption replaces place · time on the strip", () {
      final copy = SkyPageCopy.resolve(
        page(1, note: 'A note.', caption: 'боча пролил пиво'),
        SkyPageLayout.fan,
        en,
        'en',
      );
      expect(copy.heroCaption, 'боча пролил пиво');
      expect(copy.placeCaption, startsWith('Alfama'));
    });

    test('without a note it goes on the sky', () {
      final copy = SkyPageCopy.resolve(
        page(1, caption: 'our castle'),
        SkyPageLayout.fan,
        en,
        'en',
      );
      expect(copy.skyText, 'our castle');
      expect(copy.heroCaption, isEmpty);
    });

    group('laid out', () {
      setUpAll(loadSkyStoryFonts);

      test('a caption too long for the strip gives way to place · time, '
          'never "…"', () {
        final texts = SkyPageTexts(
          SkyPageCopy.resolve(
            page(1, note: 'A note.', caption: 'word ' * 40),
            SkyPageLayout.fan,
            en,
            'en',
          ),
          SkyPageLayout.fan,
        );
        final shown = (texts.caption.text! as TextSpan).text!;
        expect(shown, startsWith('Alfama'));
        expect(texts.caption.didExceedMaxLines, isFalse);
        texts.dispose();
      });

      test('a short caption shows whole at ≥ 40 px', () {
        final texts = SkyPageTexts(
          SkyPageCopy.resolve(
            page(1, note: 'A note.', caption: 'fast check-in'),
            SkyPageLayout.fan,
            en,
            'en',
          ),
          SkyPageLayout.fan,
        );
        final span = texts.caption.text! as TextSpan;
        expect(span.text, 'fast check-in');
        expect(span.style!.fontSize, greaterThanOrEqualTo(40));
        texts.dispose();
      });

      test('noteFits: three lines on a card, four on the sky', () {
        const long =
            'We waited for a metre and a half of ribs, four and a half '
            'kilos of them, and it was worth every minute of the wait.';
        expect(SkyPageTexts.noteFits('Short.', SkyPageLayout.fan), isTrue);
        expect(
          SkyPageTexts.noteFits(long * 2, SkyPageLayout.fan),
          isFalse,
        );
        expect(
          SkyPageTexts.noteFits(long * 3, SkyPageLayout.flyOut),
          isFalse,
        );
      });
    });
  });

  group('reading time (#399 T1)', () {
    test("a page with a long note plays until it's read", () {
      final note = 'a' * 120; // 10.8 s to read
      final dur = SkyStoryTimeline.readingDur(
        page(1, note: note),
        SkyPageLayout.fan,
        isLast: false,
      );
      // Shown from 1.2 s, read for 10.8 s, before the 0.25 s fall.
      expect(dur, closeTo(1.2 + 10.8 + 0.25, 1e-9));
      final film = SkyStoryTimeline.forStory(
        story([page(1, note: note), page(2), page(3)]),
      );
      final first = film.scenes.firstWhere((s) => s.spec is SkyChapterSpec);
      expect(first.duration, closeTo(dur, 1e-9));
    });

    test('short words keep the reference lengths', () {
      final film = SkyStoryTimeline.forStory(
        story([page(1, note: 'Hi.'), page(2), page(3)]),
      );
      expect(film.total, SkyStoryTimeline.forChapters(3).total);
    });
  });
}

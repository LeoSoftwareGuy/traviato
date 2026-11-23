import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/wrap_up/domain/entities/wrap_up_golden_vows.dart';
import 'package:traviato/features/wrap_up/presentation/film/golden_vows/golden_vows_album.dart';
import 'package:traviato/features/wrap_up/presentation/film/golden_vows/golden_vows_from_wrap_up.dart';
import 'package:traviato/features/wrap_up/presentation/film/golden_vows/golden_vows_scene_spec.dart';
import 'package:traviato/features/wrap_up/presentation/film/golden_vows/golden_vows_story.dart';
import 'package:traviato/features/wrap_up/presentation/film/golden_vows/golden_vows_texts.dart';
import 'package:traviato/l10n/app_localizations.dart';

final _takenAt = DateTime(2026, 6, 14, 15, 10).toUtc();

WrapUpGoldenVows _gv({
  WrapUpGoldenVowsPacking? packing,
  List<String> carousel = const ['c1', 'c2', 'c3', 'c4', 'c5', 'c6'],
}) => WrapUpGoldenVows(
  occasion: 'wedding',
  occasionLine: 'Our Wedding Day',
  names: 'Anna & Marco',
  startDate: DateTime(2026, 6, 14),
  place: 'Lake Bled',
  packing: packing,
  heroes: [
    WrapUpGoldenVowsHero(
      photoId: 'h1',
      label: 'The vows',
      takenAt: _takenAt,
      note: 'You cried before I did.',
    ),
    const WrapUpGoldenVowsHero(photoId: 'h2', label: 'First dance'),
    const WrapUpGoldenVowsHero(photoId: 'gone'),
  ],
  chapters: const [
    WrapUpGoldenVowsChapter(
      title: 'Getting ready',
      line: 'Chapter one · Morning',
      photoIds: ['a1', 'gone', 'a3'],
      layout: 'B',
    ),
    WrapUpGoldenVowsChapter(title: 'All gone', photoIds: ['gone']),
  ],
  carousel: WrapUpGoldenVowsChapter(title: 'The night', photoIds: carousel),
  heartPhotoIds: const ['h1', 'gone', 'a1'],
  momentCount: 240,
  endLine: 'Always',
);

const _photos = {'h1', 'h2', 'a1', 'a3', 'c1', 'c2', 'c3', 'c4', 'c5', 'c6'};

void main() {
  test("the album over the memory's photos, gone ones left out", () {
    final story = goldenVowsFromWrapUp(_gv(), photoIds: _photos)!;
    expect(story.names, 'Anna & Marco');
    expect(story.occasionLine, 'Our Wedding Day');
    expect(story.date, DateTime(2026, 6, 14));
    expect(story.place, 'Lake Bled');
    expect(story.heroes, const [
      GvHero(
        photoId: 'h1',
        note: 'You cried before I did.',
        caption: 'The vows · 15:10',
      ),
      GvHero(photoId: 'h2', caption: 'First dance'),
    ]);
    expect(story.chapters.single.photoIds, ['a1', 'a3']);
    expect(story.chapters.single.layout, GvChapterLayout.b);
    expect(story.carousel!.photoIds, hasLength(6));
    expect(story.heartPhotoIds, ['h1', 'a1']);
    expect(story.momentCount, 240);
    expect(story.endLine, 'Always');
    expect(story.hasPackingCard, isFalse);
  });

  test('a carousel under 6 photos is dropped', () {
    final story = goldenVowsFromWrapUp(
      _gv(carousel: const ['c1', 'c2', 'c3', 'c4', 'c5', 'gone']),
      photoIds: _photos,
    )!;
    expect(story.carousel, isNull);
  });

  test('live dates win; nothing left or no date: null', () {
    final moved = goldenVowsFromWrapUp(
      _gv(),
      photoIds: _photos,
      startDate: DateTime(2026, 6, 20),
      endDate: DateTime(2026, 6, 22),
    )!;
    expect(moved.date, DateTime(2026, 6, 20));
    expect(moved.dayCount, 3);
    expect(goldenVowsFromWrapUp(_gv(), photoIds: const {}), isNull);
    expect(
      goldenVowsFromWrapUp(
        const WrapUpGoldenVows(
          names: 'A',
          heroes: [WrapUpGoldenVowsHero(photoId: 'h1')],
          chapters: [],
        ),
        photoIds: _photos,
      ),
      isNull,
    );
  });

  test('the chapter keeps its layout, else A, B, C in turn', () {
    expect(
      GvChapterLayouts.forChapter(0, GvChapterLayout.c),
      GvChapterLayouts.c,
    );
    expect(GvChapterLayouts.forChapter(4), GvChapterLayouts.b);
  });

  group('the packing card', () {
    final en = lookupAppLocalizations(const Locale('en'));
    final ru = lookupAppLocalizations(const Locale('ru'));

    test('counts what was checked off, of everything to pack', () {
      final story = goldenVowsFromWrapUp(
        _gv(
          packing: const WrapUpGoldenVowsPacking(
            items: [
              WrapUpGoldenVowsPackedItem('Rings'),
              WrapUpGoldenVowsPackedItem('Veil'),
            ],
            checked: 8,
            total: 12,
          ),
        ),
        photoIds: _photos,
      )!;
      final texts = GvPackingTexts(story, en);
      expect(texts.subhead.plainText, 'WHAT WE PACKED · 8 OF 12');
      expect(texts.items.map((t) => t.plainText), ['Rings', 'Veil']);
      texts.dispose();
    });

    test('seeded items follow the film language; quests read planned', () {
      final story = goldenVowsFromWrapUp(
        _gv(
          packing: const WrapUpGoldenVowsPacking(
            items: [
              WrapUpGoldenVowsPackedItem(
                'Passport',
                suggestionCode: 'passport',
              ),
              WrapUpGoldenVowsPackedItem('Кольца'),
            ],
            checked: 2,
            total: 2,
          ),
        ),
        photoIds: _photos,
      )!;
      final texts = GvPackingTexts(story, ru);
      expect(texts.items.map((t) => t.plainText), ['Паспорт', 'Кольца']);
      texts.dispose();

      final quests = goldenVowsFromWrapUp(
        _gv(
          packing: const WrapUpGoldenVowsPacking(
            items: [WrapUpGoldenVowsPackedItem('Ceremony at 3')],
            isFromQuests: true,
          ),
        ),
        photoIds: _photos,
      )!;
      final planned = GvPackingTexts(quests, en);
      expect(planned.subhead.plainText, 'WHAT WE PLANNED');
      planned.dispose();
    });
  });

  test(
    'a chapter of 2 pages is two album pages, in the stored order (#460)',
    () {
      const gv = WrapUpGoldenVows(
        names: 'Elmas birthday',
        heroes: [
          WrapUpGoldenVowsHero(photoId: 'h1', label: 'Arabica', order: 1),
          WrapUpGoldenVowsHero(photoId: 'h2', order: 3),
        ],
        chapters: [
          WrapUpGoldenVowsChapter(
            title: 'From Tallinn',
            line: 'Chapter one · Night',
            photoIds: ['a1', 'a2', 'a3', 'a4', 'a5'],
            layout: 'B',
            pages: [
              WrapUpGoldenVowsChapterPage(
                photoIds: ['a1', 'a2', 'a3'],
                order: 0,
                layout: 'B',
              ),
              WrapUpGoldenVowsChapterPage(
                photoIds: ['a4', 'a5'],
                order: 2,
                layout: 'B2',
              ),
            ],
          ),
        ],
      );
      final story = goldenVowsFromWrapUp(
        gv,
        photoIds: const {'h1', 'h2', 'a1', 'a2', 'a3', 'a4', 'a5'},
        startDate: DateTime(2026, 2, 26),
      )!;
      expect(story.chapters.map((c) => c.photoIds), [
        ['a1', 'a2', 'a3'],
        ['a4', 'a5'],
      ]);
      expect(story.chapters.map((c) => c.title), [
        'From Tallinn',
        'From Tallinn',
      ]);
      expect(story.chapters.last.layout, GvChapterLayout.b2);
      expect(story.chapters.map((c) => c.isSecondPage), [false, true]);
      // The eyebrow on the first page only; a second page without a line of
      // its own shows none (#460).
      expect(story.chapters.map((c) => c.line), ['Chapter one · Night', null]);
      // A caption with no time plays alone.
      expect(story.heroes.first.caption, 'Arabica');
      expect(story.pageOrder, [
        (kind: GvPageKind.chapter, index: 0),
        (kind: GvPageKind.hero, index: 0),
        (kind: GvPageKind.chapter, index: 1),
        (kind: GvPageKind.hero, index: 1),
      ]);
      // Older content (no orders): main pages first, then chapters.
      final older = story.fitted(
        heroes: [for (final h in story.heroes) GvHero(photoId: h.photoId)],
      );
      expect(older.pageOrder.first, (kind: GvPageKind.hero, index: 0));
    },
  );

  test("a page's own line takes the eyebrow's place, set as a note (#460)", () {
    const gv = WrapUpGoldenVows(
      names: 'Elmas birthday',
      heroes: [],
      chapters: [
        WrapUpGoldenVowsChapter(
          title: 'From Tallinn',
          line: 'Chapter one · Night',
          photoIds: ['a1', 'a2'],
          pages: [
            WrapUpGoldenVowsChapterPage(
              photoIds: ['a1', 'a2'],
              order: 0,
              layout: 'B2',
              note: 'Direct plane from Tallinn to Budapest is the best',
            ),
          ],
        ),
      ],
    );
    final story = goldenVowsFromWrapUp(
      gv,
      photoIds: const {'a1', 'a2'},
      startDate: DateTime(2026, 2, 26),
    )!;
    final page = story.chapters.single;
    expect(page.line, 'Direct plane from Tallinn to Budapest is the best');
    expect(page.isLineANote, isTrue);
    expect(page.layout, GvChapterLayout.b2);
  });
}

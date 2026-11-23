import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/wrap_up/presentation/film/golden_vows/golden_vows_album.dart';
import 'package:traviato/features/wrap_up/presentation/film/golden_vows/golden_vows_fit.dart';
import 'package:traviato/features/wrap_up/presentation/film/golden_vows/golden_vows_story.dart';
import 'package:traviato/features/wrap_up/presentation/film/golden_vows/golden_vows_timeline.dart';

/// GvFit (#458): past the longest film the album gives way in order —
/// the carousel, the packing card, main pages down to 2, then shorter
/// chapter pages — never a chapter, the heart or a caption.
void main() {
  final wedding = GoldenVowsFixtures.wedding;
  final length = GvFit.lengthOf(wedding);

  // The fixture with 6 main pages, the last 2 without a note.
  final six = wedding.fitted(
    heroes: [
      ...wedding.heroes,
      const GvHero(photoId: 'hero-5', caption: 'Cake'),
      const GvHero(photoId: 'hero-6', caption: 'Toast'),
    ],
  );

  test('a film that fits is kept as it is', () {
    expect(GvFit.toLongest(wedding, maxSeconds: length + 1), same(wedding));
  });

  test('the carousel goes first, then the packing card', () {
    final noCarousel = GvFit.toLongest(wedding, maxSeconds: length - 0.5);
    expect(noCarousel.carousel, isNull);
    expect(noCarousel.hasPackingCard, isTrue);
    expect(noCarousel.heroes, wedding.heroes);

    final withoutBoth = wedding.fitted(dropCarousel: true, dropPacking: true);
    final noPacking = GvFit.toLongest(
      wedding,
      maxSeconds: GvFit.lengthOf(withoutBoth) + 0.01,
    );
    expect(noPacking.hasPackingCard, isFalse);
    expect(noPacking.heroes, wedding.heroes);
  });

  test('then main pages down to 2: without a note first, the latest first', () {
    final bare = six.fitted(dropCarousel: true, dropPacking: true);
    final one = GvFit.toLongest(
      six,
      maxSeconds: GvFit.lengthOf(bare) - 0.01,
      longest: GvFit.lengthOf(bare) - 0.01,
    );
    expect(one.heroes.map((h) => h.photoId), [
      'hero-1',
      'hero-2',
      'hero-3',
      'hero-4',
      'hero-5',
    ]);
    final fewest = GvFit.toLongest(six, maxSeconds: 10, longest: 10);
    expect(fewest.heroes, hasLength(GvFit.minHeroes));
    // The notes stay to the last: the two left are the first with notes.
    expect(fewest.heroes.map((h) => h.photoId), ['hero-1', 'hero-2']);
  });

  test('last, chapter pages shorten — never below their title, never gone', () {
    final fewest = GvFit.toLongest(six, maxSeconds: 10, longest: 10);
    expect(fewest.chapters, wedding.chapters);
    expect(fewest.chapterDwellScale, lessThan(1));
    expect(fewest.heartPhotoIds, wedding.heartPhotoIds);
    final timeline = GoldenVowsTimeline.forStory(fewest);
    for (final chapter in fewest.chapters) {
      expect(
        GoldenVowsTimeline.chapterDwellFor(chapter.title, 0),
        lessThanOrEqualTo(
          GoldenVowsTimeline.chapterDwellFor(
            chapter.title,
            GoldenVowsTimeline.chapterDwell * fewest.chapterDwellScale,
          ),
        ),
      );
    }
    expect(timeline.total, lessThan(GvFit.lengthOf(six)));
  });

  test("a chapter page lies open at least its title's reading time", () {
    const long = 'Самая длинная глава нашей жизни';
    expect(
      GoldenVowsTimeline.chapterDwellFor(long, 0),
      greaterThan(GoldenVowsTimeline.chapterDwellFor('Сборы', 0)),
    );
  });

  test("chapters' second pages go first, the latest first (#460)", () {
    final paged = wedding.fitted(
      chapters: [
        for (final (i, c) in wedding.chapters.indexed) ...[
          c,
          GvChapter(
            title: c.title,
            line: c.line,
            photoIds: ['more-${i + 1}-1', 'more-${i + 1}-2'],
            layout: GvChapterLayout.b2,
            isSecondPage: true,
          ),
        ],
      ],
    );
    final one = GvFit.toLongest(
      paged,
      maxSeconds: GvFit.lengthOf(paged) - 0.01,
    );
    // The last chapter's second page went; the carousel and packing stay.
    expect(one.chapters, hasLength(paged.chapters.length - 1));
    expect(one.chapters.last, wedding.chapters.last);
    expect(one.carousel, isNotNull);
    expect(one.hasPackingCard, isTrue);
    final none = GvFit.toLongest(
      paged,
      maxSeconds: GvFit.lengthOf(wedding) + 0.01,
    );
    expect(none.chapters, wedding.chapters);
    expect(none.carousel, isNotNull);
  });

  test('a page of 2 prints has its own layout (#460)', () {
    expect(GvChapterLayouts.forChapter(0, GvChapterLayout.b2), hasLength(2));
  });

  test('a small album: ~4 s a photo, giving up no words for it (#460)', () {
    // Under 75 s, past 60 s.
    final small = six.fitted(
      heroes: [...wedding.heroes.take(2), ...six.heroes.skip(4)],
      chapters: [
        ...wedding.chapters,
        const GvChapter(
          title: 'Just married',
          line: 'We danced until the band left',
          photoIds: ['more-1', 'more-2'],
          layout: GvChapterLayout.b2,
          isSecondPage: true,
          isLineANote: true,
        ),
      ],
    );
    final story = GoldenVowsStory(
      names: small.names,
      date: small.date,
      packed: small.packed,
      heroes: small.heroes,
      chapters: small.chapters,
      carousel: small.carousel,
      heartPhotoIds: GoldenVowsFixtures.heartIds(15),
    );
    expect(GvFit.limitFor(story), 60);
    expect(GvFit.lengthOf(story), inInclusiveRange(60, 75));
    final fitted = GvFit.toLongest(story);
    // Under 75 s: every main page with a note and the line page stay.
    expect(
      fitted.heroes.where((h) => h.note != null),
      story.heroes.where((h) => h.note != null),
    );
    expect(fitted.chapters.where((c) => c.isLineANote), hasLength(1));
    expect(fitted.carousel, isNull);
    expect(fitted.hasPackingCard, isFalse);
    expect(GvFit.limitFor(GoldenVowsFixtures.wedding), 75);
  });

  test("a page's own line is read in full", () {
    const line = 'We danced until the band packed up and left at three';
    expect(
      GoldenVowsTimeline.chapterDwellFor('Night', 0, note: line),
      greaterThan(GoldenVowsTimeline.chapterDwellFor('Night', 0)),
    );
  });
}

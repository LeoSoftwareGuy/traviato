import 'package:flutter_test/flutter_test.dart';
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
    );
    expect(one.heroes.map((h) => h.photoId), [
      'hero-1',
      'hero-2',
      'hero-3',
      'hero-4',
      'hero-5',
    ]);
    final fewest = GvFit.toLongest(six, maxSeconds: 10);
    expect(fewest.heroes, hasLength(GvFit.minHeroes));
    // The notes stay to the last: the two left are the first with notes.
    expect(fewest.heroes.map((h) => h.photoId), ['hero-1', 'hero-2']);
  });

  test('last, chapter pages shorten — never below their title, never gone', () {
    final fewest = GvFit.toLongest(six, maxSeconds: 10);
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
}

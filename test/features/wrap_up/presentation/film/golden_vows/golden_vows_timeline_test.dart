import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/wrap_up/presentation/film/golden_vows/golden_vows_scene_spec.dart';
import 'package:traviato/features/wrap_up/presentation/film/golden_vows/golden_vows_timeline.dart';

void main() {
  final reference = GoldenVowsTimeline.reference();

  List<double> pageOpens(GoldenVowsTimeline timeline) => [
    for (final scene in timeline.film.scenes)
      if (scene.spec is GvPageSpec) scene.start,
  ];

  test("the reference wedding reproduces the spec's page table", () {
    final opens = pageOpens(reference);
    expect(opens, hasLength(9));
    const expected = [
      14.15,
      18.40,
      22.65,
      26.90,
      31.15,
      35.80,
      40.45,
      45.10,
      52.35,
    ];
    for (var i = 0; i < expected.length; i++) {
      expect(opens[i], closeTo(expected[i], 1e-9), reason: 'page ${i + 1}');
    }
    // The cover at 12.9, then every page but the heart.
    const turns = [
      12.9,
      17.15,
      21.40,
      25.65,
      29.90,
      34.55,
      39.20,
      43.85,
      51.10,
    ];
    expect(reference.turnStarts, hasLength(turns.length));
    for (var i = 0; i < turns.length; i++) {
      expect(reference.turnStarts[i], closeTo(turns[i], 1e-9));
    }
  });

  test('h0, the close, the ending and the end', () {
    expect(reference.heartStart, closeTo(52.35, 1e-9));
    expect(reference.closeStart, closeTo(59.95, 1e-9));
    expect(reference.endingStart, closeTo(60.95, 1e-9));
    expect(reference.total, closeTo(70, 1e-9));
  });

  test('pages in album order: heroes, chapters, carousel, heart', () {
    final pages = [
      for (final scene in reference.film.scenes)
        if (scene.spec case final GvPageSpec page) page,
    ];
    expect(pages.map((p) => p.number), [1, 2, 3, 4, 5, 6, 7, 8, 9]);
    expect(pages.map((p) => p.kind), [
      ...List.filled(4, GvPageKind.hero),
      ...List.filled(3, GvPageKind.chapter),
      GvPageKind.carousel,
      GvPageKind.heart,
    ]);
    expect(pages[5].index, 1);
  });

  test('each extra hero adds 4.25 s and each extra chapter 4.65 s', () {
    expect(
      GoldenVowsTimeline(heroes: 5).total,
      closeTo(reference.total + 4.25, 1e-9),
    );
    expect(
      GoldenVowsTimeline(chapters: 4).total,
      closeTo(reference.total + 4.65, 1e-9),
    );
  });

  test('leaving out the card or the carousel shortens the film', () {
    final noCard = GoldenVowsTimeline(hasPackingCard: false);
    expect(noCard.film.first<GvPackingCardSpec>(), isNull);
    expect(noCard.total, closeTo(70 - 6.5, 1e-9));
    final noCarousel = GoldenVowsTimeline(hasCarousel: false);
    expect(noCarousel.total, closeTo(70 - 7.25, 1e-9));
    expect(noCarousel.turnStarts, hasLength(8));
  });
}

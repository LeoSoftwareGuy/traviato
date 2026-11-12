import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/wrap_up/domain/entities/wrap_up_sky.dart';
import 'package:traviato/features/wrap_up/presentation/film/sky_story/sky_story.dart';
import 'package:traviato/features/wrap_up/presentation/film/sky_story/sky_story_from_wrap_up.dart';

WrapUpSkyPage _page({
  int day = 1,
  String hero = 'p1',
  List<String> extras = const ['p2', 'p3'],
  String? note = 'Took the tram the wrong way.',
  String? skyLine,
}) => WrapUpSkyPage(
  firstDay: day,
  date: DateTime(2026, 6, 11 + day),
  photoCount: 10,
  heroPhotoId: hero,
  extraPhotoIds: extras,
  note: note,
  skyLine: skyLine,
);

WrapUpSky _sky(List<WrapUpSkyPage> pages, {String? firstName = 'Jonas'}) =>
    WrapUpSky(
      isFromDirector: true,
      title: 'Lisbon, together',
      firstName: firstName,
      momentCount: 187,
      mosaicPhotoIds: const ['p1', 'gone', 'p2'],
      pages: pages,
    );

final _photos = {
  for (final id in ['p1', 'p2', 'p3', 'p4'])
    id: SkyPhoto(id: id, place: 'Alfama'),
};

void main() {
  test('resolves pages against the memory\'s photos', () {
    final story = skyStoryFromWrapUp(
      _sky([_page()]),
      photos: _photos,
      startDate: DateTime(2026, 6, 12),
      endDate: DateTime(2026, 6, 14),
    )!;
    expect(story.title, 'Lisbon, together');
    expect(story.startDate, DateTime(2026, 6, 12));
    expect(story.endDate, DateTime(2026, 6, 14));
    expect(story.names, 'Jonas');
    expect(story.momentCount, 187);
    expect(story.mosaicPhotoIds, ['p1', 'p2']);
    final page = story.pages.single;
    expect(page.hero.place, 'Alfama');
    expect(page.extras.map((p) => p.id), ['p2', 'p3']);
    expect(page.signature, 'Jonas');
  });

  test('a page whose hero is gone is dropped; gone extras are skipped', () {
    final story = skyStoryFromWrapUp(
      _sky([
        _page(hero: 'gone'),
        _page(day: 2, extras: ['gone', 'p4']),
      ]),
      photos: _photos,
    )!;
    expect(story.pages.single.firstDay, 2);
    expect(story.pages.single.extras.map((p) => p.id), ['p4']);
  });

  test('null when no page is left', () {
    expect(
      skyStoryFromWrapUp(_sky([_page(hero: 'gone')]), photos: _photos),
      isNull,
    );
  });

  test('no note: no signature, and the sky line instead', () {
    final story = skyStoryFromWrapUp(
      _sky([
        _page(note: null, skyLine: 'Eleven bridges.'),
        _page(day: 2, skyLine: 'Ignored next to a note.'),
      ]),
      photos: _photos,
    )!;
    expect(story.pages[0].signature, isNull);
    expect(story.pages[0].skyLine, 'Eleven bridges.');
    expect(story.pages[1].skyLine, isNull);
  });

  test('no first name: no signature', () {
    final story = skyStoryFromWrapUp(
      _sky([_page()], firstName: null),
      photos: _photos,
    )!;
    expect(story.pages.single.signature, isNull);
    expect(story.names, isNull);
  });

  test('without live dates, the pages\' own dates', () {
    final story = skyStoryFromWrapUp(
      _sky([_page(), _page(day: 3)]),
      photos: _photos,
    )!;
    expect(story.startDate, DateTime(2026, 6, 12));
    expect(story.endDate, DateTime(2026, 6, 14));
  });
}

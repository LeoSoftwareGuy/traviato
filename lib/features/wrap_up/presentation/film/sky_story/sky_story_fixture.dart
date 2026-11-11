import 'package:flutter/painting.dart';

import 'sky_story.dart';

/// The reference film's memory, "Lisbon, together" (docs/design/sky-story,
/// spec §7), for the debug preview and the goldens until real memories
/// are turned into stories (#345, phase 6). The photos are placeholders:
/// the app's bundled cover images, by asset name.
abstract final class SkyStoryFixtures {
  /// Placeholder photos, `assets/images/covers/<id>.jpg`.
  static ImageProvider? photo(String id) =>
      AssetImage('assets/images/covers/$id.jpg');

  /// The mosaic's tiles: the bundled covers, standing in for a memory's
  /// photos.
  static const _mosaic = [
    'mountain_town',
    'sunset_peaks',
    'maui',
    'foodie',
    'cultural',
    'romantic',
    'nightlife',
    'rooftop_gathering',
    'lago_di_braies',
    'canoe',
    'picnic_on_the_edge',
    'departure',
  ];

  static final lisbon = SkyStory(
    title: 'Lisbon, together',
    startDate: DateTime(2026, 6, 12),
    endDate: DateTime(2026, 6, 14),
    names: 'Mari & Jonas',
    momentCount: 187,
    mosaicPhotoIds: _mosaic,
    pages: [
      SkyPage(
        firstDay: 1,
        date: DateTime(2026, 6, 12),
        photoCount: 64,
        headline: 'Lost, on purpose',
        hero: SkyPhoto(
          id: 'mountain_town',
          place: 'Alfama',
          takenAt: DateTime(2026, 6, 12, 9, 40),
        ),
        extras: const [
          SkyPhoto(id: 'rooftop_gathering'),
          SkyPhoto(id: 'cultural'),
          SkyPhoto(id: 'autumn_woods'),
          SkyPhoto(id: 'foodie'),
        ],
        note:
            'Took the 28 tram the wrong way, twice. Found the best little '
            'bakery because of it.',
        signature: 'Jonas',
      ),
      SkyPage(
        firstDay: 2,
        date: DateTime(2026, 6, 13),
        photoCount: 71,
        headline: 'The quiet hour',
        hero: SkyPhoto(
          id: 'sunset_peaks',
          place: 'Miradouro',
          takenAt: DateTime(2026, 6, 13, 20, 15),
        ),
        extras: const [
          SkyPhoto(id: 'picnic_on_the_edge'),
          SkyPhoto(id: 'lago_di_braies'),
          SkyPhoto(id: 'romantic'),
          SkyPhoto(id: 'nightlife'),
        ],
        note:
            'Everyone went quiet when the sun hit the river. I forgot to take '
            'a photo for a whole minute.',
        signature: 'Mari',
      ),
      SkyPage(
        firstDay: 3,
        date: DateTime(2026, 6, 14),
        photoCount: 52,
        headline: 'Salt in our hair',
        hero: const SkyPhoto(id: 'maui', place: 'Cascais'),
        extras: const [
          SkyPhoto(id: 'departure'),
          SkyPhoto(id: 'canoe'),
          SkyPhoto(id: 'picnic_on_the_edge'),
        ],
        note:
            'Last morning. Sand in everything, and already planning the next '
            'one.',
        signature: 'Jonas',
      ),
    ],
  );

  /// The same memory written in Russian, for the Russian film.
  static final lisbonRu = SkyStory(
    title: 'Лиссабон, вдвоём',
    startDate: lisbon.startDate,
    endDate: lisbon.endDate,
    names: 'Мари и Йонас',
    momentCount: 187,
    mosaicPhotoIds: _mosaic,
    pages: [
      _ru(
        lisbon.pages[0],
        headline: 'Заблудились нарочно',
        place: 'Алфама',
        note:
            'Дважды сели на 28-й трамвай не в ту сторону. Зато нашли лучшую '
            'маленькую пекарню.',
        signature: 'Йонас',
      ),
      _ru(
        lisbon.pages[1],
        headline: 'Тихий час',
        place: 'Мирадоуру',
        note:
            'Все замолчали, когда солнце коснулось реки. Я целую минуту '
            'забывала фотографировать.',
        signature: 'Мари',
      ),
      _ru(
        lisbon.pages[2],
        headline: 'Соль в волосах',
        place: 'Кашкайш',
        note: 'Последнее утро. Песок повсюду, а мы уже планируем следующее.',
        signature: 'Йонас',
      ),
    ],
  );

  static SkyPage _ru(
    SkyPage page, {
    required String headline,
    required String place,
    required String note,
    required String signature,
  }) => SkyPage(
    firstDay: page.firstDay,
    date: page.date,
    photoCount: page.photoCount,
    headline: headline,
    hero: SkyPhoto(id: page.hero.id, place: place, takenAt: page.hero.takenAt),
    extras: page.extras,
    note: note,
    signature: signature,
  );
}

import '../../../domain/entities/wrap_up_sky.dart';
import 'sky_story.dart';

/// The Sky Story film for a wrap-up's `content.sky` (#345): its pages
/// resolved against [photos], the memory's photos the app can show (place
/// and time for captions). A page whose hero photo is gone is dropped, a
/// gone extra is skipped; null when no page is left, so the classic film
/// plays.
///
/// [startDate] / [endDate] are the memory's live dates (they follow a date
/// edit); without them the pages' own dates are used.
SkyStory? skyStoryFromWrapUp(
  WrapUpSky sky, {
  required Map<String, SkyPhoto> photos,
  DateTime? startDate,
  DateTime? endDate,
}) {
  final pages = <SkyPage>[
    for (final page in sky.pages)
      if (photos[page.heroPhotoId] case final hero?)
        SkyPage(
          firstDay: page.firstDay,
          lastDay: page.lastDay,
          date: page.date,
          endDate: page.endDate,
          photoCount: page.photoCount,
          headline: page.headline,
          hero: hero,
          extras: [
            for (final id in page.extraPhotoIds) ?photos[id],
          ].take(SkyPage.maxExtras).toList(),
          note: page.note,
          signature: page.note == null ? null : sky.firstName,
          skyLine: page.note == null ? page.skyLine : null,
        ),
  ];
  if (pages.isEmpty) return null;
  return SkyStory(
    title: sky.title,
    startDate: startDate ?? pages.first.date,
    endDate: endDate ?? pages.last.endDate ?? pages.last.date,
    names: sky.firstName,
    pages: pages,
    momentCount: sky.momentCount,
    mosaicPhotoIds: [
      for (final id in sky.mosaicPhotoIds)
        if (photos.containsKey(id)) id,
    ],
  );
}

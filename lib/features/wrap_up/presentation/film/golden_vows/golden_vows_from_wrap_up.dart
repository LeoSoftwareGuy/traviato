import '../../../domain/entities/wrap_up_golden_vows.dart';
import 'golden_vows_story.dart';

/// The fewest photos the carousel page plays with (as the server picks).
const minGoldenVowsCarouselPhotos = 6;

/// The Golden Vows film for a wrap-up's `content.golden_vows` (#346),
/// resolved against [photoIds], the memory's photos the app can show. A
/// hero whose photo is gone is skipped, a chapter keeps the photos left
/// (none → skipped), a carousel under [minGoldenVowsCarouselPhotos] is
/// dropped; null when no hero or chapter is left, or there's no date, so
/// Sky Story plays.
///
/// [startDate] / [endDate] are the memory's live dates (they follow a date
/// edit); without them the stored ones are used.
GoldenVowsStory? goldenVowsFromWrapUp(
  WrapUpGoldenVows gv, {
  required Set<String> photoIds,
  DateTime? startDate,
  DateTime? endDate,
}) {
  final date = startDate ?? gv.startDate;
  if (date == null) return null;
  final heroes = [
    for (final hero in gv.heroes)
      if (photoIds.contains(hero.photoId))
        GvHero(
          photoId: hero.photoId,
          note: hero.note,
          caption: _caption(hero.label, hero.takenAt),
        ),
  ];
  final chapters = [
    for (final chapter in gv.chapters)
      ?_chapter(chapter, photoIds, minPhotos: 1),
  ];
  if (heroes.isEmpty && chapters.isEmpty) return null;
  final packing = gv.packing;
  return GoldenVowsStory(
    occasionLine: gv.occasionLine,
    names: gv.names,
    date: date,
    place: gv.place,
    packed: [for (final item in packing?.items ?? const []) item.text],
    packedCodes: [
      for (final item in packing?.items ?? const []) item.suggestionCode,
    ],
    packedChecked: packing?.checked,
    packedTotal: packing?.total,
    isPackedFromQuests: packing?.isFromQuests ?? false,
    heroes: heroes,
    chapters: chapters,
    carousel: switch (gv.carousel) {
      final carousel? => _chapter(
        carousel,
        photoIds,
        minPhotos: minGoldenVowsCarouselPhotos,
      ),
      null => null,
    },
    heartPhotoIds: [
      for (final id in gv.heartPhotoIds)
        if (photoIds.contains(id)) id,
    ],
    moments: gv.momentCount > 0 ? gv.momentCount : null,
    endLine: gv.endLine,
    dayCount: _dayCount(startDate, endDate) ?? gv.dayCount,
  );
}

GvChapter? _chapter(
  WrapUpGoldenVowsChapter chapter,
  Set<String> photoIds, {
  required int minPhotos,
}) {
  final ids = [
    for (final id in chapter.photoIds)
      if (photoIds.contains(id)) id,
  ];
  if (ids.length < minPhotos) return null;
  return GvChapter(
    title: chapter.title,
    line: chapter.line,
    photoIds: ids,
    layout: switch (chapter.layout) {
      'A' => GvChapterLayout.a,
      'B' => GvChapterLayout.b,
      'C' => GvChapterLayout.c,
      _ => null,
    },
  );
}

/// "The vows · 15:10": the director's label and the photo's local time,
/// either one alone, or null.
String? _caption(String? label, DateTime? takenAt) {
  final local = takenAt?.toLocal();
  final time = local == null
      ? null
      : '${local.hour.toString().padLeft(2, '0')}:'
            '${local.minute.toString().padLeft(2, '0')}';
  return switch ((label, time)) {
    (final l?, final t?) => '$l · $t',
    (final l?, null) => l,
    (null, final t?) => t,
    (null, null) => null,
  };
}

int? _dayCount(DateTime? start, DateTime? end) {
  if (start == null || end == null) return null;
  final days =
      DateTime.utc(
        end.year,
        end.month,
        end.day,
      ).difference(DateTime.utc(start.year, start.month, start.day)).inDays +
      1;
  return days > 0 ? days : null;
}

import '../../../domain/entities/wrap_up_neon_night.dart';
import 'neon_night_scene_spec.dart';
import 'neon_night_story.dart';

/// How many photos each moment plays with (as the server checks them).
const neonMomentPhotos = {
  NnMomentType.split: (min: 2, max: 3),
  NnMomentType.burst: (min: 2, max: 4),
  NnMomentType.timeline: (min: 2, max: 8),
  NnMomentType.peak: (min: 3, max: 5),
};

/// The Neon Night film for a wrap-up's `content.neon_night` (#363),
/// resolved against [photoIds], the memory's photos the app can show.
///
/// A chapter keeps the photos left; a moment that falls under its photo
/// count is dropped, and a chapter left without one gets a timeline of its
/// photos. A chapter under 2 photos is skipped. Null when no chapter is
/// left or there's no date, so the next film plays. Times are the phone's
/// local times.
///
/// [startDate] is the memory's live start date (it follows a date edit);
/// without it the stored one, else the first photo's day.
NeonNightStory? neonNightFromWrapUp(
  WrapUpNeonNight nn, {
  required Set<String> photoIds,
  DateTime? startDate,
}) {
  final kept = [
    for (final chapter in nn.chapters)
      (
        chapter: chapter,
        photos: [
          for (final photo in chapter.photos)
            if (photoIds.contains(photo.id)) photo,
        ],
      ),
  ].where((c) => c.photos.length >= 2).take(5).toList();
  if (kept.isEmpty) return null;

  final byId = {
    for (final chapter in nn.chapters)
      for (final photo in chapter.photos)
        if (photoIds.contains(photo.id)) photo.id: photo,
  };
  final chapters = <NnChapter>[];
  for (final (index, entry) in kept.indexed) {
    final photos = [for (final photo in entry.photos) _photo(photo)];
    final ids = {for (final photo in entry.photos) photo.id};
    final moments = [
      for (final moment in entry.chapter.moments)
        ?_moment(moment, [
          for (final id in moment.photoIds)
            if (ids.contains(id)) _photo(byId[id]!),
        ]),
    ].take(2).toList();
    chapters.add(
      NnChapter(
        title: entry.chapter.title,
        from: photos.first.takenAt,
        to: index + 1 < kept.length
            ? _clock(kept[index + 1].photos.first.takenAt)
            : photos.last.takenAt,
        photos: photos,
        note: entry.chapter.note,
        moments: moments.isNotEmpty ? moments : [NnTimeline(_spread(photos))],
      ),
    );
  }

  final firstPhoto = kept.first.photos.first.takenAt.toLocal();
  final date =
      startDate ??
      nn.startDate ??
      DateTime(firstPhoto.year, firstPhoto.month, firstPhoto.day);
  final note = nn.note;
  final notePhoto = note?.photoId == null ? null : byId[note!.photoId];
  return NeonNightStory(
    title: nn.title,
    date: date,
    plan: [
      for (final row in nn.plan)
        NnPlanRow(time: row.time, item: row.title, done: row.done),
    ],
    chapters: chapters,
    note: note == null
        ? null
        : NnNoteMoment(
            text: note.text,
            number: note.number,
            time: note.writtenAt == null ? null : _clock(note.writtenAt!),
            photo: notePhoto == null ? null : _photo(notePhoto),
          ),
    firstName: nn.firstName,
    headline: nn.headline,
    totals: switch (nn.totals) {
      final t? => NnTotals(
        photos: t.photos,
        notes: t.notes,
        ticks: t.ticks,
        moments: t.moments,
      ),
      null => null,
    },
  );
}

NnMoment? _moment(WrapUpNeonMoment moment, List<NnPhoto> photos) {
  final type = switch (moment.type) {
    'split' => NnMomentType.split,
    'burst' => NnMomentType.burst,
    'timeline' => NnMomentType.timeline,
    'peak' => NnMomentType.peak,
    _ => null,
  };
  if (type == null) return null;
  final count = neonMomentPhotos[type]!;
  if (photos.length < count.min) return null;
  final shown = photos.take(count.max).toList();
  return switch (type) {
    NnMomentType.split => NnSplit(shown, place: moment.place),
    NnMomentType.burst => NnBurst(shown),
    NnMomentType.timeline => NnTimeline(shown),
    NnMomentType.peak => NnPeak(shown),
  };
}

/// Up to 8 of [photos], spread evenly, first and last included.
List<NnPhoto> _spread(List<NnPhoto> photos) {
  const max = 8;
  if (photos.length <= max) return photos;
  return [
    for (var i = 0; i < max; i++)
      photos[(i * (photos.length - 1) / (max - 1)).round()],
  ];
}

NnPhoto _photo(WrapUpNeonPhoto photo) =>
    NnPhoto(id: photo.id, takenAt: _clock(photo.takenAt));

/// 'HH:MM' on the phone's clock.
String _clock(DateTime instant) {
  final local = instant.toLocal();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(local.hour)}:${two(local.minute)}';
}

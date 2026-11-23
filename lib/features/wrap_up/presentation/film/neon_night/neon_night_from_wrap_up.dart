import '../../../domain/entities/film_clock.dart';
import '../../../domain/entities/wrap_up_neon_night.dart';
import 'neon_night_scene_spec.dart';
import 'neon_night_fit.dart';
import 'neon_night_story.dart';

/// How many photos each moment plays with (as the server checks them).
const neonMomentPhotos = {
  NnMomentType.split: (min: 2, max: 4),
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
  FilmClock clock = FilmClock.phone,
}) {
  NnPhoto photoOf(WrapUpNeonPhoto photo) => _photo(photo, clock);
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
  for (final entry in kept) {
    final photos = [for (final photo in entry.photos) photoOf(photo)];
    final ids = {for (final photo in entry.photos) photo.id};
    final moments = [
      for (final moment in entry.chapter.moments)
        ?_moment(moment, [
          for (final id in moment.photoIds)
            if (ids.contains(id)) byId[id]!,
        ], clock),
    ].take(2).toList();
    chapters.add(
      NnChapter(
        title: entry.chapter.title,
        // The chapter's own photos (#444): never up to the next chapter's
        // first, which read 09:40–18:42 over two morning photos.
        from: photos.first.takenAt,
        to: photos.last.takenAt,
        photos: photos,
        cardPhotos: [
          for (final photo in [
            for (final id in entry.chapter.cardPhotoIds)
              if (ids.contains(id)) byId[id]!,
          ]..sort((a, b) => a.takenAt.compareTo(b.takenAt)))
            photoOf(photo),
        ],
        note: entry.chapter.note,
        zooms: entry.chapter.cardZooms ?? 2,
        moments: _withLines(
          // No moment: the card alone (#444) when it has its own photos;
          // content from before falls back to a timeline of the chapter.
          moments.isNotEmpty || entry.chapter.cardPhotoIds.isNotEmpty
              ? moments
              : [NnTimeline(_spread(photos))],
          entry.chapter,
          photos,
        ),
      ),
    );
  }

  final first = kept.first.photos.first;
  final firstPhoto = clock.photo(first.id, first.takenAt);
  final date =
      startDate ??
      nn.startDate ??
      DateTime(firstPhoto.year, firstPhoto.month, firstPhoto.day);
  // The Note scene only with a line no chapter already plays (#416).
  final shown = {
    for (final chapter in chapters) ...[
      ?_same(chapter.note),
      for (final moment in chapter.moments)
        for (final photo in moment.photos) ?_same(photo.line),
    ],
  };
  final note = nn.note == null || shown.contains(_same(nn.note!.text))
      ? null
      : nn.note;
  final notePhoto = note?.photoId == null ? null : byId[note!.photoId];
  // Never past the longest film as the player plays it (#450).
  return NnFit.toLongest(
    NeonNightStory(
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
              time: note.writtenAt == null
                  ? null
                  : FilmClock.hhmm(clock.note(note.noteId, note.writtenAt!)),
              photo: notePhoto == null ? null : photoOf(notePhoto),
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
      heartPhotoIds: [
        for (final id in nn.heartPhotoIds)
          if (photoIds.contains(id)) id,
      ],
      targetSeconds: nn.filmSeconds,
    ),
  );
}

/// The longest line a photo plays under it (#426): the server's cap.
const int _maxLineChars = 140;

/// [moments] with the chapter's note lines on their photos (#426), so each
/// line plays when the film reaches its photo — under it, in the moment —
/// instead of in a scene of its own. A line goes on its own photo when a
/// moment shows it, else on the moment photo nearest it in time that has
/// no line yet (one without a caption first). The card's typed line isn't
/// repeated; a line no photo is left for is left out.
List<NnMoment> _withLines(
  List<NnMoment> moments,
  WrapUpNeonChapter chapter,
  List<NnPhoto> photos,
) {
  // The server chose each moment's words (#448): those photos show them
  // (a caption as itself, else as the line); the rest none.
  final chosen = {
    for (final m in chapter.moments) ...?m.words,
  };
  if (chapter.moments.any((m) => m.words != null)) {
    return [
      for (final moment in moments)
        _rebuilt(moment, [
          for (final photo in moment.photos)
            switch (chosen[photo.id]) {
              null => photo.quiet,
              final text when text == photo.caption?.trim() => NnPhoto(
                id: photo.id,
                takenAt: photo.takenAt,
                caption: photo.caption,
                heroScore: photo.heroScore,
              ),
              final text => photo.quiet.withLine(text),
            },
        ]),
    ];
  }
  final order = {for (final (i, p) in photos.indexed) p.id: i};
  final card = _same(chapter.note);
  final lines = <(int, int), String>{};
  final slots = [
    for (final (m, moment) in moments.indexed)
      for (final (k, photo) in moment.photos.indexed) (m, k, photo),
  ];
  for (final (n, e) in chapter.excerpts.indexed) {
    if (_same(e.text) == card || e.text.runes.length > _maxLineChars) {
      continue;
    }
    final free = [
      for (final slot in slots)
        if (!lines.containsKey((slot.$1, slot.$2))) slot,
    ];
    if (free.isEmpty) break;
    // Where the line belongs in the chapter: its photo, else spread.
    final at =
        order[e.photoId] ??
        ((n + 1) * photos.length / (chapter.excerpts.length + 1)).floor();
    (int, int, NnPhoto)? best;
    var bestCost = double.infinity;
    for (final slot in free) {
      final own = slot.$3.id == e.photoId;
      final cost = own
          ? -1.0
          : (order[slot.$3.id]! - at).abs() +
                (slot.$3.caption == null ? 0.0 : 0.5);
      if (cost < bestCost) {
        bestCost = cost;
        best = slot;
      }
    }
    lines[(best!.$1, best.$2)] = e.text;
  }
  if (lines.isEmpty) return moments;
  return [
    for (final (m, moment) in moments.indexed)
      _rebuilt(moment, [
        for (final (k, photo) in moment.photos.indexed)
          switch (lines[(m, k)]) {
            final line? => photo.withLine(line),
            null => photo,
          },
      ]),
  ];
}

NnMoment _rebuilt(NnMoment moment, List<NnPhoto> photos) => switch (moment) {
  NnSplit(:final place) => NnSplit(photos, place: place),
  NnBurst() => NnBurst(photos),
  NnTimeline() => NnTimeline(photos),
  NnPeak() => NnPeak(photos),
};

/// [text] compared loosely: spacing and case.
String? _same(String? text) =>
    text?.replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();

NnMoment? _moment(
  WrapUpNeonMoment moment,
  List<WrapUpNeonPhoto> source,
  FilmClock clock,
) {
  // In the order they were taken (#399 T6), whatever the plan's order.
  final photos = [
    for (final photo in [
      ...source,
    ]..sort((a, b) => a.takenAt.compareTo(b.takenAt)))
      _photo(photo, clock),
  ];
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

NnPhoto _photo(WrapUpNeonPhoto photo, FilmClock clock) => NnPhoto(
  id: photo.id,
  // On the clock of where it was taken (#461).
  takenAt: FilmClock.hhmm(clock.photo(photo.id, photo.takenAt)),
  caption: photo.caption,
  heroScore: photo.heroScore,
);

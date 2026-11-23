import 'film_seconds_model.dart';
import '../../domain/entities/wrap_up_neon_night.dart';

/// The `content.neon_night` version this app reads.
const neonNightContentVersion = 1;

const _momentTypes = {'split', 'burst', 'timeline', 'peak'};

/// Reads the Neon Night film from a wrap-up's `content` (#363): `null`
/// unless `content.neon_night` is version 1 with a title and at least one
/// chapter with photos, so the next film plays instead. Malformed pieces
/// are dropped. Never throws.
WrapUpNeonNight? parseWrapUpNeonNight(Map<String, dynamic> content) {
  final nn = content['neon_night'];
  if (nn is! Map || nn['nn_version'] != neonNightContentVersion) return null;
  final title = _string(nn['title']);
  if (title == null) return null;
  final chapters = _list(nn['chapters']).map(_chapter).nonNulls.toList();
  if (chapters.isEmpty) return null;
  return WrapUpNeonNight(
    title: title,
    startDate: _date(nn['start_date']),
    place: _string(nn['place']),
    plan: _list(nn['plan']).map(_planRow).nonNulls.toList(),
    chapters: chapters,
    note: _note(nn['note']),
    headline: _string(nn['headline']),
    firstName: _string(nn['first_name']),
    totals: _totals(nn['totals']),
    heartPhotoIds: _ids(nn['heart_photo_ids']),
    filmSeconds: parseFilmSeconds(content),
  );
}

final _clock = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');

WrapUpNeonPlanRow? _planRow(dynamic json) {
  if (json is! Map) return null;
  final time = _string(json['time']);
  final title = _string(json['title']);
  if (time == null || !_clock.hasMatch(time) || title == null) return null;
  return WrapUpNeonPlanRow(
    time: time,
    title: title,
    done: json['done'] == true,
  );
}

WrapUpNeonChapter? _chapter(dynamic json) {
  if (json is! Map) return null;
  final title = _string(json['title']);
  if (title == null) return null;
  final photos = <WrapUpNeonPhoto>[];
  for (final photo in _list(json['photos'])) {
    if (photo is! Map) continue;
    final id = _string(photo['id']);
    final takenAt = _instant(photo['taken_at']);
    if (id == null || takenAt == null) continue;
    photos.add(
      WrapUpNeonPhoto(
        id: id,
        takenAt: takenAt,
        caption: _string(photo['caption']),
        heroScore: switch (photo['hero_score']) {
          final num score => score.round(),
          _ => null,
        },
      ),
    );
  }
  if (photos.isEmpty) return null;
  final moments = <WrapUpNeonMoment>[];
  for (final moment in _list(json['moments'])) {
    if (moment is! Map) continue;
    final type = moment['type'];
    if (type is! String || !_momentTypes.contains(type)) continue;
    moments.add(
      WrapUpNeonMoment(
        type: type,
        photoIds: _ids(moment['photo_ids']),
        place: _string(moment['place']),
        words: switch (moment['words']) {
          final List<dynamic> words => {
            for (final w in words)
              if (w is Map &&
                  _string(w['photo_id']) != null &&
                  _string(w['text']) != null)
                _string(w['photo_id'])!: _string(w['text'])!,
          },
          _ => null,
        },
      ),
    );
  }
  return WrapUpNeonChapter(
    title: title,
    photos: photos,
    note: _string(json['note']),
    moments: moments,
    cardPhotoIds: _ids(json['card_photo_ids']),
    cardZooms: switch (json['card_zooms']) {
      final num n => n.round().clamp(0, 2),
      _ => null,
    },
    excerpts: _list(json['excerpts']).map(_excerpt).nonNulls.toList(),
    days: _list(json['days']).map(_date).nonNulls.toList(),
    rejectedExcerpts: _list(
      json['rejected_excerpts'],
    ).map(_rejected).nonNulls.toList(),
  );
}

/// One of a chapter's lines (#398); one without words or note is dropped.
WrapUpNeonExcerpt? _excerpt(dynamic json) {
  if (json is! Map) return null;
  final text = _string(json['text']);
  final noteId = _string(json['note_id']);
  if (text == null || noteId == null) return null;
  final score = json['score'];
  return WrapUpNeonExcerpt(
    text: text,
    noteId: noteId,
    photoId: _string(json['photo_id']),
    fromDirector: json['source'] == 'director',
    score: score is num ? score.round() : 0,
  );
}

WrapUpNeonRejectedExcerpt? _rejected(dynamic json) {
  if (json is! Map) return null;
  final text = _string(json['text']);
  if (text == null) return null;
  final score = json['score'];
  return WrapUpNeonRejectedExcerpt(
    text: text,
    score: score is num ? score.round() : 0,
  );
}

WrapUpNeonNote? _note(dynamic json) {
  if (json is! Map) return null;
  final text = json['text'];
  final number = json['number'];
  if (text is! String || text.trim().isEmpty) return null;
  if (number is! int || number < 1) return null;
  return WrapUpNeonNote(
    text: text.trim(),
    number: number,
    writtenAt: _instant(json['written_at']),
    photoId: _string(json['photo_id']),
    noteId: _string(json['note_id']),
  );
}

WrapUpNeonTotals? _totals(dynamic json) {
  if (json is! Map) return null;
  int? count(dynamic v) => v is int && v >= 0 ? v : null;
  final photos = count(json['photos']);
  final notes = count(json['notes']);
  final ticks = count(json['ticks']);
  final moments = count(json['moments']);
  if (photos == null || notes == null || ticks == null || moments == null) {
    return null;
  }
  return WrapUpNeonTotals(
    photos: photos,
    notes: notes,
    ticks: ticks,
    moments: moments,
  );
}

/// `2026-11-14` as a local calendar date.
DateTime? _date(dynamic value) {
  if (value is! String) return null;
  final parsed = DateTime.tryParse(value);
  return parsed == null
      ? null
      : DateTime(parsed.year, parsed.month, parsed.day);
}

DateTime? _instant(dynamic value) =>
    value is String ? DateTime.tryParse(value) : null;

List<dynamic> _list(dynamic value) => value is List ? value : const [];

List<String> _ids(dynamic value) => value is List
    ? value.whereType<String>().where((id) => id.isNotEmpty).toList()
    : const [];

String? _string(dynamic value) =>
    value is String && value.trim().isNotEmpty ? value.trim() : null;

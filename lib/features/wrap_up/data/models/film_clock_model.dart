import '../../domain/entities/film_clock.dart';

/// `content.local_times` (#461) → a [FilmClock]; absent or malformed = the
/// phone's clock, as every film played before.
FilmClock parseFilmClock(Map<String, dynamic> content) {
  final json = content['local_times'];
  if (json is! Map) return FilmClock.phone;
  Map<String, int> offsets(dynamic map) => {
    if (map is Map)
      for (final MapEntry(:key, :value) in map.entries)
        if (key is String && value is num && value.abs() <= 18 * 60)
          key: value.toInt(),
  };
  Map<String, int> counts(dynamic map) => {
    if (map is Map)
      for (final MapEntry(:key, :value) in map.entries)
        if (key is String && value is num) key: value.toInt(),
  };
  String? text(dynamic value) => value is String ? value : null;
  return FilmClock(
    photoOffsets: offsets(json['photos']),
    noteOffsets: offsets(json['notes']),
    zone: text(json['zone']),
    zoneSource: text(json['zone_source']),
    zoneDetail: text(json['zone_detail']),
    photoSources: counts(json['photo_sources']),
    noteSources: counts(json['note_sources']),
  );
}

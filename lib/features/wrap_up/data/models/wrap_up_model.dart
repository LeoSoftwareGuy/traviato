import '../../domain/entities/wrap_up_achievement_moment.dart';
import '../../domain/entities/wrap_up_close.dart';
import '../../domain/entities/wrap_up_entity.dart';
import '../../domain/entities/wrap_up_hero.dart';
import '../../domain/entities/wrap_up_photo_beat.dart';
import '../../domain/entities/wrap_up_route_chapter.dart';
import '../../domain/entities/wrap_up_route_stop.dart';
import '../../domain/entities/wrap_up_stat_card.dart';
import '../../domain/entities/wrap_up_stat_chapter.dart';

/// Hand-parsed rather than `@JsonSerializable`-generated: `content` is
/// arbitrary AI-generated JSONB (#93's screenplay schema), and every block
/// must degrade to `null`/an empty list on a shape mismatch instead of
/// throwing (issue #94 AC) — logic the generator doesn't express well.
class WrapUpModel extends WrapUpEntity {
  const WrapUpModel({
    super.hero,
    super.routeChapter,
    super.photoBeats,
    super.statChapter,
    super.achievementMoment,
    super.close,
    required super.generatedAt,
    super.publishedAt,
  });

  /// [row] is a `wrap_ups` row shape: `content`, `generated_at`,
  /// `published_at`.
  factory WrapUpModel.fromRow(Map<String, dynamic> row) {
    final content = row['content'];
    final contentMap = content is Map
        ? content.cast<String, dynamic>()
        : const <String, dynamic>{};

    return WrapUpModel(
      hero: _parseHero(contentMap['hero']),
      routeChapter: _parseRouteChapter(contentMap['route_chapter']),
      photoBeats: _parsePhotoBeats(contentMap['photo_beats']),
      statChapter: _parseStatChapter(contentMap['stat_chapter']),
      achievementMoment: _parseAchievementMoment(
        contentMap['achievement_moment'],
      ),
      close: _parseClose(contentMap['close']),
      generatedAt: _parseDateTime(row['generated_at']) ?? DateTime.now(),
      publishedAt: _parseDateTime(row['published_at']),
    );
  }
}

WrapUpHero? _parseHero(dynamic json) {
  if (json is! Map) return null;
  final title = json['title'];
  if (title is! String) return null;
  return WrapUpHero(
    title: title,
    subtitle: json['subtitle'] is String ? json['subtitle'] as String : null,
    coverPhotoId: json['cover_photo_id'] is String
        ? json['cover_photo_id'] as String
        : null,
  );
}

WrapUpRouteChapter? _parseRouteChapter(dynamic json) {
  if (json is! Map) return null;
  final intro = json['intro'];
  if (intro is! String) return null;

  final stops = <WrapUpRouteStop>[];
  final rawStops = json['stops'];
  if (rawStops is List) {
    for (final rawStop in rawStops) {
      final stop = _parseRouteStop(rawStop);
      if (stop != null) stops.add(stop);
    }
  }

  final stats = json['stats'];
  final statsMap = stats is Map
      ? stats.cast<String, dynamic>()
      : const <String, dynamic>{};
  final totalKm = statsMap['total_km'];
  final stopCount = statsMap['stop_count'];

  return WrapUpRouteChapter(
    intro: intro,
    stops: stops,
    totalKm: totalKm is num ? totalKm.toDouble() : null,
    stopCount: stopCount is num ? stopCount.toInt() : stops.length,
  );
}

WrapUpRouteStop? _parseRouteStop(dynamic json) {
  if (json is! Map) return null;
  final placeText = json['place_text'];
  final dayDate = _parseDate(json['day_date']);
  if (placeText is! String || dayDate == null) return null;
  final lat = json['lat'];
  final lng = json['lng'];
  return WrapUpRouteStop(
    placeText: placeText,
    dayDate: dayDate,
    lat: lat is num ? lat.toDouble() : null,
    lng: lng is num ? lng.toDouble() : null,
  );
}

List<WrapUpPhotoBeat> _parsePhotoBeats(dynamic json) {
  if (json is! List) return const [];
  final beats = <WrapUpPhotoBeat>[];
  for (final raw in json) {
    if (raw is! Map) continue;
    final photoId = raw['photo_id'];
    final narrative = raw['narrative'];
    if (photoId is! String || narrative is! String) continue;
    beats.add(
      WrapUpPhotoBeat(
        photoId: photoId,
        dayDate: _parseDate(raw['day_date']),
        narrative: narrative,
      ),
    );
  }
  return beats;
}

WrapUpStatChapter? _parseStatChapter(dynamic json) {
  if (json is! Map) return null;
  final rawStats = json['stats'];
  if (rawStats is! List) return null;
  final stats = <WrapUpStatCard>[];
  for (final raw in rawStats) {
    if (raw is! Map) continue;
    final label = raw['label'];
    final value = raw['value'];
    if (label is! String || value is! String) continue;
    stats.add(WrapUpStatCard(label: label, value: value));
  }
  if (stats.isEmpty) return null;
  return WrapUpStatChapter(stats: stats);
}

WrapUpAchievementMoment? _parseAchievementMoment(dynamic json) {
  if (json is! Map) return null;
  final code = json['code'];
  final title = json['title'];
  final description = json['description'];
  if (code is! String || title is! String || description is! String) {
    return null;
  }
  return WrapUpAchievementMoment(
    code: code,
    title: title,
    description: description,
  );
}

WrapUpClose? _parseClose(dynamic json) {
  if (json is! Map) return null;
  final line = json['line'];
  if (line is! String) return null;
  return WrapUpClose(line: line);
}

DateTime? _parseDateTime(dynamic value) {
  if (value is! String) return null;
  return DateTime.tryParse(value);
}

DateTime? _parseDate(dynamic value) {
  if (value is! String) return null;
  return DateTime.tryParse(value);
}

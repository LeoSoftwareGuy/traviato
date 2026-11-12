import '../../domain/entities/wrap_up_sky.dart';

/// The `content.sky` version this app reads.
const skyContentVersion = 1;

/// The most pages a Sky Story film plays.
const maxSkyPages = 5;

/// Reads Sky Story's pages from a wrap-up's `content` (#345): `null`
/// unless `content.sky` is version 1 with at least one whole page, so the
/// classic film plays instead. A malformed page is dropped; at most
/// [maxSkyPages] are kept. Never throws.
WrapUpSky? parseWrapUpSky(Map<String, dynamic> content) {
  final sky = content['sky'];
  if (sky is! Map || sky['sky_version'] != skyContentVersion) return null;
  final title = sky['title'];
  final rawPages = sky['pages'];
  if (title is! String || rawPages is! List) return null;

  final pages = rawPages
      .map(_page)
      .whereType<WrapUpSkyPage>()
      .take(maxSkyPages)
      .toList();
  if (pages.isEmpty) return null;

  final momentCount = sky['moment_count'];
  return WrapUpSky(
    isFromDirector: sky['source'] == 'director',
    title: title,
    firstName: _optionalString(sky['first_name']),
    momentCount: momentCount is int && momentCount > 0 ? momentCount : 0,
    mosaicPhotoIds: _ids(sky['mosaic_photo_ids']),
    pages: pages,
  );
}

WrapUpSkyPage? _page(dynamic json) {
  if (json is! Map) return null;
  final firstDay = json['first_day'];
  final date = _date(json['date']);
  final hero = json['hero_photo_id'];
  if (firstDay is! int || firstDay < 1 || date == null) return null;
  if (hero is! String || hero.isEmpty) return null;
  final lastDay = json['last_day'];
  final photoCount = json['photo_count'];
  return WrapUpSkyPage(
    firstDay: firstDay,
    lastDay: lastDay is int && lastDay > firstDay ? lastDay : null,
    date: date,
    endDate: _date(json['end_date']),
    photoCount: photoCount is int && photoCount > 0 ? photoCount : 0,
    headline: _optionalString(json['headline']),
    heroPhotoId: hero,
    extraPhotoIds: _ids(
      json['extra_photo_ids'],
    ).where((id) => id != hero).toList(),
    noteId: _optionalString(json['note_id']),
    note: _optionalString(json['note']),
    skyLine: _optionalString(json['sky_line']),
  );
}

/// `2026-06-12` as a local calendar date.
DateTime? _date(dynamic value) {
  if (value is! String) return null;
  final parsed = DateTime.tryParse(value);
  return parsed == null
      ? null
      : DateTime(parsed.year, parsed.month, parsed.day);
}

List<String> _ids(dynamic value) => value is List
    ? value.whereType<String>().where((id) => id.isNotEmpty).toList()
    : const [];

String? _optionalString(dynamic value) =>
    value is String && value.trim().isNotEmpty ? value : null;

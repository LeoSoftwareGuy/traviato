import '../../domain/entities/wrap_up_golden_vows.dart';

/// The `content.golden_vows` version this app reads.
const goldenVowsContentVersion = 1;

/// Reads the Golden Vows album from a wrap-up's `content` (#346): `null`
/// unless `content.golden_vows` is version 1 with a name and at least one
/// hero or chapter, so Sky Story plays instead. Malformed pieces are
/// dropped. Never throws.
WrapUpGoldenVows? parseWrapUpGoldenVows(Map<String, dynamic> content) {
  final gv = content['golden_vows'];
  if (gv is! Map || gv['gv_version'] != goldenVowsContentVersion) return null;
  final names = _string(gv['names']);
  if (names == null) return null;
  final heroes = _list(gv['heroes']).map(_hero).nonNulls.toList();
  final chapters = _list(gv['chapters']).map(_chapter).nonNulls.toList();
  if (heroes.isEmpty && chapters.isEmpty) return null;

  final dayCount = gv['day_count'];
  final momentCount = gv['moment_count'];
  return WrapUpGoldenVows(
    occasion: _string(gv['occasion']),
    occasionLine: _string(gv['occasion_line']),
    names: names,
    startDate: _date(gv['start_date']),
    dayCount: dayCount is int && dayCount > 0 ? dayCount : 1,
    place: _string(gv['place']),
    packing: _packing(gv['packing']),
    heroes: heroes,
    chapters: chapters,
    carousel: _chapter(gv['carousel']),
    heartPhotoIds: _ids(gv['heart_photo_ids']),
    momentCount: momentCount is int && momentCount > 0 ? momentCount : 0,
    endLine: _string(gv['end_line']),
  );
}

WrapUpGoldenVowsPacking? _packing(dynamic json) {
  if (json is! Map) return null;
  final items = <WrapUpGoldenVowsPackedItem>[];
  for (final item in _list(json['items'])) {
    if (item is! Map) continue;
    final text = _string(item['text']);
    if (text == null) continue;
    items.add(
      WrapUpGoldenVowsPackedItem(
        text,
        suggestionCode: _string(item['suggestion_code']),
      ),
    );
  }
  if (items.isEmpty) return null;
  final checked = json['checked'];
  final total = json['total'];
  return WrapUpGoldenVowsPacking(
    items: items,
    isFromQuests: json['source'] == 'quests',
    checked: checked is int && checked > 0 ? checked : null,
    total: total is int && total > 0 ? total : null,
  );
}

WrapUpGoldenVowsHero? _hero(dynamic json) {
  if (json is! Map) return null;
  final photoId = _string(json['photo_id']);
  if (photoId == null) return null;
  final takenAt = _string(json['taken_at']);
  return WrapUpGoldenVowsHero(
    photoId: photoId,
    label: _string(json['label']),
    takenAt: takenAt == null ? null : DateTime.tryParse(takenAt),
    note: _string(json['note']),
  );
}

WrapUpGoldenVowsChapter? _chapter(dynamic json) {
  if (json is! Map) return null;
  final title = _string(json['title']);
  final photoIds = _ids(json['photo_ids']);
  if (title == null || photoIds.isEmpty) return null;
  final layout = json['layout'];
  return WrapUpGoldenVowsChapter(
    title: title,
    line: _string(json['line']),
    photoIds: photoIds,
    layout: const {'A', 'B', 'C'}.contains(layout) ? layout as String : null,
  );
}

/// `2026-06-14` as a local calendar date.
DateTime? _date(dynamic value) {
  if (value is! String) return null;
  final parsed = DateTime.tryParse(value);
  return parsed == null
      ? null
      : DateTime(parsed.year, parsed.month, parsed.day);
}

List<dynamic> _list(dynamic value) => value is List ? value : const [];

List<String> _ids(dynamic value) => value is List
    ? value.whereType<String>().where((id) => id.isNotEmpty).toList()
    : const [];

String? _string(dynamic value) =>
    value is String && value.trim().isNotEmpty ? value.trim() : null;

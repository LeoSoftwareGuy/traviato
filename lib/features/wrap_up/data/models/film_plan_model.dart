import '../../domain/entities/film_plan.dart';
import '../../domain/entities/film_plan_chapter.dart';
import '../../domain/entities/film_plan_scene.dart';

/// Reads the director's plan from a wrap-up's `content` (#344): `null`
/// unless `content.plan_version` is 2 and `content.plan` is a whole,
/// well-formed plan. Unlike the Plan inspector's lenient reading of
/// `wrap_ups.director` (a dev tool shows what it can), a plan that would be
/// played must be all there: one bad scene drops the whole plan, and the
/// film falls back to its template. Never throws.
///
/// Scene types aren't checked against a list here: which ones are playable
/// is up to the template that uses the plan.
FilmPlan? parseFilmPlan(Map<String, dynamic> content) {
  if (content['plan_version'] != 2) return null;
  final plan = content['plan'];
  if (plan is! Map || plan['plan_version'] != 2) return null;

  final chapters = _listOf(plan['chapters'], _chapter);
  if (chapters == null || chapters.isEmpty) return null;

  final footnote = plan['footnote'];
  return FilmPlan(
    occasion: _optionalString(plan['occasion']),
    recipe: _optionalString(plan['recipe']),
    chapters: chapters,
    footnoteLine: footnote is Map ? _optionalString(footnote['line']) : null,
    closingLine: _optionalString(plan['closing_line']),
  );
}

FilmPlanChapter? _chapter(dynamic json) {
  if (json is! Map) return null;
  final bridgeLine = json['bridge_line'];
  if (bridgeLine is! String) return null;
  final scenes = _listOf(json['scenes'], _scene);
  if (scenes == null || scenes.isEmpty) return null;
  return FilmPlanChapter(bridgeLine: bridgeLine, scenes: scenes);
}

FilmPlanScene? _scene(dynamic json) {
  if (json is! Map) return null;
  final type = json['type'];
  final duration = json['duration_s'];
  if (type is! String || type.isEmpty) return null;
  if (duration is! num || !duration.isFinite || duration <= 0) return null;

  final photoIds = _listOf(
    json['photo_ids'] ?? const <dynamic>[],
    (id) => id is String && id.isNotEmpty ? id : null,
  );
  if (photoIds == null) return null;

  final captionNoteId = json['caption_note_id'];
  final text = json['text'];
  if (captionNoteId != null && captionNoteId is! String) return null;
  if (text != null && text is! String) return null;

  return FilmPlanScene(
    type: type,
    photoIds: photoIds,
    captionNoteId: captionNoteId as String?,
    text: text as String?,
    durationSeconds: duration.toDouble(),
    isHero: json['emphasis'] == 'hero',
  );
}

/// [json] as a list with every entry parsed by [parse], or null when it
/// isn't a list or any entry fails.
List<T>? _listOf<T>(dynamic json, T? Function(dynamic) parse) {
  if (json is! List) return null;
  final parsed = <T>[];
  for (final entry in json) {
    final value = parse(entry);
    if (value == null) return null;
    parsed.add(value);
  }
  return parsed;
}

String? _optionalString(dynamic json) => json is String ? json : null;

import '../../domain/entities/film_director_report.dart';
import '../../domain/entities/film_photo_analysis.dart';
import '../../domain/entities/film_plan_chapter.dart';
import '../../domain/entities/film_plan_scene.dart';

/// Hand-parsed like `WrapUpModel`: `wrap_ups.director` is function-written
/// JSONB (#328), and a dev tool should show what it can of an odd shape
/// rather than throw.
class FilmDirectorReportModel extends FilmDirectorReport {
  const FilmDirectorReportModel({
    required super.isPlanned,
    super.occasion,
    super.recipe,
    super.musicEnergy,
    super.reasoning,
    super.chapters,
    super.footnoteLine,
    super.closingLine,
    super.problems,
    super.skyProblems,
    super.hasSkyStory,
    super.runCount,
    super.attempts,
    super.model,
    super.ranAt,
    super.plannablePhotos,
    super.analysedNow,
    super.cachedPhotos,
    super.failedPhotos,
    super.inputTokens,
    super.outputTokens,
    super.estimatedUsd,
  });

  /// Null when [json] isn't a director record (the director never ran).
  static FilmDirectorReportModel? fromJson(dynamic json) {
    if (json is! Map) return null;
    final status = json['status'];
    if (status != 'planned' && status != 'fallback') return null;
    final plan = _map(json['plan']);
    final photos = _map(json['photos']);
    final usage = _map(json['usage']);
    return FilmDirectorReportModel(
      isPlanned: status == 'planned' && plan.isNotEmpty,
      occasion: _string(plan['occasion']),
      recipe: _string(plan['recipe']),
      musicEnergy: _string(_map(plan['music'])['energy']),
      reasoning: _string(plan['reasoning']),
      chapters: _list(plan['chapters']).map(_chapter).toList(),
      footnoteLine: _string(_map(plan['footnote'])['line']),
      closingLine: _string(plan['closing_line']),
      problems: _list(json['problems']).whereType<String>().toList(),
      skyProblems: _list(json['sky_problems']).whereType<String>().toList(),
      hasSkyStory: _map(json['sky_story']).isNotEmpty,
      runCount: _int(json['run_count']),
      attempts: _int(json['attempts']),
      model: _string(json['model']) ?? '',
      ranAt: DateTime.tryParse(_string(json['ran_at']) ?? ''),
      plannablePhotos: _int(photos['plannable']),
      analysedNow: _int(photos['analysed_now']),
      cachedPhotos: _int(photos['cached']),
      failedPhotos: _int(photos['failed']),
      inputTokens: _int(usage['input_tokens']),
      outputTokens: _int(usage['output_tokens']),
      estimatedUsd: _double(usage['estimated_usd']),
    );
  }
}

/// A `photo_analysis` row, or null when it's missing its id.
FilmPhotoAnalysis? filmPhotoAnalysisFromRow(Map<String, dynamic> row) {
  final id = _string(row['photo_id']);
  if (id == null) return null;
  return FilmPhotoAnalysis(
    photoId: id,
    summary: _string(row['summary']) ?? '',
    setting: _string(row['setting']) ?? '',
    people: _string(row['people']) ?? '',
    energy: _string(row['energy']) ?? '',
    quality: _string(row['quality']) ?? '',
    heroScore: _int(row['hero_score']),
    dupGroup: _string(row['dup_group']),
  );
}

FilmPlanChapter _chapter(dynamic json) {
  final map = _map(json);
  return FilmPlanChapter(
    bridgeLine: _string(map['bridge_line']) ?? '',
    scenes: _list(map['scenes']).map(_scene).toList(),
  );
}

FilmPlanScene _scene(dynamic json) {
  final map = _map(json);
  return FilmPlanScene(
    type: _string(map['type']) ?? '?',
    photoIds: _list(map['photo_ids']).whereType<String>().toList(),
    captionNoteId: _string(map['caption_note_id']),
    text: _string(map['text']),
    durationSeconds: _double(map['duration_s']),
    isHero: map['emphasis'] == 'hero',
  );
}

Map<String, dynamic> _map(dynamic json) =>
    json is Map ? json.cast<String, dynamic>() : const {};

List<dynamic> _list(dynamic json) => json is List ? json : const [];

String? _string(dynamic json) => json is String ? json : null;

int _int(dynamic json) => json is num ? json.toInt() : 0;

double _double(dynamic json) => json is num ? json.toDouble() : 0;

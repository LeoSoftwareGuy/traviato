import '../../domain/entities/film_director_report.dart';
import '../../domain/entities/film_neon_slot.dart';
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
    super.goldenVowsOccasion,
    super.goldenVowsProblems,
    super.hasNeonNight,
    super.neonNightProblems,
    super.neonSlots,
    super.gvSlots,
    super.gvTrims,
    super.gvShownPages,
    super.gvShownPhotos,
    super.gvUnlisted,
    super.gvTrigger,
    super.template,
    super.filmSource,
    super.filmRepairs,
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
      goldenVowsOccasion: _string(_map(json['golden_vows'])['occasion']),
      goldenVowsProblems: _list(
        json['golden_vows_problems'],
      ).whereType<String>().toList(),
      hasNeonNight: _map(json['neon_night']).isNotEmpty,
      neonNightProblems: _list(
        json['neon_night_problems'],
      ).whereType<String>().toList(),
      neonSlots: _list(
        json['neon_slots'],
      ).map(_neonSlot).whereType<FilmNeonSlot>().toList(),
      // The same shape as Neon's (#458).
      gvSlots: _list(
        json['gv_slots'],
      ).map(_neonSlot).whereType<FilmNeonSlot>().toList(),
      gvTrims: _list(json['gv_trims']).whereType<String>().toList(),
      gvShownPages: _map(json['gv_shown'])['pages'] is num
          ? _int(_map(json['gv_shown'])['pages'])
          : null,
      gvShownPhotos: _map(json['gv_shown'])['photos'] is num
          ? _int(_map(json['gv_shown'])['photos'])
          : null,
      gvUnlisted: [
        for (final n in _list(json['gv_unlisted']).map(_map))
          if (_string(n['text']) case final text?)
            '$text — ${_string(n['reason']) ?? '?'}',
      ],
      gvTrigger: _trigger(_map(json['gv_trigger'])),
      template: _string(json['template']),
      filmSource: _string(json['${_string(json['template'])}_source']),
      filmRepairs: _list(
        json['${_string(json['template'])}_repairs'],
      ).whereType<String>().toList(),
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

/// A `neon_slots` entry (#454), or null without its slot name.
FilmNeonSlot? _neonSlot(dynamic json) {
  final map = _map(json);
  final slot = _string(map['slot']);
  if (slot == null) return null;
  final pick = _map(map['pick']);
  final chosen = _list(map['chosen']).map(_map).toList();
  return FilmNeonSlot(
    slot: slot,
    candidates: [
      for (final c in _list(map['candidates']).map(_map))
        if (_string(c['id']) case final id?)
          FilmNeonCandidate(
            id: id,
            text: _string(c['text']) ?? '',
            score: _int(c['score']),
          ),
    ],
    // The director's ids carry their slot's name ("ch2.card/n:…").
    pickedIds: [
      for (final id in _list(pick['ids']).whereType<String>())
        id.startsWith('$slot/') ? id.substring(slot.length + 1) : id,
    ],
    freeText: _string(pick['free_title']),
    chosenIds: [for (final c in chosen) ?_string(c['id'])],
    chosen: [for (final c in chosen) ?_string(c['text'])],
    source: _string(map['source']) ?? 'none',
    reason: _string(map['reason']) ?? '',
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

/// "«bride» in photo p03": the word that set the album's occasion (#458).
String? _trigger(Map<String, dynamic> json) {
  final word = _string(json['word']);
  if (word == null) return null;
  final source = switch (_string(json['source'])) {
    'note' => 'note',
    'caption' => "photo's caption",
    _ => "photo's summary",
  };
  return '«$word» in $source ${_string(json['id']) ?? '?'}';
}

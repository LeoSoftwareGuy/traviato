import '../../domain/entities/film_director_report.dart';
import '../../domain/entities/film_neon_slot.dart';
import '../../domain/entities/film_photo_analysis.dart';

/// Hand-parsed like `WrapUpModel`: `wrap_ups.director` is function-written
/// JSONB (#328), and a dev tool should show what it can of an odd shape
/// rather than throw.
class FilmDirectorReportModel extends FilmDirectorReport {
  const FilmDirectorReportModel({
    required super.isPlanned,
    super.problems,
    super.skyProblems,
    super.skySlots,
    super.skyTrims,
    super.skyShownPages,
    super.skyShownPhotos,
    super.skyUnlisted,
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
    final photos = _map(json['photos']);
    final usage = _map(json['usage']);
    return FilmDirectorReportModel(
      isPlanned: status == 'planned',
      problems: _list(json['problems']).whereType<String>().toList(),
      skyProblems: _list(json['sky_problems']).whereType<String>().toList(),
      skySlots: _list(
        json['sky_slots'],
      ).map(_neonSlot).whereType<FilmNeonSlot>().toList(),
      skyTrims: _list(json['sky_trims']).whereType<String>().toList(),
      skyShownPages: _shown(json['sky_shown'], 'pages'),
      skyShownPhotos: _shown(json['sky_shown'], 'photos'),
      skyUnlisted: _unlisted(json['sky_unlisted']),
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
      gvShownPages: _shown(json['gv_shown'], 'pages'),
      gvShownPhotos: _shown(json['gv_shown'], 'photos'),
      gvUnlisted: _unlisted(json['gv_unlisted']),
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

/// A `{pages, photos}` count, or null when absent.
int? _shown(dynamic json, String key) =>
    _map(json)[key] is num ? _int(_map(json)[key]) : null;

/// Notes on no page: "its text — why".
List<String> _unlisted(dynamic json) => [
  for (final n in _list(json).map(_map))
    if (_string(n['text']) case final text?)
      '$text — ${_string(n['reason']) ?? '?'}',
];

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

import 'package:equatable/equatable.dart';

import 'film_plan_chapter.dart';

/// The last director run for a memory (#328, `wrap_ups.director`): the plan
/// it made, or why it fell back to the template film, and what it cost.
/// Read by the debug-only Plan inspector — never shown to users.
class FilmDirectorReport extends Equatable {
  const FilmDirectorReport({
    required this.isPlanned,
    this.occasion,
    this.recipe,
    this.musicEnergy,
    this.reasoning,
    this.chapters = const [],
    this.footnoteLine,
    this.closingLine,
    this.problems = const [],
    this.skyProblems = const [],
    this.hasSkyStory = false,
    this.goldenVowsOccasion,
    this.goldenVowsProblems = const [],
    this.hasNeonNight = false,
    this.neonNightProblems = const [],
    this.template,
    this.filmSource,
    this.filmRepairs = const [],
    this.runCount = 0,
    this.attempts = 0,
    this.model = '',
    this.ranAt,
    this.plannablePhotos = 0,
    this.analysedNow = 0,
    this.cachedPhotos = 0,
    this.failedPhotos = 0,
    this.inputTokens = 0,
    this.outputTokens = 0,
    this.estimatedUsd = 0,
  });

  /// `planned` — false means the film fell back to the template.
  final bool isPlanned;
  final String? occasion;
  final String? recipe;
  final String? musicEnergy;
  final String? reasoning;
  final List<FilmPlanChapter> chapters;
  final String? footnoteLine;
  final String? closingLine;
  final List<String> problems;

  /// Why the director's Sky Story pages weren't used (#345); empty when
  /// [hasSkyStory].
  final List<String> skyProblems;

  /// The run produced Sky Story pages.
  final bool hasSkyStory;

  /// The occasion of the run's Golden Vows section (#346); null when the
  /// director chose another occasion or its section stayed invalid.
  final String? goldenVowsOccasion;

  /// Why the section stayed invalid; empty when there is one, or when the
  /// director left it out on purpose.
  final List<String> goldenVowsProblems;

  /// The run produced a Neon Night section (#363).
  final bool hasNeonNight;

  /// Why the Neon Night section stayed invalid; empty when there is one,
  /// or when the director left it out on purpose.
  final List<String> neonNightProblems;

  /// The film the memory's vibes chose (#433): `golden_vows`,
  /// `neon_night` or `sky_story`; null for a run from before.
  final String? template;

  /// Where that film's section came from: `director` (repaired where it
  /// had to be) or `code`; null for Sky Story or an older run.
  final String? filmSource;

  /// Every repair the section needed, with its reason (#433).
  final List<String> filmRepairs;

  /// Runs for this memory so far (automatic re-runs are capped).
  final int runCount;
  final int attempts;
  final String model;
  final DateTime? ranAt;
  final int plannablePhotos;
  final int analysedNow;
  final int cachedPhotos;
  final int failedPhotos;
  final int inputTokens;
  final int outputTokens;
  final double estimatedUsd;

  double get durationSeconds =>
      chapters.fold(0, (sum, chapter) => sum + chapter.durationSeconds);

  @override
  List<Object?> get props => [
    isPlanned,
    occasion,
    recipe,
    musicEnergy,
    reasoning,
    chapters,
    footnoteLine,
    closingLine,
    problems,
    skyProblems,
    hasSkyStory,
    goldenVowsOccasion,
    goldenVowsProblems,
    hasNeonNight,
    neonNightProblems,
    template,
    filmSource,
    filmRepairs,
    runCount,
    attempts,
    model,
    ranAt,
    plannablePhotos,
    analysedNow,
    cachedPhotos,
    failedPhotos,
    inputTokens,
    outputTokens,
    estimatedUsd,
  ];
}

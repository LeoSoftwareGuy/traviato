import 'package:equatable/equatable.dart';

import 'film_neon_slot.dart';

/// The last director run for a memory (#328, `wrap_ups.director`): the
/// words it picked for the memory's film (#454, #458, #463), why code
/// picked them instead, and what it cost.
/// Read by the debug-only Plan inspector — never shown to users.
class FilmDirectorReport extends Equatable {
  const FilmDirectorReport({
    required this.isPlanned,
    this.problems = const [],
    this.skyProblems = const [],
    this.skySlots = const [],
    this.skyTrims = const [],
    this.skyShownPages,
    this.skyShownPhotos,
    this.skyUnlisted = const [],
    this.goldenVowsOccasion,
    this.goldenVowsProblems = const [],
    this.hasNeonNight = false,
    this.neonNightProblems = const [],
    this.neonSlots = const [],
    this.gvSlots = const [],
    this.gvTrims = const [],
    this.gvShownPages,
    this.gvShownPhotos,
    this.gvUnlisted = const [],
    this.gvTrigger,
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

  /// `planned`: the director picked the film's words (#463) — false means
  /// code picked every slot.
  final bool isPlanned;
  final List<String> problems;

  /// Why the director's Sky Story words weren't used; empty when they
  /// were.
  final List<String> skyProblems;

  /// Every Sky Story slot (#463), as [neonSlots]. Empty for a run from
  /// before, or for a Golden Vows or Neon Night memory.
  final List<FilmNeonSlot> skySlots;

  /// What Sky Story gave up for its length, in order.
  final List<String> skyTrims;

  /// "N / M photos on pages" (the mosaic holds the rest).
  final int? skyShownPages;
  final int? skyShownPhotos;

  /// Notes on no page, each "its text — why".
  final List<String> skyUnlisted;

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

  /// Every Neon Night slot (#454): its candidates, the director's pick,
  /// what plays and why. Empty for a run from before.
  final List<FilmNeonSlot> neonSlots;

  /// Every Golden Vows slot (#458), as [neonSlots]. Empty for a run from
  /// before.
  final List<FilmNeonSlot> gvSlots;

  /// What the album gave up for its length (#458), in order.
  final List<String> gvTrims;

  /// "N / M photos shown" on the album's pages (the heart holds them all).
  final int? gvShownPages;
  final int? gvShownPhotos;

  /// Notes on no main page, each "its text — why".
  final List<String> gvUnlisted;

  /// What made it a wedding, engagement…: "«свадьба» in note n1"; null
  /// = romance (nothing did).
  final String? gvTrigger;

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

  @override
  List<Object?> get props => [
    isPlanned,
    problems,
    skyProblems,
    skySlots,
    skyTrims,
    skyShownPages,
    skyShownPhotos,
    skyUnlisted,
    goldenVowsOccasion,
    goldenVowsProblems,
    hasNeonNight,
    neonNightProblems,
    neonSlots,
    gvSlots,
    gvTrims,
    gvShownPages,
    gvShownPhotos,
    gvUnlisted,
    gvTrigger,
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

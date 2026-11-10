import 'package:equatable/equatable.dart';

import 'film_plan_chapter.dart';

/// The director's film plan (#328, `plan_version: 2`) as stored in a
/// wrap-up's `content.plan` (#344). Read and validated, but nothing plays
/// it yet: the film templates (#345, #346) decide which plans they can use.
class FilmPlan extends Equatable {
  const FilmPlan({
    this.occasion,
    this.recipe,
    required this.chapters,
    this.footnoteLine,
    this.closingLine,
  });

  final String? occasion;
  final String? recipe;

  /// At least one, each with at least one scene.
  final List<FilmPlanChapter> chapters;
  final String? footnoteLine;
  final String? closingLine;

  double get durationSeconds =>
      chapters.fold(0, (sum, chapter) => sum + chapter.durationSeconds);

  @override
  List<Object?> get props => [
    occasion,
    recipe,
    chapters,
    footnoteLine,
    closingLine,
  ];
}

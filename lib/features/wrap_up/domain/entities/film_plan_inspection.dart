import 'package:equatable/equatable.dart';

import 'film_director_report.dart';
import 'film_photo_analysis.dart';

/// Everything the debug Plan inspector (#328) shows for one memory: the
/// last director run (null when it never ran) and the cached analysis of
/// each photo, by photo id.
class FilmPlanInspection extends Equatable {
  const FilmPlanInspection({this.report, this.analyses = const {}});

  final FilmDirectorReport? report;
  final Map<String, FilmPhotoAnalysis> analyses;

  @override
  List<Object?> get props => [report, analyses];
}

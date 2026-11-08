import 'package:equatable/equatable.dart';

import 'film_plan_scene.dart';

/// A chapter of the director's film plan (#328): its bridge line, then its
/// scenes in order.
class FilmPlanChapter extends Equatable {
  const FilmPlanChapter({required this.bridgeLine, this.scenes = const []});

  final String bridgeLine;
  final List<FilmPlanScene> scenes;

  double get durationSeconds =>
      scenes.fold(0, (sum, scene) => sum + scene.durationSeconds);

  @override
  List<Object?> get props => [bridgeLine, scenes];
}

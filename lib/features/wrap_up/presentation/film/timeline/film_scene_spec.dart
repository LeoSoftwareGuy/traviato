import 'package:equatable/equatable.dart';

/// What one scene of a `FilmTimeline` shows (#344). Each film template has
/// its own sealed family of scene types (`ClassicSceneSpec`, the Sky Story
/// scenes, …), so its canvas can handle every one of them exhaustively;
/// when a scene plays and for how long lives on the `TimedScene` around it.
abstract class FilmSceneSpec extends Equatable {
  const FilmSceneSpec();
}

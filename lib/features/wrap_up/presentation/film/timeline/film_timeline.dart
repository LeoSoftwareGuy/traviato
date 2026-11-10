import 'package:equatable/equatable.dart';

import 'film_scene_spec.dart';

/// One scene on the film's master clock: it plays from [start] for
/// [duration] seconds and shows [spec].
class TimedScene<S extends FilmSceneSpec> extends Equatable {
  const TimedScene({
    required this.start,
    required this.duration,
    required this.spec,
  });

  final double start;
  final double duration;
  final S spec;

  double get end => start + duration;

  @override
  List<Object?> get props => [start, duration, spec];
}

/// A film as an ordered list of timed scenes, all driven by one looping
/// clock (#344). Scenes follow each other with no gap and no overlap; a
/// frame may still animate a little before its start or after its end
/// (a toss in, a fade out), but the schedule itself is contiguous.
class FilmTimeline<S extends FilmSceneSpec> extends Equatable {
  /// Lays [scenes] end to end from 0, in order, with the given durations.
  factory FilmTimeline.sequence(List<(double, S)> scenes) {
    var cursor = 0.0;
    final timed = <TimedScene<S>>[];
    for (final (duration, spec) in scenes) {
      assert(duration > 0, 'a scene must last: $spec');
      timed.add(TimedScene(start: cursor, duration: duration, spec: spec));
      cursor += duration;
    }
    return FilmTimeline<S>._(List.unmodifiable(timed), cursor);
  }

  const FilmTimeline._(this.scenes, this.total);

  /// In play order.
  final List<TimedScene<S>> scenes;

  /// Film length in seconds: the clock's loop duration.
  final double total;

  /// The first scene showing a [T], or null when none plays.
  TimedScene<S>? first<T extends S>() {
    for (final scene in scenes) {
      if (scene.spec is T) return scene;
    }
    return null;
  }

  @override
  List<Object?> get props => [scenes, total];
}

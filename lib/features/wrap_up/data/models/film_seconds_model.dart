/// `content.film_seconds` (#434): how long the film plays, from its
/// photos; the film fits its scenes to it. Null for content from before
/// #434 and for kept films that weren't rebuilt — they keep their pacing —
/// or anything that isn't a plausible length.
double? parseFilmSeconds(Map<String, dynamic> content) {
  final value = content['film_seconds'];
  if (value is! num || !value.isFinite) return null;
  final seconds = value.toDouble();
  return seconds >= 10 && seconds <= 300 ? seconds : null;
}

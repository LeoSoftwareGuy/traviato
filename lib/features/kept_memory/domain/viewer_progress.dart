/// The Kept Memory viewer's progress line (#279): one segment per day,
/// each as wide as that day's photo count, filled up to the current photo.
///
/// Returns each segment's fill (0–1) for [index] (0-based, across every
/// day's photos in order) — days before the current one are full, days
/// after it empty, and the current day filled through the current photo.
List<double> dayProgressFills(List<int> dayPhotoCounts, int index) {
  final fills = <double>[];
  var start = 0;
  for (final count in dayPhotoCounts) {
    if (count <= 0) {
      fills.add(index >= start ? 1 : 0);
      continue;
    }
    final seen = (index + 1 - start).clamp(0, count);
    fills.add(seen / count);
    start += count;
  }
  return fills;
}

/// The next photo the slideshow shows after [index] — it loops back to the
/// first after the last.
int nextSlideshowIndex(int index, int count) =>
    count <= 0 ? 0 : (index + 1) % count;

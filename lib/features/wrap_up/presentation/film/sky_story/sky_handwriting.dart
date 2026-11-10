/// Wraps [text] into lines no wider than [maxWidth], as [measure] sizes
/// them (#345). Past [maxLines] the last line is cut at a word and ends in
/// `…`, so a long note never runs off its card. A single word wider than
/// the line keeps its own line rather than being split.
List<String> wrapWords(
  String text,
  double maxWidth,
  double Function(String) measure, {
  int maxLines = 3,
}) {
  final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
  final lines = <String>[];
  var current = '';
  for (final word in words) {
    final candidate = current.isEmpty ? word : '$current $word';
    if (current.isNotEmpty && measure(candidate) > maxWidth) {
      lines.add(current);
      current = word;
    } else {
      current = candidate;
    }
  }
  if (current.isNotEmpty) lines.add(current);
  if (lines.length <= maxLines) return lines;

  final kept = lines.take(maxLines).toList();
  var last = kept.last.split(' ');
  while (last.length > 1 && measure('${last.join(' ')}…') > maxWidth) {
    last = last.sublist(0, last.length - 1);
  }
  kept[maxLines - 1] = '${_trimTrailingPunctuation(last.join(' '))}…';
  return kept;
}

String _trimTrailingPunctuation(String s) =>
    s.replaceFirst(RegExp(r'[\s,;:.\-–—]+$'), '');

/// When each handwritten line writes on (#345): left to right at a steady
/// hand's [speed] (px/s), a short [gap] between lines, as the reference's
/// Day 2 note does (three lines in about 3.5 s).
List<({double start, double end})> writeOnSchedule(
  List<double> lineWidths,
  double from, {
  double speed = 560,
  double gap = 0.35,
}) {
  final schedule = <({double start, double end})>[];
  var at = from;
  for (final width in lineWidths) {
    final end = at + width / speed;
    schedule.add((start: at, end: end));
    at = end + gap;
  }
  return schedule;
}

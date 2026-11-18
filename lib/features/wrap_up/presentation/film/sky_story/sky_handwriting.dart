/// Wraps [text] into lines no wider than [maxWidth], as [measure] sizes
/// them (#345). Never cut (#399): a caller checks [fitsWords] first and
/// shows fewer whole sentences instead. A single word wider than the line
/// keeps its own line rather than being split.
List<String> wrapWords(
  String text,
  double maxWidth,
  double Function(String) measure,
) {
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
  return lines;
}

/// Whether [text] wraps into at most [maxLines] lines of [maxWidth], none
/// of them wider (a single over-wide word doesn't fit).
bool fitsWords(
  String text,
  double maxWidth,
  double Function(String) measure, {
  required int maxLines,
}) {
  final lines = wrapWords(text, maxWidth, measure);
  return lines.isNotEmpty &&
      lines.length <= maxLines &&
      lines.every((line) => measure(line) <= maxWidth);
}

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

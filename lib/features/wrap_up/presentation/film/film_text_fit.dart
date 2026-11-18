import 'package:flutter/painting.dart';

/// [text] laid out at the first of [sizes] (largest first) at which it
/// fits on [maxLines] lines of [maxWidth], or null when it fits at none
/// (#399: the films never cut the user's words with "…"; a caller shows
/// fewer whole sentences or nothing instead).
TextPainter? fitTextPainter(
  String text,
  TextStyle Function(double size) style, {
  required Iterable<double> sizes,
  required double maxWidth,
  required int maxLines,
  TextAlign align = TextAlign.start,
}) {
  for (final size in sizes) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style(size)),
      textDirection: TextDirection.ltr,
      textAlign: align,
      maxLines: maxLines,
    )..layout(maxWidth: maxWidth);
    if (!painter.didExceedMaxLines) return painter;
    painter.dispose();
  }
  return null;
}

/// Sizes from [from] down to [to] in steps of [step], for [fitTextPainter].
Iterable<double> fitSizes(double from, double to, {double step = 2}) sync* {
  for (var size = from; size >= to - 1e-9; size -= step) {
    yield size;
  }
}

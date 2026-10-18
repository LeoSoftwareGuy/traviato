import 'package:flutter/material.dart';

/// A UI label that shrinks rather than truncates (localization spec 4t,
/// "SHRINK"): first tightens letter-spacing down to [minLetterSpacing],
/// then steps the font size down to [minFontSize] to stay on one line.
/// If it still doesn't fit at the floor it wraps onto up to [maxLines]
/// lines. Never an ellipsis — UI labels don't truncate (#241).
class ShrinkToFloorText extends StatelessWidget {
  const ShrinkToFloorText(
    this.text, {
    required this.style,
    required this.minFontSize,
    this.minLetterSpacing,
    this.maxLines = 1,
    this.textAlign,
    super.key,
  });

  final String text;
  final TextStyle style;
  final double minFontSize;
  final double? minLetterSpacing;
  final int maxLines;
  final TextAlign? textAlign;

  static const _step = .5;

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final fitted = fittedStyle(
          text: text,
          style: style,
          maxWidth: constraints.maxWidth,
          minFontSize: minFontSize,
          minLetterSpacing: minLetterSpacing,
          textScaler: scaler,
          textDirection: direction,
        );
        return Text(
          text,
          style: fitted.style,
          textAlign: textAlign,
          maxLines: fitted.fitsOnOneLine ? 1 : maxLines,
          softWrap: !fitted.fitsOnOneLine,
        );
      },
    );
  }

  /// The largest style (tracking first, then size) that fits [text] on one
  /// line within [maxWidth]; the floor style when nothing does.
  @visibleForTesting
  static ({TextStyle style, bool fitsOnOneLine}) fittedStyle({
    required String text,
    required TextStyle style,
    required double maxWidth,
    required double minFontSize,
    double? minLetterSpacing,
    TextScaler textScaler = TextScaler.noScaling,
    TextDirection textDirection = TextDirection.ltr,
  }) {
    bool fits(TextStyle candidate) {
      if (!maxWidth.isFinite) return true;
      final painter = TextPainter(
        text: TextSpan(text: text, style: candidate),
        maxLines: 1,
        textDirection: textDirection,
        textScaler: textScaler,
      )..layout();
      final ok = !painter.didExceedMaxLines && painter.width <= maxWidth;
      painter.dispose();
      return ok;
    }

    var candidate = style;
    if (fits(candidate)) return (style: candidate, fitsOnOneLine: true);
    if (minLetterSpacing != null &&
        (candidate.letterSpacing ?? 0) > minLetterSpacing) {
      candidate = candidate.copyWith(letterSpacing: minLetterSpacing);
      if (fits(candidate)) return (style: candidate, fitsOnOneLine: true);
    }
    var size = candidate.fontSize ?? 14;
    while (size - _step >= minFontSize - 1e-9) {
      size -= _step;
      candidate = candidate.copyWith(fontSize: size);
      if (fits(candidate)) return (style: candidate, fitsOnOneLine: true);
    }
    return (style: candidate, fitsOnOneLine: false);
  }
}

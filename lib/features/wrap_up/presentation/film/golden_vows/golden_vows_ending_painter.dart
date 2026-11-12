import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import '../marks/balloon_mark.dart';
import 'golden_vows_ending.dart';
import 'golden_vows_texts.dart';
import 'golden_vows_tokens.dart';

/// The spec's "end mark" layer (#346, §5.6), between the heart and the
/// gold frame: the balloon over "Storyni", a gold rule and the names and
/// date, all fading out with the frame at the very end.
class GoldenVowsEndingPainter extends CustomPainter {
  GoldenVowsEndingPainter({
    required this.ending,
    required this.texts,
    required this.time,
  }) : super(repaint: time);

  final GoldenVowsEnding ending;
  final GvEndingTexts texts;
  final ValueListenable<double> time;

  static const _balloon = BalloonMark(style: GoldenVowsColors.balloon);

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    if (!ending.visibleAt(t)) return;
    final fade = ending.fade(t);

    _balloon.paint(
      canvas,
      topLeft: Offset(GoldenVowsEnding.balloonX, ending.balloonY(t)),
      scale: GoldenVowsEnding.balloonScale,
      opacity: fade,
    );

    final wordmark = texts.wordmark(ending.wordmarkSpacing(t));
    gvPaintText(
      canvas,
      wordmark,
      Offset(540 - wordmark.width / 2, GoldenVowsEnding.wordmarkTop),
      ending.wordmark(t) * fade,
      blur: ending.wordmarkBlur(t),
    );

    final grown = ending.ruleGrown(t);
    if (grown > 0) {
      const rule = GoldenVowsEnding.rule;
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(rule.x + rule.width / 2, rule.y + rule.height / 2),
          width: rule.width * grown,
          height: rule.height,
        ),
        Paint()..color = GoldenVowsColors.gold.withValues(alpha: fade),
      );
    }

    final line = ending.lineAt(t);
    gvPaintText(
      canvas,
      texts.line,
      Offset(540 - texts.line.width / 2, line.top),
      line.opacity * fade,
    );
  }

  @override
  bool shouldRepaint(GoldenVowsEndingPainter oldDelegate) =>
      oldDelegate.ending != ending ||
      oldDelegate.texts != texts ||
      oldDelegate.time != time;
}

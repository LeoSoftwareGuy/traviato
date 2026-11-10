import 'package:flutter/material.dart';

import '../wrap_up_film_motion.dart';
import '../timeline/film_timeline.dart';
import '../wrap_up_film_tokens.dart';

/// One AI-written bridge line between chapters — never a photograph
/// (docs/design/WRAP_UP_FILM_FLUTTER_SPEC.md § Bridges). Bridge2 (index 1) is fully
/// opaque; the others let the persistent chrome show through underneath.
class WrapUpFilmBridge extends StatelessWidget {
  const WrapUpFilmBridge({
    required this.t,
    required this.scene,
    required this.index,
    required this.line,
    super.key,
  });

  final double t;
  final TimedScene scene;
  final int index;
  final String line;

  @override
  Widget build(BuildContext context) {
    final a = scene.start;
    final dur = scene.duration;
    final solid = index == 1;
    // Fade-out tracks this bridge's own duration (ending 1.0s before its
    // slot closes) rather than a fixed offset from `a` — otherwise
    // lengthening the schedule slot alone just adds dead air after the text
    // has already faded, not more time to read it.
    final grp = band(t, a + 0.2, 1.1, a + dur - 1.0, 1.0);
    if (grp <= 0.004) return const SizedBox.shrink();

    final plateOpacity = (grp * (solid ? 1.0 : 0.88)).clamp(0.0, 1.0);
    final textRise = rise(t, a + 0.5, 2.0, lift: 34);

    return Positioned.fill(
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: plateOpacity,
              child: const ColoredBox(color: WrapUpFilmColors.bg),
            ),
          ),
          Positioned(
            left: 120,
            right: 120,
            top: 780,
            child: Opacity(
              opacity: grp.clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(0, textRise.translateY),
                child: Opacity(
                  opacity: textRise.opacity.clamp(0.0, 1.0),
                  child: Text(
                    line,
                    textAlign: TextAlign.center,
                    style: WrapUpFilmText.serif(
                      size: 62,
                      height: 1.42,
                      italic: true,
                      color: WrapUpFilmColors.ink.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

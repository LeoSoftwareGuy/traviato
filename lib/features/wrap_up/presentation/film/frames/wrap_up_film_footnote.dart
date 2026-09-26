import 'package:flutter/material.dart';

import '../../../domain/entities/wrap_up_footnote.dart';
import '../wrap_up_film_motion.dart';
import '../wrap_up_film_scenes.dart';
import '../wrap_up_film_tokens.dart';

/// The numbers, demoted to one breath: photographs taken, bonus tasks
/// completed, stars earned — no distance, no step count
/// (docs/design/WRAP_UP_FILM_FLUTTER_SPEC.md § Footnote).
class WrapUpFilmFootnote extends StatelessWidget {
  const WrapUpFilmFootnote({
    required this.t,
    required this.scenes,
    required this.footnote,
    super.key,
  });

  final double t;
  final WrapUpFilmScenes scenes;
  final WrapUpFootnote footnote;

  @override
  Widget build(BuildContext context) {
    final a = scenes.footnoteStart;
    final grp = band(t, a + 0.3, 1.2, a + 3.0, 1.0);
    if (grp <= 0.004) return const SizedBox.shrink();

    final rowRise = rise(t, a + 0.5, 1.6, lift: 26);
    final closingRise = rise(t, a + 1.6, 1.6, lift: 24);

    final bonusLabel = footnote.bonusCompletedCount == 1
        ? 'bonus task'
        : 'bonus tasks';
    final bits = [
      ('${footnote.photoCount}', 'photographs', false),
      ('${footnote.bonusCompletedCount}', bonusLabel, false),
      ('✦${footnote.stars}', 'stars', true),
    ];

    return Positioned(
      left: 90,
      right: 90,
      top: 880,
      child: Opacity(
        opacity: grp.clamp(0.0, 1.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.translate(
              offset: Offset(0, rowRise.translateY),
              child: Opacity(
                opacity: rowRise.opacity.clamp(0.0, 1.0),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.end,
                  spacing: 44,
                  children: [
                    for (final (value, label, isAccent) in bits)
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            value,
                            style: WrapUpFilmText.serif(
                              size: 76,
                              height: 1.0,
                              letterSpacing: -2,
                              color: isAccent
                                  ? WrapUpFilmColors.accent
                                  : WrapUpFilmColors.ink,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            label.toUpperCase(),
                            style: WrapUpFilmText.mono(
                              size: 19,
                              color: WrapUpFilmColors.faint,
                              letterSpacingEm: 0.2,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 64),
            Transform.translate(
              offset: Offset(0, closingRise.translateY),
              child: Opacity(
                opacity: closingRise.opacity.clamp(0.0, 1.0),
                child: Text(
                  "None of which is the reason you'll remember it.",
                  textAlign: TextAlign.center,
                  style: WrapUpFilmText.serif(
                    size: 40,
                    height: 1.5,
                    italic: true,
                    color: WrapUpFilmColors.dim,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

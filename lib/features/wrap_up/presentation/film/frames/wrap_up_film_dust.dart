import 'package:flutter/material.dart';

import '../wrap_up_film_motion.dart';
import '../wrap_up_film_scenes.dart';
import '../wrap_up_film_tokens.dart';

/// Opening frame: five star specks, a growing hairline, and the trip's
/// dates — no photograph, no copy (docs/design/wrap-film-spec.md § Dust).
class WrapUpFilmDust extends StatelessWidget {
  const WrapUpFilmDust({
    required this.t,
    required this.datesFormatted,
    super.key,
  });

  final double t;
  final String datesFormatted;

  static const _specks = [
    (214.0, 470.0, 2.4, 0.5),
    (820.0, 372.0, 3.2, 1.1),
    (318.0, 1276.0, 2.6, 1.7),
    (742.0, 1420.0, 3.0, 0.9),
    (540.0, 236.0, 2.2, 2.1),
  ];

  @override
  Widget build(BuildContext context) {
    final line = swell(t, 1.2, 1.9, 0, 168);
    final lineOpacity = band(t, 1.2, 1.0, 2.7, 0.7).clamp(0.0, 1.0);
    final dateOpacity = band(t, 0.6, 1.4, 2.5, 0.9).clamp(0.0, 1.0);

    return Stack(
      children: [
        for (var i = 0; i < _specks.length; i++) ..._speck(i),
        Positioned(
          left: 540 - line,
          top: 1040,
          width: line * 2,
          height: 1,
          child: Opacity(
            opacity: lineOpacity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    WrapUpFilmColors.accent.withValues(alpha: 0),
                    WrapUpFilmColors.accent,
                    WrapUpFilmColors.accent.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 900,
          child: Opacity(
            opacity: dateOpacity,
            child: Center(
              child: Text(
                datesFormatted.toUpperCase(),
                style: WrapUpFilmText.mono(
                  size: 28,
                  color: WrapUpFilmColors.dim,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _speck(int i) {
    final (left, top, radius, phase) = _specks[i];
    final diameter = radius * 2.6;
    final opacity =
        (band(t, phase, 1.4, WrapUpFilmScenes.keepsakeStart - 1.4, 1.8) * 0.7)
            .clamp(0.0, 1.0);
    return [
      Positioned(
        left: left,
        top: top,
        width: diameter,
        height: diameter,
        child: Opacity(
          opacity: opacity,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i.isOdd ? WrapUpFilmColors.accent : WrapUpFilmColors.ink,
            ),
          ),
        ),
      ),
    ];
  }
}

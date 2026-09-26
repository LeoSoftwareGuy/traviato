import 'package:flutter/material.dart';

import '../../../domain/entities/wrap_up_unlock.dart';
import '../wrap_up_film_motion.dart';
import '../wrap_up_film_scenes.dart';
import '../wrap_up_film_tokens.dart';

/// The achievement earned by this trip, if any (docs/design/WRAP_UP_FILM_FLUTTER_SPEC.md
/// § Unlock). `null` skips the whole frame — the player's call, per the #126
/// plan comment.
class WrapUpFilmUnlock extends StatelessWidget {
  const WrapUpFilmUnlock({
    required this.t,
    required this.scenes,
    required this.unlock,
    super.key,
  });

  final double t;
  final WrapUpFilmScenes scenes;
  final WrapUpUnlock? unlock;

  @override
  Widget build(BuildContext context) {
    final unlock = this.unlock;
    if (unlock == null) return const SizedBox.shrink();

    final a = scenes.unlockStart;
    final grp = band(t, a + 0.2, 1.0, a + 3.8, 0.9);
    if (grp <= 0.004) return const SizedBox.shrink();

    final pop = toss(t, a + 0.4, 1.1);
    final ringA = swell(t, a + 0.6, 2.4, 0.4, 2.5);
    final ringB = swell(t, a + 1.1, 2.4, 0.4, 2.5);
    final nameRise = rise(t, a + 1.3, 1.5, lift: 34);
    final reasonRise = rise(t, a + 2.0, 1.6, lift: 30);

    return Positioned(
      left: 110,
      right: 110,
      top: 740,
      child: Opacity(
        opacity: grp.clamp(0.0, 1.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 300,
              child: Stack(
                alignment: Alignment.topCenter,
                clipBehavior: Clip.none,
                children: [
                  _ring(ringA, (0.5 - ringA * 0.2).clamp(0.0, 1.0)),
                  _ring(ringB, (0.4 - ringB * 0.16).clamp(0.0, 1.0)),
                  Positioned(
                    top: 62,
                    child: Transform.scale(
                      scale: pop,
                      child: Opacity(
                        opacity: pop.clamp(0.0, 1.0),
                        child: Text(
                          '✦',
                          style: WrapUpFilmText.serif(
                            size: 168,
                            height: 1.0,
                            color: WrapUpFilmColors.accent,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Transform.translate(
              offset: Offset(0, nameRise.translateY),
              child: Opacity(
                opacity: nameRise.opacity.clamp(0.0, 1.0),
                child: Text(
                  unlock.name,
                  textAlign: TextAlign.center,
                  style: WrapUpFilmText.serif(
                    size: 96,
                    height: 1.06,
                    letterSpacing: -2,
                    color: WrapUpFilmColors.ink,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 26),
            Transform.translate(
              offset: Offset(0, reasonRise.translateY),
              child: Opacity(
                opacity: reasonRise.opacity.clamp(0.0, 1.0),
                child: Text(
                  unlock.reason,
                  textAlign: TextAlign.center,
                  style: WrapUpFilmText.sans(
                    size: 38,
                    height: 1.6,
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

  Widget _ring(double scale, double opacity) {
    return Opacity(
      opacity: opacity,
      child: Transform.scale(
        scale: scale,
        child: Container(
          width: 300,
          height: 300,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: WrapUpFilmColors.accent),
          ),
        ),
      ),
    );
  }
}

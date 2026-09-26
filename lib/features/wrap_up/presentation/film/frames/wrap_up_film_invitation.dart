import 'package:flutter/material.dart';

import '../wrap_up_film_motion.dart';
import '../wrap_up_film_scenes.dart';
import '../wrap_up_film_tokens.dart';

/// "Five days. / One long road." — line 1 computed, line 2 AI-written
/// (docs/design/WRAP_UP_FILM_FLUTTER_SPEC.md § Invitation).
class WrapUpFilmInvitation extends StatelessWidget {
  const WrapUpFilmInvitation({
    required this.t,
    required this.scenes,
    required this.line1,
    required this.line2,
    super.key,
  });

  final double t;
  final WrapUpFilmScenes scenes;
  final String line1;
  final String line2;

  @override
  Widget build(BuildContext context) {
    final a = scenes.invitationStart;
    final rise1 = rise(t, a + 0.4, 1.8, lift: 46);
    final rise2 = rise(t, a + 1.6, 1.8, lift: 46);
    final out = fade(t, a + 3.2, 1.0, 1, 0).clamp(0.0, 1.0);

    return Positioned(
      left: 110,
      right: 110,
      top: 760,
      child: Opacity(
        opacity: out,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.translate(
              offset: Offset(0, rise1.translateY),
              child: Opacity(
                opacity: rise1.opacity.clamp(0.0, 1.0),
                child: Text(
                  line1,
                  style: WrapUpFilmText.serif(
                    size: 132,
                    height: 0.98,
                    letterSpacing: -3,
                    color: WrapUpFilmColors.ink,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Transform.translate(
              offset: Offset(0, rise2.translateY),
              child: Opacity(
                opacity: rise2.opacity.clamp(0.0, 1.0),
                child: Text(
                  line2,
                  style: WrapUpFilmText.serif(
                    size: 132,
                    height: 1.0,
                    letterSpacing: -3,
                    italic: true,
                    color: WrapUpFilmColors.amber,
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

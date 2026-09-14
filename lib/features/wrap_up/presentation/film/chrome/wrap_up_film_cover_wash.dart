import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../wrap_up_film_motion.dart';
import '../wrap_up_film_scenes.dart';

/// The persistent background photo washes (docs/design/wrap-film-spec.md §6)
/// — the cover image, blurred and drifting behind the opening/middle
/// sections, then returning sharp and full-bleed for the Keepsake close.
class WrapUpFilmCoverWash extends StatelessWidget {
  const WrapUpFilmCoverWash({
    required this.t,
    required this.scenes,
    required this.coverImage,
    super.key,
  });

  final double t;
  final WrapUpFilmScenes scenes;
  final ImageProvider? coverImage;

  @override
  Widget build(BuildContext context) {
    final image = coverImage;
    if (image == null) return const SizedBox.shrink();

    final coverEarly = band(
      t,
      scenes.invitationStart - 0.2,
      2.0,
      scenes.bridge1Start - 0.3,
      1.5,
    );
    final routeWash = band(
      t,
      scenes.invitationStart + 1.4,
      1.3,
      scenes.bridge1Start - 0.2,
      1.1,
    );
    final roomTone = band(
      t,
      scenes.bridge1Start - 0.4,
      1.6,
      scenes.footnoteStart - 0.6,
      1.4,
    );
    final coverLate = band(
      t,
      scenes.keepsakeStart - 0.6,
      2.3,
      scenes.keepsakeStart + 5.3,
      1.3,
    );

    final earlyOpacity = (coverEarly * 0.22 + routeWash * 0.07 + roomTone * 0.1)
        .clamp(0.0, 1.0);
    final earlyScale = swell(t, 3.0, 40.0, 1.04, 1.28);
    final lateOpacity = coverLate.clamp(0.0, 1.0);
    final lateScale = swell(t, scenes.keepsakeStart - 1.0, 9.0, 1.02, 1.16);

    return Stack(
      children: [
        if (earlyOpacity > 0.002)
          Positioned.fill(
            child: Opacity(
              opacity: earlyOpacity,
              child: ImageFiltered(
                imageFilter: ui.ImageFilter.blur(sigmaX: 7, sigmaY: 7),
                child: _cover(image, earlyScale),
              ),
            ),
          ),
        if (lateOpacity > 0.002) ...[
          Positioned.fill(
            child: Opacity(
              opacity: lateOpacity,
              child: _cover(image, lateScale, dyPercent: -0.6),
            ),
          ),
          Positioned.fill(
            child: Opacity(
              opacity: lateOpacity,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  // CSS `linear-gradient(to top, rgba(...,.94) 6%,
                  // rgba(...,.34) 46%, rgba(...,.72) 100%)` — darkest at the
                  // bottom (where the title sits), lighter through the
                  // middle, darker again toward the top.
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Color(0xF007091A),
                      Color(0x5707091A),
                      Color(0xB807091A),
                    ],
                    stops: [0.06, 0.46, 1.0],
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _cover(ImageProvider image, double scale, {double dyPercent = 0}) {
    return ClipRect(
      child: FractionalTranslation(
        translation: Offset(0, dyPercent / 100),
        child: Transform.scale(
          scale: 1.16 * scale,
          child: Image(image: image, fit: BoxFit.cover),
        ),
      ),
    );
  }
}

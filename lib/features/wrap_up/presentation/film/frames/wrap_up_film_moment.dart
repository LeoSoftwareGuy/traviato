import 'package:flutter/material.dart';

import '../../../domain/entities/wrap_up_moment.dart';
import '../wrap_up_film_motion.dart';
import '../wrap_up_film_scenes.dart';
import '../wrap_up_film_tokens.dart';
import 'wrap_up_film_plate.dart';

/// One Moment: thrown in, held centre-frame while its caption is read, then
/// it slides down into the pile and stays there for the rest of the middle
/// section (docs/design/wrap-film-spec.md § Moments). Index 0..7 maps to
/// scenes M1..M8 via [WrapUpFilmScenes.momentStarts].
class WrapUpFilmMoment extends StatelessWidget {
  const WrapUpFilmMoment({
    required this.t,
    required this.scenes,
    required this.index,
    required this.moment,
    required this.imageUrl,
    required this.pileFade,
    super.key,
  });

  final double t;
  final WrapUpFilmScenes scenes;
  final int index;
  final WrapUpMoment moment;
  final String? imageUrl;
  final double pileFade;

  double get _dur => WrapUpFilmScenes.momentDurations[index];

  @override
  Widget build(BuildContext context) {
    final at = scenes.momentStarts[index];
    final inAt = at - 0.45;
    final to = at + _dur;
    final goAt = to - 0.85;

    if (t < inAt || t > scenes.footnoteStart + 0.2) {
      return const SizedBox.shrink();
    }

    final thrown = toss(t, inAt, 0.75);
    final gone = fade(t, goAt, 0.85, 0, 1);

    final pileCx = (300 + (index % 5) * 118 + (index > 4 ? 26 : 0)).toDouble();
    final pileCy = (1824 + (index % 3) * 7).toDouble();
    final pileRot = (rnd(index, 9) - 0.5) * 22;

    final cx = mix(540, pileCx, gone);
    final cy = mix(mix(880, 782, thrown), pileCy, gone);
    final swellPush = swell(t, at - 0.5, 5.4, 1, 1.035);
    final scale = mix(mix(0.86, 1, thrown) * swellPush, 0.4, gone);
    final rot = mix((1 - thrown) * -5, pileRot, gone);
    final lift = mix(thrown, 0.35, gone);

    final flip = Curves.easeInOutCubic.transform(
      ((t - (at + 0.3)) / 0.58).clamp(0.0, 1.0),
    );

    final live = 1 - gone;
    final tagRise = rise(t, at + 0.82, 1.0, lift: 22);
    final noteRise = rise(t, at + 1.0, 1.25, lift: 28);
    final capOut = fade(t, goAt - 0.15, 0.6, 1, 0);
    final captionOpacity = (live * capOut * pileFade).clamp(0.0, 1.0);

    return Stack(
      children: [
        WrapUpFilmPlate(
          cx: cx,
          cy: cy,
          scale: scale,
          rotationDeg: rot,
          opacity: pileFade,
          lift: lift,
          flip: flip,
          imageUrl: imageUrl,
        ),
        if (captionOpacity > 0.002)
          Positioned(
            left: 108,
            right: 108,
            top: 1330,
            child: Opacity(
              opacity: captionOpacity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (moment.badge != null)
                    Transform.translate(
                      offset: Offset(0, tagRise.translateY),
                      child: Opacity(
                        opacity: tagRise.opacity.clamp(0.0, 1.0),
                        child: Text(
                          moment.badge!.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: WrapUpFilmText.mono(
                            size: 21,
                            color: WrapUpFilmColors.dare,
                            letterSpacingEm: 0.22,
                          ),
                        ),
                      ),
                    ),
                  if (moment.note != null)
                    Transform.translate(
                      offset: Offset(0, noteRise.translateY),
                      child: Opacity(
                        opacity: noteRise.opacity.clamp(0.0, 1.0),
                        child: Padding(
                          padding: EdgeInsets.only(
                            top: moment.badge != null ? 24 : 0,
                          ),
                          child: Text(
                            moment.note!,
                            textAlign: TextAlign.center,
                            style: WrapUpFilmText.serif(
                              size: 50,
                              height: 1.5,
                              italic: true,
                              color: WrapUpFilmColors.ink,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

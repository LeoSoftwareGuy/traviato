import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../wrap_up_film_motion.dart';
import '../wrap_up_film_scenes.dart';
import '../wrap_up_film_tokens.dart';
import 'wrap_up_film_small_print.dart';

/// The rest of what remains: face-up prints crossing the frame, unhurried —
/// the first couple run corner to corner, later ones bend and exit through
/// the top centre (docs/design/wrap-film-spec.md § Flurry2). [photoUrls]
/// holds up to 15 entries (the player's own display cap), already sliced
/// from whatever Flurry1 didn't show.
class WrapUpFilmFlurry2 extends StatelessWidget {
  const WrapUpFilmFlurry2({
    required this.t,
    required this.photoUrls,
    required this.remainingLabel,
    super.key,
  });

  final double t;
  final List<String?> photoUrls;
  final String? remainingLabel;

  @override
  Widget build(BuildContext context) {
    const a = WrapUpFilmScenes.flurry2Start;
    const next = WrapUpFilmScenes.bridge3Start;
    final grp = band(t, a + 0.05, 0.5, next - 0.25, 0.7);
    if (grp <= 0.004) return const SizedBox.shrink();

    final n = photoUrls.length < 15 ? photoUrls.length : 15;
    final specs = <_WaveCardSpec>[
      for (var i = 0; i < n; i++)
        () {
          final w = 240 + rnd(i, 57) * 120;
          final bend = Curves.easeInOutSine.transform(
            ((i - 2) / (n < 4 ? 1 : n - 3)).clamp(0.0, 1.0),
          );
          const width = 1080.0;
          return _WaveCardSpec(
            imageUrl: photoUrls[i],
            at: a + 0.1 + i * 0.16,
            dur: 3.0 + rnd(i, 58) * 0.6,
            w: w,
            h: w * (0.74 + rnd(i, 59) * 0.4),
            amp: (120 + rnd(i, 60) * 200) * (1 - bend * 0.6),
            toX: mix(width + 160, width * 0.5 - w / 2, bend),
            toY: mix(-360, -520, bend),
          );
        }(),
    ];

    final labelRise = rise(t, a + 0.5, 1.0, lift: 22);

    return Positioned.fill(
      child: Stack(
        children: [
          for (final spec in specs)
            _WrapUpFilmWaveCard(t: t, spec: spec, opacity: grp),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 360,
            child: Opacity(
              opacity: grp.clamp(0.0, 1.0),
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0xB807091A), Color(0x0007091A)],
                    stops: [0.18, 1.0],
                  ),
                ),
              ),
            ),
          ),
          if (remainingLabel != null)
            Positioned(
              left: 110,
              top: 300,
              child: Opacity(
                opacity: grp.clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(0, labelRise.translateY),
                  child: Opacity(
                    opacity: labelRise.opacity.clamp(0.0, 1.0),
                    child: Text(
                      remainingLabel!.toUpperCase(),
                      style: WrapUpFilmText.mono(color: WrapUpFilmColors.dim),
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

class _WaveCardSpec {
  const _WaveCardSpec({
    required this.imageUrl,
    required this.at,
    required this.dur,
    required this.w,
    required this.h,
    required this.amp,
    required this.toX,
    required this.toY,
  });

  final String? imageUrl;
  final double at;
  final double dur;
  final double w;
  final double h;
  final double amp;
  final double toX;
  final double toY;
}

class _WrapUpFilmWaveCard extends StatelessWidget {
  const _WrapUpFilmWaveCard({
    required this.t,
    required this.spec,
    required this.opacity,
  });

  final double t;
  final _WaveCardSpec spec;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    if (t <= spec.at || t >= spec.at + spec.dur) return const SizedBox.shrink();
    final p = ((t - spec.at) / spec.dur).clamp(0.0, 1.0);
    final e = Curves.easeInOutSine.transform(p);
    final o =
        (((p / 0.12).clamp(0.0, 1.0)) *
                ((1 - p) / 0.16).clamp(0.0, 1.0) *
                opacity)
            .clamp(0.0, 1.0);
    if (o <= 0.004) return const SizedBox.shrink();

    final bump = spec.toX < 648 ? 150.0 : 0.0;
    final x = mix(-420, spec.toX, e) + math.sin(e * math.pi) * bump;
    final y = mix(1880, spec.toY, e) + math.sin(e * 2 * math.pi) * spec.amp;
    final rot = mix(-13, spec.toX < 648 ? 4 : 13, e);

    return Positioned(
      left: 0,
      top: 0,
      child: Transform(
        transform: Matrix4.identity()
          ..translateByDouble(x, y, 0, 1)
          ..rotateZ(rot * math.pi / 180),
        child: RepaintBoundary(
          child: Opacity(
            opacity: o,
            child: WrapUpFilmSmallPrint(
              imageUrl: spec.imageUrl,
              width: spec.w,
              height: spec.h,
              shadowBlur: 54,
              shadowOffsetY: 26,
              shadowOpacity: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

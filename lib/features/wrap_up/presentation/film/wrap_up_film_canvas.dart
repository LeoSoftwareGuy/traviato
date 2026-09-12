import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../domain/entities/wrap_up_entity.dart';
import 'chrome/wrap_up_film_cover_wash.dart';
import 'chrome/wrap_up_film_grain.dart';
import 'chrome/wrap_up_film_letterbox.dart';
import 'chrome/wrap_up_film_vignette.dart';
import 'frames/wrap_up_film_bridge.dart';
import 'frames/wrap_up_film_dust.dart';
import 'frames/wrap_up_film_flurry1.dart';
import 'frames/wrap_up_film_flurry2.dart';
import 'frames/wrap_up_film_footnote.dart';
import 'frames/wrap_up_film_invitation.dart';
import 'frames/wrap_up_film_keepsake.dart';
import 'frames/wrap_up_film_moment.dart';
import 'frames/wrap_up_film_unlock.dart';
import 'wrap_up_film_motion.dart';
import 'wrap_up_film_scenes.dart';
import 'wrap_up_film_tokens.dart';

/// One continuous 1080×1920 composition, driven by a single looping
/// `AnimationController` (docs/design/wrap-film-spec.md §1, §7). Every child
/// reads the same `T` and computes its own opacity/transform — no per-scene
/// widgets, no per-element tickers.
class WrapUpFilmCanvas extends StatefulWidget {
  const WrapUpFilmCanvas({
    required this.wrapUp,
    required this.photoUrlById,
    required this.coverImage,
    required this.grainImage,
    super.key,
  });

  static const double width = 1080;
  static const double height = 1920;

  final WrapUpEntity wrapUp;
  final Map<String, String> photoUrlById;
  final ImageProvider? coverImage;
  final ui.Image? grainImage;

  @override
  State<WrapUpFilmCanvas> createState() => _WrapUpFilmCanvasState();
}

class _WrapUpFilmCanvasState extends State<WrapUpFilmCanvas>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: (WrapUpFilmScenes.total * 1000).round(),
      ),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _urlFor(String photoId) => widget.photoUrlById[photoId];

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: WrapUpFilmColors.bg,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = _controller.value * WrapUpFilmScenes.total;
              return FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: WrapUpFilmCanvas.width,
                  height: WrapUpFilmCanvas.height,
                  child: ClipRect(child: _buildLayers(t)),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildLayers(double t) {
    final wrapUp = widget.wrapUp;
    final leftovers = wrapUp.flurryLeftovers.photos;
    final flurry1Urls = leftovers
        .take(15)
        .map((p) => _urlFor(p.photoId))
        .toList();
    final flurry2Urls = leftovers
        .skip(15)
        .take(15)
        .map((p) => _urlFor(p.photoId))
        .toList();

    final pileFade = band(
      t,
      WrapUpFilmScenes.bridge1Start,
      0.8,
      WrapUpFilmScenes.footnoteStart - 0.9,
      1.0,
    );

    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        WrapUpFilmCoverWash(t: t, coverImage: widget.coverImage),
        WrapUpFilmDust(t: t, datesFormatted: wrapUp.dates.formatted),
        WrapUpFilmInvitation(
          t: t,
          line1: wrapUp.invitation.line1,
          line2: wrapUp.invitation.line2,
        ),
        for (var i = 0; i < wrapUp.moments.length; i++)
          WrapUpFilmMoment(
            t: t,
            index: i,
            moment: wrapUp.moments[i],
            imageUrl: _urlFor(wrapUp.moments[i].photoId),
            pileFade: pileFade,
          ),
        for (var i = 0; i < wrapUp.bridges.length && i < 3; i++)
          WrapUpFilmBridge(t: t, index: i, line: wrapUp.bridges[i]),
        WrapUpFilmFlurry1(t: t, photoUrls: flurry1Urls),
        WrapUpFilmFlurry2(
          t: t,
          photoUrls: flurry2Urls,
          remainingLabel: wrapUp.flurryLeftovers.totalRemainingLabel,
        ),
        WrapUpFilmFootnote(t: t, footnote: wrapUp.footnote),
        WrapUpFilmUnlock(t: t, unlock: wrapUp.unlock),
        WrapUpFilmKeepsake(t: t, keepsake: wrapUp.keepsake),
        const WrapUpFilmVignette(),
        WrapUpFilmGrain(t: t, image: widget.grainImage),
        WrapUpFilmLetterbox(t: t),
      ],
    );
  }
}

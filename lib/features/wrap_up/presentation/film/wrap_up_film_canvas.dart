import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../domain/entities/wrap_up_entity.dart';
import 'chrome/wrap_up_film_cover_wash.dart';
import 'chrome/wrap_up_film_grain.dart';
import 'chrome/wrap_up_film_letterbox.dart';
import 'chrome/wrap_up_film_vignette.dart';
import 'frames/wrap_up_film_bridge.dart';
import 'frames/wrap_up_film_collage.dart';
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
/// `AnimationController` (docs/design/WRAP_UP_FILM_FLUTTER_SPEC.md §1, §7). Every child
/// reads the same `T` and computes its own opacity/transform — no per-scene
/// widgets, no per-element tickers.
class WrapUpFilmCanvas extends StatefulWidget {
  const WrapUpFilmCanvas({
    required this.wrapUp,
    required this.photoUrlById,
    required this.coverImage,
    required this.grainImage,
    this.collages = true,
    super.key,
  });

  static const double width = 1080;
  static const double height = 1920;

  final WrapUpEntity wrapUp;
  final Map<String, String> photoUrlById;
  final ImageProvider? coverImage;
  final ui.Image? grainImage;

  /// Feature flag (docs/design/WRAP_UP_FILM_COLLAGE_SPEC.md §1). `false`
  /// plays every moment as a card flip, exactly as before collages
  /// existed — a collage's extra tiles are then simply not shown, so
  /// nothing ever repeats.
  final bool collages;

  @override
  State<WrapUpFilmCanvas> createState() => _WrapUpFilmCanvasState();
}

class _WrapUpFilmCanvasState extends State<WrapUpFilmCanvas>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final WrapUpFilmScenes _scenes;
  late final List<String?> _flurry1Urls;
  late final List<String?> _flurry2Urls;

  @override
  void initState() {
    super.initState();

    final wrapUp = widget.wrapUp;
    _flurry1Urls = wrapUp.flurry1Photos.map((p) => _urlFor(p.photoId)).toList();
    _flurry2Urls = wrapUp.flurry2Photos.map((p) => _urlFor(p.photoId)).toList();
    _scenes = WrapUpFilmScenes.forWrapUp(wrapUp);

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (_scenes.total * 1000).round()),
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
              final t = _controller.value * _scenes.total;
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

    final pileFade = band(
      t,
      _scenes.bridge1Start,
      0.8,
      _scenes.footnoteStart - 0.9,
      1.0,
    );

    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        WrapUpFilmCoverWash(
          t: t,
          scenes: _scenes,
          coverImage: widget.coverImage,
        ),
        WrapUpFilmDust(
          t: t,
          scenes: _scenes,
          datesFormatted: wrapUp.dates.formatted,
        ),
        WrapUpFilmInvitation(
          t: t,
          scenes: _scenes,
          line1: wrapUp.invitation.line1,
          line2: wrapUp.invitation.line2,
        ),
        for (
          var i = 0;
          i < wrapUp.moments.length && i < _scenes.momentStarts.length;
          i++
        )
          _buildMoment(t, i, pileFade),
        for (var i = 0; i < wrapUp.bridges.length && i < 3; i++)
          if (_bridgePlays(i))
            WrapUpFilmBridge(
              t: t,
              scenes: _scenes,
              index: i,
              line: wrapUp.bridges[i],
            ),
        if (_scenes.hasFlurry1)
          WrapUpFilmFlurry1(t: t, scenes: _scenes, photoUrls: _flurry1Urls),
        if (_scenes.hasFlurry2)
          WrapUpFilmFlurry2(
            t: t,
            scenes: _scenes,
            photoUrls: _flurry2Urls,
            remainingLabel: wrapUp.flurryLeftovers.totalRemainingLabel,
          ),
        WrapUpFilmFootnote(t: t, scenes: _scenes, footnote: wrapUp.footnote),
        if (_scenes.hasUnlock)
          WrapUpFilmUnlock(t: t, scenes: _scenes, unlock: wrapUp.unlock!),
        WrapUpFilmKeepsake(t: t, scenes: _scenes, keepsake: wrapUp.keepsake),
        const WrapUpFilmVignette(),
        WrapUpFilmGrain(t: t, image: widget.grainImage),
        WrapUpFilmLetterbox(t: t),
      ],
    );
  }

  bool _bridgePlays(int index) => switch (index) {
    1 => _scenes.hasBridge2,
    2 => _scenes.hasBridge3,
    _ => true,
  };

  /// A collage when the plan made this moment one (and the flag allows
  /// it), otherwise the card flip — collages never enter the card pile.
  Widget _buildMoment(double t, int index, double pileFade) {
    final moment = widget.wrapUp.moments[index];
    final layout = moment.layout;
    if (widget.collages && layout != null && widget.wrapUp.cut != null) {
      final at = _scenes.momentStarts[index];
      return WrapUpFilmCollage(
        t: t,
        at: at,
        to: at + WrapUpFilmScenes.momentDurations[index],
        layout: layout,
        imageUrls: [
          for (final ref in moment.allPhotoRefs.take(layout.tileCount))
            _urlFor(ref.photoId),
        ],
        note: moment.note,
      );
    }
    return WrapUpFilmMoment(
      t: t,
      scenes: _scenes,
      index: index,
      moment: moment,
      imageUrl: _urlFor(moment.photoId),
      pileFade: pileFade,
    );
  }
}

import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../domain/entities/wrap_up_entity.dart';
import '../../domain/entities/wrap_up_photo_ref.dart';
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
import 'timeline/classic_scene_spec.dart';
import 'timeline/film_timeline.dart';
import 'timeline/template_timeline.dart';
import 'wrap_up_film_motion.dart';
import 'wrap_up_film_tokens.dart';

/// One continuous 1080×1920 composition, driven by a single looping
/// `AnimationController` (docs/design/WRAP_UP_FILM_FLUTTER_SPEC.md §1, §7).
/// The schedule is a [FilmTimeline] (#344): every scene's frame is built
/// from the same `T` and its own [TimedScene], and computes its own
/// opacity/transform, with no per-element tickers.
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
  late final TemplateTimeline _template;

  /// The timeline's scenes in paint order (see [_paintRank]).
  late final List<TimedScene<ClassicSceneSpec>> _layers;

  @override
  void initState() {
    super.initState();

    _template = TemplateTimeline.forWrapUp(
      widget.wrapUp,
      collages: widget.collages,
    );
    _layers = [
      for (final scene in _template.timeline.scenes)
        if (scene.spec is! HoldSceneSpec) scene,
    ];
    // List.sort isn't stable, so break ties on play order.
    final order = {
      for (final (i, scene) in _layers.indexed) scene: i,
    };
    _layers.sort((a, b) {
      final byRank = _paintRank(a.spec).compareTo(_paintRank(b.spec));
      return byRank != 0 ? byRank : order[a]!.compareTo(order[b]!);
    });

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (_template.total * 1000).round()),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// The template paints by kind, not by time: the card pile stays on
  /// screen under the later bridges and Flurries, and a later scene's fade
  /// in overlaps an earlier one's fade out.
  static int _paintRank(ClassicSceneSpec spec) => switch (spec) {
    DustSceneSpec() => 0,
    InvitationSceneSpec() => 1,
    CardFlipSceneSpec() || CollageSceneSpec() => 2,
    BridgeSceneSpec() => 3,
    FlurrySceneSpec(:final round) => 3 + round,
    FootnoteSceneSpec() => 6,
    UnlockSceneSpec() => 7,
    KeepsakeSceneSpec() => 8,
    HoldSceneSpec() => 9,
  };

  String? _urlFor(String photoId) => widget.photoUrlById[photoId];

  List<String?> _urlsFor(Iterable<WrapUpPhotoRef> refs) => [
    for (final ref in refs) _urlFor(ref.photoId),
  ];

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: WrapUpFilmColors.bg,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = _controller.value * _template.total;
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
    final anchors = _template.anchors;
    final pileFade = band(
      t,
      anchors.bridge1Start,
      0.8,
      anchors.footnoteStart - 0.9,
      1.0,
    );

    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        WrapUpFilmCoverWash(
          t: t,
          anchors: anchors,
          coverImage: widget.coverImage,
        ),
        for (final scene in _layers) _buildScene(t, scene, pileFade),
        const WrapUpFilmVignette(),
        WrapUpFilmGrain(t: t, image: widget.grainImage),
        WrapUpFilmLetterbox(t: t),
      ],
    );
  }

  Widget _buildScene(
    double t,
    TimedScene<ClassicSceneSpec> scene,
    double pileFade,
  ) {
    final anchors = _template.anchors;
    return switch (scene.spec) {
      DustSceneSpec(:final datesFormatted) => WrapUpFilmDust(
        t: t,
        scene: scene,
        datesFormatted: datesFormatted,
        specksUntil: anchors.keepsakeStart,
      ),
      InvitationSceneSpec(:final invitation) => WrapUpFilmInvitation(
        t: t,
        scene: scene,
        line1: invitation.line1,
        line2: invitation.line2,
      ),
      BridgeSceneSpec(:final index, :final line) => WrapUpFilmBridge(
        t: t,
        scene: scene,
        index: index,
        line: line,
      ),
      CardFlipSceneSpec(:final pileIndex, :final moment) => WrapUpFilmMoment(
        t: t,
        scene: scene,
        index: pileIndex,
        hideAfter: anchors.footnoteStart + 0.2,
        moment: moment,
        imageUrl: _urlFor(moment.photoId),
        pileFade: pileFade,
      ),
      CollageSceneSpec(:final moment, :final layout) => WrapUpFilmCollage(
        t: t,
        at: scene.start,
        to: scene.end,
        layout: layout,
        imageUrls: _urlsFor(moment.allPhotoRefs.take(layout.tileCount)),
        note: moment.note,
      ),
      FlurrySceneSpec(round: 1, :final photos) => WrapUpFilmFlurry1(
        t: t,
        scene: scene,
        photoUrls: _urlsFor(photos),
      ),
      FlurrySceneSpec(:final photos, :final remainingLabel) =>
        WrapUpFilmFlurry2(
          t: t,
          scene: scene,
          photoUrls: _urlsFor(photos),
          remainingLabel: remainingLabel,
        ),
      FootnoteSceneSpec(:final footnote) => WrapUpFilmFootnote(
        t: t,
        scene: scene,
        footnote: footnote,
      ),
      UnlockSceneSpec(:final unlock) => WrapUpFilmUnlock(
        t: t,
        scene: scene,
        unlock: unlock,
      ),
      KeepsakeSceneSpec(:final keepsake) => WrapUpFilmKeepsake(
        t: t,
        scene: scene,
        keepsake: keepsake,
      ),
      HoldSceneSpec() => const SizedBox.shrink(),
    };
  }
}

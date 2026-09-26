import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../domain/entities/wrap_up_collage_layout.dart';
import '../wrap_up_film_motion.dart';
import '../wrap_up_film_tokens.dart';
import 'wrap_up_film_collage_layouts.dart';

/// A collage moment (docs/design/WRAP_UP_FILM_COLLAGE_SPEC.md): a full-frame
/// multi-photo layout that replaces the card flip. Tiles slide/zoom in one
/// after another with a slow Ken Burns settle, the caption rises over a
/// bottom scrim, then the whole collage fades out on its own — it never
/// drops into the card pile.
///
/// Driven only by the film's single clock [t], so scrubbing/seeking works
/// like every other frame. [at]/[to] are this moment's cue and the next
/// one's. [imageUrls] is tile 0 (the moment's own photo) then the collage
/// tiles, in paint order; `null` entries render as bare paper.
class WrapUpFilmCollage extends StatelessWidget {
  const WrapUpFilmCollage({
    required this.t,
    required this.at,
    required this.to,
    required this.layout,
    required this.imageUrls,
    required this.note,
    super.key,
  });

  final double t;
  final double at;
  final double to;
  final WrapUpCollageLayout layout;
  final List<String?> imageUrls;
  final String? note;

  /// Whether the collage is on screen at all at [t] (spec §4 render window).
  static bool isVisibleAt(double t, double at, double to) =>
      t >= at - 0.55 && t <= to + 0.1;

  @override
  Widget build(BuildContext context) {
    if (!isVisibleAt(t, at, to)) return const SizedBox.shrink();

    final spec = collageLayouts[layout]!;
    final bgOpacity = swell(t, at - 0.45, 0.35, 0, 1);
    final scrimOpacity = swell(t, at + 0.6, 0.9, 0, 1);
    final exitOpacity = swell(t, to - 0.85, 0.85, 1, 0);
    final exitScale = swell(t, to - 0.85, 0.85, 1, 1.05);
    if (exitOpacity <= 0.002) return const SizedBox.shrink();

    final tileCount = math.min(spec.tiles.length, imageUrls.length);

    return Positioned.fill(
      child: Opacity(
        opacity: exitOpacity,
        child: Transform.scale(
          scale: exitScale,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: Opacity(
                  opacity: bgOpacity,
                  child: ColoredBox(color: spec.background),
                ),
              ),
              for (var i = 0; i < tileCount; i++)
                _CollageTile(
                  key: ValueKey('collage-tile-$i'),
                  t: t,
                  at: at,
                  to: to,
                  index: i,
                  spec: spec.tiles[i],
                  isPaper: spec.isPaper,
                  imageUrl: imageUrls[i],
                ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 760,
                child: Opacity(
                  opacity: scrimOpacity,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Color(0xEB07091A),
                          Color(0xB307091A),
                          Color(0x0007091A),
                        ],
                        stops: [0, .45, 1],
                      ),
                    ),
                  ),
                ),
              ),
              if (note != null) _CollageCaption(t: t, at: at, note: note!),
            ],
          ),
        ),
      ),
    );
  }
}

class _CollageTile extends StatelessWidget {
  const _CollageTile({
    required this.t,
    required this.at,
    required this.to,
    required this.index,
    required this.spec,
    required this.isPaper,
    required this.imageUrl,
    super.key,
  });

  final double t;
  final double at;
  final double to;
  final int index;
  final CollageTileSpec spec;
  final bool isPaper;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final start = at - 0.45 + index * 0.20;
    final p = ((t - start) / 0.8).clamp(0.0, 1.0);
    if (p <= 0) return const SizedBox.shrink();
    final e = Curves.easeOutCubic.transform(p);

    var dx = 0.0;
    var dy = 0.0;
    var scale = 1.0;
    switch (spec.entry) {
      case CollageEntry.left:
        dx = -(spec.x + spec.w + 80) * (1 - e);
      case CollageEntry.right:
        dx = (1080 - spec.x + 80) * (1 - e);
      case CollageEntry.top:
        dy = -(spec.y + spec.h + 80) * (1 - e);
      case CollageEntry.bottom:
        dy = (1920 - spec.y + 80) * (1 - e);
      case CollageEntry.zoom:
        scale = mix(1.25, 1.0, Curves.easeOutBack.transform(p));
    }
    final rotationDeg = spec.rotationDeg + (1 - e) * (index.isOdd ? 6 : -6);
    final opacity = (e * 1.6).clamp(0.0, 1.0);

    // Ken Burns: 1.14 → 1.00 linearly, from this tile's own start over the
    // collage's whole on-screen span.
    final kenBurns = swell(t, start, to - (at - 0.45), 1.14, 1.0);

    return Positioned(
      left: spec.x,
      top: spec.y,
      width: spec.w,
      height: spec.h,
      child: Opacity(
        opacity: opacity,
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..translateByDouble(dx, dy, 0, 1)
            ..rotateZ(rotationDeg * math.pi / 180)
            ..scaleByDouble(scale, scale, 1, 1),
          child: RepaintBoundary(
            child: _TileBody(
              index: index,
              spec: spec,
              isPaper: isPaper,
              imageUrl: imageUrl,
              kenBurns: kenBurns,
            ),
          ),
        ),
      ),
    );
  }
}

/// A tile's painted layers: shadow (paper layouts), torn paper backing
/// (torn tiles), then the clipped, Ken-Burns-scaled photo.
class _TileBody extends StatelessWidget {
  const _TileBody({
    required this.index,
    required this.spec,
    required this.isPaper,
    required this.imageUrl,
    required this.kenBurns,
  });

  final int index;
  final CollageTileSpec spec;
  final bool isPaper;
  final String? imageUrl;
  final double kenBurns;

  @override
  Widget build(BuildContext context) {
    final w = spec.w;
    final h = spec.h;
    final paperPath = spec.isTorn
        ? tornOutline(
            w: w,
            h: h,
            tornEdges: spec.tornEdges,
            seed: index + 17,
            amp: 7,
            pad: 11,
          )
        : null;
    final photoPath = spec.isTorn
        ? tornOutline(
            w: w,
            h: h,
            tornEdges: spec.tornEdges,
            seed: index + 3,
            amp: 5,
            pad: -2,
          )
        : (Path()..addRect(Rect.fromLTWH(0, 0, w, h)));

    // The image box bleeds 60px past the tile on every side so the Ken
    // Burns scale — and a torn tile's overhanging straight edges — never
    // uncover an empty edge.
    Widget photo = Transform.scale(
      scale: kenBurns,
      child: _TilePhoto(imageUrl: imageUrl),
    );
    if (spec.isHero) {
      photo = ColorFiltered(colorFilter: _heroFilter, child: photo);
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (isPaper)
          Positioned.fill(
            child: CustomPaint(
              painter: _PathShadowPainter(paperPath ?? photoPath),
            ),
          ),
        if (paperPath != null)
          Positioned.fill(
            child: CustomPaint(painter: _PathFillPainter(paperPath)),
          ),
        Positioned.fill(
          child: ClipPath(
            clipper: _PathClipper(photoPath),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: -60,
                  top: -60,
                  width: w + 120,
                  height: h + 120,
                  child: photo,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Grayscale (Rec. 709 luma) then contrast ×1.1 — torn6's hero piece.
const _heroContrast = 1.1;
const _heroOffset = 127.5 * (1 - _heroContrast);
const _heroFilter = ColorFilter.matrix(<double>[
  0.2126 * _heroContrast,
  0.7152 * _heroContrast,
  0.0722 * _heroContrast,
  0,
  _heroOffset, //
  0.2126 * _heroContrast,
  0.7152 * _heroContrast,
  0.0722 * _heroContrast,
  0,
  _heroOffset, //
  0.2126 * _heroContrast,
  0.7152 * _heroContrast,
  0.0722 * _heroContrast,
  0,
  _heroOffset, //
  0, 0, 0, 1, 0, //
]);

class _TilePhoto extends StatelessWidget {
  const _TilePhoto({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    const blank = ColoredBox(color: WrapUpFilmColors.paper);
    if (imageUrl == null) return blank;
    return CachedNetworkImage(
      imageUrl: imageUrl!,
      fit: BoxFit.cover,
      fadeInDuration: const Duration(milliseconds: 220),
      fadeOutDuration: Duration.zero,
      placeholder: (context, url) => blank,
      errorWidget: (context, url, error) => blank,
    );
  }
}

class _PathClipper extends CustomClipper<Path> {
  const _PathClipper(this.path);

  final Path path;

  @override
  Path getClip(Size size) => path;

  @override
  bool shouldReclip(_PathClipper oldClipper) => oldClipper.path != path;
}

/// The torn paper backing — sticks out past the photo as a white rim.
class _PathFillPainter extends CustomPainter {
  const _PathFillPainter(this.path);

  final Path path;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(path, Paint()..color = WrapUpFilmColors.paperRim);
  }

  @override
  bool shouldRepaint(_PathFillPainter oldDelegate) => oldDelegate.path != path;
}

/// Drop shadow painted from the tile's own outline — a `BoxShadow` would
/// ignore the torn edge. Spec: offset (0, 10), blur 22, rgba(0,0,0,.28).
class _PathShadowPainter extends CustomPainter {
  const _PathShadowPainter(this.path);

  final Path path;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      path.shift(const Offset(0, 10)),
      Paint()
        ..color = const Color(0x47000000)
        // CSS blur radius 22 ≈ a Gaussian sigma of half that.
        ..maskFilter = const MaskFilter.blur(ui.BlurStyle.normal, 11),
    );
  }

  @override
  bool shouldRepaint(_PathShadowPainter oldDelegate) =>
      oldDelegate.path != path;
}

class _CollageCaption extends StatelessWidget {
  const _CollageCaption({
    required this.t,
    required this.at,
    required this.note,
  });

  final double t;
  final double at;
  final String note;

  @override
  Widget build(BuildContext context) {
    final noteRise = rise(t, at + 1.0, 1.25, lift: 28);
    if (noteRise.opacity <= 0.002) return const SizedBox.shrink();
    return Positioned(
      left: 108,
      right: 108,
      bottom: 250,
      child: Transform.translate(
        offset: Offset(0, noteRise.translateY),
        child: Opacity(
          opacity: noteRise.opacity.clamp(0.0, 1.0),
          child: Text(
            note,
            key: const Key('collage-caption'),
            textAlign: TextAlign.center,
            style:
                WrapUpFilmText.serif(
                  size: 50,
                  height: 1.5,
                  italic: true,
                  color: WrapUpFilmColors.ink,
                ).copyWith(
                  shadows: const [
                    Shadow(
                      offset: Offset(0, 2),
                      blurRadius: 18,
                      color: Color(0x80000000),
                    ),
                  ],
                ),
          ),
        ),
      ),
    );
  }
}

import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../wrap_up_film_tokens.dart';

/// The reusable Moment print — a Polaroid-shaped card with a real white
/// border that lands face-down, holds, then turns over to reveal the photo
/// (docs/design/WRAP_UP_FILM_FLUTTER_SPEC.md § Moments — "the print" and "the flip").
///
/// [flip] runs 0 (back) → 1 (front). Flutter has no CSS `backface-visibility`,
/// so rather than stacking both faces we render whichever face is toward the
/// camera and rotate it by the same angle either side of the crossover — at
/// `flip == 0.5` both faces are edge-on (invisible), so the swap is seamless.
class WrapUpFilmPlate extends StatelessWidget {
  const WrapUpFilmPlate({
    required this.cx,
    required this.cy,
    required this.scale,
    required this.rotationDeg,
    required this.opacity,
    required this.lift,
    required this.flip,
    required this.imageUrl,
    super.key,
  });

  static const double width = 720;
  static const double photoHeight = 860;
  static const double height = 11 + photoHeight + 96;

  final double cx;
  final double cy;
  final double scale;
  final double rotationDeg;
  final double opacity;
  final double lift;
  final double flip;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final clampedOpacity = opacity.clamp(0.0, 1.0);
    if (clampedOpacity <= 0.004) return const SizedBox.shrink();

    final flipClamped = flip.clamp(0.0, 1.0);
    final angle = math.pi * (1 - flipClamped);
    final isFront = flip >= 0.5;

    return Positioned(
      left: cx - width / 2,
      top: cy - height / 2,
      width: width,
      height: height,
      child: RepaintBoundary(
        child: Opacity(
          opacity: clampedOpacity,
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..scaleByDouble(scale, scale, scale, 1)
              ..rotateZ(rotationDeg * math.pi / 180),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    offset: Offset(0, 30 * lift),
                    blurRadius: 64 * lift,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, -1 / 2200)
                    ..rotateY(angle),
                  child: isFront
                      ? _PlateFront(imageUrl: imageUrl)
                      : const _PlateBack(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlateFront extends StatelessWidget {
  const _PlateFront({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: WrapUpFilmPlate.width,
      padding: const EdgeInsets.fromLTRB(11, 11, 11, 96),
      color: WrapUpFilmColors.ink,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: SizedBox(
          height: WrapUpFilmPlate.photoHeight,
          child: imageUrl == null
              ? const ColoredBox(color: Color(0xFFD9D3C4))
              : CachedNetworkImage(
                  imageUrl: imageUrl!,
                  fit: BoxFit.cover,
                  // Precaching (see WrapUpPage) usually has the photo decoded
                  // before the print flips face-up, but on a slow device or
                  // network it can still lag — the flip itself already
                  // carries the suspense, so a short fade here just makes a
                  // late arrival look intentional instead of a hard pop-in.
                  fadeInDuration: const Duration(milliseconds: 220),
                  fadeOutDuration: Duration.zero,
                  placeholder: (context, url) =>
                      const ColoredBox(color: Color(0xFFD9D3C4)),
                  errorWidget: (context, url, error) =>
                      const ColoredBox(color: Color(0xFFD9D3C4)),
                ),
        ),
      ),
    );
  }
}

class _PlateBack extends StatelessWidget {
  const _PlateBack();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: WrapUpFilmPlate.width,
      height: WrapUpFilmPlate.height,
      padding: const EdgeInsets.fromLTRB(11, 11, 11, 96),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF4F1E8), Color(0xFFE4DFD2), Color(0xFFD9D3C4)],
          stops: [0.0, 0.62, 1.0],
        ),
      ),
    );
  }
}

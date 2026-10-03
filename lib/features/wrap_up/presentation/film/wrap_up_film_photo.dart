import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// A photo inside the film — the Moment print, collage tiles and Flurry
/// small prints all render through this, and the page precaches with the
/// same [providerFor], so a precached photo is always the exact cache entry
/// the frame looks up (#178).
///
/// An image already in the cache paints in the same frame it's built — no
/// placeholder, no fade — which is what lets a print flip face-up straight
/// onto its photo. Only a genuinely late image shows [placeholderColor]
/// and fades in.
class WrapUpFilmPhoto extends StatelessWidget {
  const WrapUpFilmPhoto({
    required this.imageUrl,
    required this.placeholderColor,
    this.fadeInDuration = const Duration(milliseconds: 220),
    super.key,
  });

  final String imageUrl;
  final Color placeholderColor;
  final Duration fadeInDuration;

  /// Bounds the decode to what the film can show. Uploads are up to 2048px
  /// (PhotoCompressor), ~12.6 MB each decoded — a handful of those filled
  /// Flutter's 100 MB image cache and evicted earlier precaches before
  /// playback reached them, so the print flipped onto a re-decode (the
  /// white flash, #178). Fit within 1200×1200 (~4.3 MB) still covers the
  /// largest frame — the 698×860 print at its ~1.04 swell — at the 1080×1920
  /// canvas's ≈1:1 device scale, in either orientation.
  static ImageProvider providerFor(String url) => ResizeImage(
    CachedNetworkImageProvider(url),
    width: _maxDecodeDimension,
    height: _maxDecodeDimension,
    policy: ResizeImagePolicy.fit,
  );

  static const _maxDecodeDimension = 1200;

  @override
  Widget build(BuildContext context) {
    final placeholder = ColoredBox(color: placeholderColor);
    return Image(
      image: providerFor(imageUrl),
      fit: BoxFit.cover,
      gaplessPlayback: true,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return Stack(
          fit: StackFit.passthrough,
          children: [
            Positioned.fill(child: placeholder),
            AnimatedOpacity(
              opacity: frame == null ? 0 : 1,
              duration: fadeInDuration,
              child: child,
            ),
          ],
        );
      },
      errorBuilder: (context, error, stackTrace) => placeholder,
    );
  }
}

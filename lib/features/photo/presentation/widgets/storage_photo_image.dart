import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// A `trip-photos` image, cached on-device by its storage path (#179).
///
/// The bucket is private, so photos arrive as signed URLs — and every
/// signing mints a new token, so the URL changes on each Journal visit.
/// Keyed by URL (as `Image.network` was), nothing ever hit the cache and
/// every visit re-downloaded every photo. The storage path is immutable
/// (`{user}/{trip}/{photoId}.jpg`), so it keys both the disk cache and the
/// in-memory image cache instead; the URL is only used to fetch on a miss.
class StoragePhotoImage extends StatelessWidget {
  const StoragePhotoImage({
    required this.url,
    required this.storagePath,
    this.fit = BoxFit.cover,
    this.decodeSize,
    this.width,
    this.height,
    this.gaplessPlayback = false,
    super.key,
  });

  final String url;
  final String storagePath;
  final BoxFit fit;
  final double? width;
  final double? height;
  final bool gaplessPlayback;

  /// The logical size this image is shown at, for thumbnails. Uploads are
  /// up to 2048px (~12.6 MB decoded) — a strip of those crowds Flutter's
  /// 100 MB image cache and evicts photos the user just looked at. Null
  /// decodes at full size (the photo viewer).
  final Size? decodeSize;

  static ImageProvider providerFor({
    required String url,
    required String storagePath,
    int? maxDecodeDimension,
  }) {
    final provider = CachedNetworkImageProvider(url, cacheKey: storagePath);
    if (maxDecodeDimension == null) return provider;
    return ResizeImage(
      provider,
      width: maxDecodeDimension,
      height: maxDecodeDimension,
      policy: ResizeImagePolicy.fit,
    );
  }

  /// Fit-within-a-square sizing that still fills [size] under
  /// [BoxFit.cover] for photos up to 2:1 either way — twice the larger
  /// side, in physical pixels.
  static int maxDecodeDimensionFor(Size size, double devicePixelRatio) =>
      (2 * math.max(size.width, size.height) * devicePixelRatio).round();

  @override
  Widget build(BuildContext context) {
    final decode = decodeSize;
    const placeholder = ColoredBox(color: AppColors.surface);
    return Image(
      image: providerFor(
        url: url,
        storagePath: storagePath,
        maxDecodeDimension: decode == null
            ? null
            : maxDecodeDimensionFor(
                decode,
                MediaQuery.devicePixelRatioOf(context),
              ),
      ),
      fit: fit,
      width: width,
      height: height,
      gaplessPlayback: gaplessPlayback,
      // Already decoded (a revisit) paints in the first frame; only a
      // genuine first load shows the placeholder and fades in.
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return Stack(
          fit: StackFit.passthrough,
          children: [
            const Positioned.fill(child: placeholder),
            AnimatedOpacity(
              opacity: frame == null ? 0 : 1,
              duration: const Duration(milliseconds: 180),
              child: child,
            ),
          ],
        );
      },
      errorBuilder: (context, error, stackTrace) => placeholder,
    );
  }
}

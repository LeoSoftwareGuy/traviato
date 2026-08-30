import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/cover_image_url_provider.dart';
import 'cover_options.dart';

/// A trip's cover photo — a bundled cover-picker asset (`asset:<id>`), a
/// custom upload's storage path (signed for display since `trip-photos` is
/// a private bucket), or a themed placeholder when neither is set yet.
class TripCoverImage extends ConsumerWidget {
  const TripCoverImage({this.imagePath, super.key});

  final String? imagePath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = imagePath;
    if (path == null || path.isEmpty) return const _CoverPlaceholder();

    final assetPath = resolveAssetCoverPath(path);
    if (assetPath != null) {
      return Image.asset(assetPath, fit: BoxFit.cover);
    }

    final signedUrl = ref.watch(coverImageUrlProvider(path));
    return signedUrl.when(
      loading: () => const ColoredBox(color: AppColors.surface),
      error: (_, _) => const _BrokenCover(),
      data: (url) => CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        placeholder: (context, url) =>
            const ColoredBox(color: AppColors.surface),
        errorWidget: (context, url, error) => const _BrokenCover(),
      ),
    );
  }
}

class _BrokenCover extends StatelessWidget {
  const _BrokenCover();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(color: AppColors.surface),
      child: Icon(Icons.broken_image_outlined, color: AppColors.textTertiary),
    );
  }
}

class _CoverPlaceholder extends StatelessWidget {
  const _CoverPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surface, AppColors.background],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.photo_outlined,
          color: AppColors.textTertiary,
          size: 32,
        ),
      ),
    );
  }
}

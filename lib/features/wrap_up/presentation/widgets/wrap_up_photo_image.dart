import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// A single wrap-up photo, resolved to its signed URL by the controller
/// (`WrapUpState.imageUrlForPhoto`). Falls back to a plain surface tile when
/// the photo couldn't be resolved, rather than failing the whole block.
class WrapUpPhotoImage extends StatelessWidget {
  const WrapUpPhotoImage({this.imageUrl, super.key});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    if (url == null) {
      return const ColoredBox(color: AppColors.surface);
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.high,
      placeholder: (context, url) => const ColoredBox(color: AppColors.surface),
      errorWidget: (context, url, error) =>
          const ColoredBox(color: AppColors.surface),
    );
  }
}

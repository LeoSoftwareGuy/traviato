import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// A trip's cover photo, or a themed placeholder when none has been
/// uploaded yet (photo upload lands in a later milestone).
class TripCoverImage extends StatelessWidget {
  const TripCoverImage({this.imagePath, super.key});

  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    final path = imagePath;
    if (path == null || path.isEmpty) {
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
    return CachedNetworkImage(
      imageUrl: path,
      fit: BoxFit.cover,
      placeholder: (context, url) => const ColoredBox(color: AppColors.surface),
      errorWidget: (context, url, error) => const DecoratedBox(
        decoration: BoxDecoration(color: AppColors.surface),
        child: Icon(Icons.broken_image_outlined, color: AppColors.textTertiary),
      ),
    );
  }
}

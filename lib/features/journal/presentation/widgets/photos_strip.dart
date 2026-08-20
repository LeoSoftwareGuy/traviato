import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../photo/domain/entities/photo_entity.dart';

/// "Photos" section: count + a wrap of thumbnails, plus an "Add" tile.
/// Photo capture is a separate issue, so Add is a stub — it doesn't route
/// anywhere yet.
class PhotosStrip extends StatelessWidget {
  const PhotosStrip({
    required this.photos,
    required this.onAddTap,
    super.key,
  });

  final List<PhotoEntity> photos;
  final VoidCallback onAddTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.photo_library_outlined,
              size: 16,
              color: AppColors.textPrimary,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'Photos',
              style: AppTypography.bodyInput.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              '${photos.length} saved',
              style: AppTypography.caption.copyWith(letterSpacing: 0),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final photo in photos) _PhotoTile(photo: photo),
            _AddPhotoTile(onTap: onAddTap),
          ],
        ),
      ],
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.photo});

  final PhotoEntity photo;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 106,
        height: 106,
        child: photo.imageUrl != null
            ? Image.network(photo.imageUrl!, fit: BoxFit.cover)
            : const ColoredBox(color: AppColors.surface),
      ),
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: const Key('journal-add-photo'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 106,
        height: 106,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surfaceDisabled,
          border: Border.all(
            color: AppColors.surfaceBorder,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.add_a_photo_outlined,
              size: 20,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Add',
              style: AppTypography.caption.copyWith(letterSpacing: 0),
            ),
          ],
        ),
      ),
    );
  }
}

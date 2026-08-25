import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/dashed_rrect_border.dart';
import '../../../photo/domain/entities/photo_entity.dart';

const _photoTileWidth = 88.0;
const _photoTileHeight = 110.0;

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
      borderRadius: AppRadius.cardRadius,
      child: SizedBox(
        width: _photoTileWidth,
        height: _photoTileHeight,
        child: photo.imageUrl != null
            ? Image.network(photo.imageUrl!, fit: BoxFit.cover)
            : const ColoredBox(color: AppColors.surface),
      ),
    );
  }
}

/// "Add ✦2" tile — dashed primary border, primary-tinted fill
/// (`docs/design/README.md` § 7). Photo = 2 stars canonically
/// (`docs/data-model.md`); the handoff's "Add ✦1" copy is one of the
/// mockup's non-canonical star values.
class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: const Key('journal-add-photo'),
      onTap: onTap,
      borderRadius: AppRadius.cardRadius,
      child: DashedRRectBorder(
        color: AppColors.tint(AppColors.primary, .5),
        borderRadius: AppRadius.cardRadius,
        child: Container(
          width: _photoTileWidth,
          height: _photoTileHeight,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.tint(AppColors.primary, .08),
            borderRadius: AppRadius.cardRadius,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add, size: 20, color: AppColors.primary),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Add ✦2',
                style: AppTypography.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/dashed_rrect_border.dart';
import '../../../photo/domain/entities/photo_entity.dart';

const _photoTileWidth = 80.0;
const _photoTileHeight = 100.0;
const _photoTileGap = 10.0;
const _photoTileRadius = AppRadius.badgeRadius;

final _takenAtFormat = DateFormat('h:mm a');

/// "Photos" section: count + one horizontally scrolling row of thumbnails,
/// led by the "Add" tile. Tiles keep a fixed 80×100 size (never squeezed)
/// and snap to the row's leading edge (#149). Tapping a thumbnail opens the
/// day-scoped swipeable viewer at that photo's index.
class PhotosStrip extends StatelessWidget {
  const PhotosStrip({
    required this.photos,
    required this.onAddTap,
    required this.onPhotoTap,
    super.key,
  });

  final List<PhotoEntity> photos;
  final VoidCallback onAddTap;
  final ValueChanged<int> onPhotoTap;

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
        SizedBox(
          height: _photoTileHeight,
          child: ListView.separated(
            key: const Key('journal-photo-strip'),
            scrollDirection: Axis.horizontal,
            physics: const _SnapToTilePhysics(
              extent: _photoTileWidth + _photoTileGap,
            ),
            itemCount: photos.length + 1,
            separatorBuilder: (_, _) => const SizedBox(width: _photoTileGap),
            itemBuilder: (context, index) {
              if (index == 0) return _AddPhotoTile(onTap: onAddTap);
              final photoIndex = index - 1;
              return _PhotoTile(
                photo: photos[photoIndex],
                onTap: () => onPhotoTap(photoIndex),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Settles a scroll so a tile's leading edge lines up with the row's start
/// — the Flutter equivalent of CSS `snap-x snap-mandatory` + `snap-start`.
/// Same ballistic logic as `PageScrollPhysics`, stepping one tile
/// ([extent] = tile width + gap) instead of one viewport.
class _SnapToTilePhysics extends ScrollPhysics {
  const _SnapToTilePhysics({required this.extent, super.parent});

  final double extent;

  @override
  _SnapToTilePhysics applyTo(ScrollPhysics? ancestor) =>
      _SnapToTilePhysics(extent: extent, parent: buildParent(ancestor));

  double _targetPixels(
    ScrollMetrics position,
    Tolerance tolerance,
    double velocity,
  ) {
    var tile = position.pixels / extent;
    if (velocity < -tolerance.velocity) {
      tile -= .5;
    } else if (velocity > tolerance.velocity) {
      tile += .5;
    }
    return (tile.roundToDouble() * extent).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    if ((velocity <= 0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }
    final tolerance = toleranceFor(position);
    final target = _targetPixels(position, tolerance, velocity);
    if (target == position.pixels) return null;
    return ScrollSpringSimulation(
      spring,
      position.pixels,
      target,
      velocity,
      tolerance: tolerance,
    );
  }

  @override
  bool get allowImplicitScrolling => false;
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.photo, required this.onTap});

  final PhotoEntity photo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final takenAt = photo.takenAt;
    return GestureDetector(
      key: Key('journal-photo-tile-${photo.id}'),
      onTap: onTap,
      child: ClipRRect(
        borderRadius: _photoTileRadius,
        child: SizedBox(
          width: _photoTileWidth,
          height: _photoTileHeight,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (photo.imageUrl != null)
                Image.network(photo.imageUrl!, fit: BoxFit.cover)
              else
                const ColoredBox(color: AppColors.surface),
              if (takenAt != null)
                Positioned(
                  left: 6,
                  right: 6,
                  bottom: 6,
                  child: Center(child: _TimePill(takenAt: takenAt)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Frosted time label over the bottom of a thumbnail — only rendered when
/// the photo has a `takenAt` (#149).
class _TimePill extends StatelessWidget {
  const _TimePill({required this.takenAt});

  final DateTime takenAt;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(AppSpacing.xs)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: ColoredBox(
          color: AppColors.tint(AppColors.background50, .7),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            child: Text(
              _takenAtFormat.format(takenAt),
              key: const Key('journal-photo-time-pill'),
              maxLines: 1,
              style: AppTypography.caption.copyWith(
                fontSize: 9,
                height: 1.2,
                letterSpacing: 0,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "Add ✦2" tile — dashed primary border, primary-tinted fill
/// (`docs/design/README.md` § 7), first in the row. Photo = 2 stars
/// canonically (`docs/data-model.md`); the handoff's "Add ✦1" copy is one
/// of the mockup's non-canonical star values.
class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: const Key('journal-add-photo'),
      onTap: onTap,
      borderRadius: _photoTileRadius,
      child: DashedRRectBorder(
        color: AppColors.tint(AppColors.primary, .7),
        borderRadius: _photoTileRadius,
        child: Container(
          width: _photoTileWidth,
          height: _photoTileHeight,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.tint(AppColors.primary, .08),
            borderRadius: _photoTileRadius,
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

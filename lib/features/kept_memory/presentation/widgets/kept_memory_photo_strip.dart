import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../photo/presentation/widgets/storage_photo_image.dart';
import '../../domain/entities/kept_memory_photo.dart';

/// Thumbnail widths cycle through this for rhythm (spec § 3.3).
const _itemWidths = [200.0, 124.0, 124.0, 168.0, 124.0, 200.0];
const _gap = 5.0;
const _sidePadding = 22.0;
const _stripHeight = 168.0;

/// The strip width for the item at [index].
double keptMemoryStripItemWidth(int index) =>
    _itemWidths[index % _itemWidths.length];

/// A day's photos as a horizontal strip that snaps to item edges (#279).
/// Thumbs decode at strip size; the viewer loads full images.
class KeptMemoryPhotoStrip extends StatelessWidget {
  const KeptMemoryPhotoStrip({
    required this.photos,
    required this.onPhotoTap,
    super.key,
  });

  final List<KeptMemoryPhoto> photos;

  /// Called with the index within [photos].
  final ValueChanged<int> onPhotoTap;

  @override
  Widget build(BuildContext context) {
    final snapOffsets = <double>[];
    var offset = 0.0;
    for (var i = 0; i < photos.length; i++) {
      snapOffsets.add(offset);
      offset += keptMemoryStripItemWidth(i) + _gap;
    }
    return SizedBox(
      height: _stripHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: _sidePadding),
        physics: _SnapToItemPhysics(snapOffsets: snapOffsets),
        itemCount: photos.length,
        separatorBuilder: (_, _) => const SizedBox(width: _gap),
        itemBuilder: (context, index) => _StripThumb(
          photo: photos[index],
          width: keptMemoryStripItemWidth(index),
          onTap: () => onPhotoTap(index),
        ),
      ),
    );
  }
}

class _StripThumb extends StatelessWidget {
  const _StripThumb({
    required this.photo,
    required this.width,
    required this.onTap,
  });

  final KeptMemoryPhoto photo;
  final double width;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final url = photo.photo.imageUrl;
    return GestureDetector(
      key: ValueKey('kept-memory-thumb-${photo.photo.id}'),
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: width,
          height: _stripHeight,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (url == null)
                const ColoredBox(color: AppColors.surface)
              else
                StoragePhotoImage(
                  url: url,
                  storagePath: photo.photo.storagePath,
                  decodeSize: Size(width, _stripHeight),
                ),
              if (photo.bonusTask != null)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.tint(AppColors.background, .72),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '✦',
                      style: AppTypography.mono.copyWith(
                        fontSize: 10,
                        letterSpacing: 0,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Settles a fling on the nearest item's leading edge. The strip's items
/// differ in width, so [PageScrollPhysics] can't do it.
class _SnapToItemPhysics extends ScrollPhysics {
  const _SnapToItemPhysics({required this.snapOffsets, super.parent});

  final List<double> snapOffsets;

  @override
  _SnapToItemPhysics applyTo(ScrollPhysics? ancestor) => _SnapToItemPhysics(
    snapOffsets: snapOffsets,
    parent: buildParent(ancestor),
  );

  double _target(ScrollMetrics position, double velocity) {
    // Where the fling would coast to, then the nearest edge to that.
    final projected = position.pixels + velocity * .25;
    var best = position.maxScrollExtent;
    var bestDistance = (projected - best).abs();
    for (final offset in snapOffsets) {
      final candidate = offset.clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      );
      final distance = (projected - candidate).abs();
      if (distance < bestDistance) {
        best = candidate;
        bestDistance = distance;
      }
    }
    return best;
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
    final target = _target(position, velocity);
    if ((target - position.pixels).abs() < toleranceFor(position).distance) {
      return null;
    }
    return ScrollSpringSimulation(
      spring,
      position.pixels,
      target,
      velocity,
      tolerance: toleranceFor(position),
    );
  }

  @override
  bool get allowImplicitScrolling => false;
}

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/l10n/context_l10n.dart';
import '../../../../core/l10n/l10n_dates.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/dashed_rrect_border.dart';
import '../../../photo/domain/entities/film_pick.dart';
import '../../../photo/domain/entities/photo_entity.dart';
import '../../../photo/presentation/widgets/storage_photo_image.dart';

const _photoTileWidth = 80.0;
const _photoTileHeight = 100.0;
const _photoTileGap = 10.0;
const _photoTileRadius = AppRadius.badgeRadius;

/// "Photos" section: count + one horizontally scrolling row of thumbnails,
/// led by the "Add" tile. Tiles keep a fixed 80×100 size (never squeezed)
/// and snap to the row's leading edge (#149). Tapping a thumbnail opens the
/// day-scoped swipeable viewer at that photo's index. [photos] come oldest
/// first (#291); when one is added the row scrolls to bring it into view.
/// Key the strip by day so switching days doesn't read as an addition.
///
/// Film markers (#294): "▸ N IN THE FILM" in the header, and a badge on
/// each thumb the film uses — Always, or on Auto and in [filmMomentIds].
class PhotosStrip extends StatefulWidget {
  const PhotosStrip({
    required this.photos,
    required this.onAddTap,
    required this.onPhotoTap,
    this.filmMomentIds = const {},
    super.key,
  });

  final List<PhotoEntity> photos;
  final VoidCallback onAddTap;
  final ValueChanged<int> onPhotoTap;

  /// Photos the film currently gives a main moment to.
  final Set<String> filmMomentIds;

  @override
  State<PhotosStrip> createState() => _PhotosStripState();
}

class _PhotosStripState extends State<PhotosStrip> {
  final _scrollController = ScrollController();

  @override
  void didUpdateWidget(PhotosStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldIds = {for (final p in oldWidget.photos) p.id};
    final addedIndex = widget.photos.indexWhere((p) => !oldIds.contains(p.id));
    if (addedIndex == -1) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final position = _scrollController.position;
      // +1 for the leading Add tile.
      final target = ((addedIndex + 1) * (_photoTileWidth + _photoTileGap))
          .clamp(position.minScrollExtent, position.maxScrollExtent);
      _scrollController.animateTo(
        target,
        duration: AppMotion.progressDuration,
        curve: AppMotion.progressCurve,
      );
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photos = widget.photos;
    final inFilmCount = photos.where(_isInFilm).length;
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
              context.l10n.journal_photos,
              style: AppTypography.bodyInput.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Right-aligned, and the one part that gives way on a narrow
            // screen (RU at 360pt) rather than overflowing the header.
            Expanded(
              child: inFilmCount == 0
                  ? const SizedBox.shrink()
                  : Text(
                      '▸ ${context.l10n.film_stripCount(inFilmCount)}'
                          .toUpperCase(),
                      key: const Key('journal-photo-strip-film-count'),
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.mono.copyWith(
                        color: AppColors.primaryLight,
                      ),
                    ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              context.l10n.journal_photosSaved(photos.length),
              style: AppTypography.caption.copyWith(letterSpacing: 0),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: _photoTileHeight,
          child: ListView.separated(
            key: const Key('journal-photo-strip'),
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            physics: const _SnapToTilePhysics(
              extent: _photoTileWidth + _photoTileGap,
            ),
            itemCount: photos.length + 1,
            separatorBuilder: (_, _) => const SizedBox(width: _photoTileGap),
            itemBuilder: (context, index) {
              if (index == 0) return _AddPhotoTile(onTap: widget.onAddTap);
              final photoIndex = index - 1;
              final photo = photos[photoIndex];
              return _PhotoTile(
                photo: photo,
                isAutoPicked: widget.filmMomentIds.contains(photo.id),
                onTap: () => widget.onPhotoTap(photoIndex),
              );
            },
          ),
        ),
      ],
    );
  }

  bool _isInFilm(PhotoEntity photo) => switch (photo.filmPick) {
    FilmPick.always => true,
    FilmPick.auto => widget.filmMomentIds.contains(photo.id),
    FilmPick.never => false,
  };
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
  const _PhotoTile({
    required this.photo,
    required this.isAutoPicked,
    required this.onTap,
  });

  final PhotoEntity photo;

  /// The film gives this photo a main moment while it's on Auto.
  final bool isAutoPicked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final takenAt = photo.takenAt;
    final pick = photo.filmPick;
    final badge = switch (pick) {
      FilmPick.always => const _FilmBadge.yourPick(),
      FilmPick.never => const _FilmBadge.leftOut(),
      FilmPick.auto when isAutoPicked => const _FilmBadge.autoPicked(),
      FilmPick.auto => null,
    };
    return GestureDetector(
      key: Key('journal-photo-tile-${photo.id}'),
      onTap: onTap,
      child: Opacity(
        opacity: pick == FilmPick.never ? .45 : 1,
        child: Container(
          foregroundDecoration: pick == FilmPick.always
              ? BoxDecoration(
                  borderRadius: _photoTileRadius,
                  border: Border.all(color: AppColors.primary, width: 1.5),
                )
              : null,
          child: ClipRRect(
            borderRadius: _photoTileRadius,
            child: SizedBox(
              width: _photoTileWidth,
              height: _photoTileHeight,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (photo.imageUrl != null)
                    StoragePhotoImage(
                      url: photo.imageUrl!,
                      storagePath: photo.storagePath,
                      decodeSize: const Size(
                        _photoTileWidth,
                        _photoTileHeight,
                      ),
                    )
                  else
                    const ColoredBox(color: AppColors.surface),
                  if (badge != null) Positioned(top: 7, left: 7, child: badge),
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
        ),
      ),
    );
  }
}

enum _FilmBadgeKind { autoPicked, yourPick, leftOut }

/// A thumb's film marker (#294): "▸" when the film chose it, "▸ Your pick"
/// for Always, "Left out" for Leave out.
class _FilmBadge extends StatelessWidget {
  const _FilmBadge.autoPicked() : _kind = _FilmBadgeKind.autoPicked;
  const _FilmBadge.yourPick() : _kind = _FilmBadgeKind.yourPick;
  const _FilmBadge.leftOut() : _kind = _FilmBadgeKind.leftOut;

  final _FilmBadgeKind _kind;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (label, foreground, background, border) = switch (_kind) {
      _FilmBadgeKind.autoPicked => (
        '▸',
        AppColors.primaryLight,
        AppColors.tint(AppColors.filmBackground, .6),
        AppColors.tint(AppColors.primary, .45),
      ),
      _FilmBadgeKind.yourPick => (
        '▸ ${l10n.film_badgeYourPick}',
        AppColors.background,
        AppColors.primary,
        AppColors.primary,
      ),
      _FilmBadgeKind.leftOut => (
        l10n.film_badgeLeftOut,
        AppColors.textSecondary,
        AppColors.tint(AppColors.filmBackground, .7),
        AppColors.tint(AppColors.textSecondary, .3),
      ),
    };
    return Container(
      key: Key('journal-photo-film-badge-${_kind.name}'),
      constraints: const BoxConstraints(
        maxWidth: _photoTileWidth - 14,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.caption.copyWith(
          fontSize: 9,
          height: 1.2,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          color: foreground,
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
              L10nDates.time(context.l10n.localeName).format(takenAt),
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
                context.l10n.journal_addPhotoTile,
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

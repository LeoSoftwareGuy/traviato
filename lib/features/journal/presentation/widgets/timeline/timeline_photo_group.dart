import 'package:flutter/material.dart';

import '../../../../../core/l10n/context_l10n.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_motion.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../photo/domain/entities/film_pick.dart';
import '../../../../photo/domain/entities/photo_entity.dart';
import '../../../../photo/presentation/widgets/storage_photo_image.dart';
import '../photo_tile_badges.dart';

const _gap = 6.0;
const _radius = BorderRadius.all(Radius.circular(12));
const _singleMaxWidth = 236.0;
const _singleHeight = 196.0;
const _pairHeight = 150.0;
const _gridHeight = 112.0;
const _gridVisible = 3;

/// A row of photos on the day timeline (#401, docs/design/journal-notes/
/// §4): one photo up to 236×196, two at 150 high, three or more at 112
/// with "+N" on the third. Tapping "+N" shows the whole group, three to a
/// line, and "less" folds it again. Each tile in a group has its own time
/// pill; a caption sits under its tile (2 lines). A photo with notes on it
/// gets a ✎ badge.
class TimelinePhotoGroup extends StatefulWidget {
  const TimelinePhotoGroup({
    required this.photos,
    required this.use24h,
    required this.onPhotoTap,
    this.notedPhotoIds = const {},
    this.filmMomentIds = const {},
    super.key,
  });

  final List<PhotoEntity> photos;
  final bool use24h;
  final ValueChanged<PhotoEntity> onPhotoTap;

  /// Photos that have at least one note written on them.
  final Set<String> notedPhotoIds;

  /// Photos the film gives a main moment to on Auto (#294).
  final Set<String> filmMomentIds;

  @override
  State<TimelinePhotoGroup> createState() => _TimelinePhotoRowState();
}

class _TimelinePhotoRowState extends State<TimelinePhotoGroup> {
  var _expanded = false;

  Widget _tile(PhotoEntity photo, double height, {String? overlay}) =>
      _PhotoTile(
        photo: photo,
        height: height,
        showTime: widget.photos.length > 1,
        use24h: widget.use24h,
        hasNotes: widget.notedPhotoIds.contains(photo.id),
        isAutoPicked: widget.filmMomentIds.contains(photo.id),
        overlay: overlay,
        onTap: overlay == null
            ? () => widget.onPhotoTap(photo)
            : () => setState(() => _expanded = true),
      );

  @override
  Widget build(BuildContext context) {
    final photos = widget.photos;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final Widget content;
    if (photos.length == 1) {
      content = ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _singleMaxWidth),
        child: _tile(photos.single, _singleHeight),
      );
    } else if (photos.length == 2) {
      content = _line([
        for (final p in photos) _tile(p, _pairHeight),
      ]);
    } else if (!_expanded) {
      final hidden = photos.length - _gridVisible;
      content = _line([
        for (var i = 0; i < _gridVisible; i++)
          _tile(
            photos[i],
            _gridHeight,
            overlay: i == _gridVisible - 1 && hidden > 0 ? '+$hidden' : null,
          ),
      ]);
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < photos.length; i += _gridVisible) ...[
            if (i > 0) const SizedBox(height: _gap),
            _line([
              for (var j = i; j < i + _gridVisible; j++)
                j < photos.length
                    ? _tile(photos[j], _gridHeight)
                    : const SizedBox.shrink(),
            ]),
          ],
          GestureDetector(
            key: const Key('timeline-photos-less'),
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _expanded = false),
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                context.l10n.timeline_less,
                style: AppTypography.timelineLink,
              ),
            ),
          ),
        ],
      );
    }
    return AnimatedSize(
      duration: reducedMotion
          ? Duration.zero
          : const Duration(milliseconds: 380),
      curve: AppMotion.progressCurve,
      alignment: Alignment.topLeft,
      child: content,
    );
  }

  Widget _line(List<Widget> tiles) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (var i = 0; i < tiles.length; i++) ...[
        if (i > 0) const SizedBox(width: _gap),
        Expanded(child: tiles[i]),
      ],
    ],
  );
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.photo,
    required this.height,
    required this.showTime,
    required this.use24h,
    required this.hasNotes,
    required this.isAutoPicked,
    required this.onTap,
    this.overlay,
  });

  final PhotoEntity photo;
  final double height;
  final bool showTime;
  final bool use24h;
  final bool hasNotes;
  final bool isAutoPicked;
  final VoidCallback onTap;

  /// "+N" over the last visible tile of a folded group.
  final String? overlay;

  @override
  Widget build(BuildContext context) {
    final caption = photo.caption?.trim();
    final pick = photo.filmPick;
    final badge = switch (pick) {
      FilmPick.always => const FilmBadge.yourPick(),
      FilmPick.never => const FilmBadge.leftOut(),
      FilmPick.auto when isAutoPicked => const FilmBadge.autoPicked(),
      FilmPick.auto => null,
    };
    return GestureDetector(
      key: Key(
        overlay == null ? 'timeline-photo-${photo.id}' : 'timeline-photos-more',
      ),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: _radius,
            child: SizedBox(
              height: height,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Opacity(
                    opacity: pick == FilmPick.never ? .45 : 1,
                    child: photo.imageUrl == null
                        ? const ColoredBox(color: AppColors.surface)
                        : StoragePhotoImage(
                            url: photo.imageUrl!,
                            storagePath: photo.storagePath,
                            decodeSize: Size(_singleMaxWidth, height),
                          ),
                  ),
                  if (badge != null && overlay == null)
                    Positioned(bottom: 7, left: 7, child: badge),
                  if (showTime && overlay == null)
                    Positioned(
                      top: 7,
                      left: 7,
                      child: PhotoTimePill(
                        takenAt: photo.takenAt ?? photo.createdAt,
                        use24h: use24h,
                      ),
                    ),
                  if (hasNotes && overlay == null)
                    const Positioned(top: 7, right: 7, child: _NotedBadge()),
                  if (overlay != null)
                    ColoredBox(
                      color: AppColors.scrim,
                      child: Center(
                        child: Text(
                          overlay!,
                          style: AppTypography.bigNumber.copyWith(
                            fontSize: 22,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (caption != null && caption.isNotEmpty && overlay == null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                caption,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.timelineCaption,
              ),
            ),
        ],
      ),
    );
  }
}

/// ✎ on a photo that has notes (spec §10.3: 20px, top/right 7).
class _NotedBadge extends StatelessWidget {
  const _NotedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('timeline-photo-noted'),
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.scrim,
        shape: BoxShape.circle,
      ),
      child: Text(
        '✎',
        style: AppTypography.timelineLink.copyWith(
          fontSize: 11,
          color: AppColors.primaryLight,
        ),
      ),
    );
  }
}

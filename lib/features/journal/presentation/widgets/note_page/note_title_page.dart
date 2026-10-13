import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../photo/domain/entities/photo_entity.dart';
import '../../../../photo/presentation/widgets/storage_photo_image.dart';
import 'hand_drawn_balloon.dart';
import 'note_page_chrome.dart';

const _polaroidWidth = 150.0;
const _polaroidHeight = 172.0;
const _polaroidPadding = EdgeInsets.fromLTRB(8, 8, 8, 30);

/// Inner photo size of the polaroid — also what the Journal precaches
/// before pushing the note page.
const notePolaroidPhotoSize = Size(
  _polaroidWidth - 16,
  _polaroidHeight - 38,
);

/// Front face of the turning page: the day's title page — stamp, title,
/// a polaroid of the day's first photo, a meta line, and the hand-drawn
/// balloons (docs/design/JOURNAL_NOTE_PAGETURN_SPEC.md §3).
class NoteTitlePage extends StatelessWidget {
  const NoteTitlePage({
    required this.stamp,
    required this.title,
    required this.meta,
    this.photo,
    super.key,
  });

  final String stamp;
  final String title;
  final String meta;
  final PhotoEntity? photo;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const Key('note-title-page'),
      decoration: const BoxDecoration(
        color: AppColors.paper,
        borderRadius: notePageRadius,
      ),
      child: ClipRRect(
        borderRadius: notePageRadius,
        child: Stack(
          children: [
            // Trail runs from the small balloon up to the large one; the
            // spec gives no position for it or the cloud.
            const Positioned(
              top: 74,
              left: 86,
              child: JournalDoodle(
                asset: JournalDoodleAssets.flightTrail,
                width: 190,
              ),
            ),
            const Positioned(
              top: 168,
              right: 30,
              child: JournalDoodle(asset: JournalDoodleAssets.cloud, width: 46),
            ),
            const Positioned(
              top: 46,
              right: 34,
              child: HandDrawnBalloon(
                asset: JournalDoodleAssets.balloonLarge,
                width: 70,
                rotationDegrees: 7,
              ),
            ),
            const Positioned(
              top: 128,
              left: 48,
              child: HandDrawnBalloon(
                asset: JournalDoodleAssets.balloonSmall,
                width: 36,
                rotationDegrees: -9,
              ),
            ),
            const Positioned(
              bottom: 78,
              right: 70,
              child: HandDrawnBalloon(
                asset: JournalDoodleAssets.balloonTiny,
                width: 28,
                rotationDegrees: 4,
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      stamp.toUpperCase(),
                      style: AppTypography.titlePageStamp,
                    ),
                    const SizedBox(height: 14),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 270),
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titlePageTitle,
                      ),
                    ),
                    const SizedBox(height: 28),
                    _Polaroid(photo: photo),
                    const SizedBox(height: 26),
                    Text(meta, style: AppTypography.titlePageMeta),
                  ],
                ),
              ),
            ),
            const SpineGutter(),
          ],
        ),
      ),
    );
  }
}

class _Polaroid extends StatelessWidget {
  const _Polaroid({required this.photo});

  final PhotoEntity? photo;

  @override
  Widget build(BuildContext context) {
    final url = photo?.imageUrl;
    return Transform.rotate(
      angle: -4 * math.pi / 180,
      child: Container(
        width: _polaroidWidth,
        height: _polaroidHeight,
        padding: _polaroidPadding,
        decoration: BoxDecoration(
          color: AppColors.polaroid,
          boxShadow: [
            BoxShadow(
              color: AppColors.tint(AppColors.paperInk, .22),
              offset: const Offset(0, 12),
              blurRadius: 26,
            ),
          ],
        ),
        child: url == null
            ? const ColoredBox(color: AppColors.paperEdge)
            : StoragePhotoImage(
                url: url,
                storagePath: photo!.storagePath,
                decodeSize: notePolaroidPhotoSize,
              ),
      ),
    );
  }
}

/// Back face of the turning page — plain paper, darker toward the spine.
/// Laid out un-mirrored; the caller flips it once the page passes 90°.
class NotePageBack extends StatelessWidget {
  const NotePageBack({super.key});

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      key: Key('note-page-back'),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.horizontal(left: Radius.circular(16)),
        gradient: LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [AppColors.paperEdgeBack, AppColors.paperBackLight],
          stops: [0, .7],
        ),
      ),
    );
  }
}

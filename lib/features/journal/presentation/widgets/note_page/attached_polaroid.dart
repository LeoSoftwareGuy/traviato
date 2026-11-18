import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../core/l10n/context_l10n.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../photo/domain/entities/photo_entity.dart';
import '../../../../photo/presentation/widgets/storage_photo_image.dart';

/// The photo a note is being written on (#402): its time ("18:25", in the
/// phone's clock) and a line under it — the caption, else the place.
class NotePhotoAttachment {
  const NotePhotoAttachment({
    required this.photo,
    required this.time,
    this.line,
  });

  final PhotoEntity photo;
  final String time;
  final String? line;
}

const _width = 96.0;
const _height = 112.0;

/// The polaroid at the top of a photo note's ruled page
/// (docs/design/journal-notes/ §6): 96×112, white, tilted −3°, with
/// "ON THIS PHOTO · 18:25" and the caption beside it.
class AttachedPolaroid extends StatelessWidget {
  const AttachedPolaroid({required this.attachment, super.key});

  final NotePhotoAttachment attachment;

  @override
  Widget build(BuildContext context) {
    final photo = attachment.photo;
    final line = attachment.line?.trim();
    return Padding(
      key: const Key('note-page-attached-photo'),
      padding: const EdgeInsets.only(top: 6, bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Transform.rotate(
            angle: -3 * math.pi / 180,
            child: Container(
              width: _width,
              height: _height,
              padding: const EdgeInsets.fromLTRB(6, 6, 6, 22),
              decoration: BoxDecoration(
                color: AppColors.polaroid,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.tint(AppColors.paperInk, .2),
                    offset: const Offset(0, 8),
                    blurRadius: 18,
                  ),
                ],
              ),
              child: photo.imageUrl == null
                  ? const ColoredBox(color: AppColors.paperEdge)
                  : StoragePhotoImage(
                      url: photo.imageUrl!,
                      storagePath: photo.storagePath,
                      decodeSize: const Size(_width, _height),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n
                        .note_onThisPhoto(attachment.time)
                        .toUpperCase(),
                    style: AppTypography.titlePageStamp.copyWith(
                      fontSize: 9,
                      letterSpacing: 9 * .14,
                    ),
                  ),
                  if (line != null && line.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      line,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titlePageMeta.copyWith(
                        fontSize: 14,
                        color: AppColors.paperInkOld,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

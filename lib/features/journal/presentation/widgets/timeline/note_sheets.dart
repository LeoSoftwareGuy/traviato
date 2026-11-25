import 'package:flutter/material.dart';

import '../../../../../core/l10n/context_l10n.dart';
import '../../../../../core/l10n/l10n_dates.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/bottom_sheet_chrome.dart';
import '../../../../photo/domain/entities/photo_entity.dart';
import '../../../../photo/presentation/widgets/storage_photo_image.dart';
import '../../../domain/entities/journal_note_entity.dart';

enum NoteAction { edit, editTime, delete }

enum PhotoAction { delete }

const _sheetDuration = Duration(milliseconds: 280);

Future<T?> _showSheet<T>(BuildContext context, WidgetBuilder builder) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.tint(AppColors.filmBackground, .62),
    sheetAnimationStyle: const AnimationStyle(
      duration: _sheetDuration,
      reverseDuration: _sheetDuration,
    ),
    builder: builder,
  );
}

/// Long-press on a note (#401, spec §5): a preview (time, mic, two lines)
/// and Edit note / Delete note / Cancel. Null when dismissed.
abstract final class NoteActionsSheet {
  static Future<NoteAction?> show(
    BuildContext context, {
    required JournalNoteEntity note,
    required bool use24h,
  }) {
    return _showSheet<NoteAction>(context, (context) {
      final l10n = context.l10n;
      final time = note.isBackfilled
          ? l10n.timeline_addedLater
          : L10nDates.clock(
              l10n.localeName,
              use24h: use24h,
            ).format(note.localTakenAt);
      return BottomSheetChrome(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.base,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(time, style: AppTypography.timelineTime),
                  if (note.dictated) ...[
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.mic_none_rounded,
                      size: 11,
                      color: AppColors.textMuted,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              Text(
                note.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.timelineNote,
              ),
              const SizedBox(height: AppSpacing.base),
              _SheetButton(
                key: const Key('note-sheet-edit'),
                label: l10n.timeline_editNote,
                onTap: () => Navigator.of(context).pop(NoteAction.edit),
              ),
              if (!note.legacy)
                _SheetButton(
                  key: const Key('note-sheet-edit-time'),
                  label: l10n.timeline_editTime,
                  onTap: () => Navigator.of(context).pop(NoteAction.editTime),
                ),
              _SheetButton(
                key: const Key('note-sheet-delete'),
                label: l10n.timeline_deleteNote,
                color: AppColors.dangerText,
                onTap: () => Navigator.of(context).pop(NoteAction.delete),
              ),
              _SheetButton(
                label: l10n.common_cancel,
                color: AppColors.textMuted,
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      );
    });
  }
}

/// "Delete the 21:16 note?" (#401, spec §5): Keep / Delete. True to delete.
abstract final class DeleteNoteSheet {
  static Future<bool> confirm(BuildContext context, {required String time}) {
    final l10n = context.l10n;
    return _confirmDelete(
      context,
      keyPrefix: 'note-delete',
      title: l10n.timeline_deleteTitle(time),
      body: l10n.timeline_deleteBody,
    );
  }
}

/// Long-press on a timeline photo (#424, like a note's): a preview
/// (thumbnail, time, caption) and Delete photo / Cancel. Null when
/// dismissed.
abstract final class PhotoActionsSheet {
  static Future<PhotoAction?> show(
    BuildContext context, {
    required PhotoEntity photo,
    required bool use24h,
  }) {
    return _showSheet<PhotoAction>(context, (context) {
      final l10n = context.l10n;
      final time = L10nDates.clock(
        l10n.localeName,
        use24h: use24h,
      ).format(photo.localTime);
      final caption = photo.caption?.trim();
      return BottomSheetChrome(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.base,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                key: const Key('photo-sheet-preview'),
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                    child: SizedBox.square(
                      dimension: _thumbSize,
                      child: photo.imageUrl == null
                          ? const ColoredBox(color: AppColors.surface)
                          : StoragePhotoImage(
                              url: photo.imageUrl!,
                              storagePath: photo.storagePath,
                              decodeSize: const Size.square(_thumbSize),
                            ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(time, style: AppTypography.timelineTime),
                        if (caption != null && caption.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            caption,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.timelineCaption,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.base),
              _SheetButton(
                key: const Key('photo-sheet-delete'),
                label: l10n.timeline_deletePhoto,
                color: AppColors.dangerText,
                onTap: () => Navigator.of(context).pop(PhotoAction.delete),
              ),
              _SheetButton(
                label: l10n.common_cancel,
                color: AppColors.textMuted,
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      );
    });
  }

  static const double _thumbSize = 56;
}

/// "Delete this photo?" (#424): Keep / Delete. True to delete. Asked by
/// the timeline's photo sheet and by the photo viewer's trash button.
abstract final class DeletePhotoSheet {
  static Future<bool> confirm(BuildContext context) {
    final l10n = context.l10n;
    return _confirmDelete(
      context,
      keyPrefix: 'photo-delete',
      title: l10n.timeline_deletePhotoTitle,
      body: l10n.timeline_deletePhotoBody,
    );
  }
}

/// The shared Keep / Delete confirm sheet; keys `<keyPrefix>-keep` and
/// `<keyPrefix>-confirm`.
Future<bool> _confirmDelete(
  BuildContext context, {
  required String keyPrefix,
  required String title,
  required String body,
}) {
  return _showSheet<bool>(context, (context) {
    final l10n = context.l10n;
    return BottomSheetChrome(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.base,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: AppTypography.displaySerif),
            const SizedBox(height: AppSpacing.sm),
            Text(
              body,
              style: AppTypography.bodyEmphasis.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: Key('$keyPrefix-keep'),
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.hairline),
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: Text(l10n.timeline_keep),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FilledButton(
                    key: Key('$keyPrefix-confirm'),
                    onPressed: () => Navigator.of(context).pop(true),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accentCoral,
                      foregroundColor: AppColors.background,
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: Text(l10n.common_delete),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }).then((value) => value ?? false);
}

class _SheetButton extends StatelessWidget {
  const _SheetButton({
    required this.label,
    required this.onTap,
    this.color = AppColors.textPrimary,
    super.key,
  });

  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Text(
          label,
          style: AppTypography.bodyEmphasis.copyWith(
            fontSize: 15,
            color: color,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../../core/l10n/context_l10n.dart';
import '../../../../../core/l10n/l10n_dates.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/bottom_sheet_chrome.dart';
import '../../../domain/entities/journal_note_entity.dart';

enum NoteAction { edit, delete }

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
      final time = L10nDates.clock(
        l10n.localeName,
        use24h: use24h,
      ).format(note.takenAt.toLocal());
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
              Text(
                l10n.timeline_deleteTitle(time),
                style: AppTypography.displaySerif,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.timeline_deleteBody,
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
                      key: const Key('note-delete-keep'),
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
                      key: const Key('note-delete-confirm'),
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

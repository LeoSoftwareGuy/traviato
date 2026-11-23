import 'package:flutter/material.dart';

import '../../../../core/l10n/context_l10n.dart';
import '../../../../core/l10n/l10n_dates.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/journal_note_entity.dart';
import 'timeline/fresh_glow.dart';
import 'timeline/fresh_note_in.dart';

/// Under a photo in the viewer (#402, docs/design/journal-notes/ §6):
/// "✎ Add a note to this photo", then NOTES ON THIS PHOTO · N with each
/// note in full (time + mic), or nothing when it has none (#438).
/// [freshNoteId] slides in and wears JUST NOW.
class PhotoNotesPanel extends StatelessWidget {
  const PhotoNotesPanel({
    required this.notes,
    required this.onAdd,
    this.freshNoteId,
    super.key,
  });

  /// This photo's notes, oldest first.
  final List<JournalNoteEntity> notes;
  final VoidCallback onAdd;
  final String? freshNoteId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final clock = L10nDates.clock(
      l10n.localeName,
      use24h: MediaQuery.alwaysUse24HourFormatOf(context),
    );
    return Column(
      key: const Key('photo-notes-panel'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: AppColors.tint(AppColors.primary, .12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.tint(AppColors.primary, .45)),
          ),
          child: InkWell(
            key: const Key('photo-notes-add'),
            borderRadius: BorderRadius.circular(16),
            onTap: onAdd,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                l10n.photoNote_add,
                textAlign: TextAlign.center,
                style: AppTypography.timelineLink.copyWith(fontSize: 12.5),
              ),
            ),
          ),
        ),
        // No notes yet: nothing under the add button (#438).
        if (notes.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            l10n.photoNote_listLabel(notes.length).toUpperCase(),
            style: AppTypography.mono.copyWith(color: AppColors.textTertiary),
          ),
          for (final note in notes) ...[
            const SizedBox(height: 8),
            FreshNoteIn(
              key: ValueKey('photo-note-${note.id}'),
              isFresh: note.id == freshNoteId,
              child: FreshGlow(
                isFresh: note.id == freshNoteId,
                borderRadius: BorderRadius.circular(16),
                child: _PhotoNoteCard(
                  note: note,
                  time: clock.format(note.localTakenAt),
                  isFresh: note.id == freshNoteId,
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class _PhotoNoteCard extends StatelessWidget {
  const _PhotoNoteCard({
    required this.note,
    required this.time,
    required this.isFresh,
  });

  final JournalNoteEntity note;
  final String time;
  final bool isFresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFresh
              ? AppColors.tint(AppColors.primary, .75)
              : AppColors.hairline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
              if (isFresh) ...[
                const Spacer(),
                Text(
                  context.l10n.timeline_justNow.toUpperCase(),
                  style: AppTypography.mono.copyWith(color: AppColors.primary),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          // User content — in full, exactly as written.
          Text(note.content, style: AppTypography.timelineNote),
        ],
      ),
    );
  }
}

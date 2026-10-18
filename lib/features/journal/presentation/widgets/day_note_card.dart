import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/note_text.dart';

final _editedAtFormat = DateFormat('HH:mm');

/// The day's note card — read-only (docs/design/JOURNAL_NOTE_PAGETURN_SPEC.md
/// §1, #205). Shows the saved entry with its "EDITED {time} · {N} WORDS"
/// footer, or an "Add notes about today" prompt when there isn't one yet.
/// Writing happens on the full-screen note page: the prompt and the
/// "Continue entry" link both call [onOpenNotePage].
class DayNoteCard extends StatelessWidget {
  const DayNoteCard({
    required this.content,
    required this.updatedAt,
    required this.isSaving,
    required this.onOpenNotePage,
    super.key,
  });

  final String content;
  final DateTime? updatedAt;
  final bool isSaving;
  final VoidCallback onOpenNotePage;

  @override
  Widget build(BuildContext context) {
    if (content.trim().isEmpty) {
      return InkWell(
        key: const Key('journal-note-add-prompt'),
        onTap: onOpenNotePage,
        borderRadius: AppRadius.cardRadius,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.surfaceBorder),
            borderRadius: AppRadius.cardRadius,
          ),
          child: Row(
            children: [
              // Expanded (not Text + Spacer) so a longer translation wraps
              // instead of overflowing (#220).
              Expanded(
                child: Text(
                  context.l10n.journal_addNotesToday,
                  style: AppTypography.bodyEmphasis.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
              if (isSaving) const _SavingIndicator(),
            ],
          ),
        ),
      );
    }

    final wordCount = countNoteWords(content);
    return Container(
      key: const Key('journal-note-view'),
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.surfaceBorder),
        borderRadius: AppRadius.cardRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(content, style: AppTypography.pullQuote),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Text(
                (updatedAt == null
                        ? context.l10n.journal_wordCount(wordCount)
                        : '${context.l10n.journal_edited(_editedAtFormat.format(updatedAt!))}'
                              ' · ${context.l10n.journal_wordCount(wordCount)}')
                    .toUpperCase(),
                style: AppTypography.mono,
              ),
              const Spacer(),
              if (isSaving) const _SavingIndicator(),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          TextButton(
            key: const Key('journal-note-continue'),
            onPressed: onOpenNotePage,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              context.l10n.journal_continueEntry,
              style: AppTypography.bodyEmphasis.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SavingIndicator extends StatelessWidget {
  const _SavingIndicator();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 12,
      height: 12,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  }
}

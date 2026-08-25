import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

final _editedAtFormat = DateFormat('HH:mm');

/// The day's note card — `docs/design/README.md` § 7. Idle view state shows
/// either the saved note (with an "EDITED {time} · {N} WORDS" footer) or an
/// "Add notes about today" prompt when there isn't one yet; tapping either
/// enters edit mode with explicit Save / Cancel actions.
class DayNoteCard extends StatefulWidget {
  const DayNoteCard({
    required this.content,
    required this.updatedAt,
    required this.isSaving,
    required this.onSave,
    super.key,
  });

  final String content;
  final DateTime? updatedAt;
  final bool isSaving;
  final ValueChanged<String> onSave;

  @override
  State<DayNoteCard> createState() => _DayNoteCardState();
}

class _DayNoteCardState extends State<DayNoteCard> {
  late final _controller = TextEditingController(text: widget.content);
  var _isEditing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startEditing() => setState(() => _isEditing = true);

  void _cancel() {
    _controller.text = widget.content;
    setState(() => _isEditing = false);
  }

  void _save() {
    widget.onSave(_controller.text);
    setState(() => _isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    return _isEditing ? _buildEditing() : _buildView();
  }

  Widget _buildView() {
    if (widget.content.trim().isEmpty) {
      return InkWell(
        key: const Key('journal-note-add-prompt'),
        onTap: _startEditing,
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
              const Icon(
                Icons.edit_note_outlined,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Add notes about today',
                style: AppTypography.bodyEmphasis.copyWith(
                  color: AppColors.primary,
                ),
              ),
              const Spacer(),
              if (widget.isSaving)
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
        ),
      );
    }

    final wordCount = widget.content
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .length;

    return InkWell(
      key: const Key('journal-note-view'),
      onTap: _startEditing,
      borderRadius: AppRadius.cardRadius,
      child: Container(
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
            Text(widget.content, style: AppTypography.pullQuote),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Text(
                  widget.updatedAt == null
                      ? '$wordCount WORDS'
                      : 'EDITED ${_editedAtFormat.format(widget.updatedAt!)} '
                            '· $wordCount WORDS',
                  style: AppTypography.mono,
                ),
                const Spacer(),
                if (widget.isSaving)
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditing() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.tint(AppColors.primary, .5)),
        borderRadius: AppRadius.cardRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            key: const Key('journal-note-field'),
            controller: _controller,
            autofocus: true,
            maxLines: null,
            minLines: 6,
            style: AppTypography.bodyInput.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            decoration: InputDecoration(
              hintText: 'Add notes about today',
              hintStyle: AppTypography.bodyInput.copyWith(
                color: AppColors.textTertiary,
              ),
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              isCollapsed: true,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                key: const Key('journal-note-cancel'),
                onPressed: widget.isSaving ? null : _cancel,
                child: const Text('Cancel'),
              ),
              const SizedBox(width: AppSpacing.xs),
              ElevatedButton(
                key: const Key('journal-note-save'),
                onPressed: widget.isSaving ? null : _save,
                child: widget.isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

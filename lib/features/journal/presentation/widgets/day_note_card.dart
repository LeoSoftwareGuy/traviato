import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// "Add notes about today" card. Autosaves on blur (no separate Save
/// button, matching the Figma frame) and again on dispose, so switching
/// days — which re-keys this widget per day — never silently drops an
/// unsaved edit.
class DayNoteCard extends StatefulWidget {
  const DayNoteCard({
    required this.content,
    required this.isSaving,
    required this.onSave,
    super.key,
  });

  final String content;
  final bool isSaving;
  final ValueChanged<String> onSave;

  @override
  State<DayNoteCard> createState() => _DayNoteCardState();
}

class _DayNoteCardState extends State<DayNoteCard> {
  late final _controller = TextEditingController(text: widget.content);
  final _focusNode = FocusNode();
  late String _lastSavedContent = widget.content;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) _flushIfChanged();
  }

  void _flushIfChanged() {
    final text = _controller.text;
    if (text == _lastSavedContent) return;
    _lastSavedContent = text;
    widget.onSave(text);
  }

  @override
  void dispose() {
    _flushIfChanged();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.edit_note_outlined,
              size: 16,
              color: AppColors.textPrimary,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'Add notes about today',
              style: AppTypography.bodyInput.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
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
        const SizedBox(height: AppSpacing.sm),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.surfaceBorder),
            borderRadius: AppRadius.cardRadius,
          ),
          child: TextField(
            key: const Key('journal-note-field'),
            controller: _controller,
            focusNode: _focusNode,
            maxLines: null,
            minLines: 6,
            style: AppTypography.bodyInput.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w400,
              height: 1.5,
            ),
            decoration: InputDecoration(
              hintText: 'Add notes about today',
              hintStyle: AppTypography.bodyInput.copyWith(
                color: AppColors.textTertiary,
              ),
              border: InputBorder.none,
              isCollapsed: true,
            ),
          ),
        ),
      ],
    );
  }
}

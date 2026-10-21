import 'package:flutter/material.dart';

import '../../../../../core/l10n/context_l10n.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import 'note_dictation_controller.dart';
import 'note_dock.dart';
import 'note_page_chrome.dart';
import 'ruled_lines_painter.dart';

/// The page the user writes on, revealed when the title page turns away
/// (docs/design/JOURNAL_NOTE_PAGETURN_SPEC.md §2, §4 typing): header with
/// Cancel / stamp / Done, the title, the ruled scroll (the day's whole
/// entry, editable — #276), and the dock with voice dictation.
class NoteWritingPage extends StatelessWidget {
  const NoteWritingPage({
    required this.stamp,
    required this.title,
    required this.controller,
    required this.focusNode,
    required this.draftWordCount,
    required this.dockBottomPadding,
    required this.onCancel,
    required this.onDone,
    required this.onAaTap,
    required this.dictation,
    required this.onMicTap,
    required this.onFieldTap,
    required this.languageCode,
    required this.isLanguageAvailable,
    required this.onLanguageTap,
    super.key,
  });

  final String stamp;
  final String title;
  final TextEditingController controller;
  final FocusNode focusNode;
  final int draftWordCount;
  final double dockBottomPadding;
  final VoidCallback onCancel;
  final VoidCallback onDone;
  final VoidCallback onAaTap;
  final NoteDictationController dictation;
  final VoidCallback onMicTap;

  /// Tapping into the field while listening stops the recording.
  final VoidCallback onFieldTap;

  /// The dictation language and whether it works here (#218).
  final String languageCode;
  final bool isLanguageAvailable;
  final VoidCallback onLanguageTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.paper,
        borderRadius: notePageRadius,
      ),
      child: ClipRRect(
        borderRadius: notePageRadius,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(stamp: stamp, onCancel: onCancel, onDone: onDone),
                Padding(
                  padding: const EdgeInsets.fromLTRB(30, 12, 22, 8),
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.noteTitle,
                  ),
                ),
                Expanded(
                  child: _RuledScroll(
                    hintText: isLanguageAvailable
                        ? context.l10n.note_bodyHint
                        : context.l10n.note_bodyHintUnavailable,
                    controller: controller,
                    focusNode: focusNode,
                    onFieldTap: onFieldTap,
                  ),
                ),
                NoteDock(
                  dictation: dictation,
                  draftWordCount: draftWordCount,
                  bottomPadding: dockBottomPadding,
                  onAaTap: onAaTap,
                  onMicTap: onMicTap,
                  languageCode: languageCode,
                  isLanguageAvailable: isLanguageAvailable,
                  onLanguageTap: onLanguageTap,
                ),
              ],
            ),
            const SpineGutter(),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.stamp,
    required this.onCancel,
    required this.onDone,
  });

  final String stamp;
  final VoidCallback onCancel;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 6, 10, 0),
      child: Row(
        children: [
          TextButton(
            key: const Key('note-page-cancel'),
            onPressed: onCancel,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.paperInkMuted,
            ),
            child: Text(
              context.l10n.common_cancel,
              style: AppTypography.noteHeaderAction,
            ),
          ),
          Expanded(
            child: Text(
              stamp.toUpperCase(),
              textAlign: TextAlign.center,
              style: AppTypography.noteStamp,
            ),
          ),
          TextButton(
            key: const Key('note-page-done'),
            onPressed: onDone,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.paperDoneInk,
            ),
            child: Text(
              context.l10n.common_done,
              style: AppTypography.noteHeaderAction.copyWith(
                color: AppColors.paperDoneInk,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RuledScroll extends StatelessWidget {
  const _RuledScroll({
    required this.hintText,
    required this.controller,
    required this.focusNode,
    required this.onFieldTap,
  });

  final String hintText;
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onFieldTap;

  static const _minFieldLines = 8; // 240px at the 30px line height

  @override
  Widget build(BuildContext context) {
    final bodyStyle = AppTypography.noteBody;
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        key: const Key('note-page-scroll'),
        padding: const EdgeInsets.only(bottom: 20),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
        child: ConstrainedBox(
          // Rules run to the bottom of the page even when there's little
          // text, and keep scrolling with it when there's a lot.
          constraints: BoxConstraints(
            minHeight: (constraints.maxHeight - 20).clamp(
              0.0,
              double.infinity,
            ),
          ),
          child: CustomPaint(
            painter: const RuledLinesPainter(
              lineHeight: AppTypography.noteLineHeight,
              color: AppColors.paperRule,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(30, 0, 22, 0),
              // Keeps the field at its own height (on the rule grid) rather
              // than stretched to the page's minHeight.
              child: Align(
                alignment: Alignment.topCenter,
                child: TextField(
                  key: const Key('note-page-field'),
                  controller: controller,
                  focusNode: focusNode,
                  onTap: onFieldTap,
                  maxLines: null,
                  minLines: _minFieldLines,
                  keyboardType: TextInputType.multiline,
                  textCapitalization: TextCapitalization.sentences,
                  style: bodyStyle,
                  strutStyle: AppTypography.noteBodyStrut,
                  cursorColor: AppColors.paperInk,
                  decoration: InputDecoration.collapsed(
                    hintText: hintText,
                    hintStyle: bodyStyle.copyWith(
                      color: AppColors.tint(AppColors.paperInkMuted, .7),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

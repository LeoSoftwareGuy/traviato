import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_gradients.dart';
import '../../../../../core/theme/app_typography.dart';
import 'note_page_chrome.dart';
import 'ruled_lines_painter.dart';

/// The page the user writes on, revealed when the title page turns away
/// (docs/design/JOURNAL_NOTE_PAGETURN_SPEC.md §2, §4 typing): header with
/// Cancel / stamp / Done, the title, the ruled scroll (existing entry in
/// faded ink + the new-text field), and the dock.
class NoteWritingPage extends StatelessWidget {
  const NoteWritingPage({
    required this.stamp,
    required this.title,
    required this.existingText,
    required this.controller,
    required this.focusNode,
    required this.draftWordCount,
    required this.dockBottomPadding,
    required this.onCancel,
    required this.onDone,
    required this.onAaTap,
    super.key,
  });

  final String stamp;
  final String title;
  final String existingText;
  final TextEditingController controller;
  final FocusNode focusNode;
  final int draftWordCount;
  final double dockBottomPadding;
  final VoidCallback onCancel;
  final VoidCallback onDone;
  final VoidCallback onAaTap;

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
                    existingText: existingText,
                    controller: controller,
                    focusNode: focusNode,
                  ),
                ),
                _Dock(
                  draftWordCount: draftWordCount,
                  bottomPadding: dockBottomPadding,
                  onAaTap: onAaTap,
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
            child: Text('Cancel', style: AppTypography.noteHeaderAction),
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
              'Done',
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
    required this.existingText,
    required this.controller,
    required this.focusNode,
  });

  final String existingText;
  final TextEditingController controller;
  final FocusNode focusNode;

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (existingText.trim().isNotEmpty)
                    Text(
                      existingText.trim(),
                      key: const Key('note-page-existing'),
                      strutStyle: AppTypography.noteBodyStrut,
                      style: bodyStyle.copyWith(color: AppColors.paperInkOld),
                    ),
                  TextField(
                    key: const Key('note-page-field'),
                    controller: controller,
                    focusNode: focusNode,
                    maxLines: null,
                    minLines: _minFieldLines,
                    keyboardType: TextInputType.multiline,
                    textCapitalization: TextCapitalization.sentences,
                    style: bodyStyle,
                    strutStyle: AppTypography.noteBodyStrut,
                    cursorColor: AppColors.paperInk,
                    decoration: InputDecoration.collapsed(
                      hintText:
                          'Keep going — type, or tap the mic and just talk.',
                      hintStyle: bodyStyle.copyWith(
                        color: AppColors.tint(AppColors.paperInkMuted, .7),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Dock extends StatelessWidget {
  const _Dock({
    required this.draftWordCount,
    required this.bottomPadding,
    required this.onAaTap,
  });

  final int draftWordCount;
  final double bottomPadding;
  final VoidCallback onAaTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('note-page-dock'),
      padding: EdgeInsets.fromLTRB(30, 12, 22, bottomPadding),
      decoration: const BoxDecoration(
        color: AppColors.paperDock,
        border: Border(top: BorderSide(color: AppColors.paperRule)),
      ),
      child: Row(
        children: [
          _AaButton(onTap: onAaTap),
          const Expanded(child: _MicButton()),
          SizedBox(
            width: 72,
            child: draftWordCount == 0
                ? null
                : Text(
                    '+$draftWordCount ${draftWordCount == 1 ? 'word' : 'words'}',
                    key: const Key('note-page-word-counter'),
                    textAlign: TextAlign.right,
                    style: AppTypography.noteDockCounter,
                  ),
          ),
        ],
      ),
    );
  }
}

class _AaButton extends StatelessWidget {
  const _AaButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Type',
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        shape: CircleBorder(
          side: BorderSide(color: AppColors.tint(AppColors.paperInk, .2)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: const Key('note-page-aa'),
          onTap: onTap,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Center(child: Text('Aa', style: AppTypography.noteDockAa)),
          ),
        ),
      ),
    );
  }
}

/// Voice arrives in a follow-up issue — until then the mic is shown so the
/// dock keeps its final layout, but it's disabled and says so.
class _MicButton extends StatelessWidget {
  const _MicButton();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: false,
      label: 'Voice notes, coming soon',
      excludeSemantics: true,
      child: Column(
        key: const Key('note-page-mic'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Opacity(
            opacity: .45,
            child: Container(
              width: 68,
              height: 68,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppGradients.primaryCta,
              ),
              child: const Icon(
                Icons.mic_none_rounded,
                color: AppColors.background,
                size: 28,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text('Voice coming soon', style: AppTypography.noteDockLabel),
        ],
      ),
    );
  }
}

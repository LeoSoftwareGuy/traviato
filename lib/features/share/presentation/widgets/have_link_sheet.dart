import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/bottom_sheet_chrome.dart';
import '../../domain/share_slug.dart';
import '../controllers/share_link_intake_controller.dart';

/// "I have a link" (#310): paste a `storyni.app/m/…` link to open the
/// shared memory. It's the fallback for every deferred-link gap, and the
/// iOS "Opening a shared memory?" card. Pasting goes through the system
/// edit menu where the platform has one, so iOS shows no paste prompt.
class HaveLinkSheet extends ConsumerStatefulWidget {
  const HaveLinkSheet({this.isPasteOffer = false, super.key});

  /// Shown unasked once after sign-up (iOS): its title asks the question.
  final bool isPasteOffer;

  static Future<void> show(BuildContext context, {bool isPasteOffer = false}) {
    return showAppBottomSheet<void>(
      context: context,
      builder: (context) => HaveLinkSheet(isPasteOffer: isPasteOffer),
    );
  }

  @override
  ConsumerState<HaveLinkSheet> createState() => _HaveLinkSheetState();
}

class _HaveLinkSheetState extends ConsumerState<HaveLinkSheet> {
  final _controller = TextEditingController();
  bool _showInvalid = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _open() {
    final slug = parseShareSlug(_controller.text);
    if (slug == null) {
      setState(() => _showInvalid = true);
      return;
    }
    Navigator.of(context).pop();
    ref.read(shareLinkIntakeControllerProvider.notifier).open(slug);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        22,
        AppSpacing.sm,
        22,
        AppSpacing.xl + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.isPasteOffer ? l10n.share_pasteCard : l10n.share_haveLink,
            style: AppTypography.serif(
              fontSize: 20,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.share_haveLinkBody,
            style: AppTypography.caption.copyWith(
              fontSize: 12.5,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.base),
          TextField(
            key: const Key('have-link-field'),
            controller: _controller,
            autofocus: !widget.isPasteOffer,
            keyboardType: TextInputType.url,
            autocorrect: false,
            textInputAction: TextInputAction.go,
            onSubmitted: (_) => _open(),
            onChanged: (_) {
              if (_showInvalid) setState(() => _showInvalid = false);
            },
            style: AppTypography.mono.copyWith(
              fontSize: 12.5,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: l10n.share_linkHint,
              errorText: _showInvalid ? l10n.share_linkInvalid : null,
            ),
            contextMenuBuilder: (context, editableTextState) =>
                SystemContextMenu.isSupported(context)
                ? SystemContextMenu.editableText(
                    editableTextState: editableTextState,
                  )
                : AdaptiveTextSelectionToolbar.editableText(
                    editableTextState: editableTextState,
                  ),
          ),
          const SizedBox(height: AppSpacing.md),
          ElevatedButton(
            key: const Key('have-link-open'),
            onPressed: _open,
            child: Text(l10n.share_linkOpen),
          ),
        ],
      ),
    );
  }
}

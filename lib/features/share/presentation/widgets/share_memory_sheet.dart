import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure_message.dart';
import '../../../../core/l10n/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/bottom_sheet_chrome.dart';
import '../../../../core/widgets/show_error_snackbar.dart';
import '../../../../core/widgets/star_award_toast.dart';
import '../../domain/entities/share_link.dart';
import '../controllers/share_sheet_controller.dart';
import '../pages/share_qr_page.dart';
import '../pages/share_story_card_page.dart';
import '../providers/share_memory_provider.dart';
import '../providers/share_providers.dart';
import 'share_link_field.dart';
import 'share_sheet_parts.dart';
import 'share_turn_off.dart';

/// Share a memory (#311, design 1a): the memory's public link — copy,
/// system share, QR, story card — what people will see, and a two-step
/// "Turn off link". Owner only; every entry point is on the owner's own
/// memory screens.
class ShareMemorySheet extends ConsumerWidget {
  const ShareMemorySheet({required this.tripId, super.key});

  final String tripId;

  static Future<void> show(BuildContext context, {required String tripId}) =>
      showAppBottomSheet<void>(
        context: context,
        builder: (_) => ShareMemorySheet(tripId: tripId),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sheet = ref.watch(shareSheetControllerProvider(tripId));
    final memory = ref.watch(shareMemoryProvider(tripId)).value;
    final state = sheet.value;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 2, 22, AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ShareSheetHeader(
            title: memory?.trip.name ?? '',
            coverPath:
                memory?.teaserPhotos.firstOrNull?.storagePath ??
                memory?.trip.coverImagePath,
            isLive: state?.isLive ?? true,
          ),
          const SizedBox(height: 18),
          if (sheet.hasError && state == null)
            ShareSheetError(
              onRetry: () =>
                  ref.invalidate(shareSheetControllerProvider(tripId)),
            )
          else if (state == null)
            const _LinkBlock(link: null)
          else if (state.link case final link?)
            _LinkBlock(link: link, tripId: tripId, title: memory?.trip.name)
          else
            ShareRevokedCard(
              revokedUrl: state.revokedLink?.url,
              isBusy: state.isBusy,
              onNewLink: () => _newLink(context, ref),
            ),
          const SizedBox(height: 18),
          const ShareWhatPeopleSee(),
          if (state?.isLive ?? false) ...[
            const SizedBox(height: AppSpacing.base),
            const Divider(height: 1, color: AppColors.hairline),
            const SizedBox(height: AppSpacing.sm),
            ShareTurnOff(
              isConfirming: state!.isConfirmingRevoke,
              isBusy: state.isBusy,
              onAsk: ref
                  .read(shareSheetControllerProvider(tripId).notifier)
                  .askRevoke,
              onKeep: ref
                  .read(shareSheetControllerProvider(tripId).notifier)
                  .cancelRevoke,
              onConfirm: () => _revoke(context, ref),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _revoke(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    try {
      await ref.read(shareSheetControllerProvider(tripId).notifier).revoke();
      if (context.mounted) showStarToast(context, l10n.share_toastOff);
    } catch (e) {
      if (context.mounted) {
        showErrorSnackbar(
          context,
          message: presentationFailureMessage(e, l10n),
        );
      }
    }
  }

  Future<void> _newLink(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    try {
      await ref
          .read(shareSheetControllerProvider(tripId).notifier)
          .makeNewLink();
      if (context.mounted) showStarToast(context, l10n.share_toastNew);
    } catch (e) {
      if (context.mounted) {
        showErrorSnackbar(
          context,
          message: presentationFailureMessage(e, l10n),
        );
      }
    }
  }
}

/// The link field and the three tiles. [link] null = still making it:
/// a shimmering field and disabled tiles.
class _LinkBlock extends ConsumerWidget {
  const _LinkBlock({required this.link, this.tripId, this.title});

  final ShareLink? link;
  final String? tripId;
  final String? title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final link = this.link;
    final tripId = this.tripId;
    final ready = link != null && tripId != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ShareLinkField(slug: link?.slug, onCopy: () => _copy(context, link)),
        const SizedBox(height: 10),
        ShareTiles(
          onShare: ready
              ? () => ref
                    .read(shareOutletsProvider)
                    .shareLink(title: title ?? '', url: link.url)
              : null,
          onQr: ready
              ? () => ShareQrPage.show(context, tripId: tripId, link: link)
              : null,
          onStory: ready
              ? () =>
                    ShareStoryCardPage.show(context, tripId: tripId, link: link)
              : null,
        ),
      ],
    );
  }

  Future<void> _copy(BuildContext context, ShareLink? link) async {
    if (link == null) return;
    final message = context.l10n.share_toastCopied;
    await Clipboard.setData(ClipboardData(text: link.url));
    await HapticFeedback.lightImpact();
    if (context.mounted) showStarToast(context, message);
  }
}

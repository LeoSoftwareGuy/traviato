import 'package:flutter/material.dart';

import '../../../../core/l10n/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/dashed_rrect_border.dart';

/// "Turn off link" and its inline step 2 (#311, 1a).
class ShareTurnOff extends StatelessWidget {
  const ShareTurnOff({
    required this.isConfirming,
    required this.isBusy,
    required this.onAsk,
    required this.onKeep,
    required this.onConfirm,
    super.key,
  });

  final bool isConfirming;
  final bool isBusy;
  final VoidCallback onAsk;
  final VoidCallback onKeep;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (!isConfirming) {
      return Align(
        alignment: Alignment.centerLeft,
        child: TextButton(
          onPressed: onAsk,
          style: TextButton.styleFrom(foregroundColor: AppColors.accentCoral),
          child: Text(l10n.share_turnOff),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.tint(AppColors.accentCoral, .08),
        border: Border.all(color: AppColors.tint(AppColors.accentCoral, .3)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.share_turnOffTitle,
            style: AppTypography.serif(
              fontSize: 17,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.share_turnOffBody,
            style: AppTypography.caption.copyWith(
              fontSize: 13,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isBusy ? null : onKeep,
                  child: Text(l10n.share_keep),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: FilledButton(
                  key: const ValueKey('share-turn-off-confirm'),
                  onPressed: isBusy ? null : onConfirm,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accentCoral,
                    foregroundColor: AppColors.background,
                  ),
                  child: Text(l10n.share_turnOffConfirm),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The link is off: the old URL struck through and "Make a new link".
class ShareRevokedCard extends StatelessWidget {
  const ShareRevokedCard({
    required this.revokedUrl,
    required this.isBusy,
    required this.onNewLink,
    super.key,
  });

  final String? revokedUrl;
  final bool isBusy;
  final VoidCallback onNewLink;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final url = revokedUrl?.replaceFirst('https://', '');
    return DashedRRectBorder(
      color: AppColors.surfaceBorder,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.base),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (url != null)
              Text(
                url,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.mono.copyWith(
                  fontSize: 12,
                  letterSpacing: 0,
                  color: AppColors.textTertiary,
                  decoration: TextDecoration.lineThrough,
                  decorationColor: AppColors.textTertiary,
                ),
              ),
            const SizedBox(height: 6),
            Text(
              l10n.share_revokedLine,
              style: AppTypography.caption.copyWith(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton(
              key: const ValueKey('share-new-link'),
              onPressed: isBusy ? null : onNewLink,
              child: Text(l10n.share_newLink),
            ),
          ],
        ),
      ),
    );
  }
}

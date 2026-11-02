import 'package:flutter/material.dart';

import '../../../../core/l10n/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../trip/presentation/widgets/trip_cover_image.dart';

/// Cover thumb + `Share "{title}"` + whether a link is live (#311, 1a).
class ShareSheetHeader extends StatelessWidget {
  const ShareSheetHeader({
    required this.title,
    required this.coverPath,
    required this.isLive,
    super.key,
  });

  final String title;
  final String? coverPath;
  final bool isLive;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox.square(
            dimension: 46,
            child: TripCoverImage(imagePath: coverPath),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.share_title(title),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.serif(
                  fontSize: 20,
                  height: 1.2,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isLive ? l10n.share_subLive : l10n.share_subNone,
                style: AppTypography.caption.copyWith(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Share… · QR code · Story card. A null callback = disabled (link loading).
class ShareTiles extends StatelessWidget {
  const ShareTiles({
    required this.onShare,
    required this.onQr,
    required this.onStory,
    super.key,
  });

  final VoidCallback? onShare;
  final VoidCallback? onQr;
  final VoidCallback? onStory;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Tile(
            icon: Icons.ios_share,
            label: l10n.share_system,
            onTap: onShare,
          ),
          const SizedBox(width: AppSpacing.sm),
          _Tile(icon: Icons.qr_code_2, label: l10n.share_qr, onTap: onQr),
          const SizedBox(width: AppSpacing.sm),
          _Tile(
            icon: Icons.crop_portrait,
            label: l10n.share_story,
            onTap: onStory,
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final color = enabled ? AppColors.textPrimary : AppColors.textTertiary;
    const radius = BorderRadius.all(Radius.circular(16));
    return Expanded(
      child: Material(
        color: AppColors.tint(AppColors.background, .6),
        shape: const RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: AppColors.hairline),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 14, 6, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 22, color: color),
                const SizedBox(height: 6),
                // At 360pt a long RU label wraps to two lines, never truncates.
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: AppTypography.caption.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// What a link shows — and never shows.
class ShareWhatPeopleSee extends StatelessWidget {
  const ShareWhatPeopleSee({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.share_whatSee.toUpperCase(),
          style: AppTypography.mono.copyWith(color: AppColors.textTertiary),
        ),
        const SizedBox(height: 10),
        _SeeRow(text: l10n.share_seeCover, included: true),
        _SeeRow(text: l10n.share_seePhotos, included: true),
        _SeeRow(text: l10n.share_seeNever, included: false),
      ],
    );
  }
}

class _SeeRow extends StatelessWidget {
  const _SeeRow({required this.text, required this.included});

  final String text;
  final bool included;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: included ? AppColors.primaryTint : null,
              border: included
                  ? null
                  : Border.all(color: AppColors.textTertiary),
            ),
            child: Icon(
              included ? Icons.check : Icons.close,
              size: 11,
              color: included ? AppColors.primary : AppColors.textTertiary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTypography.caption.copyWith(
                fontSize: 13,
                color: included
                    ? AppColors.textSecondary
                    : AppColors.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Couldn't make a link. Try again" — tap to retry.
class ShareSheetError extends StatelessWidget {
  const ShareSheetError({required this.onRetry, super.key});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.accentCoralTint,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        key: const ValueKey('share-retry'),
        onTap: onRetry,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Icon(Icons.refresh, size: 18, color: AppColors.accentCoral),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.l10n.share_error,
                  style: AppTypography.caption.copyWith(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

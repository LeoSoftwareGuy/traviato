import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/l10n/context_l10n.dart';
import '../../../../core/l10n/l10n_dates.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/shared_memory_preview.dart';

/// The in-app teaser's cover (#310, design 2c): ✕ and "{name} shared
/// this" over the photo, eyebrow / title / meta at the bottom.
class SharedMemoryHero extends StatelessWidget {
  const SharedMemoryHero({
    required this.preview,
    required this.onClose,
    super.key,
  });

  static const double height = 360;

  final SharedMemoryPreview preview;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final top = MediaQuery.paddingOf(context).top;
    final eyebrow = [
      ?preview.destination,
      L10nDates.dateRange(preview.startDate, preview.endDate, l10n.localeName),
    ].join(' · ');
    final meta = [
      l10n.common_dayCount(preview.dayCount),
      if (preview.photoCount > 0) l10n.common_photoCount(preview.photoCount),
      if (preview.hasFilm) l10n.share_metaFilm,
    ].join(' · ');
    final cover = preview.coverUrl;

    return SizedBox(
      height: height + top,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (cover != null)
            CachedNetworkImage(imageUrl: cover, fit: BoxFit.cover)
          else
            const ColoredBox(color: AppColors.background50),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: AppGradients.keptMemoryHeroScrim,
            ),
          ),
          Positioned(
            top: top + 10,
            left: 18,
            right: 18,
            child: Row(
              children: [
                SharedMemoryRoundButton(
                  key: const Key('shared-memory-close'),
                  icon: Icons.close,
                  semanticLabel: MaterialLocalizations.of(
                    context,
                  ).closeButtonTooltip,
                  onTap: onClose,
                ),
                const Spacer(),
                if (preview.ownerName case final name?)
                  _OwnerPill(name: name, avatarUrl: preview.ownerAvatarUrl),
              ],
            ),
          ),
          Positioned(
            left: 22,
            right: 22,
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  eyebrow.toUpperCase(),
                  style: AppTypography.mono.copyWith(
                    color: AppColors.primaryLight,
                    letterSpacing: AppTypography.eyebrowTracking(9.5),
                  ),
                ),
                const SizedBox(height: 6),
                // User content — shown exactly as written.
                Text(
                  preview.title,
                  style: AppTypography.serif(
                    fontSize: 34,
                    height: 1.05,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  meta.toUpperCase(),
                  style: AppTypography.mono.copyWith(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OwnerPill extends StatelessWidget {
  const _OwnerPill({required this.name, this.avatarUrl});

  final String name;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: ColoredBox(
          color: AppColors.tint(AppColors.background, .6),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(7, 7, 12, 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OwnerAvatar(name: name, url: avatarUrl, size: 20),
                const SizedBox(width: 8),
                Text(
                  context.l10n.share_ownerShared(name),
                  style: AppTypography.bodyEmphasis.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The owner's picture, or their initial on purple.
class OwnerAvatar extends StatelessWidget {
  const OwnerAvatar({
    required this.name,
    required this.size,
    this.url,
    super.key,
  });

  final String name;
  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initial = name.characters.first.toUpperCase();
    return ClipOval(
      child: SizedBox.square(
        dimension: size,
        child: url == null
            ? ColoredBox(
                color: AppColors.accentPurple,
                child: Center(
                  child: Text(
                    initial,
                    style: AppTypography.bodyEmphasis.copyWith(
                      fontSize: size * .48,
                      fontWeight: FontWeight.w600,
                      height: 1,
                    ),
                  ),
                ),
              )
            : CachedNetworkImage(imageUrl: url!, fit: BoxFit.cover),
      ),
    );
  }
}

/// 38px round glass button over a cover.
class SharedMemoryRoundButton extends StatelessWidget {
  const SharedMemoryRoundButton({
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Material(
          color: AppColors.tint(AppColors.background, .6),
          child: InkWell(
            onTap: onTap,
            child: SizedBox.square(
              dimension: 38,
              child: Icon(
                icon,
                size: 18,
                color: AppColors.textPrimary,
                semanticLabel: semanticLabel,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Five teaser photos, the last three blurred (design 2c). Not tappable.
class SharedMemoryStrip extends StatelessWidget {
  const SharedMemoryStrip({required this.photoUrls, super.key});

  static const _widths = [150.0, 96.0, 120.0, 96.0, 150.0];
  static const clearCount = 2;

  final List<String> photoUrls;

  @override
  Widget build(BuildContext context) {
    final photos = photoUrls.take(_widths.length).toList();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Row(
        children: [
          for (final (i, url) in photos.indexed) ...[
            if (i > 0) const SizedBox(width: 5),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: _widths[i],
                height: 132,
                child: TeaserPhoto(url: url, blurred: i >= clearCount),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A teaser photo; past the first two it's blurred and darkened, the same
/// as on the web page (`blur(10px) brightness(.55)`, scaled 1.15).
class TeaserPhoto extends StatelessWidget {
  const TeaserPhoto({required this.url, required this.blurred, super.key});

  final String url;
  final bool blurred;

  @override
  Widget build(BuildContext context) {
    final image = CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (_, _) => const ColoredBox(color: AppColors.surface),
      errorWidget: (_, _, _) => const ColoredBox(color: AppColors.surface),
    );
    if (!blurred) return image;
    return Stack(
      fit: StackFit.expand,
      children: [
        Transform.scale(
          scale: 1.15,
          child: ImageFiltered(
            key: const Key('teaser-photo-blurred'),
            imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: image,
          ),
        ),
        ColoredBox(color: Colors.black.withValues(alpha: .45)),
      ],
    );
  }
}

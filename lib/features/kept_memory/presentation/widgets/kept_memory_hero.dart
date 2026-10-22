import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/l10n/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../trip/presentation/widgets/trip_cover_image.dart';
import '../../domain/entities/kept_memory.dart';
import '../kept_memory_labels.dart';

/// The Kept Memory page's 330-tall cover (#279, spec § 3.1): back and ⋯
/// over the photo, then eyebrow, title and counts at the bottom left.
class KeptMemoryHero extends StatelessWidget {
  const KeptMemoryHero({
    required this.memory,
    required this.onBack,
    required this.onMore,
    super.key,
  });

  static const double height = 330;

  final KeptMemory memory;
  final VoidCallback onBack;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final trip = memory.trip;
    final locale = context.l10n.localeName;
    final start = trip.startDate;
    final end = trip.endDate;
    final eyebrow = [
      if (trip.isKeptForever) context.l10n.home_keptForever,
      if (start != null && end != null)
        KeptMemoryLabels.dateRange(start, end, locale),
    ].join(' · ');
    final meta = KeptMemoryLabels.meta(memory, context.l10n);

    return SizedBox(
      height: height + MediaQuery.paddingOf(context).top,
      child: Stack(
        fit: StackFit.expand,
        children: [
          TripCoverImage(imagePath: trip.coverImagePath),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: AppGradients.keptMemoryHeroScrim,
            ),
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 10,
            left: 22,
            right: 22,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _HeroRoundButton(
                  key: const Key('kept-memory-back'),
                  icon: Icons.arrow_back,
                  semanticLabel: MaterialLocalizations.of(
                    context,
                  ).backButtonTooltip,
                  onTap: onBack,
                ),
                _HeroRoundButton(
                  key: const Key('kept-memory-more'),
                  icon: Icons.more_horiz,
                  semanticLabel: context.l10n.keptMemory_more,
                  onTap: onMore,
                ),
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
                if (eyebrow.isNotEmpty)
                  Text(
                    eyebrow.toUpperCase(),
                    style: AppTypography.mono.copyWith(
                      color: AppColors.primaryLight,
                    ),
                  ),
                const SizedBox(height: 8),
                // User content — shown exactly as written.
                Text(
                  trip.name,
                  style: AppTypography.serif(
                    fontSize: 34,
                    height: 1.05,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    meta.toUpperCase(),
                    style: AppTypography.mono.copyWith(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 38px round button over the cover — background-tinted glass.
class _HeroRoundButton extends StatelessWidget {
  const _HeroRoundButton({
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

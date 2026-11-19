import 'package:flutter/material.dart';

import '../../../../core/l10n/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/photo_scrim.dart';
import '../../../trip/domain/entities/trip_card_entity.dart';
import '../../../trip/presentation/widgets/trip_cover_image.dart';
import 'trip_card_pill.dart';

/// Gap between the grid's two columns (and its rows).
const double memoryGridGap = AppSpacing.md;

/// The tiles' width ÷ height (the original 161.5 × 160 tile).
const double _tileAspectRatio = 161.5 / 160;

/// "Kept forever" grid: finished trips. Where a tap goes is the page's
/// call — Journal for a memory not kept yet (#101), the Kept Memory page
/// for a kept one (#279).
/// `docs/design/README.md` § 3.
class MemoriesGridSection extends StatelessWidget {
  const MemoriesGridSection({
    required this.trips,
    required this.onTripTap,
    required this.onTripLongPress,
    super.key,
  });

  final List<TripCardEntity> trips;
  final ValueChanged<TripCardEntity> onTripTap;
  // Opens the delete-only sheet for that trip (issue #115).
  final ValueChanged<TripCardEntity> onTripLongPress;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.home_keptForever.toUpperCase(),
          style: AppTypography.mono.copyWith(color: AppColors.textTertiary),
        ),
        const SizedBox(height: AppSpacing.base),
        if (trips.isEmpty)
          Text(
            context.l10n.home_keptForeverEmpty,
            style: AppTypography.chipLabel.copyWith(
              color: AppColors.textMuted,
            ),
          )
        else
          // Two columns that fill the page's own side padding, so the left
          // and right gaps match on every phone (#424).
          Column(
            children: [
              for (var i = 0; i < trips.length; i += 2) ...[
                if (i > 0) const SizedBox(height: memoryGridGap),
                Row(
                  children: [
                    for (var j = i; j < i + 2; j++) ...[
                      if (j > i) const SizedBox(width: memoryGridGap),
                      Expanded(
                        child: AspectRatio(
                          aspectRatio: _tileAspectRatio,
                          child: j < trips.length
                              ? _MemoryGridCard(
                                  trip: trips[j],
                                  onTap: () => onTripTap(trips[j]),
                                  onLongPress: () => onTripLongPress(trips[j]),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
      ],
    );
  }
}

class _MemoryGridCard extends StatelessWidget {
  const _MemoryGridCard({
    required this.trip,
    required this.onTap,
    required this.onLongPress,
  });

  final TripCardEntity trip;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: AppRadius.mediaRadius,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: AppRadius.mediaRadius,
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: PhotoScrim(
          image: TripCoverImage(imagePath: trip.coverImagePath),
          child: Stack(
            children: [
              Positioned(
                top: AppSpacing.sm,
                left: AppSpacing.sm,
                child: TripCardPill(
                  color: trip.isKeptForever
                      ? AppColors.tint(AppColors.primary, .62)
                      : AppColors.tint(AppColors.background, .62),
                  child: Text(
                    trip.isKeptForever
                        ? '✦ ${context.l10n.home_keptForever}'
                        : '▸ ${context.l10n.home_recap}',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textOnPhoto,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trip.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.screenTitle.copyWith(
                          fontSize: 15,
                          color: AppColors.textOnPhoto,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '${context.l10n.common_dayCount(trip.durationDays ?? 0)} · '
                                '${context.l10n.common_photoCount(trip.photoCount)}'
                            .toUpperCase(),
                        style: AppTypography.mono.copyWith(
                          color: AppColors.textOnPhotoMuted,
                        ),
                      ),
                    ],
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

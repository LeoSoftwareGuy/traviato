import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/photo_scrim.dart';
import '../../../trip/domain/entities/trip_card_entity.dart';
import '../../../trip/presentation/widgets/trip_cover_image.dart';
import 'trip_card_pill.dart';

/// "Kept forever" grid: finished trips, tapping into the Wrap-up placeholder.
/// `docs/design/README.md` § 3.
class MemoriesGridSection extends StatelessWidget {
  const MemoriesGridSection({
    required this.trips,
    required this.onTripTap,
    super.key,
  });

  final List<TripCardEntity> trips;
  final ValueChanged<TripCardEntity> onTripTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'KEPT FOREVER',
          style: AppTypography.mono.copyWith(color: AppColors.textTertiary),
        ),
        const SizedBox(height: AppSpacing.base),
        if (trips.isEmpty)
          Text(
            'No memories logged yet — they show up here once a trip wraps.',
            style: AppTypography.chipLabel.copyWith(
              color: AppColors.textMuted,
            ),
          )
        else
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              for (final trip in trips)
                _MemoryGridCard(trip: trip, onTap: () => onTripTap(trip)),
            ],
          ),
      ],
    );
  }
}

class _MemoryGridCard extends StatelessWidget {
  const _MemoryGridCard({required this.trip, required this.onTap});

  final TripCardEntity trip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.mediaRadius,
      child: Container(
        width: 161.5,
        height: 160,
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
                  color: AppColors.tint(AppColors.background, .62),
                  child: Text(
                    '▸ Recap',
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
                        '${trip.durationDays ?? 0} DAYS · ${trip.photoCount} PHOTOS',
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

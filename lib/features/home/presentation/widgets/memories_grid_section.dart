import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../trip/domain/entities/trip_card_entity.dart';
import 'trip_card_pill.dart';
import '../../../trip/presentation/widgets/trip_cover_image.dart';
import 'trip_date_format.dart';

/// "Memories" grid: finished trips with a Recap badge, duration and photo
/// count.
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
        Text('Memories', style: AppTypography.headlineSerif),
        const SizedBox(height: 2),
        Text(
          "Journals you've kept forever",
          style: AppTypography.chipLabel.copyWith(color: AppColors.textMuted),
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
      borderRadius: AppRadius.cardRadius,
      child: ClipRRect(
        borderRadius: AppRadius.cardRadius,
        child: Container(
          width: 161.5,
          height: 201.875,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              TripCoverImage(imagePath: trip.coverImagePath),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      AppColors.backgroundScrim,
                      AppColors.background,
                    ],
                    stops: [0.0, 0.5, 1.0],
                  ),
                ),
              ),
              Positioned(
                top: AppSpacing.sm,
                left: AppSpacing.sm,
                child: TripCardPill(
                  color: AppColors.backgroundScrim,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.movie_creation_outlined,
                        color: AppColors.textOnPhoto,
                        size: 12,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'Recap',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textOnPhoto,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (trip.durationDays != null)
                Positioned(
                  top: AppSpacing.sm,
                  right: AppSpacing.sm,
                  child: TripCardPill(
                    color: AppColors.accentCoral,
                    child: Text(
                      '${trip.durationDays} ${trip.durationDays == 1 ? 'day' : 'days'}',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.background,
                        letterSpacing: 0,
                        fontWeight: FontWeight.w700,
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
                        style: AppTypography.headlineSerif.copyWith(
                          fontSize: 15,
                          color: AppColors.textOnPhoto,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        tripDateRangeLabel(trip.startDate, trip.endDate),
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textOnPhotoMuted,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          const Icon(
                            Icons.camera_alt_outlined,
                            color: AppColors.textOnPhotoMuted,
                            size: 12,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            '${trip.photoCount}',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textOnPhotoMuted,
                              letterSpacing: 0,
                            ),
                          ),
                        ],
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

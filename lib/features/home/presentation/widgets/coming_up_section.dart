import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../trip/domain/entities/trip_card_entity.dart';
import 'trip_card_pill.dart';
import '../../../trip/presentation/widgets/trip_cover_image.dart';
import 'trip_date_format.dart';

/// "Coming up" horizontal row: remaining current/upcoming trips (the hero
/// trip is shown separately) plus a trailing create-memory CTA card.
class ComingUpSection extends StatelessWidget {
  const ComingUpSection({
    required this.trips,
    required this.onTripTap,
    required this.onCreateMemoryTap,
    super.key,
  });

  final List<TripCardEntity> trips;
  final ValueChanged<TripCardEntity> onTripTap;
  final VoidCallback onCreateMemoryTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Coming up', style: AppTypography.headlineSerif),
        const SizedBox(height: 2),
        Text(
          trips.isEmpty
              ? 'Plan your next memory'
              : '${trips.length} ${trips.length == 1 ? 'memory' : 'memories'} in the making',
          style: AppTypography.chipLabel.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: AppSpacing.base),
        SizedBox(
          height: 280,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: trips.length + 1,
            separatorBuilder: (context, index) =>
                const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, index) {
              if (index == trips.length) {
                return _CreateMemoryCard(onTap: onCreateMemoryTap);
              }
              final trip = trips[index];
              return _UpcomingListCard(
                trip: trip,
                onTap: () => onTripTap(trip),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _UpcomingListCard extends StatelessWidget {
  const _UpcomingListCard({required this.trip, required this.onTap});

  final TripCardEntity trip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.mediaRadius,
      child: ClipRRect(
        borderRadius: AppRadius.mediaRadius,
        child: Container(
          width: 210,
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
              if (trip.vibes.isNotEmpty)
                Positioned(
                  top: AppSpacing.sm,
                  left: AppSpacing.sm,
                  child: TripCardPill(
                    color: AppColors.primary,
                    child: Text(
                      trip.vibes.first,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.background,
                        letterSpacing: 0,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              if (trip.startDate != null)
                Positioned(
                  top: AppSpacing.sm,
                  right: AppSpacing.sm,
                  child: TripCardPill(
                    color: AppColors.backgroundScrim,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.schedule,
                          color: AppColors.textOnPhoto,
                          size: 12,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          tripCountdownLabel(trip.startDate!),
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textOnPhoto,
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trip.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.headlineSerif.copyWith(
                          fontSize: 17,
                          color: AppColors.textOnPhoto,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          if (trip.destination != null)
                            Expanded(
                              child: Text(
                                trip.destination!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textOnPhotoMuted,
                                  letterSpacing: 0,
                                ),
                              ),
                            ),
                          Text(
                            tripDateRangeLabel(trip.startDate, trip.endDate),
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

class _CreateMemoryCard extends StatelessWidget {
  const _CreateMemoryCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.mediaRadius,
      child: Container(
        width: 210,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surfaceDisabled,
          borderRadius: AppRadius.mediaRadius,
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: AppColors.background),
            ),
            const SizedBox(height: AppSpacing.base),
            Text(
              'Capture a new memory',
              textAlign: TextAlign.center,
              style: AppTypography.headlineSerif.copyWith(fontSize: 15),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'A moment worth keeping',
              style: AppTypography.caption.copyWith(letterSpacing: 0),
            ),
          ],
        ),
      ),
    );
  }
}

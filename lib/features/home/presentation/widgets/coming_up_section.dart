import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/photo_scrim.dart';
import '../../../quest/presentation/providers/quest_providers.dart';
import '../../../trip/domain/entities/trip_card_entity.dart';
import '../../../trip/presentation/widgets/trip_cover_image.dart';
import 'trip_card_pill.dart';
import 'trip_date_format.dart';

/// "Coming up" horizontal row: remaining current/upcoming trips (the hero
/// trip is shown separately) plus a trailing create-memory CTA card. The
/// whole card taps into Plan for that memory. `docs/design/README.md` § 3.
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
        Text(
          'COMING UP',
          style: AppTypography.mono.copyWith(color: AppColors.textTertiary),
        ),
        const SizedBox(height: AppSpacing.base),
        SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: trips.length + 1,
            separatorBuilder: (context, index) =>
                const SizedBox(width: AppSpacing.sm),
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

class _UpcomingListCard extends ConsumerWidget {
  const _UpcomingListCard({required this.trip, required this.onTap});

  final TripCardEntity trip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questCount = ref.watch(questCountForTripProvider(trip.id)).value;

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.mediaRadius,
      child: Container(
        width: 150,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: AppRadius.mediaRadius,
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: PhotoScrim(
          image: TripCoverImage(imagePath: trip.coverImagePath),
          child: Stack(
            children: [
              if (trip.startDate != null)
                Positioned(
                  top: AppSpacing.sm,
                  right: AppSpacing.sm,
                  child: TripCardPill(
                    color: AppColors.primary,
                    child: Text(
                      tripCountdownLabel(trip.startDate!),
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
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trip.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.screenTitle.copyWith(
                          fontSize: 16,
                          color: AppColors.textOnPhoto,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        tripDateRangeLabel(trip.startDate, trip.endDate),
                        style: AppTypography.mono.copyWith(
                          color: AppColors.textOnPhotoMuted,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              questCount == null
                                  ? ''
                                  : questCount > 0
                                  ? '$questCount quests planned'
                                  : 'Nothing planned yet',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.chipLabel.copyWith(
                                color: (questCount ?? 0) > 0
                                    ? AppColors.primary
                                    : AppColors.textOnPhotoMuted,
                                fontWeight: FontWeight.w600,
                                fontSize: 9.5,
                              ),
                            ),
                          ),
                          Text(
                            'Plan →',
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
        width: 150,
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
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: AppColors.background),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Capture a new memory',
              textAlign: TextAlign.center,
              style: AppTypography.screenTitle.copyWith(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../core/l10n/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../home/presentation/widgets/trip_date_format.dart';
import '../../../trip/domain/entities/trip_card_entity.dart';
import '../../../trip/presentation/widgets/trip_cover_image.dart';
import '../../../trip/presentation/widgets/vibe_label.dart';

/// The memory whose first day opens the next tray (#219 Phase 3): cover,
/// title, "21–24 OCT · 4 DAYS · FOODIE", quests planned · Plan →.
class UpcomingMemoryCard extends StatelessWidget {
  const UpcomingMemoryCard({
    required this.trip,
    required this.onTap,
    super.key,
  });

  static const _radius = BorderRadius.all(Radius.circular(20));

  final TripCardEntity trip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final meta = [
      tripDateRangeLabel(l10n, trip.startDate, trip.endDate),
      if (trip.durationDays case final days?) l10n.common_dayCount(days),
      if (trip.vibes.isNotEmpty) vibeLabel(l10n, trip.vibes.first),
    ].join(' · ');
    final secondary = AppTypography.bodyEmphasis.copyWith(
      fontSize: 10.5,
      fontWeight: FontWeight.w600,
      color: AppColors.textSecondary,
    );

    return Material(
      color: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: _radius,
        side: BorderSide(color: AppColors.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 96,
                child: TripCoverImage(imagePath: trip.coverImagePath),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trip.name,
                        style: AppTypography.serif(
                          fontSize: 17,
                          height: 1.2,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        meta.toUpperCase(),
                        style: AppTypography.mono.copyWith(letterSpacing: 0),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              trip.questCount > 0
                                  ? l10n.home_questsPlanned(trip.questCount)
                                  : l10n.home_nothingPlanned,
                              style: secondary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.home_planArrow,
                            style: secondary.copyWith(
                              fontSize: 11,
                              color: AppColors.primary,
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

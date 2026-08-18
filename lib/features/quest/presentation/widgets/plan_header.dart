import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../trip/domain/entities/trip_card_entity.dart';
import '../../../trip/presentation/widgets/trip_cover_image.dart';
import '../../../trip/presentation/widgets/trip_images.dart';
import 'plan_background_glow.dart';

/// Back button + memory name/place (over an ambient glow), and the cover
/// photo below it.
class PlanHeader extends StatelessWidget {
  const PlanHeader({required this.trip, required this.onBack, super.key});

  final TripCardEntity trip;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: PlanBackgroundGlow(),
            ),
            Row(
              children: [
                IconButton(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        trip.name,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.headlineSerif,
                      ),
                      if (trip.destination != null)
                        Text(
                          trip.destination!,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption.copyWith(
                            letterSpacing: 0,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.base),
        ClipRRect(
          borderRadius: AppRadius.mediaRadius,
          child: Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: trip.coverImagePath != null
                ? TripCoverImage(imagePath: trip.coverImagePath)
                : Image.asset(TripImages.planner, fit: BoxFit.cover),
          ),
        ),
      ],
    );
  }
}

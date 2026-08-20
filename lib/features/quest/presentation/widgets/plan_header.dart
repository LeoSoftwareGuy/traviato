import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../trip/domain/entities/trip_card_entity.dart';
import '../../../trip/presentation/widgets/trip_cover_image.dart';
import '../../../trip/presentation/widgets/trip_images.dart';

/// Back button + memory name/place, and the cover photo below it.
class PlanHeader extends StatelessWidget {
  const PlanHeader({
    required this.trip,
    required this.onBack,
    required this.onChecklistTap,
    super.key,
  });

  final TripCardEntity trip;
  final VoidCallback onBack;
  final VoidCallback onChecklistTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back)),
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
                      style: AppTypography.caption.copyWith(letterSpacing: 0),
                    ),
                ],
              ),
            ),
            IconButton(
              key: const Key('plan-checklist-action'),
              onPressed: onChecklistTap,
              icon: const Icon(Icons.checklist_outlined),
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

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/photo_scrim.dart';
import '../../../trip/domain/entities/trip_card_entity.dart';
import 'trip_date_range_mono.dart';

/// Back / mono `THE PLAN` / ☑ Checklist / ⋯ Manage, the trip name + Edit
/// link, and the cover banner. `docs/design/README.md` § 5.
class PlanHeader extends StatelessWidget {
  const PlanHeader({
    required this.trip,
    required this.currentDayNumber,
    required this.totalDays,
    required this.onBack,
    required this.onChecklistTap,
    required this.onManageTap,
    super.key,
  });

  final TripCardEntity trip;
  final int? currentDayNumber;
  final int totalDays;
  final VoidCallback onBack;
  final VoidCallback onChecklistTap;
  final VoidCallback onManageTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _IconButton(icon: Icons.arrow_back, onTap: onBack),
            Expanded(
              child: Center(
                child: Text(
                  'THE PLAN',
                  style: AppTypography.mono.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
            ),
            _IconButton(
              key: const Key('plan-checklist-action'),
              icon: Icons.checklist_outlined,
              onTap: onChecklistTap,
              iconColor: AppColors.primary,
            ),
            const SizedBox(width: AppSpacing.sm),
            _IconButton(
              key: const Key('plan-manage-action'),
              icon: Icons.more_horiz,
              onTap: onManageTap,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.base),
        Row(
          children: [
            Expanded(
              child: Text(
                trip.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.screenTitle.copyWith(fontSize: 27),
              ),
            ),
            InkWell(
              onTap: onManageTap,
              borderRadius: AppRadius.badgeRadius,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xs),
                child: Text(
                  'Edit',
                  style: AppTypography.chipLabel.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.base),
        Container(
          height: 118,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: AppRadius.mediaRadius,
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: PhotoScrim(
            image: Image.asset(
              'assets/images/journal/balloons_wide.png',
              fit: BoxFit.cover,
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tripDateRangeMono(trip.startDate, trip.endDate),
                          style: AppTypography.mono.copyWith(
                            color: AppColors.primaryLight,
                          ),
                        ),
                        if (trip.destination != null)
                          Text(
                            trip.destination!,
                            style: AppTypography.screenTitle.copyWith(
                              fontSize: 16,
                              color: AppColors.textOnPhoto,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (currentDayNumber != null)
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.tint(AppColors.background, .62),
                          borderRadius: AppRadius.pillRadius,
                        ),
                        child: Text(
                          'Day $currentDayNumber of $totalDays',
                          style: AppTypography.chipLabel.copyWith(
                            color: AppColors.textOnPhoto,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({
    required this.icon,
    required this.onTap,
    this.iconColor,
    super.key,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.badgeRadius,
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.surfaceBorder),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(
          icon,
          size: 18,
          color: iconColor ?? AppColors.textSecondary,
        ),
      ),
    );
  }
}

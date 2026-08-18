import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../trip/domain/entities/trip_card_entity.dart';
import 'trip_cover_image.dart';
import 'trip_date_format.dart';

/// Featured "Up next" card for the single soonest current/upcoming trip
/// (Figma "Home screen 2" hero). The shortcuts open Plan/Checklist/Journal
/// for that trip.
class UpcomingHeroCard extends StatelessWidget {
  const UpcomingHeroCard({
    required this.trip,
    required this.onPlanTap,
    required this.onChecklistTap,
    required this.onJournalTap,
    super.key,
  });

  final TripCardEntity trip;
  final VoidCallback onPlanTap;
  final VoidCallback onChecklistTap;
  final VoidCallback onJournalTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.mediaRadius,
      child: Container(
        height: 382,
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
                  stops: [0.0, 0.4, 0.95],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.base),
              child: _TopBadgeRow(trip: trip),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: _HeroContent(
                trip: trip,
                onPlanTap: onPlanTap,
                onChecklistTap: onChecklistTap,
                onJournalTap: onJournalTap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBadgeRow extends StatelessWidget {
  const _TopBadgeRow({required this.trip});

  final TripCardEntity trip;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'Up next',
              style: AppTypography.chipLabel.copyWith(
                color: AppColors.textOnPhoto,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        if (trip.startDate != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.schedule,
                color: AppColors.textOnPhotoMuted,
                size: 14,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                tripCountdownLabel(trip.startDate!),
                style: AppTypography.chipLabel.copyWith(
                  color: AppColors.textOnPhoto,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _HeroContent extends StatelessWidget {
  const _HeroContent({
    required this.trip,
    required this.onPlanTap,
    required this.onChecklistTap,
    required this.onJournalTap,
  });

  final TripCardEntity trip;
  final VoidCallback onPlanTap;
  final VoidCallback onChecklistTap;
  final VoidCallback onJournalTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            trip.name,
            style: AppTypography.headlineSerif.copyWith(
              fontSize: 22,
              color: AppColors.textOnPhoto,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              if (trip.destination != null) ...[
                const Icon(
                  Icons.place_outlined,
                  color: AppColors.textOnPhotoMuted,
                  size: 14,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  trip.destination!,
                  style: AppTypography.chipLabel.copyWith(
                    color: AppColors.textOnPhotoMuted,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
              ],
              Text(
                tripDateRangeLabel(trip.startDate, trip.endDate),
                style: AppTypography.chipLabel.copyWith(
                  color: AppColors.textOnPhotoMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(color: AppColors.surfaceBorder, height: 1),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _ShortcutButton(
                  icon: Icons.map_outlined,
                  label: 'Plan',
                  onTap: onPlanTap,
                ),
              ),
              Expanded(
                child: _ShortcutButton(
                  icon: Icons.checklist_outlined,
                  label: 'Checklist',
                  onTap: onChecklistTap,
                ),
              ),
              Expanded(
                child: _ShortcutButton(
                  icon: Icons.menu_book_outlined,
                  label: 'Journal',
                  onTap: onJournalTap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ShortcutButton extends StatelessWidget {
  const _ShortcutButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.badgeRadius,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.textOnPhoto, size: 18),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: AppColors.textOnPhoto,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

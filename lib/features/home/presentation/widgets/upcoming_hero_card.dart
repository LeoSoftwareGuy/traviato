import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/dashed_rrect_border.dart';
import '../../../../core/widgets/photo_scrim.dart';
import '../../../checklist/presentation/providers/checklist_providers.dart';
import '../../../trip/domain/entities/trip_card_entity.dart';
import '../../../trip/presentation/widgets/trip_cover_image.dart';
import 'trip_card_pill.dart';
import 'trip_date_format.dart';

/// "Happening now" hero for the single soonest current/upcoming trip.
/// `docs/design/README.md` § 3.
class UpcomingHeroCard extends ConsumerWidget {
  const UpcomingHeroCard({
    required this.trip,
    required this.onPlanTap,
    required this.onChecklistTap,
    required this.onJournalTap,
    required this.onAddExpenseTap,
    super.key,
  });

  final TripCardEntity trip;
  final VoidCallback onPlanTap;
  final VoidCallback onChecklistTap;
  final VoidCallback onJournalTap;
  final VoidCallback onAddExpenseTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(checklistProgressForTripProvider(trip.id)).value;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.mediaRadius,
        border: Border.all(color: AppColors.tint(AppColors.primary, .28)),
        boxShadow: [
          BoxShadow(
            color: AppColors.tint(Colors.black, .45),
            blurRadius: 46,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 206,
            width: double.infinity,
            child: PhotoScrim(
              warm: true,
              image: TripCoverImage(imagePath: trip.coverImagePath),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.base),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TopBadgeRow(trip: trip),
                    const Spacer(),
                    Text(
                      trip.name,
                      style: AppTypography.screenTitle.copyWith(
                        fontSize: 26,
                        height: 1.12,
                        color: AppColors.textOnPhoto,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    _SubtitleRow(trip: trip),
                    const SizedBox(height: AppSpacing.sm),
                    _TripProgressBar(fraction: _progressFraction(trip)),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.base),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.map_outlined,
                        label: 'Plan',
                        onTap: onPlanTap,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.receipt_long_outlined,
                        label: 'Expenses',
                        onTap: onAddExpenseTap,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.menu_book_outlined,
                        label: 'Journal',
                        onTap: onJournalTap,
                        primary: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                _ChecklistRow(
                  packed: progress?.packed ?? 0,
                  total: progress?.total ?? 0,
                  onTap: onChecklistTap,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static double _progressFraction(TripCardEntity trip) {
    final start = trip.startDate;
    final end = trip.endDate;
    if (trip.status != TripStatus.current || start == null || end == null) {
      return 0;
    }
    return tripProgressFraction(start, end);
  }
}

class _TopBadgeRow extends StatelessWidget {
  const _TopBadgeRow({required this.trip});

  final TripCardEntity trip;

  @override
  Widget build(BuildContext context) {
    final start = trip.startDate;
    final dayLabel =
        trip.status == TripStatus.current &&
            start != null &&
            trip.endDate != null
        ? tripDayOfLabel(start, trip.endDate!)
        : start != null
        ? tripCountdownLabel(start)
        : null;

    return Row(
      children: [
        if (dayLabel != null)
          TripCardPill(
            color: AppColors.tint(AppColors.background, .62),
            child: Text(
              dayLabel,
              style: AppTypography.chipLabel.copyWith(
                color: AppColors.primaryLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        if (trip.vibes.isNotEmpty) ...[
          const SizedBox(width: AppSpacing.xs),
          TripCardPill(
            color: AppColors.tint(AppColors.background, .62),
            child: Text(
              trip.vibes.first,
              style: AppTypography.chipLabel.copyWith(
                color: AppColors.textOnPhoto,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SubtitleRow extends StatelessWidget {
  const _SubtitleRow({required this.trip});

  final TripCardEntity trip;

  @override
  Widget build(BuildContext context) {
    final parts = [
      if (trip.destination != null) trip.destination!,
      tripDateRangeLabel(trip.startDate, trip.endDate),
    ];
    return Text(
      parts.join(' · '),
      style: AppTypography.chipLabel.copyWith(
        color: AppColors.textOnPhotoMuted,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _TripProgressBar extends StatelessWidget {
  const _TripProgressBar({required this.fraction});

  final double fraction;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.pillRadius,
      child: LinearProgressIndicator(
        value: fraction,
        minHeight: 4,
        backgroundColor: Colors.white.withValues(alpha: .2),
        valueColor: const AlwaysStoppedAnimation(AppColors.primary),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final fg = primary ? AppColors.background : AppColors.textPrimary;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.badgeRadius,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: primary ? AppColors.primary : AppColors.surfaceDisabled,
          borderRadius: AppRadius.badgeRadius,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: fg, size: 18),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: fg,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({
    required this.packed,
    required this.total,
    required this.onTap,
  });

  final int packed;
  final int total;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.badgeRadius,
      child: DashedRRectBorder(
        color: AppColors.tint(AppColors.textSecondary, .35),
        borderRadius: AppRadius.badgeRadius,
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.badgeRadius,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.base,
            vertical: AppSpacing.md,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Checklist', style: AppTypography.bodyEmphasis),
              Text(
                '$packed of $total packed →',
                style: AppTypography.chipLabel.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

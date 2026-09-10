import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
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
                      child: _ActionButton(label: 'Plan', onTap: onPlanTap),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: _ActionButton(
                        label: 'Expenses',
                        onTap: onAddExpenseTap,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: _ActionButton(
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

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.onTap,
    this.primary = false,
  });

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
        child: Center(
          child: Text(
            label,
            style: AppTypography.caption.copyWith(
              color: fg,
              letterSpacing: 0,
            ),
          ),
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
    final fraction = total == 0 ? 0.0 : (packed / total).clamp(0.0, 1.0);
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.badgeRadius,
      splashColor: AppColors.tint(AppColors.primary, .18),
      highlightColor: AppColors.tint(AppColors.primary, .1),
      child: ClipRRect(
        borderRadius: AppRadius.badgeRadius,
        child: Stack(
          children: [
            // Unfilled remainder — the button's current resting fill.
            Positioned.fill(
              child: ColoredBox(
                color: AppColors.tint(AppColors.surfaceBorder, .4),
              ),
            ),
            // Packed portion — same gradient as the Checklist screen's
            // progress bar (#111).
            Positioned.fill(
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: fraction,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppGradients.primaryCta,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.base,
                vertical: AppSpacing.md,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Checklist',
                    style: AppTypography.bodyEmphasis.copyWith(
                      color: AppColors.textOnPhoto,
                    ),
                  ),
                  Text(
                    '$packed of $total packed →',
                    // White rather than the accent color (#111) — the
                    // gradient fill can sit under either end of this text
                    // depending on progress, and white stays legible
                    // against both the fill and the resting background.
                    style: AppTypography.chipLabel.copyWith(
                      color: AppColors.textOnPhoto,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

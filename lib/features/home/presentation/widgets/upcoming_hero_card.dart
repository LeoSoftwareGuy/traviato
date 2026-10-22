import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/photo_scrim.dart';
import '../../../../core/widgets/shrink_to_floor_text.dart';
import '../../../checklist/presentation/providers/checklist_providers.dart';
import '../../../trip/domain/entities/trip_card_entity.dart';
import '../../../trip/presentation/widgets/trip_cover_image.dart';
import '../../../trip/presentation/widgets/vibe_label.dart';
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
    required this.onLongPress,
    super.key,
  });

  final TripCardEntity trip;
  final VoidCallback onPlanTap;
  final VoidCallback onChecklistTap;
  final VoidCallback onJournalTap;
  final VoidCallback onAddExpenseTap;
  // Opens the Manage-memory sheet (issue #115). The cover, buttons and
  // checklist row each own a tap; the long-press is the card's only
  // gesture, so it doesn't compete with them in the gesture arena.
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(checklistProgressForTripProvider(trip.id)).value;
    // Before the start day there's nothing to journal yet, so the cover is
    // the way into Plan and the Plan/Journal buttons go away. From the
    // start day on, the cover opens Journal and all three buttons show
    // (#287).
    final isUnderway = trip.status == TripStatus.current;

    return GestureDetector(
      onLongPress: () {
        Feedback.forLongPress(context);
        onLongPress();
      },
      child: Container(
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
            _CoverTapTarget(
              label: isUnderway
                  ? context.l10n.home_coverOpenJournal
                  : context.l10n.home_coverOpenPlan,
              onTap: isUnderway ? onJournalTap : onPlanTap,
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
                      if (isUnderway) ...[
                        Expanded(
                          child: _ActionButton(
                            label: context.l10n.home_actionPlan,
                            onTap: onPlanTap,
                          ),
                        ),
                        const SizedBox(width: 7),
                      ],
                      Expanded(
                        child: _ActionButton(
                          label: context.l10n.home_actionExpenses,
                          onTap: onAddExpenseTap,
                        ),
                      ),
                      if (isUnderway) ...[
                        const SizedBox(width: 7),
                        Expanded(
                          // The day's main action while the memory is
                          // happening (functionality.md § 3).
                          child: _ActionButton(
                            label: context.l10n.home_actionJournal,
                            onTap: onJournalTap,
                            primary: true,
                          ),
                        ),
                      ],
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
      ),
    );
  }
}

/// The 206-tall cover, tappable with an ink overlay painted above the
/// photo — an InkWell under the opaque image would never show.
class _CoverTapTarget extends StatelessWidget {
  const _CoverTapTarget({
    required this.label,
    required this.onTap,
    required this.child,
  });

  final String label;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: SizedBox(
        height: 206,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            child,
            Positioned.fill(
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: onTap,
                  splashColor: AppColors.tint(AppColors.primary, .18),
                  highlightColor: AppColors.tint(AppColors.background, .12),
                ),
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
    final start = trip.startDate;
    final dayLabel =
        trip.status == TripStatus.current &&
            start != null &&
            trip.endDate != null
        ? tripDayOfLabel(context.l10n, start, trip.endDate!)
        : start != null
        ? tripCountdownLabel(context.l10n, start)
        : null;

    // Wrap, not Row: a long day pill + vibe ("День 2 из 5" +
    // "Автопутешествие") moves to a second line instead of overflowing (#220).
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
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
          TripCardPill(
            color: AppColors.tint(AppColors.background, .62),
            child: Text(
              vibeLabel(context.l10n, trip.vibes.first),
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
      tripDateRangeLabel(context.l10n, trip.startDate, trip.endDate),
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
    // The fill lives on the Material, not a Container under the InkWell —
    // an opaque Container painted over the ink and hid every tap (#177).
    // Pressed tints match the Checklist row's below; on the primary fill an
    // accent tint wouldn't show, so it darkens instead.
    final pressTint = primary ? AppColors.background : AppColors.primary;
    return Material(
      color: primary ? AppColors.primary : AppColors.surfaceDisabled,
      borderRadius: AppRadius.badgeRadius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.tint(pressTint, .18),
        highlightColor: AppColors.tint(pressTint, .1),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          // Spec 4t "Home hero actions": shrink one step, then 2 lines.
          child: Center(
            child: ShrinkToFloorText(
              label,
              minFontSize: 9,
              maxLines: 2,
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(
                color: fg,
                letterSpacing: 0,
              ),
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
                    context.l10n.home_checklist,
                    style: AppTypography.bodyEmphasis.copyWith(
                      color: AppColors.textOnPhoto,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  // Flexible: the progress line wraps rather than overflows
                  // when the translation runs long (#220).
                  Flexible(
                    child: Text(
                      context.l10n.home_packedProgress(packed, total),
                      textAlign: TextAlign.end,
                      // White rather than the accent color (#111) — the
                      // gradient fill can sit under either end of this text
                      // depending on progress, and white stays legible
                      // against both the fill and the resting background.
                      style: AppTypography.chipLabel.copyWith(
                        color: AppColors.textOnPhoto,
                        fontWeight: FontWeight.w600,
                      ),
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

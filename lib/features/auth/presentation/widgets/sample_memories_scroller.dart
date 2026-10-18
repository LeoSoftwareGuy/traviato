import 'package:flutter/material.dart';

import '../../../../core/l10n/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/photo_scrim.dart';
import '../../../../core/widgets/shrink_to_floor_text.dart';
import 'guest_images.dart';

class _Moment {
  const _Moment({
    required this.imagePath,
    required this.title,
    required this.days,
    required this.photos,
  });

  final String imagePath;
  final String Function(AppLocalizations l10n) title;
  final int days;
  final int photos;
}

String _sampleTokyoTitle(AppLocalizations l) => l.guest_sampleTokyo;
String _sampleSoloTitle(AppLocalizations l) => l.guest_sampleSolo;
String _sampleAnniversaryTitle(AppLocalizations l) => l.guest_sampleAnniversary;
String _sampleGraduationTitle(AppLocalizations l) => l.guest_sampleGraduation;
String _sampleFoodTitle(AppLocalizations l) => l.guest_sampleFood;
String _sampleBucketListTitle(AppLocalizations l) => l.guest_sampleBucketList;

const _moments = [
  _Moment(
    imagePath: GuestImages.familyAdventure,
    title: _sampleTokyoTitle,
    days: 9,
    photos: 214,
  ),
  _Moment(
    imagePath: GuestImages.soloGetaway,
    title: _sampleSoloTitle,
    days: 4,
    photos: 96,
  ),
  _Moment(
    imagePath: GuestImages.anniversary,
    title: _sampleAnniversaryTitle,
    days: 3,
    photos: 86,
  ),
  _Moment(
    imagePath: GuestImages.graduation,
    title: _sampleGraduationTitle,
    days: 1,
    photos: 42,
  ),
  _Moment(
    imagePath: GuestImages.foodLoversWeekend,
    title: _sampleFoodTitle,
    days: 3,
    photos: 118,
  ),
  _Moment(
    imagePath: GuestImages.bucketListMoment,
    title: _sampleBucketListTitle,
    days: 1,
    photos: 27,
  ),
];

/// Sample memories horizontal scroller. `docs/design/README.md` § 1.
class SampleMemoriesScroller extends StatelessWidget {
  const SampleMemoriesScroller({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.guest_sampleMemoriesEyebrow.toUpperCase(),
          style: AppTypography.mono.copyWith(color: AppColors.primary),
        ),
        const SizedBox(height: AppSpacing.base),
        SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _moments.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) =>
                _MomentCard(moment: _moments[index]),
          ),
        ),
      ],
    );
  }
}

class _MomentCard extends StatelessWidget {
  const _MomentCard({required this.moment});

  final _Moment moment;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 132,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 88,
            width: 132,
            child: PhotoScrim(
              image: Image.asset(moment.imagePath, fit: BoxFit.cover),
              borderRadius: AppRadius.cardRadius,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  // Translated sample copy, not user content: shrinks, then
                  // wraps — no ellipsis (spec 4t).
                  child: ShrinkToFloorText(
                    moment.title(context.l10n),
                    minFontSize: 11,
                    maxLines: 2,
                    style: AppTypography.screenTitle.copyWith(
                      fontSize: 13,
                      color: AppColors.textOnPhoto,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${context.l10n.common_dayCount(moment.days)} · '
                    '${context.l10n.common_photoCount(moment.photos)}'
                .toUpperCase(),
            style: AppTypography.mono,
          ),
        ],
      ),
    );
  }
}

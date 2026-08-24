import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/photo_scrim.dart';
import 'guest_images.dart';

class _Moment {
  const _Moment({
    required this.imagePath,
    required this.title,
    required this.days,
    required this.photos,
  });

  final String imagePath;
  final String title;
  final int days;
  final int photos;
}

const _moments = [
  _Moment(
    imagePath: GuestImages.familyAdventure,
    title: 'Family trip to Tokyo',
    days: 9,
    photos: 214,
  ),
  _Moment(
    imagePath: GuestImages.soloGetaway,
    title: 'A solo getaway',
    days: 4,
    photos: 96,
  ),
  _Moment(
    imagePath: GuestImages.honeymoonEscape,
    title: 'Honeymoon',
    days: 11,
    photos: 348,
  ),
  _Moment(
    imagePath: GuestImages.epicMilestone,
    title: 'Graduation',
    days: 1,
    photos: 42,
  ),
  _Moment(
    imagePath: GuestImages.foodLoversWeekend,
    title: "A food lover's weekend",
    days: 3,
    photos: 118,
  ),
  _Moment(
    imagePath: GuestImages.bucketListMoment,
    title: 'A bucket-list moment',
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
          'A FEW MEMORIES, KEPT',
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
                  child: Text(
                    moment.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
            '${moment.days} DAYS · ${moment.photos} PHOTOS',
            style: AppTypography.mono,
          ),
        ],
      ),
    );
  }
}

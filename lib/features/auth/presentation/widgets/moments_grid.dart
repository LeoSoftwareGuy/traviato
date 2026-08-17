import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import 'guest_images.dart';

class _Moment {
  const _Moment({
    required this.imagePath,
    required this.title,
    required this.date,
  });

  final String imagePath;
  final String title;
  final String date;
}

const _moments = [
  _Moment(
    imagePath: GuestImages.familyAdventure,
    title: 'Family trip to Tokyo',
    date: '10.07.26-10.08.26',
  ),
  _Moment(
    imagePath: GuestImages.soloGetaway,
    title: 'A solo getaway',
    date: '13.04.26-15.04.26',
  ),
  _Moment(
    imagePath: GuestImages.honeymoonEscape,
    title: 'Honeymoon',
    date: '12.06.25-10.07.25',
  ),
  _Moment(
    imagePath: GuestImages.epicMilestone,
    title: 'Graduation',
    date: '10.06.25',
  ),
  _Moment(
    imagePath: GuestImages.foodLoversWeekend,
    title: "A food lover's weekend",
    date: '15.12.25',
  ),
  _Moment(
    imagePath: GuestImages.bucketListMoment,
    title: 'A bucket-list moment',
    date: '01.12.25',
  ),
];

/// Static sample gallery matching the "Moments worth capturing" section of
/// the guest landing frame.
class MomentsGrid extends StatelessWidget {
  const MomentsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MOMENTS WORTH CAPTURING',
          style: AppTypography.caption.copyWith(letterSpacing: 1.98),
        ),
        const SizedBox(height: AppSpacing.base),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final moment in _moments) _MomentTile(moment: moment),
          ],
        ),
      ],
    );
  }
}

class _MomentTile extends StatelessWidget {
  const _MomentTile({required this.moment});

  final _Moment moment;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 162.5,
      height: 160,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(moment.imagePath, fit: BoxFit.cover),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, AppColors.background],
                stops: [0.35, 1.0],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    moment.title,
                    style: AppTypography.chipLabel.copyWith(
                      color: AppColors.textOnPhoto,
                    ),
                  ),
                  Text(
                    moment.date,
                    style: AppTypography.caption.copyWith(letterSpacing: 0),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

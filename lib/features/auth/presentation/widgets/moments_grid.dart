import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class _Moment {
  const _Moment({required this.icon, required this.title, required this.date});

  final IconData icon;
  final String title;
  final String date;
}

const _moments = [
  _Moment(
    icon: Icons.temple_buddhist_outlined,
    title: 'Family trip to Tokyo',
    date: '10.07.26-10.08.26',
  ),
  _Moment(
    icon: Icons.hiking_outlined,
    title: 'A solo getaway',
    date: '13.04.26-15.04.26',
  ),
  _Moment(
    icon: Icons.favorite_outline,
    title: 'Honeymoon',
    date: '12.06.25-10.07.25',
  ),
  _Moment(icon: Icons.school_outlined, title: 'Graduation', date: '10.06.25'),
  _Moment(
    icon: Icons.restaurant_outlined,
    title: "A food lover's weekend",
    date: '15.12.25',
  ),
  _Moment(
    icon: Icons.landscape_outlined,
    title: 'A bucket-list moment',
    date: '01.12.25',
  ),
];

/// Static sample gallery matching the "Moments worth capturing" section of
/// the guest landing frame. Icon tiles stand in for the Figma stock photos.
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
      padding: const EdgeInsets.all(AppSpacing.md),
      alignment: Alignment.bottomLeft,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(moment.icon, color: AppColors.textSecondary),
          const SizedBox(height: AppSpacing.sm),
          Text(
            moment.title,
            style: AppTypography.chipLabel.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            moment.date,
            style: AppTypography.caption.copyWith(letterSpacing: 0),
          ),
        ],
      ),
    );
  }
}

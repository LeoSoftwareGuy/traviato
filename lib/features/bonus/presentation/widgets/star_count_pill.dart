import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';

/// "✦ 47" — the user's star total in the Bonus page's top bar.
class StarCountPill extends StatelessWidget {
  const StarCountPill({required this.stars, super.key});

  final int stars;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.tint(AppColors.primary, .15),
        border: Border.all(color: AppColors.tint(AppColors.primary, .35)),
        borderRadius: AppRadius.pillRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '✦',
            style: AppTypography.caption.copyWith(
              fontSize: 9,
              letterSpacing: 0,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '$stars',
            style: AppTypography.bodyEmphasis.copyWith(
              fontSize: 11,
              height: 1.2,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

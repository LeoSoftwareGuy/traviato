import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Pro/Free tier pill — shown both under `@handle` (`ProfileHeader`) and
/// atop the subscription card (`SubscriptionSection`), #142.
class TierPill extends StatelessWidget {
  const TierPill({required this.isPro, this.periodLabel, super.key});

  final bool isPro;

  /// e.g. "ANNUAL" / "MONTHLY" — omitted (just "PRO") when the active
  /// product id doesn't match this app's naming convention.
  final String? periodLabel;

  @override
  Widget build(BuildContext context) {
    final label = isPro
        ? (periodLabel != null ? 'PRO · $periodLabel' : 'PRO')
        : 'FREE PLAN';
    final glyphColor = isPro ? AppColors.primary : AppColors.textTertiary;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: isPro
            ? AppColors.tint(AppColors.primary, .14)
            : AppColors.surfaceElevated,
        border: Border.all(
          color: isPro
              ? AppColors.tint(AppColors.primary, .45)
              : AppColors.surfaceBorder,
        ),
        borderRadius: AppRadius.pillRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isPro ? '✦' : '○',
            style: TextStyle(color: glyphColor, fontSize: 10),
          ),
          const SizedBox(width: 4),
          Text(label, style: AppTypography.mono.copyWith(color: glyphColor)),
        ],
      ),
    );
  }
}

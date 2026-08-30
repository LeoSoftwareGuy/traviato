import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

final _weekdayFormat = DateFormat('EEE');
final _monthDayFormat = DateFormat('d MMM');

/// "MON · 24 AUG" — today's date as the header's mono eyebrow.
String homeDateEyebrow() {
  final now = DateTime.now();
  return '${_weekdayFormat.format(now)} · ${_monthDayFormat.format(now)}'
      .toUpperCase();
}

/// Header row: mono date eyebrow + "Hello, {name}", stars badge (→ Bonus
/// tasks) and avatar (→ Profile). `docs/design/README.md` § 3.
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    required this.username,
    required this.stars,
    required this.onAvatarTap,
    required this.onStarsTap,
    this.hasOpenBonusTasks = false,
    super.key,
  });

  final String username;
  final int stars;
  final VoidCallback onAvatarTap;
  final VoidCallback onStarsTap;

  /// Shows a small dot on the stars badge when the active trip's tray has
  /// open tasks (issue #64 AC).
  final bool hasOpenBonusTasks;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                homeDateEyebrow(),
                style: AppTypography.mono.copyWith(color: AppColors.primary),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text.rich(
                key: const Key('home-greeting'),
                TextSpan(
                  style: AppTypography.heroHeadline.copyWith(fontSize: 26),
                  children: [
                    const TextSpan(text: 'Hello, '),
                    TextSpan(
                      text: username,
                      style: const TextStyle(color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        _StarsBadge(
          stars: stars,
          onTap: onStarsTap,
          showDot: hasOpenBonusTasks,
        ),
        const SizedBox(width: AppSpacing.sm),
        _Avatar(username: username, onTap: onAvatarTap),
      ],
    );
  }
}

class _StarsBadge extends StatelessWidget {
  const _StarsBadge({
    required this.stars,
    required this.onTap,
    required this.showDot,
  });

  final int stars;
  final VoidCallback onTap;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: const Key('home-stars-badge'),
      onTap: onTap,
      borderRadius: AppRadius.pillRadius,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.tint(AppColors.primary, .15),
              border: Border.all(
                color: AppColors.tint(AppColors.primary, .35),
              ),
              borderRadius: AppRadius.pillRadius,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '✦',
                  style: AppTypography.chipLabel.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '$stars',
                  style: AppTypography.chipLabel.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (showDot)
            Positioned(
              key: const Key('home-stars-badge-dot'),
              top: -2,
              right: -2,
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.accentCoral,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.username, required this.onTap});

  final String username;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final initial = username.isEmpty ? '?' : username[0].toUpperCase();
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.tint(AppColors.primary, .5),
            width: 1.5,
          ),
        ),
        child: Text(
          initial,
          style: AppTypography.bodyInput.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

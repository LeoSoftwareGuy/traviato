import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/context_l10n.dart';
import '../../../../core/l10n/inline_placeholder.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../profile/presentation/widgets/profile_avatar.dart';

/// "MON · 24 AUG" — today's date as the header's mono eyebrow, in the UI
/// language: "ПН · 24 АВГ.", "E · 24. AUG" (#220).
String homeDateEyebrow(AppLocalizations l10n) {
  final now = DateTime.now();
  final locale = l10n.localeName;
  final dayMonth = locale == 'en'
      ? DateFormat('d MMM', locale)
      : DateFormat.MMMd(locale);
  return '${DateFormat('EEE', locale).format(now)} · ${dayMonth.format(now)}'
      .toUpperCase();
}

/// Header row: mono date eyebrow + "Hello, {name}" (just "Hello!" when
/// there's no username), stars badge (→ Bonus tasks) and avatar (→ Profile).
/// `docs/design/README.md` § 3.
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    required this.username,
    this.avatarUrl,
    required this.stars,
    required this.onAvatarTap,
    required this.onStarsTap,
    this.hasOpenBonusTasks = false,
    super.key,
  });

  /// Null or blank when the profile has no name (Apple sign-in can hide it).
  final String? username;

  /// The profile photo (#283) — null shows the name's initial.
  final String? avatarUrl;
  final int stars;
  final VoidCallback onAvatarTap;
  final VoidCallback onStarsTap;

  /// Shows a small dot on the stars badge when the active trip's tray has
  /// open tasks (issue #64 AC).
  final bool hasOpenBonusTasks;

  @override
  Widget build(BuildContext context) {
    final name = username?.trim() ?? '';
    final greeting = splitAroundPlaceholder(context.l10n.home_greeting);
    final greetingStyle = AppTypography.heroHeadline.copyWith(fontSize: 26);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                homeDateEyebrow(context.l10n),
                style: AppTypography.mono.copyWith(color: AppColors.primary),
              ),
              const SizedBox(height: AppSpacing.xs),
              if (name.isEmpty)
                Text(
                  context.l10n.home_greetingNoName,
                  key: const Key('home-greeting'),
                  style: greetingStyle,
                )
              else
                Text.rich(
                  key: const Key('home-greeting'),
                  TextSpan(
                    style: greetingStyle,
                    children: [
                      TextSpan(text: greeting.before),
                      TextSpan(
                        text: name,
                        style: const TextStyle(color: AppColors.primary),
                      ),
                      TextSpan(text: greeting.after),
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
        _Avatar(username: name, avatarUrl: avatarUrl, onTap: onAvatarTap),
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

/// The profile photo — the same [ProfileAvatar] the Profile screen shows
/// (#283) — falling back to the name's initial.
class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.username,
    required this.avatarUrl,
    required this.onTap,
  });

  final String username;
  final String? avatarUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: const Key('home-avatar'),
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: ProfileAvatar(
        avatarUrl: avatarUrl,
        username: username,
        size: 38,
        borderWidth: 1.5,
        borderColor: AppColors.tint(AppColors.primary, .5),
        initialsStyle: AppTypography.bodyInput.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

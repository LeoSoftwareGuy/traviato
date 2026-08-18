import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Greeting + top-right avatar/stars row (Figma "Home screen 1/2" header).
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    required this.username,
    required this.stars,
    required this.onAvatarTap,
    super.key,
  });

  final String username;
  final int stars;
  final VoidCallback onAvatarTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text.rich(
            key: const Key('home-greeting'),
            TextSpan(
              style: AppTypography.displaySerif.copyWith(
                fontSize: 26,
                height: 32.5 / 26,
              ),
              children: [
                const TextSpan(text: 'Hello, '),
                TextSpan(
                  text: username,
                  style: const TextStyle(color: AppColors.primary),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        _CircleIconButton(icon: Icons.person_outline, onTap: onAvatarTap),
        const SizedBox(width: AppSpacing.sm),
        _StarsBadge(stars: stars),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.surfaceBorder),
          borderRadius: AppRadius.pillRadius,
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 18),
      ),
    );
  }
}

class _StarsBadge extends StatelessWidget {
  const _StarsBadge({required this.stars});

  final int stars;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.surfaceBorder),
        borderRadius: AppRadius.pillRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: AppColors.primary, size: 18),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '$stars',
            style: AppTypography.chipLabel.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

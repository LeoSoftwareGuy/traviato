import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Back, memory name, delete (bin), and a stars badge — stub `0` until the
/// points migration lands (Figma "current trip - journal" doesn't show the
/// badge in this frame, but the issue's acceptance criteria calls for it).
class JournalHeader extends StatelessWidget {
  const JournalHeader({
    required this.tripName,
    required this.stars,
    required this.onBack,
    required this.onDelete,
    super.key,
  });

  final String tripName;
  final int stars;
  final VoidCallback onBack;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CircleIconButton(icon: Icons.arrow_back, onTap: onBack),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            tripName,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.headlineSerif.copyWith(fontSize: 18),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        _StarsBadge(stars: stars),
        const SizedBox(width: AppSpacing.sm),
        _CircleIconButton(
          key: const Key('journal-delete-action'),
          icon: Icons.delete_outline,
          onTap: onDelete,
        ),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({super.key, required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.surfaceBorder),
          borderRadius: AppRadius.pillRadius,
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 16),
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
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.surfaceBorder),
        borderRadius: AppRadius.pillRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: AppColors.primary, size: 16),
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

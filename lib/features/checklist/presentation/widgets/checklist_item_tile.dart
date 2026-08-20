import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/checklist_item_entity.dart';

class ChecklistItemTile extends StatelessWidget {
  const ChecklistItemTile({
    required this.item,
    required this.isToggling,
    required this.onToggle,
    super.key,
  });

  final ChecklistItemEntity item;
  final bool isToggling;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.surfaceBorder),
        borderRadius: AppRadius.badgeRadius,
      ),
      child: Row(
        children: [
          _Checkbox(
            key: Key('checklist-item-check-${item.id}'),
            isChecked: item.isChecked,
            isToggling: isToggling,
            onTap: onToggle,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              item.title,
              style: AppTypography.bodyInput.copyWith(
                fontWeight: FontWeight.w400,
                decoration: item.isChecked ? TextDecoration.lineThrough : null,
                color: item.isChecked
                    ? AppColors.textMuted
                    : AppColors.textPrimary,
              ),
            ),
          ),
          if (item.isEssential) ...[
            const SizedBox(width: AppSpacing.sm),
            const _EssentialBadge(),
          ],
        ],
      ),
    );
  }
}

class _Checkbox extends StatelessWidget {
  const _Checkbox({
    super.key,
    required this.isChecked,
    required this.isToggling,
    required this.onTap,
  });

  final bool isChecked;
  final bool isToggling;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isToggling ? null : onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 20,
        height: 20,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isChecked ? AppColors.primary : Colors.transparent,
          border: Border.all(
            color: isChecked ? AppColors.primary : AppColors.surfaceBorder,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: isToggling
            ? const SizedBox(
                width: 10,
                height: 10,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              )
            : isChecked
            ? const Icon(Icons.check, size: 14, color: AppColors.background)
            : null,
      ),
    );
  }
}

class _EssentialBadge extends StatelessWidget {
  const _EssentialBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: const BoxDecoration(
        color: AppColors.accentCoralTint,
        borderRadius: AppRadius.pillRadius,
      ),
      child: Text(
        'Essential',
        style: AppTypography.caption.copyWith(color: AppColors.accentCoral),
      ),
    );
  }
}

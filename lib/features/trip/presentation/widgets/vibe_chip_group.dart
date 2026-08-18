import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// The fixed 10-vibe list (functionality.md §5). No hard cap on selection —
/// the open question in data-model.md is left to app-side UX, not a
/// database check.
const kTripVibes = [
  'Romantic',
  'Adventure',
  'Cultural',
  'Chill',
  'Foodie',
  'Road trip',
  'Wellness',
  'Wildlife',
  'Nightlife',
  'Photography',
];

/// Multi-select vibe chips for the "The vibe" section of the "Add trip"
/// Figma frame.
class VibeChipGroup extends StatelessWidget {
  const VibeChipGroup({
    required this.selected,
    required this.onToggle,
    super.key,
  });

  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('The vibe', style: AppTypography.fieldLabel),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final vibe in kTripVibes)
              _VibeChip(
                label: vibe,
                selected: selected.contains(vibe),
                onTap: () => onToggle(vibe),
              ),
          ],
        ),
      ],
    );
  }
}

class _VibeChip extends StatelessWidget {
  const _VibeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.pillRadius,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.surfaceBorder,
          ),
          borderRadius: AppRadius.pillRadius,
        ),
        child: Text(
          label,
          style: AppTypography.chipLabel.copyWith(
            color: selected ? AppColors.background : AppColors.textSecondary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/expense_summary_entity.dart';

/// "Memory" dropdown on the add-expense sheet (Figma "add expenses").
class ExpenseTripSelector extends StatelessWidget {
  const ExpenseTripSelector({
    required this.trips,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final List<ExpenseSummaryEntity> trips;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Memory', style: AppTypography.fieldLabel),
        const SizedBox(height: AppSpacing.sm),
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textSecondary,
          ),
          dropdownColor: AppColors.surface,
          style: AppTypography.bodyInput,
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(
              horizontal: AppSpacing.base,
              vertical: AppSpacing.md,
            ),
          ),
          items: [
            for (final trip in trips)
              DropdownMenuItem(value: trip.tripId, child: Text(trip.tripName)),
          ],
          onChanged: onChanged,
          validator: (value) =>
              value == null ? 'Pick which memory this belongs to.' : null,
        ),
      ],
    );
  }
}

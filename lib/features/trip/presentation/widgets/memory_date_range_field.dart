import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

final _dateFormat = DateFormat('MMM d, y');

/// Start/end date pickers with a divider, matching the "When?" section of
/// the "Add trip" Figma frame. Both dates are optional.
class MemoryDateRangeField extends StatelessWidget {
  const MemoryDateRangeField({
    required this.startDate,
    required this.endDate,
    required this.onStartDateChanged,
    required this.onEndDateChanged,
    this.errorText,
    super.key,
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final ValueChanged<DateTime?> onStartDateChanged;
  final ValueChanged<DateTime?> onEndDateChanged;
  final String? errorText;

  Future<void> _pickDate(
    BuildContext context,
    DateTime? initial,
    ValueChanged<DateTime?> onChanged,
  ) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('When?', style: AppTypography.fieldLabel),
        const SizedBox(height: AppSpacing.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: _DateButton(
                label: 'Start',
                date: startDate,
                onTap: () => _pickDate(context, startDate, onStartDateChanged),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.surfaceBorder),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward,
                color: AppColors.textSecondary,
                size: 14,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _DateButton(
                label: 'End',
                date: endDate,
                onTap: () => _pickDate(context, endDate, onEndDateChanged),
              ),
            ),
          ],
        ),
        if (errorText != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            errorText!,
            style: AppTypography.caption.copyWith(
              color: AppColors.accentCoral,
              letterSpacing: 0,
            ),
          ),
        ],
      ],
    );
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton({
    required this.label,
    required this.date,
    required this.onTap,
  });

  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.cardRadius,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.surfaceBorder),
          borderRadius: AppRadius.cardRadius,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label.toUpperCase(),
              style: AppTypography.caption.copyWith(letterSpacing: 0.25),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              date == null ? 'Pick a date' : _dateFormat.format(date!),
              style: AppTypography.bodyInput.copyWith(
                color: date == null
                    ? AppColors.textTertiary
                    : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_date_picker_sheet.dart';

/// Starts / Ends field cards, side by side. `docs/design/README.md` § 4.
class MemoryDateRangeField extends StatelessWidget {
  const MemoryDateRangeField({
    required this.startDate,
    required this.endDate,
    required this.onStartDateChanged,
    required this.onEndDateChanged,
    this.errorText,
    this.showHint = true,
    super.key,
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final ValueChanged<DateTime?> onStartDateChanged;
  final ValueChanged<DateTime?> onEndDateChanged;
  final String? errorText;

  /// The "best guess, change it later" hint (#270) — for Create memory.
  /// Off in the Manage sheet, where the user is already changing them.
  final bool showHint;

  Future<void> _pickDate(
    BuildContext context,
    String label,
    DateTime? initial,
    ValueChanged<DateTime?> onChanged,
  ) async {
    final now = DateTime.now();
    final picked = await showAppDatePicker(
      context: context,
      label: label,
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
        Row(
          children: [
            Expanded(
              child: _DateCard(
                label: context.l10n.trip_startsLabel,
                date: startDate,
                onTap: () => _pickDate(
                  context,
                  context.l10n.trip_startsLabel,
                  startDate,
                  onStartDateChanged,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _DateCard(
                label: context.l10n.trip_endsLabel,
                date: endDate,
                onTap: () => _pickDate(
                  context,
                  context.l10n.trip_endsLabel,
                  endDate,
                  onEndDateChanged,
                ),
              ),
            ),
          ],
        ),
        // The error replaces the hint rather than stacking under it (#270).
        if (errorText != null || showHint)
          const SizedBox(height: AppSpacing.xs),
        if (errorText != null)
          Text(
            errorText!,
            style: AppTypography.caption.copyWith(
              color: AppColors.accentCoral,
              letterSpacing: 0,
            ),
          )
        else if (showHint)
          Text(
            context.l10n.trip_datesHint,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 0,
            ),
          ),
      ],
    );
  }
}

class _DateCard extends StatelessWidget {
  const _DateCard({
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
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
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
              style: AppTypography.mono.copyWith(color: AppColors.textTertiary),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              date == null
                  ? context.l10n.datePicker_defaultLabel
                  : DateFormat(
                      'd MMM y',
                      context.l10n.localeName,
                    ).format(date!),
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

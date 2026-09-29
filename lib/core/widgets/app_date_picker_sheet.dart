import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import 'bottom_sheet_chrome.dart';

final _headlineFormat = DateFormat('EEE, d MMM y');

/// Opens [AppDatePickerSheet] in the shared bottom-sheet chrome and resolves
/// with the tapped day, or `null` when dismissed. Replaces `showDatePicker`
/// app-wide so date entry looks the same on iOS and Android (#163).
Future<DateTime?> showAppDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  String label = 'Pick a date',
}) {
  return showAppBottomSheet<DateTime>(
    context: context,
    builder: (context) => AppDatePickerSheet(
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      label: label,
    ),
  );
}

/// Month calendar skinned with [AppTheme.datePicker]: mono eyebrow, serif
/// headline of the current choice, the day grid, then Cancel / Done. Picking a
/// day only updates the headline — the calendar also reports year switches
/// through `onDateChanged`, so popping on change would close mid-browse.
class AppDatePickerSheet extends StatefulWidget {
  const AppDatePickerSheet({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.label,
    super.key,
  });

  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final String label;

  @override
  State<AppDatePickerSheet> createState() => _AppDatePickerSheetState();
}

class _AppDatePickerSheetState extends State<AppDatePickerSheet> {
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    // CalendarDatePicker asserts the initial date is inside the range.
    final initial = widget.initialDate;
    _selected = initial.isBefore(widget.firstDate)
        ? widget.firstDate
        : initial.isAfter(widget.lastDate)
        ? widget.lastDate
        : initial;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Theme(
      data: theme.copyWith(
        datePickerTheme: AppTheme.datePicker,
        colorScheme: theme.colorScheme.copyWith(
          primary: AppColors.primary,
          onSurface: AppColors.textPrimary,
        ),
        textTheme: theme.textTheme.copyWith(
          titleSmall: AppTypography.bodyEmphasis,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          0,
          AppSpacing.xl,
          AppSpacing.base,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.label.toUpperCase(),
              style: AppTypography.mono.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _headlineFormat.format(_selected),
              style: AppTypography.displaySerif,
            ),
            const SizedBox(height: AppSpacing.sm),
            CalendarDatePicker(
              initialDate: _selected,
              firstDate: widget.firstDate,
              lastDate: widget.lastDate,
              onDateChanged: (date) => setState(() => _selected = date),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(_selected),
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

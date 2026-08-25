import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

final _dayFormat = DateFormat('d MMM');

/// Prev/next day arrows, "Day N" + a mono done-count sub-line, and tappable
/// segment dots for every day. `docs/design/README.md` § 5.
class DayNavigator extends StatelessWidget {
  const DayNavigator({
    required this.currentDate,
    required this.dayNumber,
    required this.totalDays,
    required this.doneCount,
    required this.totalForDay,
    required this.canGoToPreviousDay,
    required this.canGoToNextDay,
    required this.onPreviousDay,
    required this.onNextDay,
    required this.onSelectDayNumber,
    super.key,
  });

  final DateTime currentDate;
  final int dayNumber;
  final int totalDays;
  final int doneCount;
  final int totalForDay;
  final bool canGoToPreviousDay;
  final bool canGoToNextDay;
  final VoidCallback onPreviousDay;
  final VoidCallback onNextDay;
  final ValueChanged<int> onSelectDayNumber;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _ArrowButton(
              icon: Icons.chevron_left,
              enabled: canGoToPreviousDay,
              onTap: onPreviousDay,
            ),
            Column(
              children: [
                Text(
                  'Day $dayNumber',
                  style: AppTypography.screenTitle.copyWith(fontSize: 19),
                ),
                Text(
                  '${_dayFormat.format(currentDate)} · $doneCount of '
                  '$totalForDay done',
                  style: AppTypography.mono.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
            _ArrowButton(
              icon: Icons.chevron_right,
              enabled: canGoToNextDay,
              onTap: onNextDay,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.base),
        Row(
          children: [
            for (var i = 1; i <= totalDays; i++) ...[
              if (i > 1) const SizedBox(width: 4),
              Expanded(
                child: GestureDetector(
                  key: Key('day-segment-$i'),
                  onTap: () => onSelectDayNumber(i),
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: i == dayNumber
                          ? AppColors.primary
                          : AppColors.surfaceBorder,
                      borderRadius: AppRadius.pillRadius,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      customBorder: const CircleBorder(),
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: enabled
                ? AppColors.surfaceBorder
                : AppColors.surfaceBorder.withValues(alpha: 0.3),
          ),
        ),
        child: Icon(
          icon,
          color: enabled ? AppColors.textPrimary : AppColors.textTertiary,
        ),
      ),
    );
  }
}

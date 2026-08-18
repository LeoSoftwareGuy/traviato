import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

final _dayFormat = DateFormat('MMM d');

/// Prev/next day navigation, clamped to the memory's date range.
class DayNavigator extends StatelessWidget {
  const DayNavigator({
    required this.currentDate,
    required this.dayNumber,
    required this.canGoToPreviousDay,
    required this.canGoToNextDay,
    required this.onPreviousDay,
    required this.onNextDay,
    super.key,
  });

  final DateTime currentDate;
  final int dayNumber;
  final bool canGoToPreviousDay;
  final bool canGoToNextDay;
  final VoidCallback onPreviousDay;
  final VoidCallback onNextDay;

  @override
  Widget build(BuildContext context) {
    return Row(
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
              _dayFormat.format(currentDate),
              style: AppTypography.headlineSerif,
            ),
            Text(
              'Day $dayNumber',
              style: AppTypography.chipLabel.copyWith(
                color: AppColors.textMuted,
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
        width: 40,
        height: 40,
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

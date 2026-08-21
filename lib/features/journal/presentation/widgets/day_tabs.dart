import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../photo/domain/entities/photo_entity.dart';

final _dayLabelFormat = DateFormat('MMM d');

/// Horizontally scrollable day pills — a small thumbnail is shown only for
/// a day that already has a photo. Simplified from Figma's two-row
/// hero-thumbnail treatment to the app's existing pill/tab visual language.
class DayTabs extends StatelessWidget {
  const DayTabs({
    required this.days,
    required this.selectedDay,
    required this.thumbnailForDay,
    required this.onSelect,
    super.key,
  });

  final List<DateTime> days;
  final DateTime selectedDay;
  final PhotoEntity? Function(DateTime day) thumbnailForDay;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final day = days[index];
          final isSelected = _isSameDate(day, selectedDay);
          return _DayTab(
            key: Key('journal-day-tab-${day.toIso8601String()}'),
            day: day,
            isSelected: isSelected,
            thumbnail: thumbnailForDay(day),
            onTap: () => onSelect(day),
          );
        },
      ),
    );
  }
}

class _DayTab extends StatelessWidget {
  const _DayTab({
    super.key,
    required this.day,
    required this.isSelected,
    required this.thumbnail,
    required this.onTap,
  });

  final DateTime day;
  final bool isSelected;
  final PhotoEntity? thumbnail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.pillRadius,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryTint : AppColors.surface,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.surfaceBorder,
          ),
          borderRadius: AppRadius.pillRadius,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (thumbnail?.imageUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: Image.network(
                  thumbnail!.imageUrl!,
                  width: 18,
                  height: 18,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
            Text(
              _dayLabelFormat.format(day),
              style: AppTypography.chipLabel.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textMuted,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

bool _isSameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

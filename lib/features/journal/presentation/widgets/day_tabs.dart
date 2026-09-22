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
/// A future day (`day_date` > today) shows a lock icon and isn't tappable;
/// past days and today stay fully open (#118).
class DayTabs extends StatelessWidget {
  const DayTabs({
    required this.days,
    required this.selectedDay,
    required this.thumbnailForDay,
    required this.onSelect,
    required this.isDayLocked,
    this.isDayEmpty,
    super.key,
  });

  final List<DateTime> days;
  final DateTime selectedDay;
  final PhotoEntity? Function(DateTime day) thumbnailForDay;
  final ValueChanged<DateTime> onSelect;
  final bool Function(DateTime day) isDayLocked;

  /// Drives the empty-day dot indicator (#140/M6-4b) — optional so callers
  /// that don't have this data yet aren't forced to supply it.
  final bool Function(DateTime day)? isDayEmpty;

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
          final isLocked = isDayLocked(day);
          return _DayTab(
            key: Key('journal-day-tab-${day.toIso8601String()}'),
            day: day,
            isSelected: isSelected,
            isLocked: isLocked,
            isEmpty: !isLocked && (isDayEmpty?.call(day) ?? false),
            thumbnail: thumbnailForDay(day),
            onTap: () =>
                isLocked ? _showLockedDayMessage(context) : onSelect(day),
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
    required this.isLocked,
    required this.isEmpty,
    required this.thumbnail,
    required this.onTap,
  });

  final DateTime day;
  final bool isSelected;
  final bool isLocked;
  final bool isEmpty;
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
            if (isLocked) ...[
              const Icon(
                Icons.lock_outline,
                size: 12,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: AppSpacing.xs),
            ] else if (thumbnail?.imageUrl != null) ...[
              _Thumbnail(url: thumbnail!.imageUrl!, isEmpty: isEmpty),
              const SizedBox(width: AppSpacing.xs),
            ] else if (isEmpty) ...[
              const _EmptyDayDot(),
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

/// Day-tab thumbnail with the empty-day dot indicator pinned to its
/// top-right corner (spec §7: 5px `fg3` dot, 2px dark ring so it reads
/// against any photo).
class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.url, required this.isEmpty});

  final String url;
  final bool isEmpty;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 18,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Image.network(
              url,
              width: 18,
              height: 18,
              fit: BoxFit.cover,
            ),
          ),
          if (isEmpty)
            const Positioned(top: -1, right: -1, child: _EmptyDayDot()),
        ],
      ),
    );
  }
}

class _EmptyDayDot extends StatelessWidget {
  const _EmptyDayDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('empty-day-dot'),
      width: 5,
      height: 5,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.textTertiary,
        border: Border.all(
          color: AppColors.tint(AppColors.background, 0.8),
          width: 2,
        ),
      ),
    );
  }
}

void _showLockedDayMessage(BuildContext context) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      const SnackBar(content: Text("This day hasn't happened yet")),
    );
}

bool _isSameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

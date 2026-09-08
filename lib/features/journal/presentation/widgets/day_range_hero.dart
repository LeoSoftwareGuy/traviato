import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import 'journal_images.dart';

/// The day-range photo strip above the date pills (Figma "current trip -
/// journal", DIV-38) — placeholder day photography (real per-day photos
/// aren't captured yet; see `PhotosStrip` for that data once it exists).
/// The selected day's tile is larger with a golden ring + glow — a
/// selection cue, independent of [isDayLocked]. A future day (`day_date` >
/// today) is dimmed with a lock overlay and not tappable; past days and
/// today stay fully open (#118).
class DayRangeHero extends StatelessWidget {
  const DayRangeHero({
    required this.days,
    required this.selectedDay,
    required this.onSelect,
    required this.isDayLocked,
    super.key,
  });

  final List<DateTime> days;
  final DateTime selectedDay;
  final ValueChanged<DateTime> onSelect;
  final bool Function(DateTime day) isDayLocked;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final day = days[index];
          final isLocked = isDayLocked(day);
          return _DayTile(
            key: Key('journal-day-hero-${day.toIso8601String()}'),
            imagePath: JournalImages.forDayIndex(index),
            isSelected: _isSameDate(day, selectedDay),
            isLocked: isLocked,
            onTap: isLocked ? null : () => onSelect(day),
          );
        },
      ),
    );
  }
}

class _DayTile extends StatelessWidget {
  const _DayTile({
    super.key,
    required this.imagePath,
    required this.isSelected,
    required this.isLocked,
    required this.onTap,
  });

  final String imagePath;
  final bool isSelected;
  final bool isLocked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final width = isSelected ? 90.0 : 75.0;
    final height = isSelected ? 110.0 : 92.0;
    return Align(
      alignment: Alignment.bottomCenter,
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: width,
          height: height,
          child: Stack(
            children: [
              AnimatedOpacity(
                opacity: isLocked ? 0.5 : 1,
                duration: const Duration(milliseconds: 150),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.surfaceBorder,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ]
                        : null,
                  ),
                  padding: const EdgeInsets.all(2),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.asset(
                      imagePath,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              // Rendered outside the AnimatedOpacity above so the tint and
              // lock icon stay crisp instead of inheriting the fade.
              if (isLocked)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.lock_outline,
                          color: AppColors.textOnPhoto,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

bool _isSameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

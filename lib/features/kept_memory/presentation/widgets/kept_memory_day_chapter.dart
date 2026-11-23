import 'package:flutter/material.dart';

import '../../../../core/l10n/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/kept_memory_day.dart';
import '../kept_memory_labels.dart';
import 'kept_memory_photo_strip.dart';

const _sidePadding = 22.0;

/// One day of a kept memory (#279, spec § 3.3): header with the day's date
/// and "N photos ›", the photo strip, then every note in full. A day with
/// notes only has no strip and no photos link.
class KeptMemoryDayChapter extends StatelessWidget {
  const KeptMemoryDayChapter({
    required this.day,
    required this.onOpenPhoto,
    super.key,
  });

  final KeptMemoryDay day;

  /// Called with the index across every photo of the memory.
  final ValueChanged<int> onOpenPhoto;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hasPhotos = day.photos.isNotEmpty;
    final header =
        '${l10n.keptMemory_day(day.dayIndex)} · '
        '${KeptMemoryLabels.weekdayDate(day.date, l10n.localeName)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: _sidePadding),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  header.toUpperCase(),
                  style: AppTypography.mono.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
              if (hasPhotos)
                GestureDetector(
                  key: ValueKey('kept-memory-day-photos-${day.dayIndex}'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onOpenPhoto(day.firstPhotoIndex),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      '${l10n.common_photoCount(day.photos.length)} ›'
                          .toUpperCase(),
                      style: AppTypography.mono.copyWith(
                        fontSize: 10,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (hasPhotos) ...[
          const SizedBox(height: 12),
          KeptMemoryPhotoStrip(
            photos: day.photos,
            onPhotoTap: (index) => onOpenPhoto(day.firstPhotoIndex + index),
          ),
        ],
        for (final note in day.notes) ...[
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: _sidePadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  // An old one-a-day note has no real time of its own.
                  note.legacy
                      ? context.l10n.timeline_earlierNote.toUpperCase()
                      : KeptMemoryLabels.noteTime(
                          note.localTakenAt,
                          context.l10n.localeName,
                          use24h: MediaQuery.alwaysUse24HourFormatOf(context),
                        ),
                  style: AppTypography.mono.copyWith(
                    fontSize: 9,
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 4),
                // User content — shown exactly as written, in full.
                Text(
                  '“${note.content}”',
                  style: AppTypography.serif(
                    fontSize: 16,
                    height: 1.5,
                    fontStyle: FontStyle.italic,
                    color: AppColors.noteText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

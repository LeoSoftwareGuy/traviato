import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';

/// The rail column's width; the line sits on its right edge
/// (docs/design/journal-notes/JOURNAL_NOTES_OPTION_B_SPEC.md §4).
const timelineRailWidth = 52.0;
const timelineRailGap = 13.0;
const _dotSize = 8.0;
const _dotRing = 3.0;

/// The rail's 1px line, behind every row.
class TimelineRailLine extends StatelessWidget {
  const TimelineRailLine({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: timelineRailWidth - .5,
      top: 0,
      bottom: 0,
      child: Container(
        width: 1,
        color: AppColors.tint(AppColors.textSecondary, .16),
      ),
    );
  }
}

/// One timeline row: the time (right-aligned, with a mic glyph under it for
/// a dictated note) and a dot on the rail, then [child].
class TimelineRailRow extends StatelessWidget {
  const TimelineRailRow({
    required this.label,
    required this.isNote,
    required this.child,
    this.dictated = false,
    super.key,
  });

  /// The clock time, or "LATER" for something added after the day.
  final String label;
  final bool isNote;
  final bool dictated;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: timelineRailWidth,
                child: Padding(
                  padding: const EdgeInsets.only(right: 11),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        label,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.fade,
                        textAlign: TextAlign.right,
                        style: AppTypography.timelineTime.copyWith(
                          color: isNote
                              ? AppColors.primaryLight
                              : AppColors.textMuted,
                        ),
                      ),
                      if (dictated)
                        const Padding(
                          padding: EdgeInsets.only(top: 3),
                          child: Icon(
                            Icons.mic_none_rounded,
                            key: Key('timeline-dictated'),
                            size: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: timelineRailGap),
              Expanded(child: child),
            ],
          ),
          Positioned(
            left: timelineRailWidth - (_dotSize / 2 + _dotRing),
            top: 1,
            child: Container(
              width: _dotSize + 2 * _dotRing,
              height: _dotSize + 2 * _dotRing,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.background,
                shape: BoxShape.circle,
              ),
              child: Container(
                width: _dotSize,
                height: _dotSize,
                decoration: BoxDecoration(
                  color: isNote
                      ? AppColors.primary
                      : AppColors.timelinePhotoDot,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "AFTER MIDNIGHT · FRI 24 OCT" / "LATER": a mono label across the
/// timeline with a hairline after it.
class TimelineDivider extends StatelessWidget {
  const TimelineDivider({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final rule = AppColors.tint(AppColors.textSecondary, .16);
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        children: [
          const SizedBox(width: timelineRailWidth + timelineRailGap),
          Text(
            label.toUpperCase(),
            style: AppTypography.mono.copyWith(color: AppColors.textTertiary),
          ),
          const SizedBox(width: 10),
          Expanded(child: Container(height: 1, color: rule)),
        ],
      ),
    );
  }
}

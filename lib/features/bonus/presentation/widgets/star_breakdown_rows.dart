import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// The 8px segmented bar over the type rows: one segment per (flex, color).
/// With no segments it draws one empty track (the 0-star guide).
class StarSegmentBar extends StatelessWidget {
  const StarSegmentBar({required this.segments, super.key});

  final List<(int flex, Color color)> segments;

  @override
  Widget build(BuildContext context) {
    final parts = segments.isEmpty ? const [(1, AppColors.hairline)] : segments;
    return SizedBox(
      height: 8,
      child: Row(
        children: [
          for (var i = 0; i < parts.length; i++) ...[
            if (i > 0) const SizedBox(width: 3),
            Expanded(
              flex: parts[i].$1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: parts[i].$2,
                  borderRadius: const BorderRadius.all(Radius.circular(4)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// One type row: dot · label · trailing. [outlined] draws the 0-star
/// guide's hollow dot; [showDivider] adds the top hairline every row after
/// the first carries.
class StarTypeRow extends StatelessWidget {
  const StarTypeRow({
    required this.color,
    required this.label,
    required this.trailing,
    this.detail,
    this.outlined = false,
    this.muted = false,
    this.showDivider = false,
    super.key,
  });

  final Color color;
  final String label;
  final String? detail;
  final Widget trailing;
  final bool outlined;
  final bool muted;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: showDivider
          ? const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.hairlineSoft)),
            )
          : null,
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: outlined ? null : color,
              border: outlined ? Border.all(color: color, width: 1.5) : null,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodyEmphasis.copyWith(
                height: 1.3,
                color: muted ? AppColors.textSecondary : AppColors.textPrimary,
              ),
            ),
          ),
          if (detail case final detail?) ...[
            const SizedBox(width: 11),
            Text(
              detail,
              style: AppTypography.mono.copyWith(
                fontSize: 10,
                letterSpacing: 0,
              ),
            ),
          ],
          const SizedBox(width: 11),
          trailing,
        ],
      ),
    );
  }
}

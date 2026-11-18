import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../core/l10n/context_l10n.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_gradients.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';

const _pageWidth = 206.0;
const _pageHeight = 134.0;
const _ruleGap = 30.0;

/// A day with nothing yet (#401, docs/design/journal-notes/ §4 "Empty
/// day"): a small tilted notebook page, "Nothing written for Saturday yet",
/// one line on how notes work, "✎ Write the first note ✦1" and "or add a
/// photo".
class EmptyDayNotebook extends StatelessWidget {
  const EmptyDayNotebook({
    required this.stamp,
    required this.weekday,
    required this.onWrite,
    required this.onAddPhoto,
    super.key,
  });

  /// "DAY 3 · SAT 25 OCT".
  final String stamp;

  /// "Saturday", capitalised.
  final String weekday;
  final VoidCallback onWrite;
  final VoidCallback onAddPhoto;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      key: const Key('timeline-empty-day'),
      children: [
        const SizedBox(height: AppSpacing.base),
        Transform.rotate(
          angle: -3 * math.pi / 180,
          child: Container(
            width: _pageWidth,
            height: _pageHeight,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                const BoxShadow(
                  color: AppColors.paperDropShadow,
                  offset: Offset(0, 10),
                  blurRadius: 24,
                ),
              ],
            ),
            child: CustomPaint(
              painter: const _RulesPainter(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stamp.toUpperCase(),
                    style: AppTypography.titlePageStamp,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    l10n.timeline_emptyLine,
                    style: AppTypography.titlePageMeta.copyWith(
                      color: AppColors.tint(AppColors.paperInkOld, .45),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          l10n.timeline_emptyTitle(weekday),
          textAlign: TextAlign.center,
          style: AppTypography.displaySerif.copyWith(fontSize: 21),
        ),
        const SizedBox(height: AppSpacing.sm),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
          child: Text(
            l10n.timeline_emptyBody,
            textAlign: TextAlign.center,
            style: AppTypography.timelineMeta.copyWith(
              fontSize: 12.5,
              fontWeight: FontWeight.w400,
              height: 1.45,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        DecoratedBox(
          decoration: const BoxDecoration(
            gradient: AppGradients.primaryCta,
            borderRadius: AppRadius.pillRadius,
          ),
          child: TextButton(
            key: const Key('timeline-empty-write'),
            onPressed: onWrite,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.background,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: 14,
              ),
              shape: const StadiumBorder(),
            ),
            child: Text(
              l10n.timeline_emptyWrite,
              style: AppTypography.buttonLabel.copyWith(
                color: AppColors.background,
              ),
            ),
          ),
        ),
        TextButton(
          key: const Key('timeline-empty-photo'),
          onPressed: onAddPhoto,
          child: Text(
            l10n.timeline_emptyOrPhoto,
            style: AppTypography.timelineLink,
          ),
        ),
      ],
    );
  }
}

class _RulesPainter extends CustomPainter {
  const _RulesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.paperRule
      ..strokeWidth = 1;
    for (var y = _ruleGap + 18; y < size.height; y += _ruleGap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

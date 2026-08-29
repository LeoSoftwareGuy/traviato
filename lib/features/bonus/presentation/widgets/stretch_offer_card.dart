import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/bonus_task_template_entity.dart';

/// The single opt-in stretch offer shown once both dailies are done —
/// dashed border, visibly optional, never auto-inserted (functionality.md
/// §12: "UNLOCKED · OPTIONAL").
class StretchOfferCard extends StatelessWidget {
  const StretchOfferCard({
    required this.template,
    required this.onClaim,
    super.key,
  });

  final BonusTaskTemplateEntity template;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: const Key('bonus-stretch-offer'),
      onTap: onClaim,
      borderRadius: AppRadius.cardRadius,
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: AppColors.tint(AppColors.accentPurple, .5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.base),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'UNLOCKED · OPTIONAL',
                      style: AppTypography.mono.copyWith(
                        color: AppColors.accentPurpleLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(template.title, style: AppTypography.bodyEmphasis),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.tint(AppColors.accentPurple, .16),
                  borderRadius: AppRadius.pillRadius,
                ),
                child: Text(
                  '✦${template.points}',
                  style: AppTypography.mono.copyWith(
                    color: AppColors.accentPurpleLight,
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

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(AppRadius.card),
    );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      var distance = 0.0;
      const dashWidth = 5.0;
      const dashGap = 4.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + dashWidth),
          paint,
        );
        distance += dashWidth + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}

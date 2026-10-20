import 'package:flutter/material.dart';

import '../../../../core/l10n/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/dashed_rrect_border.dart';
import '../../domain/entities/bonus_task_template_entity.dart';
import 'bonus_template_text.dart';

/// A muted, dashed preview of a tray task (#219 Phase 3). Deliberately not
/// tappable and without any expiry chip — it's a sample, not a task.
class TrayTeaserCard extends StatelessWidget {
  const TrayTeaserCard({
    required this.template,
    required this.accent,
    required this.icon,
    super.key,
  });

  final BonusTaskTemplateEntity template;
  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DashedRRectBorder(
      color: AppColors.tint(AppColors.textSecondary, .22),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.tint(AppColors.surface, .35),
          borderRadius: AppRadius.cardRadius,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.tint(accent, .12),
                borderRadius: const BorderRadius.all(Radius.circular(13)),
              ),
              child: Icon(icon, size: 18, color: AppColors.tint(accent, .8)),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bonusTemplateTitle(context.l10n, template),
                    style: AppTypography.serif(
                      fontSize: 15,
                      height: 1.25,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '✦${template.points}',
                    style: AppTypography.bodyEmphasis.copyWith(
                      fontSize: 10,
                      height: 1.2,
                      fontWeight: FontWeight.w600,
                      color: AppColors.tint(AppColors.primary, .75),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

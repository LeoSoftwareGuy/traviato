import 'package:flutter/material.dart';

import '../../../../core/l10n/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/dashed_rrect_border.dart';

/// The dashed "stars aren't points to spend" note that closes every no-tray
/// state (#219 Phase 2).
class StarsFooterNote extends StatelessWidget {
  const StarsFooterNote({super.key});

  static const _radius = BorderRadius.all(Radius.circular(14));

  @override
  Widget build(BuildContext context) {
    return DashedRRectBorder(
      color: AppColors.tint(AppColors.textSecondary, .2),
      borderRadius: _radius,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.tint(AppColors.surface, .5),
          borderRadius: _radius,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '✦',
              style: AppTypography.caption.copyWith(
                fontSize: 11,
                height: 18 / 11,
                letterSpacing: 0,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                context.l10n.stars_footer,
                style: AppTypography.chipLabel.copyWith(
                  fontSize: 11.5,
                  height: 1.55,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

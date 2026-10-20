import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Mono eyebrow, a two-line serif headline (second line italic), and body
/// copy — the top of every no-tray state (#219 Phase 2). The headline is
/// two strings so the italic split survives translation.
class BonusEmptyHero extends StatelessWidget {
  const BonusEmptyHero({
    required this.eyebrow,
    required this.lead,
    required this.emphasis,
    required this.body,
    super.key,
  });

  final String eyebrow;
  final String lead;
  final String emphasis;
  final String body;

  @override
  Widget build(BuildContext context) {
    final headline = AppTypography.screenTitle.copyWith(
      fontSize: AppTypography.serifIsLiterata ? 27 : 28,
      height: 1.14,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(eyebrow.toUpperCase(), style: AppTypography.mono),
        const SizedBox(height: 9),
        Text.rich(
          TextSpan(
            text: '$lead\n',
            children: [
              TextSpan(
                text: emphasis,
                style: headline.copyWith(
                  fontStyle: FontStyle.italic,
                  color: AppColors.primaryLight,
                ),
              ),
            ],
          ),
          style: headline,
        ),
        const SizedBox(height: 8),
        Text(body, style: bonusBodyStyle),
      ],
    );
  }
}

/// Roboto 12.5/1.6 muted body copy.
TextStyle get bonusBodyStyle => AppTypography.chipLabel.copyWith(
  fontSize: 12.5,
  height: 1.6,
  fontWeight: FontWeight.w400,
  color: AppColors.textMuted,
);

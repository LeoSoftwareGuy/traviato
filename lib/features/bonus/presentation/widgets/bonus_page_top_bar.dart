import 'package:flutter/material.dart';

import '../../../../core/l10n/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import 'star_count_pill.dart';

/// Back arrow · centred mono [eyebrow] · star pill (#219 Phase 2).
class BonusPageTopBar extends StatelessWidget {
  const BonusPageTopBar({
    required this.eyebrow,
    required this.stars,
    required this.onBack,
    super.key,
  });

  final String eyebrow;
  final int stars;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Semantics(
              button: true,
              label: context.l10n.common_back,
              child: InkWell(
                onTap: onBack,
                borderRadius: AppRadius.badgeRadius,
                child: const SizedBox(
                  width: 36,
                  height: 36,
                  child: Icon(
                    Icons.arrow_back,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 72),
            child: Text(
              eyebrow.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.mono,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: StarCountPill(stars: stars),
          ),
        ],
      ),
    );
  }
}

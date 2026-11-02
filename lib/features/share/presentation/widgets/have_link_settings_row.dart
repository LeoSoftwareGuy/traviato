import 'package:flutter/material.dart';

import '../../../../core/l10n/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import 'have_link_sheet.dart';

/// You → "I have a link" (#310): opens [HaveLinkSheet]. Styled like the
/// settings rows above it.
class HaveLinkSettingsRow extends StatelessWidget {
  const HaveLinkSettingsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.surfaceBorder),
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: const Key('profile-have-link'),
        onTap: () => HaveLinkSheet.show(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.base,
            vertical: 11,
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.tint(AppColors.primary, .16),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.link_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  context.l10n.share_haveLink,
                  style: AppTypography.bodyInput.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

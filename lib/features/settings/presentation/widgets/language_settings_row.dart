import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/app_language.dart';
import '../controllers/app_language_controller.dart';
import 'language_sheet.dart';

/// You → SETTINGS group with the Language row (localization design 1a).
/// The trailing value shows what "System default" resolves to, so it's
/// never a mystery.
class LanguageSettingsSection extends ConsumerWidget {
  const LanguageSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final choice = ref.watch(appLanguageControllerProvider);
    final resolved = ref.watch(resolvedAppLanguageProvider);
    final value = choice == AppLanguage.system
        ? '${l10n.language_systemDefault} · ${resolved.nativeName}'
        : choice.nativeName;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.settings_header.toUpperCase(),
          style: AppTypography.mono.copyWith(color: AppColors.textTertiary),
        ),
        const SizedBox(height: 11),
        Material(
          color: Colors.transparent,
          child: InkWell(
            key: const Key('settings-language-row'),
            onTap: () => LanguageSheet.show(context),
            borderRadius: BorderRadius.circular(18),
            child: Ink(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.base,
                vertical: 15,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.surfaceBorder),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.tint(AppColors.accentBlue, .16),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Text(
                      'Aa',
                      style: AppTypography.bodyEmphasis.copyWith(
                        fontSize: 12,
                        color: AppColors.accentBlue,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.settings_language,
                          style: AppTypography.bodyInput.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          value,
                          style: AppTypography.chipLabel.copyWith(
                            fontSize: 11.5,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: AppColors.textTertiary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../controllers/reduce_flashing_controller.dart';

/// You → SETTINGS row with the "Reduce flashing" switch (#363), styled
/// like the Memory reminders row above it. While the phone asks for
/// reduced motion the films already play softly, so the switch shows on
/// and can't be turned off here.
class ReduceFlashingSettingsRow extends ConsumerWidget {
  const ReduceFlashingSettingsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final byPhone = MediaQuery.disableAnimationsOf(context);
    final enabled = ref.watch(reduceFlashingControllerProvider);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: 11,
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
              color: AppColors.tint(AppColors.primary, .16),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.flash_off_rounded,
              size: 18,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.settings_reduceFlashing,
                  style: AppTypography.bodyInput.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  byPhone
                      ? l10n.settings_reduceFlashingByPhone
                      : l10n.settings_reduceFlashingSubtitle,
                  style: AppTypography.chipLabel.copyWith(
                    fontSize: 11.5,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            key: const Key('settings-reduce-flashing-switch'),
            value: byPhone || enabled,
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.surfaceDisabled,
            inactiveThumbColor: AppColors.textTertiary,
            trackOutlineColor: const WidgetStatePropertyAll(
              Colors.transparent,
            ),
            onChanged: byPhone
                ? null
                : (value) => ref
                      .read(reduceFlashingControllerProvider.notifier)
                      .setEnabled(enabled: value),
          ),
        ],
      ),
    );
  }
}

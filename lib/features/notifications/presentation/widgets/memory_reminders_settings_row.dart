import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../controllers/memory_reminders_controller.dart';

/// You → SETTINGS row with the "Memory reminders" on/off switch (#307),
/// styled like the Language row above it.
class MemoryRemindersSettingsRow extends ConsumerWidget {
  const MemoryRemindersSettingsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final enabled = ref.watch(memoryRemindersControllerProvider);
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
              Icons.notifications_none_rounded,
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
                  l10n.settings_memoryReminders,
                  style: AppTypography.bodyInput.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.settings_memoryRemindersSubtitle,
                  style: AppTypography.chipLabel.copyWith(
                    fontSize: 11.5,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            key: const Key('settings-reminders-switch'),
            // Shows "on" while loading — the stored default.
            value: enabled.value ?? true,
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.surfaceDisabled,
            inactiveThumbColor: AppColors.textTertiary,
            trackOutlineColor: const WidgetStatePropertyAll(
              Colors.transparent,
            ),
            onChanged: enabled.isLoading
                ? null
                : (value) => ref
                      .read(memoryRemindersControllerProvider.notifier)
                      .setEnabled(value),
          ),
        ],
      ),
    );
  }
}

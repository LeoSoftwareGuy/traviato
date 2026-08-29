import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Reached from Home's stars badge when there is no active/upcoming trip to
/// draw a tray for (issue #64 AC: "Empty/no-active-memory state").
class BonusTasksEmptyPage extends StatelessWidget {
  const BonusTasksEmptyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppGradients.screenGroundRadial(
            AppGradients.groundTopBonusProfile,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '✦',
                    style: AppTypography.bigNumber.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.base),
                  Text(
                    'No active memory yet',
                    style: AppTypography.screenTitle.copyWith(fontSize: 20),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Bonus tasks show up here once a memory is under way.',
                    textAlign: TextAlign.center,
                    style: AppTypography.chipLabel.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    child: const Text('Back home'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';

/// Back arrow + mono `PROFILE` eyebrow, matching Journal/Plan's header
/// back button (issue #176). Sits above the page's async content so the way
/// back is there in the loading and error states too.
class ProfileTopBar extends StatelessWidget {
  const ProfileTopBar({required this.onBack, super.key});

  final VoidCallback onBack;

  static const _buttonSize = 36.0;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          key: const Key('profile-back-button'),
          onTap: onBack,
          customBorder: const CircleBorder(),
          child: Container(
            width: _buttonSize,
            height: _buttonSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.surfaceBorder),
              borderRadius: AppRadius.pillRadius,
            ),
            child: const Icon(
              Icons.arrow_back,
              color: AppColors.textPrimary,
              size: 16,
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: Text(
              'PROFILE',
              style: AppTypography.mono.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ),
        ),
        // Balances the back button so the eyebrow stays centred.
        const SizedBox(width: _buttonSize),
      ],
    );
  }
}

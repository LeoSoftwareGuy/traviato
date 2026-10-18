import 'package:flutter/material.dart';

import '../../../../core/l10n/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Visual-only password strength: three stadium segments + a label. Heuristic
/// is length + character variety, not a real strength estimate — the design
/// only calls for a rough signal (`docs/design/README.md` § 2).
class PasswordStrengthMeter extends StatelessWidget {
  const PasswordStrengthMeter({required this.password, super.key});

  final String password;

  /// Filled segments, 0–3: empty, weak, good, strong.
  static int strengthOf(String password) {
    if (password.isEmpty) return 0;
    final hasLetter = RegExp(r'[A-Za-z]').hasMatch(password);
    final hasDigit = RegExp(r'\d').hasMatch(password);
    final variety = (hasLetter ? 1 : 0) + (hasDigit ? 1 : 0);
    if (password.length >= 10 && variety == 2) {
      return 3;
    }
    if (password.length >= 6) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final filled = strengthOf(password);
    if (filled == 0) return const SizedBox.shrink();
    final l10n = context.l10n;
    final label = switch (filled) {
      1 => l10n.auth_strengthWeak,
      2 => l10n.auth_strengthGood,
      _ => l10n.auth_strengthStrong,
    };

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Row(
        children: [
          for (var i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  color: i < filled
                      ? AppColors.primary
                      : AppColors.surfaceBorder,
                  borderRadius: AppRadius.pillRadius,
                ),
              ),
            ),
          ],
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: AppTypography.caption.copyWith(letterSpacing: 0),
          ),
        ],
      ),
    );
  }
}
